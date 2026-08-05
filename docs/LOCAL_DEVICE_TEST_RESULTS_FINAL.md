# Ofrivo Local Device Test Results — Final

Validation date: 2026-08-05. This is a local-only report. No Cloudflare, Vercel, Supabase Cloud, Google Play, real SMS, native FCM, payment, maps, chat, or membership service was used.

## Environment

- Base before this validation: `2ac0c3f`; rollback point: `bd59bbb`.
- Docker Desktop 29.6.2; Supabase CLI `2.109.1`; Flutter 3.44.8 / Dart 3.12.2; Node 24.15.0 / npm 11.12.1.
- AVD: `medium_phone`, Android 16 / API 36, serial `emulator-5554`, model `sdk_gphone64_x86_64`.
- The AVD was explicitly wiped with `-wipe-data` because the previous install had only about 543 MB free. After the wipe/reboot, `/data` had about 3.0 GB free and the debug APK installed successfully.
- Desktop API: `http://127.0.0.1:54421`; emulator API: `http://10.0.2.2:54421`; database `127.0.0.1:54422`; Studio `http://127.0.0.1:54423`; Mailpit `http://127.0.0.1:54424`.
- Docker briefly required a local restart after the emulator reboot. PostgreSQL completed recovery fsync; final API/Auth, REST, Studio, and Mailpit probes were HTTP 200. The unrelated `baccarat-ai-platform` project was not manually changed.

## Automated results

| Check | Result |
| --- | --- |
| Version 1.1 contract validator | PASS — 68 checks |
| `flutter analyze` | PASS — no issues |
| `flutter test` | PASS — 39 tests |
| Configured local debug APK | PASS — built and installed |
| Admin lint / production build | PASS |
| `npm audit` | PASS — 0 vulnerabilities |
| Local Docker integration | PASS — Step 11: 19; no-show: 3; expiry: 3; review: 4; Admin: 6 audit events |

## Emulator UI/E2E results

| Flow | Result |
| --- | --- |
| Onboarding, login, customer Auth | PASS |
| Session restore after force-stop/relaunch | PASS |
| English ↔ Bahasa Melayu switch | PASS (`Selamat pagi`) |
| Notification centre and mark-all-read | PASS |
| Customer post-job form, preview, publish, My Jobs | PASS |
| Android Photo Picker | PASS (`1/5 photos selected`) |
| Provider approval guard | PASS |
| Approved provider feed and pre-bid address privacy | PASS |
| Provider bid (RM170) | PASS |
| Customer received-bid view and accept | PASS |
| Accepted-provider address/phone reveal | PASS |
| Start → in-progress → complete | PASS |
| Provider review and customer review | PASS on rebuilt APK; both returned to Job Detail |
| Provider report | PASS on rebuilt APK; confirmation and Job Detail return |
| Airplane-mode error and retry after reconnect | PASS; retry restored Job Feed |
| Final exception scan | PASS; no recent `FATAL`, `Unhandled Exception`, `GoError`, or Dart initialization error |

The test-created address contains a literal `%2C%20` sequence because `adb input text` encoded the comma/space; this is test-data encoding only, not an app authorization issue.

## Fixes made from device evidence

- `apps/mobile/lib/features/onboarding/onboarding_screen.dart`: authenticated Supabase sessions now leave onboarding and restore the customer shell after restart. Demo mode remains on onboarding for widget tests.
- `apps/mobile/lib/features/job_lifecycle/job_lifecycle_screens.dart`: review/report success now uses a role-aware Job Detail route instead of `context.pop()`. Previously the database write succeeded but the screen logged `GoError: There is nothing to pop`.

## Remaining gates

- Physical Android phone: `BLOCKED` — no authorized USB device was connected, so `adb reverse` and a physical-device result are not claimed.
- Dual-device UI concurrency: `BLOCKED` — concurrent acceptance is covered by the local 19-check integration runner, but two-device UI was not claimed.
- Native FCM delivery, real SMS, hosted Supabase, and release distribution remain intentionally deferred.

## Classification

**Local automated validation is complete and local Emulator UI/E2E is substantially complete.** The customer/provider lifecycle, privacy boundary, notification, photo picker, session restore, review/report, and offline-retry paths passed on the wiped `medium_phone` AVD. Physical-device and dual-device UI remain explicitly blocked rather than inferred from automation.
