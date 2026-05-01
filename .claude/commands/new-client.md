Scaffold a new client delivery project: $ARGUMENTS

Load `.claude/skills/client-delivery/SKILL.md` before proceeding.

**Input expected:** Client name and slug (e.g. "Acme Studio acme-studio"), or prompt interactively.

---

Walk through the following in order. Ask for each value if not provided in $ARGUMENTS.
Generate a ready-to-use `client.json` at the end.

**Step 1 — Identity**
- `CLIENT_NAME` — full business name (e.g. "Acme Studio")
- `CLIENT_SLUG` — URL-safe, hyphens only (e.g. "acme-studio")
- `SHORT_NAME` — home screen label, max 12 chars (default: first 12 of CLIENT_NAME)
- `BUNDLE_ID` — mobile app ID if mobile delivery needed (e.g. "com.acmestudio.app")

**Step 2 — Backend**
- `SUPABASE_URL` — from Supabase Settings → API → Project URL
- `SUPABASE_ANON_KEY` — from Supabase Settings → API → anon/public key
- `SITE_URL` — production domain, no trailing slash (e.g. "https://acmestudio.com")
- `TIMEZONE` — IANA timezone string (e.g. "America/New_York")

**Step 3 — Modules**
Ask: which feature modules does this client need?
List the available modules with one-line descriptions:
- booking, newsletter, blog, gallery, testimonials, faq, subscriptions, shop, events,
  courses, crm, gdpr, referrals, intake, gift, loyalty, waitlist, packages, reviews, recurring

Always include: `home,contact,auth`
Suggest: add `booking` for any service business.

**Step 4 — Payments** (skip if booking/shop/subscriptions not selected)
- `STRIPE_MODE` — "standard" (solo) or "connect_multi_staff" (multi-staff payouts)
- `STRIPE_PK` — public key (pk_test_... for now, swap to pk_live_... at launch)
- Note: STRIPE_SK goes directly to Supabase secrets — do NOT put in client.json

**Step 5 — Branding**
- `PERSONALITY` — luxury / minimal / bold / warm / corporate
- `COLOR_PRIMARY`, `COLOR_SECONDARY`, `COLOR_ACCENT` — hex without #
- `COLOR_SURFACE` — splash/icon background (default: "000000")
- `FONT_PRIMARY`, `FONT_SECONDARY` — Google Fonts names

**Step 6 — Email** (skip if no RESEND_KEY yet)
- `RESEND_KEY` — re_...
- `FROM_EMAIL` — must be a verified sender in Resend

**Step 7 — SEO**
- `SEO_TITLE` — max 60 chars, include business name + city + service
- `SEO_DESCRIPTION` — max 160 chars
- `PHONE`, `STREET`, `CITY`, `STATE`, `ZIP`, `COUNTRY` — for LocalBusiness JSON-LD

**Step 8 — Feature flags**
Ask which add-ons apply (default all false):
SMS_ENABLED, GDPR_ENABLED, CHATBOT_ENABLED, GOOGLE_AUTH_ENABLED, APPLE_AUTH_ENABLED,
DIGEST_ENABLED, LOYALTY_ENABLED, GIFT_ENABLED, INTAKE_ENABLED

---

**Output:**
1. Complete `client.json` with all answered fields filled in and unset fields commented out
2. Next steps checklist:
   - [ ] Copy template: `cp -r modular_project clients/CLIENT_SLUG`
   - [ ] Save client.json to `execution/frontend/app/client.json`
   - [ ] Link Supabase: `supabase link --project-ref <ref>`
   - [ ] Configure MCP in `.claude/settings.local.json` (see planning/client/02_setup.md §1.3)
   - [ ] Run `./deliver.sh`
   - [ ] Complete manual checklist printed by deliver.sh
