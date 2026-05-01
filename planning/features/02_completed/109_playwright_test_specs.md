# FEATURE: Playwright Automated Test Specs
**Mode:** STUDIO
**Priority:** P2
**Status:** COMPLETED

## Overview
`qa/chrome/` contains manual QA checklists for auth flows and Stripe checkout. The Playwright
MCP server is already configured in `.claude/settings.local.json`. This feature converts the
existing checklists into runnable Playwright specs that the QA agent can execute via the MCP,
replacing manual browser testing with automated regression checks.

## Acceptance Criteria
- [ ] `qa/chrome/auth_flows.spec.js` — runnable Playwright spec covering:
  - [ ] Signup → email confirm → login flow
  - [ ] Login with existing credentials
  - [ ] Password reset flow
  - [ ] Session persistence across page reload
  - [ ] Auth-gated route redirect (unauthenticated → login page)
- [ ] `qa/chrome/booking_flow.spec.js` — runnable Playwright spec covering:
  - [ ] Step 1–4 happy path (artist → service → slot → details)
  - [ ] Slot unavailable state shown correctly
  - [ ] Stripe checkout redirect (test mode)
  - [ ] Confirmation page shown after `?booking_id=` param
- [ ] `qa/chrome/admin_flows.spec.js` — runnable Playwright spec covering:
  - [ ] Master login → dashboard visible
  - [ ] Staff login → restricted view (own bookings only)
  - [ ] Service CRUD round-trip
- [ ] `qa/package.json` with Playwright dependency and `test` script
- [ ] `qa/README.md` explaining how to run: `cd qa && npm test`
- [ ] QA agent `/review` command updated to reference `npm test` as automated check

## Scope
- `qa/chrome/auth_flows.spec.js` — new
- `qa/chrome/booking_flow.spec.js` — new
- `qa/chrome/admin_flows.spec.js` — new
- `qa/package.json` — new
- `qa/README.md` — new
- `.claude/commands/review.md` — update to mention `npm test` step

## Notes
- Playwright MCP already configured — QA agent can drive browser directly
- Supabase is live from day one (provisioned immediately after client email). No local emulator needed.
- Tests run against the real deployed project: SUPABASE_URL + SUPABASE_ANON_KEY from client.json
- Stripe: use test mode keys (pk_test_/sk_test_) throughout — real project, test credentials
- Specs should use SITE_URL from client.json (deployed site, not localhost) so tests reflect production behaviour
- Auth flows need a dedicated test user per client — create once in Supabase Auth dashboard, store in `qa/.env`
- `qa/.env` holds: TEST_EMAIL, TEST_PASSWORD, TEST_MASTER_EMAIL, TEST_MASTER_PASSWORD, BASE_URL
- Add `qa/.env` and `qa/node_modules/` to root `.gitignore`
- Benefit: specs can run as part of post-delivery QA on the live site, not just in dev
