# Appendix: Mobile App Delivery (iOS & Android)

The Flutter codebase targets web, iOS, and Android from the same source. The Supabase backend,
edge functions, and all business logic are unchanged — only the build target and distribution differ.
You do not need separate backend work.

---

## What changes vs web-only

| Area | Web | Mobile |
|------|-----|--------|
| Build command | `flutter build web` | `flutter build apk/appbundle/ipa` |
| Loading screen | `index.html` HTML/CSS | Native splash screen (separate package) |
| Hosting | Cloudflare/Vercel/Netlify | App Store / Google Play |
| SPA routing | `_redirects` + path strategy | Not applicable (native routing) |
| Stripe redirect | Browser tab, returns to app via URL | Deep link required |
| PWA icons | `web/icons/*.png` | Separate Android/iOS icon sets |

---

## Accounts you need before starting

| Account | Cost | For |
|---------|------|-----|
| Apple Developer Program | $99/yr | iOS build signing + App Store |
| Google Play Developer | $25 one-time | Google Play Console |
| Xcode (macOS only) | Free | iOS builds — requires a Mac |

> iOS builds require a Mac. If you don't have one, use Codemagic CI — see Step 8.
> It handles iOS builds on Mac M1 in the cloud with no Mac required on your side.

---

## Step 1 — Add mobile fields to client.json

Two new fields are required for mobile delivery:

```json
"BUNDLE_ID":     "com.acmestudio.app",   // reverse-domain, unique per client
"APPLE_TEAM_ID": "XXXXXXXXXX"            // 10-char ID — developer.apple.com → Membership
```

> Use `com.<CLIENT_SLUG>.app` as the bundle ID pattern to keep it consistent across clients.

---

## Step 2 — Drop the asset files

Mobile needs two PNG files committed to the repo:

| File | Size | Purpose |
|------|------|---------|
| `assets/icons/app_icon.png` | 1024×1024 px, **no alpha channel** (iOS rejects transparency) | App icon — all sizes auto-generated |
| `assets/images/splash_logo.png` | Any size, transparency OK | Centred on splash background |

---

## Step 3 — Run prepare_mobile.sh

One script handles everything:

```bash
./prepare_mobile.sh
```

What it does automatically:
- Injects the domain (from `SITE_URL`) into `AndroidManifest.xml` and `Runner.entitlements`
- Sets `android:label` to `CLIENT_NAME`
- Patches the splash background colour in `pubspec.yaml` to match `COLOR_SURFACE`
- Generates `web/.well-known/assetlinks.json` (Android App Links verification)
- Generates `web/.well-known/apple-app-site-association` (iOS Universal Links verification)
- Runs `dart run flutter_native_splash:create` (if `splash_logo.png` exists)
- Runs `dart run flutter_launcher_icons` (if `app_icon.png` exists)

Or trigger it via the main delivery script:
```bash
./deliver.sh --mobile
```

---

## Step 4 — Complete the two manual deep link steps

`prepare_mobile.sh` sets up both ends of Universal Links / App Links automatically, but two steps
still require human hands:

**4a. Paste the Android release keystore SHA-256 fingerprint**

`web/.well-known/assetlinks.json` is generated with a placeholder. Replace it:
```bash
keytool -list -v -keystore acme-studio.jks -alias acme-studio | grep SHA256
```
Then open `web/.well-known/assetlinks.json` and replace `TODO:REPLACE_WITH_RELEASE_KEYSTORE_SHA256_FINGERPRINT` with the result.

**4b. Register Associated Domains in Xcode (iOS)**

`ios/Runner/Runner.entitlements` is generated with the correct domain, but Xcode must reference the file:
1. Open `ios/Runner.xcodeproj` in Xcode
2. Select `Runner` target → `Signing & Capabilities`
3. Click **+** → **Associated Domains**
4. Xcode detects `Runner.entitlements` automatically — no further action needed

> The `web/.well-known/` files are included in the Flutter web build and served at
> `https://yourdomain.com/.well-known/`. Both Apple and Google call these URLs to verify
> the domain ownership before activating Universal Links / App Links.
>
> **Netlify users:** add a `_headers` rule so `apple-app-site-association` is served as
> `application/json` (Apple requires this, even without the `.json` extension):
> ```
> /.well-known/apple-app-site-association
>   Content-Type: application/json
> ```

**The `app_links` package and routing are already wired in `main.dart`** — no Flutter code changes
needed. Incoming deep links are automatically routed via `Get.toNamed(uri.path, parameters: uri.queryParameters)`.

---

## Step 5 — Build commands

**Android (APK for testing / AAB for Play Store):**
```bash
flutter build apk \
  --dart-define-from-file=client.json \
  --obfuscate --split-debug-info=build/symbols \
  --release

flutter build appbundle \
  --dart-define-from-file=client.json \
  --obfuscate --split-debug-info=build/symbols \
  --release
```

**iOS:**
```bash
flutter build ipa \
  --dart-define-from-file=client.json \
  --obfuscate --split-debug-info=build/symbols \
  --release
```

> `--obfuscate` renames Dart symbols to short meaningless names, making reverse-engineering
> significantly harder.
> `--split-debug-info=build/symbols` writes the mapping file to `build/symbols/` so you can
> still deobfuscate crash stacks locally.
> Add `build/symbols/` to `.gitignore` — never commit these files.
> Web builds do not support `--obfuscate` (Dart2JS has its own minification).

---

## Step 6 — Signing

**Android:**
1. Generate a keystore: `keytool -genkey -v -keystore acme-studio.jks -keyalg RSA -keysize 2048 -validity 10000 -alias acme-studio`
2. Store it securely — **never commit it to git**
3. Reference in `android/app/build.gradle` under `signingConfigs`

**iOS:**
1. In Xcode: `Runner` → `Signing & Capabilities` → select your Apple Developer Team
2. Xcode manages the provisioning profile automatically for a registered device

---

## Step 7 — Distribution

**TestFlight (iOS internal testing):**
1. Archive in Xcode (`Product → Archive`) or use `flutter build ipa`
2. Upload via `xcrun altool` or Transporter app to App Store Connect
3. Add internal testers in App Store Connect → TestFlight

**Google Play (internal testing):**
1. Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console
2. Create an internal testing track, add testers

**App Store / Play Store public release:**
- Complete store listing: screenshots (required), description, keywords, age rating, privacy policy URL
- iOS: submit for review (1–3 days average)
- Android: submit for review (~1 day for new apps)

> **Privacy Policy is required by both stores** for any app that collects user data
> (contact forms, bookings, auth — so: always). Have the URL ready before submission.

---

## Step 8 — CI/CD with Codemagic (recommended, especially for iOS without a Mac)

Codemagic builds Flutter apps in the cloud — iOS on macOS M1, Android on Linux. It handles
signing, uploads to TestFlight / Google Play, and keeps secrets out of your repo.

**Free tier:** 500 Mac M1 build minutes/month. A typical Flutter iOS build takes 10–15 min,
so the free tier covers ~30–40 builds/month.

### The client.json injection problem

`client.json` is gitignored — Codemagic can't read it from the repo. The solution:

```bash
# On your machine — base64 encode the whole file:
base64 -i client.json | pbcopy   # macOS (copies to clipboard)
base64 client.json               # Linux
```

Store the output as an **encrypted environment variable** called `CLIENT_JSON_BASE64` in
Codemagic (`App settings → Environment variables → Add`). Mark it **Secure**.

At build time, Codemagic decodes it back:
```bash
echo "$CLIENT_JSON_BASE64" | base64 --decode > client.json
```

> Do this per client. Each Codemagic app (one per client) has its own encrypted env vars.
> Never share `CLIENT_JSON_BASE64` between clients — they have different secrets.

### codemagic.yaml

Create this file at the root of the client project directory:

```yaml
workflows:

  # ── iOS ──────────────────────────────────────────────────────────────────────
  ios-release:
    name: iOS Release
    max_build_duration: 60
    instance_type: mac_mini_m1
    environment:
      flutter: stable
      xcode: latest
      ios_signing:
        distribution_type: app_store
        bundle_identifier: com.acmestudio.app   # ← change per client
      vars:
        CLIENT_JSON_BASE64: Encrypted(...)      # ← paste encrypted value here
    scripts:
      - name: Decode client.json
        script: echo "$CLIENT_JSON_BASE64" | base64 --decode > execution/frontend/app/client.json
      - name: Dependencies + mobile config
        working_directory: execution/frontend/app
        script: |
          flutter pub get
          bash prepare_mobile.sh
      - name: Flutter build IPA
        working_directory: execution/frontend/app
        script: |
          flutter build ipa \
            --dart-define-from-file=client.json \
            --obfuscate --split-debug-info=build/symbols \
            --release
    artifacts:
      - execution/frontend/app/build/ios/ipa/*.ipa
    publishing:
      app_store_connect:
        auth: integration        # configure once in Codemagic → Integrations → App Store Connect
        submit_to_testflight: true

  # ── Android ──────────────────────────────────────────────────────────────────
  android-release:
    name: Android Release
    max_build_duration: 45
    instance_type: linux_x2
    environment:
      flutter: stable
      android_signing:
        - acme-studio-keystore   # ← name you gave the keystore in Codemagic
      vars:
        CLIENT_JSON_BASE64: Encrypted(...)      # ← paste encrypted value here
    scripts:
      - name: Decode client.json
        script: echo "$CLIENT_JSON_BASE64" | base64 --decode > execution/frontend/app/client.json
      - name: Dependencies + mobile config
        working_directory: execution/frontend/app
        script: |
          flutter pub get
          bash prepare_mobile.sh
      - name: Flutter build AAB
        working_directory: execution/frontend/app
        script: |
          flutter build appbundle \
            --dart-define-from-file=client.json \
            --obfuscate --split-debug-info=build/symbols \
            --release
    artifacts:
      - execution/frontend/app/build/app/outputs/bundle/release/app-release.aab
    publishing:
      google_play:
        credentials: $GCLOUD_SERVICE_ACCOUNT_CREDENTIALS  # stored in Codemagic env vars
        track: internal

  # ── Web (optional — build web from CI too) ───────────────────────────────────
  web-release:
    name: Web Release
    max_build_duration: 30
    instance_type: linux_x2
    environment:
      flutter: stable
      vars:
        CLIENT_JSON_BASE64: Encrypted(...)
    scripts:
      - name: Decode client.json
        script: echo "$CLIENT_JSON_BASE64" | base64 --decode > execution/frontend/app/client.json
      - name: Prepare and build
        working_directory: execution/frontend/app
        script: |
          bash prepare.sh
          flutter pub get
          flutter build web \
            --dart-define-from-file=client.json \
            --web-renderer html \
            --release
    artifacts:
      - execution/frontend/app/build/web.zip
```

> Codemagic zips `build/web/` automatically if you list the directory. You can then download
> and deploy it manually, or add a `publishing` step to push to Cloudflare/Netlify via CLI.

### iOS signing setup (one-time per Apple account)

1. Go to [codemagic.io](https://codemagic.io) → `Teams` → `Integrations` → **App Store Connect**
2. Generate an App Store Connect API key: App Store Connect → `Users & Access` → `Integrations` → `App Store Connect API`
3. Download the `.p8` file, note the Key ID and Issuer ID
4. Upload all three to Codemagic Integrations — done. Codemagic handles certificates and
   provisioning profiles automatically from this point.

### Android signing setup (one-time per keystore)

1. Generate keystore locally:
   ```bash
   keytool -genkey -v -keystore acme-studio.jks -keyalg RSA -keysize 2048 -validity 10000 -alias acme-studio
   ```
2. In Codemagic: `Teams` → `Code signing identities` → `Android keystores` → **Add keystore**
3. Upload the `.jks` file, enter alias + passwords
4. The name you give it (`acme-studio-keystore`) goes into `codemagic.yaml` under `android_signing`
5. Never commit the `.jks` file — add it to `.gitignore`

### Google Play publishing setup (one-time)

1. Google Play Console → `Setup` → `API access` → Link to a Google Cloud project
2. Create a service account with `Release Manager` role
3. Download the JSON key file
4. Store the file contents as `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` in Codemagic env vars

### When to trigger a build

Codemagic can build on every push to a branch, or you can trigger manually from the dashboard.
For client delivery, manual trigger is cleaner — run the web pipeline via `./deliver.sh` locally
(it runs fast), and use Codemagic only for the slower iOS/Android builds.

### codemagic.yaml template

A ready-to-use `codemagic.yaml.tpl` lives at `execution/ci/codemagic.yaml.tpl`. When running
`./deliver.sh --mobile`, it is patched with `CLIENT_*` tokens and copied to `codemagic.yaml`
at the project root. Review the output file before committing — update bundle IDs and signing
identity names to match your Codemagic setup.

---

## Step 9 — FCM Push Notifications (opt-in: `FCM_ENABLED=true`)

Skip this step if the client only needs web push (PWA) — that's already handled by the default
`PUSH_ENABLED=true` setup. FCM is required for **background locked-screen push on iOS and Android**.

### 9a. Create a Firebase project (one per client)

1. Go to [console.firebase.google.com](https://console.firebase.google.com) → **Add project**
2. Name it `<CLIENT_SLUG>` — free Spark plan is sufficient (FCM is free)
3. Register two apps: one Android (package name = `BUNDLE_ID`), one iOS (bundle ID = `BUNDLE_ID`)
4. Download `google-services.json` → place in `android/app/`
5. Download `GoogleService-Info.plist` → place in `ios/Runner/` (via Xcode drag-and-drop)

### 9b. Generate firebase_options.dart

Install FlutterFire CLI once:
```bash
dart pub global activate flutterfire_cli
```

Then in the app directory:
```bash
flutterfire configure --project=<firebase-project-id>
```

This generates `lib/firebase_options.dart` — commit it to the client repo.

### 9c. Add Firebase packages

```bash
flutter pub add firebase_core firebase_messaging
```

### 9d. Activate FCM in deliver.sh

Set in `client.json`:
```json
"FCM_ENABLED": true
```

Then run:
```bash
./deliver.sh --mobile
```

`deliver.sh` will:
- Copy `push_service_fcm_full.dart.tpl` → `push_service_fcm.dart` (real Firebase implementation)
- Update `push_service.dart` to export the FCM version for native
- Deploy updated `send-push` Edge Function
- Push `FIREBASE_SERVICE_ACCOUNT` secret (obtain from Firebase Console → Project settings →
  Service accounts → Generate new private key)

### 9e. Initialize Firebase in main.dart

Add to `main()` before `runApp()` (only when `FCM_ENABLED=true`):
```dart
if (!kIsWeb && AppEnv.fcmEnabled) {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  registerFcmTapHandlers(_handleDeepLink);
}
```

Imports needed:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/push/push_service_fcm.dart';
```

### 9f. FCM secrets in Codemagic

Add a `firebase_secrets` environment variable group in Codemagic:
- `FIREBASE_SERVICE_ACCOUNT` — full JSON string from Firebase service account key

Reference it in `codemagic.yaml` under `environment.groups`.

### FCM checklist

- [ ] `google-services.json` in `android/app/`
- [ ] `GoogleService-Info.plist` in `ios/Runner/` (added via Xcode)
- [ ] `lib/firebase_options.dart` generated and committed
- [ ] `firebase_core` + `firebase_messaging` in `pubspec.yaml`
- [ ] `main.dart` updated with `Firebase.initializeApp()` guard
- [ ] `FIREBASE_SERVICE_ACCOUNT` secret pushed to Supabase and Codemagic
- [ ] `send-push` Edge Function redeployed with FCM path
- [ ] Test: send a test notification from Firebase Console → Cloud Messaging → Send test message
