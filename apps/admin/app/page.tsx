'use client';

import { useCallback, useEffect, useState } from 'react';
import type { FormEvent, ReactNode } from 'react';

import {
  type AccountStatus,
  type AdminData,
  type AdminCategoryRequest,
  type AdminJob,
  type AdminProvider,
  type AdminReport,
  type AdminUser,
  type BidStatus,
  type CategoryRequestStatus,
  type ProviderStatus,
  type ReportStatus,
} from '../lib/admin-data';
import {
  loadAdminData,
  restoreAdminSession,
  reviewProvider,
  reviewProviderCategory,
  reviewReport,
  signInAdmin,
  signOutAdmin,
  updateAccountStatus,
  type AdminSession,
} from '../lib/admin-repository';
import { isLocalSupabaseConfigured } from '../lib/supabase';

type AdminTab = 'Dashboard' | 'Pending Providers' | 'Users' | 'Jobs' | 'Bids' | 'Reports' | 'Categories' | 'Areas' | 'Audit Log' | 'System Settings' | 'Category Requests';
type AdminLayout = 'desktop' | 'tablet' | 'mobile';

const navigation: { id: AdminTab; label: string; hint: string }[] = [
  { id: 'Dashboard', label: 'Dashboard', hint: 'Operations overview' },
  { id: 'Pending Providers', label: 'Pending Providers', hint: 'Review applications' },
  { id: 'Category Requests', label: 'Category Requests', hint: 'Approve new services' },
  { id: 'Users', label: 'Users', hint: 'Account controls' },
  { id: 'Jobs', label: 'Jobs', hint: 'Marketplace activity' },
  { id: 'Bids', label: 'Bids', hint: 'Offer monitoring' },
  { id: 'Reports', label: 'Reports', hint: 'Safety queue' },
  { id: 'Categories', label: 'Categories', hint: 'Service taxonomy' },
  { id: 'Areas', label: 'Areas', hint: 'Coverage zones' },
  { id: 'Audit Log', label: 'Audit Log', hint: 'Admin activity' },
  { id: 'System Settings', label: 'System Settings', hint: 'Runtime controls' },
];

export default function AdminHome() {
  const [data, setData] = useState<AdminData | null>(null);
  const [activeTab, setActiveTab] = useState<AdminTab>('Dashboard');
  const [session, setSession] = useState<AdminSession | null>(null);
  const [loading, setLoading] = useState(isLocalSupabaseConfigured());
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  const refresh = useCallback(async () => setData(await loadAdminData()), []);

  useEffect(() => {
    if (!isLocalSupabaseConfigured()) return;
    let active = true;
    void restoreAdminSession()
      .then(async (restored) => {
        if (!active || !restored) return;
        setSession(restored);
        await refresh();
      })
      .catch((reason: unknown) => {
        if (active) setError(reason instanceof Error ? reason.message : 'Unable to restore the local Admin session.');
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [refresh]);

  const handleLogin = async (email: string, password: string) => {
    setError(null);
    setLoading(true);
    try {
      const nextSession = await signInAdmin(email, password);
      setSession(nextSession);
      await refresh();
    } catch (reason: unknown) {
      setError(reason instanceof Error ? reason.message : 'Admin sign-in failed.');
    } finally {
      setLoading(false);
    }
  };

  const mutate = async (message: string, operation: () => Promise<void>) => {
    setError(null);
    setLoading(true);
    try {
      await operation();
      await refresh();
      setToast(message);
      window.setTimeout(() => setToast(null), 3200);
    } catch (reason: unknown) {
      setError(reason instanceof Error ? reason.message : 'Admin operation failed.');
    } finally {
      setLoading(false);
    }
  };

  const providerAction = (provider: AdminProvider, status: ProviderStatus) => {
    const label = status === 'approved' ? 'approved' : status === 'rejected' ? 'rejected' : 'suspended';
    void mutate(`Provider ${provider.name} ${label}.`, () => reviewProvider(provider.id, status));
  };

  const categoryAction = (request: AdminCategoryRequest, status: CategoryRequestStatus, note: string | null) => {
    const label = status === 'approved' ? 'approved' : 'rejected';
    void mutate(`Category ${request.category} for ${request.providerName} ${label}.`, () => reviewProviderCategory(request.providerId, request.categoryId, status, note));
  };
  const userAction = (user: AdminUser, status: AccountStatus) => {
    const label = status === 'suspended' ? 'suspended' : 'restored';
    void mutate(`Account ${user.name} ${label}.`, () => updateAccountStatus(user.id, status));
  };

  const reportAction = (report: AdminReport, status: ReportStatus) => {
    void mutate(`Report marked ${status}.`, () => reviewReport(report.id, status));
  };

  if (!isLocalSupabaseConfigured()) return <AdminNotConfigured />;
  if (!session) return <AdminLogin onLogin={handleLogin} loading={loading} error={error} />;
  if (loading || !data) return <AdminLoading message={error ?? 'Loading local Supabase data…'} />;

  const selectTab = (tab: AdminTab) => {
    setActiveTab(tab);
    setMobileNavOpen(false);
  };

  const signOut = () => {
    void signOutAdmin().then(() => { setSession(null); setData(null); }).catch((reason: unknown) => setError(reason instanceof Error ? reason.message : 'Sign out failed.'));
  };

  if (!isLocalSupabaseConfigured()) return <AdminNotConfigured />;
  if (!session) return <AdminLogin onLogin={handleLogin} loading={loading} error={error} />;
  if (loading || !data) return <AdminLoading message={error ?? 'Loading local Supabase data…'} />;

  const current = navigation.find((item) => item.id === activeTab) ?? navigation[0];
  const renderContent = (layout: AdminLayout) => <>
    {activeTab === 'Dashboard' && <DashboardView data={data} onNavigate={selectTab} />}
    {activeTab === 'Pending Providers' && <ProvidersView providers={data.providers} onAction={providerAction} />}
    {activeTab === 'Category Requests' && <CategoryRequestsView requests={data.categoryRequests} onAction={categoryAction} />}
    {activeTab === 'Users' && <UsersView users={data.users} onAction={userAction} />}
    {activeTab === 'Jobs' && <JobsView jobs={data.jobs} layout={layout} />}
    {activeTab === 'Bids' && <BidsView bids={data.bids} />}
    {activeTab === 'Reports' && <ReportsView reports={data.reports} onAction={reportAction} />}
    {activeTab === 'Categories' && <TaxonomyView title="Categories" items={data.categories} description="Service categories used by customers and approved providers." />}
    {activeTab === 'Areas' && <TaxonomyView title="Areas" items={data.areas} description="Johor Bahru coverage zones available to matching providers." />}
    {activeTab === 'Audit Log' && <AuditView audit={data.audit} />}
    {activeTab === 'System Settings' && <SettingsView />}
  </>;

  return (
    <>
      <div className="hidden min-h-screen lg:flex">
        <AdminSidebar activeTab={activeTab} onNavigate={selectTab} variant="desktop" />
        <AdminWorkspace current={current} session={session} error={error} toast={toast} onSignOut={signOut}>{renderContent('desktop')}</AdminWorkspace>
      </div>
      <div className="hidden min-h-screen md:flex lg:hidden">
        <AdminSidebar activeTab={activeTab} onNavigate={selectTab} variant="tablet" />
        <AdminWorkspace current={current} session={session} error={error} toast={toast} onSignOut={signOut}>{renderContent('tablet')}</AdminWorkspace>
      </div>
      <div className="min-h-screen md:hidden">
        <MobileAdminShell activeTab={activeTab} current={current} session={session} error={error} toast={toast} navOpen={mobileNavOpen} onToggleNav={() => setMobileNavOpen((open) => !open)} onNavigate={selectTab} onSignOut={signOut}>{renderContent('mobile')}</MobileAdminShell>
      </div>
    </>
  );
}

function AdminSidebar({ activeTab, onNavigate, variant }: { activeTab: AdminTab; onNavigate: (tab: AdminTab) => void; variant: 'desktop' | 'tablet' }) {
  const width = variant === 'desktop' ? 'w-72' : 'w-60';
  return <aside className={`min-h-screen shrink-0 overflow-y-auto border-r border-slate-200 bg-white px-5 py-6 ${width}`}>
    <div className="mb-8 flex items-center gap-3">
      <div className="grid h-10 w-10 place-items-center rounded-xl bg-tealbrand text-lg font-black text-white">O</div>
      <div><p className="font-extrabold tracking-tight">Ofrivo</p><p className="text-xs text-slate-500">Operations console</p></div>
    </div>
    <nav aria-label="Admin navigation" className="grid gap-1">
      {navigation.map((item) => <button key={item.id} type="button" onClick={() => onNavigate(item.id)} className={`rounded-xl px-3 py-2.5 text-left text-sm font-semibold transition ${activeTab === item.id ? 'bg-teal-50 text-tealbrand' : 'text-slate-600 hover:bg-slate-50'}`}>
        <span className="block">{item.label}</span><span className={`mt-0.5 block text-[11px] font-medium ${activeTab === item.id ? 'text-teal-700' : 'text-slate-400'}`}>{item.hint}</span>
      </button>)}
    </nav>
    <div className="mt-8 rounded-2xl bg-slate-50 p-4 text-sm text-slate-600"><p className="font-bold text-slate-800">Local Supabase Admin</p><p className="mt-1">Authenticated data and moderation actions use local RLS-protected tables. No service-role key is sent to this browser.</p></div>
  </aside>;
}

function AdminWorkspace({ current, session, error, toast, onSignOut, children }: { current: { label: string; hint: string }; session: AdminSession; error: string | null; toast: string | null; onSignOut: () => void; children: ReactNode }) {
  return <section className="min-w-0 flex-1 p-5 sm:p-8">
    <header className="mb-8 flex flex-wrap items-start justify-between gap-4">
      <div><p className="text-sm font-semibold text-tealbrand">{current.hint}</p><h1 className="mt-1 text-3xl font-black tracking-tight">{current.label}</h1><p className="mt-2 text-slate-500">Moderate providers, protect users, and keep marketplace activity healthy.</p></div>
      <div className="flex items-center gap-3"><span className="rounded-full border border-emerald-200 bg-emerald-50 px-4 py-2 text-sm font-semibold text-emerald-700">{session.name} · local active</span><button type="button" onClick={onSignOut} className="rounded-full border border-slate-200 bg-white px-4 py-2 text-sm font-bold text-slate-600 hover:border-slate-300">Sign out</button></div>
    </header>
    {error && <div role="alert" className="mb-6 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-semibold text-red-800">{error}</div>}
    {children}
    {toast && <div role="status" className="fixed bottom-5 right-5 z-20 max-w-sm rounded-xl bg-slate-900 px-4 py-3 text-sm font-semibold text-white shadow-xl">{toast}</div>}
  </section>;
}

function MobileAdminShell({ activeTab, current, session, error, toast, navOpen, onToggleNav, onNavigate, onSignOut, children }: { activeTab: AdminTab; current: { label: string; hint: string }; session: AdminSession; error: string | null; toast: string | null; navOpen: boolean; onToggleNav: () => void; onNavigate: (tab: AdminTab) => void; onSignOut: () => void; children: ReactNode }) {
  return <main className="min-h-screen bg-page">
    <header className="sticky top-0 z-20 flex items-center gap-3 border-b border-slate-200 bg-white px-4 py-3 shadow-sm">
      <button type="button" onClick={onToggleNav} aria-label={navOpen ? 'Close admin navigation' : 'Open admin navigation'} aria-expanded={navOpen} className="grid h-10 w-10 place-items-center rounded-xl border border-slate-200 text-xl font-bold text-slate-700">{navOpen ? '×' : '☰'}</button>
      <div className="min-w-0 flex-1"><p className="truncate text-base font-black tracking-tight">Ofrivo Admin</p><p className="truncate text-xs font-semibold text-tealbrand">{current.label} · {current.hint}</p></div>
      <div className="hidden text-right"><p className="text-xs font-bold text-slate-700">{session.name}</p><p className="text-[10px] font-semibold text-emerald-700">Local active</p></div>
      <button type="button" onClick={onSignOut} aria-label="Sign out" className="rounded-xl border border-slate-200 px-3 py-2 text-xs font-bold text-slate-600">Sign out</button>
    </header>
    {navOpen && <div className="fixed inset-0 z-40" role="dialog" aria-modal="true" aria-label="Admin navigation"><button type="button" onClick={onToggleNav} aria-label="Close navigation" className="absolute inset-0 bg-slate-900/40" /><aside className="relative z-10 h-full w-[min(84vw,320px)] overflow-y-auto bg-white px-4 py-5 shadow-2xl"><div className="mb-6 flex items-center justify-between"><div><p className="font-black tracking-tight">Ofrivo Admin</p><p className="text-xs text-slate-500">Operations console</p></div><button type="button" onClick={onToggleNav} aria-label="Close navigation" className="grid h-9 w-9 place-items-center rounded-lg border border-slate-200 text-lg">×</button></div><nav aria-label="Admin navigation" className="grid gap-1">{navigation.map((item) => <button key={item.id} type="button" onClick={() => onNavigate(item.id)} className={`rounded-xl px-3 py-3 text-left text-sm font-semibold ${activeTab === item.id ? 'bg-teal-50 text-tealbrand' : 'text-slate-600 hover:bg-slate-50'}`}><span className="block">{item.label}</span><span className="mt-0.5 block text-[11px] font-medium text-slate-400">{item.hint}</span></button>)}</nav><div className="mt-7 rounded-2xl bg-slate-50 p-4 text-xs leading-5 text-slate-600">Authenticated local Supabase data and moderation actions are protected by RLS. No service-role key is sent to this browser.</div></aside></div>}
    <section className="min-w-0 p-4"><div className="mb-5"><p className="text-sm font-semibold text-tealbrand">{current.hint}</p><h1 className="mt-1 text-2xl font-black tracking-tight">{current.label}</h1><p className="mt-2 text-sm leading-5 text-slate-500">Moderate providers, protect users, and keep marketplace activity healthy.</p></div>{error && <div role="alert" className="mb-5 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-semibold text-red-800">{error}</div>}{children}{toast && <div role="status" className="fixed bottom-5 left-4 right-4 z-30 rounded-xl bg-slate-900 px-4 py-3 text-sm font-semibold text-white shadow-xl">{toast}</div>}</section>
  </main>;
}
function AdminNotConfigured() {
  return <main className="grid min-h-screen place-items-center bg-page px-5 py-10"><section className="w-full max-w-xl rounded-3xl border border-amber-200 bg-white p-8 shadow-sm"><h1 className="text-2xl font-black tracking-tight">Local Supabase is not configured</h1><p className="mt-3 text-sm leading-6 text-slate-600">Start the local stack, then expose only the local URL and anon key to the Admin process.</p><pre className="mt-5 overflow-x-auto rounded-2xl bg-slate-900 p-4 text-xs leading-6 text-slate-100">$env:NEXT_PUBLIC_SUPABASE_URL=&apos;http://127.0.0.1:54421&apos;{`\n`}$env:NEXT_PUBLIC_SUPABASE_ANON_KEY=&apos;(from supabase status)&apos;{`\n`}npm.cmd run dev</pre><p className="mt-4 text-xs text-slate-500">The service-role key is never accepted by this UI.</p></section></main>;
}

function AdminLoading({ message }: { message: string }) {
  return <main className="grid min-h-screen place-items-center bg-page px-5 py-10"><section className="rounded-3xl border border-slate-200 bg-white px-8 py-7 text-center shadow-sm"><p className="font-bold text-slate-800">Connecting to local Supabase…</p><p className="mt-2 text-sm text-slate-500">{message}</p></section></main>;
}

function AdminLogin({ onLogin, loading, error }: { onLogin: (email: string, password: string) => Promise<void>; loading: boolean; error: string | null }) {
  const [email, setEmail] = useState('admin@example.test');
  const [password, setPassword] = useState('local-dev-only');
  const submit = (event: FormEvent<HTMLFormElement>) => { event.preventDefault(); if (email.trim() && password.trim()) void onLogin(email, password); };
  return <main className="grid min-h-screen place-items-center bg-page px-5 py-10"><form onSubmit={submit} className="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-8 shadow-sm"><div className="mb-8 flex items-center gap-3"><div className="grid h-12 w-12 place-items-center rounded-2xl bg-tealbrand text-xl font-black text-white">O</div><div><p className="font-extrabold">Ofrivo Admin</p><p className="text-xs text-slate-500">Local Supabase operations console</p></div></div><h1 className="text-2xl font-black tracking-tight">Sign in to continue</h1><p className="mt-2 text-sm leading-6 text-slate-500">Sign in with the seeded local Admin identity. The profile `is_admin` flag and RLS are enforced by Supabase.</p><label className="mt-6 block text-sm font-bold text-slate-700">Email<input value={email} onChange={(event) => setEmail(event.target.value)} className="mt-2 w-full rounded-xl border border-slate-200 px-3 py-3 outline-none ring-teal-200 focus:ring-2" type="email" autoComplete="username" /></label><label className="mt-4 block text-sm font-bold text-slate-700">Password<input value={password} onChange={(event) => setPassword(event.target.value)} className="mt-2 w-full rounded-xl border border-slate-200 px-3 py-3 outline-none ring-teal-200 focus:ring-2" type="password" autoComplete="current-password" /></label>{error && <p role="alert" className="mt-4 rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm font-semibold text-red-800">{error}</p>}<button disabled={loading} type="submit" className="mt-6 w-full rounded-xl bg-tealbrand px-4 py-3 font-bold text-white hover:bg-teal-700 disabled:cursor-wait disabled:opacity-60">{loading ? 'Signing in…' : 'Sign in to local Admin'}</button><p className="mt-5 text-center text-xs text-slate-400">Only NEXT_PUBLIC Supabase URL and anon key are accepted by this browser.</p></form></main>;
}

function DashboardView({ data, onNavigate }: { data: AdminData; onNavigate: (tab: AdminTab) => void }) {
  const openReports = data.reports.filter((report) => report.status === 'open' || report.status === 'reviewing').length;
  const pendingProviders = data.providers.filter((provider) => provider.status === 'pending').length;
  const activeProviders = data.providers.filter((provider) => provider.status === 'approved').length;
  const openJobs = data.jobs.filter((job) => job.status === 'open').length;
  const jobsWithOffers = data.jobs.filter((job) => job.bids > 0).length;
  const acceptedBids = data.bids.filter((bid) => bid.status === 'accepted').length;
  const resolvedReports = data.reports.filter((report) => report.status === 'resolved' || report.status === 'dismissed').length;
  const percent = (value: number, total: number) => total > 0 ? Math.round((value / total) * 100) : 0;
  return <div className="space-y-6"><div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4"><MetricCard label="Open jobs" value={openJobs} note="Live marketplace requests" tone="emerald" /><MetricCard label="Pending providers" value={pendingProviders} note="Needs verification review" tone="orange" /><MetricCard label="Approved providers" value={activeProviders} note="Eligible to receive jobs" tone="blue" /><MetricCard label="Open reports" value={openReports} note="Safety queue" tone="red" /></div><div className="grid gap-6 xl:grid-cols-[1.4fr_1fr]"><section className="admin-card p-5"><SectionHeader title="Recent jobs" subtitle="Live jobs from the local Supabase database; private fields stay behind the admin RLS boundary." action={<button type="button" onClick={() => onNavigate('Jobs')} className="rounded-lg border border-slate-200 px-3 py-2 text-sm font-bold text-tealbrand">View all</button>} /><JobTable jobs={data.jobs.slice(0, 4)} compact /></section><section className="admin-card p-5"><SectionHeader title="Safety queue" subtitle="Review live moderation queues without losing the audit trail." /><div className="mt-5 grid gap-3"><QueueButton title="Pending provider verification" value={`${pendingProviders} waiting`} tone="orange" onClick={() => onNavigate('Pending Providers')} /><QueueButton title="Reports requiring review" value={`${openReports} open`} tone="red" onClick={() => onNavigate('Reports')} /><QueueButton title="Audit events" value={`${data.audit.length} recorded`} tone="blue" onClick={() => onNavigate('Audit Log')} /></div></section></div><section className="admin-card p-5"><SectionHeader title="Conversion pulse" subtitle="Calculated from the currently loaded local records." /><div className="mt-6 grid gap-5 md:grid-cols-3"><Progress label="Jobs with an offer" value={percent(jobsWithOffers, data.jobs.length)} note={`${jobsWithOffers} of ${data.jobs.length} jobs`} tone="teal" /><Progress label="Accepted offers" value={percent(acceptedBids, data.bids.length)} note={`${acceptedBids} of ${data.bids.length} bids`} tone="blue" /><Progress label="Reports resolved" value={percent(resolvedReports, data.reports.length)} note={`${resolvedReports} of ${data.reports.length} reports`} tone="orange" /></div></section></div>;
}

function ProvidersView({ providers, onAction }: { providers: AdminProvider[]; onAction: (provider: AdminProvider, status: ProviderStatus) => void }) {
  const [selectedId, setSelectedId] = useState(providers.find((provider) => provider.status === 'pending')?.id ?? providers[0]?.id);
  const selected = providers.find((provider) => provider.id === selectedId) ?? providers[0];
  return <div className="grid gap-6 xl:grid-cols-[1.3fr_0.8fr]"><section className="admin-card overflow-hidden"><div className="border-b border-slate-200 p-5"><SectionHeader title="Provider verification" subtitle="Review identity evidence and approve only complete applications." /></div><div className="overflow-x-auto"><table className="w-full min-w-[680px] text-left text-sm"><thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase tracking-wide text-slate-500"><tr><th className="px-5 py-3">Provider</th><th className="py-3">Service</th><th className="py-3">Submitted</th><th className="py-3">Status</th><th className="py-3 pr-5 text-right">Action</th></tr></thead><tbody>{providers.map((provider) => <tr key={provider.id} className={`border-b border-slate-100 last:border-0 ${selectedId === provider.id ? 'bg-teal-50/40' : ''}`}><td className="px-5 py-4"><button type="button" onClick={() => setSelectedId(provider.id)} className="text-left"><p className="font-bold text-slate-800">{provider.name}</p><p className="mt-1 text-xs text-slate-500">{provider.email}</p></button></td><td className="py-4"><p>{provider.category}</p><p className="mt-1 text-xs text-slate-500">{provider.area}</p></td><td className="py-4 text-slate-500">{provider.submittedAt}</td><td className="py-4"><StatusBadge value={provider.status} /></td><td className="py-4 pr-5 text-right"><button type="button" onClick={() => setSelectedId(provider.id)} className="font-bold text-tealbrand hover:underline">Review</button></td></tr>)}</tbody></table></div></section>{selected && <ProviderDetail provider={selected} onAction={onAction} />}</div>;
}

function ProviderDetail({ provider, onAction }: { provider: AdminProvider; onAction: (provider: AdminProvider, status: ProviderStatus) => void }) {
  const evidence = provider.evidenceLinks ?? provider.evidence.map((label) => ({ label, path: '', url: null }));
  return <aside className="admin-card h-fit p-5"><div className="flex items-start justify-between gap-3"><div><p className="text-xs font-bold uppercase tracking-wide text-tealbrand">Provider detail</p><h2 className="mt-1 text-xl font-black">{provider.name}</h2><p className="mt-1 text-sm text-slate-500">{provider.email}</p></div><StatusBadge value={provider.status} /></div><div className="mt-6 grid grid-cols-2 gap-3"><Info label="Rating" value={`${provider.rating.toFixed(1)} / 5`} /><Info label="Completed" value={`${provider.completedJobs} jobs`} /><Info label="Category" value={provider.category} /><Info label="Area" value={provider.area} /></div><div className="mt-6 rounded-2xl bg-slate-50 p-4"><p className="text-xs font-bold uppercase tracking-wide text-slate-500">Profile bio</p><p className="mt-2 text-sm leading-6 text-slate-700">{provider.bio}</p></div><div className="mt-5"><p className="text-sm font-bold text-slate-800">Private evidence</p><div className="mt-3 grid gap-2">{evidence.map((item) => <div key={`${item.label}-${item.path}`} className="flex items-center justify-between gap-3 rounded-xl border border-slate-200 px-3 py-2 text-sm"><span>{item.label}</span>{item.url ? <a href={item.url} target="_blank" rel="noreferrer" className="text-xs font-bold text-tealbrand hover:underline">Open signed URL</a> : <span className="text-xs font-bold text-slate-400">Unavailable locally</span>}</div>)}</div><p className="mt-3 text-xs leading-5 text-slate-500">URLs expire after five minutes and are generated only for this authenticated Admin session.</p></div><div className="mt-6 flex flex-wrap gap-2">{provider.status === 'pending' && <><ActionButton label="Approve" tone="primary" onClick={() => onAction(provider, 'approved')} /><ActionButton label="Reject" tone="muted" onClick={() => onAction(provider, 'rejected')} /></>}{provider.status === 'approved' && <ActionButton label="Suspend provider" tone="danger" onClick={() => onAction(provider, 'suspended')} />}{(provider.status === 'rejected' || provider.status === 'suspended') && <ActionButton label="Approve provider" tone="primary" onClick={() => onAction(provider, 'approved')} />}</div></aside>;
}

function CategoryRequestsView({ requests, onAction }: { requests: AdminCategoryRequest[]; onAction: (request: AdminCategoryRequest, status: CategoryRequestStatus, note: string | null) => void }) {
  const [selectedId, setSelectedId] = useState(requests.find((request) => request.status === 'pending')?.id ?? requests[0]?.id);
  const [note, setNote] = useState('');
  const selected = requests.find((request) => request.id === selectedId) ?? requests[0];
  if (!selected) return <section className="admin-card p-5"><SectionHeader title="Category requests" subtitle="No provider category requests are waiting for review." /></section>;
  return <div className="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]"><section className="admin-card overflow-hidden"><div className="border-b border-slate-200 p-5"><SectionHeader title="Provider category requests" subtitle="Approved categories can match jobs. Pending and rejected categories stay out of the provider feed." /></div><div className="overflow-x-auto"><table className="w-full min-w-[700px] text-left text-sm"><thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase tracking-wide text-slate-500"><tr><th className="px-5 py-3">Provider</th><th className="py-3">Category</th><th className="py-3">Submitted</th><th className="py-3">Status</th><th className="py-3 pr-5 text-right">Action</th></tr></thead><tbody>{requests.map((request) => <tr key={request.id} className={`border-b border-slate-100 last:border-0 ${request.id === selected.id ? 'bg-teal-50/40' : ''}`}><td className="px-5 py-4"><button type="button" onClick={() => { setSelectedId(request.id); setNote(request.adminNote); }} className="text-left"><p className="font-bold text-slate-800">{request.providerName}</p><p className="mt-1 text-xs text-slate-500">{request.providerEmail}</p></button></td><td className="py-4">{request.category}</td><td className="py-4 text-slate-500">{request.submittedAt}</td><td className="py-4"><StatusBadge value={request.status} /></td><td className="py-4 pr-5 text-right"><button type="button" onClick={() => { setSelectedId(request.id); setNote(request.adminNote); }} className="font-bold text-tealbrand hover:underline">Review</button></td></tr>)}</tbody></table></div></section><aside className="admin-card h-fit p-5"><div className="flex items-start justify-between gap-3"><div><p className="text-xs font-bold uppercase tracking-wide text-tealbrand">Category detail</p><h2 className="mt-1 text-xl font-black">{selected.category}</h2><p className="mt-1 text-sm text-slate-500">{selected.providerName} · {selected.providerEmail}</p></div><StatusBadge value={selected.status} /></div><div className="mt-6 grid gap-3"><Info label="Submitted" value={selected.submittedAt} /><Info label="Reviewed" value={selected.reviewedAt} /></div><label className="mt-6 block text-sm font-bold text-slate-700">Admin note<textarea value={note} onChange={(event) => setNote(event.target.value)} rows={4} className="mt-2 w-full rounded-xl border border-slate-200 px-3 py-3 text-sm outline-none ring-teal-200 focus:ring-2" placeholder="Optional guidance for the provider" /></label>{selected.adminNote && <p className="mt-3 text-xs text-slate-500">Previous note: {selected.adminNote}</p>}<div className="mt-6 flex flex-wrap gap-2">{selected.status === 'pending' && <><ActionButton label="Approve category" tone="primary" onClick={() => onAction(selected, 'approved', note.trim() || null)} /><ActionButton label="Reject category" tone="danger" onClick={() => onAction(selected, 'rejected', note.trim() || null)} /></>}</div></aside></div>;
}function UsersView({ users, onAction }: { users: AdminUser[]; onAction: (user: AdminUser, status: AccountStatus) => void }) {
  return <section className="admin-card overflow-hidden"><div className="border-b border-slate-200 p-5"><SectionHeader title="Users" subtitle="Suspend or restore accounts while keeping role and activity visible." /></div><div className="overflow-x-auto"><table className="w-full min-w-[760px] text-left text-sm"><thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase tracking-wide text-slate-500"><tr><th className="px-5 py-3">User</th><th className="py-3">Role</th><th className="py-3">Activity</th><th className="py-3">Status</th><th className="py-3 pr-5 text-right">Account action</th></tr></thead><tbody>{users.map((user) => <tr key={user.id} className="border-b border-slate-100 last:border-0"><td className="px-5 py-4"><p className="font-bold">{user.name}</p><p className="mt-1 text-xs text-slate-500">{user.email} · Joined {user.joinedAt}</p></td><td className="py-4"><StatusBadge value={user.role} /></td><td className="py-4 text-slate-600">{user.jobs} jobs · {user.bids} bids</td><td className="py-4"><StatusBadge value={user.status} /></td><td className="py-4 pr-5 text-right">{user.status === 'active' ? <ActionButton label="Suspend" tone="danger" onClick={() => onAction(user, 'suspended')} /> : <ActionButton label="Restore" tone="primary" onClick={() => onAction(user, 'active')} />}</td></tr>)}</tbody></table></div></section>;
}

function JobsView({ jobs, layout }: { jobs: AdminJob[]; layout: AdminLayout }) {
  const [selectedId, setSelectedId] = useState(jobs[0]?.id);
  const [detailOpen, setDetailOpen] = useState(false);
  const selected = jobs.find((job) => job.id === selectedId) ?? jobs[0];
  const selectJob = (id: string) => {
    setSelectedId(id);
    if (layout !== 'desktop') setDetailOpen(true);
  };

  if (layout === 'mobile') return <>
    <MobileJobList jobs={jobs} onSelect={selectJob} />
    {selected && detailOpen && <MobileJobDetail job={selected} onClose={() => setDetailOpen(false)} />}
  </>;

  if (layout === 'tablet') return <>
    <section className="admin-card overflow-hidden"><div className="border-b border-slate-200 p-5"><SectionHeader title="Jobs" subtitle="Tap a job to open its detail drawer without leaving the list." /></div><JobTable jobs={jobs} onSelect={selectJob} selectedId={selectedId} /></section>
    {selected && detailOpen && <TabletJobDrawer job={selected} onClose={() => setDetailOpen(false)} />}
  </>;

  return <div className="grid gap-6 lg:grid-cols-[1.3fr_0.7fr]"><section className="admin-card overflow-hidden"><div className="border-b border-slate-200 p-5"><SectionHeader title="Jobs" subtitle="Monitor the full marketplace state; private address fields are only shown in the admin detail." /></div><JobTable jobs={jobs} onSelect={selectJob} selectedId={selectedId} /></section>{selected && <JobDetailCard job={selected} />}</div>;
}

function JobDetailCard({ job, onClose }: { job: AdminJob; onClose?: () => void }) {
  return <aside className="admin-card h-fit p-5"><div className="flex items-start justify-between gap-3"><div><p className="text-xs font-bold uppercase tracking-wide text-tealbrand">Job detail</p><h2 className="mt-1 text-xl font-black">{job.title}</h2></div>{onClose && <button type="button" onClick={onClose} className="rounded-lg border border-slate-200 px-3 py-2 text-xs font-bold text-slate-600">Close</button>}</div><div className="mt-5 grid gap-3"><Info label="Customer" value={job.customer} /><Info label="Category" value={job.category} /><Info label="Area" value={job.area} /><Info label="Budget" value={`RM${job.budget}`} /><Info label="Scheduled" value={job.scheduledTime} /><Info label="Created" value={job.createdAt} /><Info label="Private address" value={job.fullAddress} /></div><div className="mt-5 rounded-xl bg-slate-50 p-4 text-sm text-slate-600">{job.bids} offer(s) · {job.status.replace('_', ' ')}</div></aside>;
}

function MobileJobList({ jobs, onSelect }: { jobs: AdminJob[]; onSelect: (id: string) => void }) {
  return <section className="admin-card overflow-hidden"><div className="border-b border-slate-200 p-4"><SectionHeader title="Jobs" subtitle="Tap a job to inspect customer, budget, address, and offers." /></div>{jobs.length === 0 ? <p className="p-5 text-sm text-slate-500">No jobs found.</p> : <div className="divide-y divide-slate-100">{jobs.map((job) => <button key={job.id} type="button" onClick={() => onSelect(job.id)} className="flex w-full items-center gap-3 p-4 text-left transition active:bg-teal-50 hover:bg-slate-50"><div className="min-w-0 flex-1"><div className="flex items-start justify-between gap-3"><p className="truncate font-bold text-slate-800">{job.title}</p><span className="shrink-0 text-lg leading-none text-slate-400" aria-hidden="true">›</span></div><p className="mt-1 truncate text-xs text-slate-500">{job.area} · {job.customer}</p><div className="mt-3 flex flex-wrap items-center gap-2"><span className="text-sm font-black text-slate-800">RM{job.budget}</span><StatusBadge value={job.status} /><span className="text-xs font-semibold text-slate-400">{job.bids} offer(s)</span></div></div></button>)}</div>}</section>;
}

function TabletJobDrawer({ job, onClose }: { job: AdminJob; onClose: () => void }) {
  return <div className="fixed inset-0 z-40" role="dialog" aria-modal="true" aria-label={`Job detail for ${job.title}`}><button type="button" onClick={onClose} aria-label="Close job detail" className="absolute inset-0 bg-slate-900/40" /><aside className="relative z-10 ml-auto h-full w-full max-w-xl overflow-y-auto bg-page p-4 shadow-2xl sm:p-6"><JobDetailCard job={job} onClose={onClose} /></aside></div>;
}

function MobileJobDetail({ job, onClose }: { job: AdminJob; onClose: () => void }) {
  return <div className="fixed inset-0 z-50 overflow-y-auto bg-page" role="dialog" aria-modal="true" aria-label={`Job detail for ${job.title}`}><header className="sticky top-0 z-10 flex items-center gap-3 border-b border-slate-200 bg-white px-4 py-3 shadow-sm"><button type="button" onClick={onClose} className="rounded-lg border border-slate-200 px-3 py-2 text-sm font-bold text-slate-700">← Jobs</button><div className="min-w-0"><p className="text-xs font-semibold text-tealbrand">Job detail</p><p className="truncate font-black">{job.title}</p></div></header><div className="p-4"><JobDetailCard job={job} /></div></div>;
}
function JobTable({ jobs, compact = false, onSelect, selectedId }: { jobs: AdminJob[]; compact?: boolean; onSelect?: (id: string) => void; selectedId?: string }) {
  return <div className="overflow-x-auto"><table className="w-full min-w-[620px] text-left text-sm"><thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase tracking-wide text-slate-500"><tr><th className="px-5 py-3">Job</th><th className="py-3">Area</th><th className="py-3">Status</th><th className="py-3 pr-5 text-right">Bids</th></tr></thead><tbody>{jobs.map((job) => <tr key={job.id} className={`border-b border-slate-100 last:border-0 ${selectedId === job.id ? 'bg-teal-50/50' : ''}`}><td className="px-5 py-4"><button type="button" onClick={() => onSelect?.(job.id)} className="text-left"><p className="font-bold text-slate-800">{job.title}</p><p className="mt-1 text-xs text-slate-500">{compact ? job.createdAt : `${job.customer} · RM${job.budget}`}</p></button></td><td className="py-4 text-slate-600">{job.area}</td><td className="py-4"><StatusBadge value={job.status} /></td><td className="py-4 pr-5 text-right font-bold">{job.bids}</td></tr>)}</tbody></table></div>;
}
function BidsView({ bids }: { bids: { id: string; jobTitle: string; provider: string; customer: string; amount: number; status: BidStatus; createdAt: string }[] }) {
  return <section className="admin-card overflow-hidden"><div className="border-b border-slate-200 p-5"><SectionHeader title="Bids" subtitle="Admin visibility is broader than the provider feed; providers still never receive another provider's amount." /></div><div className="overflow-x-auto"><table className="w-full min-w-[760px] text-left text-sm"><thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase tracking-wide text-slate-500"><tr><th className="px-5 py-3">Job</th><th className="py-3">Provider</th><th className="py-3">Customer</th><th className="py-3">Amount</th><th className="py-3">Status</th><th className="py-3 pr-5">Created</th></tr></thead><tbody>{bids.map((bid) => <tr key={bid.id} className="border-b border-slate-100 last:border-0"><td className="px-5 py-4"><p className="font-bold">{bid.jobTitle}</p><p className="mt-1 text-xs text-slate-500">{bid.id}</p></td><td className="py-4">{bid.provider}</td><td className="py-4">{bid.customer}</td><td className="py-4 font-bold">RM{bid.amount}</td><td className="py-4"><StatusBadge value={bid.status} /></td><td className="py-4 pr-5 text-slate-500">{bid.createdAt}</td></tr>)}</tbody></table></div></section>;
}

function ReportsView({ reports, onAction }: { reports: AdminReport[]; onAction: (report: AdminReport, status: ReportStatus) => void }) {
  const [selectedId, setSelectedId] = useState(reports[0]?.id);
  const selected = reports.find((report) => report.id === selectedId) ?? reports[0];
  return <div className="grid gap-6 xl:grid-cols-[1.25fr_0.75fr]"><section className="admin-card overflow-hidden"><div className="border-b border-slate-200 p-5"><SectionHeader title="Reports" subtitle="Prioritise open safety reports and record every resolution." /></div><div className="divide-y divide-slate-100">{reports.map((report) => <button type="button" key={report.id} onClick={() => setSelectedId(report.id)} className={`flex w-full items-start justify-between gap-4 p-5 text-left hover:bg-slate-50 ${selectedId === report.id ? 'bg-red-50/40' : ''}`}><div><p className="font-bold">{report.reason}</p><p className="mt-1 text-sm text-slate-600">{report.reporter} reported {report.reportedUser}</p><p className="mt-1 text-xs text-slate-400">{report.jobTitle} · {report.createdAt}</p></div><StatusBadge value={report.status} /></button>)}</div></section>{selected && <aside className="admin-card h-fit p-5"><div className="flex items-start justify-between gap-3"><div><p className="text-xs font-bold uppercase tracking-wide text-red-700">Report detail</p><h2 className="mt-1 text-xl font-black">{selected.reason}</h2></div><StatusBadge value={selected.status} /></div><div className="mt-5 grid gap-3"><Info label="Reporter" value={selected.reporter} /><Info label="Reported user" value={selected.reportedUser} /><Info label="Job" value={selected.jobTitle} /></div><div className="mt-5 rounded-2xl bg-slate-50 p-4 text-sm leading-6 text-slate-700">{selected.description}</div><div className="mt-6 flex flex-wrap gap-2"><ActionButton label="Mark reviewing" tone="muted" onClick={() => onAction(selected, 'reviewing')} /><ActionButton label="Resolve" tone="primary" onClick={() => onAction(selected, 'resolved')} /><ActionButton label="Dismiss" tone="danger" onClick={() => onAction(selected, 'dismissed')} /></div></aside>}</div>;
}

function AuditView({ audit }: { audit: AdminData['audit'] }) {
  return <section className="admin-card"><div className="border-b border-slate-200 p-5"><SectionHeader title="Audit Log" subtitle="Every moderation action is attributable and time-stamped." /></div><div className="divide-y divide-slate-100">{audit.map((event) => <div key={event.id} className="flex flex-wrap items-center justify-between gap-3 px-5 py-4"><div><p className="font-bold">{event.action}</p><p className="mt-1 text-sm text-slate-500">{event.actor} · target {event.target}</p></div><span className="text-xs font-semibold text-slate-400">{event.createdAt}</span></div>)}</div></section>;
}

function TaxonomyView({ title, items, description }: { title: string; items: string[]; description: string }) {
  return <section className="admin-card p-5"><SectionHeader title={title} subtitle={`${description} Read-only local view for this phase.`} /><div className="mt-6 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">{items.map((item, index) => <div key={item} className="flex items-center justify-between rounded-xl border border-slate-200 px-4 py-3"><div><p className="font-bold">{item}</p><p className="mt-1 text-xs text-slate-400">Active · ID {String(index + 1).padStart(3, '0')}</p></div><span className="text-xs font-bold text-slate-400">Read-only</span></div>)}</div></section>;
}

function LegacyTaxonomyView({ title, items, description }: { title: string; items: string[]; description: string }) {
  /* Legacy fake preview retained only as a migration reference; it is not rendered.
  return <section className="admin-card p-5"><SectionHeader title={title} subtitle={description} action={<button type="button" className="rounded-lg bg-tealbrand px-3 py-2 text-sm font-bold text-white">Add {title === 'Areas' ? 'area' : 'category'}</button>} /><div className="mt-6 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">{items.map((item, index) => <div key={item} className="flex items-center justify-between rounded-xl border border-slate-200 px-4 py-3"><div><p className="font-bold">{item}</p><p className="mt-1 text-xs text-slate-400">Active · ID {String(index + 1).padStart(3, '0')}</p></div><button type="button" className="text-xs font-bold text-slate-400 hover:text-red-700">Disable</button></div>)}</div></section>;
}

  */
}

function SettingsView() {
  return <section className="max-w-3xl space-y-5"><div className="admin-card p-5"><SectionHeader title="System settings" subtitle="Runtime-only controls and operational safeguards." /><div className="mt-5 grid gap-3"><Setting label="Environment" value="local development" /><Setting label="Supabase URL" value={process.env.NEXT_PUBLIC_SUPABASE_URL ?? 'Not configured'} /><Setting label="Anon key" value="Loaded at runtime only" /><Setting label="Service role key" value="Never exposed to browser" /><Setting label="Audit retention" value="Local database table" /></div></div><div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-5 text-sm leading-6 text-emerald-900"><p className="font-bold">Local safeguards active</p><p className="mt-1">Admin Auth, profile `is_admin`, table RLS, atomic moderation RPCs, and five-minute verification signed URLs are enforced by the local Supabase stack.</p></div></section>;
}

function SectionHeader({ title, subtitle, action }: { title: string; subtitle: string; action?: ReactNode }) {
  return <div className="flex flex-wrap items-start justify-between gap-3"><div><h2 className="text-lg font-extrabold">{title}</h2><p className="mt-1 text-sm text-slate-500">{subtitle}</p></div>{action}</div>;
}

function MetricCard({ label, value, note, tone }: { label: string; value: number; note: string; tone: 'emerald' | 'orange' | 'blue' | 'red' }) {
  const colors = { emerald: 'text-emerald-700 bg-emerald-50', orange: 'text-orange-700 bg-orange-50', blue: 'text-blue-700 bg-blue-50', red: 'text-red-700 bg-red-50' };
  return <article className="admin-card p-5"><div className="flex items-start justify-between gap-3"><p className="text-sm text-slate-500">{label}</p><span className={`h-2.5 w-2.5 rounded-full ${colors[tone].split(' ')[1]}`} /></div><p className={`mt-3 text-3xl font-black ${colors[tone].split(' ')[0]}`}>{value}</p><p className="mt-2 text-xs font-semibold text-slate-500">{note}</p></article>;
}

function QueueButton({ title, value, tone, onClick }: { title: string; value: string; tone: 'orange' | 'red' | 'blue'; onClick: () => void }) {
  const colors = { orange: 'bg-orange-50 text-orange-900', red: 'bg-red-50 text-red-900', blue: 'bg-blue-50 text-blue-900' };
  return <button type="button" onClick={onClick} className={`rounded-xl p-4 text-left transition hover:-translate-y-0.5 ${colors[tone]}`}><p className="font-bold">{title}</p><p className="mt-1 text-sm">{value}</p></button>;
}

function Progress({ label, value, note, tone }: { label: string; value: number; note: string; tone: 'teal' | 'blue' | 'orange' }) {
  const color = tone === 'teal' ? 'bg-tealbrand' : tone === 'blue' ? 'bg-blue-600' : 'bg-orange-500';
  return <div><div className="flex justify-between gap-3 text-sm"><span className="font-bold">{label}</span><span className="font-black text-slate-500">{value}%</span></div><div className="mt-3 h-2 rounded-full bg-slate-100"><div className={`h-2 rounded-full ${color}`} style={{ width: `${value}%` }} /></div><p className="mt-2 text-xs text-slate-500">{note}</p></div>;
}

function StatusBadge({ value }: { value: string }) {
  const normalized = value.toLowerCase();
  const tone = normalized.includes('approved') || normalized.includes('active') || normalized.includes('completed') || normalized.includes('resolved') || normalized.includes('accepted') ? 'bg-emerald-50 text-emerald-700' : normalized.includes('pending') || normalized.includes('reviewing') || normalized.includes('assigned') || normalized.includes('open') ? 'bg-orange-50 text-orange-700' : normalized.includes('rejected') || normalized.includes('suspended') || normalized.includes('cancelled') || normalized.includes('dismissed') || normalized.includes('withdrawn') ? 'bg-red-50 text-red-700' : 'bg-slate-100 text-slate-600';
  return <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-bold capitalize ${tone}`}>{value.replace('_', ' ')}</span>;
}

function ActionButton({ label, tone, onClick }: { label: string; tone: 'primary' | 'danger' | 'muted'; onClick: () => void }) {
  const style = tone === 'primary' ? 'bg-tealbrand text-white hover:bg-teal-700' : tone === 'danger' ? 'border border-red-200 bg-red-50 text-red-700 hover:bg-red-100' : 'border border-slate-200 bg-white text-slate-700 hover:bg-slate-50';
  return <button type="button" onClick={onClick} className={`rounded-lg px-3 py-2 text-xs font-bold ${style}`}>{label}</button>;
}

function Info({ label, value }: { label: string; value: string }) {
  return <div className="rounded-xl border border-slate-200 p-3"><p className="text-xs font-bold uppercase tracking-wide text-slate-400">{label}</p><p className="mt-1 text-sm font-semibold text-slate-700">{value}</p></div>;
}

function Setting({ label, value }: { label: string; value: string }) {
  return <div className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-slate-200 px-4 py-3"><span className="text-sm font-bold text-slate-700">{label}</span><span className="text-sm text-slate-500">{value}</span></div>;
}
