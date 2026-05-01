# FEATURE: Stale Path Pre-Commit Guard
**Mode:** FLOW
**Priority:** P3
**Status:** BACKLOG

## Overview
Nothing currently prevents accidentally re-introducing legacy path references (`.cloud/`,
`.agent/`, `settings.local.json` hardcoded paths, old hook locations) into new code or docs.
A grep check in `pre_bash.sh` on git commits catches this drift before it lands.

## Acceptance Criteria
- [ ] `pre_bash.sh` checks staged files for stale path patterns before any `git commit`
- [ ] Blocks commit with clear message if any of these are found in staged files:
  - `.cloud/skills/` — old skills path
  - `.agent/hooks/` — old hooks path
  - `/.agent/` — old agent dir reference
  - `agents.json` — replaced by `.claude/agents/*.md`
- [ ] Exempts binary files and the legacy dirs themselves (if any remain as archive)
- [ ] Does NOT block on false positives (e.g., this very feature file mentioning `.cloud/`)
- [ ] Existing secret-scan and dart-analyze gates still run after this check

## Scope
- `.claude/hooks/pre_bash.sh` — add stale-path check block before existing git commit gates

## Notes
- Pattern should use `grep -l` on staged files list, not full repo scan
- Should only fire on `git commit` commands (same gate as secret scan)
- Exempt files: `planning/features/**`, `MEMORY.md`, `*.md` in memory/ (docs may legitimately reference old paths)
