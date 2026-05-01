import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// No auth required. Validates booking review_token before inserting.
// POST body: { booking_id, token, rating, comment? }

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
    const { booking_id, token, rating, comment } = await req.json()

    if (!booking_id || !token)       return json({ error: 'booking_id and token required' }, 400)
    if (!rating || rating < 1 || rating > 5) return json({ error: 'rating must be 1–5' }, 400)

    const db = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // Load booking and verify token
    const { data: booking, error: bErr } = await db
      .from('bookings')
      .select('review_token, client_email, client_name')
      .eq('id', booking_id)
      .single()

    if (bErr || !booking) return json({ error: 'Booking not found' }, 404)
    if (booking.review_token !== token) return json({ error: 'Invalid token' }, 403)

    // Prevent duplicate reviews
    const { data: existing } = await db
      .from('reviews')
      .select('id')
      .eq('booking_id', booking_id)
      .maybeSingle()

    if (existing) return json({ error: 'Review already submitted' }, 409)

    // Insert review — pending admin approval
    const { error: iErr } = await db.from('reviews').insert({
      booking_id,
      client_email: booking.client_email,
      client_name:  booking.client_name,
      rating:       Number(rating),
      comment:      comment ?? null,
      is_approved:  false,
    })

    if (iErr) return json({ error: iErr.message }, 500)

    return json({ success: true })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
