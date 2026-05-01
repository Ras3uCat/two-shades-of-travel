Analyze inspiration URLs from client.json and produce a Brand Alignment Report.

Load `.claude/skills/client-delivery/SKILL.md` before proceeding.

---

Follow Phase 0.1: Inspiration Analysis from the skill.

1. Read `execution/frontend/app/client.json`
2. Parse `BRAND_INSPO_URLS` as a JSON array (Raspucat exports it as `["https://...","https://..."]` or `[]`).
   If the array is empty or the field is missing — stop and tell the user to add inspiration URLs in the Raspucat discovery form first.
3. Read the brand brief context fields before fetching any URLs:
   - `BRAND_THREE_WORDS` — the three words that describe the brand's desired feeling
   - `BRAND_CELEBRITY` — the celebrity whose aesthetic this brand wants to channel
   - `BRAND_TARGET_CUSTOMER` — who the site is for (age, lifestyle, needs)
   Use these as your interpretive lens throughout the analysis:
   - When URL signals are ambiguous, break ties toward BRAND_THREE_WORDS
   - Ask "does this site feel like [BRAND_CELEBRITY]'s aesthetic?" for each URL — flag contradictions
   - Evaluate every guest flow decision through the eyes of BRAND_TARGET_CUSTOMER
4. Iterate over the parsed URL array. Fetch each URL with WebFetch.
4. Analyze each page and produce the Brand Alignment Report with these five sections:

**A. Visual Brand**
Recommended PERSONALITY (with reasoning), COLOR_PRIMARY / COLOR_SECONDARY / COLOR_ACCENT (hex), FONT_PRIMARY / FONT_SECONDARY (Google Fonts names), HERO_VARIANT. Alignment score vs stated PERSONALITY; flag any conflicts.

**B. Layout Patterns (cross-site)**
Common section ordering across all URLs, grid density (sparse / balanced / dense), above-the-fold pattern shared across sites, structural motifs (sticky nav, full-bleed images, card grids). Recommended HOME_SECTIONS order derived from cross-site consensus.

**C. Interactive Elements**
Scroll behavior (parallax, fade-in, sticky — check script tags for AOS, GSAP, Lottie, Framer Motion), hover/micro-interaction patterns, carousels/modals/accordions present (Y/N per site), animation library detected. Recommend Flutter animation vocabulary to match.

**D. Guest Flow**
Hero CTA entry point (Book / Shop / Sign up / Browse), conversion path from homepage to transaction, trust signals shown before CTA, friction removed (guest checkout, inline booking vs redirect). Recommended module sequence and CTA placement for HOME_SECTIONS.

**E. Conflicts & Gaps**
Tension between stated PERSONALITY and extracted signals. Modules selected in client.json that none of the inspiration sites use (potential friction). Modules not selected that appear prominently in inspiration sites (potential miss).

---

**Output format:** Markdown report. End with a diff-style summary of recommended changes to client.json fields — only list fields where the recommendation differs from the current value.

**After producing the report:** Save the full report to `planning/client/brand_alignment.md`. Confirm the file was written and tell the user they can now run `/build` to have these findings influence the Flutter build.
