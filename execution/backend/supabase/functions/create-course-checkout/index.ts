// create-course-checkout
// Creates a Stripe Checkout session for a one-time course purchase.
// Follows create-shop-checkout pattern: pending enrollment row before Stripe session.
//
// POST { course_id, success_url?, cancel_url? }
// Requires valid JWT (auth required for course purchase).
// Returns { url: string }

import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe           from 'https://esm.sh/stripe@14?target=deno&no-check'

const SITE_URL = Deno.env.get('SITE_URL') ?? 'http://localhost:3000'

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 })

  // ── Auth ─────────────────────────────────────────────────────────────────────
  const authHeader = req.headers.get('Authorization') ?? ''
  if (!authHeader.startsWith('Bearer ')) return json({ error: 'Authentication required' }, 401)

  const anonClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  )
  const { data: { user } } = await anonClient.auth.getUser()
  if (!user?.email) return json({ error: 'Authentication required' }, 401)

  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  const { course_id, success_url, cancel_url } = await req.json()
  if (!course_id) return json({ error: 'course_id is required' }, 400)

  // ── Load course ───────────────────────────────────────────────────────────────
  const { data: course, error: cErr } = await db
    .from('courses')
    .select('id, title, slug, price_cents, stripe_price_id, is_published')
    .eq('id', course_id)
    .single()

  if (cErr || !course) return json({ error: 'Course not found' }, 404)
  if (!course.is_published) return json({ error: 'Course is not available' }, 400)
  if (!course.price_cents || (course.price_cents as number) <= 0) {
    return json({ error: 'Course is free — no checkout required' }, 400)
  }

  const clientEmail = user.email

  // ── Upsert pending enrollment (idempotent — safe to retry) ───────────────────
  const { error: eErr } = await db
    .from('course_enrollments')
    .upsert(
      { course_id, client_email: clientEmail, status: 'pending' },
      { onConflict: 'course_id,client_email', ignoreDuplicates: true },
    )

  if (eErr) return json({ error: 'Failed to create enrollment record' }, 500)

  // ── Create Stripe Checkout session ────────────────────────────────────────────
  const stripe = new Stripe(Deno.env.get('STRIPE_SK')!, { apiVersion: '2024-06-20' })

  const successUrl = success_url ?? `${SITE_URL}/courses/${course.slug as string}?enrolled=true`
  const cancelUrl  = cancel_url  ?? `${SITE_URL}/courses/${course.slug as string}`

  const session = await stripe.checkout.sessions.create({
    mode:           'payment',
    customer_email: clientEmail,
    line_items: [{
      quantity: 1,
      price_data: {
        currency:    'usd',
        unit_amount: course.price_cents as number,
        product_data: { name: course.title as string },
      },
    }],
    success_url: successUrl,
    cancel_url:  cancelUrl,
    metadata: {
      type:         'course',
      course_id:    course_id as string,
      client_email: clientEmail,
    },
  })

  // Attach session ID to enrollment row
  await db
    .from('course_enrollments')
    .update({ stripe_checkout_session: session.id })
    .eq('course_id', course_id as string)
    .eq('client_email', clientEmail)
    .eq('status', 'pending')

  return json({ url: session.url })
})
