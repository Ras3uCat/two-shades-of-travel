import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe           from 'https://esm.sh/stripe@14?target=deno&no-check'

type DB = ReturnType<typeof createClient>

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
    headers: { Authorization: `Bearer ${resendKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ from: 'noreply@raspucat.com', to, subject, text }),
  })
}

// ---------------------------------------------------------------------------
// Gift voucher fulfillment
// ---------------------------------------------------------------------------

export async function handleGiftVoucherPurchase(
  session: Stripe.Checkout.Session,
  db: DB,
): Promise<void> {
  const { purchased_by_email, recipient_email, amount_cents, message } =
    session.metadata ?? {}

  const code      = generateVoucherCode()
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

  await sendEmail(
    recipient_email!,
    `You've received a ${displayAmount} Gift Voucher!`,
    `Someone special has sent you a gift voucher worth ${displayAmount}.\n\n` +
    `Your voucher code: ${code}\n\n` +
    (message ? `Message: "${message}"\n\n` : '') +
    `Redeem at booking checkout. Valid for 1 year.`,
    resendKey,
  ).catch(() => { /* non-fatal */ })

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

export async function handleBookingConfirmation(
  session: Stripe.Checkout.Session,
  bookingId: string,
  db: DB,
): Promise<void> {
  await db
    .from('bookings')
    .update({
      status:                   'confirmed',
      stripe_payment_intent_id: session.payment_intent as string,
    })
    .eq('id', bookingId)

  const { data: booking } = await db
    .from('bookings')
    .select('client_email, total_price, gift_voucher_id, loyalty_points_redeemed')
    .eq('id', bookingId)
    .single()

  const { data: config } = await db
    .from('business_config')
    .select('loyalty_enabled, loyalty_points_per_dollar')
    .limit(1)
    .single()

  if (booking) {
    if (booking.gift_voucher_id) {
      await db
        .from('gift_vouchers')
        .update({ redeemed_at: new Date().toISOString(), redeemed_by_booking_id: bookingId })
        .eq('id', booking.gift_voucher_id)
        .is('redeemed_at', null)
    }

    if (config?.loyalty_enabled === true) {
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

  fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/process-referral`, {
    method:  'POST',
    headers: {
      Authorization:  `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ booking_id: bookingId }),
  }).catch(() => { /* non-fatal */ })

  if (Deno.env.get('INVOICES_ENABLED') === 'true') {
    fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/generate-invoice`, {
      method:  'POST',
      headers: {
        Authorization:  `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ booking_id: bookingId }),
    }).catch(console.error)
  }
}
