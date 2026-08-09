/**
 * Exercise Phase 3 job time-range and owner-edit invariants against local Docker.
 * Keys are read from supabase status --output env and never committed.
 */

const apiUrl = (process.env.SUPABASE_LOCAL_API_URL || 'http://127.0.0.1:54421').replace(/\/$/, '');
const anonKey = process.env.SUPABASE_LOCAL_ANON_KEY;
const serviceRoleKey = process.env.SUPABASE_LOCAL_SERVICE_ROLE_KEY;
if (!anonKey || !serviceRoleKey) {
  throw new Error('Set local Supabase API, anon, and service-role keys first.');
}

const customer = {
  id: '00000000-0000-0000-0000-000000000101',
  email: 'customer@example.test',
};
const provider = {
  id: '00000000-0000-0000-0000-000000000102',
  email: 'provider@example.test',
};
const testJobId = '00000000-0000-0000-0000-000000000903';
const checks = [];

function pass(label, condition, details = '') {
  if (!condition) {
    throw new Error(label + ' failed' + (details ? ': ' + details : ''));
  }
  checks.push(label);
  console.log('PASS ' + label);
}

async function request(url, { key = anonKey, token = key, method = 'GET', body, headers = {} } = {}) {
  const requestHeaders = new Headers(headers);
  requestHeaders.set('apikey', key);
  requestHeaders.set('authorization', 'Bearer ' + token);
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
    // Keep raw diagnostics for failed assertions.
  }
  return { ok: response.ok, status: response.status, data };
}

function rest(path, options = {}) {
  return request(apiUrl + '/rest/v1' + path, options);
}

async function login(user) {
  const result = await request(apiUrl + '/auth/v1/token?grant_type=password', {
    method: 'POST',
    body: { email: user.email, password: 'local-dev-only' },
  });
  if (!result.ok || !result.data?.access_token) {
    throw new Error('fixture login failed for ' + user.email);
  }
  return result.data.access_token;
}

async function deleteRows(table, filter) {
  const result = await rest('/' + table + '?' + filter, {
    key: serviceRoleKey,
    token: serviceRoleKey,
    method: 'DELETE',
    headers: { prefer: 'return=minimal' },
  });
  if (!result.ok) {
    throw new Error('cleanup ' + table + ' failed: ' + result.status + ' ' + JSON.stringify(result.data));
  }
}

async function cleanup() {
  await deleteRows('notifications', 'reference_id=eq.' + testJobId);
  await deleteRows('jobs', 'id=eq.' + testJobId);
}

async function main() {
  const [customerToken, providerToken] = await Promise.all([
    login(customer),
    login(provider),
  ]);
  pass('fixture accounts authenticate', Boolean(customerToken && providerToken));
  await cleanup();

  const baseJob = {
    id: testJobId,
    customer_id: customer.id,
    category_id: '00000000-0000-0000-0000-000000000201',
    area_id: '00000000-0000-0000-0000-000000000251',
    title: 'Phase 3 schedule check',
    description: 'A deterministic local time-range fixture.',
    public_location_text: 'Mount Austin',
    full_address: '12 Phase 3 Street, Mount Austin, Johor Bahru',
    budget_amount: 120,
    urgency: 'normal',
    status: 'draft',
    time_window: '11 Aug, 2:00 PM - 4:00 PM',
    contact_phone: '+60 12 000 0101',
    contact_whatsapp: null,
  };

  const sameTime = await rest('/jobs', {
    token: customerToken,
    method: 'POST',
    headers: { prefer: 'return=representation' },
    body: {
      ...baseJob,
      id: '00000000-0000-0000-0000-000000000904',
      scheduled_at: '2026-08-11T06:00:00Z',
      scheduled_end_at: '2026-08-11T06:00:00Z',
    },
  });
  pass('database rejects equal start/end times', !sameTime.ok);
  await deleteRows('jobs', 'id=eq.00000000-0000-0000-0000-000000000904');

  const valid = await rest('/jobs', {
    token: customerToken,
    method: 'POST',
    headers: { prefer: 'return=representation' },
    body: {
      ...baseJob,
      id: '00000000-0000-0000-0000-000000000905',
      scheduled_at: '2026-08-11T06:00:00Z',
      scheduled_end_at: '2026-08-11T08:00:00Z',
    },
  });
  pass('database accepts a valid UTC range', valid.ok);
  await deleteRows('jobs', 'id=eq.00000000-0000-0000-0000-000000000905');

  const invalidOvernight = await rest('/jobs', {
    token: customerToken,
    method: 'POST',
    headers: { prefer: 'return=representation' },
    body: {
      ...baseJob,
      id: '00000000-0000-0000-0000-000000000906',
      scheduled_at: '2026-08-11T14:00:00Z',
      scheduled_end_at: '2026-08-12T01:00:00Z',
    },
  });
  pass('database rejects an overnight range', !invalidOvernight.ok);
  await deleteRows('jobs', 'id=eq.00000000-0000-0000-0000-000000000906');

  const inserted = await rest('/jobs', {
    token: customerToken,
    method: 'POST',
    headers: { prefer: 'return=representation' },
    body: {
      ...baseJob,
      scheduled_at: '2026-08-11T06:00:00Z',
      scheduled_end_at: '2026-08-11T08:00:00Z',
    },
  });
  pass('customer can create a valid draft with a UTC range', inserted.ok, JSON.stringify(inserted.data));

  const stored = await rest('/jobs?select=status,scheduled_at,scheduled_end_at,expires_at&id=eq.' + testJobId, {
    key: serviceRoleKey,
    token: serviceRoleKey,
  });
  pass(
    'stored range remains UTC and both endpoints are persisted',
    stored.ok &&
      stored.data?.[0]?.scheduled_at?.startsWith('2026-08-11T06:00:00') &&
      stored.data?.[0]?.scheduled_end_at?.startsWith('2026-08-11T08:00:00') &&
      stored.data?.[0]?.status === 'draft',
    JSON.stringify(stored.data),
  );

  const published = await rest('/jobs?id=eq.' + testJobId + '&customer_id=eq.' + customer.id + '&status=eq.draft', {
    token: customerToken,
    method: 'PATCH',
    headers: { prefer: 'return=representation' },
    body: { status: 'open' },
  });
  pass('customer can publish the draft', published.ok && published.data?.[0]?.status === 'open', JSON.stringify(published.data));
  pass(
    'publishing assigns a future server expiry',
    published.ok && published.data?.[0]?.expires_at && new Date(published.data[0].expires_at) > new Date(),
    JSON.stringify(published.data),
  );

  const expiryTamper = await rest('/jobs?id=eq.' + testJobId, {
    token: customerToken,
    method: 'PATCH',
    headers: { prefer: 'return=representation' },
    body: { expires_at: new Date(Date.now() - 60_000).toISOString() },
  });
  pass('customer cannot tamper with an open expiry', !expiryTamper.ok);

  const unpublish = await rest('/jobs?id=eq.' + testJobId, {
    token: customerToken,
    method: 'PATCH',
    headers: { prefer: 'return=representation' },
    body: { status: 'draft' },
  });
  pass('customer cannot move an open job back to draft', !unpublish.ok);

  const edit = await rest('/jobs?id=eq.' + testJobId, {
    token: customerToken,
    method: 'PATCH',
    headers: { prefer: 'return=representation' },
    body: { title: 'Phase 3 edited schedule check' },
  });
  pass('customer can edit safe fields on an open job', edit.ok && edit.data?.[0]?.title === 'Phase 3 edited schedule check');

  const legacy = await rest('/jobs?select=scheduled_at,scheduled_end_at,time_window&id=eq.00000000-0000-0000-0000-000000000301', {
    token: customerToken,
  });
  pass(
    'legacy jobs retain time_window fallback data',
    legacy.ok && legacy.data?.[0]?.scheduled_end_at == null && Boolean(legacy.data?.[0]?.time_window),
    JSON.stringify(legacy.data),
  );

  const feed = await rest('/public_job_feed?select=id,scheduled_at,scheduled_end_at&id=eq.' + testJobId, {
    token: providerToken,
  });
  pass(
    'approved provider feed exposes both schedule endpoints',
    feed.ok && feed.data?.[0]?.scheduled_end_at?.startsWith('2026-08-11T08:00:00'),
    JSON.stringify(feed.data),
  );

  const assignedEdit = await rest('/jobs?id=eq.00000000-0000-0000-0000-000000000303', {
    token: customerToken,
    method: 'PATCH',
    headers: { prefer: 'return=representation' },
    body: { title: 'Should not change assigned job' },
  });
  pass('customer cannot edit an assigned job', assignedEdit.ok && Array.isArray(assignedEdit.data) && assignedEdit.data.length === 0);

  await cleanup();
  console.log('Phase 3 local validation passed: ' + checks.length + ' checks.');
}

await main();
