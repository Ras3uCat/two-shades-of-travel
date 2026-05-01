# Feature — Push Notifications (PWA)
**Created:** 2026-03-26 | **Updated:** 2026-03-26 (2nd pass) | **Mode:** STUDIO | **Status:** COMPLETE
**Priority:** Medium | **Complexity:** Medium
**Flag:** `PUSH_ENABLED=true` (dart-define in client.json)

---

## Objective

Web Push notifications via the browser Push API — no FCM or APNs required. Works on Chrome,
Edge, Firefox, and Safari 16.4+. Most impactful for mobile users who add the PWA to home screen.

Use cases v1:
- 24h booking reminder (alongside existing Resend email)
- New booking notification to staff/master

---

## What's Already in Place

- `send-reminders/index.ts` — confirmed cron pattern: queries bookings 23-25h ahead, calls
  `send-notification` per booking, marks `reminder_sent=true`. Selects `id, client_email,
  client_name` — **no `client_id`** (bookings table has none; clients identified by email only).
- `send-notification/index.ts` — handles `staff_new_booking`; has `booking.artist_id` for staff
  push target. No client user_id available here either.
- `web/index.html.tpl` — source-of-truth for web/ assets (never edit index.html directly).
  SW registration block goes in the `.tpl` file.
- `AppEnv` — `pushEnabled` not yet in `app_env.dart`. Must be added using `static const` pattern.
- `SITE_URL` dart-define already exists in `AppEnv.siteUrl` — needed for VAPID origin.
- `package:web ^1.0.0` — already in `pubspec.yaml`. Use this for all browser Push API bindings
  (`Notification`, `PushManager`, `PushSubscription`). Do NOT use the simpler `dart:js_interop`
  `@JS()` void-function pattern from `gdpr_bridge_web.dart` — insufficient for async Push API.

---

## Schema Changes

**Migration: `092_push_subscriptions.sql`** (next after 091_tip.sql)

```sql
-- Stores Web Push subscriptions for both authenticated users (staff/master)
-- and guest clients (identified by client_email, no auth account required).
CREATE TABLE push_subscriptions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid REFERENCES auth.users ON DELETE CASCADE, -- nullable: staff/master only
  client_email text,                                         -- nullable: guest clients only
  endpoint     text NOT NULL UNIQUE,
  p256dh       text NOT NULL,
  auth_key     text NOT NULL,
  user_agent   text,
  created_at   timestamptz DEFAULT now(),
  CONSTRAINT identifier_required CHECK (user_id IS NOT NULL OR client_email IS NOT NULL)
);

ALTER TABLE push_subscriptions ENABLE ROW LEVEL SECURITY;

-- Authenticated users can manage their own rows
CREATE POLICY "own subscriptions" ON push_subscriptions
  FOR ALL USING (auth.uid() = user_id);

-- Service role bypasses RLS for save-push-subscription (guest inserts) and send-push (fan-out)
-- No additional policy needed — service role key skips RLS automatically.
```

---

## Edge Functions

### `save-push-subscription/index.ts` (new)

Called from Flutter after browser grants permission. Uses **service role key** (not anon key)
so it works for both logged-in users and guests.

Request body:
```json
{ "endpoint": "...", "p256dh": "...", "auth_key": "...", "user_agent": "...",
  "client_email": "..." }
```

Flow:
1. Optionally verify JWT (`db.auth.getUser(token)`) — if present, populate `user_id`.
2. Fall back to `client_email` from body if no valid JWT (guest booking flow).
3. Upsert on `endpoint` (unique) with `ignoreDuplicates: false` to refresh keys if browser reissues.

### `send-push/index.ts` (new, internal — not called from Flutter)

Uses `https://deno.land/x/web_push/mod.ts` (Deno-native VAPID — NOT `esm.sh/web-push` which
has Node.js crypto dependencies incompatible with Deno's Web Crypto API).

Accepts: `{ user_id?: string, client_email?: string, title: string, body: string, url: string }`

Fan-out: queries `push_subscriptions` matching either `user_id` OR `client_email`, sends to all.
Errors per-subscription are caught and skipped (expired endpoints removed from DB).

Secrets: `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `SITE_URL`.

### Modify `send-reminders/index.ts`

After firing reminder email, also call `send-push` keyed by `client_email` (not `client_id` —
that field does not exist on bookings):
```ts
// best-effort — don't await, don't let failure block email
db.functions.invoke('send-push', {
  body: { client_email: booking.client_email, title: 'Appointment reminder', body: '...', url: '...' },
}).catch(() => {})
```

### Modify `send-notification/index.ts`

On `staff_new_booking`: also call `send-push` to `booking.artist_id` (staff user_id is available):
```ts
db.functions.invoke('send-push', {
  body: { user_id: booking.artist_id, title: 'New booking', body: '...', url: '...' },
}).catch(() => {})
```

---

## Flutter / Web Changes

### `app_env.dart`
```dart
static const pushEnabled = bool.fromEnvironment('PUSH_ENABLED', defaultValue: false);
static const vapidPublicKey = String.fromEnvironment('VAPID_PUBLIC_KEY');
```
Note: use `static const`, not `static bool get`.

### `web/sw.js` (new)
Service worker file. Handles:
- `push` event → `self.registration.showNotification(title, { body, icon: '/icons/Icon-192.png', data: { url } })`
- `notificationclick` → `clients.openWindow(event.notification.data.url)`

### `web/index.html.tpl` (not `index.html`)
Add SW registration block — unconditional (sw.js always present; Flutter gates permission prompt
via `AppEnv.pushEnabled`, so no push subscription is ever saved when disabled):
```js
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js');
}
```
Add as a new `<script>` block before the `flutter_bootstrap.js` script tag.

### `lib/core/push/` (conditional import — web only)

Uses `package:web` (already in pubspec at `^1.0.0`) — NOT the `dart:js_interop` `@JS()` pattern
from `gdpr_bridge_web.dart` (that pattern is only sufficient for void JS calls, not async Push API).

- `push_service.dart` — abstract interface + conditional export:
  ```dart
  export 'push_service_stub.dart'
    if (dart.library.js_interop) 'push_service_web.dart';
  ```
- `push_service_stub.dart` — no-op for non-web: `Future<void> requestAndSavePush(String clientEmail) async {}`
- `push_service_web.dart` — uses `package:web`:
  1. Check `window.Notification.permission` — return early if `'denied'`
  2. `await window.Notification.requestPermission()` — return if not `'granted'`
  3. `final reg = await window.navigator.serviceWorker.ready`
  4. `final sub = await reg.pushManager.subscribe(PushSubscriptionOptionsInit(userVisibleOnly: true, applicationServerKey: vapidKey))`
  5. Extract `endpoint`, `p256dh` (from `getKey('p256dh')`), `auth` (from `getKey('auth')`) — encode as base64url
  6. Call `save-push-subscription` Edge Function via `SupabaseService.client.functions.invoke()`

### Integration point

`BookingConfirmationView` — call after booking confirmed/paid (highest intent moment).
Show once per session; check `Notification.permission != 'denied'` before prompting.
Pass `booking.clientEmail` from the confirmed booking model so guests can receive reminders.

---

## client.json / deliver.sh

```json
"PUSH_ENABLED": "true",
"VAPID_PUBLIC_KEY": "B..."
```

**`VAPID_PRIVATE_KEY` must NOT go in `client.json`** — `client.json` is committed to the repo.
Pass it as a shell environment variable or enter interactively; `deliver.sh` reads it from env
and pushes it as a Supabase secret:
```bash
VAPID_PRIVATE_KEY="${VAPID_PRIVATE_KEY:-}" # read from shell env, not client.json
[[ -n "$VAPID_PRIVATE_KEY" ]] && SECRET_ARGS="$SECRET_ARGS VAPID_PRIVATE_KEY='$VAPID_PRIVATE_KEY'"
```

Generate VAPID keys once per client (requires Node.js):
```bash
npx web-push generate-vapid-keys
```

`deliver.sh`:
- Deploy `save-push-subscription` + `send-push` when `PUSH_ENABLED=true`
- Push `VAPID_PUBLIC_KEY` (from client.json) + `VAPID_PRIVATE_KEY` (from shell env) as secrets
- No new cron needed — push piggybacks `send-reminders` (existing `0 10 * * *`) and `send-notification`

---

## Acceptance Criteria

- [ ] `PUSH_ENABLED=false` — no permission prompt, no subscription saved; sw.js still loads (harmless)
- [ ] `PUSH_ENABLED=true` — permission prompt appears on booking confirmation view
- [ ] `push_subscriptions` row created for both logged-in users (user_id) and guests (client_email)
- [ ] Push received alongside reminder email for qualifying bookings (keyed by client_email)
- [ ] Staff push fires on new booking (keyed by artist_id / user_id)
- [ ] `notificationclick` opens correct booking URL in-app
- [ ] Denied permission handled silently (no crash, no retry prompt)
- [ ] Expired endpoint rows deleted automatically on 410 response from push service
- [ ] `VAPID_PRIVATE_KEY` never written to client.json or any committed file
- [ ] All files ≤ 300 lines
