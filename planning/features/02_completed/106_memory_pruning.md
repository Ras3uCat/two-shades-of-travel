# FEATURE: MEMORY.md Pruning + Reorganization
**Mode:** FLOW
**Priority:** P2
**Status:** BACKLOG

## Overview
MEMORY.md is 288 lines and already truncating (Claude only loads the first 200 lines of the index). The bulk of content is implementation detail that belongs in topic files, not the index. The index should be ~30 one-liner entries pointing to topic files. This directly degrades session quality every time the project is opened.

## Acceptance Criteria
- [ ] `MEMORY.md` index is under 60 lines — one line per memory file entry
- [ ] Implementation detail (Enhancement Batch sections, Key Patterns, Module patterns) extracted into topic memory files under `memory/`
- [ ] Each extracted file has correct frontmatter (name, description, type)
- [ ] All existing factual content is preserved — nothing lost, just reorganized
- [ ] `MEMORY.md` loads fully within the 200-line truncation limit

## Scope
- `/home/ryan/.claude/projects/-home-ryan-Documents-development-flutter-apps-dev-modular-project/memory/MEMORY.md`
- New topic files in the same `memory/` directory

## Suggested Topic Files to Extract
- `memory/enhancement_batches.md` — batch 1/2/3 details
- `memory/module_patterns.md` — Blog, Gallery, Newsletter, GDPR, FAQ, Testimonials key patterns
- `memory/stripe_patterns.md` — Stripe integration patterns
- `memory/delivery_pipeline.md` — deliver.sh automations, prepare.sh, mobile
- `memory/flutter_patterns.md` — main.dart patterns, admin module, booking add-ons
- `memory/architecture_decisions.md` — summary of ADR decisions

## Notes
- Keep "What This Project Is", "Current Status", and "Key Files" in the MEMORY.md index — these are high-value at-a-glance context
- project_enhancement_batch3.md already exists as a topic file — follow that pattern
