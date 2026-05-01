Enrich the client's brand brief fields in client.json before running /inspo.

Poor brand brief inputs produce generic /inspo output and off-brand images. This command ensures all fields are discovery-grade before any analysis runs.

---

1. Read `execution/frontend/app/client.json`

2. Display current values for the brand brief fields:
   - `BUSINESS_TYPE`
   - `BRAND_THREE_WORDS`
   - `BRAND_CELEBRITY`
   - `BRAND_TARGET_CUSTOMER`
   - `BRAND_INSPO_URLS`

3. Flag any field that is a placeholder or too vague (single generic word, "FILL_IN", empty):
   - `BUSINESS_TYPE`: needs to be a specific business category (e.g. "artisan cheese shop" not "shop")
   - `BRAND_THREE_WORDS`: needs to be evocative mood/feeling words (e.g. "Aged Indulgent Tactile" not "Cheesy Yummy Gooey")
   - `BRAND_CELEBRITY`: needs a real person + brief reason (e.g. "Sofia Coppola — moody, cinematic, effortlessly cool")
   - `BRAND_TARGET_CUSTOMER`: needs demographics + lifestyle (e.g. "food-obsessed urban professionals 28–45 who host dinner parties")
   - `BRAND_INSPO_URLS`: must be a proper JSON array — `["https://a.com", "https://b.com"]` not space-separated

4. For each flagged field, ask the user the enrichment question:

   - **BUSINESS_TYPE:** "What type of business is this? Be specific — e.g. 'artisan cheese shop', 'online cheese subscription box', 'cheese catering service'"
   - **BRAND_THREE_WORDS:** "What three words describe how you want customers to FEEL when they visit the site? Think mood, not product. E.g. 'Seductive Warm Curious'"
   - **BRAND_CELEBRITY:** "Whose aesthetic does this brand want to channel? Give a name + one sentence on why. E.g. 'Nigella Lawson — sensual, indulgent, makes food feel like an experience'"
   - **BRAND_TARGET_CUSTOMER:** "Describe your ideal customer in one sentence — age range, lifestyle, what they value. E.g. 'Food-obsessed professionals aged 28–45 who treat dining as entertainment'"
   - **BRAND_INSPO_URLS:** "List 2–4 websites whose visual style you love (not necessarily competitors). Paste each URL on its own line."

5. After collecting answers, write the updated fields back to `execution/frontend/app/client.json`.
   - Convert multi-line BRAND_INSPO_URLS input to proper JSON array: `["url1", "url2", "url3"]`
   - Preserve all other fields exactly as they are

6. Print a confirmation diff: `FIELD: old_value → new_value`

7. **Generate shareable HTML report:** Create `planning/client/brand_brief_report.html` as a self-contained client deliverable. Requirements:
   - Inline all CSS — no external CDN or `<link>` tags (except Google Fonts @import for font preview only)
   - Use `COLOR_SURFACE` from client.json as page background (fall back to `#0D0907`), `COLOR_PRIMARY` as accent
   - `@media print { .no-print { display: none; } }` for clean PDF export
   - `page-break-before: always` before each major section
   - Font: system-ui stack for UI chrome; Google Fonts @import for FONT_PRIMARY/FONT_SECONDARY preview cards only

   HTML report structure:
   1. **Cover** — Client name (`CLIENT_NAME`), "Brand Brief", date, "Prepared by Raspucat"
   2. **Business Identity** — `BUSINESS_TYPE` + `CLIENT_NAME` displayed as a headline card
   3. **Brand Feeling** — Three large word cards for `BRAND_THREE_WORDS`, each styled in `COLOR_PRIMARY`
   4. **Celebrity Aesthetic** — Name + reason displayed as a pull quote; note what visual signals to draw from their aesthetic
   5. **Target Customer** — Customer profile card with the full sentence + inferred signals (age range, lifestyle keywords extracted and displayed as tags)
   6. **Inspiration URLs** — Each URL as a clickable card with the domain name and a "Visit →" link
   7. **Before / After Diff** — Two-column table showing only client-facing fields: `BUSINESS_TYPE`, `BRAND_THREE_WORDS`, `BRAND_CELEBRITY`, `BRAND_TARGET_CUSTOMER`. Do NOT include `BRAND_INSPO_URLS` or any internal/technical fields in this table.

   Do NOT include a Next Steps section — that is internal workflow information, not relevant to the client.

8. Confirm: "Brand brief updated and saved to `client.json`. Report saved to `planning/client/brand_brief_report.html` — open in browser or print to PDF to share with the client. Run `/comp-intel` next for competitor analysis."

---

**Quality bar for each field:**
| Field | Too vague ❌ | Discovery-grade ✅ |
|-------|-------------|-------------------|
| BUSINESS_TYPE | "shop" | "artisan cheese shop and tasting room" |
| BRAND_THREE_WORDS | "Cheesy Yummy Good" | "Aged Indulgent Theatrical" |
| BRAND_CELEBRITY | "Rob Lowe" | "Nigella Lawson — sensual, makes food feel like seduction" |
| BRAND_TARGET_CUSTOMER | "cheese eaters" | "food-obsessed urban professionals 28–45 who host dinner parties" |
| BRAND_INSPO_URLS | space-separated string | proper JSON array of 2–4 URLs |
