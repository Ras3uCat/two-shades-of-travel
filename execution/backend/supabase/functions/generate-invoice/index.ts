import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { PDFDocument, StandardFonts, rgb } from 'https://esm.sh/pdf-lib@1.17.1'
import { encodeBase64 } from 'https://deno.land/std@0.168.0/encoding/base64.ts'

// generate-invoice — creates a PDF invoice and emails it via Resend.
// Called internally from stripe-dispatcher (service-role bearer) or from admin (master JWT).

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
    const SUPABASE_URL      = Deno.env.get('SUPABASE_URL')!
    const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!
    const serviceRoleKey    = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    // Create service-role client first — needed for role lookup and all DB ops
    const db = createClient(SUPABASE_URL, serviceRoleKey)

    // ── Auth: accept service-role bearer (internal) OR master JWT (admin) ──
    const authHeader = req.headers.get('Authorization') ?? ''
    const token = authHeader.replace('Bearer ', '')

    let isAuthorized = false
    if (token === serviceRoleKey) {
      isAuthorized = true
    } else {
      const anonClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
        global: { headers: { Authorization: authHeader } },
      })
      const { data: { user } } = await anonClient.auth.getUser()
      if (user) {
        const { data: profile } = await db.from('profiles')
          .select('role').eq('user_id', user.id).single()
        isAuthorized = profile?.role === 'master'
      }
    }
    if (!isAuthorized) return json({ error: 'Unauthorized' }, 401)

    const { booking_id } = await req.json()
    if (!booking_id) return json({ error: 'booking_id required' }, 400)

    // ── Load booking ──────────────────────────────────────────────────────
    const { data: booking } = await db.from('bookings')
      .select('id, client_name, client_email, service_names, total_price, start_time, invoice_number, stripe_payment_intent_id, status')
      .eq('id', booking_id)
      .single()

    if (!booking) return json({ error: 'Booking not found' }, 404)
    if (booking.status !== 'confirmed') return json({ error: 'Booking must be confirmed' }, 400)

    // ── Load business config ──────────────────────────────────────────────
    const { data: config } = await db.from('business_config')
      .select('business_name, address, logo_url')
      .limit(1).single()

    // ── Invoice number: reuse if already set (resend path) ────────────────
    let invoiceNumber = booking.invoice_number as string | null
    if (!invoiceNumber) {
      const { data: nextNum } = await db.rpc('next_invoice_number')
      invoiceNumber = nextNum as string
      await db.from('bookings').update({ invoice_number: invoiceNumber }).eq('id', booking_id)
    }

    // ── Build PDF ─────────────────────────────────────────────────────────
    const pdfDoc  = await PDFDocument.create()
    const page    = pdfDoc.addPage([595, 842]) // A4
    const font    = await pdfDoc.embedFont(StandardFonts.Helvetica)
    const fontB   = await pdfDoc.embedFont(StandardFonts.HelveticaBold)
    const { height } = page.getSize()
    const black   = rgb(0.1, 0.1, 0.1)
    const muted   = rgb(0.5, 0.5, 0.5)
    const primary = rgb(0.4, 0.31, 0.64)

    let y = height - 60

    const draw = (text: string, x: number, size: number, bold = false, color = black) => {
      page.drawText(text, { x, y, size, font: bold ? fontB : font, color })
    }

    // Business header
    const bizName = config?.business_name ?? 'Business'
    draw(bizName, 50, 20, true, primary)
    y -= 24
    if (config?.address) { draw(config.address, 50, 10, false, muted); y -= 14 }

    // Invoice label + number
    y -= 20
    draw('INVOICE', 50, 28, true)
    draw(invoiceNumber, 400, 14, false, muted)
    y -= 18
    const dateStr = new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
    draw(`Date: ${dateStr}`, 400, 10, false, muted)

    // Divider
    y -= 16
    page.drawLine({ start: { x: 50, y }, end: { x: 545, y }, thickness: 0.5, color: muted })
    y -= 20

    // Bill to
    draw('BILL TO', 50, 9, true, muted)
    y -= 14
    draw(booking.client_name, 50, 12, true)
    y -= 14
    draw(booking.client_email, 50, 10, false, muted)
    y -= 24

    // Line items header
    page.drawLine({ start: { x: 50, y }, end: { x: 545, y }, thickness: 0.5, color: muted })
    y -= 16
    draw('DESCRIPTION', 50, 9, true, muted)
    draw('AMOUNT', 460, 9, true, muted)
    y -= 14
    page.drawLine({ start: { x: 50, y }, end: { x: 545, y }, thickness: 0.5, color: muted })
    y -= 20

    // Services
    const services = (booking.service_names as string[]).join(', ')
    const apptDate = new Date(booking.start_time).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
    draw(`${services} — ${apptDate}`, 50, 11)
    const amount = `$${Number(booking.total_price).toFixed(2)}`
    draw(amount, 460, 11)
    y -= 30

    // Total
    page.drawLine({ start: { x: 50, y }, end: { x: 545, y }, thickness: 0.5, color: muted })
    y -= 18
    draw('TOTAL', 380, 11, true)
    draw(amount, 460, 11, true)
    y -= 30

    // Reference
    if (booking.stripe_payment_intent_id) {
      draw(`Payment reference: ${booking.stripe_payment_intent_id}`, 50, 9, false, muted)
      y -= 14
    }
    draw(`Invoice: ${invoiceNumber}`, 50, 9, false, muted)

    // ── Encode PDF ────────────────────────────────────────────────────────
    const pdfBytes  = await pdfDoc.save()
    const pdfBase64 = encodeBase64(pdfBytes)

    // ── Send via Resend ───────────────────────────────────────────────────
    const resendKey = Deno.env.get('RESEND_KEY') ?? ''
    if (!resendKey) return json({ error: 'RESEND_KEY not configured' }, 500)

    const resendRes = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization:  `Bearer ${resendKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from:    Deno.env.get('FROM_EMAIL') ?? `noreply@${SUPABASE_URL.replace('https://', '').split('.')[0]}.io`,
        to:      [booking.client_email],
        subject: `Invoice ${invoiceNumber} — ${bizName}`,
        text:    `Hi ${booking.client_name},\n\nPlease find your invoice attached.\n\nInvoice: ${invoiceNumber}\nAmount: ${amount}\n\nThank you!`,
        attachments: [{
          filename: `${invoiceNumber}.pdf`,
          content:  pdfBase64,
        }],
      }),
    })

    if (!resendRes.ok) {
      const err = await resendRes.text()
      return json({ error: `Resend error: ${err}` }, 500)
    }

    // ── Update booking ────────────────────────────────────────────────────
    await db.from('bookings')
      .update({ invoice_sent_at: new Date().toISOString() })
      .eq('id', booking_id)

    return json({ invoice_number: invoiceNumber })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
