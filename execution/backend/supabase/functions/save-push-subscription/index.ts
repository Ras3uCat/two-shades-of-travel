import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Saves a Web Push OR FCM subscription from the Flutter client.
// JWT optional — works for authenticated users (staff/master) and guest clients.

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  })

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  try {
    const body = await req.json()
    const { endpoint, p256dh, auth_key, user_agent, client_email, fcm_token } = body

    // FCM path: only fcm_token required (no endpoint/keys)
    const isFcm = !!fcm_token

    if (!isFcm && (!endpoint || !p256dh || !auth_key)) {
      return json({ error: 'endpoint, p256dh, and auth_key required for Web Push' }, 400)
    }

    const db = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // Resolve user_id from JWT if present
    let userId: string | null = null
    const authHeader = req.headers.get('Authorization') ?? ''
    if (authHeader.startsWith('Bearer ')) {
      const anonDb = createClient(
        Deno.env.get('SUPABASE_URL')!,
        Deno.env.get('SUPABASE_ANON_KEY')!,
      )
      const { data: { user } } = await anonDb.auth.getUser(authHeader.slice(7))
      userId = user?.id ?? null
    }

    if (!userId && !client_email) {
      return json({ error: 'client_email required for unauthenticated subscriptions' }, 400)
    }

    if (isFcm) {
      // FCM upsert — keyed on fcm_token
      await db.from('push_subscriptions').upsert({
        fcm_token,
        user_agent: user_agent ?? null,
        ...(userId       ? { user_id:      userId       } : {}),
        ...(client_email ? { client_email: client_email } : {}),
      }, { onConflict: 'fcm_token' })
    } else {
      // Web Push upsert — keyed on endpoint
      await db.from('push_subscriptions').upsert({
        endpoint,
        p256dh,
        auth_key,
        user_agent: user_agent ?? null,
        ...(userId       ? { user_id:      userId       } : {}),
        ...(client_email ? { client_email: client_email } : {}),
      }, { onConflict: 'endpoint' })
    }

    return json({ ok: true })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
