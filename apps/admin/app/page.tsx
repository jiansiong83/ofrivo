'use client';

import { useState } from 'react';
import type { FormEvent, ReactNode } from 'react';

import {
  type AccountStatus,
  type AdminData,
  type AdminJob,
  type AdminProvider,
  type AdminReport,
  type AdminUser,
  type BidStatus,
  type ProviderStatus,
  type ReportStatus,
  makeFakeAdminData,
} from '../lib/admin-data';

type AdminTab = 'Dashboard' | 'Pending Providers' | 'Users' | 'Jobs' | 'Bids' | 'Reports' | 'Categories' | 'Areas' | 'Audit Log' | 'System Settings';

const navigation: { id: AdminTab; label: string; hint: string }[] = [
  { id: 'Dashboard', label: 'Dashboard', hint: 'Operations overview' },
  { id: 'Pending Providers', label: 'Pending Providers', hint: 'Review applications' },
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
  const [data, setData] = useState<AdminData>(() => makeFakeAdminData());
  const [activeTab, setActiveTab] = useState<AdminTab>('Dashboard');
  const [signedIn, setSignedIn] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  const mutate = (message: string, auditAction: string, target: string, updater: (next: AdminData) => void) => {
    setData((previous) => {
      const next: AdminData = {
        ...previous,
        providers: [...previous.providers],
        users: [...previous.users],
        jobs: [...previous.jobs],
        bids: [...previous.bids],
        reports: [...previous.reports],
        audit: [...previous.audit],
        categories: [...previous.categories],
        areas: [...previous.areas],
      };
      updater(next);
      next.audit.unshift({ id: `audit-${Date.now()}`, actor: 'Admin', action: auditAction, target, createdAt: 'Just now' });
      return next;
    });
    setToast(message);
    window.setTimeout(() => setToast(null), 3200);
  };

  const providerAction = (provider: AdminProvider, status: ProviderStatus) => {
    const label = status === 'approved' ? 'approved' : status === 'rejected' ? 'rejected' : 'suspended';
    mutate(`Provider ${provider.name} ${label}.`, `${label[0].toUpperCase()}${label.slice(1)} provider`, provider.id, (next) => {
      const target = next.providers.find((item) => item.id === provider.id);
      if (target) target.status = status;
    });
  };

  const userAction = (user: AdminUser, status: AccountStatus) => {
    const label = status === 'suspended' ? 'suspended' : 'restored';
    mutate(`Account ${user.name} ${label}.`, `${label[0].toUpperCase()}${label.slice(1)} account`, user.id, (next) => {
      const target = next.users.find((item) => item.id === user.id);
      if (target) target.status = status;
    });
  };

  const reportAction = (report: AdminReport, status: ReportStatus) => {
    mutate(`Report marked ${status}.`, `Marked report ${status}`, report.id, (next) => {
      const target = next.reports.find((item) => item.id === report.id);
      if (target) target.status = status;
    });
  };

  if (!signedIn) return <AdminLogin onLogin={() => setSignedIn(true)} />;

  const current = navigation.find((item) => item.id === activeTab) ?? navigation[0];
  return (
    <main className="min-h-screen lg:flex">
      <aside className="border-b border-slate-200 bg-white px-5 py-6 lg:min-h-screen lg:w-72 lg:border-b-0 lg:border-r">
        <div className="mb-8 flex items-center gap-3">
          <div className="grid h-10 w-10 place-items-center rounded-xl bg-tealbrand text-lg font-black text-white">O</div>
          <div><p className="font-extrabold tracking-tight">Ofrivo</p><p className="text-xs text-slate-500">Operations console</p></div>
        </div>
        <nav aria-label="Admin navigation" className="grid gap-1">
          {navigation.map((item) => (
            <button key={item.id} type="button" onClick={() => setActiveTab(item.id)} className={`rounded-xl px-3 py-2.5 text-left text-sm font-semibold transition ${activeTab === item.id ? 'bg-teal-50 text-tealbrand' : 'text-slate-600 hover:bg-slate-50'}`}>
              <span className="block">{item.label}</span><span className={`mt-0.5 block text-[11px] font-medium ${activeTab === item.id ? 'text-teal-700' : 'text-slate-400'}`}>{item.hint}</span>
            </button>
          ))}
        </nav>
        <div className="mt-8 rounded-2xl bg-slate-50 p-4 text-sm text-slate-600"><p className="font-bold text-slate-800">Local admin preview</p><p className="mt-1">Actions update fake data and append an audit event. Supabase values stay runtime-only.</p></div>
      </aside>
      <section className="min-w-0 flex-1 p-5 sm:p-8">
        <header className="mb-8 flex flex-wrap items-start justify-between gap-4">
          <div><p className="text-sm font-semibold text-tealbrand">{current.hint}</p><h1 className="mt-1 text-3xl font-black tracking-tight">{current.label}</h1><p className="mt-2 text-slate-500">Moderate providers, protect users, and keep marketplace activity healthy.</p></div>
          <div className="flex items-center gap-3"><span className="rounded-full border border-emerald-200 bg-emerald-50 px-4 py-2 text-sm font-semibold text-emerald-700">Demo admin · active</span><button type="button" onClick={() => setSignedIn(false)} className="rounded-full border border-slate-200 bg-white px-4 py-2 text-sm font-bold text-slate-600 hover:border-slate-300">Sign out</button></div>
        </header>
        {activeTab === 'Dashboard' && <DashboardView data={data} onNavigate={setActiveTab} />}
        {activeTab === 'Pending Providers' && <ProvidersView providers={data.providers} onAction={providerAction} />}
        {activeTab === 'Users' && <UsersView users={data.users} onAction={userAction} />}
        {activeTab === 'Jobs' && <JobsView jobs={data.jobs} />}
        {activeTab === 'Bids' && <BidsView bids={data.bids} />}
        {activeTab === 'Reports' && <ReportsView reports={data.reports} onAction={reportAction} />}
        {activeTab === 'Categories' && <TaxonomyView title="Categories" items={data.categories} description="Service categories used by customers and approved providers." />}
        {activeTab === 'Areas' && <TaxonomyView title="Areas" items={data.areas} description="Johor Bahru coverage zones available to matching providers." />}
        {activeTab === 'Audit Log' && <AuditView audit={data.audit} />}
        {activeTab === 'System Settings' && <SettingsView />}
        {toast && <div role="status" className="fixed bottom-5 right-5 z-20 max-w-sm rounded-xl bg-slate-900 px-4 py-3 text-sm font-semibold text-white shadow-xl">{toast}</div>}
      </section>
    </main>
  );
}

function AdminLogin({ onLogin }: { onLogin: () => void }) {
  const [email, setEmail] = useState('admin@example.test');
  const [password, setPassword] = useState('local-preview');
  const submit = (event: FormEvent<HTMLFormElement>) => { event.preventDefault(); if (email.trim() && password.trim()) onLogin(); };
  return <main className="grid min-h-screen place-items-center bg-page px-5 py-10"><form onSubmit={submit} className="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-8 shadow-sm"><div className="mb-8 flex items-center gap-3"><div className="grid h-12 w-12 place-items-center rounded-2xl bg-tealbrand text-xl font-black text-white">O</div><div><p className="font-extrabold">Ofrivo Admin</p><p className="text-xs text-slate-500">Secure operations console</p></div></div><h1 className="text-2xl font-black tracking-tight">Sign in to continue</h1><p className="mt-2 text-sm leading-6 text-slate-500">The local preview uses fake admin data. Production authentication will use Supabase Auth and an admin profile guard.</p><label className="mt-6 block text-sm font-bold text-slate-700">Email<input value={email} onChange={(event) => setEmail(event.target.value)} className="mt-2 w-full rounded-xl border border-slate-200 px-3 py-3 outline-none ring-teal-200 focus:ring-2" type="email" /></label><label className="mt-4 block text-sm font-bold text-slate-700">Password<input value={password} onChange={(event) => setPassword(event.target.value)} className="mt-2 w-full rounded-xl border border-slate-200 px-3 py-3 outline-none ring-teal-200 focus:ring-2" type="password" /></label><button type="submit" className="mt-6 w-full rounded-xl bg-tealbrand px-4 py-3 font-bold text-white hover:bg-teal-700">Enter admin preview</button><p className="mt-5 text-center text-xs text-slate-400">No credentials are stored in the repository.</p></form></main>;
}

function DashboardView({ data, onNavigate }: { data: AdminData; onNavigate: (tab: AdminTab) => void }) {
  const openReports = data.reports.filter((report) => report.status === 'open' || report.status === 'reviewing').length;
  const pendingProviders = data.providers.filter((provider) => provider.status === 'pending').length;
  const activeProviders = data.providers.filter((provider) => provider.status === 'approved').length;
  const openJobs = data.jobs.filter((job) => job.status === 'open').length;
  return <div className="space-y-6"><div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4"><MetricCard label="Open jobs" value={openJobs} note="Live marketplace requests" tone="emerald" /><MetricCard label="Pending providers" value={pendingProviders} note="Needs verification review" tone="orange" /><MetricCard label="Approved providers" value={activeProviders} note="Eligible to receive jobs" tone="blue" /><MetricCard label="Open reports" value={openReports} note="Safety queue" tone="red" /></div><div className="grid gap-6 xl:grid-cols-[1.4fr_1fr]"><section className="admin-card p-5"><SectionHeader title="Recent jobs" subtitle="Public job fields are shown in the list; private fields stay behind the job detail permission." action={<button type="button" onClick={() => onNavigate('Jobs')} className="rounded-lg border border-slate-200 px-3 py-2 text-sm font-bold text-tealbrand">View all</button>} /><JobTable jobs={data.jobs.slice(0, 4)} compact /></section><section className="admin-card p-5"><SectionHeader title="Safety queue" subtitle="Review urgent work without losing the audit trail." /><div className="mt-5 grid gap-3"><QueueButton title="Pending provider verification" value={`${pendingProviders} waiting`} tone="orange" onClick={() => onNavigate('Pending Providers')} /><QueueButton title="Reports requiring review" value={`${openReports} open`} tone="red" onClick={() => onNavigate('Reports')} /><QueueButton title="Audit events today" value={`${data.audit.length} recent events`} tone="blue" onClick={() => onNavigate('Audit Log')} /></div></section></div><section className="admin-card p-5"><SectionHeader title="Conversion pulse" subtitle="A small operational snapshot for the first Johor Bahru cohort." /><div className="mt-6 grid gap-5 md:grid-cols-3"><Progress label="Jobs with an offer" value={75} note="3 of 4 demo jobs" tone="teal" /><Progress label="Offer acceptance" value={50} note="2 assigned jobs" tone="blue" /><Progress label="Reports resolved" value={33} note="1 of 3 demo reports" tone="orange" /></div></section></div>;
}

function ProvidersView({ providers, onAction }: { providers: AdminProvider[]; onAction: (provider: AdminProvider, status: ProviderStatus) => void }) {
  const [selectedId, setSelectedId] = useState(providers.find((provider) => provider.status === 'pending')?.id ?? providers[0]?.id);
  const selected = providers.find((provider) => provider.id === selectedId) ?? providers[0];
  return <div className="grid gap-6 xl:grid-cols-[1.3fr_0.8fr]"><section className="admin-card overflow-hidden"><div className="border-b border-slate-200 p-5"><SectionHeader title="Provider verification" subtitle="Review identity evidence and approve only complete applications." /></div><div className="overflow-x-auto"><table className="w-full min-w-[680px] text-left text-sm"><thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase tracking-wide text-slate-500"><tr><th className="px-5 py-3">Provider</th><th className="py-3">Service</th><th className="py-3">Submitted</th><th className="py-3">Status</th><th className="py-3 pr-5 text-right">Action</th></tr></thead><tbody>{providers.map((provider) => <tr key={provider.id} className={`border-b border-slate-100 last:border-0 ${selectedId === provider.id ? 'bg-teal-50/40' : ''}`}><td className="px-5 py-4"><button type="button" onClick={() => setSelectedId(provider.id)} className="text-left"><p className="font-bold text-slate-800">{provider.name}</p><p className="mt-1 text-xs text-slate-500">{provider.email}</p></button></td><td className="py-4"><p>{provider.category}</p><p className="mt-1 text-xs text-slate-500">{provider.area}</p></td><td className="py-4 text-slate-500">{provider.submittedAt}</td><td className="py-4"><StatusBadge value={provider.status} /></td><td className="py-4 pr-5 text-right"><button type="button" onClick={() => setSelectedId(provider.id)} className="font-bold text-tealbrand hover:underline">Review</button></td></tr>)}</tbody></table></div></section>{selected && <ProviderDetail provider={selected} onAction={onAction} />}</div>;
}

function ProviderDetail({ provider, onAction }: { provider: AdminProvider; onAction: (provider: AdminProvider, status: ProviderStatus) => void }) {
  return <aside className="admin-card h-fit p-5"><div className="flex items-start justify-between gap-3"><div><p className="text-xs font-bold uppercase tracking-wide text-tealbrand">Provider detail</p><h2 className="mt-1 text-xl font-black">{provider.name}</h2><p className="mt-1 text-sm text-slate-500">{provider.email}</p></div><StatusBadge value={provider.status} /></div><div className="mt-6 grid grid-cols-2 gap-3"><Info label="Rating" value={`${provider.rating.toFixed(1)} / 5`} /><Info label="Completed" value={`${provider.completedJobs} jobs`} /><Info label="Category" value={provider.category} /><Info label="Area" value={provider.area} /></div><div className="mt-6 rounded-2xl bg-slate-50 p-4"><p className="text-xs font-bold uppercase tracking-wide text-slate-500">Profile bio</p><p className="mt-2 text-sm leading-6 text-slate-700">{provider.bio}</p></div><div className="mt-5"><p className="text-sm font-bold text-slate-800">Private evidence</p><div className="mt-3 grid gap-2">{provider.evidence.map((item) => <div key={item} className="flex items-center justify-between rounded-xl border border-slate-200 px-3 py-2 text-sm"><span>{item}</span><span className="text-xs font-bold text-tealbrand">Signed preview</span></div>)}</div><p className="mt-3 text-xs leading-5 text-slate-500">Evidence should be served through short-lived signed URLs to admins only.</p></div><div className="mt-6 flex flex-wrap gap-2">{provider.status === 'pending' && <><ActionButton label="Approve" tone="primary" onClick={() => onAction(provider, 'approved')} /><ActionButton label="Reject" tone="muted" onClick={() => onAction(provider, 'rejected')} /></>}{provider.status === 'approved' && <ActionButton label="Suspend provider" tone="danger" onClick={() => onAction(provider, 'suspended')} />}{(provider.status === 'rejected' || provider.status === 'suspended') && <ActionButton label="Approve provider" tone="primary" onClick={() => onAction(provider, 'approved')} />}</div></aside>;
}

function UsersView({ users, onAction }: { users: AdminUser[]; onAction: (user: AdminUser, status: AccountStatus) => void }) {
  return <section className="admin-card overflow-hidden"><div className="border-b border-slate-200 p-5"><SectionHeader title="Users" subtitle="Suspend or restore accounts while keeping role and activity visible." /></div><div className="overflow-x-auto"><table className="w-full min-w-[760px] text-left text-sm"><thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase tracking-wide text-slate-500"><tr><th className="px-5 py-3">User</th><th className="py-3">Role</th><th className="py-3">Activity</th><th className="py-3">Status</th><th className="py-3 pr-5 text-right">Account action</th></tr></thead><tbody>{users.map((user) => <tr key={user.id} className="border-b border-slate-100 last:border-0"><td className="px-5 py-4"><p className="font-bold">{user.name}</p><p className="mt-1 text-xs text-slate-500">{user.email} · Joined {user.joinedAt}</p></td><td className="py-4"><StatusBadge value={user.role} /></td><td className="py-4 text-slate-600">{user.jobs} jobs · {user.bids} bids</td><td className="py-4"><StatusBadge value={user.status} /></td><td className="py-4 pr-5 text-right">{user.status === 'active' ? <ActionButton label="Suspend" tone="danger" onClick={() => onAction(user, 'suspended')} /> : <ActionButton label="Restore" tone="primary" onClick={() => onAction(user, 'active')} />}</td></tr>)}</tbody></table></div></section>;
}

function JobsView({ jobs }: { jobs: AdminJob[] }) {
  const [selectedId, setSelectedId] = useState(jobs[0]?.id);
  const selected = jobs.find((job) => job.id === selectedId) ?? jobs[0];
  return <div className="grid gap-6 xl:grid-cols-[1.3fr_0.7fr]"><section className="admin-card overflow-hidden"><div className="border-b border-slate-200 p-5"><SectionHeader title="Jobs" subtitle="Monitor the full marketplace state; private address fields are only shown in the admin detail." /></div><JobTable jobs={jobs} onSelect={setSelectedId} selectedId={selectedId} /></section>{selected && <aside className="admin-card h-fit p-5"><p className="text-xs font-bold uppercase tracking-wide text-tealbrand">Job detail</p><h2 className="mt-1 text-xl font-black">{selected.title}</h2><div className="mt-5 grid gap-3"><Info label="Customer" value={selected.customer} /><Info label="Category" value={selected.category} /><Info label="Area" value={selected.area} /><Info label="Budget" value={`RM${selected.budget}`} /><Info label="Created" value={selected.createdAt} /><Info label="Private address" value={selected.fullAddress} /></div><div className="mt-5 rounded-xl bg-slate-50 p-4 text-sm text-slate-600">{selected.bids} offer(s) · {selected.status.replace('_', ' ')}</div></aside>}</div>;
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
  return <section className="admin-card p-5"><SectionHeader title={title} subtitle={description} action={<button type="button" className="rounded-lg bg-tealbrand px-3 py-2 text-sm font-bold text-white">Add {title === 'Areas' ? 'area' : 'category'}</button>} /><div className="mt-6 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">{items.map((item, index) => <div key={item} className="flex items-center justify-between rounded-xl border border-slate-200 px-4 py-3"><div><p className="font-bold">{item}</p><p className="mt-1 text-xs text-slate-400">Active · ID {String(index + 1).padStart(3, '0')}</p></div><button type="button" className="text-xs font-bold text-slate-400 hover:text-red-700">Disable</button></div>)}</div></section>;
}

function SettingsView() {
  return <section className="max-w-3xl space-y-5"><div className="admin-card p-5"><SectionHeader title="System settings" subtitle="Runtime-only controls and operational safeguards." /><div className="mt-5 grid gap-3"><Setting label="Environment" value="development / fake data" /><Setting label="Supabase URL" value="Not configured in this preview" /><Setting label="Service role key" value="Never exposed to browser" /><Setting label="Audit retention" value="90 days (planned)" /></div></div><div className="rounded-2xl border border-amber-200 bg-amber-50 p-5 text-sm leading-6 text-amber-900"><p className="font-bold">Production checklist</p><p className="mt-1">Use Supabase Auth admin claims/RLS for admin access, short-lived signed URLs for verification evidence, and server-side audit writes before enabling real moderation actions.</p></div></section>;
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
