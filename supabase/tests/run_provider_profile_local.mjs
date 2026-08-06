/**
 * Local integration checks for Provider Profile editing, category requests,
 * Admin review, availability filtering, and assigned-job preservation.
 * Keys are supplied through the environment and never committed.
 */
const apiUrl = (process.env.SUPABASE_LOCAL_API_URL || 'http://127.0.0.1:54421').replace(/\/$/, '');
const anonKey = process.env.SUPABASE_LOCAL_ANON_KEY;
const serviceRoleKey = process.env.SUPABASE_LOCAL_SERVICE_ROLE_KEY;
if (!anonKey || !serviceRoleKey) throw new Error('Set local Supabase keys from `supabase status --output env`.');

const ids = {
  provider: '00000000-0000-0000-0000-000000000102',
  admin: '00000000-0000-0000-0000-000000000199',
  categoryPlumbing: '00000000-0000-0000-0000-000000000201',
  categoryElectrical: '00000000-0000-0000-0000-000000000202',
  categoryHandyman: '00000000-0000-0000-0000-000000000206',
  areaMountAustin: '00000000-0000-0000-0000-000000000251',
  areaTamanMolek: '00000000-0000-0000-0000-000000000252',
  jobPlumbing: '00000000-0000-0000-0000-000000000301',
  jobElectrical: '00000000-0000-0000-0000-000000000302',
  assignedJob: '00000000-0000-0000-0000-000000000303',
};
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
  const raw = await response.text();
  let data = raw;
  try { data = raw ? JSON.parse(raw) : null; } catch (_) { /* keep text */ }
  return { ok: response.ok, status: response.status, data };
}
function rest(path, options = {}) { return request(`${apiUrl}/rest/v1${path}`, options); }
async function login(email) {
  const result = await request(`${apiUrl}/auth/v1/token?grant_type=password`, { method: 'POST', body: { email, password: 'local-dev-only' } });
  if (!result.ok || !result.data?.access_token) throw new Error(`login failed for ${email}: ${JSON.stringify(result.data)}`);
  return result.data.access_token;
}
async function rpc(name, params, token) { return request(`${apiUrl}/rest/v1/rpc/${name}`, { method: 'POST', token, body: params }); }
async function cleanup() {
  await rest(`/provider_categories?provider_id=eq.${ids.provider}&category_id=eq.${ids.categoryElectrical}`, { key: serviceRoleKey, token: serviceRoleKey, method: 'DELETE', headers: { prefer: 'return=minimal' } });
  await rest(`/provider_profiles?user_id=eq.${ids.provider}`, { key: serviceRoleKey, token: serviceRoleKey, method: 'PATCH', headers: { prefer: 'return=minimal' }, body: { is_available: true, bio: 'Friendly local plumbing service for homes and small shops.' } });
  await rest(`/profiles?id=eq.${ids.provider}`, { key: serviceRoleKey, token: serviceRoleKey, method: 'PATCH', headers: { prefer: 'return=minimal' }, body: { display_name: 'Ahmad Plumbing', phone: '+60 12 000 0102', whatsapp: '+60 12 000 0102' } });
}

const providerToken = await login('provider@example.test');
const adminToken = await login('admin@example.test');
try {
  const initial = await rest(`/provider_categories?provider_id=eq.${ids.provider}&select=category_id,status`, { token: providerToken });
  pass('provider sees existing categories as approved', initial.ok && initial.data.some((row) => row.category_id === ids.categoryPlumbing && row.status === 'approved'));

  const directEscalation = await rest('/provider_categories', { token: providerToken, method: 'POST', headers: { prefer: 'return=representation' }, body: { provider_id: ids.provider, category_id: ids.categoryElectrical, status: 'approved' } });
  pass('provider cannot insert an approved category directly', !directEscalation.ok);

  const submitted = await rpc('submit_provider_category_changes', { p_category_ids: [ids.categoryPlumbing, ids.categoryHandyman, ids.categoryElectrical] }, providerToken);
  pass('provider category change RPC accepts a new request', submitted.ok, JSON.stringify(submitted.data));
  const pending = await rest(`/provider_categories?provider_id=eq.${ids.provider}&category_id=eq.${ids.categoryElectrical}&select=status,reviewed_at,reviewed_by,admin_note`, { token: providerToken });
  pass('new category is pending with no review fields', pending.ok && pending.data.length === 1 && pending.data[0].status === 'pending' && pending.data[0].reviewed_at === null && pending.data[0].reviewed_by === null);

  const hiddenFeed = await rest('/public_job_feed?select=id,category_id&order=id', { token: providerToken });
  pass('pending category is excluded from provider feed', hiddenFeed.ok && !hiddenFeed.data.some((row) => row.id === ids.jobElectrical));

  const reviewed = await rpc('review_provider_category', { p_provider_id: ids.provider, p_category_id: ids.categoryElectrical, p_status: 'approved', p_admin_note: 'Electrical service evidence approved.' }, adminToken);
  pass('admin category review approves a pending request', reviewed.ok, JSON.stringify(reviewed.data));
  const feed = await rest('/public_job_feed?select=id,category_id&order=id', { token: providerToken });
  pass('approved category appears in provider feed', feed.ok && feed.data.some((row) => row.id === ids.jobElectrical));
  const categoryNotification = await rest(`/notifications?user_id=eq.${ids.provider}&type=eq.provider_category_approved&select=type,reference_id`, { token: providerToken });
  pass('category approval creates a provider notification', categoryNotification.ok && categoryNotification.data.some((row) => row.reference_id === ids.categoryElectrical));

  const removed = await rpc('submit_provider_category_changes', { p_category_ids: [ids.categoryPlumbing, ids.categoryHandyman] }, providerToken);
  pass('category removal is immediate', removed.ok);
  const requestedAgain = await rpc('submit_provider_category_changes', { p_category_ids: [ids.categoryPlumbing, ids.categoryHandyman, ids.categoryElectrical] }, providerToken);
  pass('removed category can be requested again', requestedAgain.ok);
  const rejectResult = await rpc('review_provider_category', { p_provider_id: ids.provider, p_category_id: ids.categoryElectrical, p_status: 'rejected', p_admin_note: 'Please add a clearer certificate.' }, adminToken);
  pass('admin can reject a category with a note', rejectResult.ok);
  const resubmitted = await rpc('submit_provider_category_changes', { p_category_ids: [ids.categoryPlumbing, ids.categoryHandyman, ids.categoryElectrical] }, providerToken);
  pass('rejected category can be resubmitted', resubmitted.ok);
  const resubmittedRow = await rest(`/provider_categories?provider_id=eq.${ids.provider}&category_id=eq.${ids.categoryElectrical}&select=status,admin_note`, { token: providerToken });
  pass('resubmission clears rejection note and returns to pending', resubmittedRow.ok && resubmittedRow.data[0]?.status === 'pending' && resubmittedRow.data[0]?.admin_note === null);

  const unavailable = await rpc('set_provider_availability', { p_is_available: false }, providerToken);
  pass('availability off persists through RPC', unavailable.ok && unavailable.data?.is_available === false);
  const unavailableFeed = await rest('/public_job_feed?select=id', { token: providerToken });
  pass('unavailable provider sees no new jobs', unavailableFeed.ok && unavailableFeed.data.length === 0);
  const assigned = await rest(`/jobs?select=id,status&id=eq.${ids.assignedJob}`, { token: providerToken });
  pass('unavailable provider still reads an assigned job', assigned.ok && assigned.data.some((row) => row.id === ids.assignedJob));
  const available = await rpc('set_provider_availability', { p_is_available: true }, providerToken);
  pass('availability on can be restored', available.ok && available.data?.is_available === true);

  const profile = await rpc('update_provider_profile', { p_display_name: 'Ahmad Plumbing Test', p_bio: 'Friendly local plumbing service for homes and small shops.', p_phone: '+60 12 999 0102', p_whatsapp: '+60 12 999 0102', p_area_ids: [ids.areaMountAustin, ids.areaTamanMolek], p_work_photo_paths: [] }, providerToken);
  pass('profile update RPC persists public fields', profile.ok, JSON.stringify(profile.data));
  const profileRow = await rest(`/profiles?id=eq.${ids.provider}&select=display_name,phone,whatsapp`, { token: providerToken });
  pass('provider can read its updated profile fields', profileRow.ok && profileRow.data[0]?.display_name === 'Ahmad Plumbing Test');
} finally {
  await cleanup();
}
console.log(`Provider profile local integration validation passed: ${checks.length} checks.`);