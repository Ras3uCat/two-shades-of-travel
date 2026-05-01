import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

// Internal helper — sends a single SMS via Twilio REST API.
// Not called from Flutter directly. Called best-effort from send-notification.
// Secrets: TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_FROM_NUMBER

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
    const { phone, message } = await req.json()
    if (!phone || !message) return json({ error: 'phone and message required' }, 400)

    const sid        = Deno.env.get('TWILIO_ACCOUNT_SID')  ?? ''
    const authToken  = Deno.env.get('TWILIO_AUTH_TOKEN')   ?? ''
    const fromNumber = Deno.env.get('TWILIO_FROM_NUMBER')  ?? ''

    if (!sid || !authToken || !fromNumber) {
      return json({ error: 'TWILIO_* secrets not configured' }, 500)
    }

    const res = await fetch(
      `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`,
      {
        method:  'POST',
        headers: {
          Authorization:  `Basic ${btoa(`${sid}:${authToken}`)}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({ To: phone, From: fromNumber, Body: message }).toString(),
      }
    )

    if (!res.ok) {
      const err = await res.text()
      return json({ error: `Twilio error: ${err}` }, 500)
    }

    return json({ ok: true })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
