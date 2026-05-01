# Phase 11 + Phase 13 — Post-Deploy Setup & Client Handover

---

## Phase 11 — Create Master User

The owner account must be created after the site is live, because they must sign up through the
deployed app first.

1. Direct the owner to `https://yourclientdomain.com/auth`
2. They sign up with their business email
3. They confirm via the Supabase confirmation email (now correctly branded and pointing to the live domain)
4. Run in `Project → SQL Editor`:

```sql
UPDATE profiles SET role = 'master' WHERE email = 'owner@clientdomain.com';
```

5. Owner signs out and signs back in — the JWT hook injects `user_role: master`
6. They now have full access to the Admin panel

> Staff accounts follow the same flow. Sign up → set `role = 'staff'` → sign in again.
> Staff must sign out and back in after the role is set to get a refreshed JWT.

### Security: Enable 2FA on the Supabase Account

The Supabase project dashboard controls the database, secrets, RLS policies, and edge functions
for this client. Compromising it means compromising all client data.

**Strongly recommend to the client (and yourself):**

1. Go to [supabase.com](https://supabase.com) → Account → Security
2. Enable **Two-Factor Authentication** (TOTP app such as Authy or Google Authenticator)
3. Ensure the client's email account (used to sign in to Supabase) also has 2FA enabled

This applies to:
- Your Raspucat Supabase account (if you manage the project)
- The client's account if they are added as a team member to the project

---

## Phase 13 — Client Handover

### 13.0 — Pre-handover: clean up test data

Before inviting the client to log in, delete all QA artifacts from the database. Finding
`test@test.com` bookings or "lorem ipsum" blog posts in their admin is unprofessional.

Run in the Supabase SQL editor:

```sql
-- Remove test bookings
DELETE FROM bookings WHERE client_email ILIKE '%test%' OR client_email ILIKE '%example%';

-- Remove test testimonials (if module enabled)
DELETE FROM testimonials WHERE author_name ILIKE '%test%' OR content ILIKE '%lorem%';

-- Remove test blog posts (if module enabled)
DELETE FROM blog_posts WHERE title ILIKE '%test%' OR slug ILIKE '%test%';

-- Remove test gallery photos (if module enabled)
DELETE FROM gallery_photos WHERE caption ILIKE '%test%';

-- Remove test FAQ entries (if module enabled)
DELETE FROM faqs WHERE question ILIKE '%test%';

-- Remove test newsletter subscribers
DELETE FROM newsletter_subscribers WHERE email ILIKE '%test%' OR email ILIKE '%example%';

-- Remove test shop orders (if shop module enabled)
DELETE FROM shop_order_items WHERE order_id IN (
  SELECT id FROM shop_orders WHERE client_email ILIKE '%test%' OR client_email ILIKE '%example%'
);
DELETE FROM shop_orders WHERE client_email ILIKE '%test%' OR client_email ILIKE '%example%';
```

Also check:
- [ ] Supabase Auth → Users: delete any `test@...` or `example@...` accounts used during QA
- [ ] Stripe: refund and delete any test payment intents if live mode was tested early
- [ ] Admin panel: confirm the bookings list, staff list, and services list look clean

---

### 13.1 — What to give the client

1. **Site URL** — live domain
2. **Admin login** — confirm they can sign in and access the admin panel
3. **Supabase dashboard access** — invite them as `viewer`:
   `Project Settings → Team → Invite member`
4. **Analytics access** — add them to GA4 / Plausible / Search Console as a user
5. **Uptime monitor** — show them the UptimeRobot dashboard (or set up email alerts to their address too)
6. **Resend domain confirmed** — show them the green verified status
7. **Stripe dashboard** — confirm they have access to their own Stripe account
8. **Privacy Policy / Terms** — confirm the pages are live and they own the content

### 13.2 — What NOT to give them

- `client.json` (contains keys — not user-facing)
- Supabase service role key
- Stripe secret key
- Resend API key

These stay in Supabase secrets and are never exposed.

---

### 13.3 — What to document for them (1-page handover note)

- Live URL
- Admin login URL: `https://yourclientdomain.com/auth`
- How to add/edit content (testimonials, FAQs, gallery, blog posts)
- How to manage bookings and staff (if booking enabled)
- **Clients** (`/admin/clients`): view all unique clients with visit history, total spend, and last visit date
- **Settings → Page Content** (`/admin/config`): update hero image, tagline, overline, CTA text, and section labels — no rebuild needed
- **Settings → Booking Rules** (`/admin/config`): update cancellation window and refund % — affects the cancel dialog shown to users AND the automatic Stripe refund amount
- **Team** (`/admin/staff`): update staff display names, bios, photos, and specialties — reflects live on the home page
- Cancelling a booking from the admin panel automatically issues the Stripe refund and emails the client
- Customers with accounts can view/cancel their own bookings at `/profile`
- **Shop** (`/admin/shop/products` and `/admin/shop/orders`): add/edit/deactivate products, manage categories, create discount codes, view and fulfil orders (advance status: paid → processing → shipped → delivered)
- Where to view analytics
- Privacy Policy and Terms URLs (their responsibility to keep updated)
- Who to contact for changes: you (Raspucat)
- What triggers a rebuild (see below)

---

### 13.4 — Ongoing updates: rebuild vs. no rebuild

**Requires a rebuild + redeploy (you do this):**
- Brand changes (colours, fonts, personality, hero style)
- Adding or removing modules
- Domain changes
- SEO content changes (title, description, structured data)
- Analytics script changes

**No rebuild needed (client does this in the admin panel):**
- Adding/editing testimonials, FAQs, gallery photos, blog posts
- Adding/editing shop products, categories, and discount codes; fulfilling and managing orders
- Updating business hours (Settings → Business Hours in admin panel)
- Managing bookings, staff, services, promo codes
- Editing page content: hero image/overline/tagline, services section labels, CTA text (Settings → Page Content)
- Editing staff profiles: display name, bio, photo, specialties (Team section)
- Updating cancellation policy: window hours and refund % (Settings → Booking Rules)
- Adding a service image URL (Services section)
- Viewing and responding to contact form submissions (via Supabase dashboard)

**No rebuild needed (you do this in Supabase dashboard):**
- Rotating secrets / API keys
- Updating Stripe keys (test → live)
- Adjusting RLS or DB records directly

---

### 13.5 — Client operational runbook

Include this section in the handover document so the client knows what to do when things go
wrong — before they call you.

**"A customer says their confirmation email never arrived"**
1. Ask them to check spam / promotions folder
2. Check Resend dashboard → Logs — search by their email address
3. If the email shows as delivered, the issue is their inbox filter
4. If the email shows as failed/bounced, check the error — likely a typo in their email address at booking time; the admin can see the booking in the admin panel

**"A customer wants a refund"**
1. Find the booking in Admin → Bookings
2. Click **CANCEL** on the booking — the cancellation Edge Function handles everything automatically:
   - Issues the Stripe refund (full refund if cancellation is outside the policy window; partial or no refund if within the window per the configured `cancellation_refund_pct`)
   - Sends the client a cancellation email
   - Updates the booking status to `cancelled`
3. Confirm in Stripe dashboard → Payments that the refund appears (usually within seconds)
4. If the Stripe refund must be overridden (e.g. good-will full refund despite a no-refund policy), log into Stripe directly → Payments → find the charge → Issue refund manually, then cancel the booking from the admin panel
5. Contact Raspucat if something goes wrong or the refund is disputed

**"The site is down"**
1. Check UptimeRobot — it will have emailed you the moment it went down
2. Check if it's a Supabase pause: go to the Supabase dashboard → if the project shows "Paused", click **Restore project** (free tier pauses after 7 days of inactivity)
3. If it's a hosting issue (Cloudflare/Vercel/Netlify), check their status page
4. Contact Raspucat if the issue persists beyond 30 minutes

**"I want to change something on the site"**
- Refer to the rebuild vs. no-rebuild list above
- If it requires a rebuild, contact Raspucat with the specific change requested

---

### 13.6 — Setting SEO expectations

Tell the client this during handover to avoid a support call in week 2:

> "Your site is now live and correctly set up for search engines. However, Google typically takes
> **4–12 weeks** to index and rank a new domain. During that time, impressions and clicks in Search
> Console will be near zero — this is completely normal. We've submitted your sitemap and set up
> structured data, which gives you the best possible start. Rankings build over time as Google
> crawls the site and as you add content (blog posts, testimonials, etc.)."

---

### 13.8 — Handover email template

Send this to the client once QA is complete and test data is cleared.
Customise the bracketed sections for each client.

---

**Subject:** Your [Business Name] app is live 🎉

Hi [Client Name],

Your site is live at [https://yourclientdomain.com].

Here's everything you need to get started:

**Your admin panel**
Log in at: [https://yourclientdomain.com/auth]
Use the email address you signed up with during testing.

**What you can manage yourself (no technical help needed):**
- Add and edit testimonials, FAQs, gallery photos, and blog posts from the admin panel
- Update your hero image, tagline, and CTA text under Settings → Page Content
- Manage bookings, staff availability, and services
- View all client bookings and revenue under Bookings
- [If shop enabled] Add/edit products, manage orders, and create discount codes under Shop
- Update business hours under Settings → Business Hours

**What requires a rebuild (contact me):**
- Brand changes (colours, fonts)
- Adding new features or pages
- Domain changes
- SEO title or description changes

**SEO note:** Google typically takes 4–12 weeks to index and rank a new site. Your sitemap has
been submitted to Search Console — this is normal, not a problem.

**If something breaks:**
- First, check your spam folder for any missed confirmation emails
- Check the uptime monitor at [UptimeRobot dashboard URL]
- Contact me at [your email] — I aim to respond within [your SLA]

I've attached a one-page quick-reference guide for day-to-day admin tasks.

Let me know if you have any questions — happy to do a quick walkthrough call.

[Your name / Raspucat]

---

> **Tip:** Attach the one-page summary from §13.3 as a PDF or plain text file.
> Keep the email itself short — the attachment covers the details.

---

### 13.7 — Supabase backup strategy

Tell the client which plan they're on and what it means for their data:

| Plan | Backups | Recommendation |
|------|---------|---------------|
| **Free** | No automated backups | Acceptable for new sites. Export data manually monthly via `Project → Database → Backups` (manual snapshots only). Upgrade before the site gets real revenue. |
| **Pro ($25/mo)** | Daily automated backups, 7-day retention | Recommended for any site taking real bookings/payments |
| **Pro + PITR add-on** | Point-in-time recovery | Only needed for high-volume booking sites |

For free tier clients, set a monthly reminder to export a database snapshot:
```bash
supabase db dump --linked > backup_$(date +%Y%m%d).sql
```
