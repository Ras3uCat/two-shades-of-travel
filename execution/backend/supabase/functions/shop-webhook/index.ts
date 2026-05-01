// DEPRECATED — use stripe-dispatcher instead. Kept for reference only.
// stripe-dispatcher handles all Stripe webhook events via a single endpoint.
//
// shop-webhook
// Handles Stripe payment events for shop orders.
// Register in Stripe dashboard → Webhooks with these events:
//   checkout.session.completed  (where metadata.type === 'shop_order')
//
// Secret env var: STRIPE_SHOP_WEBHOOK_SECRET
// (separate from STRIPE_WEBHOOK_SECRET used by the booking webhook)
//
// TODOs for client-specific integrations:
//   - Award loyalty points: insert into loyalty_ledger (LOYALTY_ENABLED)
//   - Mark gift voucher used: update gift_vouchers table (GIFT_ENABLED)
//   - Send to fulfilment system / print-on-demand API

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import Stripe from 'https://esm.sh/stripe@14?target=deno&no-check';

const stripe         = new Stripe(Deno.env.get('STRIPE_SK') ?? '', { apiVersion: '2023-10-16' });
const WEBHOOK_SECRET = Deno.env.get('STRIPE_SHOP_WEBHOOK_SECRET') ?? '';
const RESEND_KEY     = Deno.env.get('RESEND_KEY')      ?? '';
const FROM_EMAIL     = Deno.env.get('FROM_EMAIL')      ?? 'noreply@example.com';
const BIZ_NAME       = Deno.env.get('BUSINESS_NAME')   ?? 'Store';
const SITE_URL       = Deno.env.get('SITE_URL')        ?? 'http://localhost:3000';

serve(async (req) => {
  const sig  = req.headers.get('stripe-signature') ?? '';
  const body = await req.text();

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(body, sig, WEBHOOK_SECRET);
  } catch (_) {
    return new Response('Invalid signature', { status: 400 });
  }

  if (event.type !== 'checkout.session.completed') {
    return new Response(JSON.stringify({ received: true }), { status: 200 });
  }

  const session = event.data.object as Stripe.Checkout.Session;
  if (session.metadata?.type !== 'shop_order') {
    return new Response(JSON.stringify({ received: true }), { status: 200 });
  }

  const orderId = session.metadata?.order_id;
  if (!orderId) {
    return new Response(JSON.stringify({ error: 'order_id missing from metadata' }), { status: 400 });
  }

  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  // ── Mark order paid ──────────────────────────────────────────────────────────
  const { data: order } = await db
    .from('shop_orders')
    .update({
      status:                 'paid',
      stripe_payment_intent:  session.payment_intent as string ?? null,
      updated_at:             new Date().toISOString(),
    })
    .eq('id', orderId)
    .select('client_email, client_name, total_cents, discount_code, shop_order_items(*)')
    .single();

  if (!order) {
    return new Response(JSON.stringify({ error: 'Order not found' }), { status: 404 });
  }

  // ── Decrement inventory ──────────────────────────────────────────────────────
  const orderItems = (order.shop_order_items ?? []) as Array<{
    product_id: string | null;
    quantity:   number;
  }>;

  for (const item of orderItems) {
    if (!item.product_id) continue;
    await db.rpc('decrement_product_inventory', {
      p_product_id: item.product_id,
      p_qty:        item.quantity,
    }).catch(() => { /* non-fatal — product may be unlimited */ });
  }

  // ── Increment discount code usage ────────────────────────────────────────────
  if (order.discount_code) {
    await db.rpc('increment_discount_used_count', { p_code: order.discount_code })
      .catch(() => { /* non-fatal */ });
  }

  // TODO: award loyalty points for shop purchase (LOYALTY_ENABLED)
  // await db.from('loyalty_ledger').insert({
  //   client_email: order.client_email,
  //   points: Math.floor((order.total_cents / 100) * LOYALTY_POINTS_PER_DOLLAR),
  //   source: 'shop_order', source_id: orderId,
  // }).catch(() => {});

  // TODO: mark gift_voucher as used (GIFT_ENABLED)
  // TODO: send to fulfilment API

  // ── Send confirmation email ──────────────────────────────────────────────────
  if (RESEND_KEY && order.client_email) {
    const itemsList = orderItems
      .map((i: any) => `<li>${i.product_name} × ${i.quantity}</li>`)
      .join('');

    await fetch('https://api.resend.com/emails', {
      method:  'POST',
      headers: {
        Authorization:  `Bearer ${RESEND_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from:    `${BIZ_NAME} <${FROM_EMAIL}>`,
        to:      order.client_email,
        subject: `Your order from ${BIZ_NAME} is confirmed!`,
        html: `
          <p>Hi ${order.client_name},</p>
          <p>Thank you for your order! Here's what you ordered:</p>
          <ul>${itemsList}</ul>
          <p><strong>Total: $${((order.total_cents as number) / 100).toFixed(2)}</strong></p>
          <p>We'll be in touch with shipping details soon.</p>
          <p><a href="${SITE_URL}/shop">Continue shopping →</a></p>
        `,
      }),
    }).catch(() => { /* non-fatal */ });
  }

  return new Response(JSON.stringify({ received: true, orderId }), { status: 200 });
});
