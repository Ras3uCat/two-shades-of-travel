# Phase 0.5 + Phase 1 — Project Setup & Environment

---

## Phase 0.5 — Start a New Client Project

Each client is an independent copy of the modular project. Never share a directory between clients.

**Use the Raspucat admin setup script (recommended):**

1. Go to the Raspucat admin panel → open the client's quote
2. Click **Generate client.json** → then **Setup Script**
3. Save the downloaded `<slug>-setup.sh` to `~/Downloads/`, then run it from anywhere:
   ```bash
   bash ~/Downloads/<slug>-setup.sh
   ```
   The script creates the client directory itself — no need to `cd` first.

The script clones the template, strips the git history, initialises a fresh repo, writes `client.json`, prompts for Supabase credentials, links the Supabase CLI, and reports progress back to the Raspucat admin delivery tab.

> **Before running the script**, make sure you are logged in to the Supabase CLI — the link step will fail with a privileges error otherwise:
> ```bash
> supabase login
> ```

> The script stops after scaffolding — it does **not** run `deliver.sh`.
> You must run `/inspo` and fill in the remaining `client.json` fields first (see Phase 1.3 below).

**Manual alternative** (if you cannot use the setup script):

```bash
cp -r /path/to/modular_project /path/to/clients/acme-studio
cd /path/to/clients/acme-studio
rm -rf .git
git init
chmod +x execution/frontend/app/deliver.sh execution/frontend/app/prepare.sh
git add -A
git commit -m "scaffold: initial project for acme-studio"
```

> Keep one canonical modular_project as your read-only master template.
> Never deliver work from the template directory directly.

---

## Phase 1 — Environment Setup

### 1.1 — One-time prerequisites (your machine)

Make sure these are installed and on PATH:
```bash
flutter --version    # 3.x, HTML renderer supported
supabase --version   # Supabase CLI
python3 --version    # Used by deliver.sh json parsing
```

Log in to Supabase CLI (once per machine):
```bash
supabase login
```

### 1.2 — Provision client email and create the Supabase project

**Step 1 — Provision the client email address (Raspucat admin)**

Before creating the Supabase project, provision a dedicated email address for this client:

1. Go to your Raspucat admin panel → create or open the client's quote
2. Enter the client/site name → click **Provision Email**
3. Raspucat will generate and register e.g. `footballwinner@raspucat.com` via Cloudflare Email Routing
4. Copy the provisioned address — you will use it as the Supabase account email in the next step
5. Copy the quote UUID — paste it into `client.json` as `RASPUCAT_QUOTE_ID` (see Phase 2)

> All emails sent to the provisioned address automatically forward to your personal inbox.
> See Raspucat feature `013_client_email_provisioning` for full details.

**Step 2 — Create a new Supabase account using the provisioned email**

Each client gets their own Supabase account (not just a project under your account).
This keeps their data, billing, and access fully isolated from your other clients.

1. Sign out of your personal Supabase account (or open an incognito window)
2. Go to [supabase.com](https://supabase.com) → **Sign up**
3. Use the provisioned address (`footballwinner@raspucat.com`) as the email
4. The confirmation email will arrive in your personal inbox via forwarding — click the link
5. Set a strong password and save it in your password manager under the client's name
6. Once signed in, click **New project** and set:
   - **Project name:** use `CLIENT_SLUG` (e.g. `acme-studio`)
   - **Database password:** generate a strong one, save it alongside the account password
   - **Region:** closest to the client's customers
7. Wait for provisioning (~60 seconds)
8. Copy the **Project URL** and **anon/public key** from
   `Project Settings → API → Project URL / anon key`

> When it is time to hand the site off to the client, you can transfer ownership of this
> Supabase account to them by updating the account email to their own address.

> **Plan recommendation: use Pro ($25/mo) for any live client site.**
> Free tier projects automatically pause after 1 week of inactivity — a client site goes down
> silently with no warning. Pro also includes daily database backups and higher auth email limits.
> Factor this into your client pricing.

---

### 1.3 — Run /inspo and finalise client.json

Before running `deliver.sh`, run the brand alignment analysis to validate and fill in the remaining visual fields.

1. Open the client project in Claude Code
2. Run `/inspo` — Claude fetches each URL in `BRAND_INSPO_URLS` and produces a Brand Alignment Report
3. The report is saved to `planning/client/brand_alignment.md`
4. Review the five sections (Visual Brand, Layout, Interactive, Guest Flow, Conflicts)
5. Apply recommended changes to `client.json` — colors, fonts, `HERO_VARIANT`, `HOME_SECTIONS`, `PERSONALITY`
6. Check `FILL_IN` fields flagged in the Raspucat admin dialog and fill any that remain
7. Mark `brand_alignment_complete` in the Raspucat admin delivery tab

> Skip this phase only if `BRAND_INSPO_URLS` is empty **and** all visual fields are already confirmed with the client.
> Do not run `deliver.sh` until this step is complete — the build bakes `client.json` values into the app.

---

### 1.4 — Configure Claude MCP servers for this client project

Claude Code uses MCP servers to query the client's live Supabase schema directly.
Fill in `.claude/settings.local.json` with the credentials from the project you just created.

**Supabase — service role key** (same page you copied the anon key from):

1. `Project Settings → API → Project URL` — paste as `YOUR_SUPABASE_PROJECT_URL`
2. `Project Settings → API → service_role` key (reveal it) — paste as `YOUR_SUPABASE_SERVICE_ROLE_KEY`

> The service role key bypasses RLS — it stays in `.claude/settings.local.json` only.
> That file is `.gitignored` and never committed.

**GitHub — personal access token** (one-time per machine, reuse across clients):

1. GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Scopes needed: `Contents` (read), `Pull requests` (read/write), `Issues` (read/write)
3. Paste as `YOUR_GITHUB_PAT`

After filling in both values, restart Claude Code. Verify with `/health` — MCP servers should
show as active, not placeholder.

---

### 1.5 — Claude Code slash commands

The following slash commands are available inside Claude Code (prefix with `/`).
Run them by typing `/command` in the Claude Code prompt — not in the terminal.

| Command | What it does |
|---------|-------------|
| `/health` | Environment check — Supabase, Flutter, Stripe CLI, MCP servers, active feature |
| `/status` | Current sprint status — active feature, backlog count, recent decisions |
| `/new-client` | Scaffold a new `client.json` interactively, with next-steps checklist |
| `/deliver` | Pre-flight check before running `deliver.sh` — surfaces the first blocking issue |
| `/review` | Structured code review — architecture, The Nevers, security audit |
| `/fix-issue` | Guided bug fix workflow — root cause first, minimal change |
| `/gen-feature` | Scaffold a new feature module (controller, views, repository, binding, route) |
| `/migrate` | Generate a timestamped Supabase migration file with RLS boilerplate |

> Start every session with `/status` to orient Claude on the active task.
> Use `/deliver` before `./deliver.sh` to catch missing fields or config issues early.
