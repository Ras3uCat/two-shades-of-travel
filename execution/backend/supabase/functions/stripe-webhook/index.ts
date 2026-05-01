// DEPRECATED — use stripe-dispatcher instead. Kept for reference only.
// stripe-dispatcher handles all Stripe webhook events via a single endpoint.
import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe           from 'https://esm.sh/stripe@14?target=deno&no-check'

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function randomSegment(len: number): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  return Array.from({ length: len }, () => chars[Math.floor(Math.random() * chars.length)]).join('')
}

function generateVoucherCode(): string {
  return `GIFT-${randomSegment(4)}-${randomSegment(4)}`
}

async function sendEmail(
  to: string,
  subject: string,
  text: string,
  resendKey: string,
): Promise<void> {
  await fetch('https://api.resend.com/emails', {
    method:  'POST',
    headers: {
      Authorization:  `Bearer ${resendKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ from: 'noreply@raspucat.com', to, subject, text }),
  })
}

// ---------------------------------------------------------------------------
// Gift voucher fulfillment — triggered when type=gift_voucher in metadata
// ---------------------------------------------------------------------------

async function handleGiftVoucherPurchase(
  session: Stripe.Checkout.Session,
  db: ReturnType<typeof createClient>,
): Promise<void> {
  const { purchased_by_email, recipient_email, amount_cents, message } =
    session.metadata ?? {}

  const code = generateVoucherCode()

  // Expires 1 year from purchase
  const expiresAt = new Date()
  expiresAt.setFullYear(expiresAt.getFullYear() + 1)

  await db.from('gift_vouchers').insert({
    code,
    amount_cents:             Number(amount_cents ?? 0),
    purchased_by_email,
    recipient_email,
    message:                  message ?? '',
    stripe_payment_intent_id: session.payment_intent as string,
    expires_at:               expiresAt.toISOString(),
  })

  const resendKey = Deno.env.get('RESEND_KEY')
  if (!resendKey) return

  const displayAmount = `£${(Number(amount_cents ?? 0) / 100).toFixed(2)}`

  // Email to recipient
  await sendEmail(
    recipient_email!,
    `You've received a ${displayAmount} Gift Voucher!`,
    `Someone special has sent you a gift voucher worth ${displayAmount}.\n\n` +
    `Your voucher code: ${code}\n\n` +
    (message ? `Message: "${message}"\n\n` : '') +
    `Redeem at booking checkout. Valid for 1 year.`,
    resendKey,
  ).catch(() => { /* non-fatal */ })

  // Confirmation to purchaser
  await sendEmail(
    purchased_by_email!,
    `Your Gift Voucher purchase is confirmed`,
    `Thank you! Your ${displayAmount} gift voucher (code: ${code}) has been sent to ${recipient_email}.\n\n` +
    `Keep this email as a record.`,
    resendKey,
  ).catch(() => { /* non-fatal */ })
}

// ---------------------------------------------------------------------------
// Booking confirmation + loyalty + gift-voucher redemption
// ---------------------------------------------------------------------------

async function handleBookingConfirmation(
  session: Stripe.Checkout.Session,
  bookingId: string,
  db: ReturnType<typeof createClient>,
): Promise<void> {
  // Confirm booking
  await db
    .from('bookings')
    .update({
      status:                   'confirmed',
      stripe_payment_intent_id: session.payment_intent as string,
    })
    .eq('id', bookingId)

  // Load booking for downstream logic (total_price, gift_voucher_id, etc.)
  const { data: booking } = await db
    .from('bookings')
    .select('client_email, total_price, gift_voucher_id, loyalty_points_redeemed')
    .eq('id', bookingId)
    .single()

  // Load business config for loyalty settings
  const { data: config } = await db
    .from('business_config')
    .select('loyalty_enabled, loyalty_points_per_dollar')
    .limit(1)
    .single()

  const loyaltyEnabled = config?.loyalty_enabled === true

  if (booking) {
    // Gift voucher redemption (partial coverage via Stripe)
    if (booking.gift_voucher_id) {
      await db
        .from('gift_vouchers')
        .update({
          redeemed_at:              new Date().toISOString(),
          redeemed_by_booking_id:   bookingId,
        })
        .eq('id', booking.gift_voucher_id)
        .is('redeemed_at', null) // idempotency guard
    }

    // Loyalty points earned
    if (loyaltyEnabled) {
      const ptsPerDollar = Number(config?.loyalty_points_per_dollar ?? 1)
      const earned       = Math.floor(Number(booking.total_price) * ptsPerDollar)

      if (earned > 0) {
        await db.from('loyalty_ledger').insert({
          client_email: booking.client_email,
          booking_id:   bookingId,
          points:       earned,
          type:         'earned',
        }).catch(() => { /* non-fatal */ })
      }

      // Loyalty points redeemed
      const redeemed = Number(booking.loyalty_points_redeemed ?? 0)
      if (redeemed > 0) {
        await db.from('loyalty_ledger').insert({
          client_email: booking.client_email,
          booking_id:   bookingId,
          points:       -redeemed,
          type:         'redeemed',
          note:         'Applied at booking',
        }).catch(() => { /* non-fatal */ })
      }
    }
  }

  // Trigger notification emails (best-effort)
  const notifyUrl     = `${Deno.env.get('SUPABASE_URL')}/functions/v1/send-notification`
  const notifyHeaders = {
    Authorization:  `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
    'Content-Type': 'application/json',
  }
  fetch(notifyUrl, {
    method: 'POST', headers: notifyHeaders,
    body: JSON.stringify({ booking_id: bookingId, type: 'confirmation' }),
  }).catch(() => { /* non-fatal */ })
  fetch(notifyUrl, {
    method: 'POST', headers: notifyHeaders,
    body: JSON.stringify({ booking_id: bookingId, type: 'staff_new_booking' }),
  }).catch(() => { /* non-fatal */ })

  // Trigger referral reward check (best-effort)
  fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/process-referral`, {
    method:  'POST',
    headers: {
      Authorization:  `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ booking_id: bookingId }),
  }).catch(() => { /* non-fatal */ })
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

serve(async (req) => {
  const sig  = req.headers.get('stripe-signature') ?? ''
  const body = await req.text()

  const stripe = new Stripe(Deno.env.get('STRIPE_SK')!, { apiVersion: '2024-06-20' })

  let event: Stripe.Event
  try {
    event = stripe.webhooks.constructEvent(body, sig, Deno.env.get('STRIPE_WEBHOOK_SECRET')!)
  } catch (e) {
    return new Response(`Webhook signature error: ${e}`, { status: 400 })
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object as Stripe.Checkout.Session
    const db      = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    if (session.metadata?.type === 'gift_voucher') {
      await handleGiftVoucherPurchase(session, db).catch(console.error)
    } else {
      const bookingId = session.metadata?.booking_id
      if (bookingId) {
        await handleBookingConfirmation(session, bookingId, db).catch(console.error)
      }
    }
  }

  return new Response(JSON.stringify({ received: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
