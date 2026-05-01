# Agent Matrix

## Operational Modes
| Mode | Usage | Requirements |
| :--- | :--- | :--- |
| **FLOW** | Bugs, UI, Small Refactors | Small diffs, no schema changes. |
| **STUDIO**| Features, Migrations, Auth | Requires `STUDIO_PLAN.md` + Architect approval. |

## The Pilot Army (Roles & Scopes)
| Role | Responsibility | Authority | Forbidden Actions |
| :--- | :--- | :--- | :--- |
| **Planner** | Decomposition & Roadmap | Strategic | No code implementation. |
| **Architect**| Safety Net & System Design | **Final Say** | No silent overrides. |
| **Flutter** | `/lib` & UI Design | Feature Owner | Logic in Widgets; bypass Repos; generic UI. |
| **Backend** | `backend/` (Supabase) | Data Owner | Skip RLS; trust client state. |
| **Payments** | Stripe (Checkout, Webhooks, Versioning) | Financial Security| Client-side authority. |
| **QA** | Browser/Unit Testing | Validation | Modifying logic to pass tests. |

## Subagent Mapping
- Planner → Claude (cloud)
- Architect → Claude (cloud)
- Flutter → **AntiGravity** (external system agent)
- Backend → backend subagent
- Payments → payments subagent
- QA → qa subagent

## Context Isolation
- Each role operates in its own context window.
- Only summaries may be shared upward.
- Raw code or logs must not be forwarded to Main.

## Investigation Rule
- Multi-file exploration should be delegated to a subagent.
- Subagent returns:
  - affected files
  - key findings
  - risks
  - recommendation

## Handshake Protocol (The "Done" Definition)
- **Planner → Engineer:** Plan is approved in `STUDIO_PLAN.md`.
- **Engineer → QA:** Code is implemented and local unit tests pass.
- **QA → Architect: Validation report saved to `qa/reports/` with "PASS".
- **Architect/Planner (Claude) → AntiGravity:** Final approval given; `CURRENT_TASK.md` marked complete.

## Communication Protocol
1. **Current Status:** `planning/CURRENT_TASK.md` (What is happening right now).
2. **Technical Blueprint:** `STUDIO_PLAN.md` (Deep dive for the current feature).
3. **Audit Trail:** `planning/DECISIONS.md` (Why we chose X over Y).

## Conflict Resolution
1. If **QA** fails a build, **Engineer** must revert or fix; **Architect** cannot override a QA "FAIL" without a documented `decision.md` entry.
2. If **Engineer** finds a plan flaw, they must signal **Planner** to revise the `STUDIO_PLAN.md` before writing more code.

## Critical Guardrails
- **Separate Concerns:** Never combine Planning + Implementation in STUDIO mode.
- **The 300 Rule:** Refer to `CLAUDE.md` for the 300-line file limit.
- **Skill Loading:** Agents must load relevant `.cloud/skills/` before execution.

## Escalation Limit
- A task may loop Planner → Engineer → QA at most 2 times.
- On third failure, Architect must intervene with a design change.

