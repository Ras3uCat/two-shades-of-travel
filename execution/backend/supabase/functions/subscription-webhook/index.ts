// DEPRECATED — use stripe-dispatcher instead. Kept for reference only.
// stripe-dispatcher handles all Stripe webhook events via a single endpoint.
//
// subscription-webhook
// Handles Stripe subscription lifecycle events.
// Register in Stripe dashboard → Webhooks with these events:
//   checkout.session.completed  (mode: subscription)
//   customer.subscription.updated
//   customer.subscription.deleted
//   invoice.payment_failed
//
// Secret env var: STRIPE_SUBSCRIPTION_WEBHOOK_SECRET
// (separate from STRIPE_WEBHOOK_SECRET used by the booking webhook)
//
// TODO markers indicate where client-specific business logic should be added
// once the subscription model is decided (discounts, welcome emails, etc.).

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import Stripe from 'https://esm.sh/stripe@14?target=deno&no-check';

const stripe         = new Stripe(Deno.env.get('STRIPE_SK') ?? '', { apiVersion: '2023-10-16' });
const WEBHOOK_SECRET = Deno.env.get('STRIPE_SUBSCRIPTION_WEBHOOK_SECRET') ?? '';

serve(async (req) => {
  const sig  = req.headers.get('stripe-signature') ?? '';
  const body = await req.text();

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(body, sig, WEBHOOK_SECRET);
  } catch (_) {
    return new Response('Invalid signature', { status: 400 });
  }

  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  switch (event.type) {

    case 'checkout.session.completed': {
      const session = event.data.object as Stripe.Checkout.Session;
      if (session.mode !== 'subscription') break;

      const planId      = session.metadata?.plan_id;
      const clientEmail = session.metadata?.client_email ?? session.customer_email ?? '';
      const clientName  = session.metadata?.client_name ?? '';
      const subId       = session.subscription as string;

      if (!planId || !clientEmail) break;

      const sub = await stripe.subscriptions.retrieve(subId);

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
      );

      // TODO: send welcome email via Resend
      // TODO: if plan.booking_discount_pct > 0, record discount entitlement for clientEmail
      // TODO: if plan.included_service_ids.length > 0, create service credit records
      break;
    }

    case 'customer.subscription.updated': {
      const sub = event.data.object as Stripe.Subscription;
      const statusMap: Record<string, string> = {
        active:    'active',
        trialing:  'trialing',
        past_due:  'past_due',
        canceled:  'cancelled',
        cancelled: 'cancelled',
      };
      await db.from('subscriptions')
        .update({
          status:               statusMap[sub.status] ?? sub.status,
          current_period_start: new Date(sub.current_period_start * 1000).toISOString(),
          current_period_end:   new Date(sub.current_period_end   * 1000).toISOString(),
        })
        .eq('stripe_subscription_id', sub.id);

      // TODO: notify client if status changed to past_due
      break;
    }

    case 'customer.subscription.deleted': {
      const sub = event.data.object as Stripe.Subscription;
      await db.from('subscriptions')
        .update({ status: 'cancelled', cancelled_at: new Date().toISOString() })
        .eq('stripe_subscription_id', sub.id);

      // TODO: send cancellation confirmation email
      // TODO: revoke any active discount or included-service credits
      break;
    }

    case 'invoice.payment_failed': {
      const invoice = event.data.object as Stripe.Invoice;
      if (invoice.subscription) {
        await db.from('subscriptions')
          .update({ status: 'past_due' })
          .eq('stripe_subscription_id', invoice.subscription as string);

        // TODO: email client with payment failure notice + link to update card
      }
      break;
    }

    default:
      // Unhandled event — safe to ignore
  }

  return new Response(JSON.stringify({ received: true }), { status: 200 });
});
