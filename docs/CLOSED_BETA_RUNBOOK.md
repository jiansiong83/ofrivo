# Ofrivo Closed Beta Runbook

This runbook is the release gate for Step 12. It separates reproducible local preparation from actions that require the Ofrivo Google Play and Supabase environments.

## Signed APK / AAB

1. Choose and register the permanent Android application ID before the first Play upload. The current `com.example.ofrivo_mobile` value is a development placeholder.
2. Create a production upload keystore outside the repository. Copy `apps/mobile/android/key.properties.example` to `apps/mobile/android/key.properties`, fill it locally, and keep both the keystore and passwords in the team secret manager.
3. Run the release checks from `apps/mobile`:

   ```powershell
   F:\Dev\FlutterSDK\bin\flutter.bat analyze
   F:\Dev\FlutterSDK\bin\flutter.bat test
   F:\Dev\FlutterSDK\bin\flutter.bat build appbundle --release
   ```

   The release build refuses to run without `key.properties`. `OFRIVO_ALLOW_DEBUG_RELEASE_SIGNING=true` is allowed only for a local smoke build and must never be uploaded to Play.
4. Record the version from `pubspec.yaml` (`versionName+versionCode`), the AAB SHA-256, the Git commit, and the build date in the release ticket. Archive the exact AAB in the release store.

   ```powershell
   Get-FileHash build\app\outputs\bundle\release\app-release.aab -Algorithm SHA256
   ```

## Google Play track sequence

1. Upload the signed AAB to an internal test track and add the approved tester email list.
2. Verify install, sign-in, customer job creation, provider application, feed/bid, accept-bid, lifecycle, review/report, notifications, retry, offline, and image-validation paths on a clean Android device.
3. Promote the same immutable artifact to a closed-testing track only after the internal smoke checklist is green. Do not rebuild between tracks.
4. Capture tester feedback through the bug report template and record severity, app version, device/Android version, reproducibility, and evidence.

## Test identities and jobs

Use accounts created in the isolated beta Supabase project; never put passwords in this repository or in screenshots.

| Identity | Purpose | Required checks |
| --- | --- | --- |
| `customer.closedbeta@ofrivo.example` | Customer account | Register/login, profile restore, publish/cancel job, compare bids, accept bid, complete/review/report |
| `provider.closedbeta@ofrivo.example` | Approved provider | Provider mode, feed filters, bid submit/edit/withdraw, accepted job, completion |
| `provider.pending.closedbeta@ofrivo.example` | Pending provider guard | Application status, private evidence access, feed denial until approval |
| `admin.closedbeta@ofrivo.example` | Admin preview only | Local Admin Web moderation and audit preview; never grant service-role credentials to a client |

Prepare deterministic jobs in the beta project:

- `CB-JOB-001`: open, non-urgent handyman job with two eligible providers.
- `CB-JOB-002`: urgent cleaning job with one bid and one no-bid provider.
- `CB-JOB-003`: accepted/completed job for review and report checks.

Reset or recreate these records between test cycles so a prior tester cannot affect another tester's privacy checks.

## Bug report process

Every issue uses `docs/BUG_REPORT_TEMPLATE.md`. Triage P0/P1 issues before promotion; attach logs or screenshots only after removing email addresses, phone numbers, addresses, tokens, and private evidence. A release owner links each fixed issue to a new build number and reruns the affected checklist path.

## Rollback build

- Keep the previous Play-approved AAB and its SHA-256 in the release store.
- If a closed-beta build is unsafe, halt promotion, disable the affected test track, and restore the previous immutable AAB/version in Play Console.
- Record the rollback reason, affected build number, tester impact, and follow-up issue. Never overwrite a released artifact or reuse its version code.
- For local reproduction, checkout the recorded commit in a disposable worktree and rebuild only with the matching signing configuration.

## External gates

Google Play Console access, a permanent application ID, a production upload keystore, an isolated Supabase project, and real tester accounts are required to mark Closed Beta complete. Until those are supplied, the repository can validate the release contract and produce local smoke artifacts but must not claim an internal or closed test run.
