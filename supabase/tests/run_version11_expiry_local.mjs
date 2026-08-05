/**
 * Exercise Version 1.1 job expiry against the local Supabase stack.
 * Keys are read from `supabase status --output env` and never committed.
 */

const apiUrl = (process.env.SUPABASE_LOCAL_API_URL || 'http://127.0.0.1:54421').replace(/\/$/, '');
const anonKey = process.env.SUPABASE_LOCAL_ANON_KEY;
const serviceRoleKey = process.env.SUPABASE_LOCAL_SERVICE_ROLE_KEY;
if (!anonKey || !serviceRoleKey) throw new Error('Set local Supabase API, anon, and service-role keys first.');

const customer = {
  id: '00000000-0000-0000-0000-000000000101',
  email: 'customer@example.test',
};
const jobId = '00000000-0000-0000-0000-000000000301';
const bidId = '00000000-0000-0000-0000-000000000401';
const checks = [];

function pass(label, condition, details = '') {
  if (!condition) throw new Error(`${label} failed${details ? `: ${details}` : ''}`);
  checks.push(label);
  console.log(`PASS ${label}`);
}

async function request(url, { key = anonKey, token = key, method = 'GET', body, headers = {} } = {}) {
  const requestHeaders = new Headers(headers);
  requestHeaders.set('apikey', key);
  requestHeaders.set('authorization', `Bearer ${token}`);
  if (body !== undefined) {
    requestHeaders.set('content-type', 'application/json');
    body = JSON.stringify(body);
  }
  const response = await fetch(url, { method, headers: requestHeaders, body });
  const text = await response.text();
  let data = text;
  try {
    data = text ? JSON.parse(text) : null;
  } catch (_) {
    // Keep the raw response for diagnostics.
  }
  return { ok: response.ok, status: response.status, data };
}

function rest(path, options = {}) {
  return request(`${apiUrl}/rest/v1${path}`, options);
}

async function login() {
  const result = await request(`${apiUrl}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    body: { email: customer.email, password: 'local-dev-only' },
  });
  if (!result.ok || !result.data?.access_token) throw new Error('fixture login failed');
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
  if (!result.ok) throw new Error(`reset ${table} failed: ${result.status} ${JSON.stringify(result.data)}`);
}

async function deleteRows(table, filter) {
  const result = await rest(`/${table}?${filter}`, {
    key: serviceRoleKey,
    token: serviceRoleKey,
    method: 'DELETE',
    headers: { prefer: 'return=minimal' },
  });
  if (!result.ok) throw new Error(`cleanup ${table} failed: ${result.status} ${JSON.stringify(result.data)}`);
}

async function resetFixture() {
  await patchTable('jobs', `id=eq.${jobId}`, {
    status: 'open',
    accepted_bid_id: null,
    expires_at: new Date(Date.now() - 60_000).toISOString(),
  });
  await patchTable('bids', `id=eq.${bidId}`, { status: 'pending' });
  await deleteRows('job_events', `job_id=eq.${jobId}&event_type=eq.job_expired`);
  await deleteRows('notifications', `reference_id=eq.${jobId}&type=eq.job_expired`);
}

async function cleanupFixture() {
  await patchTable('jobs', `id=eq.${jobId}`, {
    status: 'open',
    accepted_bid_id: null,
    expires_at: new Date(Date.now() + 172_800_000).toISOString(),
  });
  await patchTable('bids', `id=eq.${bidId}`, { status: 'pending' });
  await deleteRows('job_events', `job_id=eq.${jobId}&event_type=eq.job_expired`);
  await deleteRows('notifications', `reference_id=eq.${jobId}&type=eq.job_expired`);
}

async function main() {
  const customerToken = await login();
  await resetFixture();
  try {
    const browserCall = await rest('/rpc/expire_open_jobs', {
      token: customerToken,
      method: 'POST',
      body: { p_limit: 10 },
    });
    pass('browser clients cannot run the expiry worker', !browserCall.ok, JSON.stringify(browserCall.data));

    const workerCall = await rest('/rpc/expire_open_jobs', {
      key: serviceRoleKey,
      token: serviceRoleKey,
      method: 'POST',
      body: { p_limit: 10 },
    });
    pass('service worker expires due open jobs', workerCall.ok && workerCall.data === 1, JSON.stringify(workerCall.data));

    const job = await rest(`/jobs?select=status&id=eq.${jobId}`, { key: serviceRoleKey, token: serviceRoleKey });
    const bid = await rest(`/bids?select=status&id=eq.${bidId}`, { key: serviceRoleKey, token: serviceRoleKey });
    const event = await rest(`/job_events?select=event_type&job_id=eq.${jobId}&event_type=eq.job_expired`, { key: serviceRoleKey, token: serviceRoleKey });
    const notification = await rest(`/notifications?select=type,user_id&reference_id=eq.${jobId}&type=eq.job_expired`, { key: serviceRoleKey, token: serviceRoleKey });
    pass(
      'expiry atomically updates bids and records event/notification',
      job.ok && job.data[0]?.status === 'expired' && bid.ok && bid.data[0]?.status === 'expired' &&
        event.ok && event.data.length === 1 && notification.ok && notification.data.length === 1 && notification.data[0].user_id === customer.id,
      JSON.stringify({ job: job.data, bid: bid.data, event: event.data, notification: notification.data }),
    );
  } finally {
    await cleanupFixture();
  }
  console.log(`Version 1.1 expiry local validation passed: ${checks.length} checks.`);
}

await main();
