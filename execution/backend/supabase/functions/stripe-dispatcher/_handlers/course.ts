// stripe-dispatcher/_handlers/course.ts
// Handles checkout.session.completed when metadata.type === 'course'.
// Activates the pending enrollment and sends a confirmation email via Resend.

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe             from 'https://esm.sh/stripe@14?target=deno&no-check'

export async function handleCourseEnrollment(
  session: Stripe.Checkout.Session,
  db: SupabaseClient,
): Promise<void> {
  const courseId    = session.metadata?.course_id
  const clientEmail = session.metadata?.client_email

  if (!courseId || !clientEmail) {
    console.error('course handler: missing course_id or client_email in metadata')
    return
  }

  // ── Activate enrollment ───────────────────────────────────────────────────────
  const { error } = await db
    .from('course_enrollments')
    .update({ status: 'active', enrolled_at: new Date().toISOString() })
    .eq('stripe_checkout_session', session.id)

  if (error) {
    console.error('course handler: failed to activate enrollment', error.message)
    return
  }

  // ── Load course title for email ───────────────────────────────────────────────
  const { data: course } = await db
    .from('courses')
    .select('title, slug')
    .eq('id', courseId)
    .single()

  if (!course) return

  // ── Send enrollment confirmation email (skip gracefully if no RESEND_KEY) ─────
  const resendKey = Deno.env.get('RESEND_KEY')
  const siteUrl   = Deno.env.get('SITE_URL') ?? ''
  const fromEmail = Deno.env.get('FROM_EMAIL') ?? 'noreply@example.com'
  const bizName   = Deno.env.get('BUSINESS_NAME') ?? 'Us'

  if (!resendKey) return

  await fetch('https://api.resend.com/emails', {
    method:  'POST',
    headers: {
      Authorization:  `Bearer ${resendKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from:    fromEmail,
      to:      clientEmail,
      subject: `You're enrolled in ${course.title as string}`,
      text: [
        `Hi there,`,
        ``,
        `You're now enrolled in "${course.title as string}" with ${bizName}.`,
        ``,
        `Start learning here: ${siteUrl}/courses/${course.slug as string}`,
        ``,
        `Enjoy the course!`,
        `— The ${bizName} team`,
      ].join('\n'),
    }),
  }).catch((e: Error) => console.error('course handler: resend email failed', e.message))
}
