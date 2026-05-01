// save-lesson-progress
// Upserts lesson progress for the authenticated user.
// Silently no-ops if unauthenticated (preview watchers don't track).
//
// POST { lesson_id: string, watched_seconds: number, completed: bool }
// Returns { ok: true } or { ok: false } (never errors for the client)

import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 })

  // ── Auth — silent no-op if unauthenticated ────────────────────────────────────
  const authHeader = req.headers.get('Authorization') ?? ''
  if (!authHeader.startsWith('Bearer ')) return json({ ok: false })

  const anonClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  )
  const { data: { user } } = await anonClient.auth.getUser()
  if (!user?.email) return json({ ok: false })

  const { lesson_id, watched_seconds, completed } = await req.json()
  if (!lesson_id) return json({ ok: false })

  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  const now = new Date().toISOString()

  // Load existing row to preserve completed_at once set
  const { data: existing } = await db
    .from('lesson_progress')
    .select('completed_at')
    .eq('lesson_id', lesson_id)
    .eq('client_email', user.email)
    .single()

  const completedAt =
    existing?.completed_at
      ? existing.completed_at          // already completed — keep original timestamp
      : completed ? now : null         // first completion

  await db
    .from('lesson_progress')
    .upsert(
      {
        lesson_id,
        client_email:    user.email,
        watched_seconds: watched_seconds ?? 0,
        completed_at:    completedAt,
        updated_at:      now,
      },
      { onConflict: 'lesson_id,client_email' },
    )

  return json({ ok: true })
})
