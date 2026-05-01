# FEATURE: new-client.sh Bootstrap Script
**Mode:** STUDIO
**Priority:** P1
**Status:** COMPLETED

## Overview
Phase 0.5 of every client delivery is currently 6+ manual steps: copy template, remove `.git`,
init new repo, make scripts executable, link Supabase, fill credentials. A `new-client.sh`
script collapses this into one interactive command — matching what `dev_files/new-project.sh`
does for the harness template. Goal: new client project ready for `deliver.sh` in under 2 minutes.

## Acceptance Criteria
- [ ] `new-client.sh` exists at the project root (next to CLAUDE.md)
- [ ] Script prompts interactively: CLIENT_NAME, CLIENT_SLUG, target path, Supabase project ref, Supabase URL, Supabase anon key
- [ ] Copies template to `<target_path>/<CLIENT_SLUG>/`
- [ ] Removes `.git/` and runs `git init && git add . && git commit -m "Initial scaffold — <slug>"`
- [ ] Generates `client.json` from `client.json.example` with prompted values pre-filled
- [ ] Runs `chmod +x` on all `.sh` files
- [ ] Runs `supabase link --project-ref <ref>` in the app directory
- [ ] Configures `.claude/settings.local.json` with placeholder MCP credentials and a reminder to fill them
- [ ] Prints a completion checklist of remaining manual steps (fill remaining client.json fields, run deliver.sh, etc.)
- [ ] Idempotent: re-running on an existing directory warns and exits cleanly

## Scope
- `new-client.sh` — new file at project root
- `planning/client/02_setup.md` — add reference to new script (replaces manual Phase 0.5 steps)

## Notes
- Reference: `dev_files/new-project.sh` for structure and pattern
- Target path default: `/home/ryan/Documents/development/flutter_apps/clients/<CLIENT_SLUG>`
- Should NOT auto-run `deliver.sh` — that requires the full client.json to be completed first
- KDE Connect device ID: `dde92f39ac8040a08b80b8f6e6e964f8` (copy from CLAUDE.local.md for notification on completion)
