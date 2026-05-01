# Feature — SMS Reminders (Twilio)
**Created:** 2026-03-26 | **Updated:** 2026-03-26 (2nd pass) | **Mode:** FLOW | **Status:** COMPLETE
**Priority:** Medium | **Complexity:** Low
**Flag:** `SMS_ENABLED=true` (dart-define in client.json)

---

## Objective

Send SMS booking confirmations and 24h reminders via Twilio. Higher open rates than email.

Scope v1: confirmation SMS + 24h reminder SMS.
Not in scope v1: staff SMS, cancellation SMS, 2-way SMS.

---

## What's Already in Place

- `AppEnv.smsEnabled` — `static const` in `app_env.dart`. No change needed.
- `client_form.dart` — SMS phone field already rendered when `AppEnv.smsEnabled` (confirmed in
  code: `if (AppEnv.smsEnabled)` block with optional phone TextFormField). No Flutter UI changes.
- `bookings` table — `client_phone TEXT` column confirmed in migration `071_sms_phone.sql`.
  Note: column is `client_phone`, NOT `sms_phone`. Use `client_phone` everywhere.
- `send-sms-reminders/index.ts` — **already exists**. Scheduled function that sends reminder SMS
  via Twilio for bookings 23–25h away where `client_phone IS NOT NULL`. Handles reminder SMS —
  **no new reminder logic needed**.
- `send-reminders/index.ts` — handles email reminders. **Do not modify for SMS** — see Gap below.
- `send-notification/index.ts` — handles 6 notification types. Confirmation SMS fires here for
  `type === 'confirmation'`. Uses direct `fetch` for internal calls (established pattern).
- `deliver.sh` — `SMS_ENABLED` read from `client.json`, gates `send-sms-reminders` deploy.
  Twilio secrets noted as manual step. No `SMS_ENABLED` secret pushed (see Gap 5 below).

---

## Schema Changes

**Migration: `093_sms_reminder_sent.sql`** (next after 092_push_subscriptions.sql)

`send-sms-reminders` currently uses `reminder_sent` to track which bookings have been SMS-reminded.
`send-reminders` (email) uses the same column. Both run at `0 10 * * *` — whichever runs first
marks `reminder_sent = true`, leaving nothing for the second. This is a race condition: either
email OR SMS fires, never both.

Fix: separate tracking column for SMS:

```sql
-- 093_sms_reminder_sent.sql
ALTER TABLE bookings ADD COLUMN sms_reminder_sent boolean NOT NULL DEFAULT false;
```

Then update `send-sms-reminders` to filter by `sms_reminder_sent = false` and mark
`sms_reminder_sent = true` (not `reminder_sent`). Email and SMS reminders then track independently.

---

## Edge Functions

### `send-sms/index.ts` (new, internal helper)

Sends a single SMS via Twilio REST API. Called best-effort from `send-notification`.
Not called from Flutter directly.

```ts
// Twilio REST — no SDK, simple fetch
const res = await fetch(
  `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`,
  {
    method:  'POST',
    headers: {
      Authorization:  `Basic ${btoa(`${sid}:${token}`)}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      To:   phone,
      From: Deno.env.get('TWILIO_FROM_NUMBER')!,
      Body: message,
    }).toString(),
  }
)
```

Secrets: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_NUMBER`.

Message templates (≤160 chars for single-segment):
- Confirmation: `Hi {name}, your appointment on {date} at {time} is confirmed. – {BUSINESS_NAME}`
- (Reminder handled by `send-sms-reminders` — see below)

STOP opt-out: Twilio handles automatically for US numbers. Required by law.

### Modify `send-notification/index.ts` — `confirmation` type only

After the Resend email fires successfully, call `send-sms` best-effort using direct `fetch`
(consistent with push notification pattern already in this file):

```ts
if (type === 'confirmation' && booking.client_phone) {
  const sid   = Deno.env.get('TWILIO_ACCOUNT_SID') ?? ''
  const token = Deno.env.get('TWILIO_AUTH_TOKEN')  ?? ''
  if (sid && token) {
    const dateStr  = formatDateTime(booking.start_time, tz) // reuse existing helper
    const smsBody  = `Hi ${booking.client_name}, your appointment on ${dateStr} is confirmed. – ${businessName}`
    fetch(`https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`, {
      method:  'POST',
      headers: {
        Authorization:  `Basic ${btoa(`${sid}:${token}`)}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        To:   booking.client_phone,
        From: Deno.env.get('TWILIO_FROM_NUMBER')!,
        Body: smsBody,
      }).toString(),
    }).catch(() => {})
  }
}
```

Guard: check `sid && token` presence — no `SMS_ENABLED` env var check needed. If Twilio secrets
aren't set, SMS silently skips. This avoids needing to push `SMS_ENABLED` as a Supabase secret.

### Modify `send-sms-reminders/index.ts` — fix tracking field + add TIMEZONE + BUSINESS_NAME

Change `reminder_sent` → `sms_reminder_sent` (filter + mark) to fix race condition.
Also improve message template to use `TIMEZONE` env var and `BUSINESS_NAME`:

```ts
// Filter: .eq('sms_reminder_sent', false)  (not 'reminder_sent')
// Mark:   { sms_reminder_sent: true }       (not { reminder_sent: true })

// Improved message:
const businessName = Deno.env.get('BUSINESS_NAME') ?? 'Us'
const apptTime = new Intl.DateTimeFormat('en-US', {
  timeZone: Deno.env.get('TIMEZONE') ?? 'America/New_York',
  hour: 'numeric', minute: '2-digit', hour12: true,
}).format(new Date(b.start_time))
const body = `Reminder: your appointment is tomorrow at ${apptTime}. – ${businessName}. Reply STOP to opt out.`
```

**Do NOT modify `send-reminders/index.ts`** — email reminder tracking is independent.

---

## Flutter Changes

None. `AppEnv.smsEnabled` already defined. SMS phone field already in step 4 as `client_phone`
passed through `BookingAddonsController` → repository → `book_appointment()`. Backend-only feature.

---

## client.json / deliver.sh

```json
"SMS_ENABLED": "true"
```

`deliver.sh` additions:
- Deploy `send-sms` when `SMS_ENABLED=true`
- Twilio secrets (`TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_NUMBER`) are sensitive —
  instruct delivery person to set manually or read from shell env (same pattern as `VAPID_PRIVATE_KEY`)
- **No `SMS_ENABLED` Supabase secret needed** — `send-sms` and `send-sms-reminders` gate on
  presence of Twilio secrets, not an `SMS_ENABLED` env var

---

## Acceptance Criteria

- [ ] `SMS_ENABLED=false` — phone field hidden, no `send-sms` deployed, no SMS sent
- [ ] `SMS_ENABLED=true` — phone field visible in step 4 (already works)
- [ ] Confirmation SMS received within 60s of booking confirmation
- [ ] 24h reminder SMS received alongside reminder email (not instead of)
- [ ] `client_phone = null` — no SMS attempted
- [ ] STOP handling delegated to Twilio
- [ ] `sms_reminder_sent` column prevents double-sending after re-schedule or retry
- [ ] All files ≤ 300 lines
