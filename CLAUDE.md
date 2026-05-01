# Raspucat Constitution (Global Context)

## ROLE
Claude is the **Planner/Architect** (Global Strategy & Safety).
AntiGravity is the **Flutter Subagent** (Feature Implementation & UI Design).

## AGENT BEHAVIOR
1. **Bootstrap:** Hooks are wired automatically via `.claude/settings.json` — `skill_loader.sh` + `pre_task.sh` fire on SessionStart.
2. **Handshake:** Check `planning/features/01_active/` for the current active feature. AntiGravity leads Flutter/UI tasks, including sub-task planning within those scopes.
3. **Skill Check:** Verify corresponding `.claude/skills/` pack is loaded before implementation.
4. **Constraint:** No implementation until a task is assigned. Summary-only on first message.

## TECH STACK & ARCHITECTURE
- **State Management:** GetX (Strict). Feature-first: `execution/frontend/app/lib/features/<feature>/`.
- **Backend:** Supabase. All DB changes must be timestamped SQL migrations in `execution/backend/supabase/migrations/`.
- **Payments:** Stripe (Checkout + Webhooks). Use `.claude/skills/stripe-*` for implementation.
- **UI:** Material 3 + `E-Prefix` constants (e.g., `EColors.primary`). Use `.claude/skills/frontend-design` for high-end aesthetic execution.

## THE "NEVERS" (Critical Constraints)
- **NEVER** mix business logic in Widgets (UI only).
- **NEVER** exceed 300 lines per file (Refactor > 300 immediately).
- **NEVER** trust client-side state for Auth, Permissions, or Payments.
- **NEVER** bypass the Repository pattern in the data layer.
- **NEVER** ignore `planning/DECISIONS.md` (ADR) history.

## WORKFLOW MODES
- **FLOW:** Small diffs/bugs. Incremental commits.
- **STUDIO:** Complex features. **MANDATORY:** Create a feature plan in `planning/features/00_backlog/` (or `01_active/` if approved), review and approve before implementation. Move to `02_completed/` when done, `03_deprecated/` if cancelled.

## TASK CONTROL (Features Folders)
- `planning/features/00_backlog/` — Planned, not started.
- `planning/features/01_active/` — Currently in progress.
- `planning/features/02_completed/` — Shipped.
- `planning/features/03_deprecated/` — Cancelled or superseded.

## MEMORY & KNOWLEDGE
- **Active Task:** `planning/features/01_active/` (one file per active feature).
- **Historical Context:** `planning/DECISIONS.md`.

## CONTEXT BUDGET
- Target max active context: 6,000 tokens.
- Prefer summaries over raw files.
- Use subagents for multi-file exploration.
- NEVER load more than 3 source files unless explicitly required.

## SUBAGENT RULE
- If a task requires reading more than 3 files, spawn a subagent to investigate and return a summary.
- Main agent must not ingest raw multi-file content.

## LOCAL AGENT DELEGATION
- Flutter UI tasks → delegate to **Flutter subagent AntiGravity**.
- Multi-file investigation → delegate to subagents.
- Do not implement Flutter widgets directly unless explicitly instructed.
- Specialist agents: see `.claude/agents/` (architect, planner, flutter, backend, payments, qa, security-auditor).

## LOCAL SUBAGENT OPTIMIZATION
1. **Bootstrap Speed:** Skip full project analysis. Focus ONLY on the immediate file/task.
2. **Context Density:** Do not read more than 2 files before responding to the initial inquiry.
3. **No-Wait Mode:** Respond as soon as the core task is identified.

## SLASH COMMANDS
- `/health` — environment health check
- `/status` — current sprint status
- `/review` — structured code review
- `/fix-issue` — bug fix workflow
- `/gen-feature` — scaffold new feature
- `/migrate` — generate DB migration boilerplate
