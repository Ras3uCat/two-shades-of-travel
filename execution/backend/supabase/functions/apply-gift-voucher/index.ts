import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  })

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  try {
    const { booking_id, gift_voucher_code } = await req.json()
    if (!booking_id)        return json({ error: 'booking_id required' }, 400)
    if (!gift_voucher_code) return json({ error: 'gift_voucher_code required' }, 400)

    const db = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // Load active voucher and pending booking in parallel
    const [{ data: voucher }, { data: booking }] = await Promise.all([
      db
        .from('gift_vouchers')
        .select('*')
        .eq('code', gift_voucher_code)
        .is('redeemed_at', null)
        .gt('expires_at', new Date().toISOString())
        .single(),
      db
        .from('bookings')
        .select('*')
        .eq('id', booking_id)
        .eq('status', 'pending')
        .single(),
    ])

    if (!voucher) return json({ error: 'Gift voucher not found or already used' }, 400)
    if (!booking) return json({ error: 'Booking not found or not pending' }, 400)

    const bookingCents = Math.round(Number(booking.total_price) * 100)

    // Voucher covers less than the total — caller must use Stripe for the remainder
    if (voucher.amount_cents < bookingCents) {
      return json({ needs_stripe: true, shortfall_cents: bookingCents - voucher.amount_cents })
    }

    // Full coverage — confirm booking and mark voucher redeemed atomically (best-effort serial)
    const { error: bookingErr } = await db
      .from('bookings')
      .update({ status: 'confirmed', gift_voucher_id: voucher.id })
      .eq('id', booking_id)

    if (bookingErr) return json({ error: bookingErr.message }, 500)

    const { error: voucherErr } = await db
      .from('gift_vouchers')
      .update({ redeemed_at: new Date().toISOString(), redeemed_by_booking_id: booking_id })
      .eq('id', voucher.id)

    if (voucherErr) return json({ error: voucherErr.message }, 500)

    return json({ confirmed: true })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
