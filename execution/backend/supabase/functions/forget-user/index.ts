import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// GDPR Right-to-be-Forgotten — hard-deletes all data for a given email.
// Caller must be authenticated with a JWT that carries role=master in app_metadata.
// Uses service role for all write operations.

const CORS = {
  'Access-Control-Allow-Origin':  '*',
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
    const url            = Deno.env.get('SUPABASE_URL')!
    const anonKey        = Deno.env.get('SUPABASE_ANON_KEY')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    // ── Auth: verify caller is master ──────────────────────────────────────
    const authHeader = req.headers.get('Authorization') ?? ''
    const anonClient = createClient(url, anonKey, {
      global: { headers: { Authorization: authHeader } },
    })
    const { data: { user }, error: authErr } = await anonClient.auth.getUser()
    if (authErr || !user) return json({ error: 'Unauthorized' }, 401)

    const role = (user.app_metadata as Record<string, string> | undefined)?.role
    if (role !== 'master') return json({ error: 'Forbidden' }, 403)

    // ── Input ──────────────────────────────────────────────────────────────
    const { email } = await req.json() as { email?: string }
    if (!email || !email.includes('@')) return json({ error: 'Invalid email' }, 400)

    const db = createClient(url, serviceRoleKey)

    // ── 1. Delete bookings (cascade covers booking_addons via FK) ──────────
    const { count: bookingsDeleted } = await db
      .from('bookings')
      .delete({ count: 'exact' })
      .eq('client_email', email)

    // ── 2. Delete newsletter subscribers ──────────────────────────────────
    const { count: newslettersDeleted } = await db
      .from('subscribers')
      .delete({ count: 'exact' })
      .eq('email', email)

    // ── 3. Loyalty + referrals (skip gracefully if tables absent) ──────────
    let loyaltyDeleted = 0
    let referralsDeleted = 0
    try {
      // Look up uid by email (may not exist for guest bookings)
      const { data: authUser } = await db
        .from('profiles')
        .select('id')
        .eq('email', email)
        .maybeSingle()

      if (authUser?.id) {
        const uid = authUser.id as string
        const [loyaltyRes, referralRes] = await Promise.allSettled([
          db.from('loyalty_points').delete({ count: 'exact' }).eq('user_id', uid),
          db.from('referrals').delete({ count: 'exact' }).eq('user_id', uid),
        ])
        loyaltyDeleted   = loyaltyRes.status   === 'fulfilled' ? (loyaltyRes.value.count ?? 0)   : 0
        referralsDeleted = referralRes.status  === 'fulfilled' ? (referralRes.value.count ?? 0)  : 0
      }
    } catch (_) { /* tables may not exist — skip */ }

    // ── 4. Delete auth user (service role admin) ───────────────────────────
    let authUserDeleted = false
    try {
      const { data: listData } = await db.auth.admin.listUsers()
      const authUser = listData?.users.find(
        (u: { email?: string }) => u.email?.toLowerCase() === email.toLowerCase(),
      )
      if (authUser) {
        const { error: deleteErr } = await db.auth.admin.deleteUser(authUser.id)
        authUserDeleted = !deleteErr
      }
    } catch (_) { /* guest — no auth account */ }

    return json({
      deleted: {
        bookings:   bookingsDeleted  ?? 0,
        newsletter: newslettersDeleted ?? 0,
        loyalty:    loyaltyDeleted,
        referrals:  referralsDeleted,
        auth_user:  authUserDeleted,
      },
    })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
