/*
 * Local Admin Web integration checks. This runner deliberately uses the
 * seeded Admin Auth identity and anon key, never service_role, so it mirrors
 * the browser's RLS boundary. Values come from `supabase status --output env`.
 */

const apiUrl = process.env.SUPABASE_LOCAL_API_URL;
const anonKey = process.env.SUPABASE_LOCAL_ANON_KEY;
if (!apiUrl || !anonKey) {
  throw new Error('Set SUPABASE_LOCAL_API_URL and SUPABASE_LOCAL_ANON_KEY from `supabase status --output env`.');
}

const baseUrl = apiUrl.replace(/\/$/, '');

async function request(path, { token = anonKey, method = 'GET', body, headers = {} } = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      apikey: anonKey,
      Authorization: `Bearer ${token}`,
      ...headers,
      ...(body !== undefined && !headers['Content-Type'] ? { 'Content-Type': 'application/json' } : {}),
    },
    body: body === undefined ? undefined : typeof body === 'string' ? body : JSON.stringify(body),
  });
  const raw = await response.text();
  let parsed = raw;
  try {
    parsed = raw ? JSON.parse(raw) : null;
  } catch {
    // Keep text responses (for example a signed URL or Storage fixture).
  }
  if (!response.ok) {
    const detail = typeof parsed === 'string' ? parsed : JSON.stringify(parsed);
    throw new Error(`${method} ${path} returned HTTP ${response.status}: ${detail}`);
  }
  return parsed;
}

async function login(email, password) {
  const result = await request('/auth/v1/token?grant_type=password', {
    method: 'POST',
    body: { email, password },
  });
  return { token: result.access_token, id: result.user.id, email: result.user.email };
}

async function rpc(name, body, token) {
  return request(`/rest/v1/rpc/${name}`, { method: 'POST', token, body });
}

async function table(path, token) {
  return request(`/rest/v1/${path}`, { token });
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
  console.log(`PASS ${message}`);
}

function storagePath(path) {
  return path.split('/').map((segment) => encodeURIComponent(segment)).join('/');
}

const admin = await login('admin@example.test', 'local-dev-only');
assert(Boolean(admin.token), 'local Admin Auth session is created');

const profile = await table(`profiles?id=eq.${admin.id}&select=id,is_admin,account_status`, admin.token);
assert(profile.length === 1 && profile[0].is_admin === true && profile[0].account_status === 'active', 'Admin session is authorized by the profile is_admin guard');

const users = await rpc('admin_list_users', {}, admin.token);
assert(Array.isArray(users) && users.some((user) => user.email === 'admin@example.test') && users.some((user) => user.email === 'pending-provider@example.test'), 'Admin directory RPC exposes local auth emails without exposing auth.users to the browser');

const [providers, jobs, bids, reports, auditBefore] = await Promise.all([
  table('provider_profiles?select=user_id,verification_status', admin.token),
  table('jobs?select=id,status,full_address', admin.token),
  table('bids?select=id,status,amount', admin.token),
  table('reports?select=id,status,reason_code', admin.token),
  table('admin_audit_events?select=id,action,target_type,target_id&order=created_at.desc', admin.token),
]);
assert(providers.length >= 3, 'Admin can read real provider verification records');
assert(jobs.length >= 4 && jobs.some((job) => job.full_address), 'Admin can read real jobs including protected address fields through RLS');
assert(bids.length >= 4, 'Admin can read real bids and amounts');
assert(reports.length >= 1 && reports.some((report) => report.reason_code === 'work_quality'), 'Admin can read real reports');
assert(auditBefore.length >= 2, 'Admin can read the real audit log table');

const providerId = '00000000-0000-0000-0000-000000000103';
const signedPath = `${providerId}/admin-local-signed-url.txt`;
await request(`/storage/v1/object/provider-verifications/${storagePath(signedPath)}`, {
  method: 'POST',
  token: admin.token,
  headers: { 'Content-Type': 'text/plain', 'x-upsert': 'true' },
  body: 'local admin test',
});
const signed = await request(`/storage/v1/object/sign/provider-verifications/${storagePath(signedPath)}`, {
  method: 'POST',
  token: admin.token,
  body: { expiresIn: 300 },
});
assert(Boolean(signed?.signedURL || signed?.signedUrl), 'Admin can create a short-lived provider verification signed URL');
await request(`/storage/v1/object/provider-verifications/${storagePath(signedPath)}`, { method: 'DELETE', token: admin.token });
assert(true, 'Admin verification fixture is removed after signed URL validation');

const approved = await rpc('admin_review_provider', { p_provider_id: providerId, p_status: 'approved', p_admin_note: 'Local Admin integration check.' }, admin.token);
assert(approved?.status === 'approved', 'Admin approve RPC updates provider status atomically');
const pending = await rpc('admin_review_provider', { p_provider_id: providerId, p_status: 'pending', p_admin_note: null }, admin.token);
assert(pending?.status === 'pending', 'Admin provider fixture is restored to pending');

const suspended = await rpc('admin_update_account_status', { p_user_id: '00000000-0000-0000-0000-000000000101', p_status: 'suspended' }, admin.token);
assert(suspended?.status === 'suspended', 'Admin suspend-user RPC writes the real profile');
const restored = await rpc('admin_update_account_status', { p_user_id: '00000000-0000-0000-0000-000000000101', p_status: 'active' }, admin.token);
assert(restored?.status === 'active', 'Admin restore-user RPC writes the real profile');

const reviewing = await rpc('admin_review_report', { p_report_id: '00000000-0000-0000-0000-000000000501', p_status: 'reviewing', p_admin_note: 'Local review check.' }, admin.token);
assert(reviewing?.status === 'reviewing', 'Admin report-review RPC updates the real report');
const reopened = await rpc('admin_review_report', { p_report_id: '00000000-0000-0000-0000-000000000501', p_status: 'open', p_admin_note: null }, admin.token);
assert(reopened?.status === 'open', 'Admin report fixture is restored to open');

const auditAfter = await table('admin_audit_events?select=id,action,target_type,target_id&order=created_at.desc', admin.token);
assert(auditAfter.length >= auditBefore.length + 6, 'Admin moderation RPCs append attributable audit events');

console.log(`Admin local integration validation passed: ${auditAfter.length - auditBefore.length} audit events recorded in this run.`);
