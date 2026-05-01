import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Cancels 'pending' bookings that have not been paid within 30 minutes.
// Run on a schedule: Supabase → Edge Functions → expire-pending-bookings → Schedule → '*/30 * * * *'
//
// 'pending' bookings are created by book_appointment() when Stripe mode is enabled.
// The stripe-webhook confirms them once payment completes. Unpaid bookings hold the
// slot indefinitely unless this function runs and releases them.

serve(async (_req) => {
  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  const cutoff = new Date(Date.now() - 30 * 60 * 1000).toISOString()

  const { data, error } = await db
    .from('bookings')
    .update({ status: 'cancelled' })
    .eq('status', 'pending')
    .lt('created_at', cutoff)
    .select('id')

  if (error) {
    console.error('expire-pending-bookings error:', error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const expired = data?.length ?? 0
  console.log(`Expired ${expired} pending booking(s)`)
  return new Response(JSON.stringify({ expired }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
