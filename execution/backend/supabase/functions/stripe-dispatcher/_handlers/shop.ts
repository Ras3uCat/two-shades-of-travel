import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe           from 'https://esm.sh/stripe@14?target=deno&no-check'

type DB = ReturnType<typeof createClient>

export async function handleShopOrder(
  session: Stripe.Checkout.Session,
  db: DB,
): Promise<void> {
  const orderId = session.metadata?.order_id
  if (!orderId) {
    console.error('shop: order_id missing from metadata')
    return
  }

  const { data: order } = await db
    .from('shop_orders')
    .update({
      status:                'paid',
      stripe_payment_intent: session.payment_intent as string ?? null,
      updated_at:            new Date().toISOString(),
    })
    .eq('id', orderId)
    .select('client_email, client_name, total_cents, discount_code, shop_order_items(*)')
    .single()

  if (!order) {
    console.error('shop: order not found', orderId)
    return
  }

  const orderItems = (order.shop_order_items ?? []) as Array<{
    product_id: string | null
    quantity:   number
  }>

  for (const item of orderItems) {
    if (!item.product_id) continue
    await db.rpc('decrement_product_inventory', {
      p_product_id: item.product_id,
      p_qty:        item.quantity,
    }).catch(() => { /* non-fatal — product may be unlimited */ })
  }

  if (order.discount_code) {
    await db.rpc('increment_discount_used_count', { p_code: order.discount_code })
      .catch(() => { /* non-fatal */ })
  }

  // TODO: award loyalty points for shop purchase (LOYALTY_ENABLED)
  // TODO: mark gift_voucher as used (GIFT_ENABLED)
  // TODO: send to fulfilment API

  const resendKey = Deno.env.get('RESEND_KEY')
  const fromEmail = Deno.env.get('FROM_EMAIL')  ?? 'noreply@example.com'
  const bizName   = Deno.env.get('BUSINESS_NAME') ?? 'Store'
  const siteUrl   = Deno.env.get('SITE_URL')       ?? ''

  if (resendKey && order.client_email) {
    const itemsList = (orderItems as any[])
      .map((i) => `<li>${i.product_name} × ${i.quantity}</li>`)
      .join('')

    await fetch('https://api.resend.com/emails', {
      method:  'POST',
      headers: { Authorization: `Bearer ${resendKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from:    `${bizName} <${fromEmail}>`,
        to:      order.client_email,
        subject: `Your order from ${bizName} is confirmed!`,
        html: `
          <p>Hi ${order.client_name},</p>
          <p>Thank you for your order! Here's what you ordered:</p>
          <ul>${itemsList}</ul>
          <p><strong>Total: $${((order.total_cents as number) / 100).toFixed(2)}</strong></p>
          <p>We'll be in touch with shipping details soon.</p>
          <p><a href="${siteUrl}/shop">Continue shopping →</a></p>
        `,
      }),
    }).catch(() => { /* non-fatal */ })
  }
}
