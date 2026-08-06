import type {
  AccountStatus,
  AdminAuditEvent,
  AdminBid,
  AdminData,
  AdminCategoryRequest,
  AdminJob,
  AdminProvider,
  AdminReport,
  AdminUser,
  BidStatus,
  CategoryRequestStatus,
  JobStatus,
  ProviderStatus,
  ReportStatus,
} from './admin-data';
import { getSupabaseClient } from './supabase';

type Row = Record<string, unknown>;

export interface AdminSession {
  id: string;
  email: string;
  name: string;
}

function asRows(value: unknown): Row[] {
  return Array.isArray(value) ? value.filter((item): item is Row => !!item && typeof item === 'object') : [];
}

function text(value: unknown, fallback = ''): string {
  return typeof value === 'string' && value.length > 0 ? value : fallback;
}

function numberValue(value: unknown, fallback = 0): number {
  const parsed = typeof value === 'number' ? value : Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function formatDate(value: unknown): string {
  if (!value) return '—';
  const date = new Date(String(value));
  return Number.isNaN(date.getTime())
    ? String(value)
    : new Intl.DateTimeFormat('en-MY', { dateStyle: 'medium', timeStyle: 'short' }).format(date);
}

async function read<T>(request: PromiseLike<{ data: T | null; error: { message: string } | null }>): Promise<T> {
  const result = await request;
  if (result.error) throw new Error(result.error.message);
  return result.data as T;
}

async function requireAdminProfile(userId: string): Promise<Row> {
  const client = getSupabaseClient();
  const profile = await read<Row | null>(
    client.from('profiles').select('id, full_name, display_name, account_status, is_admin').eq('id', userId).maybeSingle(),
  );
  if (!profile || profile.is_admin !== true || profile.account_status !== 'active') {
    throw new Error('This account is not an active Ofrivo Admin.');
  }
  return profile;
}

export async function signInAdmin(email: string, password: string): Promise<AdminSession> {
  const client = getSupabaseClient();
  const result = await client.auth.signInWithPassword({ email: email.trim(), password });
  if (result.error || !result.data.user) throw new Error(result.error?.message ?? 'Admin sign-in failed.');
  const profile = await requireAdminProfile(result.data.user.id);
  return {
    id: result.data.user.id,
    email: text(result.data.user.email, email.trim()),
    name: text(profile.display_name, text(profile.full_name, 'Ofrivo Admin')),
  };
}

export async function restoreAdminSession(): Promise<AdminSession | null> {
  const client = getSupabaseClient();
  const result = await client.auth.getSession();
  if (result.error) throw new Error(result.error.message);
  const user = result.data.session?.user;
  if (!user) return null;
  const profile = await requireAdminProfile(user.id);
  return {
    id: user.id,
    email: text(user.email, 'admin'),
    name: text(profile.display_name, text(profile.full_name, 'Ofrivo Admin')),
  };
}

export async function signOutAdmin(): Promise<void> {
  const client = getSupabaseClient();
  const result = await client.auth.signOut();
  if (result.error) throw new Error(result.error.message);
}

async function signedEvidence(path: string, label: string): Promise<{ label: string; path: string; url: string | null }> {
  try {
    const result = await getSupabaseClient().storage.from('provider-verifications').createSignedUrl(path, 300);
    return { label, path, url: result.error ? null : result.data?.signedUrl ?? null };
  } catch {
    return { label, path, url: null };
  }
}

export async function loadAdminData(): Promise<AdminData> {
  const client = getSupabaseClient();
  const [usersRaw, profilesRaw, providersRaw, verificationsRaw, providerCategoriesRaw, providerAreasRaw, categoriesRaw, areasRaw, jobsRaw, bidsRaw, reportsRaw, auditRaw] = await Promise.all([
    read<unknown>(client.rpc('admin_list_users')),
    read<unknown>(client.from('profiles').select('id, full_name, display_name, account_status, is_admin, created_at')),
    read<unknown>(client.from('provider_profiles').select('user_id, bio, verification_status, rating_average, rating_count, completed_jobs, updated_at, approved_at, suspended_at')),
    read<unknown>(client.from('provider_verifications').select('provider_id, ic_front_path, ic_back_path, selfie_path, ssm_path, certificate_paths, status, submitted_at, reviewed_at, admin_note').order('submitted_at', { ascending: false })),
    read<unknown>(client.from('provider_categories').select('provider_id, category_id, status, submitted_at, reviewed_at, admin_note')),
    read<unknown>(client.from('provider_areas').select('provider_id, area_id')),
    read<unknown>(client.from('service_categories').select('id, name_en, is_active, sort_order').order('sort_order')),
    read<unknown>(client.from('areas').select('id, area_name, city, is_active, sort_order').order('sort_order')),
    read<unknown>(client.from('jobs').select('id, customer_id, category_id, area_id, title, budget_amount, status, created_at, full_address').order('created_at', { ascending: false })),
    read<unknown>(client.from('bids').select('id, job_id, provider_id, amount, status, created_at').order('created_at', { ascending: false })),
    read<unknown>(client.from('reports').select('id, job_id, reporter_id, reported_user_id, reason_code, description, status, created_at, admin_note').order('created_at', { ascending: false })),
    read<unknown>(client.from('admin_audit_events').select('id, actor_id, action, target_type, target_id, created_at').order('created_at', { ascending: false }).limit(100)),
  ]);

  const users = asRows(usersRaw);
  const profiles = asRows(profilesRaw);
  const providerProfiles = asRows(providersRaw);
  const verifications = asRows(verificationsRaw);
  const providerCategories = asRows(providerCategoriesRaw);
  const providerAreas = asRows(providerAreasRaw);
  const categories = asRows(categoriesRaw);
  const areas = asRows(areasRaw);
  const jobs = asRows(jobsRaw);
  const bids = asRows(bidsRaw);
  const reports = asRows(reportsRaw);
  const audit = asRows(auditRaw);

  const userById = new Map<string, Row>();
  users.forEach((user) => userById.set(text(user.id), user));
  profiles.forEach((profile) => {
    const id = text(profile.id);
    if (id && !userById.has(id)) userById.set(id, profile);
  });
  const categoryById = new Map(categories.map((category) => [text(category.id), text(category.name_en, text(category.id))]));
  const areaById = new Map(areas.map((area) => [text(area.id), text(area.area_name, text(area.id))]));
  const providerById = new Map(providerProfiles.map((provider) => [text(provider.user_id), provider]));
  const verificationByProvider = new Map<string, Row>();
  verifications.forEach((verification) => {
    const id = text(verification.provider_id);
    if (id && !verificationByProvider.has(id)) verificationByProvider.set(id, verification);
  });
  const jobsById = new Map(jobs.map((job) => [text(job.id), job]));
  const bidCountByJob = new Map<string, number>();
  bids.forEach((bid) => {
    const id = text(bid.job_id);
    bidCountByJob.set(id, (bidCountByJob.get(id) ?? 0) + 1);
  });
  const jobsByCustomer = new Map<string, number>();
  jobs.forEach((job) => {
    const id = text(job.customer_id);
    jobsByCustomer.set(id, (jobsByCustomer.get(id) ?? 0) + 1);
  });
  const bidsByProvider = new Map<string, number>();
  bids.forEach((bid) => {
    const id = text(bid.provider_id);
    bidsByProvider.set(id, (bidsByProvider.get(id) ?? 0) + 1);
  });
  const providerName = (id: string): string => {
    const user = userById.get(id);
    return text(user?.display_name, text(user?.full_name, text(user?.email, id)));
  };
  const evidenceLinksByProvider = await Promise.all(providerProfiles.map(async (provider) => {
    const verification = verificationByProvider.get(text(provider.user_id));
    if (!verification) return [text(provider.user_id), [] as { label: string; path: string; url: string | null }[]] as const;
    const paths: { label: string; path: string }[] = [
      ['IC front', text(verification.ic_front_path)],
      ['IC back', text(verification.ic_back_path)],
      ['Selfie', text(verification.selfie_path)],
      ['SSM certificate', text(verification.ssm_path)],
    ].filter((item): item is [string, string] => item[1].length > 0).map(([label, path]) => ({ label, path }));
    const certificatePaths = Array.isArray(verification.certificate_paths) ? verification.certificate_paths : [];
    certificatePaths.forEach((path, index) => {
      if (typeof path === 'string' && path.length > 0) paths.push({ label: `Certificate ${index + 1}`, path });
    });
    return [text(provider.user_id), await Promise.all(paths.map((item) => signedEvidence(item.path, item.label)))] as const;
  }));
  const evidenceLinks = new Map(evidenceLinksByProvider);

  const adminProviders: AdminProvider[] = await Promise.all(providerProfiles.map(async (provider) => {
    const id = text(provider.user_id);
    const verification = verificationByProvider.get(id);
    const categoriesForProvider = providerCategories.filter((item) => text(item.provider_id) === id).map((item) => categoryById.get(text(item.category_id)) ?? text(item.category_id));
    const areasForProvider = providerAreas.filter((item) => text(item.provider_id) === id).map((item) => areaById.get(text(item.area_id)) ?? text(item.area_id));
    const user = userById.get(id);
    return {
      id,
      name: providerName(id),
      email: text(user?.email, `${id}@local.invalid`),
      category: categoriesForProvider.join(', ') || 'Unassigned',
      area: areasForProvider.join(', ') || 'Unassigned',
      status: text(provider.verification_status, 'not_applied') as ProviderStatus,
      submittedAt: formatDate(verification?.submitted_at ?? provider.updated_at),
      rating: numberValue(provider.rating_average),
      completedJobs: numberValue(provider.completed_jobs),
      bio: text(provider.bio, 'No provider bio supplied.'),
      evidence: (evidenceLinks.get(id) ?? []).map((item) => item.label),
      evidenceLinks: evidenceLinks.get(id) ?? [],
    };
  }));

  const categoryRequests: AdminCategoryRequest[] = providerCategories.map((item) => {
    const providerId = text(item.provider_id);
    const categoryId = text(item.category_id);
    const user = userById.get(providerId);
    return {
      id: `${providerId}:${categoryId}`,
      providerId,
      providerName: providerName(providerId),
      providerEmail: text(user?.email, `${providerId}@local.invalid`),
      categoryId,
      category: categoryById.get(categoryId) ?? categoryId,
      status: text(item.status, 'approved') as CategoryRequestStatus,
      submittedAt: formatDate(item.submitted_at),
      reviewedAt: formatDate(item.reviewed_at),
      adminNote: text(item.admin_note),
    };
  });
  const adminUsers: AdminUser[] = users.map((user) => {
    const id = text(user.id);
    const role = user.is_admin === true ? 'admin' : providerById.has(id) ? 'provider' : 'customer';
    return {
      id,
      name: text(user.display_name, text(user.full_name, text(user.email, id))),
      email: text(user.email, `${id}@local.invalid`),
      role,
      status: text(user.account_status, 'active') as AccountStatus,
      joinedAt: formatDate(user.created_at),
      jobs: jobsByCustomer.get(id) ?? 0,
      bids: bidsByProvider.get(id) ?? 0,
    };
  });

  const adminJobs: AdminJob[] = jobs.map((job) => ({
    id: text(job.id),
    title: text(job.title, 'Untitled job'),
    customer: providerName(text(job.customer_id)),
    area: areaById.get(text(job.area_id)) ?? text(job.area_id),
    category: categoryById.get(text(job.category_id)) ?? text(job.category_id),
    budget: numberValue(job.budget_amount),
    status: text(job.status, 'draft') as JobStatus,
    bids: bidCountByJob.get(text(job.id)) ?? 0,
    createdAt: formatDate(job.created_at),
    fullAddress: text(job.full_address, 'Address unavailable'),
  }));

  const adminBids: AdminBid[] = bids.map((bid) => {
    const job = jobsById.get(text(bid.job_id));
    return {
      id: text(bid.id),
      jobTitle: text(job?.title, text(bid.job_id)),
      provider: providerName(text(bid.provider_id)),
      customer: providerName(text(job?.customer_id)),
      amount: numberValue(bid.amount),
      status: text(bid.status, 'pending') as BidStatus,
      createdAt: formatDate(bid.created_at),
    };
  });

  const adminReports: AdminReport[] = reports.map((report) => {
    const job = jobsById.get(text(report.job_id));
    return {
      id: text(report.id),
      jobTitle: text(job?.title, text(report.job_id)),
      reporter: providerName(text(report.reporter_id)),
      reportedUser: providerName(text(report.reported_user_id)),
      reason: text(report.reason_code, 'Unspecified report'),
      description: text(report.description, 'No report description supplied.'),
      status: text(report.status, 'open') as ReportStatus,
      createdAt: formatDate(report.created_at),
    };
  });

  const adminAudit: AdminAuditEvent[] = audit.map((event) => ({
    id: text(event.id),
    actor: providerName(text(event.actor_id)),
    action: text(event.action, 'Admin action'),
    target: `${text(event.target_type, 'record')}:${text(event.target_id, 'unknown')}`,
    createdAt: formatDate(event.created_at),
  }));

  return {
    categoryRequests,
    providers: adminProviders,
    users: adminUsers,
    jobs: adminJobs,
    bids: adminBids,
    reports: adminReports,
    audit: adminAudit,
    categories: categories.filter((item) => item.is_active !== false).map((item) => text(item.name_en, text(item.id))),
    areas: areas.filter((item) => item.is_active !== false).map((item) => text(item.area_name, text(item.id))),
  };
}

export async function reviewProvider(providerId: string, status: ProviderStatus): Promise<void> {
  await read(getSupabaseClient().rpc('admin_review_provider', { p_provider_id: providerId, p_status: status, p_admin_note: null }));
}

export async function updateAccountStatus(userId: string, status: AccountStatus): Promise<void> {
  await read(getSupabaseClient().rpc('admin_update_account_status', { p_user_id: userId, p_status: status }));
}

export async function reviewReport(reportId: string, status: ReportStatus): Promise<void> {
  await read(getSupabaseClient().rpc('admin_review_report', { p_report_id: reportId, p_status: status, p_admin_note: null }));
}
export async function reviewProviderCategory(
  providerId: string,
  categoryId: string,
  status: CategoryRequestStatus,
  adminNote: string | null = null,
): Promise<void> {
  await read(getSupabaseClient().rpc('review_provider_category', {
    p_provider_id: providerId,
    p_category_id: categoryId,
    p_status: status,
    p_admin_note: adminNote,
  }));
}
