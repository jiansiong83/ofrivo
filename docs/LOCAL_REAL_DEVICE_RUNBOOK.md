# Ofrivo Local Real-Device Runbook

This runbook is for local development only. It does not deploy to Cloudflare, Vercel, Supabase Cloud, Google Play, or any other online environment. It does not configure paid SMS or FCM delivery.

## Local endpoints

Ofrivo intentionally uses ports `54420`–`54427` so it can run beside other local projects:

| Service | Local endpoint |
| --- | --- |
| API, Auth, REST, Storage | `http://127.0.0.1:54421` |
| PostgreSQL | `127.0.0.1:54422` |
| Studio | `http://127.0.0.1:54423` |
| Mailpit | `http://127.0.0.1:54424` |
| SMTP | `127.0.0.1:54425` |
| POP3 | `127.0.0.1:54426` |
| Analytics | `http://127.0.0.1:54427` |

Do not replace `54421` with the default Supabase port `54321` for this repository.

## Start and reset

From `F:\Dev\Ofrivo`:

```powershell
.\scripts\local-dev.ps1 -Command start
.\scripts\local-dev.ps1 -Command status
.\scripts\local-dev.ps1 -Command health
.\scripts\local-dev.ps1 -Command reset
```

The reset reapplies every migration and the local seed. The script reads the local anon key only into the current process; it never prints or stores it and never passes `service_role` to Flutter.

Direct CLI equivalents:

```powershell
npx.cmd --yes supabase@2.109.1 start
npx.cmd --yes supabase@2.109.1 status --output env
npx.cmd --yes supabase@2.109.1 db reset --yes
npx.cmd --yes supabase@2.109.1 db lint
```

## Admin Web

```powershell
.\scripts\local-dev.ps1 -Command admin
```

Open `http://localhost:3000`. The current Admin Web is a local fake-data operations preview. Its UI actions and audit view are tested locally, but this round does not add a Supabase-backed Admin repository.

## Flutter Emulator

An Android Emulator reaches the Windows host through `10.0.2.2`:

```powershell
.\scripts\local-dev.ps1 -Command emulator
```

Equivalent runtime values:

```text
SUPABASE_URL=http://10.0.2.2:54421
APP_ENV=development
```

## Flutter physical device

Connect an authorized phone by USB, confirm it with `adb devices`, then run:

```powershell
.\scripts\local-dev.ps1 -Command adb-reverse
.\scripts\local-dev.ps1 -Command device
```

The script applies `adb reverse tcp:54421 tcp:54421` and passes:

```text
SUPABASE_URL=http://127.0.0.1:54421
APP_ENV=development
```

After a phone reconnect or reboot, run the reverse command again. Set `OFRIVO_FLUTTER_DEVICE_ID` when more than one device is connected.

## Authentication boundaries

- Seeded local Email/Password identities are used for the full Supabase-backed workflow.
- Demo OTP `123456` is tested in Fake/Demo mode only; it is not a real SMS flow.
- Real SMS providers are intentionally not configured.
- Production must never silently fall back to Demo OTP; this is a validation gate for the local round.

## Validation flow

Run the customer/provider lifecycle with seeded local accounts, then test Admin Web independently:

1. Customer signs in or registers, creates a job, and uploads photos.
2. An approved provider reads the safe feed and submits a bid.
3. Customer accepts the bid; only the accepted provider can read full address/contact fields.
4. Provider starts and completes the job.
5. Customer and provider submit reciprocal reviews.
6. Participant report and no-show paths are exercised.
7. Notification rows, outbox entries, unread state, and notification navigation are checked; native FCM is not tested.
8. Provider A and Provider B race to bid/accept; exactly one bid wins and the other is rejected.
9. Restart, offline/retry, private Storage, RLS, and cross-account boundaries are recorded.

## Automated validation

```powershell
.\scripts\local-dev.ps1 -Command validate
.\scripts\local-dev.ps1 -Command integration
node supabase/tests/validate_step11.mjs
cd apps\admin
npm.cmd run lint
npm.cmd run build
npm.cmd audit
cd ..\..
```

The `integration` command reads the local status values and exposes them only to
the Docker runner processes. It never prints or passes the service role key to
Flutter.

## Evidence and blockers

Record each device model, Android version, connection mode, scenario result, and timestamp in `docs/LOCAL_DEVICE_TEST_RESULTS.md`. A missing device, unavailable emulator, or unavailable external provider is recorded as `BLOCKED`, never as a successful test.
