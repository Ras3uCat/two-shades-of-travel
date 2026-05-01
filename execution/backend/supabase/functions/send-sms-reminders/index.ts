import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Scheduled Edge Function — mirrors send-reminders but delivers via Twilio SMS.
// Schedule: "0 10 * * *" in Supabase dashboard → Edge Functions → send-sms-reminders → Schedule
// Required secrets: TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_FROM_NUMBER

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

serve(async () => {
  try {
    const accountSid  = Deno.env.get('TWILIO_ACCOUNT_SID')
    const authToken   = Deno.env.get('TWILIO_AUTH_TOKEN')
    const fromNumber  = Deno.env.get('TWILIO_FROM_NUMBER')

    if (!accountSid || !authToken || !fromNumber) {
      console.warn('SMS not configured — TWILIO_* secrets missing. Skipping.')
      return json({ sent: 0, warning: 'SMS not configured' })
    }

    const db = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const now  = new Date()
    const from = new Date(now.getTime() + 23 * 60 * 60 * 1000).toISOString()
    const to   = new Date(now.getTime() + 25 * 60 * 60 * 1000).toISOString()

    const { data: bookings, error } = await db
      .from('bookings')
      .select('id, client_phone, start_time')
      .eq('status', 'confirmed')
      .eq('sms_reminder_sent', false)
      .not('client_phone', 'is', null)
      .gte('start_time', from)
      .lte('start_time', to)

    if (error) return json({ error: error.message }, 500)
    if (!bookings || bookings.length === 0) return json({ sent: 0 })

    const twilioUrl    = `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`
    const basicAuth    = btoa(`${accountSid}:${authToken}`)
    const authHeader   = `Basic ${basicAuth}`

    const businessName = Deno.env.get('BUSINESS_NAME') ?? 'Us'
    const tz           = Deno.env.get('TIMEZONE')      ?? 'America/New_York'

    // Send all SMS in parallel (best-effort)
    await Promise.allSettled(
      bookings.map((b: { id: string; client_phone: string; start_time: string }) => {
        const apptTime = new Intl.DateTimeFormat('en-US', {
          timeZone: tz,
          hour:     'numeric',
          minute:   '2-digit',
          hour12:   true,
        }).format(new Date(b.start_time))
        const body = `Reminder: your appointment is tomorrow at ${apptTime}. – ${businessName}. Reply STOP to opt out.`

        return fetch(twilioUrl, {
          method:  'POST',
          headers: {
            Authorization:  authHeader,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: new URLSearchParams({ To: b.client_phone, From: fromNumber, Body: body }).toString(),
        })
      })
    )

    // Mark sms_reminder_sent (independent from reminder_sent used by email send-reminders)
    const ids = bookings.map((b: { id: string }) => b.id)
    await db.from('bookings').update({ sms_reminder_sent: true }).in('id', ids)

    return json({ sent: bookings.length })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
