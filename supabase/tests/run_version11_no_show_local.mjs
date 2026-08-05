/**
 * Exercise the Version 1.1 no-show RPC against the local Supabase stack.
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
const provider = {
  id: '00000000-0000-0000-0000-000000000102',
  email: 'provider@example.test',
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

async function login(user) {
  const result = await request(`${apiUrl}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    body: { email: user.email, password: 'local-dev-only' },
  });
  if (!result.ok || !result.data?.access_token) throw new Error(`login failed for ${user.email}`);
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
  await patchTable('jobs', `id=eq.${jobId}`, { status: 'assigned', accepted_bid_id: bidId });
  await patchTable('bids', `id=eq.${bidId}`, { status: 'accepted' });
  await deleteRows('job_events', `job_id=eq.${jobId}&event_type=eq.no_show_marked`);
  await deleteRows('notifications', `reference_id=eq.${jobId}&type=eq.no_show`);
}

async function cleanupFixture() {
  await patchTable('jobs', `id=eq.${jobId}`, { status: 'open', accepted_bid_id: null });
  await patchTable('bids', `id=eq.${bidId}`, { status: 'pending' });
  await deleteRows('job_events', `job_id=eq.${jobId}&event_type=eq.no_show_marked`);
  await deleteRows('notifications', `reference_id=eq.${jobId}&type=eq.no_show`);
}

async function main() {
  const [customerToken, providerToken] = await Promise.all([login(customer), login(provider)]);
  await resetFixture();
  try {
    const marked = await rest('/rpc/mark_no_show', {
      token: customerToken,
      method: 'POST',
      body: { p_job_id: jobId, p_reason: 'Provider did not arrive.' },
    });
    pass('customer can mark an accepted provider as no-show', marked.ok, JSON.stringify(marked.data));

    const duplicate = await rest('/rpc/mark_no_show', {
      token: customerToken,
      method: 'POST',
      body: { p_job_id: jobId },
    });
    pass('duplicate no-show marker is rejected', !duplicate.ok, JSON.stringify(duplicate.data));

    const events = await rest(`/job_events?select=event_type,metadata&job_id=eq.${jobId}&event_type=eq.no_show_marked`, {
      key: serviceRoleKey,
      token: serviceRoleKey,
    });
    const notifications = await rest(`/notifications?select=type,user_id&reference_id=eq.${jobId}&type=eq.no_show`, {
      key: serviceRoleKey,
      token: serviceRoleKey,
    });
    pass(
      'no-show event and reported-user notification are recorded',
      events.ok && events.data.length === 1 && events.data[0].metadata?.reported_user_id === provider.id &&
        notifications.ok && notifications.data.length === 1 && notifications.data[0].user_id === provider.id,
      JSON.stringify({ events: events.data, notifications: notifications.data }),
    );
    void providerToken;
  } finally {
    await cleanupFixture();
  }
  console.log(`Version 1.1 no-show local validation passed: ${checks.length} checks.`);
}

await main();
