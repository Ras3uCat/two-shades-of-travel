// send-recurring-payment-reminders
// Scheduled daily cron. Finds pending recurring bookings due within
// `recurring_payment_days_ahead` days that haven't had a reminder sent,
// creates a Stripe Checkout session for each, emails the payment link,
// then marks recurring_reminder_sent = true.
//
// Schedule: daily, e.g. '0 9 * * *' (9am UTC)

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import Stripe from 'https://esm.sh/stripe@14?target=deno&no-check';

const stripe     = new Stripe(Deno.env.get('STRIPE_SK') ?? '', { apiVersion: '2023-10-16' });
const RESEND_KEY  = Deno.env.get('RESEND_KEY')      ?? '';
const SITE_URL    = Deno.env.get('SITE_URL')        ?? 'http://localhost:3000';
const FROM_EMAIL  = Deno.env.get('FROM_EMAIL')      ?? 'noreply@example.com';
const BIZ_NAME    = Deno.env.get('BUSINESS_NAME')   ?? 'Studio';

serve(async () => {
  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  // Load days-ahead setting from business_config
  const { data: cfg } = await db
    .from('business_config')
    .select('recurring_payment_days_ahead')
    .limit(1)
    .single();
  const daysAhead = (cfg?.recurring_payment_days_ahead as number) ?? 3;

  const now    = new Date();
  const cutoff = new Date(now.getTime() + daysAhead * 86_400_000);

  const { data: bookings, error } = await db
    .from('bookings')
    .select('id, client_name, client_email, artist_name, service_names, start_time, total_price')
    .eq('status', 'pending')
    .eq('recurring_reminder_sent', false)
    .not('recurring_series_id', 'is', null)
    .gte('start_time', now.toISOString())
    .lte('start_time', cutoff.toISOString());

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }

  if (!bookings || bookings.length === 0) {
    return new Response(JSON.stringify({ sent: 0 }), { status: 200 });
  }

  let sent = 0;
  for (const booking of bookings) {
    try {
      const session = await stripe.checkout.sessions.create({
        mode:           'payment',
        customer_email: booking.client_email as string,
        line_items: [{
          quantity:   1,
          price_data: {
            currency:     'usd',
            unit_amount:  Math.round((booking.total_price as number) * 100),
            product_data: { name: (booking.service_names as string[]).join(', ') },
          },
        }],
        success_url: `${SITE_URL}/booking/confirmation?booking_id=${booking.id}`,
        cancel_url:  `${SITE_URL}/booking?cancelled_booking_id=${booking.id}`,
        metadata:    { booking_id: booking.id as string },
      });

      if (RESEND_KEY) {
        const apptDate = new Date(booking.start_time as string).toLocaleDateString('en-US', {
          weekday: 'long', month: 'long', day: 'numeric',
        });
        await fetch('https://api.resend.com/emails', {
          method:  'POST',
          headers: {
            Authorization:  `Bearer ${RESEND_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            from:    `${BIZ_NAME} <${FROM_EMAIL}>`,
            to:      booking.client_email,
            subject: `Payment reminder — your appointment on ${apptDate}`,
            html: `
              <p>Hi ${booking.client_name},</p>
              <p>Your recurring appointment at <strong>${BIZ_NAME}</strong> is coming up
              on <strong>${apptDate}</strong>.</p>
              <p>Please complete your payment to confirm your slot:</p>
              <p style="margin:24px 0">
                <a href="${session.url}"
                   style="background:#000;color:#fff;padding:12px 28px;
                          text-decoration:none;font-family:sans-serif;">
                  PAY NOW
                </a>
              </p>
              <p style="color:#888;font-size:13px">
                If you no longer need this appointment, you can ignore this email —
                the slot will be released automatically.
              </p>
            `,
          }),
        });
      }

      await db
        .from('bookings')
        .update({ recurring_reminder_sent: true })
        .eq('id', booking.id);

      sent++;
    } catch (_) {
      // Continue with remaining bookings on individual failure
    }
  }

  return new Response(JSON.stringify({ sent }), { status: 200 });
});
