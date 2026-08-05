/**
 * Exercise Version 1.1 review dimensions against the local Supabase stack.
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
const jobId = '00000000-0000-0000-0000-000000000303';
const bidId = '00000000-0000-0000-0000-000000000403';
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
  await patchTable('jobs', `id=eq.${jobId}`, { status: 'completed', accepted_bid_id: bidId });
  await patchTable('bids', `id=eq.${bidId}`, { status: 'accepted' });
  await deleteRows('reviews', `job_id=eq.${jobId}`);
}

async function cleanupFixture() {
  await deleteRows('reviews', `job_id=eq.${jobId}`);
  await patchTable('jobs', `id=eq.${jobId}`, { status: 'assigned', accepted_bid_id: bidId });
  await patchTable('bids', `id=eq.${bidId}`, { status: 'accepted' });
}

function reviewBody(reviewerId, revieweeId, comment) {
  return {
    job_id: jobId,
    reviewer_id: reviewerId,
    reviewee_id: revieweeId,
    rating: 4,
    punctuality_rating: 5,
    quality_rating: 4,
    communication_rating: 3,
    comment,
  };
}

async function main() {
  const [customerToken, providerToken] = await Promise.all([login(customer), login(provider)]);
  await resetFixture();
  try {
    const customerReview = await rest('/reviews', {
      token: customerToken,
      method: 'POST',
      headers: { prefer: 'return=representation' },
      body: reviewBody(customer.id, provider.id, 'version11-review-customer'),
    });
    const row = Array.isArray(customerReview.data) ? customerReview.data[0] : customerReview.data;
    pass(
      'customer can submit all review dimensions',
      customerReview.ok && row?.punctuality_rating === 5 && row?.quality_rating === 4 && row?.communication_rating === 3,
      JSON.stringify(customerReview.data),
    );

    const invalidDimension = await rest('/reviews', {
      token: customerToken,
      method: 'POST',
      body: { ...reviewBody(customer.id, provider.id, 'version11-review-invalid'), quality_rating: 6 },
    });
    pass('out-of-range review dimensions are rejected', !invalidDimension.ok, JSON.stringify(invalidDimension.data));

    const duplicate = await rest('/reviews', {
      token: customerToken,
      method: 'POST',
      body: reviewBody(customer.id, provider.id, 'version11-review-duplicate'),
    });
    pass('one review per participant per job remains enforced', !duplicate.ok, JSON.stringify(duplicate.data));

    const providerReview = await rest('/reviews', {
      token: providerToken,
      method: 'POST',
      headers: { prefer: 'return=representation' },
      body: reviewBody(provider.id, customer.id, 'version11-review-provider'),
    });
    pass('accepted provider can submit reciprocal dimensions', providerReview.ok, JSON.stringify(providerReview.data));
  } finally {
    await cleanupFixture();
  }
  console.log(`Version 1.1 review dimensions local validation passed: ${checks.length} checks.`);
}

await main();
