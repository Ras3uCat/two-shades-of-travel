---
description: Repository and Supabase data layer conventions. Apply when editing any repository file or Edge Function.
globs: ["execution/frontend/app/lib/features/*/repositories/**/*.dart", "execution/backend/supabase/functions/**/*.ts"]
---

# API / Repository Conventions

## Repository Pattern (Dart)
- Every feature has an abstract repository + Supabase concrete implementation
- Abstract: `<Feature>Repository` (method signatures only)
- Concrete: `Supabase<Feature>Repository implements <Feature>Repository`
- Controllers always depend on the abstract type — swappable for testing

```dart
class SupabaseBookingRepository implements BookingRepository {
  Future<BookingModel?> getBooking(String id) async {
    final data = await SupabaseService.client
        .from('bookings')
        .select()
        .eq('id', id)
        .single();
    return BookingModel.fromJson(data);
  }
}
```

## Supabase Query Rules
- Apply `.eq()` filters BEFORE `.order()` / `.limit()` (SDK limitation)
- `single()` returns `Map<String,dynamic>` directly — no cast needed
- Use `.isFilter('col', null)` NOT `.is_('col', null)` for null checks (v2 SDK)
- Always handle errors — wrap in try/catch, surface via controller state

## Edge Functions
- Import Stripe: `https://esm.sh/stripe@14?target=deno&no-check`
- Email via Resend — never from Flutter code
- Always verify Stripe `Stripe-Signature` header before processing events
- Idempotency: check `evt_id` before processing webhook events
- Return `200 OK` for unknown event types (log + skip, never 400)

## Supabase RLS
- Every table: `ALTER TABLE public.table_name ENABLE ROW LEVEL SECURITY;`
- Admin roles: `master` (full access), `staff` (own data only) via JWT custom claims
- Never expose `service_role` key to Flutter client

## Migration Naming
```
execution/backend/supabase/migrations/YYYYMMDDHHMMSS_description.sql
```
Always include `-- rollback:` comment for destructive changes.
