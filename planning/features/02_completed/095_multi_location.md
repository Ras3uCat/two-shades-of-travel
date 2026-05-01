# Feature — Multi-Location Support
**Created:** 2026-03-26 | **Updated:** 2026-03-26 | **Mode:** STUDIO | **Status:** COMPLETE
**Priority:** Low (High Value) | **Complexity:** High
**Flag:** `LOCATIONS_ENABLED=true` (dart-define in client.json)

---

## Objective

Allow a single `client.json` deployment to serve multiple physical locations — each with their
own staff, hours, and address. Booking flow asks "which location?" first.

Defer until a real multi-location client is signed. The open decisions below must be resolved
before implementation begins.

---

## What Needs to Change

### Schema — `099_multi_location.sql`
_(Gap: migration 095 is taken by chatbot_full. Next available is 099.)_

New table:
```sql
CREATE TABLE locations (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name       text NOT NULL,
  address    text,
  city       text,
  phone      text,
  timezone   text NOT NULL DEFAULT 'UTC',
  is_active  boolean DEFAULT true,
  sort_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);
```

Tables requiring `location_id` (confirmed from migrations 000–090):
- `profiles` — staff belong to location(s)
- `services` — may vary per location
- `bookings` — every booking scoped to a location
- `business_hours` (in `business_config` or separate table — clarify in open decisions)
- `promo_codes` — optionally scoped

Note: `business_config` currently has a single row (confirmed from `create-checkout` which
queries `.limit(1).single()`). Multi-location means either multiple rows (one per location)
or a separate `location_config` table. This is the most impactful open decision.

### Decisions — RESOLVED 2026-03-26

| # | Decision | Resolution |
|---|----------|------------|
| 1 | `business_config` scope | **Single global row stays.** New `locations` table holds address/phone/timezone per location. Zero Edge Function changes required. |
| 2 | Service scope | **Shared catalog.** No `location_id` on services. All locations offer the same services. |
| 3 | Staff scope | **One location.** `location_id` FK on `profiles`. Nullable = unassigned (global staff). |
| 4 | Hours | **Per-location rows** in `business_hours` via `location_id` column (nullable = global fallback). |
| 5 | Admin scope | Master sees all locations + filter dropdown. Staff scoped to their location's bookings. |
| 6 | Single-location fallback | **Option A guarantees zero change.** `LOCATIONS_ENABLED=false` → all existing code paths unchanged. |

---

## Edge Function Changes

The following Edge Functions all query `business_config` and must be audited before implementation.
Resolution of open decision #1 (business_config scope) determines whether each needs a
`location_id` filter, a fallback `.limit(1)` for global config, or no change.

| Function | business_config usage | Location impact |
|---|---|---|
| `get_available_slots()` (SQL RPC) | — | Add `p_location_id uuid` param; filter staff by location |
| `book_appointment()` (SQL RPC) | — | Store `location_id` on booking row |
| `create-checkout` | reads config for business name, cancellation window | Pass `location_id` through to booking |
| `cancel-booking` | reads cancellation_window from config | May need location-scoped config lookup |
| `chat` | reads config for business name, hours, system prompt (10-min cache) | Cache key must include location_id if per-location config |
| `generate-invoice` | reads business name, logo, address for invoice header | Invoice header per-location vs global |
| `send-reminders` | sends reminder email with business address | Include location address in body |
| `send-notification` | sends new-booking / cancellation emails | Include location name/address |
| `send-recurring-payment-reminders` | reads config | Audit for location scope |
| `stripe-dispatcher` | orchestrates checkout, calls handlers that touch config | Thread location_id through |
| `stripe-webhook` | reads config for confirmation email | Audit for location scope |

---

## Flutter Changes

### `AppEnv`
```dart
static const locationsEnabled = bool.fromEnvironment(
  'LOCATIONS_ENABLED',
  defaultValue: false,
);
```

### New: `LocationSelectorStep` widget
First step in booking flow when `LOCATIONS_ENABLED=true`. `BookingController` gets
`selectedLocationId` obs, passed through all steps.

### Files with `business_config` reads that need auditing
All of these read the single-row `business_config`. Multi-location changes may break them
if config becomes per-location. Audit each before touching:
- `home_controller.dart` — hero/CTA content (should stay global)
- `supabase_booking_repository.dart` lines ~112 + ~137 — calls `get_available_slots` and
  `book_appointment` RPCs directly; both need `location_id` param added
- `booking_addons_controller.dart` — reads `deposit_enabled`, `cancellation_window`
- `profile_controller.dart` — reads `cancellation_policy`
- `master_controller.dart` + `admin_repository.dart` — read/write `business_config` row

### Admin
- `/admin/locations` view for master role (add/edit/delete locations).
- All admin list views (bookings, staff) get a location filter dropdown.
- `admin_shell.dart`: Locations nav entry gated on `LOCATIONS_ENABLED`.

---

## client.json / deliver.sh

```json
"LOCATIONS_ENABLED": true
```
_(Gap: must be boolean `true`, not string `"true"` — `bool.fromEnvironment` requires unquoted.)_

### setup.sh registration (missing — add when implementing)
```bash
if flag_enabled "LOCATIONS_ENABLED"; then run_always "099_multi_location.sql"; fi
```

### deliver.sh block (missing — add when implementing)
```bash
LOCATIONS_ENABLED=$(json_get "LOCATIONS_ENABLED")
# ... in deploy section:
if [[ "${LOCATIONS_ENABLED:-false}" == "true" ]]; then
  supabase db push --file "$MIGRATIONS_DIR/099_multi_location.sql"
fi
```

Seed locations via admin panel after deploy.

---

## Acceptance Criteria

- [ ] `LOCATIONS_ENABLED=false` — zero behaviour change
- [ ] `LOCATIONS_ENABLED=true` — location selector is step 1 of booking flow
- [ ] Available slots scoped to selected location's staff
- [ ] Booking row stores `location_id`
- [ ] Master sees all locations; staff sees only their location's bookings
- [ ] Location address in confirmation and reminder emails
- [ ] All files ≤ 300 lines (split aggressively — many new files)
