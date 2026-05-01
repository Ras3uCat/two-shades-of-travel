# Skill: image-gen

## Purpose
Source images for the client site using AI generation (Google Imagen 3 via Gemini API) with automatic fallback to royalty-free stock (Unsplash → Pexels). Every prompt is brand-aware, built from `client.json` values automatically.

## When to Load
- User runs `/image-gen <subject>`
- A calling skill (frontend-design, scroll-stop-builder, flutter_dev) needs an asset for a section being built
- User says "find me an image of", "generate an image for", "source a photo of"

## On Load
1. Read `execution/frontend/app/client.json`
2. Extract and hold in memory:
   - `CLIENT_NAME`, `PERSONALITY`, `BRAND_THREE_WORDS`, `BRAND_TARGET_CUSTOMER`
   - `GEMINI_API_KEY` (or fall back to env var `GEMINI_API_KEY`)
   - `UNSPLASH_ACCESS_KEY` (or env var)
   - `PEXELS_API_KEY` (or env var)
3. Build **Brand Context Block**:
   ```
   Brand: <CLIENT_NAME>
   Mood: <BRAND_THREE_WORDS>
   Aesthetic: <PERSONALITY>
   Audience: <BRAND_TARGET_CUSTOMER>
   ```

---

## Invocation Workflow

### Step 1 — Parse Subject
Extract the image subject from `$ARGUMENTS`. If blank, ask the user: "What should the image show?"

### Step 2 — Build Brand-Aware Prompt
```
<subject>, <BRAND_THREE_WORDS> mood, <PERSONALITY> aesthetic,
warm editorial photography, professional lighting, no text overlays,
high resolution, suitable for <BRAND_TARGET_CUSTOMER>
```
Adjust aspect ratio hint based on context:
- "hero" or "background" → landscape 16:9
- "card", "thumbnail", "portrait" → 4:3 or 1:1
- Default → 16:9

### Step 3 — Slugify Filename
Convert subject to snake_case filename: `"artisan cheese board"` → `artisan_cheese_board`
Check `execution/frontend/app/assets/images/` for existing files with that name.
If collision: append `_v2`, `_v3`, etc.

### Step 4 — Try Gemini Imagen 3
```
POST https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict
Header: x-goog-api-key: <GEMINI_API_KEY>
Body:
{
  "instances": [{ "prompt": "<brand-aware prompt>" }],
  "parameters": { "sampleCount": 1, "aspectRatio": "16:9" }
}
```
- **200 OK** → decode `predictions[0].bytesBase64Encoded` → write PNG to `execution/frontend/app/assets/images/<slug>.png`
- **401/403** → log "Gemini key invalid or missing" → go to Step 5
- **429** → log "Gemini quota hit" → go to Step 5
- **Any other error** → log response, go to Step 5

### Step 5 — Fallback: Unsplash

Build a brand-enriched stock query — NOT just the raw subject:
```
<subject> <first word of BRAND_THREE_WORDS> <PERSONALITY> editorial
```
Example: `"hero background artisan bold editorial"` not `"hero background"`

```
GET https://api.unsplash.com/search/photos?query=<brand-enriched-query>&per_page=5&orientation=landscape
Header: Authorization: Client-ID <UNSPLASH_ACCESS_KEY>
```
- **200 OK** → present top 3 results as a numbered list with `urls.regular` and photographer credit
- Ask user: "Which image do you want? (1/2/3)"
- Download chosen image via `urls.full` → save to `execution/frontend/app/assets/images/<slug>.jpg`
- **401/403** or no key → go to Step 6
- **Empty results** → retry with subject + `CLIENT_NAME` industry keyword only (e.g. "cheese artisan" not "field" or "nature")

### Step 6 — Fallback: Pexels

Use the same brand-enriched query as Step 5.

```
GET https://api.pexels.com/v1/search?query=<brand-enriched-query>&per_page=5&orientation=landscape
Header: Authorization: <PEXELS_API_KEY>
```
- **200 OK** → present top 3 results (photographer + `src.large2x` URL)
- Ask user to pick → download → save to `execution/frontend/app/assets/images/<slug>.jpg`
- **No key / failure** → go to Step 7

### Stock Query Rules (applies to Steps 5 & 6)
- NEVER send a generic subject alone ("background", "hero", "card") — always include brand adjectives
- NEVER accept results that are clearly off-industry (nature landscapes, fields, generic office photos) — if top results are irrelevant, tighten the query with the industry noun (e.g. "cheese", "food", "restaurant") and retry once
- If the subject itself is abstract ("texture", "pattern", "overlay"), prefix with `CLIENT_NAME` industry: `"cheese texture dark moody"`

### Step 7 — All Sources Unavailable
Report clearly:
```
No image sources are configured. To enable image-gen, add at least one key to client.json:

  "GEMINI_API_KEY": "..."       → Google AI Studio (free): https://aistudio.google.com/apikey
  "UNSPLASH_ACCESS_KEY": "..."  → Unsplash Developers (free): https://unsplash.com/developers
  "PEXELS_API_KEY": "..."       → Pexels API (free): https://www.pexels.com/api/
```

### Step 8 — Output Contract
After successfully saving an image, always emit this block so calling skills can parse it:
```
IMAGE_GEN_RESULT:
  path: execution/frontend/app/assets/images/<slug>.<ext>
  source: gemini | unsplash | pexels
  subject: <original subject string>
  prompt: <full brand-aware prompt used>
```
Then remind the user: "Add `assets/images/` to `pubspec.yaml` if not already listed."

---

## Cross-Skill Usage

Other skills invoke image-gen by including this instruction in their workflow:
```
Run image-gen for: "<subject>" and wait for IMAGE_GEN_RESULT before continuing.
```

| Calling Skill | Typical subject passed |
|---|---|
| `frontend-design` | section name, e.g. "hero background", "services card thumbnail" |
| `scroll-stop-builder` | "scroll animation background still", "product texture close-up" |
| `flutter_dev` | "placeholder image for <WidgetName>" |
| `brand-directives` | "mood board reference for <PERSONALITY>" |

---

## Enforcement Rules
- NEVER hardcode brand values — always read from `client.json`
- NEVER overwrite existing asset files — use versioned suffixes
- NEVER use images with visible watermarks — verify Unsplash/Pexels license before saving
- ALWAYS emit `IMAGE_GEN_RESULT:` block after success — calling skills depend on it
- ALWAYS attribute stock photos per platform terms (store attribution in `planning/client/asset_credits.md`)
