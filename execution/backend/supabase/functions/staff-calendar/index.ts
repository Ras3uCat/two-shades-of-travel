import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL            = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const CLIENT_SLUG             = Deno.env.get('CLIENT_SLUG') ?? 'app'

serve(async (req: Request) => {
  if (req.method !== 'GET') {
    return new Response('Method not allowed', { status: 405 })
  }

  const token = new URL(req.url).searchParams.get('token')
  if (!token) {
    return new Response('Missing token', { status: 400, headers: { 'Content-Type': 'text/plain' } })
  }

  const db = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

  // Resolve token → staff_id
  const { data: tokenRow } = await db
    .from('calendar_tokens')
    .select('staff_id')
    .eq('token', token)
    .maybeSingle()

  if (!tokenRow) {
    return new Response('Unknown token', { status: 404, headers: { 'Content-Type': 'text/plain' } })
  }

  // Fetch bookings for this staff member (confirmed + pending, not cancelled)
  const { data: bookings } = await db
    .from('bookings')
    .select('id, service_names, start_time, end_time, client_name, client_email, client_notes, status')
    .eq('artist_id', tokenRow.staff_id)
    .in('status', ['confirmed', 'pending'])
    .order('start_time', { ascending: true })

  // Build iCal
  const now    = new Date()
  const dtstamp = fmtDate(now)
  const lines: string[] = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    `PRODID:-//Raspucat//${CLIENT_SLUG}//EN`,
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    fold(`X-WR-CALNAME:My Bookings — ${CLIENT_SLUG}`),
  ]

  for (const b of bookings ?? []) {
    const serviceNames: string[] = Array.isArray(b.service_names)
      ? b.service_names
      : [b.service_names ?? 'Appointment']
    const summary = `${serviceNames.join(', ')} — ${b.client_name}`
    const descParts = [b.client_name, b.client_email, b.client_notes]
      .filter((p): p is string => !!p)
    const desc = descParts.join(' | ')

    lines.push(
      'BEGIN:VEVENT',
      `UID:${b.id}@${CLIENT_SLUG}`,
      `DTSTAMP:${dtstamp}`,
      `DTSTART:${fmtDate(new Date(b.start_time))}`,
      `DTEND:${fmtDate(new Date(b.end_time))}`,
      fold(`SUMMARY:${summary}`),
      ...(desc ? [fold(`DESCRIPTION:${desc}`)] : []),
      'STATUS:CONFIRMED',
      'END:VEVENT',
    )
  }

  lines.push('END:VCALENDAR')

  return new Response(lines.join('\r\n'), {
    status: 200,
    headers: {
      'Content-Type': 'text/calendar; charset=utf-8',
      'Content-Disposition': `inline; filename="${CLIENT_SLUG}-bookings.ics"`,
      'Cache-Control': 'no-cache',
    },
  })
})

// RFC 5545 §3.1 — format DateTime as YYYYMMDDTHHmmssZ
function fmtDate(d: Date): string {
  const p = (n: number, w = 2) => String(n).padStart(w, '0')
  return `${p(d.getUTCFullYear(), 4)}${p(d.getUTCMonth() + 1)}${p(d.getUTCDate())}` +
         `T${p(d.getUTCHours())}${p(d.getUTCMinutes())}${p(d.getUTCSeconds())}Z`
}

// RFC 5545 §3.1 — fold lines longer than 75 octets with CRLF + SPACE
function fold(line: string): string {
  if (line.length <= 75) return line
  const chunks: string[] = []
  let pos = 0
  const limit = 75
  while (pos < line.length) {
    chunks.push(line.slice(pos, pos + limit))
    pos += limit
    if (pos < line.length) {
      // Continuation lines begin with a single SPACE
    }
  }
  return chunks.join('\r\n ')
}
