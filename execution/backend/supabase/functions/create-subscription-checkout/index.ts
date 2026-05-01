// create-subscription-checkout
// Creates a Stripe Checkout session in 'subscription' mode for a given plan.
// Returns { url } on success.
//
// POST body: { plan_id, client_email, client_name? }
//
// If the plan has no stripe_price_id yet (not configured in Stripe dashboard),
// returns a 400 with a clear message so the admin knows what to do next.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import Stripe from 'https://esm.sh/stripe@14?target=deno&no-check';

const stripe   = new Stripe(Deno.env.get('STRIPE_SK') ?? '', { apiVersion: '2023-10-16' });
const SITE_URL = Deno.env.get('SITE_URL') ?? 'http://localhost:3000';

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const { plan_id, client_email, client_name } = await req.json();

  if (!plan_id || !client_email) {
    return new Response(
      JSON.stringify({ error: 'plan_id and client_email are required' }),
      { status: 400 },
    );
  }

  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { data: plan, error } = await db
    .from('subscription_plans')
    .select('id, name, stripe_price_id')
    .eq('id', plan_id)
    .eq('is_active', true)
    .single();

  if (error || !plan) {
    return new Response(JSON.stringify({ error: 'Plan not found' }), { status: 404 });
  }

  if (!plan.stripe_price_id) {
    return new Response(
      JSON.stringify({
        error: 'This plan is not yet configured for online payment. ' +
               'Create a Product + Price in the Stripe dashboard and paste the ' +
               'Price ID into the plan record (stripe_price_id).',
      }),
      { status: 400 },
    );
  }

  const session = await stripe.checkout.sessions.create({
    mode:           'subscription',
    customer_email: client_email as string,
    line_items:     [{ price: plan.stripe_price_id as string, quantity: 1 }],
    success_url:    `${SITE_URL}/subscriptions?subscribed=1`,
    cancel_url:     `${SITE_URL}/subscriptions`,
    metadata: {
      plan_id:      plan.id as string,
      client_email: client_email as string,
      client_name:  (client_name ?? '') as string,
    },
  });

  return new Response(JSON.stringify({ url: session.url }), { status: 200 });
});
