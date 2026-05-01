import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe           from 'https://esm.sh/stripe@14?target=deno&no-check'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  })

// Stripe minimum charge is 50 cents
const STRIPE_MIN = 50

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  try {
    const {
      booking_id,
      success_url,
      cancel_url,
      gift_voucher_code,
      loyalty_points_redeem,
      tip_amount_cents,
    } = await req.json()

    if (!booking_id) return json({ error: 'booking_id required' }, 400)

    const stripe = new Stripe(Deno.env.get('STRIPE_SK')!, { apiVersion: '2024-06-20' })
    const db     = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // Load booking + business config in parallel
    const [{ data: booking, error: bookingErr }, { data: config }] = await Promise.all([
      db.from('bookings').select('*').eq('id', booking_id).single(),
      db.from('business_config').select(
        'stripe_mode, deposit_pct, loyalty_cents_per_point, loyalty_enabled, loyalty_points_per_dollar',
      ).limit(1).single(),
    ])

    if (bookingErr || !booking) return json({ error: 'Booking not found' }, 404)
    if (booking.status !== 'pending')
      return json({ error: 'Booking already processed' }, 400)

    // --- Deposit calculation ---
    // deposit_pct 0 = no payment at booking (pay at appointment) — Flutter bypasses this fn.
    // deposit_pct 1–99 = partial deposit; 100 = full charge upfront.
    const depositPct = Number(config?.deposit_pct ?? 100)
    if (depositPct === 0) return json({ error: 'No payment required for this booking' }, 400)
    let chargeAmount = Math.round(Number(booking.total_price) * 100 * depositPct / 100)

    // --- Gift voucher partial coverage ---
    let giftVoucherId: string | null = null
    if (gift_voucher_code) {
      const { data: voucher } = await db
        .from('gift_vouchers')
        .select('id, amount_cents')
        .eq('code', gift_voucher_code)
        .is('redeemed_at', null)
        .gt('expires_at', new Date().toISOString())
        .single()

      if (voucher) {
        giftVoucherId  = voucher.id
        chargeAmount   = Math.max(STRIPE_MIN, chargeAmount - voucher.amount_cents)

        // Attach voucher to booking so webhook can mark it redeemed after payment
        await db
          .from('bookings')
          .update({ gift_voucher_id: voucher.id })
          .eq('id', booking_id)
      }
    }

    // --- Loyalty point redemption ---
    const pointsToRedeem = Number(loyalty_points_redeem ?? 0)
    if (pointsToRedeem > 0) {
      const centsPer      = Number(config?.loyalty_cents_per_point ?? 1)
      const loyaltyDisc   = pointsToRedeem * centsPer
      chargeAmount        = Math.max(STRIPE_MIN, chargeAmount - loyaltyDisc)

      await db
        .from('bookings')
        .update({ loyalty_points_redeemed: pointsToRedeem })
        .eq('id', booking_id)
    }

    // --- Tip / gratuity ---
    const tipCents = Number(tip_amount_cents ?? 0)
    if (tipCents > 0) {
      await db
        .from('bookings')
        .update({ tip_amount: tipCents })
        .eq('id', booking_id)
    }

    const siteUrl = Deno.env.get('SITE_URL') ?? ''

    const sessionParams: Stripe.Checkout.SessionCreateParams = {
      payment_method_types: ['card'],
      mode:                 'payment',
      customer_email:       booking.client_email,
      metadata: {
        booking_id,
        deposit_pct: String(depositPct),
        ...(giftVoucherId ? { gift_voucher_id: giftVoucherId } : {}),
        ...(pointsToRedeem > 0 ? { loyalty_points_redeemed: String(pointsToRedeem) } : {}),
        ...(tipCents > 0 ? { tip_amount_cents: String(tipCents) } : {}),
      },
      line_items: [
        {
          price_data: {
            currency:     'usd',
            product_data: { name: (booking.service_names as string[]).join(', ') },
            unit_amount:  chargeAmount,
          },
          quantity: 1,
        },
        ...(tipCents > 0 ? [{
          price_data: {
            currency:     'usd',
            product_data: { name: 'Gratuity' },
            unit_amount:  tipCents,
          },
          quantity: 1,
        }] : []),
      ],
      success_url:
        success_url ??
        `${siteUrl}/booking/confirmation?booking_id=${booking_id}&paid=1`,
      cancel_url: cancel_url ?? `${siteUrl}/booking`,
    }

    // Connect multi-staff: route payment to artist's Express account
    if (config?.stripe_mode === 'connect_multi_staff') {
      const { data: artist } = await db
        .from('profiles')
        .select('stripe_express_account_id')
        .eq('id', booking.artist_id)
        .single()

      if (artist?.stripe_express_account_id) {
        sessionParams.payment_intent_data = {
          transfer_data: { destination: artist.stripe_express_account_id },
        }
      }
    }

    const session = await stripe.checkout.sessions.create(sessionParams)
    return json({ url: session.url })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
