// DEPRECATED — use stripe-dispatcher instead. Kept for reference only.
// stripe-dispatcher handles all Stripe webhook events via a single endpoint.
//
// event-webhook
// Handles Stripe payment confirmation for event ticket purchases.
// Register in Stripe Dashboard → Webhooks with event: checkout.session.completed
// Uses STRIPE_EVENTS_WEBHOOK_SECRET (separate from booking and shop webhooks).

import { serve }        from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe           from 'https://esm.sh/stripe@14?target=deno&no-check'

const stripe         = new Stripe(Deno.env.get('STRIPE_SK') ?? '', { apiVersion: '2023-10-16' })
const WEBHOOK_SECRET = Deno.env.get('STRIPE_EVENTS_WEBHOOK_SECRET') ?? ''
const RESEND         = Deno.env.get('RESEND_KEY')    ?? ''
const FROM           = Deno.env.get('FROM_EMAIL')    ?? 'noreply@example.com'
const BIZ            = Deno.env.get('BUSINESS_NAME') ?? 'Events'

serve(async (req) => {
  const sig  = req.headers.get('stripe-signature') ?? ''
  const body = await req.text()

  let event: Stripe.Event
  try {
    event = stripe.webhooks.constructEvent(body, sig, WEBHOOK_SECRET)
  } catch (_) {
    return new Response('Invalid signature', { status: 400 })
  }

  if (event.type !== 'checkout.session.completed') {
    return new Response(JSON.stringify({ received: true }), { status: 200 })
  }

  const session = event.data.object as Stripe.Checkout.Session

  if (session.metadata?.type !== 'event_ticket') {
    return new Response(JSON.stringify({ received: true }), { status: 200 })
  }

  const ticketId = session.metadata?.ticket_id
  if (!ticketId) {
    return new Response(JSON.stringify({ error: 'ticket_id missing from metadata' }), { status: 400 })
  }

  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  // ── Confirm the ticket ────────────────────────────────────────────────────
  const { data: ticket, error: tErr } = await db
    .from('event_tickets')
    .update({
      status:                'confirmed',
      stripe_payment_intent: session.payment_intent as string ?? null,
      updated_at:            new Date().toISOString(),
    })
    .eq('id', ticketId)
    .select(`
      id, buyer_name, buyer_email, quantity, total_cents, ticket_code,
      ticket_type_id,
      event_ticket_types ( name ),
      events ( title, event_date, venue )
    `)
    .single()

  if (tErr || !ticket) {
    console.error('Failed to confirm ticket:', tErr)
    return new Response(JSON.stringify({ error: 'Ticket not found' }), { status: 404 })
  }

  const ticketType = (ticket.event_ticket_types as unknown) as { name: string }
  const ev         = (ticket.events            as unknown) as {
    title: string; event_date: string; venue: string | null
  }

  // ── Send confirmation email ───────────────────────────────────────────────
  if (RESEND && ticket.buyer_email) {
    const dateStr = new Date(ev.event_date).toLocaleDateString('en-US', {
      weekday: 'long', year: 'numeric', month: 'long',
      day: 'numeric', hour: '2-digit', minute: '2-digit',
    })
    const codeDisplay = (ticket.ticket_code as string).replace(/-/g, '').substring(0, 8).toUpperCase()
    const totalStr    = `$${((ticket.total_cents as number) / 100).toFixed(2)}`

    await fetch('https://api.resend.com/emails', {
      method:  'POST',
      headers: { Authorization: `Bearer ${RESEND}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from:    `${BIZ} <${FROM}>`,
        to:      ticket.buyer_email,
        subject: `Your ticket for ${ev.title}`,
        html: `
          <p>Hi ${ticket.buyer_name},</p>
          <p>Payment confirmed! You're all set for <strong>${ev.title}</strong>.</p>
          <table style="border-collapse:collapse;margin:16px 0">
            <tr><td style="padding:4px 12px 4px 0;color:#666">Date</td><td><strong>${dateStr}</strong></td></tr>
            ${ev.venue ? `<tr><td style="padding:4px 12px 4px 0;color:#666">Venue</td><td><strong>${ev.venue}</strong></td></tr>` : ''}
            <tr><td style="padding:4px 12px 4px 0;color:#666">Ticket</td><td>${ticketType.name} × ${ticket.quantity}</td></tr>
            <tr><td style="padding:4px 12px 4px 0;color:#666">Total paid</td><td>${totalStr}</td></tr>
            <tr><td style="padding:4px 12px 4px 0;color:#666">Ticket code</td><td><strong style="font-size:1.2em;letter-spacing:2px">${codeDisplay}</strong></td></tr>
          </table>
          <p>Please show this code at the door. See you there!</p>
          <p style="color:#999;font-size:0.85em">Full reference: ${ticket.ticket_code}</p>
        `,
      }),
    }).catch(() => { /* non-fatal */ })
  }

  return new Response(JSON.stringify({ received: true, ticket_id: ticketId }), { status: 200 })
})
