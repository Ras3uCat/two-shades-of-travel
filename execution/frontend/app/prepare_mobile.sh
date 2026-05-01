#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# prepare_mobile.sh — Configure native iOS/Android files from client.json.
#
# Run once per client before triggering a Codemagic build, or add as a
# pre-build script in codemagic.yaml.
#
# Can also be called by deliver.sh --mobile.
#
# What it does:
#   1. Injects app domain into AndroidManifest.xml + Runner.entitlements
#   2. Sets android:label to CLIENT_NAME
#   3. Updates flutter_native_splash color to match COLOR_SURFACE
#   4. Generates web/.well-known/assetlinks.json (Android App Links verification)
#   5. Generates web/.well-known/apple-app-site-association (iOS Universal Links)
#   6. Runs dart run flutter_native_splash:create (if splash asset exists)
#   7. Runs dart run flutter_launcher_icons      (if icon asset exists)
#
# Requires client.json fields: CLIENT_NAME, SITE_URL, COLOR_SURFACE
# Optional fields:             BUNDLE_ID, APPLE_TEAM_ID (needed for .well-known/)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_JSON="$SCRIPT_DIR/client.json"

green() { printf "\033[32m✅ %s\033[0m\n" "$*"; }
warn()  { printf "\033[33m⚠  %s\033[0m\n" "$*"; }
step()  { printf "\n\033[1;36m──── %s ────\033[0m\n" "$*"; }
info()  { printf "   %s\n" "$*"; }

if [[ ! -f "$CLIENT_JSON" ]]; then
  printf "\033[31m❌ client.json not found at %s\033[0m\n" "$CLIENT_JSON" >&2
  exit 1
fi

# ─── Step 1: Native file injection ───────────────────────────────────────────
step "Native file injection"

python3 - "$SCRIPT_DIR" "$CLIENT_JSON" << 'PYEOF'
import json, os, re, sys

script_dir  = sys.argv[1]
client_json = sys.argv[2]

with open(client_json) as f:
    c = json.load(f)

client_name   = c.get('CLIENT_NAME', '')
site_url      = c.get('SITE_URL', '').rstrip('/')
color_surface = c.get('COLOR_SURFACE', 'FFFFFF').lstrip('#')
bundle_id     = c.get('BUNDLE_ID', '')
apple_team_id = c.get('APPLE_TEAM_ID', '')

# Extract bare domain from SITE_URL (strips scheme + path)
domain = re.sub(r'^https?://', '', site_url).split('/')[0]

def replace_in_file(path, old, new):
    """Returns True if a replacement was made."""
    with open(path) as f:
        content = f.read()
    if old not in content:
        return False
    with open(path, 'w') as f:
        f.write(content.replace(old, new))
    return True

# ── AndroidManifest.xml ───────────────────────────────────────────────────────
manifest = os.path.join(script_dir, 'android/app/src/main/AndroidManifest.xml')
if os.path.exists(manifest):
    if domain and replace_in_file(manifest, 'YOUR_APP_DOMAIN', domain):
        print(f'   ✅ AndroidManifest.xml — domain → {domain}')
    if client_name and replace_in_file(
        manifest, 'android:label="raspucat_client"', f'android:label="{client_name}"'
    ):
        print(f'   ✅ AndroidManifest.xml — label  → {client_name}')
else:
    print('   ⚠  AndroidManifest.xml not found — skipping')

# ── iOS Runner.entitlements ───────────────────────────────────────────────────
entitlements = os.path.join(script_dir, 'ios/Runner/Runner.entitlements')
if os.path.exists(entitlements) and domain:
    if replace_in_file(entitlements, 'YOUR_APP_DOMAIN', domain):
        print(f'   ✅ Runner.entitlements  — domain → {domain}')
else:
    print('   ⚠  Runner.entitlements not found — skipping')

# ── Splash color in pubspec.yaml ──────────────────────────────────────────────
pubspec = os.path.join(script_dir, 'pubspec.yaml')
splash_color = f'#{color_surface}'
changed  = replace_in_file(pubspec, '  color: "#FFFFFF"', f'  color: "{splash_color}"')
changed |= replace_in_file(pubspec, '  icon_background_color: "#FFFFFF"',
                            f'  icon_background_color: "{splash_color}"')
if changed:
    print(f'   ✅ pubspec.yaml          — splash color → {splash_color}')

# ── web/.well-known/ ─────────────────────────────────────────────────────────
if not bundle_id:
    print('   ⚠  BUNDLE_ID not set in client.json — skipping .well-known/ generation')
else:
    well_known = os.path.join(script_dir, 'web', '.well-known')
    os.makedirs(well_known, exist_ok=True)

    # Android App Links — assetlinks.json
    # SHA-256 fingerprint must be obtained from your release keystore:
    #   keytool -list -v -keystore release.jks -alias release | grep SHA256
    assetlinks = [{
        "relation": ["delegate_permission/common.handle_all_urls"],
        "target": {
            "namespace": "android_app",
            "package_name": bundle_id,
            "sha256_cert_fingerprints": [
                "TODO:REPLACE_WITH_RELEASE_KEYSTORE_SHA256_FINGERPRINT"
            ]
        }
    }]
    with open(os.path.join(well_known, 'assetlinks.json'), 'w') as f:
        json.dump(assetlinks, f, indent=2)
    print('   ✅ web/.well-known/assetlinks.json (update SHA-256 fingerprint before launch)')

    # iOS Universal Links — apple-app-site-association
    # Must be served as application/json — see _headers if using Netlify.
    if apple_team_id:
        aasa = {
            "applinks": {
                "details": [{
                    "appIDs": [f"{apple_team_id}.{bundle_id}"],
                    "components": [{"/" : "/*"}]
                }]
            }
        }
        with open(os.path.join(well_known, 'apple-app-site-association'), 'w') as f:
            json.dump(aasa, f, indent=2)
        print(f'   ✅ web/.well-known/apple-app-site-association ({apple_team_id}.{bundle_id})')
    else:
        print('   ⚠  APPLE_TEAM_ID not set — skipping apple-app-site-association')

PYEOF

green "Native config applied"

# ─── Step 2: Splash screens ───────────────────────────────────────────────────
step "Splash screens"

SPLASH_ASSET="$SCRIPT_DIR/assets/images/splash_logo.png"
if [[ -f "$SPLASH_ASSET" ]]; then
  info "Running flutter_native_splash:create..."
  (cd "$SCRIPT_DIR" && dart run flutter_native_splash:create)
  green "Splash screens generated"
else
  warn "assets/images/splash_logo.png not found — skipping"
  warn "Add logo PNG and run: dart run flutter_native_splash:create"
fi

# ─── Step 3: App icons ────────────────────────────────────────────────────────
step "App icons"

ICON_ASSET="$SCRIPT_DIR/assets/icons/app_icon.png"
if [[ -f "$ICON_ASSET" ]]; then
  info "Running flutter_launcher_icons..."
  (cd "$SCRIPT_DIR" && dart run flutter_launcher_icons)
  green "App icons generated"
else
  warn "assets/icons/app_icon.png not found — skipping"
  warn "Add 1024×1024 PNG (no alpha channel for iOS) and run: dart run flutter_launcher_icons"
fi

printf "\n\033[1;32m══════════════════════════════════════════\033[0m\n"
printf "\033[1m  ✅  Mobile assets prepared\033[0m\n"
printf "\033[1;32m══════════════════════════════════════════\033[0m\n\n"

printf "Remaining manual steps:\n"
printf "   □  iOS: Open Xcode → Runner → Signing & Capabilities → + → Associated Domains\n"
printf "   □  Android: paste release keystore SHA-256 into web/.well-known/assetlinks.json\n"
printf "      Run: keytool -list -v -keystore release.jks -alias release | grep SHA256\n"
printf "   □  Netlify: add _headers rule so apple-app-site-association is served as application/json\n"
printf "\n"
