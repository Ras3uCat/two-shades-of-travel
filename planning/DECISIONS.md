# Decision Log (ADR) — Raspucat Modular Client Delivery Platform
**Purpose:** Document the "Why" behind architectural choices.
Agents must check this file before proposing alternatives.

---

## [ADR-001] Per-Client Supabase Project Isolation
- **Date:** 2026-02-27
- **Status:** Approved
- **Context:** Need to deliver apps to multiple clients. Options were multi-tenant
  (shared DB with RLS) or per-client isolated projects.
- **Decision:** Every client gets their own Supabase project.
- **Rationale:** Full data isolation, no cross-client RLS risk, easier to hand off
  to client, simpler to reason about. Multi-tenant adds complexity that isn't
  justified at this scale.
- **Consequences:** Each delivery requires a new Supabase project. `setup.sh` must
  run migrations against the linked project. Never share Supabase credentials
  across clients.

---

## [ADR-002] `client.json` + `dart-define-from-file` for Configuration
- **Date:** 2026-02-27
- **Status:** Approved
- **Context:** Needed a way to inject per-client brand values, module toggles,
  and credentials without modifying Dart source files.
- **Decision:** Use `client.json` with `flutter build --dart-define-from-file=client.json`.
  All brand values, enabled modules, and credentials live in this one file.
- **Rationale:** Available in Flutter 3.7+. No code changes required between clients.
  JSON is readable without Dart knowledge. Gitignore `client.json` (contains secrets).
  Commit `client.json.example` as the template.
- **Consequences:** `client.json` must never be committed to source control.
  `app_env.dart` is the single Dart file that reads all `String.fromEnvironment()`
  values. All other files consume `AppEnv.*` — never call `fromEnvironment` elsewhere.

---

## [ADR-003] Personality System as Full Visual Language
- **Date:** 2026-02-27
- **Status:** Approved
- **Context:** Sites must feel genuinely unique per client, not just color swaps.
- **Decision:** Five personalities (`luxury`, `minimal`, `bold`, `warm`, `corporate`),
  each defining layout structure, typography scale/weight, border radius system,
  animation duration/easing, divider style, and nav behavior — not just colors.
- **Rationale:** Two clients with different colors on the same layout still look
  like the same site. Different layouts, type systems, and motion languages make
  sites feel genuinely different. See `STUDIO_PLAN.md` for full per-personality spec.
- **Consequences:** `PersonalityTheme.fromEnv()` must be the single source for all
  layout/motion/shape constants. No hardcoded radius, duration, or spacing values
  in widgets — always consume `PersonalityTheme`. `ThemeFactory.fromEnv()` assembles
  the full Material 3 `ThemeData`.

---

## [ADR-004] Adopt template_1 Booking Widget
- **Date:** 2026-02-27
- **Status:** Approved
- **Context:** template_1 has a fully built, 4-step booking flow with GetX +
  Repository pattern. Reproducing it would be wasteful.
- **Decision:** Copy the booking module from
  `dev/template_1/execution/frontend/app/lib/features/booking/` into the new
  project. Keep all models, controllers, widgets, and the abstract repository
  interface unchanged. Replace only `MockBookingRepository` with
  `SupabaseBookingRepository`.
- **Rationale:** The flow (Path A/B artist selection, 20-min slot intervals,
  7-day lookahead, multi-select services) is production-quality. The repository
  abstraction makes swapping the data layer clean with zero changes to controllers
  or widgets.
- **Consequences:** Do not modify `BookingController` or any widget to accommodate
  Supabase — that logic belongs in `SupabaseBookingRepository`. Any new booking
  behavior (buffer time, business hours, cancellation) goes in the repository
  implementation or a new Edge Function.

---

## [ADR-005] Stripe Standard vs. Connect (Config Flag)
- **Date:** 2026-02-27
- **Status:** Approved
- **Context:** Some clients are solo operators (one Stripe account). Others are
  multi-staff businesses (e.g., salons where each barber needs their own payout).
- **Decision:** `client.json` `STRIPE_MODE` field: `standard` or `connect_multi_staff`.
  `StripeService` switches implementation based on this value. Both paths call the
  `create-checkout` Supabase Edge Function — the secret key never leaves the server.
- **Rationale:** Standard is simpler and covers most clients. Connect is needed for
  multi-staff payout routing (not for platform fees — Raspucat takes no cut).
  The switch at the service layer means zero other code changes between modes.
- **Consequences:** `StripeService` is the only file that branches on `STRIPE_MODE`.
  For Connect clients, `staff_profiles.stripe_express_account_id` must be populated
  before any booking can be paid. The `connect-stripe-onboard` Edge Function handles
  Express account creation and onboarding link generation.

---

## [ADR-006] Booking Conflict Resolution via PostgreSQL Row Lock
- **Date:** 2026-02-27
- **Status:** Approved
- **Context:** Concurrent booking attempts for the same staff member + time slot
  can cause double-bookings if resolved at the application layer.
- **Decision:** A `book_appointment()` PostgreSQL function uses `SELECT ... FOR UPDATE`
  to lock the relevant availability row atomically before inserting a booking.
- **Rationale:** Application-level checks (Flutter or even Edge Function checks)
  have a race condition window. DB-level row locking is the only safe solution.
- **Consequences:** All booking creation must go through the `book_appointment()`
  Postgres function. Never insert directly into `bookings` from Flutter or an
  Edge Function without using this function.

---

## [ADR-007] Staff Promo Codes Validated Server-Side
- **Date:** 2026-02-27
- **Status:** Approved
- **Context:** Promo codes are scoped to a specific staff member — they only apply
  when booking that staff member. This must not be enforceable client-side.
- **Decision:** Promo code validation (code exists, not expired, uses remaining,
  `owner_id` matches booking `staff_id`) happens inside the `create-checkout`
  Edge Function before the Stripe session is created.
- **Rationale:** Client-side validation can be bypassed. Stripe discount application
  happens server-side anyway, so this is the natural enforcement point.
- **Consequences:** Flutter only submits the promo code string. The Edge Function
  is the single source of truth for whether a discount applies.

---

## [ADR-008] HTML Renderer + Path Routing for Flutter Web
- **Date:** 2026-02-27
- **Status:** Approved
- **Context:** Client sites are service business websites. They must be indexable
  by Google. Flutter's default CanvasKit renderer produces no crawlable DOM.
- **Decision:** Use HTML renderer (`--web-renderer html`) and path-based URL routing
  (`url_strategy: path`). Add `LocalBusiness` JSON-LD structured data to `index.html`.
  Per-route meta tags via `SeoWrapper` widget.
- **Rationale:** HTML renderer produces actual DOM elements that crawlers can index.
  Path-based routing gives clean URLs (e.g., `/booking`, `/about`) that can rank.
  JSON-LD structured data enables Google rich results for local businesses.
- **Consequences:** Always build with `--web-renderer html`. Never switch to CanvasKit
  for client sites. Some complex animations may need simplification to perform well
  in HTML renderer — prefer CSS transforms over Flutter canvas operations where possible.

---

## [ADR-009] Admin Roles: master / staff (No Numeric Roles)
- **Date:** 2026-02-27
- **Status:** Approved
- **Context:** Need role-based access for business owner vs. individual staff members.
- **Decision:** Two roles: `master` (full access) and `staff` (own data only).
  Stored as text in `profiles.role`. JWT custom claim set via Supabase Auth hook.
  RLS policies on every table enforce `auth.uid()` scoping.
- **Rationale:** Named roles are readable and maintainable. JWT claims allow Flutter
  to route correctly without a DB query on every navigation. RLS is the enforcement
  layer — Flutter role checks are for UX only, never security.
- **Consequences:** Never trust `AppEnv` or local state for security decisions.
  Always use RLS + JWT claims. If a new role is needed in future, add an ADR.

---

## [ADR-010] Transactional Email via Resend + Supabase Edge Functions
- **Date:** 2026-02-27
- **Status:** Approved
- **Context:** Booking confirmations, reminders, and cancellations require
  transactional email. Supabase does not handle this natively beyond auth emails.
- **Decision:** Use Resend as the email provider. Triggered by Supabase Edge Functions
  (not Database Webhooks, for better error handling and retry control).
- **Rationale:** Resend has a clean API, good deliverability, and supports
  per-client sending domains. Edge Functions give full control over retry logic.
  `RESEND_KEY` is a dart-define credential, accessible only in Edge Functions.
- **Consequences:** `RESEND_KEY` must never appear in Flutter code. All email
  sending is server-side only. Each client configures their own sending domain
  in Resend during the delivery checklist.
