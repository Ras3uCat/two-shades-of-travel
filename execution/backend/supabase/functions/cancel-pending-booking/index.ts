import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Cancels a booking ONLY if its status is still 'pending' (i.e. Stripe payment was never
// completed). No auth required — the booking_id UUID is the only credential, and it was
// only ever sent to the user who just created the booking via the Stripe cancel_url.
//
// Safe constraints:
//   • Only rows with status = 'pending' are affected (confirmed/completed rows are ignored).
//   • No refund logic — pending bookings were never charged.
//   • No notification — the user cancelled themselves; notifying staff for an unpaid slot
//     would be noise.

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })
  if (req.method !== 'POST')
    return new Response('Method Not Allowed', { status: 405, headers: CORS })

  const { booking_id } = await req.json()
  if (!booking_id)
    return new Response(JSON.stringify({ error: 'booking_id required' }), {
      status: 400, headers: { ...CORS, 'Content-Type': 'application/json' },
    })

  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  const { data, error } = await db
    .from('bookings')
    .update({ status: 'cancelled' })
    .eq('id', booking_id)
    .eq('status', 'pending')   // ← only touches unpaid rows
    .select('id')

  if (error) {
    console.error('cancel-pending-booking error:', error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...CORS, 'Content-Type': 'application/json' },
    })
  }

  const cancelled = (data?.length ?? 0) > 0
  return new Response(JSON.stringify({ cancelled }), {
    headers: { ...CORS, 'Content-Type': 'application/json' },
  })
})
