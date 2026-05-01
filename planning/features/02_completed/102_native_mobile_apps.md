# Feature — Native Mobile Apps (iOS + Android, App Store)
**Created:** 2026-03-26 | **Updated:** 2026-03-26 | **Mode:** STUDIO | **Status:** COMPLETE
**Priority:** Low | **Complexity:** Medium (delivery workflow, not new code)
**Flag:** `--mobile` flag to `deliver.sh` (already exists). FCM gated by `FCM_ENABLED=true` (default false).

---

## Objective

Deliver the Flutter app as native iOS and Android binaries on the App Store and Google Play.
The Flutter code already runs on mobile. The gaps are: FCM push notifications (Web Push API
doesn't work for background push on iOS), a concrete `codemagic.yaml` template, and a complete
App Store submission guide.

---

## What's Already in Place (confirmed from code)

- `deliver.sh --mobile` flag exists and calls `prepare_mobile.sh`.
- `prepare_mobile.sh`: injects domain into `AndroidManifest.xml` + `Runner.entitlements`,
  generates `assetlinks.json` + `apple-app-site-association`, runs `flutter_native_splash` +
  `flutter_launcher_icons`. Deep links fully handled.
- `client.json` already has `BUNDLE_ID` and `APPLE_TEAM_ID` fields.
- `save-push-subscription` Edge Function exists — needs FCM branch added (see below).
- `send-push` Edge Function exists (Web Push only) — needs FCM delivery path added.
- `execution/ci/` directory does NOT exist yet — must be created.
- `15_mobile.md` delivery guide does NOT exist yet — must be created (not "expanded").

---

## What's Missing

### 1. FCM Push Notifications (native)

Web Push API doesn't deliver background notifications on iOS (even PWA). For locked-screen
push on both platforms, Firebase Cloud Messaging is required.
FCM is opt-in: `FCM_ENABLED=true` in client.json (default false — most clients don't need it).

**`AppEnv` addition:**
```dart
static const fcmEnabled = bool.fromEnvironment('FCM_ENABLED', defaultValue: false);
```

**New dependencies (`pubspec.yaml`) — only add when FCM_ENABLED=true:**
```yaml
firebase_core: ^3.x
firebase_messaging: ^15.x
```

**New files:**
- `lib/core/push/push_service_fcm.dart` — conditional import (non-web only)
  - Gated: `if (!kIsWeb && AppEnv.fcmEnabled)`
  - `FirebaseMessaging.instance.requestPermission()`
  - `FirebaseMessaging.instance.getToken()` → FCM token
  - Calls `save-push-subscription` Edge Function with `{fcm_token: ...}` payload
  - Registers `getInitialMessage()` + `onMessageOpenedApp` handlers → calls `_handleDeepLink()`
- `firebase_options.dart` — generated per client via FlutterFire CLI:
  ```bash
  flutterfire configure --project=<firebase-project-id>
  ```

**Schema — `100_fcm_tokens.sql`** (NOT 103 — next available after 099):
```sql
-- Make Web Push fields nullable (FCM rows don't have endpoint/p256dh/auth).
ALTER TABLE push_subscriptions
  ALTER COLUMN endpoint   DROP NOT NULL,
  ALTER COLUMN p256dh     DROP NOT NULL,
  ALTER COLUMN auth_key   DROP NOT NULL;

-- Add FCM token column.
ALTER TABLE push_subscriptions ADD COLUMN IF NOT EXISTS fcm_token text UNIQUE;

-- Relax identifier_required to also allow fcm_token-only rows.
ALTER TABLE push_subscriptions DROP CONSTRAINT IF EXISTS identifier_required;
ALTER TABLE push_subscriptions ADD CONSTRAINT identifier_required
  CHECK (user_id IS NOT NULL OR client_email IS NOT NULL);
-- (fcm_token rows must still have user_id or client_email — keep that constraint)
```

**`save-push-subscription/index.ts`** — add FCM branch:
- If payload has `fcm_token`: upsert on `(user_id, fcm_token)` or `(client_email, fcm_token)`,
  no `endpoint`/`p256dh`/`auth` fields.
- Existing Web Push path unchanged.

**`send-push/index.ts`** — add FCM delivery path alongside Web Push:
```ts
if (sub.fcm_token) {
  // Call FCM HTTP v1 API with Firebase service account credentials
  // Env var: FIREBASE_SERVICE_ACCOUNT (JSON string from Firebase Console)
}
```

**FCM notification tap handling (missing from original spec):**
When the app is closed and user taps an FCM notification, `app_links` won't fire.
FCM requires its own handlers in `main.dart` (or `push_service_fcm.dart`):
- `FirebaseMessaging.instance.getInitialMessage()` — app launched from tapped notification
- `FirebaseMessaging.onMessageOpenedApp` — app backgrounded, user taps notification
Both should route the `data.url` payload into the existing `_handleDeepLink()` function.

**Platform config (per-client, not in repo):**
- `android/app/google-services.json` — from Firebase Console
- `ios/Runner/GoogleService-Info.plist` — from Firebase Console
- `AndroidManifest.xml` / `AppDelegate.swift`: handled automatically by `firebase_messaging` plugin

### 2. Codemagic YAML Template

New directory: `execution/ci/` (create it).
New file: `execution/ci/codemagic.yaml.tpl`

Tokenised with `CLIENT_*` values, patched by `deliver.sh --mobile`. Contains:
- iOS workflow: `flutter build ipa --release --obfuscate --split-debug-info=build/symbols --dart-define-from-file=client.json`
- Android workflow: `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols --dart-define-from-file=client.json`
- Environment variable blocks for Supabase + Firebase secrets
- Automatic distribution to TestFlight + Google Play internal track

`deliver.sh --mobile`: patch `codemagic.yaml.tpl` → `codemagic.yaml` with client tokens.

### 3. Delivery Guide — CREATE `15_mobile.md` (does not exist yet)

New file: `planning/delivery_guide/15_mobile.md`. Cover:
- Firebase project setup (one per client — free Spark plan sufficient for FCM)
- `flutterfire configure` walkthrough
- Apple Developer Program enrollment ($99/yr — client pays)
- Google Play Console registration ($25 one-time — client pays)
- Codemagic setup: connect repo, add signing certificates, add env vars
- TestFlight distribution before public App Store submission
- App Store review timeline (1-3 days iOS, hours Android)
- Privacy policy requirement (already generated by legal pages module — link it)
- FCM setup checklist (only when `FCM_ENABLED=true`)

---

## client.json additions

```json
"BUNDLE_ID": "com.clientname.app",
"APPLE_TEAM_ID": "XXXXXXXXXX",
"FCM_ENABLED": false
```

`FCM_ENABLED` defaults to `false`. Set to `true` only when client wants mobile push notifications.

`deliver.sh --mobile`: already runs `prepare_mobile.sh`. Add:
- Patch `codemagic.yaml.tpl` → `codemagic.yaml`
- If `FCM_ENABLED=true`: deploy updated `send-push`, push `FIREBASE_SERVICE_ACCOUNT` secret
- Print FCM setup checklist (gated on `FCM_ENABLED=true`)

---

## Acceptance Criteria

- [ ] `flutter build apk --release` and `flutter build ipa --release` succeed with `client.json` values
- [ ] `FCM_ENABLED=false` → zero FCM code initialised (firebase packages not required)
- [ ] `FCM_ENABLED=true` → FCM token captured on app launch and stored in `push_subscriptions`
- [ ] Push notification received on locked iOS and Android device (when FCM_ENABLED=true)
- [ ] Tapping FCM notification routes to correct in-app screen via `_handleDeepLink()`
- [ ] Web Push subscriptions unaffected (endpoint/p256dh/auth still work after schema migration)
- [ ] `codemagic.yaml` triggers automated build on push to main branch
- [ ] App Store and Play Store listings live with client branding
- [ ] All new files ≤ 300 lines
