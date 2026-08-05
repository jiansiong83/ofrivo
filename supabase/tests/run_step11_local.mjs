/**
 * Execute the Step 11 integration checks against a running local Supabase stack.
 *
 * The local anon/service keys are supplied by `supabase status --output env` and
 * are never stored in this repository. The service key is used only to reset
 * local fixtures before/after the concurrency check.
 */

const apiUrl = (process.env.SUPABASE_LOCAL_API_URL || 'http://127.0.0.1:54421').replace(/\/$/, '');
const anonKey = process.env.SUPABASE_LOCAL_ANON_KEY;
const serviceRoleKey = process.env.SUPABASE_LOCAL_SERVICE_ROLE_KEY;

if (!anonKey || !serviceRoleKey) {
  throw new Error(
    'Set SUPABASE_LOCAL_API_URL, SUPABASE_LOCAL_ANON_KEY, and SUPABASE_LOCAL_SERVICE_ROLE_KEY from `supabase status --output env`.',
  );
}

const users = {
  customer: {
    id: '00000000-0000-0000-0000-000000000101',
    email: 'customer@example.test',
  },
  providerA: {
    id: '00000000-0000-0000-0000-000000000102',
    email: 'provider@example.test',
  },
  pendingProvider: {
    id: '00000000-0000-0000-0000-000000000103',
    email: 'pending-provider@example.test',
  },
  providerB: {
    id: '00000000-0000-0000-0000-000000000104',
    email: 'provider-b@example.test',
  },
};

const jobId = '00000000-0000-0000-0000-000000000301';
const bidA = '00000000-0000-0000-0000-000000000401';
const bidB = '00000000-0000-0000-0000-000000000402';

const checks = [];

function assertCheck(label, condition, details = '') {
  if (!condition) {
    throw new Error(`${label} failed${details ? `: ${details}` : ''}`);
  }
  checks.push(label);
  console.log(`PASS ${label}`);
}

async function request(url, { key = anonKey, token = key, method = 'GET', body, headers = {} } = {}) {
  const requestHeaders = new Headers(headers);
  requestHeaders.set('apikey', key);
  requestHeaders.set('authorization', `Bearer ${token}`);
  if (body !== undefined && !(body instanceof Uint8Array)) {
    requestHeaders.set('content-type', 'application/json');
    body = JSON.stringify(body);
  }
  const response = await fetch(url, { method, headers: requestHeaders, body });
  const text = await response.text();
  let data = text;
  try {
    data = text ? JSON.parse(text) : null;
  } catch (_) {
    // Preserve non-JSON error bodies for diagnostics.
  }
  return { ok: response.ok, status: response.status, data, headers: response.headers };
}

function rest(path, options = {}) {
  return request(`${apiUrl}/rest/v1${path}`, options);
}

function storage(path, options = {}) {
  return request(`${apiUrl}/storage/v1/object/${path}`, options);
}

async function login(user) {
  const result = await request(`${apiUrl}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    body: { email: user.email, password: 'local-dev-only' },
  });
  if (!result.ok || !result.data?.access_token) {
    throw new Error(`login failed for ${user.email}: ${result.status} ${JSON.stringify(result.data)}`);
  }
  return result.data.access_token;
}

async function patchTable(table, filter, values) {
  const result = await rest(`/${table}?${filter}`, {
    key: serviceRoleKey,
    token: serviceRoleKey,
    method: 'PATCH',
    headers: { prefer: 'return=minimal' },
    body: values,
  });
  if (!result.ok) {
    throw new Error(`reset ${table} failed: ${result.status} ${JSON.stringify(result.data)}`);
  }
}

async function deleteRows(table, filter) {
  const result = await rest(`/${table}?${filter}`, {
    key: serviceRoleKey,
    token: serviceRoleKey,
    method: 'DELETE',
    headers: { prefer: 'return=minimal' },
  });
  if (!result.ok) {
    throw new Error(`cleanup ${table} failed: ${result.status} ${JSON.stringify(result.data)}`);
  }
}

async function resetConcurrencyFixture() {
  await patchTable('jobs', `id=eq.${jobId}`, { status: 'open', accepted_bid_id: null });
  await patchTable('bids', `id=in.(${bidA},${bidB})`, { status: 'pending' });
  await deleteRows('job_events', `job_id=eq.${jobId}&event_type=eq.bid_accepted`);
  await deleteRows('notifications', `reference_id=eq.${jobId}&type=in.(bid_accepted,job_assigned)`);
}

async function main() {
  const [customerToken, providerAToken, providerBToken, pendingToken] = await Promise.all([
    login(users.customer),
    login(users.providerA),
    login(users.providerB),
    login(users.pendingProvider),
  ]);
  assertCheck(
    'fixture accounts authenticate',
    [customerToken, providerAToken, providerBToken, pendingToken].every(Boolean),
  );

  const feed = await rest('/public_job_feed?select=id,title,public_location_text,budget_amount&order=id', {
    token: providerAToken,
  });
  assertCheck(
    'approved provider receives safe feed fields',
    feed.ok && Array.isArray(feed.data) && feed.data.length > 0 && feed.data.every((row) => !('full_address' in row)),
    JSON.stringify(feed.data),
  );

  const providerAddress = await rest(`/jobs?select=full_address&id=eq.${jobId}`, { token: providerAToken });
  assertCheck(
    'provider cannot read unrelated customer address',
    providerAddress.ok && providerAddress.data.length === 0,
    `${providerAddress.status} ${JSON.stringify(providerAddress.data)}`,
  );

  const customerJob = await rest(`/jobs?select=id,full_address&id=eq.${jobId}`, { token: customerToken });
  assertCheck('customer can read own job address', customerJob.ok && customerJob.data.length === 1 && customerJob.data[0].full_address);

  const pendingFeed = await rest('/public_job_feed?select=id', { token: pendingToken });
  assertCheck('pending provider cannot read provider feed', pendingFeed.ok && pendingFeed.data.length === 0);

  const foreignNotifications = await rest(
    `/notifications?select=id&user_id=eq.${users.customer.id}`,
    { token: providerAToken },
  );
  assertCheck('provider cannot read customer notifications', foreignNotifications.ok && foreignNotifications.data.length === 0);

  const bidTestJobId = '00000000-0000-0000-0000-000000000302';
  await deleteRows('bids', `job_id=eq.${bidTestJobId}&provider_id=eq.${users.providerA.id}`);
  try {
    const approvedBid = await rest('/bids', {
      token: providerAToken,
      method: 'POST',
      headers: { prefer: 'return=representation' },
      body: {
        job_id: bidTestJobId,
        provider_id: users.providerA.id,
        amount: 70,
        available_at: new Date().toISOString(),
        inclusions: 'Labour and inspection',
        status: 'pending',
      },
    });
    assertCheck('approved provider can submit an open-job bid', approvedBid.ok, JSON.stringify(approvedBid.data));

    const pendingBid = await rest('/bids', {
      token: pendingToken,
      method: 'POST',
      headers: { prefer: 'return=representation' },
      body: {
        job_id: bidTestJobId,
        provider_id: users.pendingProvider.id,
        amount: 65,
        available_at: new Date().toISOString(),
        inclusions: 'Labour',
        status: 'pending',
      },
    });
    assertCheck('pending provider cannot submit a bid', !pendingBid.ok);
  } finally {
    await deleteRows('bids', `job_id=eq.${bidTestJobId}&provider_id=eq.${users.providerA.id}`);
    await deleteRows('bids', `job_id=eq.${bidTestJobId}&provider_id=eq.${users.pendingProvider.id}`);
  }

  const objectPath = `provider-verifications/${users.providerA.id}/step11-integration.txt`;
  const upload = await storage(objectPath, {
    token: providerAToken,
    method: 'POST',
    headers: { 'content-type': 'text/plain', 'x-upsert': 'true' },
    body: new TextEncoder().encode('step11-local-only'),
  });
  assertCheck('verification owner can upload private object', upload.ok, JSON.stringify(upload.data));

  const ownerDownload = await storage(objectPath, { token: providerAToken });
  assertCheck('verification owner can download private object', ownerDownload.ok);

  const otherDownload = await storage(objectPath, { token: providerBToken });
  assertCheck('other provider cannot download private object', !otherDownload.ok);

  const anonymousDownload = await storage(objectPath, { token: anonKey });
  assertCheck('anonymous client cannot download private object', !anonymousDownload.ok);

  const cleanupObject = await storage(objectPath, { token: providerAToken, method: 'DELETE' });
  assertCheck('verification owner can remove test object', cleanupObject.ok, JSON.stringify(cleanupObject.data));

  const beforeError = await rest(`/jobs?select=status&id=eq.${jobId}`, { key: serviceRoleKey, token: serviceRoleKey });
  const invalidStart = await rest(`/rpc/start_job`, {
    token: customerToken,
    method: 'POST',
    body: { p_job_id: jobId },
  });
  const invalidComplete = await rest(`/rpc/complete_job`, {
    token: customerToken,
    method: 'POST',
    body: { p_job_id: jobId },
  });
  const afterError = await rest(`/jobs?select=status&id=eq.${jobId}`, { key: serviceRoleKey, token: serviceRoleKey });
  assertCheck('invalid start transition returns an error', !invalidStart.ok);
  assertCheck('invalid complete transition returns an error', !invalidComplete.ok);
  assertCheck(
    'invalid transitions do not partially update job',
    beforeError.ok && afterError.ok && beforeError.data[0].status === afterError.data[0].status,
    JSON.stringify({ before: beforeError.data, after: afterError.data }),
  );

  await resetConcurrencyFixture();
  try {
    const [acceptA, acceptB] = await Promise.all([
      rest('/rpc/accept_bid', {
        token: customerToken,
        method: 'POST',
        body: { p_job_id: jobId, p_bid_id: bidA },
      }),
      rest('/rpc/accept_bid', {
        token: customerToken,
        method: 'POST',
        body: { p_job_id: jobId, p_bid_id: bidB },
      }),
    ]);
    const results = [acceptA, acceptB];
    assertCheck('concurrent accept-bid calls have one winner', results.filter((result) => result.ok).length === 1);
    assertCheck('concurrent accept-bid loser returns an error', results.filter((result) => !result.ok).length === 1);

    const jobAfterAccept = await rest(`/jobs?select=status,accepted_bid_id&id=eq.${jobId}`, {
      key: serviceRoleKey,
      token: serviceRoleKey,
    });
    const bidsAfterAccept = await rest(`/bids?select=id,status&job_id=eq.${jobId}&status=eq.accepted`, {
      key: serviceRoleKey,
      token: serviceRoleKey,
    });
    assertCheck(
      'concurrent accept-bid leaves one assigned job and one accepted bid',
      jobAfterAccept.ok &&
        jobAfterAccept.data[0]?.status === 'assigned' &&
        [bidA, bidB].includes(jobAfterAccept.data[0].accepted_bid_id) &&
        bidsAfterAccept.ok &&
        bidsAfterAccept.data.length === 1,
      JSON.stringify({ job: jobAfterAccept.data, bids: bidsAfterAccept.data }),
    );
  } finally {
    await resetConcurrencyFixture();
  }

  console.log(`Step 11 local integration validation passed: ${checks.length} checks.`);
}

await main();
