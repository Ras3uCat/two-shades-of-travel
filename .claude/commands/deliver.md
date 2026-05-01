Run a pre-flight delivery check and surface the next blocking step: $ARGUMENTS

Load `.claude/skills/client-delivery/SKILL.md` before proceeding.

**Input:** Optional — client slug or path. Defaults to current directory.

---

Check each item below in order. Stop at the first FAIL and output only the fix for that item.
Do not report items that haven't been reached yet.

**Pre-flight Checklist**

1. **client.json exists**
   - Check: `execution/frontend/app/client.json` is present
   - FAIL → run `/new-client` to scaffold it

2. **Required fields set**
   - Check: CLIENT_NAME, CLIENT_SLUG, SUPABASE_URL, SUPABASE_ANON_KEY are non-empty
   - FAIL → list which fields are missing

3. **Supabase linked**
   - Run: `supabase status` from `execution/frontend/app/`
   - Check: output shows a linked project (not "not linked")
   - FAIL → `supabase link --project-ref <ref>` (find ref in Supabase dashboard URL)

4. **Payment fields consistent**
   - If MODULES includes booking/shop/subscriptions: check STRIPE_PK is non-empty
   - If STRIPE_PK is set: warn that STRIPE_SK must be pushed as a Supabase secret separately
   - WARN (non-blocking) → note that payments will be disabled until STRIPE_PK is filled

5. **Email fields consistent**
   - If MODULES includes newsletter: check RESEND_KEY is non-empty
   - WARN (non-blocking) → emails disabled; booking flow still works

6. **SITE_URL set**
   - Check SITE_URL is non-empty
   - WARN (non-blocking) → Stripe redirects will use localhost fallback

7. **Flutter dependencies**
   - Run: `flutter pub get` in `execution/frontend/app/`
   - FAIL → show error output

8. **Dart analyzer clean**
   - Run: `dart analyze execution/frontend/app/lib/ --no-fatal-infos 2>&1 | tail -5`
   - FAIL → show errors; do not proceed to build with analyzer errors

9. **Ready to deliver**
   - All checks passed → print:
     ```
     ✅ Pre-flight complete. Run:
        cd execution/frontend/app && ./deliver.sh

     After deliver.sh completes, finish the manual checklist:
     - Register JWT hook in Supabase Auth → Hooks
     - Set Auth redirect URL in Supabase Auth → URL Configuration
     - Schedule cron jobs (see planning/client/02_setup.md)
     - Deploy build/web/ to hosting
     - Set STRIPE_SK as Supabase secret (if payments enabled)
     ```

---

**Add-module mode** (if $ARGUMENTS contains a module name):
- Check the module is in the known list
- Check it is NOT already in client.json MODULES
- If clear: `cd execution/frontend/app && ./add-module.sh <module>`
- After completion: remind to rebuild + redeploy Flutter (`./deliver.sh --skip-db --skip-functions`)
