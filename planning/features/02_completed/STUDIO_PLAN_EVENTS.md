# STUDIO PLAN — Events Module
**Created:** 2026-03-10 | **Mode:** STUDIO | **Status:** PENDING APPROVAL

---

## Overview

Add an **Events module** to the platform. Covers ticketed one-off events: workshops, masterclasses,
pop-ups, classes, launches. Different from the `booking` module (which is 1-on-1 appointments).
Different from `subscriptions` (which is recurring billing). Events are fixed-date, capacity-limited,
multi-ticket-type, Stripe-paid (or free).

**Flag:** `events` added to `MODULES` in `client.json`
**Migration:** `087_events.sql`
**Edge functions:** `create-event-checkout`, `event-webhook`, `cancel-event`
**Delivery guide:** `17_events.md`

---

## Approved Decisions

| # | Decision | Choice |
|---|----------|--------|
| 1 | Capacity enforcement | Per ticket type (`quantity_total` on each type). Event-level `capacity` field is display-only. Admin must ensure type totals sum to event capacity. |
| 2 | Pending ticket expiry | Out of scope v1. Admin clears stale pending tickets manually from the attendees view. Documented as known limitation. Add `expire-pending-event-tickets` cron in v1.1. |
| 3 | Ticket code format | UUID (`gen_random_uuid()`). Flutter UI shows first 8 chars uppercased for human readability. Full UUID stored in DB for check-in. |
| 4 | Admin route registration | Inside `AdminModule` — same pattern as shop. Modify `admin_module.dart` + `admin_shell.dart`. |
| 5 | Refund approach | Synchronous inside `cancel-event` Edge Function. Document 100-attendee limit in delivery guide. |
| 6 | Stripe webhook | Separate `event-webhook` endpoint with own `STRIPE_EVENTS_WEBHOOK_SECRET`. Mirrors shop pattern. |
| 7 | Home page integration | v1: Events appears in nav only (`/events` route). No home page preview section in v1. Deferred to v1.1 as `EventsPreviewSection`. |

---

## Implementation Checklist

### Phase A — Backend (SQL + Edge Functions)

- [ ] **`087_events.sql`** — Create 3 tables + 3 Postgres functions + RLS policies
  - Tables: `events`, `event_ticket_types`, `event_tickets`
  - Functions: `purchase_event_tickets()` (row-locked, SECURITY DEFINER, service_role only), `get_ticket_availability()`, `cancel_event_tickets()`
  - RLS: public read published events + ticket types, service_role-only purchase function, master all, anonymous INSERT on event_tickets (for guest purchase)

- [ ] **`create-event-checkout/index.ts`**
  - POST: validates event_id, ticket_type_id, quantity, buyer_email, buyer_name
  - Calls `purchase_event_tickets()` RPC via service role
  - Free (price = 0): immediately confirmed, sends email, returns `{ confirmed, ticket_id, ticket_code }`
  - Paid: creates Stripe Checkout session, stores `stripe_session_id`, returns `{ url }`
  - `success_url = ${SITE_URL}/events/confirmation?ticket_id=<id>&paid=1`
  - `cancel_url = ${SITE_URL}/events/<slug>?cancelled_ticket_id=<id>`
  - ~160 lines

- [ ] **`event-webhook/index.ts`**
  - Verifies signature with `STRIPE_EVENTS_WEBHOOK_SECRET`
  - Handles `checkout.session.completed` where `metadata.type === 'event_ticket'`
  - Updates ticket: `status = 'confirmed'`, stores `stripe_payment_intent`
  - Sends confirmation email with ticket code, event title/date/venue, quantity
  - ~130 lines

- [ ] **`cancel-event/index.ts`**
  - POST: verifies master JWT, validates event_id
  - Updates event `status = 'cancelled'`
  - Calls `cancel_event_tickets()` RPC → returns paid ticket payment intents
  - Issues Stripe refunds for each paid ticket, stores `stripe_refund_id`
  - Optionally emails unique buyers (deduped by email)
  - ~150 lines

### Phase B — Flutter Models + Repository

- [ ] **`event_model.dart`** — EventModel with fromJson, computed getters
- [ ] **`event_ticket_type_model.dart`** — priceCents, isFree, formattedPrice
- [ ] **`event_ticket_model.dart`** — ticketCode, isConfirmed, isCheckedIn
- [ ] **`events_repository.dart`** — abstract interface (public + admin methods)
- [ ] **`supabase_events_repository.dart`** — Supabase implementation, ~200 lines

### Phase C — Flutter Controllers + Binding

- [ ] **`events_controller.dart`** — public flow: list, detail, ticket purchase, cancel-return handling, ~170 lines
- [ ] **`events_admin_controller.dart`** — admin: CRUD events + ticket types, attendees, check-in, cancel event, ~200 lines
- [ ] **`events_binding.dart`** + **`events_admin_binding.dart`**

### Phase D — Flutter Public Views

- [ ] **`events_list_view.dart`** — event cards with date, price range, sold-out badge
- [ ] **`event_detail_view.dart`** — hero, description, ticket selector (type dropdown + qty stepper), purchase button, ~250 lines
- [ ] **`event_confirmation_view.dart`** — in-app (free) and post-Stripe (paid) paths

### Phase E — Flutter Admin Views

- [ ] **`admin_events_list_view.dart`** — list + create/edit dialog with slug auto-fill, status management, ~200 lines
- [ ] **`admin_event_ticket_types_section.dart`** — ticket type CRUD within event edit, ~180 lines
- [ ] **`admin_event_attendees_view.dart`** — stats bar, attendee table, check-in toggle, ~220 lines

### Phase F — Module Registration + Wiring

- [ ] **`events_module.dart`** — AppModule with navItem, 3 routes
- [ ] **`app_router.dart`** — add 5 route constants (`events`, `eventsDetail`, `eventsConfirmation`, `adminEvents`, `adminEventAttendees`)
- [ ] **`admin_module.dart`** — register 2 admin event GetPages with EventsAdminBinding
- [ ] **`admin_shell.dart`** — add Events nav item (gated by `AppEnv.moduleEnabled('events')`)
- [ ] **`main.dart`** — register `EventsModule()` in allModules list

### Phase G — Delivery Pipeline

- [ ] **`setup.sh`** — add `run_if_enabled "events" "087_events.sql"`
- [ ] **`deliver.sh`** — add events edge function deploy block + webhook reminder in output + `STRIPE_EVENTS_WEBHOOK_SECRET` secrets push
- [ ] **`prepare.sh`** — add `/events` to sitemap generation
- [ ] **`client.json.example`** — add `STRIPE_EVENTS_WEBHOOK_SECRET: ""`

### Phase H — Docs + QA

- [ ] **`17_events.md`** — full delivery guide (see outline in plan)
- [ ] **`00_CLIENT_DELIVERY_GUIDE.md`** — add `17_events.md` to appendix table
- [ ] **`01_discovery.md`** — add events discovery questions
- [ ] **`03_client-json.md`** — add `STRIPE_EVENTS_WEBHOOK_SECRET` to field index
- [ ] **`04_pipeline.md`** — add `087_events.sql` row + 3 edge functions to the deployment table
- [ ] **`05_supabase.md`** — add `STRIPE_EVENTS_WEBHOOK_SECRET` to secrets tables
- [ ] **`12_qa-checklist.md`** — add Events QA section

---

## File Inventory

| File | Type | Lines est. |
|------|------|-----------|
| `migrations/087_events.sql` | SQL | 180 |
| `functions/create-event-checkout/index.ts` | Edge Fn | 160 |
| `functions/event-webhook/index.ts` | Edge Fn | 130 |
| `functions/cancel-event/index.ts` | Edge Fn | 150 |
| `lib/modules/events/models/event_model.dart` | Flutter | 80 |
| `lib/modules/events/models/event_ticket_type_model.dart` | Flutter | 60 |
| `lib/modules/events/models/event_ticket_model.dart` | Flutter | 70 |
| `lib/modules/events/repositories/events_repository.dart` | Flutter | 60 |
| `lib/modules/events/repositories/supabase_events_repository.dart` | Flutter | 200 |
| `lib/modules/events/controllers/events_controller.dart` | Flutter | 170 |
| `lib/modules/events/controllers/events_admin_controller.dart` | Flutter | 200 |
| `lib/modules/events/bindings/events_binding.dart` | Flutter | 20 |
| `lib/modules/events/bindings/events_admin_binding.dart` | Flutter | 20 |
| `lib/modules/events/views/events_list_view.dart` | Flutter | 130 |
| `lib/modules/events/views/event_detail_view.dart` | Flutter | 250 |
| `lib/modules/events/views/event_confirmation_view.dart` | Flutter | 120 |
| `lib/modules/events/views/admin/admin_events_list_view.dart` | Flutter | 200 |
| `lib/modules/events/views/admin/admin_event_ticket_types_section.dart` | Flutter | 180 |
| `lib/modules/events/views/admin/admin_event_attendees_view.dart` | Flutter | 220 |
| `lib/modules/events/events_module.dart` | Flutter | 55 |
| **Files to modify** | | |
| `lib/core/router/app_router.dart` | Flutter | +5 lines |
| `lib/modules/admin/admin_module.dart` | Flutter | +15 lines |
| `lib/modules/admin/views/admin_shell.dart` | Flutter | +4 lines |
| `lib/main.dart` | Flutter | +1 line |
| `execution/frontend/app/deliver.sh` | Shell | +20 lines |
| `execution/frontend/app/setup.sh` | Shell | +1 line |
| `execution/frontend/app/prepare.sh` | Shell | +4 lines |
| `execution/frontend/app/client.json.example` | JSON | +1 field |
| **Total new files:** 20 | **Total modified:** 8 | **~2,455 new lines** |

---

## Known Limitations (v1)

- No pending ticket auto-expiry (stale pending tickets must be manually cleared by admin)
- Capacity enforced per ticket type only, not aggregate event-level
- No waitlist (shows "Sold Out" badge)
- No recurring/series events
- No ticket transfer or resale
- `cancel-event` refund loop may time out for events with 100+ paid attendees (documented in 17_events.md)
- No home page preview section (deferred to v1.1)

---

## v1.1 Follow-ons (out of scope now)

- `expire-pending-event-tickets` cron function
- `EventsPreviewSection` home page widget (3 upcoming events strip)
- Human-readable ticket code format option
- Events waitlist
- Series/recurring events
- QR code generation (encode `ticket_code` UUID as QR image in email or in-app)
