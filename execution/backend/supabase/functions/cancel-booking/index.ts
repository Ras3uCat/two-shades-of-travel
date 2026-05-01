import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe           from 'https://esm.sh/stripe@14?target=deno&no-check'

// Cancels a booking, issues a Stripe refund if applicable, and fires notifications.
// POST body: { booking_id: string, notify_client?: boolean }
// Auth: user JWT (client cancelling own booking) OR admin JWT (master/staff cancelling any)
// notify_client: true when an admin cancels on behalf of the client (default: false)

serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 })

  const authHeader = req.headers.get('Authorization') ?? ''
  const { booking_id, notify_client } = await req.json()

  if (!booking_id) return new Response('booking_id required', { status: 400 })

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const serviceKey  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

  // Verify caller identity via their JWT
  const anonDb = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authHeader } },
  })
  const { data: { user } } = await anonDb.auth.getUser()
  if (!user) return new Response('Unauthorized', { status: 401 })

  // Fetch booking with service role (bypasses RLS)
  const db = createClient(supabaseUrl, serviceKey)
  const { data: booking, error: bErr } = await db
    .from('bookings')
    .select('*')
    .eq('id', booking_id)
    .single()
  if (bErr || !booking) return new Response('Booking not found', { status: 404 })

  // Authorization: master/staff role OR the booking's client_email matches the caller
  const { data: profile } = await db
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()
  const isAdmin = profile?.role === 'master' || profile?.role === 'staff'
  const isOwner = user.email?.toLowerCase() === booking.client_email?.toLowerCase()
  if (!isAdmin && !isOwner) return new Response('Forbidden', { status: 403 })

  if (booking.status === 'cancelled') {
    return new Response(JSON.stringify({ already_cancelled: true }), {
      headers: { 'Content-Type': 'application/json' },
    })
  }

  // Fetch cancellation policy from business_config
  const { data: config } = await db
    .from('business_config')
    .select('cancellation_hours, cancellation_refund_pct')
    .limit(1)
    .single()
  const cancellationHours = (config?.cancellation_hours  as number) ?? 24
  const refundPct         = (config?.cancellation_refund_pct as number) ?? 100

  // Determine whether we are within the cancellation window
  const msUntilStart = new Date(booking.start_time).getTime() - Date.now()
  const withinWindow = msUntilStart < cancellationHours * 3_600_000

  // Server-side enforcement: block client-initiated cancellations within the
  // no-refund window when the business has set refund_pct = 0 (no-cancel policy).
  // Admin can always override.
  if (!isAdmin && withinWindow && refundPct === 0) {
    return new Response(
      JSON.stringify({
        error: `Cancellations are not permitted within ${cancellationHours} hours of your appointment. Please contact us directly.`,
      }),
      { status: 403, headers: { 'Content-Type': 'application/json' } },
    )
  }

  // Determine refund amount (in Stripe cents)
  let refundCents: number | null = null
  const stripeKey = Deno.env.get('STRIPE_SK') ?? ''
  // deposit_pct=0 bookings (pay at appointment) have no stripe_payment_intent_id — skip refund.
  if (booking.stripe_payment_intent_id && stripeKey) {
    // Within window → partial refund per policy; outside window → full refund
    const effectivePct = withinWindow ? refundPct : 100
    if (effectivePct > 0) {
      // total_price is in dollars; dollars × pct/100 × 100 cents/dollar = dollars × pct
      refundCents = Math.round(Number(booking.total_price) * effectivePct)
    }
  }

  // Issue Stripe refund (best-effort — log but don't block the cancellation)
  if (refundCents !== null && refundCents > 0) {
    try {
      const stripe = new Stripe(stripeKey, { apiVersion: '2024-06-20' })
      await stripe.refunds.create({
        payment_intent: booking.stripe_payment_intent_id as string,
        amount:         refundCents,
      })
    } catch (e) {
      console.error('Stripe refund error (cancellation continues):', e)
    }
  }

  // Cancel the booking
  await db.from('bookings').update({ status: 'cancelled' }).eq('id', booking_id)

  // Notifications (best-effort)
  const notifyUrl     = `${supabaseUrl}/functions/v1/send-notification`
  const notifyHeaders = {
    Authorization:  `Bearer ${serviceKey}`,
    'Content-Type': 'application/json',
  }

  // Always notify the assigned artist/staff that a booking was cancelled
  fetch(notifyUrl, {
    method: 'POST',
    headers: notifyHeaders,
    body: JSON.stringify({ booking_id, type: 'staff_cancellation' }),
  }).catch(() => { /* non-fatal */ })

  // Notify the client only when an admin initiates the cancellation
  if (notify_client) {
    fetch(notifyUrl, {
      method: 'POST',
      headers: notifyHeaders,
      body: JSON.stringify({ booking_id, type: 'cancellation' }),
    }).catch(() => { /* non-fatal */ })
  }

  // Waitlist notifications (fire-and-forget, non-fatal)
  try {
    const resendKey = Deno.env.get('RESEND_KEY') ?? ''
    const siteUrl   = Deno.env.get('SITE_URL') ?? ''
    const { data: ap } = await db.from('profiles').select('display_name').eq('id', booking.artist_id).single()
    const artistName   = ap?.display_name ?? 'your artist'
    const { data: wl } = await db.from('waitlist').select('*').eq('artist_id', booking.artist_id).is('notified_at', null)
    if (wl && wl.length > 0 && resendKey) {
      await Promise.allSettled(wl.map((e: { client_email: string; client_name: string }) =>
        fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: { Authorization: `Bearer ${resendKey}`, 'Content-Type': 'application/json' },
          body: JSON.stringify({
            from:    Deno.env.get('FROM_EMAIL') ?? '',
            to:      e.client_email,
            subject: `A slot has opened up — ${artistName}`,
            text:    `Hi ${e.client_name},\n\nA cancellation has freed up availability for ${artistName}.\n\nBook here: ${siteUrl}/booking\n`,
          }),
        })
      ))
      await db.from('waitlist').update({ notified_at: new Date().toISOString() })
        .eq('artist_id', booking.artist_id).is('notified_at', null)
    }
  } catch { /* non-fatal — cancellation already succeeded */ }

  return new Response(
    JSON.stringify({ cancelled: true, refund_cents: refundCents }),
    { headers: { 'Content-Type': 'application/json' } },
  )
})
