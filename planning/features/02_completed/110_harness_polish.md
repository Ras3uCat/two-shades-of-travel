# FEATURE: Harness Polish — Small Fixes
**Mode:** FLOW
**Priority:** P2
**Status:** BACKLOG

## Overview
Four small gaps identified in the Claude harness during the 2026-03-27 audit. Each is a
5–10 minute fix but together they close real holes in the developer experience.

## Acceptance Criteria

### 1. diagnose_build.sh — Claude CLI guard
- [ ] Hook checks `command -v claude >/dev/null 2>&1` before attempting `claude --print`
- [ ] If `claude` not on PATH, hook exits 0 silently (no error noise)
- **File:** `.claude/hooks/diagnose_build.sh`

### 2. /gen-feature command — fix scaffold layout
- [ ] Controller scaffolded at `lib/features/<slug>/controllers/<slug>_controller.dart` (not `lib/controllers/`)
- [ ] Binding at `lib/features/<slug>/bindings/<slug>_binding.dart`
- [ ] Abstract repository + Supabase concrete implementation (not single repository file)
- [ ] Feature file structure matches this project's actual architecture
- **File:** `.claude/commands/gen-feature.md`

### 3. planning/CURRENT_TASK.md — create stub
- [ ] File exists at `planning/CURRENT_TASK.md`
- [ ] Content: one-liner redirecting to `planning/features/01_active/` as the source of truth
- [ ] AGENTS.md reference is satisfied
- **File:** `planning/CURRENT_TASK.md` — new

### 4. planning/client/02_setup.md — mention slash commands
- [ ] Section 1.3 (or new 1.4) lists available slash commands with one-line descriptions
- [ ] Covers: `/health`, `/status`, `/deliver`, `/new-client`, `/review`, `/fix-issue`, `/gen-feature`, `/migrate`
- [ ] Explains these run inside Claude Code (not terminal)
- **File:** `planning/client/02_setup.md`

## Scope
- `.claude/hooks/diagnose_build.sh`
- `.claude/commands/gen-feature.md`
- `planning/CURRENT_TASK.md` — new
- `planning/client/02_setup.md`
