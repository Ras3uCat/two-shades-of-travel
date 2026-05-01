# Section 17 — Events Module

The Events module lets clients host ticketed events: workshops, masterclasses, pop-ups, launches,
and classes. Customers browse a public `/events` page, pick a ticket type, and purchase via Stripe
Checkout (or register instantly for free events).

**This module is separate from the `booking` module.** Bookings are 1-on-1 appointments with a
staff member. Events are fixed-date, capacity-limited, and open to any number of attendees.

---

## 17.1 — Enable the module

In `client.json`:

```json
{
  "MODULES": "...,events",
  "STRIPE_EVENTS_WEBHOOK_SECRET": "whsec_..."
}
```

> `STRIPE_EVENTS_WEBHOOK_SECRET` is filled in after Step 5 below (register the webhook endpoint
> once the site is live). Leave it empty initially and fill it in before going live.

---

## 17.2 — What `deliver.sh` does

When `events` is in `MODULES`, `deliver.sh` automatically:

- Runs `087_events.sql` (creates `events`, `event_ticket_types`, `event_tickets` tables +
  `purchase_event_tickets()`, `get_ticket_availability()`, `cancel_event_tickets()` functions + RLS)
- Deploys three Edge Functions: `create-event-checkout`, `event-webhook`, `cancel-event`
- Pushes `STRIPE_EVENTS_WEBHOOK_SECRET` to Supabase secrets (once you set it in `client.json`)
- Adds `/events` to `sitemap.xml`

Manual steps you still do:

- Register the Stripe webhook endpoint (see §17.5)
- Create events and ticket types in the admin panel

---

## 17.3 — Stripe webhook setup

After the site is live on the real domain:

1. Stripe dashboard → **Developers → Webhooks** → **Add endpoint**
2. Endpoint URL: `https://YOUR_PROJECT_REF.supabase.co/functions/v1/event-webhook`
3. Events to listen for: `checkout.session.completed`
4. Click **Add endpoint**
5. Copy the **Signing secret** (`whsec_...`)
6. Set in `client.json`: `"STRIPE_EVENTS_WEBHOOK_SECRET": "whsec_..."`
7. Re-run `deliver.sh` to push the secret:
   ```bash
   ./deliver.sh --skip-db --skip-build
   ```

> This is a **third separate webhook** from `stripe-webhook` (bookings) and `shop-webhook` (shop).
> Each has its own signing secret. Do not share secrets between webhooks.

**Switching to live Stripe keys:**
Same process as bookings (§6.2) — register a new webhook in live mode, update
`STRIPE_EVENTS_WEBHOOK_SECRET` with the live signing secret.

---

## 17.4 — Creating events (admin)

1. Log in as master → Admin → **Events**
2. Click **Add Event**
3. Fill in:
   - **Title** — auto-fills the slug (editable)
   - **Date & Time** — event start time in local time
   - **Venue** — physical location or "Online"
   - **Capacity** — total seats across all ticket types
   - **Description** — shown on the event detail page
   - **Hero Image URL** — hosted image, shown at top of event page
   - **Status** — start as `Draft`; set to `Published` when ready to sell

> Events in `Draft` status are not visible on the public `/events` page.
> Set to `Published` only once ticket types are configured and the Stripe webhook is live.

---

## 17.5 — Adding ticket types

From the event edit dialog, click **Add Ticket Type**:

- **Name** — e.g. "General Admission", "VIP", "Early Bird"
- **Description** — optional, shown under the ticket name on the detail page
- **Price** — in the display currency. Enter `0` for free events (no Stripe charge)
- **Quantity** — how many tickets of this type are available

You can add multiple ticket types per event. The customer selects one type and a quantity.

> **Important:** The sum of all ticket type quantities should equal the event `capacity`.
> The system enforces capacity per ticket type only — it does not prevent you from setting
> type totals that exceed the event capacity field.

---

## 17.6 — Free events

If all ticket types have `price = 0`:

- No Stripe account is required for the event flow
- Purchase completes immediately (no checkout redirect)
- Confirmation shown in-app + confirmation email sent via Resend
- `STRIPE_EVENTS_WEBHOOK_SECRET` is not needed (but can be set for future paid events)

---

## 17.7 — Managing attendees & check-in

Admin → Events → **Attendees** button on any event:

- **Stats bar:** total sold, confirmed, checked in, total revenue
- **Attendee list:** buyer name, email, ticket type, quantity, ticket code, status
- **Check In:** toggle to mark a ticket as checked in (updates `checked_in_at` in the DB)

The ticket code is a UUID. Customers receive it in their confirmation email. You can manually
type or paste the code to look up and check in an attendee. A QR scanner integration is a v1.1
addition — for now, check-in is manual via the admin table.

---

## 17.8 — Cancelling an event

Admin → Events → **Cancel** button on the event row:

1. A confirmation dialog warns that all paid tickets will be refunded
2. Confirm → all tickets are marked `cancelled`, Stripe refunds issued automatically
3. Cancellation emails sent to all unique buyers

> **Limitation:** The refund loop runs synchronously. For events with more than ~100 paid
> attendees, the Edge Function may approach the 60-second timeout. If you expect large events,
> contact support to implement a queued refund approach before going live.

---

## 17.9 — Ticket purchase flow (customer-facing)

1. Customer visits `/events` — sees list of published events with dates, prices, and availability
2. Clicks an event → event detail page with hero image, description, ticket type selector
3. Selects ticket type and quantity → clicks "Buy Tickets" or "Register Free"
4. **Paid:** redirected to Stripe Checkout → completes payment → lands on `/events/confirmation`
   with a "check your email for your ticket code" message
5. **Free:** confirmation shown immediately with ticket code
6. Confirmation email sent in both cases with: event title, date/venue, quantity, ticket code

> If the customer abandons Stripe Checkout mid-session and the cancel redirect fires,
> the reserved ticket slots are released immediately. Stale `pending` tickets from sessions
> that close without completing the cancel redirect must be cleared manually in the
> Attendees view (mark as Cancelled).

---

## 17.10 — Known limitations (v1)

| Limitation | Workaround / Timeline |
|------------|----------------------|
| No automatic expiry of abandoned `pending` tickets | Admin clears manually. Auto-expiry cron in v1.1 |
| Capacity enforced per ticket type, not aggregate | Set ticket type totals to sum to event capacity |
| No waitlist | Shows "Sold Out" badge. Waitlist in v1.1 |
| No recurring / series events | Create individual events for each date |
| No QR code scanner | Check in manually via the admin attendees table |
| No home page preview strip | Deferred to v1.1 |
| Refund loop may timeout for 100+ paid attendees | Contact Raspucat before deploying large events |

---

## 17.11 — Post-live checklist

- [ ] `087_events.sql` ran cleanly (check Supabase → Database → Tables for `events`, `event_ticket_types`, `event_tickets`)
- [ ] Three edge functions deployed: `create-event-checkout`, `event-webhook`, `cancel-event`
- [ ] Stripe `event-webhook` endpoint registered, `STRIPE_EVENTS_WEBHOOK_SECRET` set in Supabase secrets
- [ ] At least one test event created in Draft status
- [ ] Ticket type(s) added to test event
- [ ] Event published — visible at `/events`
- [ ] Free ticket test: complete purchase, confirmation email received with ticket code
- [ ] Paid ticket test (card `4242 4242 4242 4242`): Stripe Checkout opens → payment completes → `event-webhook` fires (check Stripe → Webhooks) → ticket status `confirmed` in DB → confirmation email received
- [ ] Stripe cancel test: start checkout, close the tab or click "Go back" → ticket slot released
- [ ] Admin → Events → Attendees: ticket appears with correct status
- [ ] Check-in toggle updates `checked_in_at` in the DB
- [ ] Cancel event test: confirmation dialog → all tickets cancelled, refund appears in Stripe → DB tickets show `cancelled`
- [ ] Sold-out test: set quantity to 1, buy it, reload page — "Sold Out" badge shows
- [ ] `/events` appears in `sitemap.xml`
- [ ] After QA: switch to live Stripe keys and re-register event-webhook in live mode
