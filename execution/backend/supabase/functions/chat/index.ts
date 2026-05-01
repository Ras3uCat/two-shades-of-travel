import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Public Edge Function — no JWT required.
// Powers the AI chatbot widget (CHATBOT_ENABLED feature).
// Model: claude-haiku-4-5-20251001 (fast, low-cost).

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  })

// Module-level cache — survives warm invocations on the same isolate.
// TTL prevents stale prompt after admin edits chatbot_system_prompt.
let cachedSystemPrompt: string | null = null
let cacheExpiresAt = 0
const CACHE_TTL_MS = 10 * 60 * 1000  // 10 minutes

async function buildSystemPrompt(db: ReturnType<typeof createClient>): Promise<string> {
  if (cachedSystemPrompt && Date.now() < cacheExpiresAt) return cachedSystemPrompt

  const [{ data: config }, { data: services }, { data: hours }] = await Promise.all([
    db.from('business_config')
      .select('business_name, address, phone, chatbot_system_prompt')
      .limit(1).single(),
    db.from('services').select('name, price, duration_minutes').eq('is_active', true).order('display_order'),
    db.from('business_hours').select('day_of_week, open_time, close_time, is_closed').order('day_of_week'),
  ])

  const siteUrl  = Deno.env.get('SITE_URL') ?? ''
  const name     = config?.business_name ?? 'this business'
  const address  = config?.address        ?? ''
  const phone    = config?.phone          ?? ''

  const svcList = (services ?? [])
    .map((s: { name: string; price: number; duration_minutes: number }) =>
      `${s.name} ($${Number(s.price).toFixed(2)}, ${s.duration_minutes} min)`)
    .join('; ')

  const days = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday']
  const hoursText = (hours ?? [])
    .map((h: { day_of_week: number; is_closed: boolean; open_time: string; close_time: string }) =>
      h.is_closed
        ? `${days[h.day_of_week]}: closed`
        : `${days[h.day_of_week]}: ${h.open_time}–${h.close_time}`)
    .join(', ')

  const autoPrompt = [
    `You are a helpful assistant for ${name}.`,
    `Answer questions only about this business. Be friendly and concise (1-3 sentences).`,
    `If unsure, direct the visitor to book online or call.`,
    address  ? `Address: ${address}`         : '',
    phone    ? `Phone: ${phone}`             : '',
    svcList  ? `Services: ${svcList}`        : '',
    hoursText? `Hours: ${hoursText}`         : '',
    siteUrl  ? `Booking URL: ${siteUrl}/booking` : '',
  ].filter(Boolean).join('\n')

  // Full tier: use custom prompt when set, with auto-generated context appended.
  cachedSystemPrompt = config?.chatbot_system_prompt
    ? `${config.chatbot_system_prompt}\n\nBusiness context (always accurate):\n${autoPrompt}`
    : autoPrompt

  cacheExpiresAt = Date.now() + CACHE_TTL_MS

  return cachedSystemPrompt
}

// Per-session rate limit: max 20 messages per cold-start cycle
const sessionCounts = new Map<string, number>()
const RATE_LIMIT = 20

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  try {
    const { message, session_id, history } = await req.json()
    if (!message || !session_id) return json({ error: 'message and session_id required' }, 400)

    const count = sessionCounts.get(session_id) ?? 0
    if (count >= RATE_LIMIT) return json({ error: 'Rate limit exceeded' }, 429)
    sessionCounts.set(session_id, count + 1)

    const apiKey = Deno.env.get('ANTHROPIC_API_KEY') ?? ''
    if (!apiKey) return json({ error: 'ANTHROPIC_API_KEY not configured' }, 500)

    const db = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const systemPrompt = await buildSystemPrompt(db)

    // Keep last 10 exchanges (20 messages) to bound token cost
    const priorMessages: { role: string; content: string }[] = (history ?? []).slice(-20)

    const anthropicRes = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key':         apiKey,
        'anthropic-version': '2023-06-01',
        'content-type':      'application/json',
      },
      body: JSON.stringify({
        model:      'claude-haiku-4-5-20251001',
        max_tokens: 256,
        system:     systemPrompt,
        messages:   [...priorMessages, { role: 'user', content: message }],
      }),
    })

    if (!anthropicRes.ok) {
      const err = await anthropicRes.text()
      return json({ error: `Anthropic error: ${err}` }, 500)
    }

    const data = await anthropicRes.json()
    const reply = data.content?.[0]?.text ?? ''

    return json({ reply })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
