# FEATURE: Client Delivery Skill + Slash Commands
**Mode:** STUDIO
**Priority:** P1
**Status:** BACKLOG

## Overview
The project has 5 delivery scripts (`deliver.sh`, `prepare.sh`, `prepare_mobile.sh`, `build.sh`, `add-module.sh`) with zero Claude context. No other template has this workflow. A `.claude/skills/client-delivery/` skill pack documents the full delivery pipeline so Claude can assist with client onboarding, troubleshoot delivery failures, and guide the `add-module` workflow. Two new slash commands make the most common operations one-liner invocable.

## Acceptance Criteria
- [ ] `.claude/skills/client-delivery/SKILL.md` exists — overview of the full delivery pipeline (client.json → deliver.sh → Supabase → deploy)
- [ ] `.claude/skills/client-delivery/DETAILED_GUIDE.md` exists — field-by-field `client.json` reference, each script's steps, dart-define mapping, common failure modes
- [ ] `/new-client` slash command scaffolds a new `client.json` from prompts (slug, name, personality, modules, Supabase URL, Stripe mode)
- [ ] `/deliver` slash command walks through the pre-flight checklist (client.json fields set, Supabase project linked, secrets pushed, build clean) and surfaces the next blocking step
- [ ] Both commands reference `client.json` fields correctly (SHORT_NAME, SEO_TITLE, MODULES, STRIPE_MODE, PERSONALITY, etc.)

## Scope
- `.claude/skills/client-delivery/SKILL.md` — new
- `.claude/skills/client-delivery/DETAILED_GUIDE.md` — new
- `.claude/commands/new-client.md` — new
- `.claude/commands/deliver.md` — new

## Notes
- Source of truth for client.json fields: `execution/frontend/app/client.json`
- Delivery steps documented in `planning/client/` (16 docs)
- `add-module.sh` workflow should be covered — it's undocumented outside the script itself
- Personality system (luxury, minimal, bold, warm, corporate) should be described in DETAILED_GUIDE
