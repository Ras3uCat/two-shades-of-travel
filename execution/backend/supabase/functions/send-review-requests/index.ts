import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Scheduled Edge Function — call daily via Supabase dashboard cron or pg_cron.
// Sends a "how was your experience?" email 2+ hours after a booking is completed.
// Setup: Supabase dashboard → Edge Functions → send-review-requests → Schedule → "0 12 * * *"

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

function buildHtml(clientName: string, businessName: string, siteUrl: string): string {
  return `
    <p>Hi ${clientName},</p>
    <p>Thank you for your visit to <strong>${businessName}</strong>. We hope you had a great experience!</p>
    <p>We'd love to hear your thoughts. If you enjoyed your appointment, please consider leaving us a review — it helps more than you know.</p>
    <p style="margin-top:24px">
      <a href="${siteUrl}/testimonials"
         style="background:#000;color:#fff;padding:10px 20px;text-decoration:none;display:inline-block">
        Share Your Experience
      </a>
    </p>
    <p style="margin-top:24px;color:#888;font-size:13px">
      — The ${businessName} team
    </p>
  `
}

serve(async () => {
  try {
    const resendKey    = Deno.env.get('RESEND_KEY') ?? ''
    const businessName = Deno.env.get('BUSINESS_NAME') ?? 'Us'
    const fromEmail    = Deno.env.get('FROM_EMAIL')    ?? 'hello@example.com'
    const siteUrl      = Deno.env.get('SITE_URL')      ?? ''

    if (!resendKey) return json({ error: 'RESEND_KEY not configured' }, 500)

    const db = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // Find completed bookings that ended at least 2 hours ago and haven't been asked for a review
    const cutoff = new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString()

    const { data: bookings, error } = await db
      .from('bookings')
      .select('id, client_name, client_email')
      .eq('status', 'completed')
      .eq('review_request_sent', false)
      .lte('end_time', cutoff)

    if (error) return json({ error: error.message }, 500)
    if (!bookings || bookings.length === 0) return json({ sent: 0 })

    type Booking = { id: string; client_name: string; client_email: string }

    const results = await Promise.allSettled(
      (bookings as Booking[]).map(async (b) => {
        const html = buildHtml(b.client_name, businessName, siteUrl)
        const res = await fetch('https://api.resend.com/emails', {
          method:  'POST',
          headers: {
            Authorization:  `Bearer ${resendKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            from:    `${businessName} <${fromEmail}>`,
            to:      [b.client_email],
            subject: `How was your visit? — ${businessName}`,
            html,
          }),
        })
        if (!res.ok) throw new Error(await res.text())
      })
    )

    // Mark review requests as sent regardless of email success (avoid spam on retry)
    const ids = (bookings as Booking[]).map((b) => b.id)
    await db.from('bookings').update({ review_request_sent: true }).in('id', ids)

    const sent   = results.filter((r) => r.status === 'fulfilled').length
    const failed = results.length - sent
    return json({ sent, failed })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
