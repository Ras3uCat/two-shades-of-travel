Auto-discover and profile the top 5 competitors in the client's niche. Generate a print-ready Competitive Intelligence Report and a machine-readable feed for /inspo.

Load `.claude/skills/competitor-intel/SKILL.md` before proceeding.

---

Follow the full 5-step workflow defined in the skill:

1. Read client context from `execution/frontend/app/client.json`
2. Discover top 5 competitors via WebSearch (Google ranking + Trustpilot + reviews)
3. Profile each competitor via WebFetch (brand, content, trust signals, SEO)
4. Synthesize "The Blueprint" — what winners share across visual, trust, CTA, content, and SEO dimensions
5. Generate both outputs:
   - `planning/client/competitor_intel.md` — machine-readable feed for /inspo
   - `planning/client/competitor_report.html` — print-ready client deliverable

After saving both files, confirm to the user and suggest next steps.
