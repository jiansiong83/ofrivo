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
