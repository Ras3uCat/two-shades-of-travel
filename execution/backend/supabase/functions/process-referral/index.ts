// process-referral
// Called after a booking is confirmed (via stripe-webhook or send-reminders cron).
// POST { booking_id }
//
// Checks if the booking client has an un-rewarded referral record.
// If found and it is their first completed/confirmed booking:
//   1. Generates two unique short promo codes
//   2. Stores them on the referral row
//   3. Emails both the referrer and referred person their code
//   4. Marks rewarded_at = now()
//
// Promo codes are stored as plain text on the referrals row.
// If the client also has the booking module with a promo_codes table, you can
// insert them there too — see the TODO below.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const RESEND_KEY = Deno.env.get('RESEND_KEY')      ?? '';
const SITE_URL   = Deno.env.get('SITE_URL')        ?? 'http://localhost:3000';
const FROM_EMAIL = Deno.env.get('FROM_EMAIL')      ?? 'noreply@example.com';
const BIZ_NAME   = Deno.env.get('BUSINESS_NAME')   ?? 'Studio';

// How much discount the promo codes give — adjust to client preference
const DISCOUNT_PCT    = 10;
const REFERRER_LABEL  = `${DISCOUNT_PCT}% off your next visit`;
const REFERRED_LABEL  = `Welcome gift: ${DISCOUNT_PCT}% off your first visit`;

function generateCode(prefix: string): string {
  const rand = Math.random().toString(36).substring(2, 7).toUpperCase();
  return `${prefix}-${rand}`;
}

async function sendEmail(to: string, subject: string, html: string): Promise<void> {
  if (!RESEND_KEY) return;
  await fetch('https://api.resend.com/emails', {
    method:  'POST',
    headers: {
      Authorization:  `Bearer ${RESEND_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ from: `${BIZ_NAME} <${FROM_EMAIL}>`, to, subject, html }),
  });
}

serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 });

  const { booking_id } = await req.json();
  if (!booking_id) {
    return new Response(JSON.stringify({ error: 'booking_id required' }), { status: 400 });
  }

  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  // Load the booking
  const { data: booking, error: bErr } = await db
    .from('bookings')
    .select('id, client_email, client_name, status')
    .eq('id', booking_id)
    .single();

  if (bErr || !booking) {
    return new Response(JSON.stringify({ error: 'Booking not found' }), { status: 404 });
  }

  if (!['confirmed', 'completed'].includes(booking.status as string)) {
    return new Response(JSON.stringify({ skipped: 'booking not confirmed' }), { status: 200 });
  }

  const clientEmail = (booking.client_email as string).toLowerCase();

  // Is this the referred person's first confirmed/completed booking?
  const { count } = await db
    .from('bookings')
    .select('id', { count: 'exact', head: true })
    .eq('client_email', clientEmail)
    .in('status', ['confirmed', 'completed'])
    .neq('id', booking_id);

  if ((count ?? 0) > 0) {
    // Not their first booking — referral reward only fires once
    return new Response(JSON.stringify({ skipped: 'not first booking' }), { status: 200 });
  }

  // Find un-rewarded referral for this email
  const { data: referral, error: rErr } = await db
    .from('referrals')
    .select('id, referrer_id, referred_email')
    .eq('referred_email', clientEmail)
    .is('rewarded_at', null)
    .single();

  if (rErr || !referral) {
    return new Response(JSON.stringify({ skipped: 'no referral found' }), { status: 200 });
  }

  // Generate promo codes
  const referrerCode = generateCode('REF');
  const referredCode = generateCode('WEL');

  // Mark rewarded
  await db.from('referrals').update({
    booking_id:          booking_id,
    rewarded_at:         new Date().toISOString(),
    referrer_promo_code: referrerCode,
    referred_promo_code: referredCode,
  }).eq('id', referral.id as string);

  // TODO: if the promo_codes table exists (booking module enabled), insert the codes there:
  // await db.from('promo_codes').insert([
  //   { code: referrerCode, discount_pct: DISCOUNT_PCT, max_uses: 1, is_active: true },
  //   { code: referredCode, discount_pct: DISCOUNT_PCT, max_uses: 1, is_active: true },
  // ]);

  // Get referrer's email via profiles → auth.users join
  const { data: referrerProfile } = await db
    .from('profiles')
    .select('id')
    .eq('id', referral.referrer_id as string)
    .single();

  if (referrerProfile) {
    const { data: { user } } = await db.auth.admin.getUserById(referral.referrer_id as string);
    const referrerEmail = user?.email;

    if (referrerEmail) {
      await sendEmail(
        referrerEmail,
        `Your referral was successful — here's your reward`,
        `<p>Great news! Someone you referred just completed their first booking at <strong>${BIZ_NAME}</strong>.</p>
         <p>As a thank you, here's your discount code:</p>
         <p style="font-size:24px;font-weight:bold;letter-spacing:2px">${referrerCode}</p>
         <p style="color:#888">${REFERRER_LABEL}</p>
         <p><a href="${SITE_URL}/booking">Book now →</a></p>`,
      );
    }
  }

  // Email the referred person their welcome code
  await sendEmail(
    clientEmail,
    `A welcome gift from ${BIZ_NAME}`,
    `<p>Hi ${booking.client_name},</p>
     <p>Welcome to <strong>${BIZ_NAME}</strong>! Here's a little gift for your first visit:</p>
     <p style="font-size:24px;font-weight:bold;letter-spacing:2px">${referredCode}</p>
     <p style="color:#888">${REFERRED_LABEL}</p>
     <p><a href="${SITE_URL}/booking">Book again →</a></p>`,
  );

  return new Response(JSON.stringify({ rewarded: true, referrerCode, referredCode }), { status: 200 });
});
