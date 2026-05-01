import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe           from 'https://esm.sh/stripe@14?target=deno&no-check'

// Admin-only Edge Function — creates and emails a Stripe-hosted invoice to the client.
// Requires master JWT. STRIPE_INVOICING_ENABLED feature flag.

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
    // ── Auth ────────────────────────────────────────────────────────────────
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return json({ error: 'Unauthorized' }, 401)

    const anonClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    )
    const { data: { user } } = await anonClient.auth.getUser()
    if (!user) return json({ error: 'Unauthorized' }, 401)

    const db = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const { data: profile } = await db
      .from('profiles')
      .select('role')
      .eq('user_id', user.id)
      .single()
    if (profile?.role !== 'master') return json({ error: 'Forbidden' }, 403)

    // ── Request ─────────────────────────────────────────────────────────────
    const { booking_id } = await req.json()
    if (!booking_id) return json({ error: 'booking_id required' }, 400)

    const { data: booking, error: bErr } = await db
      .from('bookings')
      .select('*')
      .eq('id', booking_id)
      .single()
    if (bErr || !booking) return json({ error: 'Booking not found' }, 404)
    if (booking.status !== 'confirmed') {
      return json({ error: 'Booking must be confirmed to invoice' }, 400)
    }

    // ── Stripe ──────────────────────────────────────────────────────────────
    const stripe = new Stripe(Deno.env.get('STRIPE_SK')!, { apiVersion: '2024-06-20' })

    // Create or retrieve customer by email
    const existing  = await stripe.customers.list({ email: booking.client_email, limit: 1 })
    const customer  = existing.data[0] ?? await stripe.customers.create({
      email: booking.client_email,
      name:  booking.client_name,
    })

    // Create invoice, add line item, finalize, send
    const invoice = await stripe.invoices.create({
      customer:     customer.id,
      auto_advance: false,
    })

    await stripe.invoiceItems.create({
      customer:    customer.id,
      invoice:     invoice.id,
      description: (booking.service_names as string[]).join(', '),
      amount:      Math.round(Number(booking.total_price) * 100),
      currency:    'usd',
    })

    const finalized = await stripe.invoices.finalizeInvoice(invoice.id)
    await stripe.invoices.sendInvoice(invoice.id)

    // ── Persist ─────────────────────────────────────────────────────────────
    await db.from('bookings').update({
      stripe_invoice_id:  finalized.id,
      stripe_invoice_url: finalized.hosted_invoice_url,
      invoice_sent_at:    new Date().toISOString(),
    }).eq('id', booking_id)

    return json({ invoice_url: finalized.hosted_invoice_url })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
