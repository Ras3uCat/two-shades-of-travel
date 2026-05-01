# Phase 14 — Post-Go-Live: Redelivery & Updates

Clients change their minds. New modules get added. Brands evolve. Here's how to handle common
post-launch update scenarios without breaking anything.

---

## Adding a new module to an existing live site

Example: client wants the blog module 3 months after launch.

1. Update `client.json` — add `blog` to `MODULES`
2. Run the full pipeline — migrations, edge functions, and the updated sitemap (`prepare.sh`
   regenerates `sitemap.xml` automatically from the new MODULES value):
   ```bash
   ./deliver.sh
   ```
   Or skip the Flutter build if you just want DB + functions first:
   ```bash
   ./deliver.sh --skip-build
   ```
   Then run the build step separately:
   ```bash
   ./deliver.sh --skip-db --skip-functions
   ```
3. Redeploy `build/web/` to hosting
4. Create initial content in admin panel (e.g. first blog post)
5. QA the new module on the live domain

> `./deliver.sh` is safe to re-run on a live project. Migrations are idempotent by design
> (Supabase tracks which have been applied). Edge functions are simply overwritten in place.

> **Adding the shop module to a live site** has one extra step beyond the standard flow:
> after `./deliver.sh` runs, you must register a new Stripe webhook endpoint manually:
> 1. Stripe dashboard → Webhooks → Add endpoint
> 2. URL: `https://<SUPABASE_REF>.supabase.co/functions/v1/shop-webhook`
> 3. Event: `checkout.session.completed`
> 4. Copy the signing secret → `supabase secrets set STRIPE_SHOP_WEBHOOK_SECRET=whsec_...`
>
> See [16_shop.md](16_shop.md) for the full shop delivery guide.

---

## Rebuilding after brand changes

If the client changes colours, fonts, or personality:

1. Update `client.json` with new values
2. Rebuild and redeploy — `prepare.sh` runs automatically and regenerates `index.html`,
   `manifest.json`, and `robots.txt` from the updated values:
   ```bash
   ./deliver.sh --skip-db --skip-functions
   ```

---

## Switching from Stripe test to live keys

1. Update `STRIPE_PK` in `client.json` to `pk_live_...`
2. Update `STRIPE_SK` in Supabase secrets to `sk_live_...`
3. Rebuild the Flutter app (publishable key is embedded in the build):
   ```bash
   ./deliver.sh --skip-db --skip-functions
   ```
4. Register a new live webhook in Stripe dashboard → get new `whsec_...` → update `STRIPE_WEBHOOK_SECRET` in Supabase secrets
5. Delete the test webhook endpoint in Stripe

---

## Rotating a compromised secret

If a Supabase secret is exposed:
1. Go to `Project → Edge Functions → Secrets` → update the value
2. If it's the Supabase anon key, rotate it in `Project Settings → API → Reset anon key`
   then update `client.json` and rebuild
3. If it's a Stripe key, rotate in Stripe dashboard → update Supabase secrets immediately
4. Audit Supabase logs (`Project → Logs → Edge Functions`) for any suspicious calls

---

## Updating the master template with new features

When you add a new module or fix to the master template and want to bring an existing client
up to date:

1. Identify the changed files (migrations, edge functions, Flutter source)
2. Copy only the changed files into the client's project directory
3. Re-run `./deliver.sh` with appropriate flags
4. Run `flutter analyze` and QA the affected modules

> Never copy `client.json` from the template — it contains the template defaults, not the
> client's real values.

---

## Changing the client's domain after launch

Example: site was delivered at `acmestudio.com` and client is moving to `acme.studio`.

1. Update `SITE_URL` in `client.json` → new domain
2. Update `FROM_EMAIL` if it used the old domain
3. Re-run `deliver.sh` to push updated `SITE_URL` secret + regenerate `index.html`:
   ```bash
   ./deliver.sh --skip-db --skip-functions
   ```
4. In Supabase dashboard:
   - `Authentication → URL Configuration` → update **Site URL** and **Redirect URLs**
   - `Edge Functions → Secrets` → confirm `SITE_URL` is updated (deliver.sh pushes it automatically)
5. Re-register any Stripe webhook endpoints with the new Supabase URL if the Supabase project ref changed — the `supabase.co/functions/v1/...` URL does NOT change with domain, only if you move Supabase projects
6. Deploy `build/web/` to the new host
7. Point DNS for new domain → new host
8. Confirm email confirmation links, Stripe `success_url` and `cancel_url` all use the new domain
9. Set up `www` redirect on the new domain
10. Cancel old hosting and remove old DNS records after 24h of confirmed uptime

> Do not forget: **Supabase auth redirect URLs will reject the old domain** once you update them.
> Brief overlap (both domains in Redirect URLs) is safe during cutover.

---

## Promoting a staff member to master / changing roles

Roles are set directly in the database — no rebuild needed.

```sql
-- Promote to master (full admin access)
UPDATE profiles SET role = 'master' WHERE email = 'newowner@clientdomain.com';

-- Demote to staff (own bookings/data only)
UPDATE profiles SET role = 'staff' WHERE email = 'formerowner@clientdomain.com';

-- Demote to regular user (no admin access)
UPDATE profiles SET role = 'user' WHERE email = 'user@clientdomain.com';
```

The user must **sign out and sign back in** after the role change — the JWT is cached and will
not reflect the new role until a fresh token is issued.

> Only one `master` user is needed. It is fine to have multiple masters, but treat it like
> physical key access — give it only to people who need full admin control.

---

## Migrating to a new Supabase project

Rare, but sometimes needed (e.g. client takes over the project from you, project reaches free
tier limits, or you want to move region).

1. Create the new Supabase project
2. Update `client.json` with the new `SUPABASE_URL` and `SUPABASE_ANON_KEY`
3. Export the database from the old project:
   ```bash
   supabase db dump --linked > migration_export.sql
   ```
4. Link to new project: `supabase link --project-ref <new-ref>`
5. Re-run the full pipeline (re-applies all migrations + functions to the new project):
   ```bash
   ./deliver.sh
   ```
6. Restore data from the dump into the new project (via Supabase SQL editor or `psql`)
7. Re-register Stripe webhook endpoints (the Supabase function URL changes with the project ref)
8. Re-register JWT hook in the new project (`Authentication → Hooks`)
9. Invite team members to the new project if applicable
10. Rebuild and redeploy the Flutter app (new `SUPABASE_URL` and `SUPABASE_ANON_KEY` are dart-defines embedded in the build)

> **Auth users do NOT migrate automatically.** Supabase does not expose a user export API.
> Ask the client to re-register their accounts on the new project, then set their roles again in SQL.
> For active booking clients, export `bookings` and `profiles` data manually and re-insert via SQL.
