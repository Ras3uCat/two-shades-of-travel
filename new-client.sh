#!/usr/bin/env bash
# new-client.sh — Bootstrap a new client project from this template
# Usage: ./new-client.sh
# Run from the modular_project root. Creates an isolated client directory.

set -euo pipefail

TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENTS_ROOT="/home/ryan/Documents/development/flutter_apps/clients"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${BLUE}▸${RESET} $*"; }
success() { echo -e "${GREEN}✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET} $*"; }
error()   { echo -e "${RED}✗${RESET} $*" >&2; }
header()  { echo -e "\n${BOLD}$*${RESET}"; }

prompt() {
  local label="$1" default="${2:-}" var
  if [ -n "$default" ]; then
    read -rp "  $label [$default]: " var
    echo "${var:-$default}"
  else
    read -rp "  $label: " var
    echo "$var"
  fi
}

prompt_secret() {
  local label="$1" var
  read -rsp "  $label: " var
  echo ""  # newline after hidden input
  echo "$var"
}

# ── Prerequisites ──────────────────────────────────────────────────────────────
header "Checking prerequisites..."
for cmd in flutter supabase python3 git; do
  if ! command -v "$cmd" &>/dev/null; then
    error "$cmd not found on PATH — install it before continuing."
    exit 1
  fi
done
success "All prerequisites found"

# ── Gather client info ─────────────────────────────────────────────────────────
header "Client Information"
echo "  Enter the details for the new client project."
echo ""

CLIENT_NAME=$(prompt "Client/business name" "Acme Studio")
CLIENT_SLUG=$(prompt "URL slug (kebab-case)" "$(echo "$CLIENT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')")
TARGET_DIR=$(prompt "Destination directory" "$CLIENTS_ROOT/$CLIENT_SLUG")

if [ -d "$TARGET_DIR" ]; then
  error "Directory already exists: $TARGET_DIR"
  error "Delete it first or choose a different path."
  exit 1
fi

header "Supabase Configuration"
echo "  Get these from: Project Settings → API"
echo ""

SUPABASE_PROJECT_REF=$(prompt "Supabase project ref (e.g. abcdefghij)")
SUPABASE_URL=$(prompt "Supabase project URL" "https://$SUPABASE_PROJECT_REF.supabase.co")
SUPABASE_ANON_KEY=$(prompt "Supabase anon/public key")
echo -n "  Supabase service role key (for MCP — stays local): "
SUPABASE_SERVICE_ROLE_KEY=$(prompt_secret "")

header "Optional Configuration"
echo "  Press Enter to skip any of these — you can fill them in client.json later."
echo ""

RASPUCAT_QUOTE_ID=$(prompt "Raspucat quote ID (from admin panel)" "")
SITE_URL=$(prompt "Client site URL" "https://${CLIENT_SLUG}.com")
RESEND_KEY=$(prompt "Resend API key" "re_...")
STRIPE_PK=$(prompt "Stripe publishable key" "pk_test_...")
GITHUB_PAT=$(prompt "GitHub personal access token (for MCP)" "")

# ── Copy template ──────────────────────────────────────────────────────────────
header "Creating project..."

info "Copying template to $TARGET_DIR"
cp -r "$TEMPLATE_DIR" "$TARGET_DIR"

info "Removing template git history"
rm -rf "$TARGET_DIR/.git"

info "Making scripts executable"
find "$TARGET_DIR" -name "*.sh" -exec chmod +x {} \;

success "Template copied"

# ── Generate client.json ───────────────────────────────────────────────────────
header "Generating client.json..."

BUNDLE_ID="com.$(echo "$CLIENT_SLUG" | tr '-' '').app"
SHORT_NAME="$CLIENT_NAME"
BUSINESS_NAME="$CLIENT_NAME"
FROM_EMAIL="hello@${CLIENT_SLUG}.com"

CLIENT_JSON="$TARGET_DIR/execution/frontend/app/client.json"

python3 - <<PYEOF
import json, sys

with open("$TARGET_DIR/execution/frontend/app/client.json.example") as f:
    raw = f.read()

# Strip comment keys before parsing
import re
clean = re.sub(r'"COMMENT[^"]*"\s*:\s*"[^"]*"\s*,?\s*\n?', '', raw)
clean = re.sub(r',(\s*})', r'\1', clean)

try:
    data = json.loads(clean)
except json.JSONDecodeError as e:
    # Fall back to building from scratch
    data = {}

overrides = {
    "CLIENT_NAME":           "$CLIENT_NAME",
    "CLIENT_SLUG":           "$CLIENT_SLUG",
    "SHORT_NAME":            "$SHORT_NAME",
    "BUNDLE_ID":             "$BUNDLE_ID",
    "SUPABASE_URL":          "$SUPABASE_URL",
    "SUPABASE_ANON_KEY":     "$SUPABASE_ANON_KEY",
    "SITE_URL":              "$SITE_URL",
    "BUSINESS_NAME":         "$BUSINESS_NAME",
    "FROM_EMAIL":            "$FROM_EMAIL",
    "RESEND_KEY":            "$RESEND_KEY",
    "STRIPE_PK":             "$STRIPE_PK",
    "RASPUCAT_QUOTE_ID":     "$RASPUCAT_QUOTE_ID",
}

for k, v in overrides.items():
    if v:
        data[k] = v

# Remove comment keys from output
output = {k: v for k, v in data.items() if not k.startswith("COMMENT") and not k.startswith("_COMMENT")}

with open("$CLIENT_JSON", "w") as f:
    json.dump(output, f, indent=2)
    f.write("\n")

print("OK")
PYEOF

success "client.json written"

# ── settings.local.json ────────────────────────────────────────────────────────
header "Configuring Claude MCP servers..."

SETTINGS_LOCAL="$TARGET_DIR/.claude/settings.local.json"
GITHUB_MCP_ARGS="[]"
if [ -n "$GITHUB_PAT" ]; then
  GITHUB_MCP_ENV=", \"env\": { \"GITHUB_PERSONAL_ACCESS_TOKEN\": \"$GITHUB_PAT\" }"
else
  GITHUB_MCP_ENV=", \"env\": { \"GITHUB_PERSONAL_ACCESS_TOKEN\": \"YOUR_GITHUB_PAT\" }"
fi

cat > "$SETTINGS_LOCAL" <<EOF
{
  "permissions": {
    "allow": [
      "Read($TARGET_DIR/**)"
    ]
  },
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": [
        "-y",
        "@supabase/mcp-server-supabase@latest",
        "--supabase-url",
        "$SUPABASE_URL",
        "--supabase-key",
        "$SUPABASE_SERVICE_ROLE_KEY"
      ]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"]${GITHUB_MCP_ENV}
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
EOF

success "settings.local.json configured"

# ── Supabase link ──────────────────────────────────────────────────────────────
if [ -n "$SUPABASE_PROJECT_REF" ] && [ "$SUPABASE_PROJECT_REF" != "YOUR_REF" ]; then
  header "Linking Supabase project..."
  APP_DIR="$TARGET_DIR/execution/frontend/app"
  if (cd "$APP_DIR" && supabase link --project-ref "$SUPABASE_PROJECT_REF" 2>&1); then
    success "Supabase linked to $SUPABASE_PROJECT_REF"
  else
    warn "supabase link failed — run it manually:"
    warn "  cd $APP_DIR && supabase link --project-ref $SUPABASE_PROJECT_REF"
  fi
fi

# ── Git init ───────────────────────────────────────────────────────────────────
header "Initialising git repository..."
(
  cd "$TARGET_DIR"
  git init -q
  git add .
  git commit -q -m "Initial client scaffold — $CLIENT_SLUG"
)
success "Git repo initialised with initial commit"

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}Project created: $TARGET_DIR${RESET}"
echo ""
header "Manual steps remaining:"
echo ""
echo "  1. Open $TARGET_DIR in Claude Code:"
echo "     claude $TARGET_DIR"
echo ""
echo "  2. Fill in remaining client.json fields:"
echo "     - PERSONALITY, HERO_VARIANT, NAV_STYLE, HOME_SECTIONS"
echo "     - COLOR_PRIMARY/SECONDARY/ACCENT (hex without #)"
echo "     - FONT_PRIMARY, FONT_SECONDARY"
echo "     - PHONE, STREET, CITY, STATE, ZIP, COUNTRY"
echo "     - SEO_TITLE, SEO_DESCRIPTION, OG_IMAGE"
echo "     - HOURS_JSON (business hours)"
echo "     - STRIPE_SHOP_WEBHOOK_SECRET, STRIPE_EVENTS_WEBHOOK_SECRET (after registering)"
echo ""
echo "  3. Run Supabase setup (if not already linked):"
echo "     cd $TARGET_DIR/execution/frontend/app"
echo "     supabase link --project-ref $SUPABASE_PROJECT_REF"
echo ""
echo "  4. Configure Supabase JWT hook (requires Supabase dashboard):"
echo "     See planning/client/03_auth.md — Step 2"
echo ""
echo "  5. Run /health in Claude Code to verify MCP + Flutter are ready"
echo ""
echo "  6. Run ./deliver.sh --dry-run to check for missing fields"
echo ""
echo "  7. Run ./deliver.sh to deploy"
echo ""
if [ -z "$RASPUCAT_QUOTE_ID" ]; then
  warn "RASPUCAT_QUOTE_ID was left blank — fill it in client.json after provisioning"
fi
if [ "$STRIPE_PK" = "pk_test_..." ] || [ -z "$STRIPE_PK" ]; then
  warn "Stripe keys are placeholders — update in client.json before going live"
fi
