import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Scheduled Edge Function — call daily via Supabase dashboard cron or pg_cron.
// Queries bookings whose appointment is 23–25 hours away and sends reminder emails.
// Setup: Supabase dashboard → Edge Functions → send-reminders → Schedule → "0 10 * * *"

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

serve(async () => {
  try {
    const db = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const now     = new Date()
    const from    = new Date(now.getTime() + 23 * 60 * 60 * 1000).toISOString()
    const to      = new Date(now.getTime() + 25 * 60 * 60 * 1000).toISOString()

    const { data: bookings, error } = await db
      .from('bookings')
      .select('id')
      .eq('status', 'confirmed')
      .eq('reminder_sent', false)
      .gte('start_time', from)
      .lte('start_time', to)

    if (error) return json({ error: error.message }, 500)
    if (!bookings || bookings.length === 0) return json({ sent: 0 })

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceKey  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    // Fire all reminder emails in parallel (best-effort)
    await Promise.allSettled(
      bookings.map((b: { id: string }) =>
        fetch(`${supabaseUrl}/functions/v1/send-notification`, {
          method:  'POST',
          headers: {
            Authorization:  `Bearer ${serviceKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ booking_id: b.id, type: 'reminder' }),
        })
      )
    )

    // Mark reminders as sent
    const ids = bookings.map((b: { id: string }) => b.id)
    await db.from('bookings').update({ reminder_sent: true }).in('id', ids)

    return json({ sent: bookings.length })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
