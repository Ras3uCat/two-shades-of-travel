// create-event-checkout
// Creates a Stripe Checkout session for event ticket purchases.
// POST { event_id, ticket_type_id, quantity, buyer_email, buyer_name }
//
// Free events (price_cents = 0): confirms immediately, sends email, returns { confirmed, ticket_id, ticket_code }
// Paid events: creates Stripe Checkout session, returns { url }
//
// Uses purchase_event_tickets() Postgres function (row-locked) to prevent overselling.
// Separate Stripe webhook secret: STRIPE_EVENTS_WEBHOOK_SECRET

import { serve }        from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe           from 'https://esm.sh/stripe@14?target=deno&no-check'

const stripe   = new Stripe(Deno.env.get('STRIPE_SK') ?? '', { apiVersion: '2023-10-16' })
const SITE_URL = Deno.env.get('SITE_URL')      ?? 'http://localhost:3000'
const RESEND   = Deno.env.get('RESEND_KEY')    ?? ''
const FROM     = Deno.env.get('FROM_EMAIL')    ?? 'noreply@example.com'
const BIZ      = Deno.env.get('BUSINESS_NAME') ?? 'Events'

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } })

serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 })

  const { event_id, ticket_type_id, quantity, buyer_email, buyer_name } = await req.json()

  if (!event_id || !ticket_type_id || !quantity || !buyer_email || !buyer_name) {
    return json({ error: 'event_id, ticket_type_id, quantity, buyer_email and buyer_name are required' }, 400)
  }

  if (typeof quantity !== 'number' || quantity < 1) {
    return json({ error: 'quantity must be a positive integer' }, 400)
  }

  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  // ── Fetch event + ticket type for display data ────────────────────────────
  const { data: ticketType, error: ttErr } = await db
    .from('event_ticket_types')
    .select('id, name, price_cents, event_id, events(id, title, slug, event_date, venue, status)')
    .eq('id', ticket_type_id)
    .eq('event_id', event_id)
    .single()

  if (ttErr || !ticketType) {
    return json({ error: 'Ticket type not found' }, 404)
  }

  const event = (ticketType.events as unknown) as {
    id: string; title: string; slug: string;
    event_date: string; venue: string | null; status: string
  }

  if (event.status !== 'published') {
    return json({ error: 'This event is not available for purchase' }, 400)
  }

  const priceCents = ticketType.price_cents as number
  const isFree     = priceCents === 0
  const totalCents = priceCents * quantity

  // ── Atomically reserve tickets ────────────────────────────────────────────
  const { data: ticket, error: purchaseErr } = await db.rpc('purchase_event_tickets', {
    p_event_id:       event_id,
    p_ticket_type_id: ticket_type_id,
    p_quantity:       quantity,
    p_buyer_email:    buyer_email,
    p_buyer_name:     buyer_name,
    p_initial_status: isFree ? 'confirmed' : 'pending',
  })

  if (purchaseErr) {
    const msg = purchaseErr.message ?? ''
    if (msg.includes('SOLD_OUT'))              return json({ error: 'Not enough tickets remaining' }, 409)
    if (msg.includes('EVENT_NOT_AVAILABLE'))   return json({ error: 'This event is not available' }, 400)
    if (msg.includes('TICKET_TYPE_NOT_FOUND')) return json({ error: 'Ticket type not found' }, 404)
    console.error('purchase_event_tickets error:', purchaseErr)
    return json({ error: 'Failed to reserve tickets' }, 500)
  }

  const ticketRow = ticket as { id: string; ticket_code: string }

  // ── Free path: confirm immediately + send email ───────────────────────────
  if (isFree) {
    await sendConfirmationEmail({
      buyerName: buyer_name, buyerEmail: buyer_email,
      eventTitle: event.title, eventDate: event.event_date,
      venue: event.venue, ticketType: ticketType.name as string,
      quantity, ticketCode: ticketRow.ticket_code, totalCents,
    })
    return json({ confirmed: true, ticket_id: ticketRow.id, ticket_code: ticketRow.ticket_code })
  }

  // ── Paid path: create Stripe Checkout session ─────────────────────────────
  const eventDate = new Date(event.event_date).toLocaleDateString('en-US', {
    weekday: 'long', year: 'numeric', month: 'long', day: 'numeric',
  })

  const session = await stripe.checkout.sessions.create({
    mode:           'payment',
    customer_email: buyer_email,
    line_items: [{
      quantity,
      price_data: {
        currency:    'usd',
        unit_amount: priceCents,
        product_data: {
          name:        `${event.title} — ${ticketType.name}`,
          description: `${eventDate}${event.venue ? ` · ${event.venue}` : ''}`,
        },
      },
    }],
    success_url: `${SITE_URL}/events/confirmation?ticket_id=${ticketRow.id}&paid=1`,
    cancel_url:  `${SITE_URL}/events/${event.slug}?cancelled_ticket_id=${ticketRow.id}`,
    metadata: {
      type:      'event_ticket',
      ticket_id: ticketRow.id,
    },
  })

  await db.from('event_tickets')
    .update({ stripe_session_id: session.id })
    .eq('id', ticketRow.id)

  return json({ url: session.url })
})

// ── Email helper ──────────────────────────────────────────────────────────────
async function sendConfirmationEmail(opts: {
  buyerName: string; buyerEmail: string; eventTitle: string;
  eventDate: string; venue: string | null; ticketType: string;
  quantity: number; ticketCode: string; totalCents: number
}) {
  if (!RESEND) return

  const dateStr = new Date(opts.eventDate).toLocaleDateString('en-US', {
    weekday: 'long', year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit',
  })
  const codeDisplay = opts.ticketCode.replace(/-/g, '').substring(0, 8).toUpperCase()
  const totalStr    = opts.totalCents === 0 ? 'Free' : `$${(opts.totalCents / 100).toFixed(2)}`

  await fetch('https://api.resend.com/emails', {
    method:  'POST',
    headers: { Authorization: `Bearer ${RESEND}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      from:    `${BIZ} <${FROM}>`,
      to:      opts.buyerEmail,
      subject: `Your ticket for ${opts.eventTitle}`,
      html: `
        <p>Hi ${opts.buyerName},</p>
        <p>You're registered for <strong>${opts.eventTitle}</strong>.</p>
        <table style="border-collapse:collapse;margin:16px 0">
          <tr><td style="padding:4px 12px 4px 0;color:#666">Date</td><td><strong>${dateStr}</strong></td></tr>
          ${opts.venue ? `<tr><td style="padding:4px 12px 4px 0;color:#666">Venue</td><td><strong>${opts.venue}</strong></td></tr>` : ''}
          <tr><td style="padding:4px 12px 4px 0;color:#666">Ticket</td><td>${opts.ticketType} × ${opts.quantity}</td></tr>
          <tr><td style="padding:4px 12px 4px 0;color:#666">Total</td><td>${totalStr}</td></tr>
          <tr><td style="padding:4px 12px 4px 0;color:#666">Ticket code</td><td><strong style="font-size:1.2em;letter-spacing:2px">${codeDisplay}</strong></td></tr>
        </table>
        <p>Please show this code at the door. See you there!</p>
        <p style="color:#999;font-size:0.85em">Full reference: ${opts.ticketCode}</p>
      `,
    }),
  }).catch(() => { /* non-fatal */ })
}
