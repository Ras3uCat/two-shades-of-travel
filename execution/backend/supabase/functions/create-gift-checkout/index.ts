import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import Stripe           from 'https://esm.sh/stripe@14?target=deno&no-check'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  })

const isValidEmail = (v: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v)

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  try {
    const { amount_cents, purchased_by_email, recipient_email, message } =
      await req.json()

    // --- Input validation ---
    if (typeof amount_cents !== 'number' || amount_cents < 500 || amount_cents > 100_000)
      return json({ error: 'amount_cents must be between 500 and 100000' }, 400)
    if (!purchased_by_email || !isValidEmail(purchased_by_email))
      return json({ error: 'Invalid purchased_by_email' }, 400)
    if (!recipient_email || !isValidEmail(recipient_email))
      return json({ error: 'Invalid recipient_email' }, 400)

    const stripe  = new Stripe(Deno.env.get('STRIPE_SK')!, { apiVersion: '2024-06-20' })
    const siteUrl = Deno.env.get('SITE_URL') ?? ''

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      mode:                 'payment',
      customer_email:       purchased_by_email,
      metadata: {
        type:                'gift_voucher',
        purchased_by_email,
        recipient_email,
        amount_cents:        String(amount_cents),
        message:             message ?? '',
      },
      line_items: [
        {
          price_data: {
            currency:     'gbp',
            product_data: { name: 'Gift Voucher' },
            unit_amount:  amount_cents,
          },
          quantity: 1,
        },
      ],
      success_url: `${siteUrl}/gift/success`,
      cancel_url:  `${siteUrl}/gift`,
    })

    return json({ url: session.url })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
