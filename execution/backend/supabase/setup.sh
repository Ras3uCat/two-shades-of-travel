#!/usr/bin/env bash
# setup.sh — Run Supabase migrations for this client's enabled modules.
# Usage: MODULES='booking,newsletter' CLIENT_JSON='/path/to/client.json' ./setup.sh
# Run AFTER: supabase link --project-ref <client-project-ref>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATIONS_DIR="$SCRIPT_DIR/migrations"

# ─── Resolve client.json ──────────────────────────────────────────────────────
# deliver.sh passes CLIENT_JSON env var. Fallback: look two dirs up from backend/.
if [[ -z "${CLIENT_JSON:-}" ]]; then
  CLIENT_JSON="$(dirname "$(dirname "$SCRIPT_DIR")")/frontend/app/client.json"
fi

if [[ ! -f "$CLIENT_JSON" ]]; then
  echo "⚠️  client.json not found at $CLIENT_JSON"
  CLIENT_JSON=""
fi

# ─── Read MODULES from env or client.json ─────────────────────────────────────
if [[ -z "${MODULES:-}" ]]; then
  if [[ -n "$CLIENT_JSON" ]]; then
    MODULES=$(python3 -c "import json; d=json.load(open('$CLIENT_JSON')); print(d.get('MODULES','home,contact,auth'))")
  else
    echo "⚠️  No MODULES env var and no client.json found. Running base migrations only."
    MODULES="home,contact,auth"
  fi
fi

echo "📦 Modules enabled: $MODULES"
echo ""

# ─── Always run: base schema + auth hook ──────────────────────────────────────
echo "▶ Running 000_base.sql..."
supabase db execute --file "$MIGRATIONS_DIR/000_base.sql" --linked
echo "✅ Base schema applied."

echo "▶ Running 001_auth_hook.sql..."
supabase db execute --file "$MIGRATIONS_DIR/001_auth_hook.sql" --linked
echo "✅ Auth hook function created."
echo "   ⚠️  Remember to register it: Auth → Hooks → Custom Access Token → custom_access_token_hook"

# ─── Conditional module migrations ────────────────────────────────────────────
run_if_enabled() {
  local module="$1"
  local file="$2"

  if [[ ",$MODULES," == *",$module,"* ]]; then
    if [[ -f "$MIGRATIONS_DIR/$file" ]]; then
      echo "▶ Running $file (module: $module)..."
      supabase db execute --file "$MIGRATIONS_DIR/$file" --linked
      echo "✅ $module migration applied."
    else
      echo "⚠️  $file not found — skipping $module migration."
    fi
  fi
}

run_if_enabled "booking"      "010_booking.sql"
run_if_enabled "newsletter"   "020_newsletter.sql"
run_if_enabled "newsletter"   "021_newsletter_unsubscribe.sql"
run_if_enabled "testimonials" "030_testimonials.sql"
run_if_enabled "faq"          "031_faq.sql"
run_if_enabled "gallery"      "032_gallery.sql"
run_if_enabled "blog"         "033_blog.sql"

# ─── Always-on: user profiles, content, reminders, pending bookings ───────────
run_always() {
  local file="$1"
  if [[ -f "$MIGRATIONS_DIR/$file" ]]; then
    echo "▶ Running $file (always)..."
    supabase db execute --file "$MIGRATIONS_DIR/$file" --linked
    echo "✅ Applied $file."
  fi
}

run_always "040_booking_user_profile.sql"
run_always "070_deposit.sql"
run_always "050_content_management.sql"
run_always "060_reminders_notes.sql"
run_always "061_pending_booking.sql"

# ─── Conditional: CRM, booking add-ons, subscriptions, referrals, shop ────────
run_if_enabled "crm"           "062_crm.sql"

# Booking add-on feature flags (driven by MODULES or env var matching names)
# These use module-like flag names; treat non-empty flag value of "true" as enabled.
flag_enabled() {
  [[ -n "$CLIENT_JSON" ]] && \
    [[ "$(python3 -c "import json; d=json.load(open('$CLIENT_JSON')); print(d.get('$1','false'))" 2>/dev/null)" == "true" ]]
}

if flag_enabled "SMS_ENABLED";           then run_always "071_sms_phone.sql"; fi
if flag_enabled "GIFT_ENABLED";          then run_always "072_gift_vouchers.sql"; fi
if flag_enabled "INTAKE_ENABLED";        then run_always "073_intake_forms.sql"; fi
if flag_enabled "LOYALTY_ENABLED";       then run_always "074_loyalty.sql"; fi
if flag_enabled "WAITLIST_ENABLED";      then run_always "075_waitlist.sql"; fi
if flag_enabled "PACKAGES_ENABLED";      then run_always "076_packages.sql"; fi

run_if_enabled "booking"       "077_staff_hours.sql"

if flag_enabled "REVIEWS_ENABLED";       then run_always "078_reviews.sql"; fi
if flag_enabled "INVOICES_ENABLED";      then run_always "096_invoice_generation.sql"; fi
if flag_enabled "CLIENT_PHOTOS_ENABLED"; then run_always "079_client_photos.sql"; fi
if flag_enabled "RECURRING_ENABLED";     then
  run_always "080_recurring_bookings.sql"
  run_always "081_recurring_payment.sql"
fi

run_if_enabled "subscriptions" "082_subscriptions.sql"
run_if_enabled "referrals"     "083_referrals.sql"
run_if_enabled "booking"       "084_analytics.sql"
run_if_enabled "shop"          "085_shop.sql"

# 086 extends get_revenue_summary() — only applies when both booking + shop are enabled
if [[ ",$MODULES," == *",shop,"* ]] && [[ ",$MODULES," == *",booking,"* ]]; then
  run_always "086_shop_analytics.sql"
fi

run_if_enabled "events"        "087_events.sql"
run_if_enabled "menu"          "097_menu.sql"
if [[ ",$MODULES," == *",testimonials,"* ]] && flag_enabled "REVIEWS_SYNC_ENABLED"; then
  run_always "098_reviews_sync.sql"
fi
if flag_enabled "LOCATIONS_ENABLED"; then run_always "099_multi_location.sql"; fi
if flag_enabled "FCM_ENABLED";       then run_always "100_fcm_tokens.sql"; fi

# ─── Seed: business_config + business_hours ───────────────────────────────────
if [[ -n "$CLIENT_JSON" ]]; then
  echo ""
  echo "▶ Seeding business_config and business_hours..."

  # Generate seed SQL with real values from client.json
  SEED_SQL=$(python3 - "$CLIENT_JSON" "$MIGRATIONS_DIR/002_seed.sql" << 'PYEOF'
import json, sys
client_json_path = sys.argv[1]
seed_tpl_path    = sys.argv[2]
with open(client_json_path) as f:
    c = json.load(f)
with open(seed_tpl_path) as f:
    sql = f.read()
sql = sql.replace('CLIENT_NAME',     c.get('CLIENT_NAME', 'Client'))
sql = sql.replace('CLIENT_TIMEZONE', c.get('TIMEZONE',    'UTC'))
print(sql)
PYEOF
)

  SEED_TMP="$(mktemp /tmp/raspucat_seed_XXXXXX.sql)"
  echo "$SEED_SQL" > "$SEED_TMP"
  supabase db execute --file "$SEED_TMP" --linked
  rm -f "$SEED_TMP"
  echo "✅ business_config and business_hours seeded."
else
  echo "⚠️  Skipping seed — no client.json available. Insert business_config manually."
fi

echo ""
echo "🎉 Database setup complete for modules: $MODULES"

# ─── Cron jobs (pg_cron + pg_net — both enabled by default on Supabase) ───────
if [[ -n "$CLIENT_JSON" ]]; then
  SUPABASE_URL_VAL=$(python3 -c "import json; d=json.load(open('$CLIENT_JSON')); print(d.get('SUPABASE_URL','').rstrip('/'))" 2>/dev/null || echo "")
  SUPABASE_ANON_VAL=$(python3 -c "import json; d=json.load(open('$CLIENT_JSON')); print(d.get('SUPABASE_ANON_KEY',''))" 2>/dev/null || echo "")

  schedule_cron() {
    local name="$1" schedule="$2" fn_path="$3"
    [[ -z "$SUPABASE_URL_VAL" || -z "$SUPABASE_ANON_VAL" ]] && return 1
    local CRON_SQL="
SELECT cron.unschedule(jobname) FROM cron.job WHERE jobname = '${name}';
SELECT cron.schedule(
  '${name}',
  '${schedule}',
  format(
    \$\$SELECT net.http_post(url:=%L,headers:=%L::jsonb,body:=%L::jsonb)\$\$,
    '${SUPABASE_URL_VAL}/functions/v1/${fn_path}',
    '{\"Content-Type\":\"application/json\",\"apikey\":\"${SUPABASE_ANON_VAL}\"}',
    '{}'
  )
);"
    local CRON_TMP
    CRON_TMP=$(mktemp /tmp/cron_XXXXXX.sql)
    echo "$CRON_SQL" > "$CRON_TMP"
    if supabase db execute --file "$CRON_TMP" --linked 2>/dev/null; then
      echo "✅ Cron scheduled: $name ($schedule)"
      rm -f "$CRON_TMP"; return 0
    else
      echo "⚠️  Cron scheduling failed for $name — schedule manually in Supabase"
      rm -f "$CRON_TMP"; return 1
    fi
  }

  CLIENT_SLUG_VAL=$(python3 -c "import json; d=json.load(open('$CLIENT_JSON')); print(d.get('CLIENT_SLUG',''))" 2>/dev/null || echo "")

  echo "▶ Scheduling cron jobs..."

  if [[ ",$MODULES," == *",booking,"* ]]; then
    schedule_cron "expire-pending-bookings" "*/10 * * * *" "expire-pending-bookings" \
      && [[ -n "$CLIENT_SLUG_VAL" ]] && touch "/tmp/.cron_expire_${CLIENT_SLUG_VAL}" || true
    schedule_cron "send-reminders" "0 8 * * *" "send-reminders" \
      && [[ -n "$CLIENT_SLUG_VAL" ]] && touch "/tmp/.cron_reminders_${CLIENT_SLUG_VAL}" || true
  fi

  if [[ ",$MODULES," == *",google_reviews,"* ]]; then
    schedule_cron "send-review-requests" "0 10 * * *" "send-review-requests" \
      && [[ -n "$CLIENT_SLUG_VAL" ]] && touch "/tmp/.cron_reviews_${CLIENT_SLUG_VAL}" || true
  fi
fi
