# Phase 12 — Post-Deploy QA Checklist

Run this checklist after deploying to the real domain and before client handover.

---

## Automated QA (Playwright)

Playwright specs in `qa/chrome/` run against the live deployed site — no local emulator needed.
Supabase is live from the moment the project is provisioned.

**One-time setup per client:**
1. Create a dedicated test user in Supabase Auth dashboard
2. Create a master test user for admin flows
3. Copy `qa/.env.example` → `qa/.env` and fill in:
   ```
   BASE_URL=https://yourclientdomain.com
   TEST_EMAIL=test@...
   TEST_PASSWORD=...
   TEST_MASTER_EMAIL=master@...
   TEST_MASTER_PASSWORD=...
   ```
4. `cd qa && npm test`

Specs cover: auth flows, booking steps 1–4, Stripe redirect, admin dashboard, staff restrictions.
Run automated specs first — the manual checks below cover gaps that automation doesn't reach.

---

## Cross-Browser & Device

Test on each of these — Flutter web on Safari has known quirks with fonts, scroll, and layout.

- [ ] **Chrome desktop** — primary test browser
- [ ] **Safari desktop** — check fonts, borders, scroll behaviour
- [ ] **Safari iOS** (actual iPhone, not DevTools simulator) — most common mobile browser
- [ ] **Chrome Android** — second most common mobile
- [ ] Responsive layout correct at 375px (iPhone SE), 768px (tablet), 1280px+ (desktop)
- [ ] Loading screen appears in correct colours on all browsers
- [ ] No console errors on any browser (open DevTools → Console)

---

## Core

- [ ] Home page loads, correct brand colours and fonts
- [ ] Contact form submits and client receives the email
- [ ] 404 page shows and home link works
- [ ] Navigation links all resolve correctly
- [ ] Direct URL navigation works (paste `/blog` in a new tab — tests SPA routing)
- [ ] www redirect works (both `www.acme.studio` and `acme.studio` resolve correctly)
- [ ] Loading screen displays on first visit, fades out cleanly when app is ready

---

## Default / Template Text — Verify None Remain

- [ ] **View page source** — `<title>` does NOT contain "Flutter", "raspucat", "CLIENT_TITLE", or "A new Flutter project"
- [ ] **View page source** — `<meta name="description">` does NOT contain "CLIENT_DESCRIPTION", "new Flutter", or is empty
- [ ] **View page source** — no unreplaced `CLIENT_*` tokens anywhere in the HTML
- [ ] `pubspec.yaml` `description` field is NOT `"A new Flutter project."`
- [ ] `pubspec.yaml` `name` field is NOT the template default (`raspucat_client` or `flutter_application`)
- [ ] PWA install prompt / home screen shows **client app name**, not the template name
- [ ] OG image loads and is NOT a placeholder — test at [opengraph.xyz](https://www.opengraph.xyz)

---

## SEO & PWA

- [ ] `<title>` tag shows client title (view page source)
- [ ] Meta description is correct length (140–160 chars) and contains natural keywords
- [ ] OG image loads when URL is pasted into Slack / iMessage
- [ ] JSON-LD validates at [schema.org/SchemaValidator](https://validator.schema.org)
- [ ] Favicon shows in browser tab (not the Flutter default blue)
- [ ] `sitemap.xml` loads at `https://yourclientdomain.com/sitemap.xml`
- [ ] `robots.txt` loads at `https://yourclientdomain.com/robots.txt` — `/admin` is disallowed
- [ ] "Add to Home Screen" on mobile shows correct icon and app name (not "raspucat_client")
- [ ] Sitemap submitted to Google Search Console

---

## Auth

- [ ] Owner signs up → role set to `master` → signs back in → Admin panel accessible
- [ ] Staff user signs up → role set to `staff` → signs back in → sees only staff views
- [ ] Non-admin user cannot access `/admin`
- [ ] Email confirmation link works (goes to the correct domain, not localhost)
- [ ] Supabase auth email shows client name (not generic Supabase template)

---

## Booking (if enabled)

- [ ] Available slots load for each staff member
- [ ] Step 1→2→3→4 flow completes, client notes field visible in Step 4
- [ ] Stripe Checkout opens with correct price (test card: `4242 4242 4242 4242`)
- [ ] Test payment completes → booking confirmed in DB with `stripe_payment_intent_id` set
- [ ] Confirmation email arrives to client
- [ ] Staff notification email arrives to the assigned artist
- [ ] Webhook event shows in Stripe dashboard with status `succeeded`
- [ ] Admin sees the booking in master Bookings view (with stats bar showing totals)
- [ ] Admin can CONFIRM a pending booking from the Bookings view
- [ ] Admin can CANCEL a booking → Stripe refund issued automatically, client notified by email
- [ ] **Stripe cancel:** abandon a checkout before paying → land back on `/booking` → confirm the slot is freed immediately (no wait). As a fallback, `expire-pending-bookings` cron also clears any bookings older than 30 min that slipped through
- [ ] **Confirmation screen:** "Add to Calendar" button downloads/opens an `.ics` file with correct event details
- [ ] **After test QA passes:** swap to live Stripe keys, rebuild, redeploy, re-register webhook
- [ ] **Deposit mode — pay at appointment (deposit_pct = 0):** Set to `0` in Admin → Settings → Booking Rules, then:
  - [ ] Complete a booking end-to-end — Stripe Checkout should NOT open
  - [ ] Booking lands on confirmation view directly (no redirect)
  - [ ] Booking is `confirmed` status in DB immediately (no `pending` state)
  - [ ] Client profile shows NO "COMPLETE PAYMENT" button for this booking
  - [ ] Admin sees the booking in correct `confirmed` status
  - [ ] Reset deposit_pct back to `100` after this test

---

## User Profile (if booking enabled)

- [ ] Authenticated user navigates to `/profile` and sees their booking history (all statuses)
- [ ] Pending bookings show a COMPLETE PAYMENT button (Stripe mode only)
- [ ] Paid bookings show a VIEW RECEIPT button; receipt dialog displays booking details
- [ ] CANCEL button appears for upcoming, non-completed bookings
- [ ] Cancel confirmation dialog shows the correct policy text from `business_config`
  - Within the cancellation window → warns about reduced/no refund
  - Outside the window → shows full refund message (if 100%)
- [ ] Cancelled bookings no longer show CANCEL; status badge updates to "cancelled"
- [ ] **Within cancellation window + `refund_pct=0`:** CANCEL shows error ("not permitted") — booking is NOT cancelled, no refund
- [ ] **Within cancellation window + `refund_pct>0`:** CANCEL succeeds, partial Stripe refund issued automatically
- [ ] **Outside cancellation window:** CANCEL succeeds, full Stripe refund issued

---

## Newsletter (if enabled)

- [ ] Newsletter form visible on home page
- [ ] Submission adds row to `newsletter_subscribers`
- [ ] Welcome email arrives

---

## Testimonials (if enabled)

- [ ] Master admin can add, edit, reorder, toggle visibility of testimonials
- [ ] `/testimonials` page shows active testimonials

---

## Admin — Clients (CRM, if crm module enabled)

- [ ] Master admin navigates to `/admin/clients` (Clients in sidebar)
- [ ] Client list shows unique clients with visit count, total spent, and last visit date
- [ ] Search/filter by client name works
- [ ] List is empty on a fresh install — verify it populates after test bookings are made
- [ ] Refresh button reloads the list

---

## Admin — Team

- [ ] Master admin can navigate to `/admin/staff` (Team in sidebar)
- [ ] Each staff/master profile shows avatar, name, role badge, specialties, bio
- [ ] Edit dialog saves display_name, bio, photo_url (full URL), specialties
- [ ] Updated photo_url appears as the avatar immediately after save
- [ ] Changes reflect on the public home page Team section after refresh

---

## Admin — Settings (Page Content)

- [ ] Master admin navigates to `/admin/config` → Settings
- [ ] Page Content section shows: Hero image URL, overline, tagline; Services section labels; CTA heading + button label
- [ ] Saving Page Content updates the home page hero/CTA immediately (no rebuild)
- [ ] Saving Booking Rules updates cancellation policy (reflected in cancel dialog on next load)
- [ ] Business Hours rows save individually per day; closed toggle hides time fields

---

## Gallery (if enabled)

- [ ] Master admin can add a photo by storage path, edit caption, toggle visibility
- [ ] Photos appear in the grid on `/gallery`
- [ ] Lightbox opens, swipe/nav arrows work, captions display

---

## FAQ (if enabled)

- [ ] Master admin can add, edit, reorder, toggle FAQs
- [ ] `/faq` page shows accordion

---

## Blog (if enabled)

- [ ] Master admin can create a post, slug auto-fills from title
- [ ] Published posts appear on `/blog`
- [ ] Click through to `/blog/:slug` shows full post
- [ ] Add live post slugs to `sitemap.xml` and redeploy

---

## Shop (if enabled)

- [ ] Products appear at `/shop` — public access, no login required
- [ ] Category filter chips work; "All" shows all products
- [ ] Product detail page: images, price (and strikethrough compare-at if set), description, tags
- [ ] Out-of-stock products show badge; Add to Cart button is hidden
- [ ] Cart: add items, adjust quantity, remove items — totals recalculate correctly
- [ ] Discount code: valid code applies % discount; invalid/expired code shows error
- [ ] Checkout dialog collects name + email; pre-fills if logged in
- [ ] Stripe test payment completes (card: `4242 4242 4242 4242`) → order confirmation page shows
- [ ] Cart clears after successful payment
- [ ] Admin → Orders: new order appears with status `paid`
- [ ] Admin can advance order: paid → processing → shipped → delivered
- [ ] Admin can cancel an order
- [ ] Inventory decrements after a paid order (if inventory count was set on the product)
- [ ] Discount code `used_count` increments after a paid order (check in Supabase dashboard)
- [ ] Confirmation email arrives (if `RESEND_KEY` is set)
- [ ] `STRIPE_SHOP_WEBHOOK_SECRET` is set in Supabase secrets (verify in Edge Functions → Secrets)
- [ ] Analytics dashboard shows Shop section with KPIs and revenue chart (if booking also enabled)
- [ ] **After test QA passes:** register shop webhook with live Stripe keys and update `STRIPE_SHOP_WEBHOOK_SECRET`

---

## Events (if enabled)

- [ ] `/events` page loads and shows only published events
- [ ] Draft events are NOT visible on the public page
- [ ] Event detail page loads via `/events/:slug` — hero image, date, venue, ticket types shown
- [ ] "Sold Out" badge shown when ticket type quantity is exhausted
- [ ] **Free event:** complete registration → confirmation shown in-app + confirmation email received with ticket code
- [ ] **Paid event:** Stripe Checkout opens (card `4242 4242 4242 4242`) → payment completes → `event-webhook` fires (check Stripe → Webhooks → event-webhook endpoint, status 200) → ticket status is `confirmed` in DB → confirmation email received with ticket code
- [ ] **Stripe cancel:** abandon Stripe Checkout mid-session → cancel URL fires → `pending` ticket is cancelled, slot released → user returned to event detail page
- [ ] Purchasing more tickets than available returns an error ("Sold Out" / not enough capacity)
- [ ] Admin → Events: list shows all events with correct status chips (Draft, Published, Cancelled)
- [ ] Admin: create event → slug auto-fills from title (editable)
- [ ] Admin: add multiple ticket types per event — each saves correctly with name, price, quantity
- [ ] Admin → Attendees view: stats bar shows correct totals after test purchases
- [ ] Admin: check-in toggle marks ticket as `checked_in` and shows `checked_in_at` timestamp
- [ ] Admin: cancel event → confirmation dialog → all tickets cancelled → Stripe refunds issued → refund appears in Stripe dashboard → cancellation email received by buyer
- [ ] `STRIPE_EVENTS_WEBHOOK_SECRET` is set in Supabase secrets (verify in Edge Functions → Secrets)
- [ ] `/events` URL appears in `sitemap.xml`
- [ ] Events nav item visible in public navigation when module is enabled
- [ ] **After test QA passes:** register event-webhook in live Stripe mode and update `STRIPE_EVENTS_WEBHOOK_SECRET`

---

## Staff Calendar / iCal sync *(always available — no module flag)*

- [ ] Staff member logs in and navigates to `/staff` — "Subscribe to Calendar" section is visible between the page header and the tab bar
- [ ] Feed URL is displayed in a selectable text box — format is `${SUPABASE_URL}/functions/v1/staff-calendar?token=<uuid>`
- [ ] **Copy URL** button copies the URL to the clipboard and shows a snackbar confirmation
- [ ] Visiting the feed URL in a browser returns a `.ics` file (Content-Type: `text/calendar`)
- [ ] The `.ics` file contains correct `VEVENT` entries for the staff member's confirmed and pending bookings
- [ ] **Google Calendar:** paste the feed URL via `+ → Other calendars → From URL` — bookings appear with correct title, date, time
- [ ] **Apple Calendar:** `File → New Calendar Subscription` — feed imports correctly
- [ ] **Outlook:** `Add calendar → Subscribe from web` — feed imports correctly
- [ ] Calendar entries update when new bookings are confirmed (calendar apps refresh every 12–24h; test with a manual refresh)
- [ ] Admin → `/admin/staff` — calendar icon (📅) is visible on each staff tile
- [ ] Clicking the calendar icon opens a dialog showing the staff member's current feed URL
- [ ] Admin: **Regenerate Token** generates a new UUID — old URL is confirmed broken, new URL works
- [ ] **Regenerate confirmation dialog** warns that existing subscriptions will break before proceeding
- [ ] A staff member's cancelled bookings do NOT appear in the iCal feed (only `confirmed` + `pending`)

---

## Subscriptions (if enabled)

- [ ] Subscription plans visible at `/subscriptions`
- [ ] Plans without a `stripe_price_id` show "Contact us" instead of Subscribe
- [ ] Plans with a `stripe_price_id` open Stripe Checkout on Subscribe
- [ ] Stripe test payment completes → `user_subscriptions` row created with status `active`
- [ ] Admin → Subscription Plans shows the subscriber count updated
- [ ] Subscription webhook event shows `200` in Stripe → Webhooks → subscription endpoint
- [ ] `STRIPE_SUBSCRIPTION_WEBHOOK_SECRET` is set in Supabase secrets
- [ ] **After test QA passes:** re-register subscription webhook with live Stripe keys

---

## Referrals (if enabled)

- [ ] Authenticated user has a referral code visible on their profile
- [ ] Referral link `/?ref=XXXXXXXX` loads correctly and stores the referral in the DB
- [ ] When referred user completes a paid booking, `referrals` row is marked `rewarded_at`
- [ ] Referrer and referred person both receive promo code emails (if `RESEND_KEY` is set)
- [ ] Admin → Referrals shows all referral records with rewarded/unrewarded filter

---

## Packages (if enabled)

- [ ] Admin can create service packages with included services and bundle price
- [ ] Packages visible on the booking flow (or dedicated packages page)
- [ ] Selecting a package pre-fills the service selection in the booking flow
- [ ] Package purchase records correctly in the DB

---

## Intake Forms (if `INTAKE_ENABLED=true`)

- [ ] After booking confirmation, client receives an intake form link or prompt
- [ ] Intake form submission stored against the booking in the DB
- [ ] Admin can view intake form responses per booking

---

## Loyalty Points (if `LOYALTY_ENABLED=true`)

- [ ] Points awarded to client after a completed booking appears in `loyalty_ledger`
- [ ] Client can see their loyalty balance on `/profile`
- [ ] Admin can view loyalty balance per client

---

## Waitlist (if `WAITLIST_ENABLED=true`)

- [ ] When all slots are fully booked, a "Join Waitlist" option appears
- [ ] Waitlist signup stores a row in the `waitlist` table
- [ ] When a booking is cancelled, waitlisted clients receive an email notification
- [ ] `notified_at` is set on the waitlist row after email is sent

---

## Reviews (if `REVIEWS_ENABLED=true`)

- [ ] After an appointment is marked `completed`, `review_request_sent` is NOT yet true
- [ ] `send-review-requests` cron (or manual trigger) fires ~2h later and sends the email
- [ ] `review_request_sent = true` set on the booking row after email fires
- [ ] Review request email contains a working link (not a placeholder URL)

---

## Client Photos (if `CLIENT_PHOTOS_ENABLED=true`)

- [ ] Staff can upload before/after photos against a booking
- [ ] Photos stored in a private Storage bucket (not publicly accessible by URL)
- [ ] Admin can view photos per booking
- [ ] Non-staff/non-admin cannot access the photo URLs

---

## Recurring Bookings (if `RECURRING_ENABLED=true`)

- [ ] When completing a booking, option to make it recurring is offered
- [ ] Recurring bookings generate future `pending` rows at the correct interval
- [ ] `send-recurring-payment-reminders` cron sends payment links for upcoming recurring bookings
- [ ] Client pays via the link → booking status updates to `confirmed`
- [ ] Admin can view and manage recurring booking series

---

## Analytics

- [ ] Analytics are receiving hits (check dashboard after a few test page loads)
- [ ] Search Console property verified and sitemap submitted

---

## GDPR (if enabled)

- [ ] Cookie banner appears on first visit at bottom of screen
- [ ] "Accept" and "Decline" both dismiss the banner for the session
- [ ] Banner re-appears on next fresh load

---

## Legal

- [ ] Privacy Policy is live and linked in the site footer
- [ ] Terms of Service is live and linked (if booking / payments enabled)
- [ ] Privacy Policy URL is correct and not a placeholder
- [ ] Cookie policy referenced in the GDPR banner (if GDPR enabled)

---

## Performance (first load)

- [ ] First load on a throttled connection (DevTools → Network → Slow 3G) is acceptable
  — Flutter web typically takes 3–8 seconds on slow connections; inform the client
- [ ] Uptime monitor is active and confirmed receiving pings (check UptimeRobot dashboard)
- [ ] Sentry receiving events (if configured — trigger a test error or check the issues tab)
