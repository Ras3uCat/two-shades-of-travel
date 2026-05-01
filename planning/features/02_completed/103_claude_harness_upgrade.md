# FEATURE: Claude Harness Upgrade
**Mode:** STUDIO
**Priority:** P1
**Status:** COMPLETED
**Source:** Comparison with `dev_files` template (2026-03-27)

---

## Summary

The `dev_files` template has significantly evolved its Claude Code harness. This project uses
an older layout (`.agent/hooks/`, `.cloud/skills/`, `agents.json`) that predates the canonical
`.claude/` structure. This feature migrates and upgrades the harness to match the template.

---

## Gap Analysis: dev_files vs modular_project

### 1. Missing Quality-Gate Hooks (HIGH IMPACT)
`dev_files` has 8 hooks. `modular_project` has 3. The missing 4 are automated quality gates:

| Hook | Trigger | Purpose |
|------|---------|---------|
| `format_dart.sh` | PostToolUse (Write/Edit) | Auto-runs `dart format` on every Dart file written |
| `check_file_size.sh` | PostToolUse (Write/Edit) | Blocks commits when a Dart file exceeds 300 lines |
| `pre_bash.sh` | PreToolUse (Bash) | Runs `dart analyze` on staged files before `git commit` |
| `diagnose_build.sh` | PostToolUseFailure (Bash) | Auto-invokes Claude to diagnose Flutter/Dart build failures |

These hooks enforce THE NEVERS automatically — currently Claude must self-enforce manually.

### 2. Hooks Not Wired to Claude Code settings.json (CRITICAL)
Hooks in `.agent/hooks/` are referenced in `CLAUDE.md` as a JSON block but are **not registered
in `.claude/settings.json`**. Claude Code's harness does not execute them. They only run if
Claude manually calls `bash ./.agent/hooks/...`.

`dev_files` wires all hooks through `.claude/settings.json` using the `hooks` config key, so the
Claude Code runtime triggers them automatically on the correct event.

### 3. Skills Location: .cloud/ → .claude/skills/ (MEDIUM)
Skills live in `.cloud/skills/` — a custom, non-standard path. `dev_files` uses `.claude/skills/`
which Claude Code natively understands. The Skill() tool and skill_loader hook should reference
the canonical path.

`dev_files` skill structure: each skill has `SKILL.md` (overview) + `DETAILED_GUIDE.md` (deep impl).
Current structure: single flat `SKILL.md`. Split high-value skills (stripe, backend) to add DETAILED_GUIDE.

### 4. Agent Definitions: agents.json → .claude/agents/*.md (MEDIUM)
`.claude/agents.json` is a routing matrix. `dev_files` uses individual `.claude/agents/*.md` files —
one per role (architect.md, flutter.md, backend.md, etc.). The markdown format allows each agent to
carry its own full system prompt, tools list, and constraints natively in Claude Code's agent format.

### 5. No Slash Commands Directory (MEDIUM)
`dev_files` has `.claude/commands/` with 6 slash commands:
- `/health` — project health check
- `/status` — current sprint status
- `/review` — code review framework
- `/fix-issue` — structured bug fix workflow
- `/gen-feature` — generate feature plan scaffold
- `/migrate` — DB migration boilerplate

None of these exist in `modular_project`. They reduce friction for common workflows.

### 6. No .claude/rules/ Directory (LOW)
`dev_files` has 3 rule files (flutter_style, api_conventions, testing). These are always-on
constraints injected into every agent context, unlike skills which are loaded on demand.
Candidate rules for this project: `dart_style.md`, `repository_pattern.md`, `rls_policy.md`.

### 7. No CLAUDE.local.md (LOW)
Personal dev preferences (KDE Connect device ID, local ports, shell preference) are scattered
or missing. `dev_files` has a `.gitignored` `CLAUDE.local.md` for this.

---

## Acceptance Criteria

- [ ] `.claude/settings.json` exists with all hooks registered to correct lifecycle events
- [ ] `format_dart.sh` runs automatically after every Dart file write/edit
- [ ] `check_file_size.sh` blocks at 300 lines on every Dart file write/edit
- [ ] `pre_bash.sh` runs `dart analyze` before git commit bash calls
- [ ] `diagnose_build.sh` fires on Bash tool failures
- [ ] Skills migrated to `.claude/skills/` with `SKILL.md` + `DETAILED_GUIDE.md` per skill
- [ ] Agent roles defined as `.claude/agents/*.md` (one file per role)
- [ ] 6 slash commands created in `.claude/commands/`
- [ ] 3 rule files in `.claude/rules/`
- [ ] `CLAUDE.local.md` created (.gitignored) with personal dev config
- [ ] `.agent/` and `.cloud/` legacy dirs removed (or renamed to `_legacy/` until verified)
- [ ] `CLAUDE.md` updated to reflect new paths

---

## Implementation Phases

### Phase A — Settings + Hook Wiring (do first, highest impact)
1. Create `.claude/settings.json` with hook registrations for all 7 hooks
2. Copy `format_dart.sh`, `check_file_size.sh`, `pre_bash.sh`, `diagnose_build.sh` from `dev_files`
3. Move existing hooks to `.claude/hooks/`
4. Verify each hook triggers correctly with a test write

### Phase B — Skills Migration
1. Copy `.cloud/skills/` → `.claude/skills/`
2. Add `DETAILED_GUIDE.md` to the 3 most-used skills (stripe-checkout, backend-dev, frontend-design)
3. Update `skill_loader.sh` to reference new path

### Phase C — Agent Definitions
1. Create `.claude/agents/` directory
2. Write `architect.md`, `flutter.md`, `backend.md`, `payments.md`, `qa.md` from agents.json content
3. Update `CLAUDE.md` agent references

### Phase D — Commands + Rules
1. Create 6 slash command files in `.claude/commands/`
2. Create 3 rule files in `.claude/rules/`
3. Create `CLAUDE.local.md` (add to `.gitignore`)

### Phase E — Cleanup
1. Archive or remove `.agent/` and `.cloud/` legacy dirs
2. Update `CLAUDE.md` boot sequence and hook JSON block
3. Test full session: skill_loader → pre_task → work → post_task notification

---

## Notes
- Phase A alone recovers the auto-formatting and 300-line enforcement (biggest day-to-day win)
- `dev_files/new-project.sh` should be updated to use this project as the reference for future bootstraps
- KDE Connect device ID: `dde92f39ac8040a08b80b8f6e6e964f8` (from post_task.sh)
