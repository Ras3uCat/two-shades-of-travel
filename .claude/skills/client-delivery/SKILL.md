# Skill: Client Delivery Pipeline

## What This Skill Covers
The full lifecycle of delivering a Raspucat client app — from cloning the template to
a live, deployed site. This project's core differentiator: one `client.json` config file
+ one `deliver.sh` command produces an isolated, fully-branded Flutter app with its own
Supabase backend.

## Key Files
- `execution/frontend/app/client.json` — single source of truth for all client config
- `execution/frontend/app/deliver.sh` — orchestrates the full delivery pipeline
- `execution/frontend/app/prepare.sh` — processes web templates + generates sitemap
- `execution/frontend/app/prepare_mobile.sh` — configures native iOS/Android files
- `execution/frontend/app/add-module.sh` — adds a feature module to an existing client
- `planning/client/` — 19-section delivery guide

## Phase 0.1: Inspiration Analysis

**Trigger:** `INSPIRATION_URLS` is non-empty in client.json (populated from Raspucat discovery form).

Run this phase before filling remaining visual brand fields. For each URL:
1. Fetch the page with WebFetch
2. Extract signals from HTML: CSS variables/inline styles (colors), `<link>` Google Fonts tags (typography), script tags (animation libraries: AOS, GSAP, Lottie, Framer Motion), section structure (`<section>`, semantic landmarks), CTA text and placement, visible trust signals (testimonials, credentials, press logos)

Output a **Brand Alignment Report** with five sections:

**A. Visual Brand** — recommended `PERSONALITY`, `COLOR_PRIMARY/SECONDARY/ACCENT` (hex), `FONT_PRIMARY/SECONDARY` (Google Fonts names), `HERO_VARIANT`. Alignment score vs stated PERSONALITY; flag any conflicts.

**B. Layout Patterns (cross-site)** — common section ordering across all URLs, grid density (sparse/balanced/dense), above-the-fold pattern shared by all sites, structural motifs (sticky nav, full-bleed images, card grids). Recommended `HOME_SECTIONS` order derived from cross-site consensus.

**C. Interactive Elements** — scroll behavior (parallax, fade-in, sticky); hover/micro-interaction patterns; carousels/modals/accordions present (Y/N per site); animation library detected. Recommendation: Flutter animation vocabulary to match.

**D. Guest Flow** — hero CTA entry point (Book / Shop / Sign up / Browse); conversion path from homepage to transaction; trust signals shown before CTA; friction removed (guest checkout, inline booking vs redirect). Recommended module sequence and CTA placement for `HOME_SECTIONS`.

**E. Conflicts & Gaps** — tension between stated PERSONALITY and extracted signals; modules selected that none of the inspiration sites use (potential friction); modules not selected that appear prominently in inspiration sites (potential miss).

The report is for human review. Developer applies recommendations to client.json manually — no auto-patching.

---

## Pipeline Overview

```
New client project
      │
      ▼
cp -r modular_project → clients/slug     Phase 0.5 — clone template
      │
      ▼
Inspiration Analysis (if INSPIRATION_URLS set)  Phase 0.1 — brand alignment report
      │
      ▼
Fill client.json                          Phase 2 — config
      │
      ▼
./deliver.sh                              Phase 3–6 — full delivery
  ├── setup.sh (DB migrations + seed)
  ├── Deploy Edge Functions + secrets
  ├── prepare.sh (web templates + sitemap)
  └── build.sh (flutter build web)
      │
      ▼
Manual steps (JWT hook, crons, hosting)   Phase 7+ — post-delivery
      │
      ▼
./add-module.sh <id>                      Anytime — add feature modules
```

## Delivery Modes
- `./deliver.sh` — full delivery (DB + functions + build)
- `./deliver.sh --skip-db` — skip migrations (re-deploy functions only)
- `./deliver.sh --skip-build` — DB + functions, no Flutter build
- `./deliver.sh --mobile` — also configure iOS/Android native files
- `./deliver.sh --register-webhooks` — auto-register Stripe webhook
- `./deliver.sh --dry-run` — validate + print plan, no changes

## Module System
Modules are comma-separated in `client.json` MODULES field. The ModuleRegistry
builds nav + routes dynamically at runtime. Use `./add-module.sh <id>` to add
a module to a live client without re-delivering from scratch.

## When to Load DETAILED_GUIDE.md
- Troubleshooting a deliver.sh failure
- Filling in client.json for a new client
- Deciding which modules to enable
- Setting up mobile delivery
- Using add-module.sh on an existing client
