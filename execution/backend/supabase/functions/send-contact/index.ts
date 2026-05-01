import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const RESEND_KEY = Deno.env.get('RESEND_KEY') ?? ''
const TO_EMAIL   = Deno.env.get('CONTACT_TO_EMAIL') ?? ''

// Rate limit: max 3 submissions per IP per hour using Deno KV
async function isRateLimited(ip: string): Promise<boolean> {
  try {
    const kv    = await Deno.openKv()
    const key   = ['rate_limit', 'contact', ip]
    const entry = await kv.get<number>(key)
    const count = (entry.value ?? 0) + 1
    if (count > 3) return true
    await kv.set(key, count, { expireIn: 3_600_000 }) // 1-hour window
    return false
  } catch {
    return false // fail open — don't block if KV unavailable
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    const ip = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? 'unknown'
    if (await isRateLimited(ip)) {
      return new Response(
        JSON.stringify({ error: 'Too many requests. Please try again later.' }),
        { status: 429, headers: { 'Content-Type': 'application/json' } },
      )
    }

    const body = await req.json()
    const { name, email, message, website } = body as Record<string, string>

    // Honeypot: a hidden 'website' field that only bots fill in
    if (website) {
      return new Response(JSON.stringify({ success: true })) // silent reject
    }

    if (!name || !email || !message) {
      return new Response(JSON.stringify({ error: 'Missing fields' }), { status: 400 })
    }

    if (message.length > 2000) {
      return new Response(JSON.stringify({ error: 'Message too long' }), { status: 400 })
    }

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${RESEND_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: `Contact Form <noreply@${Deno.env.get('RESEND_DOMAIN') ?? 'example.com'}>`,
        to: [TO_EMAIL],
        reply_to: email,
        subject: `New contact from ${name}`,
        html: `
          <h2>New Contact Form Submission</h2>
          <p><strong>Name:</strong> ${name}</p>
          <p><strong>Email:</strong> ${email}</p>
          <p><strong>Message:</strong></p>
          <p>${message.replace(/\n/g, '<br>')}</p>
        `,
      }),
    })

    if (!res.ok) {
      const err = await res.text()
      return new Response(JSON.stringify({ error: err }), { status: 500 })
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 })
  }
})
