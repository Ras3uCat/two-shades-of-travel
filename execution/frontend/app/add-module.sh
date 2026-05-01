#!/bin/bash
# add-module.sh — Add a module to a client project and mark it deployed in Raspucat.
# Usage: ./add-module.sh <module-id>
# Example: ./add-module.sh newsletter
#
# Must be run from the client project directory (same location as deliver.sh + client.json).
# Requires deliver.sh and client.json to be present.

set -euo pipefail

# ─── Colour helpers ───────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}// ${1}${NC}"; }
success() { echo -e "${GREEN}✓ ${1}${NC}"; }
warn()    { echo -e "${YELLOW}⚠ ${1}${NC}"; }
error()   { echo -e "${RED}✗ ${1}${NC}"; exit 1; }

# ─── Known modules ────────────────────────────────────────────────────────────
KNOWN_MODULES=(
  home contact auth booking newsletter crm blog gallery testimonials faq
  subscriptions referrals shop events courses admin intake gift gdpr
  loyalty waitlist packages reviews client_photos recurring
)

# ─── Args ─────────────────────────────────────────────────────────────────────
MODULE_ID="${1:-}"
if [[ -z "$MODULE_ID" ]]; then
  error "Usage: ./add-module.sh <module-id>\nExample: ./add-module.sh newsletter"
fi

# ─── Validate module-id ───────────────────────────────────────────────────────
VALID=false
for m in "${KNOWN_MODULES[@]}"; do
  [[ "$m" == "$MODULE_ID" ]] && VALID=true && break
done
$VALID || error "Unknown module: '$MODULE_ID'\nKnown modules: ${KNOWN_MODULES[*]}"

# ─── Prerequisites ────────────────────────────────────────────────────────────
[[ -f "client.json" ]] || error "client.json not found. Run from the client project directory."
[[ -f "deliver.sh" ]]  || error "deliver.sh not found. Run from the client project directory."

# ─── Read client.json ─────────────────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
  error "python3 is required to parse client.json"
fi

read_json() {
  python3 -c "import json,sys; d=json.load(open('client.json')); print(d.get('$1',''))" 2>/dev/null
}

CURRENT_MODULES=$(read_json "MODULES")
RASPUCAT_API=$(read_json "RASPUCAT_API")
RASPUCAT_QUOTE_ID=$(read_json "RASPUCAT_QUOTE_ID")
RASPUCAT_ADMIN_TOKEN=$(read_json "RASPUCAT_ADMIN_TOKEN")

# ─── Idempotency check ────────────────────────────────────────────────────────
if echo "$CURRENT_MODULES" | tr ',' '\n' | grep -qx "$MODULE_ID"; then
  warn "Module '$MODULE_ID' is already in client.json MODULES — nothing to do."
  exit 0
fi

info "Adding module: $MODULE_ID"
info "Current modules: $CURRENT_MODULES"

# ─── Update client.json MODULES ───────────────────────────────────────────────
NEW_MODULES="${CURRENT_MODULES},${MODULE_ID}"
python3 - <<EOF
import json
with open('client.json', 'r') as f:
    data = json.load(f)
data['MODULES'] = '$NEW_MODULES'
with open('client.json', 'w') as f:
    json.dump(data, f, indent=2)
EOF
success "Updated client.json MODULES → $NEW_MODULES"

# ─── Run deliver.sh --skip-build ──────────────────────────────────────────────
info "Running deliver.sh --skip-build ..."
if ! bash deliver.sh --skip-build; then
  # Revert client.json on failure
  python3 - <<EOF
import json
with open('client.json', 'r') as f:
    data = json.load(f)
data['MODULES'] = '$CURRENT_MODULES'
with open('client.json', 'w') as f:
    json.dump(data, f, indent=2)
EOF
  error "deliver.sh failed. client.json has been reverted. Module NOT marked deployed."
fi

success "deliver.sh --skip-build completed"

# ─── Call back to Raspucat ────────────────────────────────────────────────────
if [[ -z "$RASPUCAT_API" || -z "$RASPUCAT_QUOTE_ID" || -z "$RASPUCAT_ADMIN_TOKEN" ]]; then
  warn "RASPUCAT_API, RASPUCAT_QUOTE_ID, or RASPUCAT_ADMIN_TOKEN not set in client.json."
  warn "Module deployed locally but NOT marked deployed in Raspucat admin panel."
  warn "Mark it manually at: $RASPUCAT_API"
  exit 0
fi

info "Notifying Raspucat ..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  "${RASPUCAT_API}/functions/v1/admin-mark-module-deployed" \
  -H "Content-Type: application/json" \
  -d "{\"quoteId\": \"$RASPUCAT_QUOTE_ID\", \"moduleId\": \"$MODULE_ID\", \"action\": \"in_progress\", \"adminToken\": \"$RASPUCAT_ADMIN_TOKEN\"}")

HTTP_BODY=$(echo "$RESPONSE" | head -n1)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [[ "$HTTP_CODE" == "200" ]]; then
  success "Raspucat updated — '$MODULE_ID' marked as In Progress. Run QA then mark Live in admin panel."
  echo -e "${GREEN}$HTTP_BODY${NC}"
else
  warn "Raspucat callback failed (HTTP $HTTP_CODE). Module deployed locally."
  warn "Mark it manually in the admin panel."
  echo "$HTTP_BODY"
fi
