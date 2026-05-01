// stripe-dispatcher
// Single Stripe webhook endpoint. Register ONE URL in the Stripe dashboard.
// Routes internally by metadata.type and event.type.
//
// Replaces: stripe-webhook, shop-webhook, subscription-webhook, event-webhook
// Secret env var: STRIPE_WEBHOOK_SECRET (one secret for all modules)
//
// Supported routing:
//   checkout.session.completed + metadata.type=gift_voucher  → booking handler (gift)
//   checkout.session.completed + metadata.type=shop_order    → shop handler
//   checkout.session.completed + metadata.type=event_ticket  → event handler
//   checkout.session.completed + metadata.type=course        → course handler
//   checkout.session.completed + session.mode=subscription   → subscription handler
//   checkout.session.completed (default)                     → booking handler
//   customer.subscription.*                                  → subscription handler
//   invoice.payment_failed                                   → subscription handler

import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe           from 'https://esm.sh/stripe@14?target=deno&no-check'

import { handleBookingConfirmation, handleGiftVoucherPurchase } from './_handlers/booking.ts'
import { handleShopOrder }                                      from './_handlers/shop.ts'
import { handleEventTicket }                                    from './_handlers/event.ts'
import { handleCourseEnrollment }                               from './_handlers/course.ts'
import {
  handleSubscriptionCheckout,
  handleSubscriptionUpdated,
  handleSubscriptionDeleted,
  handleInvoicePaymentFailed,
} from './_handlers/subscription.ts'

serve(async (req) => {
  const sig  = req.headers.get('stripe-signature') ?? ''
  const body = await req.text()

  const stripe = new Stripe(Deno.env.get('STRIPE_SK')!, { apiVersion: '2024-06-20' })

  let event: Stripe.Event
  try {
    event = stripe.webhooks.constructEvent(body, sig, Deno.env.get('STRIPE_WEBHOOK_SECRET')!)
  } catch (e) {
    return new Response(`Webhook signature error: ${e}`, { status: 400 })
  }

  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  switch (event.type) {

    case 'checkout.session.completed': {
      const session = event.data.object as Stripe.Checkout.Session
      const type    = session.metadata?.type

      if (type === 'gift_voucher') {
        await handleGiftVoucherPurchase(session, db).catch(console.error)
      } else if (type === 'shop_order') {
        await handleShopOrder(session, db).catch(console.error)
      } else if (type === 'event_ticket') {
        await handleEventTicket(session, db).catch(console.error)
      } else if (type === 'course') {
        await handleCourseEnrollment(session, db).catch(console.error)
      } else if (session.mode === 'subscription') {
        await handleSubscriptionCheckout(session, db, stripe).catch(console.error)
      } else {
        // Default: booking (metadata.type=booking or booking_id present)
        const bookingId = session.metadata?.booking_id
        if (bookingId) {
          await handleBookingConfirmation(session, bookingId, db).catch(console.error)
        }
      }
      break
    }

    case 'customer.subscription.updated':
      await handleSubscriptionUpdated(
        event.data.object as Stripe.Subscription, db,
      ).catch(console.error)
      break

    case 'customer.subscription.deleted':
      await handleSubscriptionDeleted(
        event.data.object as Stripe.Subscription, db,
      ).catch(console.error)
      break

    case 'invoice.payment_failed':
      await handleInvoicePaymentFailed(
        event.data.object as Stripe.Invoice, db,
      ).catch(console.error)
      break

    default:
      // Unknown event type — safe no-op
  }

  return new Response(JSON.stringify({ received: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
