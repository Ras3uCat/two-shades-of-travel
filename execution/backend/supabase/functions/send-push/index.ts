import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import webpush          from 'npm:web-push@3'

// Internal helper — fans out a push notification to all subscriptions for a user.
// Handles both Web Push (endpoint) and FCM (fcm_token) rows.
// Called best-effort from send-notification (fire and forget).

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

// ── FCM helpers ───────────────────────────────────────────────────────────────

function pemToDer(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----[^-]+-----/g, '').replace(/\s/g, '')
  const bin = atob(b64)
  const buf = new Uint8Array(bin.length)
  for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i)
  return buf.buffer
}

async function getFcmAccessToken(sa: { client_email: string; private_key: string }): Promise<string> {
  const now    = Math.floor(Date.now() / 1000)
  const toB64u = (s: string) => btoa(s).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  const header  = toB64u(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  const payload = toB64u(JSON.stringify({
    iss:   sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud:   'https://oauth2.googleapis.com/token',
    iat:   now,
    exp:   now + 3600,
  }))
  const unsigned = `${header}.${payload}`
  const key = await crypto.subtle.importKey(
    'pkcs8', pemToDer(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign'],
  )
  const sigBytes = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(unsigned))
  const sig = btoa(String.fromCharCode(...new Uint8Array(sigBytes)))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  const jwt = `${unsigned}.${sig}`
  const resp = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  })
  const { access_token } = await resp.json()
  return access_token as string
}

async function sendFcm(
  sa: { project_id: string; client_email: string; private_key: string },
  token: string, title: string, body: string, url?: string,
): Promise<boolean> {
  try {
    const accessToken = await getFcmAccessToken(sa)
    const resp = await fetch(
      `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
      {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: {
            token,
            notification: { title, body },
            data: url ? { url } : {},
          },
        }),
      },
    )
    return resp.ok
  } catch {
    return false
  }
}

// ── Main handler ──────────────────────────────────────────────────────────────

serve(async (req) => {
  try {
    const { user_id, client_email, title, body, url } = await req.json()
    if (!title || (!user_id && !client_email)) {
      return json({ error: 'title and one of user_id or client_email required' }, 400)
    }

    const vapidPublic  = Deno.env.get('VAPID_PUBLIC_KEY')  ?? ''
    const vapidPrivate = Deno.env.get('VAPID_PRIVATE_KEY') ?? ''
    const siteUrl      = Deno.env.get('SITE_URL')          ?? ''
    const fcmSaRaw     = Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? ''

    if (vapidPublic && vapidPrivate) {
      webpush.setVapidDetails(
        siteUrl.startsWith('http') ? `mailto:admin@${new URL(siteUrl).hostname}` : `mailto:admin@example.com`,
        vapidPublic, vapidPrivate,
      )
    }

    const db = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    let query = db.from('push_subscriptions')
      .select('id, endpoint, p256dh, auth_key, fcm_token')
    query = user_id ? query.eq('user_id', user_id) : query.eq('client_email', client_email)

    const { data: subs } = await query
    if (!subs || subs.length === 0) return json({ sent: 0 })

    const payload     = JSON.stringify({ title, body, url })
    const expiredIds: string[] = []
    const fcmSa       = fcmSaRaw ? JSON.parse(fcmSaRaw) : null

    await Promise.allSettled(subs.map(async (sub: {
      id: string; endpoint: string | null; p256dh: string | null;
      auth_key: string | null; fcm_token: string | null;
    }) => {
      if (sub.fcm_token && fcmSa) {
        await sendFcm(fcmSa, sub.fcm_token, title, body, url)
      } else if (sub.endpoint && sub.p256dh && sub.auth_key && vapidPublic && vapidPrivate) {
        try {
          await webpush.sendNotification(
            { endpoint: sub.endpoint, keys: { p256dh: sub.p256dh, auth: sub.auth_key } },
            payload,
          )
        } catch (err: unknown) {
          if (err && typeof err === 'object' && 'statusCode' in err &&
              (err as { statusCode: number }).statusCode === 410) {
            expiredIds.push(sub.id)
          }
        }
      }
    }))

    if (expiredIds.length > 0) {
      await db.from('push_subscriptions').delete().in('id', expiredIds)
    }

    return json({ sent: subs.length - expiredIds.length, removed: expiredIds.length })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
