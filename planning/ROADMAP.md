# Strategic Roadmap — Raspucat Modular Client Delivery Platform
**Updated:** 2026-03-27 (audit + tooling additions)

## Vision
A Flutter web+mobile template system that lets Raspucat deliver fully custom,
isolated client apps — each with their own brand identity, feature set, and
backend — by filling in one config file and running one command.

## Tech Stack
- **Frontend:** Flutter (GetX, Material 3, HTML renderer)
- **Backend:** Supabase (per-client project, PostgreSQL + RLS)
- **Payments:** Stripe (Standard or Connect multi-staff, per client)
- **Email:** Resend (transactional, via Supabase Edge Functions)
- **Architecture:** See `planning/DECISIONS.md` for full ADR log

---

## Foundation & Core Platform — ✅ COMPLETE

All foundation, booking, commerce, and media modules are shipped.

| Area | What's built |
|------|-------------|
| Foundation | Flutter scaffold, client.json, theme/personality system, ModuleRegistry, Auth, Home, Contact, SEO, deliver.sh |
| Booking | Full booking flow (6 steps), SupabaseBookingRepository, availability, row-locked `book_appointment()` |
| Payments | Stripe Checkout (Standard + Connect), webhooks, stripe-dispatcher, promo codes, deposit, gift vouchers |
| Admin | Master dashboard, staff portal, booking overview, service/staff/content/gallery managers |
| Notifications | Resend email (confirm, remind, cancel, review request), send-reminders + send-review-requests crons |
| Add-ons | Loyalty, referrals, intake forms, SMS phone capture (phone stored — Twilio sending in backlog) |
| Modules | Gallery, Blog, FAQ, Testimonials, Newsletter, GDPR, Shop, Events, iCal export, Service pages, Subscriptions, Courses |
| Dynamic content | business_config CMS, hero/services/team/CTA all DB-driven |
| User profile | Booking history, cancel, resume payment, receipt |
| Delivery | deliver.sh, prepare.sh, prepare_mobile.sh, setup.sh, CLIENT_DELIVERY_GUIDE.md (19 sections) |

---

## Backlog — Implementation Order

Features ordered by: **revenue impact → sell-ability → complexity → dependencies**.
Active task always lives in `planning/features/01_active/`.

---

### Wave 0 — Developer Tooling (Claude Harness)

Internal improvements to the Claude Code workflow. No client-facing impact, but directly
accelerates all future waves by improving session quality and reducing friction.

| # | Feature | File | Complexity | Why now |
|---|---------|------|-----------|---------|
| 103 | Claude Harness Upgrade | `103_claude_harness_upgrade.md` | Low | ✅ COMPLETE — hooks wired, agents/skills/commands/rules migrated to `.claude/` |
| 104 | MCP Servers (Supabase + GitHub) | `104_mcp_servers.md` | Low | ✅ COMPLETE — configured in settings.local.json |
| 105 | Client Delivery Skill + Commands | `105_client_delivery_skill.md` | Med | ✅ COMPLETE — skill + `/new-client` + `/deliver` commands live |
| 106 | MEMORY.md Pruning | `106_memory_pruning.md` | Low | ✅ COMPLETE — 288 → 39 lines, 5 topic files |
| 107 | settings.local.json Cleanup | `107_settings_local_cleanup.md` | Low | ✅ COMPLETE — done alongside 104 |

### Wave 0.5 — Tooling Refinements ✅ COMPLETE (2026-03-27)

Gaps found during post-implementation audit. All 4 items complete.

| # | Feature | File | Complexity | Status |
|---|---------|------|-----------|--------|
| 108 | new-client.sh Bootstrap Script | `108_new_client_bootstrap_script.md` | Med | ✅ COMPLETE — `new-client.sh` at project root, interactive, links Supabase, configures MCP |
| 109 | Playwright Automated Test Specs | `109_playwright_test_specs.md` | Med | ✅ COMPLETE — auth/booking/admin specs, `qa/package.json`, `qa/README.md`, `/review` updated |
| 110 | Harness Polish — Small Fixes | `110_harness_polish.md` | Low | ✅ COMPLETE — diagnose_build CLI guard, /gen-feature rewritten, CURRENT_TASK.md stub, docs updated |
| 111 | Stale Path Pre-Commit Guard | `111_stale_path_precommit_check.md` | Low | ✅ COMPLETE — pre_bash.sh gate blocks .cloud/.agent path references in commits |

---

### Wave 1 — Premium Preset Completers ✅ COMPLETE

All 4 features shipped. Premium plan is fully deliverable.

| # | Feature | File | Complexity | Status |
|---|---------|------|-----------|--------|
| 1 | Tip / Gratuity at Checkout | `091_tip_gratuity.md` | Low | ✅ COMPLETE |
| 2 | Monthly Stats Digest Email | `096_monthly_stats_digest.md` | Low | ✅ COMPLETE |
| 3 | AI Chatbot — Lite | `092_ai_chatbot.md` | Low-Med | ✅ COMPLETE |
| 4 | PWA Push Notifications | `093_push_notifications_pwa.md` | Med | ✅ COMPLETE |

---

### Wave 2 — High-Value, Low-Effort Add-ons ✅ COMPLETE

| # | Feature | File | Complexity | Status |
|---|---------|------|-----------|--------|
| 5 | SMS Reminders (Twilio) | `101_sms_reminders_twilio.md` | Low | ✅ COMPLETE |
| 6 | Stripe Invoicing (admin button) | `098_stripe_invoicing.md` | Low | ✅ COMPLETE |
| 7 | AI Chatbot — Full upgrade | `100_ai_chatbot_full.md` | Low | ✅ COMPLETE |

---

### Wave 3 — Broader Catalog Expansion ✅ COMPLETE

| # | Feature | File | Complexity | Status |
|---|---------|------|-----------|--------|
| 8 | Invoice Generation (PDF via Resend) | `094_invoice_generation.md` | Med | ✅ COMPLETE |
| 9 | Google Reviews Auto-Sync | `099_review_platform_pull.md` | Low-Med | ✅ COMPLETE |
| 10 | Menu / Price List Module | `097_menu_price_list.md` | Low | ✅ COMPLETE |

---

### Wave 4 — Platform Expansion ✅ COMPLETE

| # | Feature | File | Complexity | Status |
|---|---------|------|-----------|--------|
| 11 | Native Mobile Apps (iOS/Android) | `102_native_mobile_apps.md` | Med | ✅ COMPLETE |
| 12 | Multi-Location Support | `095_multi_location.md` | High | ✅ COMPLETE |

---

## Project Guardrails
- State: GetX strict. No `setState` outside widgets. No business logic in widgets.
- Security: Every table has RLS. No client-side role trust. Stripe keys server-only.
- Quality: `flutter analyze` zero errors before any feature is marked complete.
- Task tracking: active feature in `planning/features/01_active/`. Move to `02_completed/` on ship.

## Success Metrics
- New client delivered (scaffolded + deployed) in under 2 hours
- Each Wave 1–2 add-on installable per client in under 30 min (migration + flag in client.json)
- Premium plan fully deliverable after Wave 1 is complete
