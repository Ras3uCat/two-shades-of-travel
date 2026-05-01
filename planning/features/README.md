# Features Directory
This folder contains one file per feature describing behavior and requirements.
- **Roadmap:** Defines *when* to build.
- **This Directory:** Defines *what* to build.

## Sequential Numbering
- Primary Features are numbered in the order they are added to the project. 001_feature_name.md
- Sub-features are numbered in the order they are added to the parent feature. 001_feature_name/001_sub_feature_name.md

## Directory Structure
- 00_backlog/: Initial drafts and "pitches" created by the Planner.
- 01_active/: Features approved by the Architect and currently being built.
- 02_completed/: Features that have passed all Acceptance Criteria.
- 03_deprecated/: Features that have been removed or replaced.

## Rules
* **One feature per file:** Avoid "Mega-features." Split into `sub_features` if the file exceeds 200 lines.
* **Snake_case naming:** `badges_achievements.md`.
* **Acceptance Criteria:** Must be binary (Pass/Fail).
* **Context Isolation:** Reference existing ADRs (from `decisions.md`) instead of re-explaining architecture.

## Agent Hand-off
* **Planner:** Responsible for drafting these feature files in the `00_backlog` directory.
* **Architect:** Must approve the "Scope" and "Backend" sections before moving the feature to the `01_active` directory.
* **Flutter Subagent:** Focuses 100% on the **UX** and **Acceptance Criteria** sections.

---

## Minimal Template
# [ID]_[Feature Name]

## Status
- [ ] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

## Overview
High-level "pitch" of the feature and value proposition.

## User Stories
- As a user, I want to [do something] so that [benefit].

## Acceptance Criteria (Binary Pass/Fail)
- [ ] Criterion 1 (e.g., "User sees toast on success")
- [ ] Criterion 2 (e.g., "Stripe metadata includes quest_id")

## Design Decisions 
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Auth Provider | Supabase Auth | Native integration with DB |

## Data Model & RLS
- **Tables:** [New/Modified Tables]
- **Logic:** [Triggers, Functions, or Views]
- **Security:** [Specific RLS Policy descriptions]

## Scope Control
- [ ] **Included:** Specific list of items.
- [ ] **NOT Included:** Items explicitly excluded to prevent creep.

## UX & UI Design
- **Flow:** [Step 1] → [Step 2]
- **Widgets:** List any `E-Prefix` components or new Flutter widgets.

## Implementation Detail
- **Backend:** Schema changes, Edge Functions, or Cron jobs.
- **Frontend:** New/Modified files in the Flutter project.

## Edge Cases & QA
- [ ] Error handling for offline mode.
- [ ] Validation for empty states.
