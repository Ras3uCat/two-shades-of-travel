# Phase 0 — Client Discovery Reference

The client fills out the **Raspucat discovery form** which covers all sections below.
On approval, the Raspucat admin panel generates a `client.json` with these values pre-filled.
Use this document as a reference for what each field means, what to check after export,
and which items (domain, Resend, Stripe) require action outside the form.

---

## Business Basics

| Question | Maps to |
|----------|---------|
| What is the full business name? | `CLIENT_NAME`, `BUSINESS_NAME` (Resend sender) |
| What is the preferred URL slug? (e.g. `acme-studio`) | `CLIENT_SLUG` — lowercase, hyphens only, no spaces |
| What is their primary timezone? | `TIMEZONE` (e.g. `America/New_York`) — affects booking slot display and reminder send times |
| What domain will the site live on? | `SITE_URL` (e.g. `https://acme.studio`) |
| Do they own the domain already? | If not: buy it now. If yes: who manages DNS — them or a web designer? |
| What email should transactional emails come from? | `FROM_EMAIL` (e.g. `hello@acme.studio`) — must match the verified sending domain in Resend |
| Do they have an existing site that needs cutting over? | Affects deploy timing — see [09_deploy.md](09_deploy.md). Plan a maintenance window. |
| Is there a hard launch deadline? (lease, campaign, event) | Sets scope — determines what can be deferred to post-launch |

> **Domain tip:** If they don't own the domain yet, buy it before doing anything else. DNS propagation
> and email domain verification (Resend) can each take 24–48 hours — you don't want these blocking
> you on go-live day.

---

## SEO & Content

These go into `client.json` and are substituted into `index.html`, `sitemap.xml`, `robots.txt`, and `manifest.json` automatically by `prepare.sh`.

| Question | `client.json` field |
|----------|---------------------|
| Page title for Google results? (e.g. "Acme Studio — Luxury Hair") | `SEO_TITLE` |
| 1–2 sentence site description for Google? | `SEO_DESCRIPTION` |
| Social share image? (1200×630 px — see tip below) | `OG_IMAGE` (full URL) |
| Business phone number? | `PHONE` (E.164, e.g. `+12125551234`) |
| Street address? | `STREET` |
| City? | `CITY` |
| State / region? | `STATE` |
| Postal / ZIP code? | `ZIP` |
| Country code? (e.g. `US`, `GB`) | `COUNTRY` |
| Opening hours per day? | `HOURS_JSON` (JSON-LD array — see tip below) |

> **OG image:** Drop `og.jpg` (1200×630 px) in `web/` — Flutter copies it to `build/web/` automatically.
> Then set `OG_IMAGE` to `https://yourclientdomain.com/og.jpg`. You can use the staging URL
> (`*.pages.dev`, `*.vercel.app`) temporarily until the real domain is live.
>
> **HOURS_JSON is for Google structured data only.** It is NOT what drives booking availability —
> the `business_hours` table in Supabase does that (seeded automatically, adjusted via Admin panel).
> If the client changes their hours after launch, update **both**.

---

## Brand Assets

| Question | Maps to |
|----------|---------|
| Logo file (SVG or high-res PNG, ≥512 px)? | Used to generate favicon + PWA icons |
| Short app name for home screen icon? (≤12 chars) | `SHORT_NAME` in `client.json` |
| Brand primary hex colour? | `COLOR_PRIMARY` — sets loading screen spinner, manifest theme_color |

> Export the logo as `favicon.png` (32×32), `Icon-192.png`, `Icon-512.png`,
> `Icon-maskable-192.png`, and `Icon-maskable-512.png`. Tools: realfavicongenerator.net or Figma export.

---

## Content Readiness

Ask before starting any build work. Missing content is the most common cause of delayed launches.

| Question | Notes |
|----------|-------|
| Are service names, descriptions, and prices finalised? | Required to seed the `services` table — minimum: name, duration (mins), price |
| Do you have professional photos? (hero, team, gallery, OG image) | Hero image and OG image are required before go-live; gallery and team photos can follow |
| Who is writing the website copy — you or them? | If client: agree a deadline in writing. If you: scope and price it separately. |
| Do they have a logo in a usable format? | SVG or PNG ≥ 512 px. JPEG logos are a red flag — they usually need a designer first. |

> **Minimum to start a build:** confirmed service list + one hero image. Everything else can be
> added post-launch, but without these two the homepage cannot be built.
>
> **No photos?** You can use high-quality stock photography (Unsplash, Pexels) as temporary
> placeholders, but make this explicit with the client — stock images set the wrong expectation
> if left in production.
>
> **Photo specs:**
> - Hero: landscape, ≥1920×1080 px, ideally wide-crop so it works on mobile too
> - Team: square or portrait, consistent crop across all staff
> - OG image: exactly 1200×630 px — this is what appears when the link is shared on social media
> - Gallery: consistent aspect ratio (square works best across screen sizes)

---

## Modules Needed

Ask each question directly. A module not needed = smaller app, fewer secrets to configure.

There are two distinct configuration mechanisms — make sure you use the right one:

### `MODULES` string — full page modules with routes and nav items

| Question | `MODULES` value | What it delivers |
|----------|-----------------|-----------------|
| Do you need online booking? | `booking` | Full booking flow: service → staff → time slot → payment → confirmation email + admin calendar |
| Do you want a newsletter signup? | `newsletter` | Email capture form + welcome email via Resend + unsubscribe flow |
| Do you want customer testimonials displayed? | `testimonials` | Curated quote cards on the homepage; managed via Admin panel |
| Do you want a gallery of your work? | `gallery` | Photo grid; images uploaded and managed via Admin panel |
| Do you want an FAQ section? | `faq` | Accordion Q&A; managed via Admin panel |
| Do you want a blog? | `blog` | Full post editor in Admin; posts get individual SEO slugs and appear in sitemap.xml |
| Do you want a CRM client list in the admin dashboard? | `crm` | Searchable client list with booking history; auto-populated from bookings |
| Do you want to sell memberships / subscription plans? | `subscriptions` | Stripe-powered recurring billing; members get a flag on their profile usable for discounts |
| Do you want a referral programme? | `referrals` | Each client gets a unique share link; both referrer and new client receive a discount on first booking |
| Do you want to sell physical or digital products? | `shop` | Stripe Checkout product listings; order management in Admin |
| Do you host workshops, classes, pop-ups, or ticketed events? | `events` | Ticketed event listings with Stripe Checkout; capacity limits and RSVP management |

> **Subscriptions are independent of the booking module.** A subscription can represent a membership,
> class pass, product box, or retainer — it does not require `booking` in MODULES. If both modules
> are enabled, use `booking_discount_pct` on the plan to give subscribers a booking discount
> (requires custom logic in the booking flow).

> `home`, `contact`, and `auth` are base modules — always include them in the `MODULES` string.
> The Raspucat admin generates them automatically. Do not omit them.
>
> **Tip:** To deliver a site with no online booking at all, simply omit `booking` from `MODULES`.
> The entire booking flow, admin booking views, and Stripe configuration become unnecessary —
> skip those sections of this guide.

### Boolean feature flags — booking add-ons and cross-cutting features

Set to `"true"` in `client.json`:

| Question | `client.json` flag |
|----------|--------------------|
| Do they take payments? (Stripe) | `STRIPE_PK` + `STRIPE_MODE` — see [06_stripe.md](06_stripe.md) |
| Do they have multiple staff needing individual payouts? | `STRIPE_MODE: "connect_multi_staff"` |
| Do you serve EU customers? (GDPR cookie banner) | `GDPR_ENABLED: "true"` |
| Enable Google login? | `GOOGLE_AUTH_ENABLED: "true"` |
| Enable Apple login? | `APPLE_AUTH_ENABLED: "true"` |
| Send SMS appointment reminders? *(Twilio)* | `SMS_ENABLED: "true"` |
| Collect a client intake form after booking? | `INTAKE_ENABLED: "true"` |
| Award loyalty points for completed bookings? | `LOYALTY_ENABLED: "true"` |
| Sell gift vouchers? | `GIFT_ENABLED: "true"` |
| Enable a waitlist when no slots are available? | `WAITLIST_ENABLED: "true"` |
| Offer pre-configured service bundles/packages? | `PACKAGES_ENABLED: "true"` |
| Send post-appointment review request emails? | `REVIEWS_ENABLED: "true"` |
| Store before/after client photos per booking? | `CLIENT_PHOTOS_ENABLED: "true"` |
| Allow clients to set up recurring bookings? *(e.g. "same slot every 4 weeks")* | `RECURRING_ENABLED: "true"` |

> **Staff calendar sync (iCal):** All staff members automatically get a private iCal feed URL at `/staff`.
> They can subscribe to it in Google Calendar, Apple Calendar, or Outlook to see their bookings on their
> phone. No module flag, no client.json field, no discovery question required — it's always available.
> Admin can view or regenerate any staff member's feed token via Admin → Staff.

> **Recurring bookings + Stripe:** When Stripe is configured, future recurring slots are created
> as `pending` and the client receives a payment link email before each appointment (default: 3 days
> ahead, configurable in `business_config`). Without Stripe, all slots are reserved as `confirmed`
> immediately — no payment collected for future appointments.
>
> **Recurring bookings ≠ Stripe Subscriptions.** Recurring bookings are per-appointment charges.
> For automatic monthly/yearly billing, use the `subscriptions` module instead.

---

## Staff & Calendar Setup

Ask only if the `booking` module is enabled.

| Question | Notes |
|----------|-------|
| How many staff members will take bookings? | Each staff member gets their own calendar, profile page, and iCal feed |
| Do all staff take all services, or is it per-staff? | Per-staff service mapping is done in Admin → Staff after launch |
| One shared calendar or per-staff booking? | Per-staff is the default; for solo operators, create a single staff record matching the business name |
| What are their working hours? | Set per-day in Admin → Business Hours after launch; overridden per-staff in Admin → Staff if hours differ |
| Will staff manage their own bookings, or is it admin-only? | Staff login (role: `staff`) can view and manage their own bookings only; `master` sees all |
| Do you need staff to accept or reject bookings manually? | By default bookings auto-confirm; manual approval requires custom logic — scope separately |

> **Seeding staff:** Each staff member needs at minimum a display name. Bio, photo URL, and
> specialties can be added later via Admin → Staff — they do not block the build.
>
> **iCal:** Every staff member automatically gets a private iCal feed at `/staff`. They can
> subscribe to it in Google Calendar, Apple Calendar, or Outlook. No setup required — just
> point them to Admin → Staff → their profile to copy the feed URL.

---

## Existing System & Migration

| Question | Notes |
|----------|-------|
| Are they currently using a booking system? (Acuity, Mindbody, Square, etc.) | Affects go-live timing — they need to stop taking bookings in the old system before cutover |
| Is there a client list to import? | Most platforms export a CSV — this can be imported into the `profiles` table manually |
| Is there historical booking data to import? | No automated migration tool exists — manual SQL inserts only; price this separately if required |
| Are there active future bookings in the old system? | These must be manually re-entered or communicated to clients individually |
| Do they have existing Stripe customers or subscriptions? | If yes, Stripe customer IDs would need to be mapped — complex, scope separately |

> **Cutover strategy:** The safest approach is a soft launch — run both systems in parallel for
> 1–2 weeks while existing bookings complete in the old system. New bookings go into the new site.
> Announce the switch to clients via email. Hard cutovers (flip the DNS and immediately stop the
> old system) carry risk of lost bookings if anything goes wrong on launch day.
>
> **What can typically be migrated easily:** client name + email list (CSV import).
> **What cannot be migrated without custom work:** booking history, loyalty points, subscription billing cycles.

---

## Visual Brand

| Question | Maps to |
|----------|---------|
| What is the overall feel? *(luxury / minimal / bold / warm / corporate)* | `PERSONALITY` — sets the full visual language (spacing, typography scale, component style) |
| What is the primary brand colour? *(hex, no #)* | `COLOR_PRIMARY` |
| What is the secondary colour? | `COLOR_SECONDARY` |
| Do you have an accent colour? | `COLOR_ACCENT` |
| Light or dark background? *(give them hex)* | `COLOR_SURFACE` (background), `COLOR_ON_SURFACE` (text on background) |
| Primary font? *(Google Fonts name)* | `FONT_PRIMARY` — used for headings |
| Secondary / body font? | `FONT_SECONDARY` — used for body text and UI elements |
| Hero style? *(fullbleed / split / centered)* | `HERO_VARIANT` |
| Nav style? *(sticky / overlay / sidebar / minimal)* | `NAV_STYLE` |
| Which sections on the home page? | `HOME_SECTIONS` — ordered list: `hero,services,team,testimonials,gallery,faq,cta` |

> **Personality guide** — use this to steer the conversation if the client isn't sure:
> - `luxury` — dark backgrounds, gold/cream accents, editorial spacing, serif headings. Think high-end salon, spa, or boutique.
> - `minimal` — white space-heavy, single accent colour, clean sans-serif. Think studio, architect, or modern clinic.
> - `bold` — high contrast, strong typographic hierarchy, punchy CTAs. Think fitness, barbershop, or streetwear.
> - `warm` — soft earthy tones, rounded corners, inviting imagery. Think café, florist, or family business.
> - `corporate` — structured grid, navy/grey palette, professional tone. Think law firm, accountant, or consultancy.
>
> **No brand guide?** Ask them to send 3 websites they like the look of. Pull the hex values from
> their logo using a colour picker tool (e.g. imagecolorpicker.com). For fonts, [Fontjoy](https://fontjoy.com)
> generates harmonious pairings quickly.
>
> **Inspiration URLs from Raspucat form:** If the client submitted URLs via the discovery form, they
> will be exported as `BRAND_INSPO_URLS` in `client.json` alongside all other pre-filled fields.
> After scaffolding the project, run `/inspo` in Claude Code — it fetches each URL and produces a
> Brand Alignment Report saved to `planning/client/brand_alignment.md`. The report cross-checks
> PERSONALITY, colors, fonts, layout, and HOME_SECTIONS against what the inspiration sites actually
> signal. Review and apply recommendations to `client.json` before running `deliver.sh`.
> Mark `brand_alignment_complete` in the Raspucat admin delivery tab when done.
>
> **Hero variants:**
> - `fullbleed` — full-width background image with text overlay. Best for strong hero photography.
> - `split` — image on one side, text on the other. Works well when the image is portrait-oriented.
> - `centered` — centred text over a muted or gradient background. Best when no strong hero photo exists yet.

---

## Social Media

| Question | Maps to |
|----------|---------|
| Instagram profile URL? | `INSTAGRAM_URL` (shown in footer if set) |
| Facebook page URL? | `FACEBOOK_URL` |
| TikTok profile URL? | `TIKTOK_URL` |
| YouTube channel URL? | `YOUTUBE_URL` |

> Leave any field empty in `client.json` to hide that icon from the footer.

---

## Auth Options

| Question | Maps to |
|----------|---------|
| Enable "Continue with Google" login? | `GOOGLE_AUTH_ENABLED: "true"` + Supabase Google OAuth setup |
| Enable "Continue with Apple" login? | `APPLE_AUTH_ENABLED: "true"` + Apple Developer setup |

> Both are optional overlays on the standard email/password flow. Enable only if the client specifically requests it.

---

## Payments (booking and/or shop module)

| Question | Maps to |
|----------|---------|
| Do they have a Stripe account? | If not: create one at stripe.com — business verification can take 1–3 days |
| Standard (solo) or Connect (multiple staff payouts)? | `STRIPE_MODE` — see below |
| Live or test mode to start? | Always recommend test mode first — switch to live keys once QA is done |
| Stripe publishable key | `STRIPE_PK` (`pk_test_...` or `pk_live_...`) |
| Stripe secret key | `STRIPE_SECRET_KEY` in `client.json` → pushed to Supabase secret `STRIPE_SK` by `deliver.sh` |
| Booking webhook secret *(generated after site is live)* | Supabase secret `STRIPE_WEBHOOK_SECRET` — generated when you register the webhook endpoint |
| Shop webhook secret *(only if `shop` in MODULES)* | `STRIPE_SHOP_WEBHOOK_SECRET` — separate Stripe webhook endpoint |
| Events webhook secret *(only if `events` in MODULES)* | `STRIPE_EVENTS_WEBHOOK_SECRET` — separate Stripe webhook endpoint |

> **Standard vs Connect:**
> - `standard` — one Stripe account receives all payments. The business owner withdraws manually.
>   Simplest setup, right for solo operators or businesses where the owner pays staff separately.
> - `connect_multi_staff` — each staff member has their own connected Stripe account. Payments are
>   split and routed automatically at checkout. Right for booth-rental salons, studios where artists
>   are self-employed, or any setup where staff need individual payouts. Significantly more complex to set up.
>
> **Stripe account readiness:** Stripe requires identity verification and a linked bank account
> before payouts are enabled. The client must complete this before go-live — you cannot do it for them.
> Chase this early; it's a common blocker.
>
> **Webhook secrets** are generated inside the Stripe dashboard when you create the webhook endpoint.
> They cannot be known until the site is live and the endpoint URL is registered. Use `--register-webhooks`
> flag in `deliver.sh` to automate this step.

---

## Cancellation Policy

Ask only if the `booking` module is enabled.

| Question | Notes |
|----------|-------|
| Do you charge for late cancellations or no-shows? | If yes → collect a deposit at booking time via Stripe; see [06_stripe.md](06_stripe.md) |
| What deposit amount or percentage? | Set per-service in Admin → Services after launch (e.g. 20%, or a flat fee) |
| What is your cancellation window? (e.g. 24h, 48h) | Shown in booking confirmation email and should appear in their Terms of Service |
| Can clients cancel online themselves? | By default yes, up until the appointment time — there is no automated window enforcement; policy is informational |

> **Deposit vs full payment:** Deposits hold the slot and reduce no-shows. Full payment upfront
> is possible but increases friction at booking. Most service businesses use 20–30% deposits.
>
> **The platform does not automatically enforce the cancellation window** (e.g. blocking
> cancellations within 24h). It is the client's responsibility to handle late cancellations
> manually and decide whether to retain the deposit. This should be communicated clearly at handover.

---

## Email (only if any module sends email)

Applies if any of these are enabled: `booking`, `newsletter`, `contact`, `reviews`, `referrals`, `subscriptions`.

| Question | Notes |
|----------|-------|
| Resend account — theirs or yours? | If yours: you control billing and API keys. If theirs: they create the account, you get the API key. |
| What domain are they sending from? | Must match `FROM_EMAIL`. The domain needs DNS records added (SPF, DKIM) — Resend provides these. |
| Has the sending domain been verified in Resend? | DNS verification takes up to 48h. Do this early — it blocks all transactional email if not done. |

> **Resend domain verification** requires adding 2–3 DNS records (provided by Resend) to the
> domain's DNS settings. If the client controls their own DNS (e.g. GoDaddy, Namecheap), they
> need to add these themselves or give you access. If DNS is in Cloudflare, you can do it directly.
>
> The `RESEND_KEY` is a **Supabase secret only** — it is never embedded in the app build.
> The `RESEND_KEY` field in `client.json` is read by `deliver.sh` only to push it to Supabase secrets.
> Edge functions read the key at runtime from Supabase — not from the app bundle.

---

## Legal & Compliance

| Question | Action required |
|----------|----------------|
| Do they have a Privacy Policy? | Required for any site with a contact form, newsletter, or booking. If not, use a generator (Termly, iubenda, or plain-text draft). |
| Do they have Terms of Service? | Required if the site takes payments or bookings. |
| Do they serve EU users? | GDPR module covers the cookie banner — but a Privacy Policy is still legally required regardless. |
| Where should legal pages live? | Add `/privacy` and `/terms` as static routes, or link to a hosted document (e.g. Termly embed URL). |

> You are not responsible for drafting legal documents — but you are responsible for flagging
> the requirement. Do not launch a site with booking or a contact form without confirming the
> client has a Privacy Policy in place.

---

## Analytics

Set up at launch — the longer you wait, the less historical data the client has.

| Question | Notes |
|----------|-------|
| Do they want to see visitor traffic? | GA4 (free, widely understood by clients) or Plausible ($9/mo, no cookies, GDPR-compliant) |
| Do they have a Google Business Profile? | Free, affects local search ranking and Google Maps listing — always recommend setting one up |
| Google Search Console | Always set up at launch regardless of other choices — takes 4–12 weeks to show ranking data |
| Uptime monitoring? | UptimeRobot free tier — alerts you if the site goes down before the client notices |

> **Analytics choice guide:**
> - GA4: best when the client already uses Google tools or wants to run Google Ads. More data, more complexity.
> - Plausible: best for EU clients or anyone with `GDPR_ENABLED=true`. No cookie consent needed for Plausible itself.
> - Both can be installed simultaneously if needed.
>
> **If `GDPR_ENABLED=true`:** Do not paste the GA4 snippet directly in `<head>`. Use the
> consent-gated path in `index.html.tpl` — analytics only fires after the user clicks Accept.
> Full instructions in [10_analytics.md](10_analytics.md).
>
> **Google Business Profile:** This is free and separate from the website. It controls what appears
> when someone searches the business name on Google — address, hours, photos, reviews. If they
> don't have one, set it up. Verification takes 1–2 weeks (postcard or video call).
>
> **Search Console tip:** Tell the client upfront that it takes 4–12 weeks to show meaningful
> ranking data for a new domain. Set expectations now or they will chase you after week 1.

---

## Post-Launch Support

Define this before the project starts, not after.

| Question | Notes |
|----------|-------|
| Who manages the admin panel day-to-day? | Client themselves, a staff member, or you? Determines who needs training |
| What does the client expect when something breaks? | Set response time expectations upfront — "same day" vs "within 48h" vs "best effort" |
| Support model after go-live? | Retainer (monthly fee, defined scope) / hourly (billed as used) / included window (e.g. 30 days free, then hourly) |
| Are they on Supabase free tier? | Free tier projects pause after 1 week of inactivity. Recommend upgrading to Pro ($25/mo) for any production booking site. |

> **Admin training covers:**
> - Adding/editing services, staff, and business hours
> - Viewing and managing bookings (confirm, cancel, add notes)
> - CRM — client list and booking history
> - Content management — hero text, testimonials, gallery, FAQs, blog posts
> - Analytics dashboard (revenue, top services, busiest days)
>
> **Supabase free tier warning:** If the project sits idle (no API calls) for 7 days, Supabase
> pauses the database. This will break the site silently. For any live booking client, strongly
> recommend the Pro plan or at minimum set up an uptime monitor (UptimeRobot) that pings the site
> every 5 minutes — this keeps the project active and alerts you if it goes down.
>
> **A retainer is always preferable to hourly** for the client — predictable cost. For you — predictable
> income. Suggested minimum: 1–2 hours/month covering security updates, content changes, and monitoring.

---

## Mobile (if delivering iOS/Android)

Add these to the intake if the client wants a mobile app.

| Question | Notes |
|----------|-------|
| iOS + Android, or one platform? | Android-only skips the Apple Developer account entirely |
| App name on the store listing? | Can differ from the short in-app name (`SHORT_NAME`) — store name has a 30-char limit |
| Bundle ID? (e.g. `com.acmestudio.app`) | Pattern: `com.<slug>.app` — maps to `BUNDLE_ID`. Must match exactly if replacing an existing app. |
| Apple Developer account — theirs or yours? | $99/yr USD. The app is published under whoever owns the account. Recommend client owns it. |
| Apple Developer Team ID? | 10-char alphanumeric ID from developer.apple.com → Account → Membership — maps to `APPLE_TEAM_ID` |
| Any existing app to replace on the stores? | Bundle ID must match the existing app exactly or it will publish as a new separate app |
| Push notifications needed? | Requires FCM (Android) + APNs (iOS) setup — not included by default, scope separately |
| TestFlight beta period before App Store submission? | Strongly recommended — plan 1–2 weeks for beta testing before submitting to App Store review |

> **Store review timelines:**
> - Google Play: typically 1–7 days for first submission; updates are usually faster (hours to 1 day)
> - Apple App Store: typically 1–3 days; first submission sometimes longer. Rejections are common —
>   budget time for one resubmission cycle.
>
> **Apple Developer account:** The client should own this account, not you. If you own it and the
> relationship ends, transferring app ownership is painful. Walk them through creating it during discovery.
>
> **Android-first strategy:** If budget or timeline is tight, launch Android first (no $99 fee,
> faster review, simpler signing) and add iOS in a second phase. The codebase is identical — only
> the signing and submission process differs.
