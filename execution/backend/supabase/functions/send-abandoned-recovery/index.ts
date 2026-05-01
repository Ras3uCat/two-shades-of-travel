import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Scheduled Edge Function — runs every 2 hours via Supabase dashboard cron.
// Emails users who reached Stripe checkout but never completed payment.
// Setup: Supabase dashboard → Edge Functions → send-abandoned-recovery → Schedule → "0 */2 * * *"

const BATCH_LIMIT = 50

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

serve(async () => {
  try {
    const db = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const cutoff = new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString()

    const { data: bookings, error } = await db
      .from('bookings')
      .select('id, client_email, client_name')
      .eq('status', 'pending')
      .eq('recovery_email_sent', false)
      .lt('created_at', cutoff)
      .limit(BATCH_LIMIT)

    if (error) return json({ error: error.message }, 500)
    if (!bookings || bookings.length === 0) return json({ sent: 0 })

    const resendKey    = Deno.env.get('RESEND_KEY') ?? ''
    const businessName = Deno.env.get('BUSINESS_NAME') ?? 'Us'
    const fromEmail    = Deno.env.get('FROM_EMAIL') ?? 'hello@example.com'
    const siteUrl      = Deno.env.get('SITE_URL') ?? ''

    if (resendKey) {
      await Promise.allSettled(
        bookings.map((b: { id: string; client_email: string; client_name: string | null }) => {
          const resumeLink = `${siteUrl}/profile`
          return fetch('https://api.resend.com/emails', {
            method:  'POST',
            headers: {
              Authorization:  `Bearer ${resendKey}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              from:    `${businessName} <${fromEmail}>`,
              to:      [b.client_email],
              subject: `Complete your booking with ${businessName}`,
              html: `
                <p>Hi${b.client_name ? ` ${b.client_name}` : ''},</p>
                <p>You started a booking with ${businessName} but didn't complete payment.</p>
                <p>Your slot is held for a limited time.</p>
                <p>
                  <a href="${resumeLink}" style="
                    display:inline-block;
                    padding:12px 24px;
                    background:#000;
                    color:#fff;
                    text-decoration:none;
                    border-radius:4px;
                    font-weight:600;
                  ">Resume booking</a>
                </p>
                <p style="font-size:12px;color:#999;margin-top:2rem;">
                  If you no longer need this booking, you can ignore this email.
                </p>
              `,
            }),
          })
        })
      )
    }

    // Mark as sent — prevents duplicate emails on next cron run
    const ids = bookings.map((b: { id: string }) => b.id)
    await db.from('bookings').update({ recovery_email_sent: true }).in('id', ids)

    return json({ sent: bookings.length })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
