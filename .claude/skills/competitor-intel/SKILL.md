# Competitor Intelligence Skill
**Skill Name:** competitor-intel
**Description:** Auto-discover and profile the top 5 competitors in a client's niche. Scrape design, content, branding, SEO, and trust signals. Synthesize what winners share — "The Blueprint". Output a print-ready HTML report and a machine-readable feed for /inspo.

**Triggered by:** `/comp-intel` command.

---

## WORKFLOW

### Step 1 — Read Client Context
From `execution/frontend/app/client.json`, extract:
- `BUSINESS_TYPE` — e.g. "spa", "dental clinic", "fitness studio"
- `BUSINESS_CITY` / `BUSINESS_REGION` — geographic target
- `BRAND_TARGET_CUSTOMER` — who the client serves
- `BRAND_THREE_WORDS` — brand feeling
- `CLIENT_NAME` — used in the report header

If any of these fields are missing, tell the user which ones are needed and stop.

---

### Step 2 — Discovery (WebSearch — run all in parallel)

Search for the top performers in the niche using three angles:

**Search A — Google ranking:**
`"[BUSINESS_TYPE] [BUSINESS_CITY]"` — note the top organic results (positions 1–10, excluding directories like Yelp/Google Maps listings)

**Search B — Trustpilot:**
`site:trustpilot.com "[BUSINESS_TYPE]" "[BUSINESS_CITY]"` — extract names + star ratings from results

**Search C — Google reviews proxy:**
`"[BUSINESS_TYPE]" "[BUSINESS_CITY]" "google reviews" "5 star"` — identify businesses with high review volume

**Rank and deduplicate.** Score each business:
- +3 points: appears in organic top 5
- +2 points: Trustpilot score ≥ 4.5
- +1 point: mentioned in reviews search

Select the **top 5 unique businesses** with the highest composite scores. Record their website URLs.

---

### Step 3 — Profile Each Competitor (WebFetch each URL)

For each of the 5 competitors, extract:

**Brand Identity:**
- Business name and tagline
- Logo URL (look for `<img>` with "logo" in src/alt, or `<svg>` in header)
- Primary color (CSS `--primary`, `--color-brand`, or the dominant color in the hero background)
- Secondary color (accent/CTA button color)
- Font names (Google Fonts `<link>` tags, or `font-family` in `<style>` tags)

**Content & Structure:**
- Hero headline (verbatim)
- Primary CTA text and destination
- Services listed (first 5)
- Section order on homepage (e.g. Hero → Services → About → Reviews → CTA)

**Trust Signals:**
- Review count and rating displayed
- Certifications or badges shown
- Awards or press mentions
- Before/after photos, case studies, or testimonials (Y/N)
- "Book online" / instant booking present (Y/N)

**SEO Signals (WebSearch):**
- Run: `site:[domain]` — note approximate page count
- Run: `"[business name]" reviews` — note total review mentions
- Top 3 keywords they appear to rank for (infer from title tags, H1s, meta description)

---

### Step 4 — Synthesize "The Blueprint"

Analyze all 5 profiles and identify what they **all share** or what the **top 3 share**:

**Visual Blueprint:**
- Dominant color temperature (warm / cool / neutral)
- Color palette mood (vibrant / muted / monochrome)
- Typography tone (serif authority / sans-serif modern / script luxury)
- Layout density (spacious / balanced / dense)
- Hero pattern (full-bleed photo / video / split layout / illustration)

**Trust Blueprint:**
- Trust signals present in all 5 (e.g. "all show review count before CTA")
- Average review score of the top 5
- Most common certification type

**CTA Blueprint:**
- Primary CTA verb used most (Book / Schedule / Get / Start / Call)
- CTA placement (hero only / hero + sticky bar / multiple throughout)
- Friction level (inline form / redirect to booking page / phone call)

**Content Blueprint:**
- Service naming convention (descriptive vs. branded vs. outcome-based)
- Common section that appears in 4+ sites
- Content tone (clinical / warm / aspirational / technical)

**SEO Blueprint:**
- Keyword patterns shared across 3+ competitors
- Average indexed page count range
- Common structured data type (LocalBusiness / Service / FAQ)

**Gaps for Client:**
- Trust signals competitors use that client's current client.json config doesn't address
- Modules not selected in client.json that appear in 3+ competitor sites

---

### Step 5 — Generate Outputs

#### Output A: `planning/client/competitor_intel.md`
Machine-readable feed for `/inspo`. Format:

```markdown
# Competitor Intel Feed
_Generated: [date]_

## Top 5 Competitors
| Rank | Name | URL | Score | Primary Color | Font |
|------|------|-----|-------|---------------|------|
| 1    | ...  | ... | ...   | #xxxxxx       | ...  |

## The Blueprint
- **Visual:** [summary]
- **Trust:** [summary]
- **CTA:** [summary]
- **Content:** [summary]
- **SEO keywords:** [comma-separated]

## Gaps for Client
- [gap 1]
- [gap 2]
```

#### Output B: `planning/client/competitor_report.html`
Print-ready client deliverable. Self-contained HTML (no external CDN dependencies — inline all CSS).

**Report structure:**
1. **Cover** — Client name, "Competitive Intelligence Report", date, "Prepared by [agency]"
2. **Market Overview** — Category, city, search landscape summary (1 paragraph)
3. **Competitor Profiles** — One card per competitor:
   - Brand name + tagline
   - Color swatches (primary + secondary as filled circles)
   - Font name
   - Top trust signals
   - Top 3 keywords
   - Hero CTA
4. **The Blueprint** — Visual summary of what winners share (each category as a labeled row)
5. **Keyword Gap Analysis** — Table: keywords competitors rank for, whether client has content for each (Yes/No/Partial)
6. **Strategic Recommendations** — 3–5 numbered actions backed by specific data points from the analysis
7. **Appendix** — Raw competitor URLs + date accessed

**HTML/CSS requirements:**
- Inline all styles — no `<link rel="stylesheet">` or CDN references
- Color palette: dark navy background (#0D1B2A), white text, client's `COLOR_PRIMARY` as accent (fall back to `#58E3EF` if not set)
- Clean card layout with subtle borders
- `@media print { .no-print { display: none; } }` — ensure clean PDF export
- Page break before each major section: `page-break-before: always`
- Font: system-ui stack (no Google Fonts — must work offline)

---

## OUTPUT CONFIRMATION

After writing both files, tell the user:
> "Competitor Intelligence Report saved to `planning/client/competitor_report.html`. Open in browser → File → Print → Save as PDF for client delivery.
> `competitor_intel.md` will be automatically used the next time you run `/inspo` to enrich the brand alignment analysis."

---

## INTEGRATION WITH /inspo

When `/inspo` runs and `planning/client/competitor_intel.md` exists:
- The top 5 competitor URLs are available as supplementary inspiration sources
- The Blueprint findings inform Section B (Layout Patterns) and Section D (Guest Flow)
- Gaps feed directly into Section E (Conflicts & Gaps)
