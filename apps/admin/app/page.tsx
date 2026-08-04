const navigation = ['Dashboard', 'Pending Providers', 'Users', 'Jobs', 'Bids', 'Reports', 'Categories', 'Areas', 'Audit Log', 'System Settings'];

const metrics = [
  { label: 'Open jobs', value: '24', note: '+8% this week', tone: 'text-emerald-700' },
  { label: 'Pending providers', value: '7', note: 'Needs review', tone: 'text-orange-700' },
  { label: 'Active providers', value: '86', note: 'Johor Bahru', tone: 'text-blue-700' },
  { label: 'Open reports', value: '3', note: 'Review promptly', tone: 'text-red-700' },
];

export default function AdminHome() {
  return (
    <main className="min-h-screen lg:flex">
      <aside className="border-b border-slate-200 bg-white px-5 py-6 lg:min-h-screen lg:w-72 lg:border-b-0 lg:border-r">
        <div className="mb-8 flex items-center gap-3">
          <div className="grid h-10 w-10 place-items-center rounded-xl bg-tealbrand text-lg font-black text-white">O</div>
          <div><p className="font-extrabold tracking-tight">Ofrivo</p><p className="text-xs text-slate-500">Admin preview</p></div>
        </div>
        <nav aria-label="Admin navigation" className="grid gap-1">
          {navigation.map((item, index) => <button key={item} className={`rounded-xl px-3 py-2.5 text-left text-sm font-semibold ${index === 0 ? 'bg-teal-50 text-tealbrand' : 'text-slate-600 hover:bg-slate-50'}`}>{item}</button>)}
        </nav>
        <div className="mt-8 rounded-2xl bg-slate-50 p-4 text-sm text-slate-600"><p className="font-bold text-slate-800">Step 1 shell</p><p className="mt-1">Backend actions are intentionally disabled until Step 2.</p></div>
      </aside>
      <section className="flex-1 p-5 sm:p-8">
        <header className="mb-8 flex flex-wrap items-start justify-between gap-4">
          <div><p className="text-sm font-semibold text-tealbrand">Operations overview</p><h1 className="mt-1 text-3xl font-black tracking-tight">Dashboard</h1><p className="mt-2 text-slate-500">A calm view of jobs, providers, and safety work.</p></div>
          <div className="rounded-full border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-600">Fake data · No backend</div>
        </header>
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">{metrics.map((metric) => <article className="admin-card p-5" key={metric.label}><p className="text-sm text-slate-500">{metric.label}</p><p className={`mt-3 text-3xl font-black ${metric.tone}`}>{metric.value}</p><p className="mt-2 text-xs font-semibold text-slate-500">{metric.note}</p></article>)}</div>
        <div className="mt-6 grid gap-6 xl:grid-cols-[1.4fr_1fr]">
          <section className="admin-card p-5"><div className="flex items-center justify-between"><div><h2 className="text-lg font-extrabold">Recent jobs</h2><p className="mt-1 text-sm text-slate-500">Public preview only; contact details stay private.</p></div><button className="rounded-lg border border-slate-200 px-3 py-2 text-sm font-bold text-tealbrand">View all</button></div><div className="mt-5 overflow-x-auto"><table className="w-full min-w-[520px] text-left text-sm"><thead className="border-b border-slate-200 text-xs uppercase tracking-wide text-slate-500"><tr><th className="pb-3">Job</th><th className="pb-3">Area</th><th className="pb-3">Status</th><th className="pb-3 text-right">Bids</th></tr></thead><tbody>{[['Toilet blockage', 'Mount Austin', 'Open', '3'], ['Install ceiling fan', 'Taman Molek', 'Open', '1'], ['Move a washing machine', 'Permas Jaya', 'Assigned', '4']].map((row) => <tr className="border-b border-slate-100 last:border-0" key={row[0]}>{row.map((cell, index) => <td className={`py-4 ${index === 3 ? 'text-right font-bold' : ''}`} key={cell}>{cell}</td>)}</tr>)}</tbody></table></div></section>
          <section className="admin-card p-5"><h2 className="text-lg font-extrabold">Safety queue</h2><p className="mt-1 text-sm text-slate-500">Keep review actions visible and auditable.</p><div className="mt-5 grid gap-3">{[['Pending provider verification', '7 waiting', 'bg-orange-50 text-orange-800'], ['Reports requiring review', '3 open', 'bg-red-50 text-red-800'], ['Audit events today', '18 events', 'bg-blue-50 text-blue-800']].map(([title, value, tone]) => <div className={`rounded-xl p-4 ${tone}`} key={title}><p className="font-bold">{title}</p><p className="mt-1 text-sm">{value}</p></div>)}</div></section>
        </div>
        <p className="mt-8 text-center text-xs text-slate-400">Ofrivo · Offers for every job · Admin layout placeholder</p>
      </section>
    </main>
  );
}

