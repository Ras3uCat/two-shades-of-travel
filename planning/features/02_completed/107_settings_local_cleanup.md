# FEATURE: settings.local.json Cleanup
**Mode:** FLOW
**Priority:** P3
**Status:** BACKLOG

## Overview
`.claude/settings.local.json` contains ~15 long, one-time `flutter build` commands from earlier sessions. These are dead weight — they bloat permission evaluation on every Bash call and make the file hard to read. The file should only contain credentials (MCP server config after feature 104) and any project-specific permissions not covered by `settings.json`.

## Acceptance Criteria
- [ ] All one-time `flutter build --dart-define=...` commands removed
- [ ] All path-specific one-off `chmod`, `flutter pub get`, and `grep` commands removed
- [ ] Remaining `allow` entries are standing permissions not already covered by `settings.json`
- [ ] File is under 30 lines

## Scope
- `.claude/settings.local.json`

## Notes
- Do feature 104 (MCP servers) first — that adds a `mcpServers` block here
- Any permission that appears in both `settings.json` and `settings.local.json` is a duplicate — remove from local
- Standing permission to keep if not in settings.json: `Read(//home/ryan/Documents/development/flutter_apps/dev/modular_project/**)` — broad read access
