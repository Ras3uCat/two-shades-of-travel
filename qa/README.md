# QA — Playwright Automated Tests

Runs against the **live deployed client site** (not local Supabase).
Supabase is provisioned from day one, so there's no local emulator needed.

## Setup (once per client)

```bash
cd qa
npm install
npx playwright install chromium
cp .env.example .env
```

Edit `qa/.env`:
- Set `BASE_URL` to the client's live site (from `client.json → SITE_URL`)
- Create test users in Supabase Auth dashboard and fill in credentials
- Set `TEST_STAFF_EMAIL` only if a staff user exists (staff role tests auto-skip if blank)

## Run via deliver.sh (automated — posts result to Raspucat)

```bash
# Full delivery + smoke test in one go
./deliver.sh --smoke-test

# Already deployed — re-run tests only
./deliver.sh --skip-db --skip-functions --skip-build --smoke-test
```

`BASE_URL` is set automatically from `client.json → SITE_URL`. On pass, Raspucat marks
`smoke_test_passed` and advances the client portal to **Deployed**. On fail, the result is
still reported so the checklist reflects the failure.

Requires `qa/node_modules` to be installed and `SITE_URL` to be live — skips gracefully if either is missing.

## Run manually

```bash
cd qa
npm test
```

## Run individual suites

```bash
npm run test:auth     # Auth flows (signup, login, session)
npm run test:booking  # Booking flow (step 1–4, confirmation)
npm run test:admin    # Admin flows (master CRUD, staff restrictions)
```

## View HTML report

```bash
npm run report
```

## Test strategy

Tests target the live site and real Supabase data.
Use **Stripe test mode keys** (`pk_test_/sk_test_`) — no real charges ever occur.

Test users to create in Supabase Auth dashboard:
| Role | Email | Notes |
|------|-------|-------|
| Client | `qa-test@...` | Booking flow, profile, auth |
| Master | `master@...` | Full admin access |
| Staff | `staff@...` | Optional — restricted admin view |

After creating users, set their role in the `profiles` table:
```sql
update profiles set role = 'master' where email = 'master@example.com';
update profiles set role = 'staff'  where email = 'staff@example.com';
```
