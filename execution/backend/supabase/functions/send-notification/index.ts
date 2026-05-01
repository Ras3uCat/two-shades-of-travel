import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Booking notification emails — confirmation, cancellation, reminder.
// POST body: { booking_id: string, type: 'confirmation' | 'cancellation' | 'reminder' }

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  })

const SUBJECTS: Record<string, string> = {
  confirmation:       'Your appointment is confirmed',
  cancellation:       'Your appointment has been cancelled',
  reminder:           'Your appointment is tomorrow',
  review_request:     'How was your appointment?',
  staff_new_booking:  'New booking received',
  staff_cancellation: 'A booking has been cancelled',
}

function formatDateTime(iso: string, tz: string): string {
  try {
    return new Intl.DateTimeFormat('en-US', {
      timeZone:     tz,
      weekday:      'long',
      month:        'long',
      day:          'numeric',
      hour:         'numeric',
      minute:       '2-digit',
      hour12:       true,
    }).format(new Date(iso))
  } catch {
    return iso
  }
}

function buildHtml(
  type:         string,
  clientName:   string,
  artistName:   string,
  serviceNames: string[],
  totalPrice:   number,
  startTime:    string,
  endTime:      string,
  businessName: string,
  tz:           string,
  reviewUrl?:   string,
): string {
  const dateStr  = formatDateTime(startTime, tz)
  const services = serviceNames.join(', ')
  const price    = `$${totalPrice.toFixed(0)}`

  if (type === 'confirmation') {
    return `
      <p>Hi ${clientName},</p>
      <p>Your appointment is confirmed. Here are the details:</p>
      <table cellpadding="4" style="border-collapse:collapse;width:100%;max-width:480px">
        <tr><td style="color:#888;width:120px">Date & Time</td><td>${dateStr}</td></tr>
        <tr><td style="color:#888">Artist</td><td>${artistName}</td></tr>
        <tr><td style="color:#888">Services</td><td>${services}</td></tr>
        <tr><td style="color:#888">Total</td><td>${price}</td></tr>
      </table>
      <p>We look forward to seeing you soon.</p>
      <p>— ${businessName}</p>
    `
  }

  if (type === 'cancellation') {
    return `
      <p>Hi ${clientName},</p>
      <p>Your appointment on <strong>${dateStr}</strong> with ${artistName} has been cancelled.</p>
      <p>If you have questions or would like to rebook, please contact us.</p>
      <p>— ${businessName}</p>
    `
  }

  if (type === 'reminder') {
    return `
      <p>Hi ${clientName},</p>
      <p>Just a reminder — your appointment is tomorrow:</p>
      <table cellpadding="4" style="border-collapse:collapse;width:100%;max-width:480px">
        <tr><td style="color:#888;width:120px">Date & Time</td><td>${dateStr}</td></tr>
        <tr><td style="color:#888">Artist</td><td>${artistName}</td></tr>
        <tr><td style="color:#888">Services</td><td>${services}</td></tr>
      </table>
      <p>See you then!</p>
      <p>— ${businessName}</p>
    `
  }

  if (type === 'staff_new_booking') {
    return `
      <p>You have a new booking:</p>
      <table cellpadding="4" style="border-collapse:collapse;width:100%;max-width:480px">
        <tr><td style="color:#888;width:120px">Client</td><td>${clientName}</td></tr>
        <tr><td style="color:#888">Date & Time</td><td>${dateStr}</td></tr>
        <tr><td style="color:#888">Services</td><td>${services}</td></tr>
        <tr><td style="color:#888">Total</td><td>${price}</td></tr>
      </table>
      <p>— ${businessName} booking system</p>
    `
  }

  if (type === 'review_request') {
    return `
      <p>Hi ${clientName},</p>
      <p>We hope you enjoyed your appointment with <strong>${artistName}</strong>. We'd love to hear how it went!</p>
      <p style="margin-top:20px">
        <a href="${reviewUrl ?? '#'}" style="display:inline-block;padding:12px 24px;background:#111;color:#fff;text-decoration:none;border-radius:6px">
          Leave a Review
        </a>
      </p>
      <p style="margin-top:16px;color:#888;font-size:13px">Or copy this link: ${reviewUrl ?? ''}</p>
      <p>— ${businessName}</p>
    `
  }

  // staff_cancellation
  return `
    <p>A booking with you has been cancelled by the client:</p>
    <table cellpadding="4" style="border-collapse:collapse;width:100%;max-width:480px">
      <tr><td style="color:#888;width:120px">Client</td><td>${clientName}</td></tr>
      <tr><td style="color:#888">Date & Time</td><td>${dateStr}</td></tr>
      <tr><td style="color:#888">Services</td><td>${services}</td></tr>
    </table>
    <p>— ${businessName} booking system</p>
  `
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  try {
    const { booking_id, type } = await req.json()

    const validTypes = ['confirmation', 'cancellation', 'reminder', 'review_request', 'staff_new_booking', 'staff_cancellation']
    if (!booking_id || !type) return json({ error: 'booking_id and type required' }, 400)
    if (!validTypes.includes(type)) {
      return json({ error: `type must be one of: ${validTypes.join(' | ')}` }, 400)
    }

    const resendKey = Deno.env.get('RESEND_KEY') ?? ''
    if (!resendKey) return json({ error: 'RESEND_KEY not configured' }, 500)

    const db = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // Load booking + artist name + business config in parallel
    const [{ data: booking, error: bErr }, { data: config }] = await Promise.all([
      db
        .from('bookings')
        .select('*, profiles(display_name)')
        .eq('id', booking_id)
        .single(),
      db.from('business_config').select('*').limit(1).single(),
    ])

    if (bErr || !booking) return json({ error: 'Booking not found' }, 404)

    const businessName = Deno.env.get('BUSINESS_NAME') ?? config?.name ?? 'Us'
    const fromEmail    = Deno.env.get('FROM_EMAIL')    ?? 'hello@example.com'
    const tz           = Deno.env.get('TIMEZONE')      ?? config?.timezone ?? 'America/New_York'
    const siteUrl      = Deno.env.get('SITE_URL')      ?? ''
    const artistName   = (booking.profiles as { display_name: string } | null)?.display_name ?? 'your artist'

    const reviewUrl = type === 'review_request'
      ? `${siteUrl}/review?booking_id=${booking.id}&token=${booking.review_token}`
      : undefined

    const html = buildHtml(
      type,
      booking.client_name,
      artistName,
      booking.service_names as string[],
      Number(booking.total_price),
      booking.start_time,
      booking.end_time,
      businessName,
      tz,
      reviewUrl,
    )

    // Staff types send to the artist's auth email, not the client email
    const isStaffType = type === 'staff_new_booking' || type === 'staff_cancellation'
    let toEmail = booking.client_email
    if (isStaffType) {
      const { data: { user: artist } } = await db.auth.admin.getUserById(booking.artist_id)
      toEmail = artist?.email ?? booking.client_email
    }

    const res = await fetch('https://api.resend.com/emails', {
      method:  'POST',
      headers: {
        Authorization:  `Bearer ${resendKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from:    `${businessName} <${fromEmail}>`,
        to:      [toEmail],
        subject: `${SUBJECTS[type]} — ${businessName}`,
        html,
      }),
    })

    if (!res.ok) {
      const err = await res.text()
      return json({ error: `Resend error: ${err}` }, 500)
    }

    // Fire push notifications best-effort (don't await, don't block email response)
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceKey  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const pushHeaders = { Authorization: `Bearer ${serviceKey}`, 'Content-Type': 'application/json' }

    // Confirmation SMS — best-effort, gates on Twilio secret presence
    if (type === 'confirmation' && booking.client_phone) {
      const twilioSid   = Deno.env.get('TWILIO_ACCOUNT_SID') ?? ''
      const twilioToken = Deno.env.get('TWILIO_AUTH_TOKEN')  ?? ''
      const twilioFrom  = Deno.env.get('TWILIO_FROM_NUMBER') ?? ''
      if (twilioSid && twilioToken && twilioFrom) {
        const smsBody = `Hi ${booking.client_name}, your appointment on ${formatDateTime(booking.start_time, tz)} is confirmed. – ${businessName}`
        fetch(`https://api.twilio.com/2010-04-01/Accounts/${twilioSid}/Messages.json`, {
          method:  'POST',
          headers: {
            Authorization:  `Basic ${btoa(`${twilioSid}:${twilioToken}`)}`,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: new URLSearchParams({ To: booking.client_phone, From: twilioFrom, Body: smsBody }).toString(),
        }).catch(() => {})
      }
    }

    if (type === 'reminder') {
      fetch(`${supabaseUrl}/functions/v1/send-push`, {
        method: 'POST', headers: pushHeaders,
        body: JSON.stringify({
          client_email: booking.client_email,
          title: 'Appointment reminder',
          body:  `Your appointment is tomorrow at ${formatDateTime(booking.start_time, tz)}`,
          url:   `${siteUrl}/profile`,
        }),
      }).catch(() => {})
    }

    if (type === 'staff_new_booking') {
      fetch(`${supabaseUrl}/functions/v1/send-push`, {
        method: 'POST', headers: pushHeaders,
        body: JSON.stringify({
          user_id: booking.artist_id,
          title:   'New booking',
          body:    `New booking from ${booking.client_name}`,
          url:     `${siteUrl}/admin/bookings`,
        }),
      }).catch(() => {})
    }

    return json({ ok: true, type, booking_id })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
