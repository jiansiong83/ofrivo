# Ofrivo

Ofrivo is a Johor Bahru local-service job-bid prototype: customers post a job, approved providers submit offers, and the customer chooses who completes the work.

Brand line: **Post a job. Compare offers. Get it done.**

## Current scope

This repository contains the Step 0 + Step 1 foundation, the local Step 2 Supabase database foundation, the Step 3 auth/profile adapter, the Step 4 customer job flow, the Step 5 provider application flow, the Step 6 provider feed/bid flow, the Step 7 transactional accept-bid flow, the Step 8 lifecycle/review/report flow, the Step 9 Admin Web console, and the Step 10 push-ready notification pipeline from the project master plan:

- Flutter Android app shell with Riverpod, go_router, Material 3, feature-based folders, and fake data.
- Next.js + TypeScript + Tailwind Admin Web console with login preview, operational dashboard, provider verification, user controls, jobs, bids, reports, taxonomy, settings, and audit log.
- Product, screen, UI, data, security, test, release, and project-status documentation.
- Supabase migration, seed, storage policy, RLS, and transaction-RPC source files. They are not applied to Supabase Cloud in this repository.
- Mobile Email + Password auth with session restore, profile guards, and a local demo fallback.
- Customer job creation with validation, private contact fields, photo selection, draft/preview/publish, My Jobs, Job Detail, and cancellation.
- Provider application with service categories, areas, private identity evidence, work photos, and Pending/Approved/Rejected/Suspended status states.
- Provider Job Feed with public-field filtering, job detail privacy boundaries, bid submission/edit/withdraw, and My Bids.
- Customer Received Bids, Provider Profile, transactional offer acceptance, automatic rejection of competing pending bids, assigned-job state, address/contact reveal for the accepted provider, and notifications.
- Transactional start/complete/cancel actions, customer/provider reviews, participant-aware reports, and job event history.
- Admin moderation actions run against explicit local fake data in the preview and append attributable audit events; production Supabase Auth/RLS wiring remains runtime-only.
- Push-ready notifications include device-token registration, matching-job/new-bid/verification/expiry event fan-out, unread badges, and read-all state; native FCM delivery remains runtime-configured.

The mobile app connects to Supabase only when explicit `--dart-define` values are supplied; otherwise it uses local demo data. Payments, chat, maps, AI pricing, and production FCM credentials/native delivery remain deferred.

## Repository map

```text
apps/mobile/    Flutter Android prototype
apps/admin/     Next.js admin shell
supabase/       Step 2 migration, seed, storage policy, RLS, RPC, and test notes
docs/           Product and engineering contracts
assets/         Branding, icons, and mockup placeholders
```

## Local development

Flutter stable 3.44.8 is prepared for the mobile commands, and Node.js is used for the admin commands. Run them from their respective app directories:

```text
flutter pub get
flutter analyze
flutter test
flutter build apk --debug

npm install
npm run lint
npm run build
```

Environment variables are documented in `docs/SECURITY.md`; no backend values are committed. Without the defines, the mobile app clearly runs in local demo mode.

## Source of truth

The full product baseline is [`Ofrivo_Project_Master_Plan.md`](./Ofrivo_Project_Master_Plan.md). Each implementation round must remain inside its stated step and update `docs/PROJECT_STATUS.md` and `docs/CHANGELOG.md`.
