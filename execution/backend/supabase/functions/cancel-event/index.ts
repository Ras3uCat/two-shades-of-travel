// cancel-event
// Admin cancels an event. Marks all tickets cancelled and issues Stripe refunds.
// POST { event_id }
// Auth: master JWT required.

import { serve }        from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe           from 'https://esm.sh/stripe@14?target=deno&no-check'

const stripe = new Stripe(Deno.env.get('STRIPE_SK') ?? '', { apiVersion: '2023-10-16' })
const RESEND = Deno.env.get('RESEND_KEY')    ?? ''
const FROM   = Deno.env.get('FROM_EMAIL')    ?? 'noreply@example.com'
const BIZ    = Deno.env.get('BUSINESS_NAME') ?? 'Events'

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } })

serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 })

  const authHeader = req.headers.get('Authorization') ?? ''
  const { event_id } = await req.json()

  if (!event_id) return json({ error: 'event_id required' }, 400)

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const serviceKey  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

  // ── Verify caller is a master user ────────────────────────────────────────
  const anonDb = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authHeader } },
  })
  const { data: { user } } = await anonDb.auth.getUser()
  if (!user) return json({ error: 'Unauthorized' }, 401)

  const db = createClient(supabaseUrl, serviceKey)

  const { data: profile } = await db
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (profile?.role !== 'master') return json({ error: 'Forbidden' }, 403)

  // ── Fetch event ───────────────────────────────────────────────────────────
  const { data: event, error: evErr } = await db
    .from('events')
    .select('id, title, status')
    .eq('id', event_id)
    .single()

  if (evErr || !event) return json({ error: 'Event not found' }, 404)

  if (event.status === 'cancelled') {
    return json({ already_cancelled: true })
  }

  // ── Mark event cancelled ──────────────────────────────────────────────────
  await db.from('events').update({ status: 'cancelled' }).eq('id', event_id)

  // ── Cancel all tickets + collect payment intents for refunds ─────────────
  const { data: cancelled } = await db.rpc('cancel_event_tickets', { p_event_id: event_id })

  const rows = (cancelled ?? []) as Array<{
    ticket_id: string; stripe_payment_intent: string | null; total_cents: number
  }>

  // ── Issue Stripe refunds (best-effort) ────────────────────────────────────
  let refundsIssued = 0
  const stripeKey   = Deno.env.get('STRIPE_SK') ?? ''

  if (stripeKey) {
    for (const row of rows) {
      if (!row.stripe_payment_intent) continue
      try {
        const refund = await stripe.refunds.create({
          payment_intent: row.stripe_payment_intent,
          reason:         'requested_by_customer',
        })
        await db.from('event_tickets')
          .update({ stripe_refund_id: refund.id })
          .eq('id', row.ticket_id)
        refundsIssued++
      } catch (e) {
        console.error(`Refund failed for ticket ${row.ticket_id}:`, e)
        // non-fatal — continue with remaining tickets
      }
    }
  }

  // ── Email unique buyers (best-effort) ────────────────────────────────────
  if (RESEND) {
    const buyerEmails = await db
      .from('event_tickets')
      .select('buyer_email, buyer_name')
      .eq('event_id', event_id)
      .eq('status', 'cancelled')

    const seen  = new Set<string>()
    const buyers = (buyerEmails.data ?? []) as Array<{ buyer_email: string; buyer_name: string }>

    await Promise.allSettled(
      buyers
        .filter((b) => { if (seen.has(b.buyer_email)) return false; seen.add(b.buyer_email); return true })
        .map((b) =>
          fetch('https://api.resend.com/emails', {
            method:  'POST',
            headers: { Authorization: `Bearer ${RESEND}`, 'Content-Type': 'application/json' },
            body: JSON.stringify({
              from:    `${BIZ} <${FROM}>`,
              to:      b.buyer_email,
              subject: `Event cancelled: ${event.title}`,
              html: `
                <p>Hi ${b.buyer_name},</p>
                <p>We're sorry to let you know that <strong>${event.title}</strong> has been cancelled.</p>
                <p>If you purchased tickets, a full refund has been issued to your original payment method.
                   Please allow 5–10 business days for it to appear.</p>
                <p>We apologise for any inconvenience.</p>
                <p>${BIZ}</p>
              `,
            }),
          })
        )
    )
  }

  return json({ cancelled: true, refunds_issued: refundsIssued })
})
