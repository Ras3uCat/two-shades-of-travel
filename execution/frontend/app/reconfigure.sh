#!/usr/bin/env bash
# reconfigure.sh — Update credential fields in client.json without re-scaffolding.
# Run this when SUPABASE_URL, STRIPE_PK, or other secrets are still FILL_IN after
# the project was created. Press Enter to keep the existing value for any field.
#
# Usage: ./reconfigure.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_JSON="$SCRIPT_DIR/client.json"

green() { printf "\033[32m✅ %s\033[0m\n" "$*"; }
red()   { printf "\033[31m❌ %s\033[0m\n" "$*" >&2; }
bold()  { printf "\033[1m%s\033[0m\n" "$*"; }
info()  { printf "   %s\n" "$*"; }

if [[ ! -f "$CLIENT_JSON" ]]; then
  red "client.json not found at $CLIENT_JSON"
  exit 1
fi

# Read current value from client.json, return empty string on missing key
current() {
  python3 -c "import json; d=json.load(open('$CLIENT_JSON')); print(d.get('$1',''))" 2>/dev/null || echo ""
}

prompt_cred() {
  local label="$1" key="$2"
  local existing
  existing=$(current "$key")
  local display="${existing}"
  # Mask keys that look like secrets (long alphanumeric strings, not URLs)
  if [[ "${#existing}" -gt 20 && "$existing" != http* ]]; then
    display="${existing:0:6}…${existing: -4}"
  fi
  if [[ -n "$existing" && "$existing" != "FILL_IN" ]]; then
    read -rp "  $label [$display]: " val
    echo "${val:-$existing}"
  else
    read -rp "  $label: " val
    echo "$val"
  fi
}

prompt_secret_cred() {
  local label="$1" key="$2"
  local existing
  existing=$(current "$key")
  local display=""
  if [[ -n "$existing" && "$existing" != "FILL_IN" ]]; then
    display="${existing:0:6}…${existing: -4} (press Enter to keep)"
  fi
  if [[ -n "$display" ]]; then
    printf "  %s [%s]: " "$label" "$display"
  else
    printf "  %s: " "$label"
  fi
  read -rs val
  echo ""
  if [[ -z "$val" && -n "$existing" && "$existing" != "FILL_IN" ]]; then
    echo "$existing"
  else
    echo "$val"
  fi
}

bold ""
bold "  🔧  Raspucat Client Reconfigure"
bold "  ─────────────────────────────────"
info "Press Enter to keep the current value for any field."
info "client.json: $CLIENT_JSON"
echo ""

bold "Supabase"
SUPABASE_URL=$(prompt_cred       "Project URL (https://xxx.supabase.co)" "SUPABASE_URL")
SUPABASE_ANON_KEY=$(prompt_secret_cred "Anon/public key"                 "SUPABASE_ANON_KEY")
SUPABASE_SERVICE_ROLE_KEY=$(prompt_secret_cred "Service role key"        "SUPABASE_SERVICE_ROLE_KEY")

echo ""
bold "Stripe"
STRIPE_PK=$(prompt_cred          "Publishable key (pk_live_… or pk_test_…)" "STRIPE_PK")
STRIPE_SECRET_KEY=$(prompt_secret_cred "Secret key (sk_live_… or sk_test_…)" "STRIPE_SECRET_KEY")

echo ""
bold "Email / Notifications"
RESEND_KEY=$(prompt_secret_cred  "Resend API key"                        "RESEND_KEY")
FROM_EMAIL=$(prompt_cred         "From email address"                    "FROM_EMAIL")

echo ""
bold "Raspucat Admin"
RASPUCAT_ADMIN_TOKEN=$(prompt_secret_cred "Raspucat admin token"         "RASPUCAT_ADMIN_TOKEN")

echo ""

# Write updates back to client.json — only overwrite fields that have a value
python3 - <<PYEOF
import json

with open("$CLIENT_JSON") as f:
    data = json.load(f)

updates = {
    "SUPABASE_URL":              "$SUPABASE_URL",
    "SUPABASE_ANON_KEY":         "$SUPABASE_ANON_KEY",
    "SUPABASE_SERVICE_ROLE_KEY": "$SUPABASE_SERVICE_ROLE_KEY",
    "STRIPE_PK":                 "$STRIPE_PK",
    "STRIPE_SECRET_KEY":         "$STRIPE_SECRET_KEY",
    "RESEND_KEY":                "$RESEND_KEY",
    "FROM_EMAIL":                "$FROM_EMAIL",
    "RASPUCAT_ADMIN_TOKEN":      "$RASPUCAT_ADMIN_TOKEN",
}

changed = []
for k, v in updates.items():
    if v and v != data.get(k, ""):
        data[k] = v
        changed.append(k)

with open("$CLIENT_JSON", "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")

if changed:
    print("Updated: " + ", ".join(changed))
else:
    print("No changes made.")
PYEOF

green "client.json saved."
info "Run ./deliver.sh to continue the delivery pipeline."
