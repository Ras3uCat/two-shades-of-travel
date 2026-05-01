Apply Brand Alignment Report findings to client.json and activate build skills.

---

**Part 1 — Update client.json design tokens**

1. Read `planning/client/brand_alignment.md`.
   If the file does not exist — stop and tell the user to run `/inspo` first.

2. Read `execution/frontend/app/client.json`.

3. Apply every field where the BAR diff summary differs from the current value:
   PERSONALITY, COLOR_PRIMARY, COLOR_SECONDARY, COLOR_ACCENT, COLOR_SURFACE,
   COLOR_ON_SURFACE, FONT_PRIMARY, FONT_SECONDARY, HERO_VARIANT, NAV_STYLE, HOME_SECTIONS.

4. Write the updated `client.json` back to disk.

5. Print a clear diff of every field changed: `FIELD: old_value → new_value`.
   If no fields changed, confirm the current client.json is already aligned with the BAR.

---

**Part 2 — Activate build skills**

6. Load `.claude/skills/brand-directives/SKILL.md`
7. Load `.claude/skills/flutter_dev/SKILL.md`
8. Confirm the Active Directives are derived from the BAR and the session is ready to build.

---

Remind the user: run `./deliver.sh --skip-db --skip-functions` from `execution/frontend/app/`
to compile the Flutter app with the updated client.json tokens.
