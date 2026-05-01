// create-shop-checkout
// Creates a Stripe Checkout session for a shop order.
// POST { items: [{product_id, quantity}], client_email, client_name, discount_code? }
// Returns { url }
//
// Discount codes are validated via validate_shop_discount() Postgres function.
// If a discount applies, a single summary line item is passed to Stripe so the
// receipt reflects the discounted total. Individual line items are used otherwise.
//
// TODOs for client-specific integrations:
//   - Gift voucher redemption: validate via gift_vouchers table (GIFT_ENABLED)
//   - Subscription discount: check subscriptions table for active subscriber
//   - Loyalty points preview: show points to be earned at checkout

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import Stripe from 'https://esm.sh/stripe@14?target=deno&no-check';

const stripe   = new Stripe(Deno.env.get('STRIPE_SK') ?? '', { apiVersion: '2023-10-16' });
const SITE_URL = Deno.env.get('SITE_URL') ?? 'http://localhost:3000';

serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 });

  const { items, client_email, client_name, discount_code } = await req.json();

  if (!items?.length || !client_email) {
    return new Response(
      JSON.stringify({ error: 'items and client_email are required' }),
      { status: 400 },
    );
  }

  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  // ── Validate products ────────────────────────────────────────────────────────
  const productIds = (items as Array<{ product_id: string; quantity: number }>)
    .map((i) => i.product_id);

  const { data: products, error: pErr } = await db
    .from('products')
    .select('id, name, price_cents, inventory_count, images')
    .in('id', productIds)
    .eq('is_active', true);

  if (pErr || !products?.length) {
    return new Response(JSON.stringify({ error: 'Products not found' }), { status: 400 });
  }

  const productMap = Object.fromEntries(products.map((p) => [p.id, p]));

  let subtotalCents = 0;
  const lineItemsForStripe: Stripe.Checkout.SessionCreateParams.LineItem[] = [];

  for (const item of items as Array<{ product_id: string; quantity: number }>) {
    const product = productMap[item.product_id];
    if (!product) {
      return new Response(JSON.stringify({ error: `Product not found: ${item.product_id}` }), { status: 400 });
    }
    if (product.inventory_count !== null && product.inventory_count < item.quantity) {
      return new Response(
        JSON.stringify({ error: `Insufficient stock for: ${product.name}` }),
        { status: 400 },
      );
    }
    subtotalCents += (product.price_cents as number) * item.quantity;
    lineItemsForStripe.push({
      quantity: item.quantity,
      price_data: {
        currency:     'usd',
        unit_amount:  product.price_cents as number,
        product_data: {
          name:   product.name as string,
          images: (product.images as string[]).slice(0, 1),
        },
      },
    });
  }

  // ── Validate discount code ───────────────────────────────────────────────────
  let discountCents = 0;
  let validCode: string | null = null;

  if (discount_code) {
    const { data: pct } = await db.rpc('validate_shop_discount', { p_code: discount_code });
    if (pct && (pct as number) > 0) {
      discountCents = Math.round(subtotalCents * (pct as number) / 100);
      validCode     = discount_code as string;
    }
  }

  // TODO: apply gift_voucher_code — validate balance via gift_vouchers table
  // TODO: apply subscription discount for authenticated active subscribers

  const totalCents = subtotalCents - discountCents;

  // ── Create pending order ─────────────────────────────────────────────────────
  const { data: order, error: oErr } = await db
    .from('shop_orders')
    .insert({
      client_email,
      client_name:    client_name ?? '',
      status:         'pending',
      subtotal_cents: subtotalCents,
      discount_cents: discountCents,
      total_cents:    totalCents,
      discount_code:  validCode,
    })
    .select('id')
    .single();

  if (oErr || !order) {
    return new Response(JSON.stringify({ error: 'Failed to create order' }), { status: 500 });
  }

  // Insert order item snapshots
  await db.from('shop_order_items').insert(
    (items as Array<{ product_id: string; quantity: number }>).map((item) => ({
      order_id:     order.id,
      product_id:   item.product_id,
      product_name: productMap[item.product_id].name,
      price_cents:  productMap[item.product_id].price_cents,
      quantity:     item.quantity,
    })),
  );

  // ── Build Stripe line items ──────────────────────────────────────────────────
  // When a discount applies, collapse to a single line item so the receipt total
  // matches exactly. Individual items are used when there is no discount.
  const stripeItems: Stripe.Checkout.SessionCreateParams.LineItem[] =
    discountCents > 0
      ? [{
          quantity: 1,
          price_data: {
            currency:     'usd',
            unit_amount:  totalCents,
            product_data: {
              name: `Order (${lineItemsForStripe.length} item${lineItemsForStripe.length > 1 ? 's' : ''}) — ${validCode} applied`,
            },
          },
        }]
      : lineItemsForStripe;

  const session = await stripe.checkout.sessions.create({
    mode:           'payment',
    customer_email: client_email as string,
    line_items:     stripeItems,
    success_url:    `${SITE_URL}/shop/confirmation?order_id=${order.id}&status=success`,
    cancel_url:     `${SITE_URL}/shop/cart`,
    metadata: {
      order_id: order.id as string,
      type:     'shop_order',
    },
  });

  await db.from('shop_orders')
    .update({ stripe_session_id: session.id })
    .eq('id', order.id as string);

  return new Response(JSON.stringify({ url: session.url }), { status: 200 });
});
