# STUDIO_PLAN_ICAL.md — Google Calendar / iCal Staff Feed

**Feature:** Tokenized iCal feed per staff member, subscribable by any calendar app
**Workflow Mode:** STUDIO
**Status:** APPROVED — Ready for implementation

---

## Context and Constraints

### Key Discoveries

1. `lib/shared/services/ics_service.dart` already exists (57 lines) with a working `_fmt()` RFC 5545 datetime formatter and VCALENDAR/VEVENT builder. The Edge Function replicates this pattern server-side.
2. `admin_repository.dart` is at **291 lines** — one more method pushes it over the 300-line limit. New calendar token methods go in a **new** `calendar_token_repository.dart`.
3. `staff_controller.dart` is at 115 lines — headroom for token state.
4. `master_controller.dart` is at 230 lines — headroom for two new methods.
5. `staff_manager_view.dart` is at 232 lines — calendar admin UI goes in a separate `staff_calendar_dialog.dart` file.
6. `url_launcher` (^6.3.1) is already in `pubspec.yaml` — Google Calendar button uses `launchUrl` as established.
7. All Edge Functions deploy with `--no-verify-jwt` — correct for calendar apps that cannot send auth headers.
8. iCal feed URL: `${AppEnv.supabaseUrl}/functions/v1/staff-calendar?token=<uuid>`. Constructed from existing dart-define.
9. Migration numbering: last is `087_events.sql`. Next is `088_calendar_tokens.sql`.

---

## Architecture Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | `calendar_tokens` table, PK = `staff_id` | One token per staff. Upsert on regenerate. |
| D2 | Edge Function uses service role key | Token lookup + booking query in one hop, no auth hop. |
| D3 | Feed includes `confirmed` + `pending`, excludes `cancelled` | Staff need visibility of tentative appointments. |
| D4 | Regeneration = `UPDATE ... SET token = gen_random_uuid()` | Atomic. Old URLs break intentionally (revoke by design). |
| D5 | `CalendarSyncWidget` is a `StatefulWidget` | One-off async load; no need for reactive obs. |
| D6 | No `AppModule` registration | Embedded widget in staff portal — no nav item, no route. |
| D7 | Admin calendar UI in separate dialog file | Keeps `staff_manager_view.dart` under 300 lines. |
| D8 | New `CalendarTokenRepository` (abstract + Supabase impl) | `admin_repository.dart` is at 291 lines. |
| D9 | iCal DESCRIPTION = `client_name + notes` concatenation | Max info in calendar app without cluttering SUMMARY. |
| D10 | RLS: staff self-update + master-all policy | Staff can self-regenerate; master can manage any staff token. |

---

## New Files

| File | Purpose | Est. Lines |
|------|---------|-----------|
| `execution/backend/supabase/migrations/088_calendar_tokens.sql` | Table + RLS policies | 45 |
| `execution/backend/supabase/functions/staff-calendar/index.ts` | Token lookup → bookings → iCal response | 130 |
| `lib/modules/admin/data/repositories/calendar_token_repository.dart` | Abstract + `SupabaseCalendarTokenRepository` | 60 |
| `lib/shared/widgets/calendar_sync_widget.dart` | Staff portal: URL display, copy, Google Cal, regenerate | 140 |
| `lib/modules/admin/views/master/staff_calendar_dialog.dart` | Admin dialog: view/regenerate any staff token | 90 |

**Total new: ~465 lines**

---

## Modified Files

| File | Change | Δ Lines |
|------|--------|---------|
| `lib/modules/admin/controllers/staff_controller.dart` | `calendarToken` obs, `loadCalendarToken()`, `regenerateCalendarToken()` | +20 |
| `lib/modules/admin/controllers/master_controller.dart` | `getStaffCalendarToken()`, `regenerateStaffCalendarToken()` | +20 |
| `lib/modules/admin/views/staff/staff_bookings_view.dart` | Embed `CalendarSyncWidget` between header and TabBar | +8 |
| `lib/modules/admin/views/master/staff_manager_view.dart` | Calendar icon button on each `_StaffTile` | +12 |
| `lib/modules/admin/bindings/admin_binding.dart` | Register `CalendarTokenRepository` | +3 |
| `execution/frontend/app/deliver.sh` | `deploy_fn "staff-calendar"` + `CLIENT_SLUG` secret | +4 |

---

## Implementation Checklist

### Phase A — Database

- [ ] **A1.** Create `execution/backend/supabase/migrations/088_calendar_tokens.sql`
  ```sql
  CREATE TABLE IF NOT EXISTS calendar_tokens (
    staff_id   UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    token      UUID NOT NULL DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
  );

  ALTER TABLE calendar_tokens ENABLE ROW LEVEL SECURITY;

  -- Staff can read their own token
  CREATE POLICY "tokens_own_read" ON calendar_tokens
    FOR SELECT USING (auth.uid() = staff_id);

  -- Staff can regenerate their own token (update)
  CREATE POLICY "tokens_own_update" ON calendar_tokens
    FOR UPDATE USING (auth.uid() = staff_id);

  -- Staff can create their own token row (insert)
  CREATE POLICY "tokens_own_insert" ON calendar_tokens
    FOR INSERT WITH CHECK (auth.uid() = staff_id);

  -- Master can manage any token
  CREATE POLICY "tokens_master_all" ON calendar_tokens
    FOR ALL USING ((auth.jwt() ->> 'user_role') = 'master');

  GRANT ALL ON calendar_tokens TO service_role;
  ```

---

### Phase B — Edge Function + Pipeline

- [ ] **B1.** Create `execution/backend/supabase/functions/staff-calendar/index.ts`

  Structure (130 lines):
  ```
  serve(async (req) => {
    1. Parse ?token= query param → 400 if missing
    2. Service-role client (SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY)
    3. SELECT staff_id FROM calendar_tokens WHERE token = $token (maybeSingle) → 404 if not found
    4. SELECT bookings WHERE artist_id = staff_id AND status IN ('confirmed','pending') ORDER BY start_time
    5. Build iCal string (VCALENDAR > VEVENTs)
       - PRODID: -//Raspucat//${CLIENT_SLUG ?? 'app'}//EN
       - Per booking: UID, DTSTAMP, DTSTART, DTEND, SUMMARY (service — client), DESCRIPTION (client + notes)
       - Line folding at 75 octets via fold() helper
    6. Return Response with Content-Type: text/calendar; charset=utf-8
  })

  function fmtDate(d: Date): string  // YYYYMMDDTHHMMSSZ format
  function fold(line: string): string // RFC 5545 line folding at 75 chars
  ```

  Key implementation notes:
  - Use `maybeSingle()` (not `single()`) for token lookup
  - Fold SUMMARY and DESCRIPTION lines — Outlook desktop is strict about 75-octet limit
  - `CLIENT_SLUG` from `Deno.env.get('CLIENT_SLUG') ?? 'app'` — cosmetic fallback acceptable
  - `--no-verify-jwt` already applied by deliver.sh — no change needed

- [ ] **B2.** Add to `deliver.sh` always-deploy block:
  ```bash
  deploy_fn "staff-calendar"
  ```

- [ ] **B3.** Add to `deliver.sh` Step 4 secrets push:
  ```bash
  CLIENT_SLUG="$CLIENT_SLUG"
  ```

- [ ] **B4.** Test via `curl` before Flutter work:
  ```bash
  curl "https://<project>.supabase.co/functions/v1/staff-calendar?token=<uuid>"
  # Expect: text/calendar response with VCALENDAR block
  ```

---

### Phase C — Repository Layer

- [ ] **C1.** Create `lib/modules/admin/data/repositories/calendar_token_repository.dart`

  ```dart
  abstract class CalendarTokenRepository {
    Future<String?> getToken(String staffId);
    Future<String>  ensureToken(String staffId); // upsert → return token
    Future<String>  regenerateToken(String staffId); // UPDATE token = gen_random_uuid()
  }

  class SupabaseCalendarTokenRepository implements CalendarTokenRepository {
    // getToken: SELECT token WHERE staff_id = $staffId (maybeSingle)
    // ensureToken: upsert({staff_id}, ignoreDuplicates: true) → SELECT token
    // regenerateToken: UPDATE calendar_tokens SET token = gen_random_uuid()
    //                  WHERE staff_id = $staffId → return new token
    //   Note: gen_random_uuid() called via rpc('gen_random_uuid') or
    //         update with Postgres DEFAULT — use raw SQL via rpc if needed.
    //   Simpler: call .update({'token': null}) won't work for DEFAULT.
    //   Best: create a tiny SQL function regenerate_calendar_token(p_staff_id)
    //         that does UPDATE ... SET token = gen_random_uuid() RETURNING token
    //         and call it via .rpc('regenerate_calendar_token', {'p_staff_id': staffId})
  }
  ```

  > **Note on regeneration:** Add `regenerate_calendar_token(p_staff_id UUID)` to `088_calendar_tokens.sql` as a `SECURITY DEFINER` function. Returns the new token UUID. This avoids the client needing to generate UUIDs.

- [ ] **C2.** Register in `lib/modules/admin/bindings/admin_binding.dart`:
  ```dart
  Get.lazyPut<CalendarTokenRepository>(() => SupabaseCalendarTokenRepository());
  ```

---

### Phase D — Staff Portal Widget

- [ ] **D1.** Add to `StaffController`:
  ```dart
  final calendarToken = RxnString();
  final isCalendarLoading = false.obs;

  Future<void> loadCalendarToken() async {
    isCalendarLoading.value = true;
    try {
      final repo = Get.find<CalendarTokenRepository>();
      calendarToken.value = await repo.ensureToken(user!.id);
    } catch (_) {} finally {
      isCalendarLoading.value = false;
    }
  }

  Future<void> regenerateCalendarToken() async {
    try {
      final repo = Get.find<CalendarTokenRepository>();
      calendarToken.value = await repo.regenerateToken(user!.id);
    } catch (_) {}
  }
  ```
  Call `loadCalendarToken()` in `onInit` / `_loadAll()`.

- [ ] **D2.** Create `lib/shared/widgets/calendar_sync_widget.dart`

  Widget outline:
  - Section header with `Icons.calendar_today_outlined`
  - Subtitle copy: "Subscribe your bookings to Google Calendar, Apple Calendar, or Outlook."
  - `Obx(() { ... })` block:
    - Loading: `LinearProgressIndicator`
    - Loaded: `SelectableText` of feed URL inside styled Container
  - Action row:
    - `OutlinedButton.icon(Icons.copy, 'Copy URL')` → `Clipboard.setData` + SnackBar
    - `OutlinedButton.icon(Icons.open_in_new, 'Google Calendar')` → `launchUrl(gcalUri)`
  - `TextButton('Regenerate token')` → `Get.dialog(AlertDialog(confirmDialog))` → `controller.regenerateCalendarToken()`

  Feed URL helper:
  ```dart
  String _feedUrl(String token) =>
      '${AppEnv.supabaseUrl}/functions/v1/staff-calendar?token=$token';

  Uri _gcalUri(String token) => Uri.parse(
      'https://calendar.google.com/calendar/r/settings/addbyurl'
      '?url=${Uri.encodeComponent(_feedUrl(token))}');
  ```

- [ ] **D3.** Embed in `staff_bookings_view.dart`:
  Insert `CalendarSyncWidget()` between the stats/header section and the TabBar. Wrap in a `Container` with `EColors.divider` bottom border to visually separate sections.

---

### Phase E — Admin View

- [ ] **E1.** Add to `MasterController`:
  ```dart
  Future<String?> getStaffCalendarToken(String staffId) =>
      Get.find<CalendarTokenRepository>().getToken(staffId);

  Future<String> regenerateStaffCalendarToken(String staffId) =>
      Get.find<CalendarTokenRepository>().regenerateToken(staffId);
  ```

- [ ] **E2.** Create `lib/modules/admin/views/master/staff_calendar_dialog.dart`

  `StatefulWidget` — takes `staffId`, `staffName`. On `initState`, loads token via `MasterController`. Renders:
  - Dialog header: `staffName` + close button
  - Feed URL display (or "No token — tap Generate")
  - `ElevatedButton('Generate / Regenerate Token')`
  - Copy URL button
  - Informational note: "Regenerating breaks existing calendar subscriptions."

- [ ] **E3.** Add calendar icon button to `_StaffTile` in `staff_manager_view.dart`:
  ```dart
  IconButton(
    tooltip: 'Calendar feed',
    icon: Icon(Icons.calendar_today_outlined, size: 18, color: EColors.onSurfaceMuted),
    onPressed: () => Get.dialog(StaffCalendarDialog(
        staffId: profile['id'] as String,
        staffName: profile['display_name'] as String? ?? '—')),
  ),
  ```

---

## Gotchas

### 1. iCal Line Folding (RFC 5545 §3.1)
Lines over 75 octets must fold with `CRLF + SPACE`. Google Calendar and Apple Calendar are tolerant; Outlook desktop is not. Implement `fold()` in the Edge Function for SUMMARY and DESCRIPTION — ~8 lines, prevents hard-to-debug Outlook failures.

### 2. `regenerateToken` needs `gen_random_uuid()` server-side
The Flutter client cannot call `gen_random_uuid()` — it must be generated by Postgres. Best approach: add a `SECURITY DEFINER` SQL function `regenerate_calendar_token(p_staff_id UUID) RETURNS UUID` to the migration, callable via `.rpc(...)`. This keeps the token generation server-side and avoids any UUID library dependency in Flutter.

### 3. Master RLS for Admin Regeneration
Without the `"tokens_master_all"` policy, admin regeneration via the master's JWT will be silently blocked — the anon client sends the master's JWT, and `auth.uid() = staff_id` evaluates false for any staff row. The `tokens_master_all` policy using `auth.jwt() ->> 'user_role' = 'master'` is critical.

### 4. `ensureToken` is Two Round-Trips
Upsert with `ignoreDuplicates: true` then re-select. Acceptable for a UI widget that loads once on page open. Not worth optimizing — the `RETURNING` clause cannot be used with `ignoreDuplicates`.

### 5. Google Calendar Mobile Behavior
`https://calendar.google.com/calendar/r/settings/addbyurl?url=...` opens in the system browser on iOS/Android, not the native Calendar app. This is expected. The **Copy URL** button is the primary path for mobile users who subscribe manually in their calendar app settings.

### 6. `booking.service_name` Column
The Edge Function selects `service_name` (scalar). Verify this column exists on `bookings` as a denormalized text column. If bookings use a join table (`booking_services`), the select must use `.select('*, booking_services(service_name)')` with a mapping step.

### 7. `CalendarSyncWidget` is Coupled to `StaffController`
Do not reuse in admin context. Admin has `StaffCalendarDialog` with `MasterController`. The widget calls `Get.find<StaffController>()` — works only inside the staff portal where `AdminBinding` has registered `StaffController`.

---

## Phase Sequence

```
Phase A (SQL + RPC fn)
  → Phase B (Edge Function, curl test)
  → Phase C (Repository + binding)
  → Phase D (StaffController + CalendarSyncWidget + embed)
  → Phase E (MasterController + StaffCalendarDialog + tile button)
```

Phases A and B can be validated independently via `curl` before any Flutter code is written.

---

## File Summary

| Category | Count | Lines |
|----------|-------|-------|
| New files | 5 | ~465 |
| Modified files | 6 | +66 |
| **Grand total** | **11** | **~531** |
