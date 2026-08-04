# Ofrivo

Ofrivo is a Johor Bahru local-service job-bid prototype: customers post a job, approved providers submit offers, and the customer chooses who completes the work.

Brand line: **Post a job. Compare offers. Get it done.**

## Current scope

This repository contains the Step 0 + Step 1 foundation, the local Step 2 Supabase database foundation, the Step 3 auth/profile adapter, and the Step 4 customer job flow from the project master plan:

- Flutter Android app shell with Riverpod, go_router, Material 3, feature-based folders, and fake data.
- Next.js + TypeScript + Tailwind admin shell with placeholder dashboard content.
- Product, screen, UI, data, security, test, release, and project-status documentation.
- Supabase migration, seed, storage policy, RLS, and transaction-RPC source files. They are not applied to Supabase Cloud in this repository.
- Mobile Email + Password auth with session restore, profile guards, and a local demo fallback.
- Customer job creation with validation, private contact fields, photo selection, draft/preview/publish, My Jobs, Job Detail, and cancellation.

The mobile app connects to Supabase only when explicit `--dart-define` values are supplied; otherwise it uses local demo data. Provider application/feed/bids, payments, chat, maps, AI pricing, and FCM remain deferred.

## Repository map

```text
apps/mobile/    Flutter Android prototype
apps/admin/     Next.js admin shell
supabase/       Step 2 migration, seed, storage policy, RLS, RPC, and test notes
docs/           Product and engineering contracts
assets/         Branding, icons, and mockup placeholders
```

## Local development

Flutter is required for the mobile commands and Node.js for the admin commands. Run them from their respective app directories once the SDKs are available:

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
