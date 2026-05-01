import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Scheduled Edge Function — runs on the 1st of each month.
// Emails the master user a summary of the previous month's performance.
// Setup: Supabase Dashboard → Edge Functions → send-monthly-digest → Schedule: "0 8 1 * *"

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

interface DigestData {
  monthLabel:      string
  businessName:    string
  totalBookings:   number
  revenue:         number
  topService:      string
  newClients:      number
  returningClients: number
  cancellations:   number
}

function buildDigestHtml(d: DigestData): string {
  const revenue = `$${d.revenue.toFixed(2)}`
  return `
    <div style="font-family:sans-serif;max-width:560px;margin:0 auto;color:#1c1b1f">
      <h2 style="margin-bottom:4px">${d.monthLabel} Stats</h2>
      <p style="color:#888;margin-top:0">${d.businessName}</p>
      <table cellpadding="10" style="border-collapse:collapse;width:100%;margin-top:16px">
        <tr style="background:#f5f5f5">
          <td style="width:55%"><strong>Confirmed Bookings</strong></td>
          <td>${d.totalBookings}</td>
        </tr>
        <tr>
          <td><strong>Total Revenue</strong></td>
          <td>${revenue}</td>
        </tr>
        <tr style="background:#f5f5f5">
          <td><strong>Top Service</strong></td>
          <td>${d.topService}</td>
        </tr>
        <tr>
          <td><strong>New Clients</strong></td>
          <td>${d.newClients}</td>
        </tr>
        <tr style="background:#f5f5f5">
          <td><strong>Returning Clients</strong></td>
          <td>${d.returningClients}</td>
        </tr>
        <tr>
          <td><strong>Cancellations</strong></td>
          <td>${d.cancellations}</td>
        </tr>
      </table>
      <p style="margin-top:24px;color:#888;font-size:13px">
        — Sent automatically by your ${d.businessName} platform
      </p>
    </div>
  `
}

serve(async () => {
  try {
    const db = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const resendKey = Deno.env.get('RESEND_KEY') ?? ''
    if (!resendKey) return json({ error: 'RESEND_KEY not configured' }, 500)

    // Previous month date range (UTC)
    const now      = new Date()
    const start    = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 1, 1))
    const end      = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1))
    const startIso = start.toISOString()
    const endIso   = end.toISOString()

    // Confirmed bookings in period
    const { data: confirmed } = await db
      .from('bookings')
      .select('total_price, service_names, client_email')
      .eq('status', 'confirmed')
      .gte('start_time', startIso)
      .lt('start_time', endIso)

    if (!confirmed || confirmed.length === 0) return json({ skipped: 'no confirmed bookings' })

    // Cancellation count
    const { count: cancellations } = await db
      .from('bookings')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'cancelled')
      .gte('start_time', startIso)
      .lt('start_time', endIso)

    // Revenue
    const revenue = confirmed.reduce((sum, b) => sum + Number(b.total_price), 0)

    // Top service — flatten text[] arrays, tally occurrences
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
      .lt('start_time', startIso)
    const priorEmails      = new Set((priorRows ?? []).map(r => r.client_email as string))
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

    const businessName = Deno.env.get('BUSINESS_NAME') ?? 'Your Business'
    const fromEmail    = Deno.env.get('FROM_EMAIL')    ?? 'hello@example.com'
    const monthLabel   = start.toLocaleString('en-US', {
      month: 'long', year: 'numeric', timeZone: 'UTC',
    })

    const html = buildDigestHtml({
      monthLabel, businessName, revenue, topService,
      totalBookings: confirmed.length,
      newClients, returningClients,
      cancellations: cancellations ?? 0,
    })

    const res = await fetch('https://api.resend.com/emails', {
      method:  'POST',
      headers: { Authorization: `Bearer ${resendKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from:    `${businessName} <${fromEmail}>`,
        to:      [toEmail],
        subject: `Your ${monthLabel} stats — ${businessName}`,
        html,
      }),
    })

    if (!res.ok) {
      const err = await res.text()
      return json({ error: `Resend error: ${err}` }, 500)
    }

    return json({ ok: true, month: monthLabel, bookings: confirmed.length })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
