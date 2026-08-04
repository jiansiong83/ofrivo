# Screen Map

The fake-data prototype uses the same navigation contract that later screens will bind to Supabase.

## Public

`Splash → Onboarding → Login / Register → Customer Home`

Forgot password, terms, privacy, account suspended, and profile are shared destinations.

## Customer mode

Bottom navigation: `Home | Post Job | My Jobs | Profile`

```text
Customer Home
├── Post Job → Post Job Preview → My Jobs
├── My Jobs → Job Detail → Received Bids → Provider Profile
└── Job Detail → Accepted Job Detail → Start / Complete → Review / Report → Job History
```

## Provider mode

Bottom navigation: `Job Feed | My Bids | Assigned | Profile`

```text
Profile → Become a Provider → Provider Application → Verification Status
Job Feed → Job Filters → Job Detail → Submit Bid
My Bids → Bid Detail / Edit Bid
Assigned → Assigned Job Detail → Start / Complete / Cancel → Review / Report → Job History
```

Only the approved-provider concept is represented by fake state; real eligibility is Step 3+.

## Admin web

The Admin Web preview exposes Dashboard, Pending Providers, Provider Detail, Users, Jobs, Bids, Reports, Categories, Areas, Audit Log, and System Settings. Provider approval/rejection/suspension, account suspend/restore, and report review actions update local fake data and append an audit event; production data access remains behind Supabase Auth/RLS.

## Interaction notes

- Every list has loading, empty, and error treatment available from shared widgets.
- A job card exposes public location only; full address/contact reveal is a later backend rule.
- Provider cards and bid cards never display another provider's price in the feed.
- Destructive moderation actions are represented by explicit action buttons in the preview; production must add server-side authorization and confirmation before mutating real data.
