#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# deliver.sh — Full Raspucat client delivery pipeline.
#
# Usage:
#   ./deliver.sh                      Full delivery (DB + functions + secrets + build)
#   ./deliver.sh --skip-db            Skip migrations (already applied)
#   ./deliver.sh --skip-functions     Skip edge function deployment + secrets push
#   ./deliver.sh --skip-build         Skip Flutter build (DB/functions only)
#   ./deliver.sh --mobile             Also run prepare_mobile.sh (native iOS/Android config)
#   ./deliver.sh --register-webhooks  Auto-register Stripe webhook via Stripe API (requires STRIPE_SK)
#   ./deliver.sh --smoke-test         Run Playwright suite after build + POST result to Raspucat
#   ./deliver.sh --dry-run            Validate + print plan, do nothing
#
# Prerequisites (run once per client project):
#   1. cp client.json.example client.json && fill in all values
#   2. supabase link --project-ref <your-project-ref>
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_JSON="$SCRIPT_DIR/client.json"
BACKEND_DIR="$(cd "$SCRIPT_DIR/../../backend/supabase" && pwd)"
SUPABASE_PARENT="$(cd "$BACKEND_DIR/.." && pwd)"  # dir containing supabase/
FUNCTIONS_DIR="$BACKEND_DIR/functions"

# ─── Flags ────────────────────────────────────────────────────────────────────
SKIP_DB=false
SKIP_FUNCTIONS=false
SKIP_BUILD=false
MOBILE=false
DRY_RUN=false
REGISTER_WEBHOOKS=false
WEBHOOKS_REGISTERED=false
SMOKE_TEST=false

for arg in "$@"; do
  case "$arg" in
    --skip-db)            SKIP_DB=true ;;
    --skip-functions)     SKIP_FUNCTIONS=true ;;
    --skip-build)         SKIP_BUILD=true ;;
    --mobile)             MOBILE=true ;;
    --dry-run)            DRY_RUN=true ;;
    --register-webhooks)  REGISTER_WEBHOOKS=true ;;
    --smoke-test)         SMOKE_TEST=true ;;
    *) echo "Unknown flag: $arg  (valid: --skip-db --skip-functions --skip-build --mobile --register-webhooks --dry-run --smoke-test)" && exit 1 ;;
  esac
done

# ─── Colour helpers ───────────────────────────────────────────────────────────
bold()  { printf "\033[1m%s\033[0m\n"    "$*"; }
green() { printf "\033[32m✅ %s\033[0m\n" "$*"; }
red()   { printf "\033[31m❌ %s\033[0m\n" "$*" >&2; }
warn()  { printf "\033[33m⚠  %s\033[0m\n" "$*"; }
step()  { printf "\n\033[1;36m──── %s ────\033[0m\n" "$*"; }
info()  { printf "   %s\n" "$*"; }

json_get() {
  python3 -c \
    "import json; d=json.load(open('$CLIENT_JSON')); print(d.get('$1',''))" \
    2>/dev/null || echo ""
}

has_module() { [[ ",$MODULES," == *",$1,"* ]]; }

register_stripe_webhook() {
  local stripe_sk
  stripe_sk=$(json_get "STRIPE_SK")

  if [[ -z "$stripe_sk" || "$stripe_sk" == "FILL_IN" ]]; then
    warn "--register-webhooks skipped: STRIPE_SK not set in client.json"
    return 0
  fi

  local supabase_url endpoint_url
  supabase_url=$(json_get "SUPABASE_URL")
  endpoint_url="${supabase_url}/functions/v1/stripe-dispatcher"

  step "Stripe webhook auto-registration"
  info "Endpoint: $endpoint_url"

  if [[ "$DRY_RUN" == true ]]; then
    info "[dry-run] Would check Stripe for existing webhook at $endpoint_url"
    info "[dry-run] Would create endpoint with events: checkout.session.completed,"
    info "          customer.subscription.updated, customer.subscription.deleted,"
    info "          invoice.payment_succeeded, invoice.payment_failed"
    info "[dry-run] Would push STRIPE_WEBHOOK_SECRET to Supabase secrets"
    return 0
  fi

  # Check if endpoint already exists (idempotent)
  local tmp_list
  tmp_list=$(mktemp)
  curl -s "https://api.stripe.com/v1/webhook_endpoints?limit=100" \
    -u "${stripe_sk}:" > "$tmp_list"

  local existing_id
  existing_id=$(python3 -c "
import json
data = json.load(open('$tmp_list'))
for ep in data.get('data', []):
    if ep.get('url') == '${endpoint_url}':
        print(ep['id'])
        break
" 2>/dev/null)
  rm -f "$tmp_list"

  if [[ -n "$existing_id" ]]; then
    warn "Webhook already registered ($existing_id) — skipping. Delete it in Stripe dashboard to re-register."
    WEBHOOKS_REGISTERED=true
    return 0
  fi

  # Create the webhook endpoint
  info "Registering webhook..."
  local tmp_create
  tmp_create=$(mktemp)
  curl -s -X POST "https://api.stripe.com/v1/webhook_endpoints" \
    -u "${stripe_sk}:" \
    --data-urlencode "url=${endpoint_url}" \
    -d "enabled_events[]=checkout.session.completed" \
    -d "enabled_events[]=customer.subscription.updated" \
    -d "enabled_events[]=customer.subscription.deleted" \
    -d "enabled_events[]=invoice.payment_succeeded" \
    -d "enabled_events[]=invoice.payment_failed" > "$tmp_create"

  local webhook_id signing_secret err_msg
  webhook_id=$(python3 -c "import json; d=json.load(open('$tmp_create')); print(d.get('id',''))" 2>/dev/null)
  signing_secret=$(python3 -c "import json; d=json.load(open('$tmp_create')); print(d.get('secret',''))" 2>/dev/null)
  err_msg=$(python3 -c "import json; d=json.load(open('$tmp_create')); print(d.get('error',{}).get('message',''))" 2>/dev/null)
  rm -f "$tmp_create"

  if [[ -z "$signing_secret" || "${signing_secret:0:6}" != "whsec_" ]]; then
    red "Stripe webhook creation failed${err_msg:+: $err_msg}"
    info "Register manually: Stripe dashboard → Webhooks → Add endpoint"
    info "URL: $endpoint_url"
    info "Events: checkout.session.completed, customer.subscription.updated,"
    info "        customer.subscription.deleted, invoice.payment_succeeded, invoice.payment_failed"
    return 1
  fi

  green "Webhook registered ($webhook_id)"
  info "Pushing STRIPE_WEBHOOK_SECRET to Supabase..."

  if (cd "$SUPABASE_PARENT" && supabase secrets set "STRIPE_WEBHOOK_SECRET=${signing_secret}"); then
    green "STRIPE_WEBHOOK_SECRET pushed — no manual copy needed"
    WEBHOOKS_REGISTERED=true
  else
    red "Failed to push secret automatically. Run manually:"
    info "supabase secrets set STRIPE_WEBHOOK_SECRET=${signing_secret}"
  fi
}

dry() {
  if [[ "$DRY_RUN" == true ]]; then
    printf "   \033[2m[dry-run] %s\033[0m\n" "$*"
  else
    eval "$*"
  fi
}

# ─── Raspucat step reporter ───────────────────────────────────────────────────
# Usage: report_step "step_key"  (no-op if RASPUCAT_REPORTED != true or DRY_RUN)
report_step() {
  local step="$1"
  [[ "$RASPUCAT_REPORTED" != true ]] && return 0
  [[ "$DRY_RUN" == true ]] && { info "[dry-run] Would report step: $step"; return 0; }
  curl -sf -X POST "${RASPUCAT_API}/functions/v1/admin-delivery-progress" \
    -H "Content-Type: application/json" \
    -d "{\"adminToken\":\"${RASPUCAT_ADMIN_TOKEN}\",\"quoteId\":\"${RASPUCAT_QUOTE_ID}\",\"action\":\"upsert\",\"step\":\"${step}\",\"checked\":true,\"checked_by\":\"system\"}" \
    2>/dev/null && green "${step} reported" || warn "${step} report failed (non-blocking)"
}

# ─── Supabase Management API ──────────────────────────────────────────────────
# Reads personal access token from env var or Supabase CLI config file.
get_access_token() {
  # 1. Explicit env var
  if [[ -n "${SUPABASE_ACCESS_TOKEN:-}" ]]; then echo "$SUPABASE_ACCESS_TOKEN"; return 0; fi
  # 2. Supabase CLI config files (written by `supabase login`)
  for f in \
    "$HOME/.config/supabase/access-token" \
    "$HOME/.supabase/access-token"; do
    [[ -f "$f" ]] && { tr -d '[:space:]' < "$f"; return 0; }
  done
  # 3. Interactive prompt (only when stdin is a terminal)
  if [[ -t 0 && "$DRY_RUN" == false ]]; then
    echo "" >&2
    echo "  Supabase access token not found." >&2
    echo "  Get one at: supabase.com → Account → Access Tokens" >&2
    read -rsp "  Enter token (leave blank to skip Management API steps): " _token </dev/tty
    echo "" >&2
    if [[ -n "$_token" ]]; then
      # Cache it for this session
      export SUPABASE_ACCESS_TOKEN="$_token"
      echo "$_token"
      return 0
    fi
  fi
  echo ""
}

mgmt_api() {
  local method="$1" path="$2" body="${3:-}"
  local token
  token=$(get_access_token)
  [[ -z "$token" ]] && return 1
  if [[ -n "$body" ]]; then
    curl -sf -X "$method" "https://api.supabase.com/v1${path}" \
      -H "Authorization: Bearer $token" \
      -H "Content-Type: application/json" \
      -d "$body" 2>/dev/null
  else
    curl -sf -X "$method" "https://api.supabase.com/v1${path}" \
      -H "Authorization: Bearer $token" \
      -H "Content-Type: application/json" \
      2>/dev/null
  fi
}

configure_supabase_auth() {
  local ref="$1"
  [[ -z "$ref" || "$DRY_RUN" == true ]] && {
    [[ "$DRY_RUN" == true ]] && info "[dry-run] Would configure Supabase auth (URLs, JWT hook, templates, MFA)"
    return 0
  }

  local token
  token=$(get_access_token)
  if [[ -z "$token" ]]; then
    warn "SUPABASE_ACCESS_TOKEN not set and CLI token not found — Supabase auth auto-config skipped."
    warn "Set it with: export SUPABASE_ACCESS_TOKEN=<your-token> (supabase.com → Account → Access Tokens)"
    return 0
  fi

  step "Configuring Supabase project"

  # ── Auth site URL + redirect URLs ─────────────────────────────────────────
  if [[ -n "$SITE_URL" && "$SITE_URL" != "FILL_IN" ]]; then
    local auth_body
    auth_body=$(python3 -c "
import json, sys
site = '${SITE_URL}'.rstrip('/')
redirects = [site + '/**', 'http://localhost:3000/**']
www = site.replace('https://', 'https://www.')
if not site.startswith('https://www.'): redirects.append(www + '/**')
print(json.dumps({'site_url': site, 'additional_redirect_urls': redirects}))
")
    if mgmt_api PATCH "/projects/${ref}/config/auth" "$auth_body" > /dev/null; then
      green "Auth Site URL + Redirect URLs configured"
      AUTH_URLS_SET=true
    else
      warn "Auth URL config failed — set manually in Supabase Auth Settings"
    fi
  else
    warn "SITE_URL not set — auth URLs not configured automatically (set manually after DNS is pointed)"
  fi

  # ── JWT hook (custom_access_token_hook) ───────────────────────────────────
  local hook_body='{"hook_custom_access_token_enabled":true,"hook_custom_access_token_uri":"pg-functions://postgres/public/custom_access_token_hook"}'
  if mgmt_api PATCH "/projects/${ref}/config/auth" "$hook_body" > /dev/null; then
    green "JWT hook registered (custom_access_token_hook)"
    JWT_HOOK_SET=true
  else
    warn "JWT hook registration failed — register manually in Supabase Auth → Hooks"
  fi

  # ── MFA / 2FA ─────────────────────────────────────────────────────────────
  local mfa_body='{"mfa_totp_enroll_enabled":true,"mfa_totp_verify_enabled":true}'
  if mgmt_api PATCH "/projects/${ref}/config/auth" "$mfa_body" > /dev/null; then
    green "Supabase MFA (TOTP) enabled"
    MFA_SET=true
  else
    warn "MFA enable failed — enable manually in Supabase Auth Settings"
  fi

  # ── Email templates ───────────────────────────────────────────────────────
  local tpl_dir
  tpl_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../backend/supabase/templates/email" 2>/dev/null && pwd)"
  if [[ -d "$tpl_dir" ]]; then
    push_email_template() {
      local tpl_type="$1" tpl_file="$2"
      [[ ! -f "$tpl_dir/$tpl_file" ]] && return 0
      local content subject body_content
      content=$(sed "s/CLIENT_NAME/${CLIENT_NAME}/g" "$tpl_dir/$tpl_file")
      subject=$(echo "$content" | head -1 | sed 's/^Subject: //')
      body_content=$(echo "$content" | tail -n +3)
      local tpl_body
      tpl_body=$(python3 -c "import json,sys; print(json.dumps({'subject':sys.argv[1],'content':sys.argv[2]}))" \
        "$subject" "$body_content")
      mgmt_api PUT "/projects/${ref}/config/auth/email/templates/${tpl_type}" "$tpl_body" > /dev/null && \
        green "Email template set: $tpl_type" || warn "Email template failed: $tpl_type"
    }
    push_email_template "confirmation" "confirm_signup.txt"
    push_email_template "recovery"     "reset_password.txt"
    TEMPLATES_SET=true
  else
    warn "Email templates dir not found at $tpl_dir — skipping template customisation"
  fi
}

create_gallery_bucket() {
  [[ "$DRY_RUN" == true ]] && { info "[dry-run] Would create gallery storage bucket"; return 0; }
  local supabase_url service_key
  supabase_url=$(json_get "SUPABASE_URL")
  service_key=$(json_get "SUPABASE_SERVICE_ROLE_KEY")
  if [[ -z "$supabase_url" || -z "$service_key" || "$service_key" == "FILL_IN" ]]; then
    warn "SUPABASE_SERVICE_ROLE_KEY not set — gallery bucket not created automatically"
    return 0
  fi
  local result
  result=$(curl -sf -X POST "${supabase_url}/storage/v1/bucket" \
    -H "Authorization: Bearer $service_key" \
    -H "Content-Type: application/json" \
    -d '{"id":"gallery","name":"gallery","public":true}' 2>/dev/null || echo "")
  if [[ "$result" == *'"name":"gallery"'* || "$result" == *'already exists'* || "$result" == *'"id":"gallery"'* ]]; then
    green "Gallery storage bucket ready"
    GALLERY_BUCKET_CREATED=true
  else
    warn "Gallery bucket creation failed — check Supabase Storage"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
bold ""
bold "  🚀  Raspucat Client Delivery"
bold "  ─────────────────────────────"
if [[ "$DRY_RUN" == true ]]; then warn "DRY RUN — no changes will be made"; fi

# ─── Step 1 / 6: Tool checks ─────────────────────────────────────────────────
step "1 / 6  Tool checks"

TOOL_ERRORS=0
for tool in flutter supabase python3; do
  if command -v "$tool" &>/dev/null; then
    green "$tool found ($(command -v "$tool"))"
  else
    red "$tool not found — install it before running deliver.sh"
    TOOL_ERRORS=$((TOOL_ERRORS + 1))
  fi
done
[[ $TOOL_ERRORS -gt 0 ]] && exit 1

# ─── Step 2 / 6: Validate client.json ────────────────────────────────────────
step "2 / 6  Validating client.json"

if [[ ! -f "$CLIENT_JSON" ]]; then
  red "client.json not found at $CLIENT_JSON"
  info "Run: cp client.json.example client.json  and fill in all values."
  exit 1
fi

FIELD_ERRORS=0
for field in CLIENT_NAME CLIENT_SLUG SUPABASE_URL SUPABASE_ANON_KEY; do
  val=$(json_get "$field")
  if [[ -z "$val" ]]; then
    red "Missing required field: $field"
    FIELD_ERRORS=$((FIELD_ERRORS + 1))
  fi
done
[[ $FIELD_ERRORS -gt 0 ]] && exit 1

CLIENT_NAME=$(json_get "CLIENT_NAME")
CLIENT_SLUG=$(json_get "CLIENT_SLUG")
MODULES=$(json_get "MODULES")

# ── Auto-update pubspec.yaml name + description ───────────────────────────────
PUBSPEC="$SCRIPT_DIR/pubspec.yaml"
if [[ -f "$PUBSPEC" && -n "$CLIENT_SLUG" ]]; then
  PACKAGE_NAME="${CLIENT_SLUG//-/_}"   # hyphens → underscores (valid Dart ID)
  dry "sed -i 's/^name: .*/name: $PACKAGE_NAME/' '$PUBSPEC'"
  dry "sed -i 's/^description: .*/description: \"$CLIENT_NAME Flutter app.\"/' '$PUBSPEC'"
  green "pubspec.yaml updated (name: $PACKAGE_NAME)"
fi
STRIPE_MODE=$(json_get "STRIPE_MODE")
STRIPE_PK=$(json_get "STRIPE_PK")
RESEND_KEY=$(json_get "RESEND_KEY")
ANTHROPIC_API_KEY=$(json_get "ANTHROPIC_API_KEY")
SITE_URL=$(json_get "SITE_URL")
FROM_EMAIL=$(json_get "FROM_EMAIL")
TIMEZONE=$(json_get "TIMEZONE")
GDPR_ENABLED=$(json_get "GDPR_ENABLED")
SMS_ENABLED=$(json_get "SMS_ENABLED")
GIFT_ENABLED=$(json_get "GIFT_ENABLED")
LOYALTY_ENABLED=$(json_get "LOYALTY_ENABLED")
INTAKE_ENABLED=$(json_get "INTAKE_ENABLED")
WAITLIST_ENABLED=$(json_get "WAITLIST_ENABLED")
PACKAGES_ENABLED=$(json_get "PACKAGES_ENABLED")
REVIEWS_ENABLED=$(json_get "REVIEWS_ENABLED")
DIGEST_ENABLED=$(json_get "DIGEST_ENABLED")
CHATBOT_ENABLED=$(json_get "CHATBOT_ENABLED")
CHATBOT_MODE=$(json_get "CHATBOT_MODE")
PUSH_ENABLED=$(json_get "PUSH_ENABLED")
STRIPE_INVOICING_ENABLED=$(json_get "STRIPE_INVOICING_ENABLED")
INVOICES_ENABLED=$(json_get "INVOICES_ENABLED")
REVIEWS_SYNC_ENABLED=$(json_get "REVIEWS_SYNC_ENABLED")
LOCATIONS_ENABLED=$(json_get "LOCATIONS_ENABLED")
FCM_ENABLED=$(json_get "FCM_ENABLED")
GOOGLE_PLACES_ID=$(json_get "GOOGLE_PLACES_ID")
REVIEWS_MIN_RATING=$(json_get "REVIEWS_MIN_RATING")
# GOOGLE_PLACES_API_KEY must NOT be in client.json — read from shell env only
GOOGLE_PLACES_API_KEY="${GOOGLE_PLACES_API_KEY:-}"
VAPID_PUBLIC_KEY=$(json_get "VAPID_PUBLIC_KEY")
# VAPID_PRIVATE_KEY must NOT be in client.json — read from shell env only
VAPID_PRIVATE_KEY="${VAPID_PRIVATE_KEY:-}"
CLIENT_PHOTOS_ENABLED=$(json_get "CLIENT_PHOTOS_ENABLED")
RECURRING_ENABLED=$(json_get "RECURRING_ENABLED")

# Module-conditional warnings (non-fatal)
if has_module "booking" && [[ -z "$STRIPE_PK" ]]; then
  warn "booking module enabled but STRIPE_PK is empty — Stripe payments disabled."
fi
if [[ -z "$RESEND_KEY" ]]; then
  warn "RESEND_KEY not set — transactional emails will not be sent."
fi
if [[ -z "$SITE_URL" ]]; then
  warn "SITE_URL not set — Stripe success/cancel redirects will use localhost fallback."
fi

green "client.json is valid"
info "Client:    $CLIENT_NAME  ($CLIENT_SLUG)"
info "Modules:   ${MODULES:-home,contact,auth}"
info "Stripe:    ${STRIPE_MODE:-standard}"
info "GDPR:      ${GDPR_ENABLED:-false}"
info "Supabase:  $(json_get SUPABASE_URL)"

# ─── Step 3 / 6: Database migrations ─────────────────────────────────────────
step "3 / 6  Database migrations"

if [[ "$SKIP_DB" == true ]]; then
  warn "Skipping DB migrations (--skip-db)"
else
  dry "MODULES='$MODULES' CLIENT_JSON='$CLIENT_JSON' bash '$BACKEND_DIR/setup.sh'"
fi

# ─── Step 4 / 6: Deploy edge functions + push secrets ────────────────────────
step "4 / 6  Edge functions + secrets"

if [[ "$SKIP_FUNCTIONS" == true ]]; then
  warn "Skipping edge functions and secrets push (--skip-functions)"
else
  deploy_fn() {
    local fn="$1"
    if [[ -d "$FUNCTIONS_DIR/$fn" ]]; then
      info "Deploying $fn..."
      dry "(cd '$SUPABASE_PARENT' && supabase functions deploy '$fn' --no-verify-jwt)"
    else
      warn "Function directory not found: $fn — skipping."
    fi
  }

  # Always deploy
  deploy_fn "send-contact"
  deploy_fn "send-notification"
  deploy_fn "send-reminders"
  deploy_fn "send-review-requests"
  deploy_fn "send-abandoned-recovery"
  deploy_fn "forget-user"
  deploy_fn "cancel-booking"
  deploy_fn "cancel-pending-booking"
  deploy_fn "expire-pending-bookings"
  deploy_fn "staff-calendar"

  # Module-conditional
  has_module "newsletter" && deploy_fn "send-welcome"
  has_module "newsletter" && deploy_fn "unsubscribe"
  if has_module "booking"; then
    deploy_fn "create-checkout"
    [[ "${STRIPE_MODE:-standard}" == "connect_multi_staff" ]] && \
      deploy_fn "connect-stripe-onboard"
    deploy_fn "send-recurring-payment-reminders"
  fi
  if has_module "subscriptions"; then
    deploy_fn "create-subscription-checkout"
  fi
  has_module "referrals" && deploy_fn "process-referral"
  if has_module "shop"; then
    deploy_fn "create-shop-checkout"
  fi
  if has_module "events"; then
    deploy_fn "create-event-checkout"
    deploy_fn "cancel-event"
  fi
  if has_module "courses"; then
    deploy_fn "get-lesson-video"
    deploy_fn "create-course-checkout"
    deploy_fn "save-lesson-progress"
  fi
  # Single dispatcher for all Stripe webhook events
  if has_module "booking" || has_module "subscriptions" || has_module "shop" || has_module "events" || has_module "courses" || [[ "${GIFT_ENABLED:-false}" == "true" ]]; then
    deploy_fn "stripe-dispatcher"
  fi
  if [[ "${GIFT_ENABLED:-false}" == "true" ]]; then
    deploy_fn "create-gift-checkout"
    deploy_fn "apply-gift-voucher"
  fi
  if [[ "${SMS_ENABLED:-false}" == "true" ]]; then
    deploy_fn "send-sms"
    deploy_fn "send-sms-reminders"
  fi
  if [[ "${REVIEWS_ENABLED:-false}" == "true" ]]; then
    deploy_fn "submit-review"
  fi
  if [[ "${DIGEST_ENABLED:-false}" == "true" ]]; then
    deploy_fn "send-monthly-digest"
  fi
  if [[ "${CHATBOT_ENABLED:-false}" == "true" || "${CHATBOT_MODE:-}" == "full" ]]; then
    deploy_fn "chat"
  fi
  if [[ "${PUSH_ENABLED:-false}" == "true" ]]; then
    deploy_fn "save-push-subscription"
    deploy_fn "send-push"
  fi
  if [[ "${STRIPE_INVOICING_ENABLED:-false}" == "true" ]]; then
    deploy_fn "send-stripe-invoice"
  fi
  if [[ "${INVOICES_ENABLED:-false}" == "true" ]]; then
    deploy_fn "generate-invoice"
    dry "supabase secrets set INVOICES_ENABLED=true"
  fi
  if [[ "${REVIEWS_SYNC_ENABLED:-false}" == "true" ]]; then
    deploy_fn "sync-google-reviews"
    dry "supabase secrets set GOOGLE_PLACES_ID='$GOOGLE_PLACES_ID' REVIEWS_MIN_RATING='${REVIEWS_MIN_RATING:-4}' GOOGLE_PLACES_API_KEY='$GOOGLE_PLACES_API_KEY'"
  fi
  if [[ "${LOCATIONS_ENABLED:-false}" == "true" ]]; then
    dry "supabase secrets set LOCATIONS_ENABLED=true"
  fi
  if [[ "${FCM_ENABLED:-false}" == "true" ]]; then
    deploy_fn "send-push"
    deploy_fn "save-push-subscription"
    if [[ -n "${FIREBASE_SERVICE_ACCOUNT:-}" ]]; then
      dry "supabase secrets set FIREBASE_SERVICE_ACCOUNT='$FIREBASE_SERVICE_ACCOUNT'"
    else
      warn "FCM_ENABLED=true but FIREBASE_SERVICE_ACCOUNT not set in shell env — push to Supabase manually"
    fi
  fi

  green "Edge functions deployed"

  # Extract project ref early (needed for Management API calls below)
  SUPABASE_PROJECT_REF_EARLY=$(json_get "SUPABASE_URL" | sed 's|https://||;s|\.supabase\.co.*||')

  # Configure Supabase project via Management API
  AUTH_URLS_SET=false; JWT_HOOK_SET=false; MFA_SET=false; TEMPLATES_SET=false
  configure_supabase_auth "$SUPABASE_PROJECT_REF_EARLY"

  # Create gallery storage bucket if gallery module is enabled
  GALLERY_BUCKET_CREATED=false
  has_module "gallery" && create_gallery_bucket "$SUPABASE_PROJECT_REF_EARLY"

  # Push secrets from client.json to Supabase (secrets not present = silently skipped)
  info "Pushing Supabase secrets..."

  STRIPE_SECRET_KEY_VAL=$(json_get "STRIPE_SECRET_KEY")
  SECRET_ARGS="BUSINESS_NAME='$CLIENT_NAME' CLIENT_SLUG='$CLIENT_SLUG'"
  [[ -n "$FROM_EMAIL"  ]] && SECRET_ARGS="$SECRET_ARGS FROM_EMAIL='$FROM_EMAIL'"
  [[ -n "$TIMEZONE"    ]] && SECRET_ARGS="$SECRET_ARGS TIMEZONE='$TIMEZONE'"
  [[ -n "$SITE_URL"    ]] && SECRET_ARGS="$SECRET_ARGS SITE_URL='$SITE_URL'"
  [[ -n "$RESEND_KEY"         ]] && SECRET_ARGS="$SECRET_ARGS RESEND_KEY='$RESEND_KEY'"
  [[ -n "$ANTHROPIC_API_KEY" ]] && SECRET_ARGS="$SECRET_ARGS ANTHROPIC_API_KEY='$ANTHROPIC_API_KEY'"
  [[ -n "$VAPID_PUBLIC_KEY"  ]] && SECRET_ARGS="$SECRET_ARGS VAPID_PUBLIC_KEY='$VAPID_PUBLIC_KEY'"
  [[ -n "$VAPID_PRIVATE_KEY" ]] && SECRET_ARGS="$SECRET_ARGS VAPID_PRIVATE_KEY='$VAPID_PRIVATE_KEY'"
  [[ -n "$STRIPE_SECRET_KEY_VAL" && "$STRIPE_SECRET_KEY_VAL" != "FILL_IN" ]] && \
    SECRET_ARGS="$SECRET_ARGS STRIPE_SK='$STRIPE_SECRET_KEY_VAL'"

  dry "(cd '$SUPABASE_PARENT' && supabase secrets set $SECRET_ARGS)"
  green "Secrets pushed"
  STRIPE_SK_PUSHED=$( [[ -n "$STRIPE_SECRET_KEY_VAL" && "$STRIPE_SECRET_KEY_VAL" != "FILL_IN" ]] && echo true || echo false )

  # Auto-register Stripe webhook if STRIPE_SECRET_KEY is set and Stripe modules are active
  STRIPE_SK_VAL=$(json_get "STRIPE_SK")
  if [[ -n "$STRIPE_SECRET_KEY_VAL" && "$STRIPE_SECRET_KEY_VAL" != "FILL_IN" ]] && \
     { has_module "booking" || has_module "subscriptions" || has_module "shop" || \
       has_module "events" || has_module "courses" || [[ "${GIFT_ENABLED:-false}" == "true" ]]; }; then
    register_stripe_webhook
  fi
fi

# ─── Step 5 / 6: Prepare web assets ──────────────────────────────────────────
step "5 / 6  Preparing web assets"

if [[ "$SKIP_BUILD" == true ]]; then
  warn "Skipping web asset preparation (--skip-build)"
else
  dry "bash '$SCRIPT_DIR/prepare.sh'"
fi

# ─── Mobile config (opt-in via --mobile) ─────────────────────────────────────
if [[ "$MOBILE" == true ]]; then
  step "Mobile config"
  if [[ "$SKIP_BUILD" == true ]]; then
    warn "Skipping mobile config (--skip-build)"
  else
    dry "bash '$SCRIPT_DIR/prepare_mobile.sh'"

    # Patch codemagic.yaml from template
    CI_TEMPLATE="$(dirname "$(dirname "$SCRIPT_DIR")")/ci/codemagic.yaml.tpl"
    CI_OUT="$SCRIPT_DIR/codemagic.yaml"
    if [[ -f "$CI_TEMPLATE" ]]; then
      sed \
        -e "s/CLIENT_BUNDLE_ID/${BUNDLE_ID:-com.example.app}/g" \
        -e "s/CLIENT_APPLE_TEAM_ID/${APPLE_TEAM_ID:-XXXXXXXXXX}/g" \
        -e "s/CLIENT_NAME/${CLIENT_NAME:-Client}/g" \
        -e "s/CLIENT_SLUG/${CLIENT_SLUG:-client}/g" \
        "$CI_TEMPLATE" > "$CI_OUT"
      green "codemagic.yaml generated at $CI_OUT"
    fi

    # FCM: activate real implementation when FCM_ENABLED=true
    if [[ "${FCM_ENABLED:-false}" == "true" ]]; then
      FCM_TPL="$SCRIPT_DIR/lib/core/push/push_service_fcm_full.dart.tpl"
      FCM_IMPL="$SCRIPT_DIR/lib/core/push/push_service_fcm.dart"
      if [[ -f "$FCM_TPL" ]]; then
        cp "$FCM_TPL" "$FCM_IMPL"
        green "push_service_fcm.dart activated (FCM_ENABLED=true)"
      fi
    fi
  fi
fi

# ─── Step 6 / 6: Flutter build ───────────────────────────────────────────────
step "6 / 6  Flutter web build"

if [[ "$SKIP_BUILD" == true ]]; then
  warn "Skipping Flutter build (--skip-build)"
else
  dry "bash '$SCRIPT_DIR/build.sh'"
fi

# ─── HTTP deployment checks ──────────────────────────────────────────────────
SITE_REACHABLE=false
WWW_REDIRECTS=false

if [[ -n "$SITE_URL" && "$SKIP_BUILD" == false && "$DRY_RUN" == false ]]; then
  step "Deployment checks"
  info "Checking $SITE_URL ..."
  for i in 1 2 3; do
    if curl -sf --max-time 15 "$SITE_URL" -o /dev/null 2>/dev/null; then
      green "Site is reachable: $SITE_URL"
      SITE_REACHABLE=true
      break
    fi
    [[ $i -lt 3 ]] && { warn "Not reachable yet — retrying in 10s..."; sleep 10; }
  done
  [[ "$SITE_REACHABLE" == false ]] && warn "Site not reachable at $SITE_URL — deployed_to_hosting not reported"

  # www redirect check: www.domain → apex (or apex → www)
  WWW_URL="https://www.${SITE_URL#https://}"
  if [[ "$WWW_URL" != "$SITE_URL" ]]; then
    WWW_FINAL=$(curl -sf --max-time 10 -o /dev/null -w "%{url_effective}" -L "$WWW_URL" 2>/dev/null || echo "")
    if [[ "$WWW_FINAL" == "$SITE_URL"* || "$WWW_FINAL" == "$WWW_URL"* ]]; then
      green "www redirect confirmed ($WWW_URL → $WWW_FINAL)"
      WWW_REDIRECTS=true
    else
      warn "www redirect not confirmed — verify DNS/hosting redirect for $WWW_URL"
    fi
  fi
fi

# ─── Report delivery to Raspucat ─────────────────────────────────────────────
RASPUCAT_API=$(json_get "RASPUCAT_API")
RASPUCAT_QUOTE_ID=$(json_get "RASPUCAT_QUOTE_ID")
RASPUCAT_ADMIN_TOKEN=$(json_get "RASPUCAT_ADMIN_TOKEN")

RASPUCAT_REPORTED=false

if [[ -n "$RASPUCAT_API" && "$RASPUCAT_API" != "FILL_IN" && \
      -n "$RASPUCAT_QUOTE_ID" && "$RASPUCAT_QUOTE_ID" != "FILL_IN" && \
      -n "$RASPUCAT_ADMIN_TOKEN" && "$RASPUCAT_ADMIN_TOKEN" != "FILL_IN" ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    info "[dry-run] Would POST deliver_sh_complete + all auto steps to Raspucat ($RASPUCAT_API)"
  else
    step "Reporting delivery to Raspucat"
    SUPABASE_PROJECT_REF=$(json_get "SUPABASE_URL" | sed 's|https://||;s|\.supabase\.co.*||')
    TEMPLATE_VERSION=$(git -C "$SCRIPT_DIR/../../.." rev-parse --short HEAD 2>/dev/null || echo "")

    if curl -sf -X POST "${RASPUCAT_API}/functions/v1/admin-delivery-progress" \
        -H "Content-Type: application/json" \
        -d "{\"adminToken\":\"${RASPUCAT_ADMIN_TOKEN}\",\"quoteId\":\"${RASPUCAT_QUOTE_ID}\",\"action\":\"upsert\",\"step\":\"deliver_sh_complete\",\"checked\":true,\"checked_by\":\"system\",\"supabase_project_ref\":\"${SUPABASE_PROJECT_REF}\",\"template_version\":\"${TEMPLATE_VERSION}\"}" \
        2>/dev/null; then
      green "deliver_sh_complete reported — portal stage set to Compiling${TEMPLATE_VERSION:+ (template: $TEMPLATE_VERSION)}"
      RASPUCAT_REPORTED=true
    else
      warn "Raspucat progress POST failed (non-blocking)"
    fi

    # ── Secrets + Stripe ──────────────────────────────────────────────────────
    [[ "$STRIPE_SK_PUSHED" == true ]]    && report_step "stripe_sk_set"
    if [[ "$WEBHOOKS_REGISTERED" == true ]]; then
      report_step "stripe_webhooks_registered"
      report_step "stripe_webhook_secret_set"
      has_module "shop"   && report_step "stripe_shop_webhook_secret_set"
      has_module "events" && report_step "stripe_events_webhook_secret_set"
    fi

    # ── Supabase auth configuration ───────────────────────────────────────────
    [[ "$AUTH_URLS_SET"   == true ]] && report_step "supabase_auth_urls_set"
    [[ "$JWT_HOOK_SET"    == true ]] && report_step "jwt_hook_registered"
    [[ "$TEMPLATES_SET"   == true ]] && report_step "auth_email_templates_customised"
    [[ "$MFA_SET"         == true ]] && report_step "supabase_2fa_enabled"

    # ── Storage ───────────────────────────────────────────────────────────────
    [[ "$GALLERY_BUCKET_CREATED" == true ]] && report_step "storage_bucket_created"

    # ── Crons (flag files written by setup.sh subprocess) ────────────────────
    if [[ -f "/tmp/.cron_expire_${CLIENT_SLUG}" ]]; then
      rm -f "/tmp/.cron_expire_${CLIENT_SLUG}"; report_step "expire_bookings_cron"
    fi
    if [[ -f "/tmp/.cron_reminders_${CLIENT_SLUG}" ]]; then
      rm -f "/tmp/.cron_reminders_${CLIENT_SLUG}"; report_step "send_reminders_cron"
    fi
    if [[ -f "/tmp/.cron_reviews_${CLIENT_SLUG}" ]]; then
      rm -f "/tmp/.cron_reviews_${CLIENT_SLUG}"; report_step "send_review_requests_cron"
    fi

    # ── Favicons ──────────────────────────────────────────────────────────────
    if [[ -f "/tmp/.favicon_generated_${CLIENT_SLUG}" ]]; then
      rm -f "/tmp/.favicon_generated_${CLIENT_SLUG}"
      report_step "favicon_replaced"
    fi

    # ── Stripe live keys ──────────────────────────────────────────────────────
    STRIPE_PK_VAL=$(json_get "STRIPE_PK")
    if [[ "${STRIPE_PK_VAL:0:7}" == "pk_live" ]]; then
      report_step "stripe_live_switchover"
      [[ "$WEBHOOKS_REGISTERED" == true ]] && report_step "stripe_webhook_live"
    fi

    # ── Deployment / DNS ──────────────────────────────────────────────────────
    [[ "$SITE_REACHABLE" == true ]] && report_step "deployed_to_hosting"
    [[ "$WWW_REDIRECTS"  == true ]] && report_step "www_redirect_confirmed"

    # ── Register site for health monitoring ───────────────────────────────────
    if [[ -n "$SITE_URL" ]]; then
      curl -sf -X POST "${RASPUCAT_API}/functions/v1/admin-register-site" \
        -H "Content-Type: application/json" \
        -d "{\"adminToken\":\"${RASPUCAT_ADMIN_TOKEN}\",\"quoteId\":\"${RASPUCAT_QUOTE_ID}\",\"siteUrl\":\"${SITE_URL}\",\"clientSlug\":\"${CLIENT_SLUG}\"}" \
        2>/dev/null && green "Site registered for health monitoring" || warn "admin-register-site POST failed (non-blocking)"
    fi
  fi
fi

# ─── Smoke test ───────────────────────────────────────────────────────────────
if [[ "$SMOKE_TEST" == true ]]; then
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
  QA_DIR="$PROJECT_ROOT/qa"

  if [[ "$DRY_RUN" == true ]]; then
    info "[dry-run] Would run Playwright against BASE_URL=${SITE_URL} and POST result to Raspucat"
  elif [[ ! -d "$QA_DIR/node_modules" ]]; then
    warn "Smoke test skipped — qa/node_modules not installed (run: cd qa && npm install)"
  elif [[ -z "$SITE_URL" ]]; then
    warn "Smoke test skipped — SITE_URL not set in client.json"
  else
    step "Running smoke tests"
    info "BASE_URL: $SITE_URL"

    # Verify site is reachable before running tests
    if ! curl -sf --max-time 10 "$SITE_URL" -o /dev/null 2>/dev/null; then
      warn "Smoke test skipped — $SITE_URL is not reachable"
    else
      SMOKE_PASSED=false
      if BASE_URL="$SITE_URL" npx --prefix "$QA_DIR" playwright test --config "$QA_DIR/playwright.config.js" 2>&1; then
        SMOKE_PASSED=true
        green "All smoke tests passed"
      else
        red "Smoke tests failed — see output above"
      fi

      # POST result to Raspucat
      if [[ -n "$RASPUCAT_API" && "$RASPUCAT_API" != "FILL_IN" && \
            -n "$RASPUCAT_QUOTE_ID" && "$RASPUCAT_QUOTE_ID" != "FILL_IN" && \
            -n "$RASPUCAT_ADMIN_TOKEN" && "$RASPUCAT_ADMIN_TOKEN" != "FILL_IN" ]]; then
        SMOKE_CHECKED="$([[ "$SMOKE_PASSED" == true ]] && echo true || echo false)"
        if curl -sf -X POST "${RASPUCAT_API}/functions/v1/admin-delivery-progress" \
            -H "Content-Type: application/json" \
            -d "{\"adminToken\":\"${RASPUCAT_ADMIN_TOKEN}\",\"quoteId\":\"${RASPUCAT_QUOTE_ID}\",\"action\":\"upsert\",\"step\":\"smoke_test_passed\",\"checked\":${SMOKE_CHECKED},\"checked_by\":\"system\"}" \
            2>/dev/null; then
          if [[ "$SMOKE_PASSED" == true ]]; then
            green "smoke_test_passed reported — portal stage set to Deployed"
          else
            warn "smoke_test_passed=false reported to Raspucat"
          fi
        else
          warn "Raspucat smoke test POST failed (non-blocking)"
        fi
      else
        warn "Raspucat not configured — smoke test result not reported (set RASPUCAT_QUOTE_ID, RASPUCAT_API, RASPUCAT_ADMIN_TOKEN)"
      fi
    fi
  fi
fi

# ─── Post-delivery checklist ──────────────────────────────────────────────────
printf "\n\033[1;32m══════════════════════════════════════════\033[0m\n"
if [[ "$DRY_RUN" == true ]]; then
  bold "  Dry run complete — review the plan above."
else
  bold "  ✅  Delivery complete — $CLIENT_NAME"
fi
printf "\033[1;32m══════════════════════════════════════════\033[0m\n\n"

bold "Remaining manual steps:"
info "□  Register JWT hook: Supabase → Authentication → Hooks → Add hook"
info "   Hook type: Custom Access Token  |  Function: custom_access_token_hook"
info "□  Set Auth URL: Supabase → Authentication → URL Configuration → Site URL"
info "□  Customise auth emails: Supabase → Authentication → Email Templates"
info "   (use templates in backend/supabase/templates/email/)"
info "□  Schedule reminders: Supabase → Edge Functions → send-reminders → Schedule"
info "   Recommended cron: '0 10 * * *'  (daily at 10am UTC)"
info "□  Schedule review requests: Supabase → Edge Functions → send-review-requests → Schedule"
info "   Recommended cron: '0 12 * * *'  (daily at noon UTC)"
info "□  Schedule booking expiry: Supabase → Edge Functions → expire-pending-bookings → Schedule"
info "   Recommended cron: '*/30 * * * *'  (every 30 min — releases unpaid Stripe slots)"
info "□  Schedule abandoned recovery: Supabase → Edge Functions → send-abandoned-recovery → Schedule"
info "   Recommended cron: '0 */2 * * *'  (every 2 hours — re-engages users who abandoned Stripe checkout)"
info "□  Deploy build/web/ to hosting"

if has_module "booking" || has_module "subscriptions" || has_module "shop" || has_module "events" || [[ "${GIFT_ENABLED:-false}" == "true" ]]; then
  info "□  Set STRIPE_SK: supabase secrets set STRIPE_SK=sk_live_..."
  if [[ "$WEBHOOKS_REGISTERED" == true ]]; then
    info "✅ Stripe webhook registered automatically (STRIPE_WEBHOOK_SECRET pushed)"
    info "   Note: re-run with --register-webhooks after switching to live key to update the secret"
  else
    info "□  Register ONE Stripe webhook → $(json_get SUPABASE_URL)/functions/v1/stripe-dispatcher"
    info "   Events: checkout.session.completed, customer.subscription.updated,"
    info "           customer.subscription.deleted, invoice.payment_succeeded, invoice.payment_failed"
    info "   Copy the signing secret → supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_..."
    info "   Tip: re-run with --register-webhooks to do this automatically next time"
  fi
  if has_module "booking" && [[ "${STRIPE_MODE:-standard}" == "connect_multi_staff" ]]; then
    info "□  Configure Stripe Connect redirect URI for staff onboarding"
  fi
fi

GOOGLE_AUTH_ENABLED=$(json_get "GOOGLE_AUTH_ENABLED")
APPLE_AUTH_ENABLED=$(json_get "APPLE_AUTH_ENABLED")
if [[ "$GOOGLE_AUTH_ENABLED" == "true" ]]; then
  info "□  Enable Google provider: Supabase → Auth → Providers → Google"
  info "   Add OAuth redirect: ${SITE_URL}/auth/v1/callback"
fi
if [[ "$APPLE_AUTH_ENABLED" == "true" ]]; then
  info "□  Enable Apple provider: Supabase → Auth → Providers → Apple"
  info "   Requires Apple Developer account + Sign in with Apple capability"
fi

if has_module "gallery"; then
  info "□  Create public Storage bucket named 'gallery' in Supabase dashboard"
fi

if [[ "${SMS_ENABLED:-false}" == "true" ]]; then
  info "□  Set Twilio secrets manually: supabase secrets set TWILIO_ACCOUNT_SID=... TWILIO_AUTH_TOKEN=... TWILIO_FROM_NUMBER=..."
  info "   Then verify send-sms-reminders is scheduled: '0 9 * * *' (daily at 9am UTC recommended)"
fi

if [[ "${GIFT_ENABLED:-false}" == "true" ]]; then
  info "□  Gift vouchers route automatically via stripe-dispatcher (metadata.type=gift_voucher)"
  info "□  Schedule gift voucher expiry: Supabase → Edge Functions → apply-gift-voucher → Schedule (optional cron)"
fi

if [[ "${LOYALTY_ENABLED:-false}" == "true" ]]; then
  info "□  Loyalty points are awarded automatically after booking confirmation via stripe-dispatcher"
  info "   No additional setup required — loyalty_ledger rows are inserted by the Edge Function"
fi

if [[ "${INTAKE_ENABLED:-false}" == "true" ]]; then
  info "□  Add intake questions before going live: Admin → Intake Forms (/admin/intake)"
  info "   Link clients to the intake form post-booking: /intake?booking_id=<id>"
fi

if [[ "${WAITLIST_ENABLED:-false}" == "true" ]]; then
  info "□  Waitlist is active — clients join via the step-3 'No availability' screen"
  info "   Notifications are sent automatically when a booking is cancelled (via cancel-booking fn)"
  info "   View + manage waitlist entries at Admin → Waitlist (/admin/waitlist)"
fi

if [[ "${REVIEWS_ENABLED:-false}" == "true" ]]; then
  info "□  Reviews active — submit-review edge function deployed (handles public form submissions)"
  info "   Trigger review requests: send-review-requests cron fires daily, or use Admin → send-notification"
  info "   Clients land at ${SITE_URL}/review?booking_id=...&token=..."
  info "   Approve pending reviews at Admin → Reviews (/admin/reviews)"
fi

if [[ "${DIGEST_ENABLED:-false}" == "true" ]]; then
  info "□  Monthly digest active — schedule send-monthly-digest:"
  info "   Supabase → Edge Functions → send-monthly-digest → Schedule: '0 8 1 * *' (1st of month, 8am UTC)"
fi

if [[ "${CHATBOT_ENABLED:-false}" == "true" || "${CHATBOT_MODE:-}" == "full" ]]; then
  info "□  AI Chatbot active — add ANTHROPIC_API_KEY to client.json before running deliver.sh"
  info "   Cost: ~\$0.001/1k tokens (claude-haiku-4-5) — negligible for most clients"
  info "   Bubble appears on all public routes; hidden on /admin/* automatically"
  if [[ "${CHATBOT_MODE:-}" == "full" ]]; then
    info "□  Chatbot Full tier — set custom prompt in Admin → Business Settings → Chatbot"
    info "   Prompt updates take effect within 10 minutes (cache TTL)"
  fi
fi

if [[ "${PUSH_ENABLED:-false}" == "true" ]]; then
  info "□  Web Push active — generate VAPID keys if not done:"
  info "   npx web-push generate-vapid-keys"
  info "   Add VAPID_PUBLIC_KEY to client.json; export VAPID_PRIVATE_KEY=<key> before running deliver.sh"
  info "   No new cron needed — push piggybacks send-reminders (daily 10am UTC) and send-notification"
  if [[ -z "$VAPID_PRIVATE_KEY" ]]; then
    warn "VAPID_PRIVATE_KEY not set in shell env — VAPID secrets not pushed to Supabase"
  fi
fi

if [[ "${CLIENT_PHOTOS_ENABLED:-false}" == "true" ]]; then
  info "□  Client Photos: create a PRIVATE Supabase Storage bucket named 'client-photos'"
  info "   Upload photos via Admin → Client Photos (/admin/client-photos)"
fi

if [[ "${RECURRING_ENABLED:-false}" == "true" ]]; then
  info "□  Recurring bookings active — clients set up series from the confirmation screen"
  info "   Admin can cancel entire series from the booking overview (cancel_recurring_series fn)"
fi

if [[ "${STRIPE_INVOICING_ENABLED:-false}" == "true" ]]; then
  info "□  Stripe Invoicing active — ensure STRIPE_SK secret is set:"
  info "   supabase secrets set STRIPE_SK=sk_live_..."
  info "   Admin → Bookings → confirmed tile → SEND INVOICE button"
fi

if [[ "${INVOICES_ENABLED:-false}" == "true" ]]; then
  info "□  PDF Invoicing active — business logo must be in a public Storage bucket"
  info "   (signed URLs expire — use public bucket URL in business_config.logo_url)"
  info "   Admin → Bookings → confirmed tile → GENERATE PDF INVOICE button"
fi

if [[ "${REVIEWS_SYNC_ENABLED:-false}" == "true" ]]; then
  if [[ -z "$GOOGLE_PLACES_API_KEY" ]]; then
    warn "REVIEWS_SYNC_ENABLED=true but GOOGLE_PLACES_API_KEY is not set in shell env — sync will fail"
  fi
  info "□  Google Reviews sync active — schedule in Supabase dashboard:"
  info "   Edge Functions → sync-google-reviews → Schedule: '0 3 * * *' (3am daily)"
  info "   Get Places ID: Google Maps → your business → Share → Embed a map → place_id= param"
  info "   Google Cloud Console: enable Places API, add billing (required even for free tier)"
fi

if [[ "${LOCATIONS_ENABLED:-false}" == "true" ]]; then
  info "□  Multi-location active — add locations via Admin → Locations"
  info "   Assign staff to locations: Admin → Team → edit staff → set Location"
  info "   Booking flow will show location selector as first step"
fi
if [[ "${FCM_ENABLED:-false}" == "true" ]]; then
  info "□  FCM active — complete setup per planning/client/15_mobile.md Step 9:"
  info "   android/app/google-services.json + ios/Runner/GoogleService-Info.plist"
  info "   Run: flutterfire configure && flutter pub add firebase_core firebase_messaging"
  info "   Add Firebase.initializeApp() + registerFcmTapHandlers() to main.dart"
  info "   Set FIREBASE_SERVICE_ACCOUNT in Supabase + Codemagic env vars"
fi

if has_module "subscriptions"; then
  info "□  Subscriptions active — create products + prices in Stripe dashboard"
  info "   Paste each Price ID into Admin → Subscription Plans (stripe_price_id field)"
  info "   Subscription events are handled automatically via stripe-dispatcher (no extra webhook needed)"
fi
if [[ "${RECURRING_ENABLED:-false}" == "true" ]]; then
  info "□  Schedule send-recurring-payment-reminders: daily cron, e.g. '0 9 * * *'"
fi

if has_module "referrals"; then
  info "□  Referrals active — clients get their link at /referrals (must be logged in)"
  info "   Reward trigger: process-referral is called automatically from stripe-dispatcher after booking confirms"
  info "   To adjust discount amount, edit DISCOUNT_PCT in functions/process-referral/index.ts"
fi

if has_module "shop"; then
  info "□  Shop module active:"
  info "   1. Add products via Admin → Products (/admin/shop/products)"
  info "   2. Shop orders are confirmed via stripe-dispatcher (metadata.type=shop_order — no extra webhook)"
  info "   3. Shop is public at ${SITE_URL}/shop — no login required to browse or buy"
fi

if has_module "courses"; then
  info "□  Courses module active:"
  info "   1. Create Supabase Storage bucket: 'course-videos'      (Private — no public access)"
  info "   2. Create Supabase Storage bucket: 'course-thumbnails'  (Public — read-only)"
  info "   3. Upload video files: Supabase dashboard → Storage → course-videos"
  info "   4. Upload thumbnails:  Supabase dashboard → Storage → course-thumbnails"
  info "   5. Add courses + lessons via Admin → Courses (/admin/courses)"
  info "      Set video_storage_path and thumbnail_storage_path on each lesson/course"
  info "   6. Course purchases confirmed via stripe-dispatcher (metadata.type=course — no extra webhook)"
  info "   7. Set COURSES_ENABLED=true in client.json dart-defines before building"
fi

if [[ "${GDPR_ENABLED:-false}" == "true" ]]; then
  info "□  Verify cookie consent banner displays for EU visitors"
fi

info "□  Create master user: sign up via app → UPDATE profiles SET role='master'"
info "□  Adjust business_hours via Admin panel (defaults: Mon–Sat 09:00–18:00)"
info "□  Run UptimeRobot monitor for: $SITE_URL"

BUNDLE_ID=$(json_get "BUNDLE_ID")
if [[ -n "$BUNDLE_ID" ]]; then
  printf "\n"
  bold "Mobile checklist (bundle: $BUNDLE_ID):"
  info "□  Run: ./prepare_mobile.sh  (or pass --mobile on next deliver.sh run)"
  info "□  Paste release keystore SHA-256 into web/.well-known/assetlinks.json"
  info "   Run: keytool -list -v -keystore release.jks -alias release | grep SHA256"
  info "□  iOS: Xcode → Runner → Signing & Capabilities → + → Associated Domains"
  info "   Add: applinks:$(echo "$SITE_URL" | sed 's|https\?://||;s|/.*||')"
  info "□  Ensure web/.well-known/ files are served at $SITE_URL (included in web build)"
fi

printf "\n"
