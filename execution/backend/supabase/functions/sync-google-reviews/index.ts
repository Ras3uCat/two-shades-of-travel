import { serve }        from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// sync-google-reviews — imports Google Reviews into the testimonials table.
// Cron: 0 3 * * * (3am daily)
// Setup: Supabase dashboard → Edge Functions → sync-google-reviews → Schedule → "0 3 * * *"

serve(async () => {
  try {
    const placeId  = Deno.env.get('GOOGLE_PLACES_ID') ?? ''
    const apiKey   = Deno.env.get('GOOGLE_PLACES_API_KEY') ?? ''
    const minRating = parseInt(Deno.env.get('REVIEWS_MIN_RATING') ?? '4', 10)

    if (!placeId || !apiKey) {
      console.error('sync-google-reviews: GOOGLE_PLACES_ID or GOOGLE_PLACES_API_KEY not set')
      return new Response('missing config', { status: 200 })
    }

    const db = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // ── Fetch from Google Places Details API ──────────────────────────────
    const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=reviews&key=${apiKey}`
    const res = await fetch(url)
    const body = await res.json()

    if (body.status !== 'OK') {
      console.error('sync-google-reviews: Places API error:', body.status, body.error_message)
      return new Response('places api error', { status: 200 })
    }

    const reviews: Array<{
      author_name: string
      author_url:  string
      rating:      number
      text:        string
    }> = body.result?.reviews ?? []

    const eligible = reviews.filter(r => r.rating >= minRating && r.text?.trim())

    if (eligible.length === 0) {
      console.log('sync-google-reviews: no eligible reviews')
      return new Response('no eligible reviews', { status: 200 })
    }

    // ── Upsert — ignoreDuplicates: true preserves admin curation ─────────
    // Existing rows (matched on external_id / author_url) are NOT updated.
    // Admin-set is_active=false on a Google review stays false after sync.
    const { error } = await db.from('testimonials').upsert(
      eligible.map(r => ({
        author:        r.author_name,
        role:          'Google Review',
        quote:         r.text.trim(),
        rating:        r.rating,
        source:        'google',
        external_id:   r.author_url,  // unique profile URL — one review per person per place
        is_active:     true,
        display_order: 999,
      })),
      { onConflict: 'external_id', ignoreDuplicates: true },
    )

    if (error) {
      console.error('sync-google-reviews: upsert error:', error.message)
      return new Response('upsert error', { status: 200 })
    }

    console.log(`sync-google-reviews: processed ${eligible.length} reviews`)
    return new Response('ok', { status: 200 })
  } catch (e) {
    console.error('sync-google-reviews: unexpected error:', String(e))
    return new Response('error', { status: 200 })
  }
})
