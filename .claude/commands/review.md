Review the code changes in the current session or the specified file/feature: $ARGUMENTS

Perform a structured code review covering:

1. **Architecture Compliance**
   - Controllers only in `lib/controllers/` (never inside feature folders)
   - Repository pattern in place (no direct API calls from controllers or widgets)
   - No business logic in widgets
   - Barrel exports used correctly (per-layer, not global)

2. **The Nevers Check**
   - [ ] No business logic in Widgets
   - [ ] No file exceeds 300 lines
   - [ ] No client-side auth/permission/payment state decisions
   - [ ] No bypass of Repository pattern
   - [ ] No contradiction with `planning/DECISIONS.md`

3. **GetX Wiring**
   - Controllers registered in `lib/bindings/app_bindings.dart` or a route-level binding
   - `GetView<TController>` used in views (not `Get.find()` ad-hoc in build methods)
   - Reactive state uses `Obx()` with `.obs` RxTypes

4. **Design Token Compliance**
   - EColors, ESpacing, ETextStyles used — no inline hex or magic numbers

5. **Security Audit**
   Invoke the security-auditor agent on all files changed in this session (or matching $ARGUMENTS).
   Append the agent's findings verbatim under a "## Security Findings" section.
   If the agent returns any CRITICAL or HIGH severity finding, the overall review status is FAIL regardless of other sections.

6. **Automated QA**
   If `qa/.env` exists and `BASE_URL` is set, run the Playwright suite:
   ```bash
   cd qa && npm test
   ```
   Report pass/fail counts per spec file. Any spec failure is a WARN (live site may have no test data).
   If `qa/.env` is missing, note "Playwright not configured — see qa/README.md".

7. **Test Coverage**
   - Corresponding test file exists for every new repository/controller/service

Output a markdown report with:
- PASS / WARN / FAIL per section
- Specific file:line citations for any issues
- Recommended fixes for FAIL items
