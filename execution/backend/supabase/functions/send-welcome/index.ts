import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

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
    const { email, name, source } = await req.json()

    if (!email || !String(email).includes('@')) {
      return json({ error: 'Invalid email' }, 400)
    }

    // Insert subscriber — silently ignore duplicate emails
    const db = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const { error: dbErr } = await db
      .from('subscribers')
      .upsert(
        {
          email:  String(email).toLowerCase().trim(),
          name:   name ?? null,
          source: source ?? 'website',
        },
        { onConflict: 'email', ignoreDuplicates: true },
      )

    if (dbErr) return json({ error: dbErr.message }, 500)

    // Fetch the unsubscribe token (works for both new and existing subscribers)
    const { data: subscriber } = await db
      .from('subscribers')
      .select('unsubscribe_token')
      .eq('email', String(email).toLowerCase().trim())
      .single()

    const supabaseUrl    = Deno.env.get('SUPABASE_URL') ?? ''
    const unsubscribeUrl = `${supabaseUrl}/functions/v1/unsubscribe?token=${subscriber?.unsubscribe_token ?? ''}`

    // Send welcome email (skip gracefully if RESEND_KEY not configured)
    const resendKey    = Deno.env.get('RESEND_KEY') ?? ''
    const businessName = Deno.env.get('BUSINESS_NAME') ?? 'Us'
    const fromEmail    = Deno.env.get('FROM_EMAIL') ?? 'hello@example.com'

    if (resendKey) {
      await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${resendKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from:    `${businessName} <${fromEmail}>`,
          to:      [email],
          subject: `You're on the list`,
          html: `
            <p>Hi${name ? ` ${name}` : ''},</p>
            <p>Thanks for subscribing! You'll be the first to hear about news,
               exclusive offers, and upcoming events from ${businessName}.</p>
            <p>See you soon.</p>
            <p>— The ${businessName} Team</p>
            <p style="font-size:12px;color:#999;margin-top:2rem;">
              Don't want these emails?
              <a href="${unsubscribeUrl}" style="color:#999;">Unsubscribe</a>
            </p>
          `,
        }),
      })
    }

    return json({ ok: true })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
