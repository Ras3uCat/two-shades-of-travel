# codemagic.yaml.tpl — Raspucat client CI/CD template.
# deliver.sh --mobile patches CLIENT_* tokens and copies to codemagic.yaml.
# DO NOT edit codemagic.yaml directly — edit this template instead.

workflows:

  # ── iOS ──────────────────────────────────────────────────────────────────────
  ios-release:
    name: iOS Release (App Store)
    max_build_duration: 60
    instance_type: mac_mini_m2
    integrations:
      app_store_connect: App Store Connect API
    environment:
      ios_signing:
        distribution_type: app_store
        bundle_identifier: CLIENT_BUNDLE_ID
      flutter: stable
      xcode: latest
      cocoapods: default
      vars:
        BUNDLE_ID: CLIENT_BUNDLE_ID
        APPLE_TEAM_ID: CLIENT_APPLE_TEAM_ID
        APP_NAME: CLIENT_NAME
      groups:
        - supabase_secrets
        - firebase_secrets
    scripts:
      - name: Set up code signing settings
        script: xcode-project use-profiles
      - name: Flutter pub get
        script: flutter pub get
      - name: Build iOS
        script: |
          flutter build ipa --release \
            --obfuscate \
            --split-debug-info=build/symbols \
            --dart-define-from-file=client.json
    artifacts:
      - build/ios/ipa/*.ipa
      - build/symbols/
    publishing:
      app_store_connect:
        auth: integration
        submit_to_testflight: true

  # ── Android ──────────────────────────────────────────────────────────────────
  android-release:
    name: Android Release (Play Store)
    max_build_duration: 60
    instance_type: linux_x2
    environment:
      android_signing:
        - CLIENT_SLUG_keystore
      flutter: stable
      vars:
        APP_NAME: CLIENT_NAME
        PACKAGE_NAME: CLIENT_BUNDLE_ID
      groups:
        - supabase_secrets
        - firebase_secrets
    scripts:
      - name: Flutter pub get
        script: flutter pub get
      - name: Build Android App Bundle
        script: |
          flutter build appbundle --release \
            --obfuscate \
            --split-debug-info=build/symbols \
            --dart-define-from-file=client.json
    artifacts:
      - build/app/outputs/bundle/release/*.aab
      - build/symbols/
    publishing:
      google_play:
        credentials: $GCLOUD_SERVICE_ACCOUNT_CREDENTIALS
        track: internal

# ── Environment variable groups (configure in Codemagic dashboard) ──────────
# Group: supabase_secrets
#   SUPABASE_URL, SUPABASE_ANON_KEY, STRIPE_PK, STRIPE_SK, STRIPE_WEBHOOK_SECRET
#   RESEND_KEY, VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY
# Group: firebase_secrets (only when FCM_ENABLED=true)
#   FIREBASE_SERVICE_ACCOUNT (full JSON from Firebase Console → Service Accounts)
