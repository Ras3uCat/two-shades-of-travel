import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe           from 'https://esm.sh/stripe@14?target=deno&no-check'

type DB = ReturnType<typeof createClient>

export async function handleEventTicket(
  session: Stripe.Checkout.Session,
  db: DB,
): Promise<void> {
  const ticketId = session.metadata?.ticket_id
  if (!ticketId) {
    console.error('event: ticket_id missing from metadata')
    return
  }

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
    console.error('event: ticket not found', tErr)
    return
  }

  const ticketType = (ticket.event_ticket_types as unknown) as { name: string }
  const ev         = (ticket.events as unknown) as {
    title: string; event_date: string; venue: string | null
  }

  const resendKey = Deno.env.get('RESEND_KEY')
  const fromEmail = Deno.env.get('FROM_EMAIL')    ?? 'noreply@example.com'
  const bizName   = Deno.env.get('BUSINESS_NAME') ?? 'Events'

  if (resendKey && ticket.buyer_email) {
    const dateStr = new Date(ev.event_date).toLocaleDateString('en-US', {
      weekday: 'long', year: 'numeric', month: 'long',
      day: 'numeric', hour: '2-digit', minute: '2-digit',
    })
    const codeDisplay = (ticket.ticket_code as string).replace(/-/g, '').substring(0, 8).toUpperCase()
    const totalStr    = `$${((ticket.total_cents as number) / 100).toFixed(2)}`

    await fetch('https://api.resend.com/emails', {
      method:  'POST',
      headers: { Authorization: `Bearer ${resendKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from:    `${bizName} <${fromEmail}>`,
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
}
