import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Returns a minimal, styled HTML page — no Flutter route needed.
const html = (body: string, status = 200) =>
  new Response(
    `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Unsubscribe</title>
  <style>
    body { font-family: system-ui, -apple-system, sans-serif; margin: 0;
           display: flex; align-items: center; justify-content: center;
           min-height: 100vh; background: #f5f5f5; }
    .card { background: #fff; border-radius: 12px; padding: 2.5rem 3rem;
            text-align: center; max-width: 420px; width: 90%;
            box-shadow: 0 2px 16px rgba(0,0,0,.08); }
    h1 { margin: 0 0 .75rem; font-size: 1.4rem; font-weight: 600; color: #111; }
    p  { margin: 0; color: #666; line-height: 1.65; font-size: .95rem; }
  </style>
</head>
<body>
  <div class="card">${body}</div>
</body>
</html>`,
    { status, headers: { 'Content-Type': 'text/html; charset=utf-8' } },
  )

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok')

  const token = new URL(req.url).searchParams.get('token')
  if (!token) {
    return html(
      '<h1>Invalid link</h1><p>This unsubscribe link is missing or has expired.</p>',
      400,
    )
  }

  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  const { error } = await db
    .from('subscribers')
    .delete()
    .eq('unsubscribe_token', token)

  if (error) {
    return html(
      '<h1>Something went wrong</h1><p>Please try again or contact us directly.</p>',
      500,
    )
  }

  return html(
    `<h1>You're unsubscribed</h1>
     <p>You've been removed from our mailing list.<br>We're sorry to see you go.</p>`,
  )
})
