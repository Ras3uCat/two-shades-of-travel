# Feature — Monthly Stats Digest Email
**Created:** 2026-03-26 | **Updated:** 2026-03-26 | **Mode:** FLOW | **Status:** COMPLETE
**Priority:** Medium | **Complexity:** Low
**Flag:** `DIGEST_ENABLED=true` (dart-define in client.json)

---

## Objective

On the 1st of each month, automatically email the master user a branded summary of last month's
performance. Makes the ongoing retainer feel tangible with zero maintenance after setup.

---

## What's Already in Place

- `send-reminders/index.ts` — confirmed pattern: `serve(async () => {` (no `req` param —
  scheduled functions don't receive a request). Service role `createClient`. Parallel fetches.
- `send-notification/index.ts` — Resend call pattern confirmed. Reads `BUSINESS_NAME`,
  `FROM_EMAIL`, `TIMEZONE`, `SITE_URL` from `Deno.env` (pushed as Supabase secrets by
  `deliver.sh`) — digest uses the same secrets, not `business_config`.
- Staff email lookup confirmed: `db.auth.admin.getUserById(userId)` — `db` is the service-role
  client (`createClient` with `SUPABASE_SERVICE_ROLE_KEY`). There is no separate `supabaseAdmin`
  variable — it's the same `db` instance.
- `bookings` table — `total_price` (numeric, dollars), `status`, `client_email`, `start_time`,
  `service_names` (text array) all confirmed.

---

## Schema Changes

None.

---

## Edge Function

**`send-monthly-digest/index.ts`**

Cron: `0 8 1 * *` (8am UTC on the 1st of each month).

```ts
serve(async () => {   // no req param — scheduled function
  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  const resendKey = Deno.env.get('RESEND_KEY') ?? ''
  if (!resendKey) return json({ error: 'RESEND_KEY not configured' }, 500)

  // Previous month range (UTC)
  const now   = new Date()
  const start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 1, 1))
  const end   = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1))
  const startIso = start.toISOString()
  const endIso   = end.toISOString()

  // Fetch confirmed bookings in period
  const { data: confirmed } = await db
    .from('bookings')
    .select('total_price, service_names, client_email')
    .eq('status', 'confirmed')
    .gte('start_time', startIso)
    .lt('start_time', endIso)

  if (!confirmed || confirmed.length === 0) return json({ skipped: 'no bookings' })

  // Cancellation count — correct Supabase v2 count syntax
  const { count: cancellations } = await db
    .from('bookings')
    .select('*', { count: 'exact', head: true })
    .eq('status', 'cancelled')
    .gte('start_time', startIso)
    .lt('start_time', endIso)

  // Revenue
  const revenue = confirmed.reduce((sum, b) => sum + Number(b.total_price), 0)

  // Top service — flatten text[] arrays, tally, pick highest
  const tally: Record<string, number> = {}
  for (const b of confirmed) {
    for (const svc of (b.service_names as string[])) {
      tally[svc] = (tally[svc] ?? 0) + 1
    }
  }
  const topService = Object.entries(tally).sort((a, b) => b[1] - a[1])[0]?.[0] ?? '—'

  // New vs returning — two queries (SDK has no subquery support)
  const periodEmails = [...new Set(confirmed.map(b => b.client_email as string))]
  const { data: priorRows } = await db
    .from('bookings')
    .select('client_email')
    .in('client_email', periodEmails)
    .lt('start_time', startIso)   // any booking before this period
  const priorEmails = new Set((priorRows ?? []).map(r => r.client_email as string))
  const newClients       = periodEmails.filter(e => !priorEmails.has(e)).length
  const returningClients = periodEmails.filter(e =>  priorEmails.has(e)).length

  // Master user email
  const { data: masterProfile } = await db
    .from('profiles')
    .select('user_id')
    .eq('role', 'master')
    .single()
  if (!masterProfile) return json({ error: 'No master user found' }, 500)

  const { data: { user: masterUser } } = await db.auth.admin.getUserById(masterProfile.user_id)
  const toEmail = masterUser?.email
  if (!toEmail) return json({ error: 'Master user has no email' }, 500)

  // Build + send email
  const businessName = Deno.env.get('BUSINESS_NAME') ?? 'Your Business'
  const fromEmail    = Deno.env.get('FROM_EMAIL')    ?? 'hello@example.com'
  const monthLabel   = start.toLocaleString('en-US', { month: 'long', year: 'numeric', timeZone: 'UTC' })

  const html = buildDigestHtml({
    monthLabel, businessName,
    totalBookings: confirmed.length,
    revenue, topService,
    newClients, returningClients,
    cancellations: cancellations ?? 0,
  })

  await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${resendKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      from:    `${businessName} <${fromEmail}>`,
      to:      [toEmail],
      subject: `Your ${monthLabel} stats — ${businessName}`,
      html,
    }),
  })

  return json({ ok: true, month: monthLabel, bookings: confirmed.length })
})
```

`buildDigestHtml()` is a local function in the same file — inline CSS table, same style as
`send-notification` HTML blocks.

---

## Flutter Changes

### `app_env.dart`
```dart
static const digestEnabled = bool.fromEnvironment('DIGEST_ENABLED', defaultValue: false);
```

No other Flutter changes. Email-only feature.

---

## client.json / deliver.sh

```json
"DIGEST_ENABLED": "true"
```

`deliver.sh`: deploy `send-monthly-digest` when `DIGEST_ENABLED=true`. Pattern:
```bash
if [[ "$(json_get 'DIGEST_ENABLED')" == "true" ]]; then
  supabase functions deploy send-monthly-digest --project-ref "$PROJECT_REF"
fi
```

Print cron setup instruction (same style as send-reminders comment in the file):
```
Supabase Dashboard → Edge Functions → send-monthly-digest → Schedule: 0 8 1 * *
```

---

## Acceptance Criteria

- [ ] `DIGEST_ENABLED=false` / key absent — function not deployed
- [ ] Digest email received on 1st of month by master user
- [ ] Correct previous calendar month range (not rolling 30 days)
- [ ] All 6 stats present: total bookings, revenue, top service, new clients, returning clients, cancellations
- [ ] Zero confirmed bookings in period → no email sent (early return)
- [ ] `RESEND_KEY` not set → 500 with clear error, no crash
- [ ] No master user in `profiles` → 500 with clear error, no crash
- [ ] Count uses correct Supabase v2 syntax: `select('*', { count: 'exact', head: true })`
- [ ] New vs returning uses two-query approach (no subquery)
- [ ] All files ≤ 300 lines
