import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe           from 'https://esm.sh/stripe@14?target=deno&no-check'

type DB = ReturnType<typeof createClient>

export async function handleSubscriptionCheckout(
  session: Stripe.Checkout.Session,
  db: DB,
  stripe: Stripe,
): Promise<void> {
  if (session.mode !== 'subscription') return

  const planId      = session.metadata?.plan_id
  const clientEmail = session.metadata?.client_email ?? session.customer_email ?? ''
  const clientName  = session.metadata?.client_name ?? ''
  const subId       = session.subscription as string

  if (!planId || !clientEmail) return

  const sub = await stripe.subscriptions.retrieve(subId)

  await db.from('subscriptions').upsert(
    {
      plan_id:                planId,
      client_email:           clientEmail,
      client_name:            clientName,
      stripe_subscription_id: subId,
      stripe_customer_id:     session.customer as string,
      status:                 'active',
      current_period_start:   new Date(sub.current_period_start * 1000).toISOString(),
      current_period_end:     new Date(sub.current_period_end   * 1000).toISOString(),
    },
    { onConflict: 'stripe_subscription_id' },
  )

  // TODO: send welcome email via Resend
  // TODO: if plan.booking_discount_pct > 0, record discount entitlement for clientEmail
  // TODO: if plan.included_service_ids.length > 0, create service credit records
}

export async function handleSubscriptionUpdated(
  sub: Stripe.Subscription,
  db: DB,
): Promise<void> {
  const statusMap: Record<string, string> = {
    active:    'active',
    trialing:  'trialing',
    past_due:  'past_due',
    canceled:  'cancelled',
    cancelled: 'cancelled',
  }
  await db.from('subscriptions')
    .update({
      status:               statusMap[sub.status] ?? sub.status,
      current_period_start: new Date(sub.current_period_start * 1000).toISOString(),
      current_period_end:   new Date(sub.current_period_end   * 1000).toISOString(),
    })
    .eq('stripe_subscription_id', sub.id)

  // TODO: notify client if status changed to past_due
}

export async function handleSubscriptionDeleted(
  sub: Stripe.Subscription,
  db: DB,
): Promise<void> {
  await db.from('subscriptions')
    .update({ status: 'cancelled', cancelled_at: new Date().toISOString() })
    .eq('stripe_subscription_id', sub.id)

  // TODO: send cancellation confirmation email
  // TODO: revoke any active discount or included-service credits
}

export async function handleInvoicePaymentFailed(
  invoice: Stripe.Invoice,
  db: DB,
): Promise<void> {
  if (!invoice.subscription) return

  await db.from('subscriptions')
    .update({ status: 'past_due' })
    .eq('stripe_subscription_id', invoice.subscription as string)

  // TODO: email client with payment failure notice + link to update card
}
