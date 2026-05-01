import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe           from 'https://esm.sh/stripe@14?target=deno&no-check'

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
    // Staff must be authenticated
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return json({ error: 'Unauthorized' }, 401)

    // Resolve the calling user from their JWT
    const anonClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    )
    const { data: { user } } = await anonClient.auth.getUser()
    if (!user) return json({ error: 'Unauthorized' }, 401)

    const { return_url, refresh_url } = await req.json()
    const siteUrl = Deno.env.get('SITE_URL') ?? ''

    const stripe = new Stripe(Deno.env.get('STRIPE_SK')!, { apiVersion: '2024-06-20' })
    const db = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // Get or create the artist's Express account
    const { data: profile } = await db
      .from('profiles')
      .select('stripe_express_account_id')
      .eq('id', user.id)
      .single()

    let accountId = profile?.stripe_express_account_id as string | undefined

    if (!accountId) {
      const account = await stripe.accounts.create({ type: 'express' })
      accountId = account.id
      await db
        .from('profiles')
        .update({
          stripe_express_account_id: accountId,
          stripe_onboard_status:     'pending',
        })
        .eq('id', user.id)
    }

    // Generate a one-time onboarding link
    const link = await stripe.accountLinks.create({
      account:     accountId,
      refresh_url: refresh_url ?? `${siteUrl}/staff`,
      return_url:  return_url  ?? `${siteUrl}/staff`,
      type:        'account_onboarding',
    })

    return json({ url: link.url })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
