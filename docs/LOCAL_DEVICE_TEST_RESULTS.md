# Ofrivo Local Device Test Results

This file is the evidence log for the current local-only validation round. It is intentionally started before device execution so blocked hardware stages are visible.

## Baseline

- Rollback point: `bd59bbb` (`docs: record notification localization`)
- Scope: local Docker Supabase, local Admin Web, Flutter debug app, Android Emulator/USB device only
- Cloudflare/Vercel/Supabase Cloud/Google Play/real SMS/real FCM: not used
- Local Supabase API: `http://127.0.0.1:54421`
- Local Supabase database: `127.0.0.1:54422`
- Local Studio: `http://127.0.0.1:54423`
- Local Mailpit: `http://127.0.0.1:54424`

## Environment preflight

| Component | Result | Evidence |
| --- | --- | --- |
| Docker Desktop | PASS | Docker Server 29.6.2; Compose v5.3.1 |
| Supabase CLI | PASS | `supabase@2.109.1` |
| Flutter/Dart | PASS | Flutter 3.44.8 / Dart 3.12.2 |
| Node/npm | PASS | Node 24.15.0 / npm 11.12.1 |
| ADB | PASS | Android Debug Bridge 1.0.41 / platform tools 37.0.0 |
| Android devices at start | BLOCKED | `adb devices -l` returned no connected devices |

## Local Supabase preflight

| Scenario | Result | Notes |
| --- | --- | --- |
| `supabase start` | PASS | Local `ofrivo-dev` stack starts on ports `54420`-`54427`; optional Windows Analytics/Vector warnings are recorded below |
| `supabase db reset --yes` | PASS | All migrations and seed reapplied; helper command also passes after restart |
| `supabase db lint` | PASS | No schema errors |
| API/Auth health | PASS | HTTP 200 after a local stop/start recovery; one immediate post-reset probe returned transient HTTP 502 |
| REST API | PASS | HTTP 200 with local anon key |
| Studio | PASS | HTTP 200 |
| Mailpit | PASS | HTTP 200 |
| Docker integration runners | PASS | Step 11: 19; no-show: 3; expiry: 3; review: 4 |
| Admin local Supabase integration | PASS | Auth, real data/RLS reads, signed URL, moderation RPCs, audit writes, and fixture restoration |
| Admin browser smoke | PASS | `localhost:3000`; seeded login, live provider queue, approval action |

The post-reset 502 was caused by a Kong/Auth route restart window. Stopping and starting only the Ofrivo local project restored the route; health and all runners then passed. `supabase_vector` may restart on Windows when Docker daemon log access is unavailable, while the tested DB/Auth/REST/Storage/Realtime paths remain healthy.

## Emulator connectivity

- AVD: `medium_phone`
- ADB serial: `emulator-5554`
- Model: `sdk_gphone64_x86_64`
- Android: `16` / API `36`
- `10.0.2.2` ping from Emulator: PASS (0% packet loss)
- TCP `10.0.2.2:54421` from Emulator: PASS
- Debug APK build with local Supabase URL: PASS
- Final debug APK build through `scripts/local-dev.ps1 -Command validate`: PASS
- Debug APK install: BLOCKED (`INSTALL_FAILED_INSUFFICIENT_STORAGE`; `/data` had approximately 543 MB available after cache trim)
- AVD wipe was not performed; no emulator user data was deleted.

## Device matrix

| Device ID | Model | Android version/API | Connection | Result |
| --- | --- | --- | --- | --- |
| `emulator-5554` | `sdk_gphone64_x86_64` | Android 16 / API 36 | Emulator / ADB | Network PASS; APK install BLOCKED by storage |
| — | No USB device connected at preflight | — | — | BLOCKED |

## Scenario matrix

USB-device note: no authorized physical phone was available during this round; all Phone A/Phone B UI scenarios are therefore `BLOCKED`.

| Scenario | Emulator | Phone A | Phone B | Notes |
| --- | --- | --- | --- | --- |
| Local Auth/session restore | BLOCKED | PENDING | PENDING | APK could not install on current AVD |
| Customer creates job and uploads photo | PENDING | PENDING | PENDING | Local Storage |
| Provider feed and bid | PENDING | PENDING | PENDING | Approved provider fixture |
| Accept-bid concurrency | PENDING | PENDING | PENDING | One winner only |
| Address reveal isolation | PENDING | PENDING | PENDING | Accepted provider only |
| Start/complete/reviews/report | PENDING | PENDING | PENDING | Lifecycle flow |
| No-show and expiry | PENDING | PENDING | PENDING | Local RPC paths |
| Notification rows/unread state | PENDING | PENDING | PENDING | No native FCM |
| Restart/offline/retry | PENDING | PENDING | PENDING | No partial state |

## Final round result

Automated local validation and documentation are complete. Core local Supabase, real Admin integration, Admin browser smoke, Flutter checks, Docker integration runners, and debug APK build pass. On-device UI execution is not complete: the Emulator cannot install because of storage and no USB device is connected. These hardware-dependent scenarios remain `BLOCKED`, not successful. No cloud or paid service was used.

## Automated regression evidence

| Check | Result |
| --- | --- |
| `node scripts/validate_version11.mjs` | PASS — 68 checks |
| Flutter analyze | PASS — no issues |
| Flutter test | PASS — 39 tests |
| Debug APK | PASS — `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk` |
| Admin lint | PASS |
| Admin production build | PASS |
| `npm audit` | PASS — 0 vulnerabilities |
| Local reset + lint + health | PASS |
| Local Docker integration | PASS — 19 + 3 + 3 + 4 |

## Implementation changes recorded

- Added the local runbook/helper and ephemeral integration command.
- Added debug-only cleartext HTTP support for local Android testing.
- Added a production bootstrap guard that refuses Demo OTP without Supabase runtime configuration.
- Replaced the Admin fake-data preview path with local Supabase Auth, RLS-backed data reads, signed verification URLs, atomic moderation RPCs, and attributable audit events.
- No service-role key, hosted URL, cloud deployment, SMS provider, FCM credential, or paid integration was added.

## Phase 4 emulator evidence (2026-08-09)

- Device: medium_phone, emulator-5554, sdk_gphone64_x86_64, Android 16 / API 36.
- AVD data was wiped as explicitly authorized; the emulator booted with approximately 5.0 GB available in /data.
- Local Supabase started on API 54421 and the development APK was built, installed, and initialized Supabase successfully.
- The login screen now identifies the configured runtime as Connected to local Supabase backend; it no longer incorrectly shows the Demo-only notice.
- Customer fixture login passed: customer@example.test rendered Good morning, Alex and its seeded Customer jobs.
- Force-stop and relaunch passed: the Supabase session restored to the Customer home without another login.
- Provider fixture login passed: provider@example.test rendered Good morning, Ahmad Plumbing.
- Provider Mode switch passed without changing the authenticated provider identity; the Provider profile showed Ahmad Plumbing and provider@example.test.
- Provider feed passed with one matching Toilet blockage Job; the pre-acceptance detail showed Address protected and hid full address/contact/GPS.

### Smoke matrix

| Scenario | Result | Evidence |
| --- | --- | --- |
| Wipe/boot/storage recovery | PASS | medium_phone booted; /data approximately 5.0 GB free |
| Local Supabase-configured APK install | PASS | Flutter run log: Supabase init completed |
| Customer login and seeded data | PASS | Good morning, Alex; active Customer jobs visible |
| Session restore after force-stop | PASS | Home restored without login |
| Provider login/profile identity | PASS | Good morning, Ahmad Plumbing; provider email visible |
| Provider mode/feed/privacy boundary | PASS | Job Feed, matching Job, Address protected before acceptance |

### Still blocked/deferred

- Full UI job creation with photo upload, bid submission, Customer acceptance, start/complete, reciprocal reviews, and report remains pending on this single-device round.
- USB physical-device and true two-device UI concurrency remain blocked because no phone is connected.
- Native FCM, real SMS, hosted Supabase, and cloud deployment remain intentionally deferred.
- This evidence is local development validation, not a hosted or external-user release approval.

## Phase 5 single-emulator complete lifecycle validation (2026-08-09)

- Device: `medium_phone` / `emulator-5554` / Android 16 (API 36); the authorized data wipe left approximately 5 GB free.
- Runtime: local Docker Supabase API `http://10.0.2.2:54421` from the emulator; no cloud, paid service, SMS provider, or FCM delivery was used.
- Customer `customer@example.test` created and published a real Job with a Material date/time range; the initial emulator was GMT, so the selected `10:00 AM - 11:00 AM` persisted as `10:00Z - 11:00Z`.
- That exposed a display defect: the app was showing the legacy `time_window` text instead of converting UTC endpoints. After the emulator was set to `Asia/Kuala_Lumpur`, the rebuilt APK correctly rendered the same row as `6:00 PM - 7:00 PM`.
- Provider `provider@example.test` saw the matching Job, submitted a RM120 bid, and could not see the private address before acceptance.
- Customer loaded the persisted bid, accepted it, and the Provider then saw the private address and phone.
- Provider marked the Job started and completed; job history recorded Bid Accepted, Job Started, and Job Completed.
- Provider submitted a 5-star review of the Customer, Customer submitted a 5-star review of the Provider, and Provider submitted a safety report. The database contains both reviews and the report.
- The test title contains a literal `%20` because Android `adb input text` treats spaces specially; this is a test-input artifact, not a product-storage defect.
- Fixed an actual PostgREST relationship ambiguity by naming `bids_job_id_fkey` in Customer received-bid and Provider bid queries.
- Fixed Customer Job-card bid counts by embedding `bids!bids_job_id_fkey(count)`; the rebuilt APK displayed `1 offers received` for the completed test Job.

### Phase 5 matrix

| Scenario | Result | Evidence |
| --- | --- | --- |
| Customer Job creation and explicit time range | PASS | Emulator UI plus UTC `scheduled_at`/`scheduled_end_at` rows; local display verified after timezone fix |
| Provider feed and pre-acceptance address privacy | PASS | Address protected until bid acceptance |
| Provider bid submission and Customer bid read | PASS | RM120 bid persisted and rendered in Received bids |
| Bid acceptance and address unlock | PASS | Acceptance message, assigned state, private details visible only after acceptance |
| Start and complete lifecycle | PASS | UI messages and job history events |
| Reciprocal reviews | PASS | Two review rows, both rating 5 |
| Safety report | PASS | One open report row with provider reporter |
| Customer Job-card offer count | PASS | Rebuilt APK displayed `1 offers received` |
| Photo upload through the device UI | NOT RUN | No photo was selected in this smoke path |
| USB physical-device UI | BLOCKED | No USB Android device connected |
| Two-device UI concurrency | BLOCKED | Emulator-only; backend concurrency remains covered by integration tests |
| Hosted/SMS/FCM delivery | DEFERRED | Explicitly outside local-only scope |

This closes the single-emulator local lifecycle gate, but it is not a physical-device, dual-device, or hosted release approval.

## Phase 6 schedule timezone display validation (2026-08-09)

- The emulator time-zone test state was set to `Asia/Kuala_Lumpur`.
- The existing Job row stored `scheduled_at=10:00Z` and `scheduled_end_at=11:00Z`; the rebuilt APK rendered `6:00 PM - 7:00 PM` on the Malaysia-time emulator.
- Customer and Provider repositories now format the display range from the parsed UTC endpoints after local conversion; rows with no endpoints still use the legacy `time_window` fallback.
- Added a regression test for local range formatting and the legacy fallback.
- This validates the local display conversion only; it does not close the physical-device or hosted gates.


## Phase 7 device photo-upload validation (2026-08-09)

- On `medium_phone` / `emulator-5554` (Android 16/API 36, `Asia/Kuala_Lumpur`), Customer selected one image through the Android system Photo Picker.
- The Job preview showed `1 photo(s) attached`; publishing returned `Job published.` and the new Job appeared as `open` in My Jobs.
- Customer-authenticated REST readback found one `job_photos` row and a private `job-photos` object returned HTTP 200.
- Provider-authenticated `public_job_feed` readback found the same Job with one photo path; the protected Storage object returned HTTP 200 through the Provider session.
- The test address contains only local adb-input text and is not production data. This validates local emulator photo selection, upload, and authorized reads only.

### Phase 7 photo access boundary

- Unauthenticated object access returned HTTP 400; pending Provider Feed returned zero rows and pending Provider Storage access returned HTTP 400.
- Customer and approved Provider sessions both returned HTTP 200 for the same local object.

### Phase 8 Git history scan

## Phase 9 full local regression rerun (2026-08-09)

- Runtime: local Docker Supabase API `http://127.0.0.1:54421`; Android emulator `emulator-5554` only (Android 16/API 36, `Asia/Kuala_Lumpur`).
- Provider profile/category integration passed 22 checks; Step 11 security/concurrency passed 19 checks; Phase 3 scheduling/lifecycle passed 14 checks; no-show, expiry, and review runners passed 3, 3, and 4 checks; Admin live integration passed with 6 audit events.
- Version 1.1 contract validation passed 69 checks and closed-beta contract validation passed 10 checks.
- Flutter analyze passed, 53 Flutter tests passed, and a new Debug APK built successfully. The APK installed and launched on `com.example.ofrivo_mobile`.
- Admin lint and production build passed. No source changes were required by this rerun.

### Phase 9 matrix

| Scenario | Result | Evidence |
| --- | --- | --- |
| Provider/category/RLS/profile controls | PASS | 22 local integration checks |
| Cross-account privacy, Storage, lifecycle, concurrency | PASS | Step 11 local runner, 19 checks |
| Schedule, expiry, no-show, review, Admin RPCs | PASS | 14 + 3 + 3 + 4 + Admin audit checks |
| Flutter analyze/tests/APK | PASS | Analyze clean; 53 tests; APK installed/launched |
| Admin lint/production build | PASS | Next.js production build completed |
| USB physical-device UI | BLOCKED | Only `emulator-5554` is connected |
| Two-device UI concurrency | BLOCKED | Backend concurrency passes; no second UI device |
| Hosted/cloud/SMS/FCM | DEFERRED | Explicitly outside this local-only phase |

- Git-native scan covered 55 reachable commits; sensitive file paths and high-risk credential patterns both returned zero hits.
- No secrets were printed during the scan. Third-party gitleaks/trufflehog execution remains unavailable locally.
- This does not validate hosted environment secrets or deployment configuration.
