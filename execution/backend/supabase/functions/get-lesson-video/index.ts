// get-lesson-video
// Returns a signed 4-hour URL for a private course video.
//
// Access check order:
//   1. lesson.is_preview = true  → allow without auth
//   2. JWT present → active enrollment for this course
//   3. JWT present → active/trialing subscription whose plan_id is in course.subscription_plan_ids
//   → 401 if no JWT and not preview
//   → 403 if JWT present but no enrollment/subscription match
//
// POST { lesson_id: string }
// Returns { signed_url: string, expires_at: string }

import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SIGNED_URL_TTL_SECONDS = 4 * 60 * 60 // 4 hours

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 })

  const { lesson_id } = await req.json()
  if (!lesson_id) return json({ error: 'lesson_id is required' }, 400)

  // ── Auth ─────────────────────────────────────────────────────────────────────
  const authHeader = req.headers.get('Authorization') ?? ''
  const anonClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  )
  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  let callerEmail: string | null = null
  if (authHeader.startsWith('Bearer ')) {
    const { data: { user } } = await anonClient.auth.getUser()
    callerEmail = user?.email ?? null
  }

  // ── Load lesson + course ──────────────────────────────────────────────────────
  const { data: lesson, error: lErr } = await db
    .from('course_lessons')
    .select('id, course_id, video_storage_path, is_preview')
    .eq('id', lesson_id)
    .single()

  if (lErr || !lesson) return json({ error: 'Lesson not found' }, 404)
  if (!lesson.video_storage_path) return json({ error: 'No video uploaded for this lesson' }, 404)

  // ── Access check ──────────────────────────────────────────────────────────────
  if (!lesson.is_preview) {
    if (!callerEmail) return json({ error: 'Authentication required' }, 401)

    // Check enrollment
    const { data: enrollment } = await db
      .from('course_enrollments')
      .select('id, expires_at')
      .eq('course_id', lesson.course_id)
      .eq('client_email', callerEmail)
      .eq('status', 'active')
      .single()

    const enrollmentValid =
      enrollment &&
      (enrollment.expires_at === null || new Date(enrollment.expires_at) > new Date())

    if (!enrollmentValid) {
      // Check subscription
      const { data: course } = await db
        .from('courses')
        .select('subscription_plan_ids')
        .eq('id', lesson.course_id)
        .single()

      const planIds: string[] = course?.subscription_plan_ids ?? []
      let subValid = false

      if (planIds.length > 0) {
        const { data: sub } = await db
          .from('subscriptions')
          .select('id')
          .eq('client_email', callerEmail)
          .in('status', ['active', 'trialing'])
          .in('plan_id', planIds)
          .limit(1)
          .single()
        subValid = !!sub
      }

      if (!subValid) return json({ error: 'Access denied — no active enrollment or subscription' }, 403)
    }
  }

  // ── Generate signed URL ───────────────────────────────────────────────────────
  const { data: signed, error: sErr } = await db.storage
    .from('course-videos')
    .createSignedUrl(lesson.video_storage_path as string, SIGNED_URL_TTL_SECONDS)

  if (sErr || !signed?.signedUrl) {
    return json({ error: 'Failed to generate signed URL' }, 500)
  }

  const expiresAt = new Date(Date.now() + SIGNED_URL_TTL_SECONDS * 1000).toISOString()

  return json({ signed_url: signed.signedUrl, expires_at: expiresAt })
})
