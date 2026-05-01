# Phase 9 — Deploy the Flutter Build

The Flutter build output is at: `execution/frontend/app/build/web/`

> The `web/_redirects` file is already in the template — Cloudflare Pages and Netlify use it
> automatically for SPA routing on every build. No manual step required.

**Check file count before choosing a host:**
```bash
find build/web -type f | wc -l
```
Cloudflare Pages has a 20,000 file limit. Typical build: 500–2,000 files.

---

## Option A — Cloudflare Pages (best if client uses Cloudflare DNS)

Unlimited bandwidth. If the client's domain is already on Cloudflare, domain wiring is instant.

```bash
npm install -g wrangler
wrangler pages deploy build/web --project-name acme-studio
```

Or drag `build/web/` to [pages.cloudflare.com](https://pages.cloudflare.com) → **Upload assets**.

**Custom domain — already on Cloudflare:**
Pages project → **Custom domains** → **Set up a custom domain** → Cloudflare wires it automatically.

**Custom domain — NOT on Cloudflare:**
Add a CNAME at their current DNS provider pointing to `<project>.pages.dev`, or migrate to
Cloudflare (recommended — free, CDN benefits immediate).

---

## Option B — Vercel

```bash
npx vercel --prod build/web
```

Add `vercel.json` for SPA routing:
```json
{
  "rewrites": [{ "source": "/((?!_flutter|assets|favicon.png).*)", "destination": "/index.html" }]
}
```

> Free tier meters bandwidth. Use Cloudflare Pages for sites that may spike.

---

## Option C — Netlify

Drag `build/web/` to [app.netlify.com](https://app.netlify.com). The `_redirects` file handles
SPA routing automatically.

---

## Option D — Firebase Hosting

```bash
firebase init hosting   # Select build/web as public dir
firebase deploy
```

---

## www redirect

Most clients expect both `www.acme.studio` and `acme.studio` to work. Set up a redirect so one
always points to the other (apex → www or www → apex — pick one and be consistent).

**Cloudflare:** `DNS → Add record` — add a CNAME for `www` pointing to `@` (apex), then in
`Rules → Redirect Rules` create: `www.acme.studio/*` → `https://acme.studio/$1` (301).

**Vercel / Netlify:** Add both domains in the project dashboard — the hosting provider handles
the redirect automatically when both are added.

**Firebase:** Add both domains; set one as primary and Firebase handles the redirect.

---

## Cutting over from an existing site

If the client has an existing live site, don't flip DNS until the new site has fully passed QA.

Recommended cutover process:
1. Complete QA using the temporary `*.pages.dev` / `*.vercel.app` / `*.netlify.app` URL
2. Schedule the cutover for a low-traffic time (early morning)
3. Set DNS TTL to 300 seconds (5 min) at least 24 hours before the cutover
4. Update DNS records to point to the new host
5. Wait for propagation (check with `dig acme.studio` or [dnschecker.org](https://dnschecker.org))
6. Confirm site loads on the live domain
7. Remove the old hosting account / DNS records

> Do not cancel the old hosting until DNS has propagated and you have confirmed the new site is
> live and healthy for at least 24 hours.

---

## Mobile app deployment (iOS / Android)

Web deployment is covered above. For native app builds and App Store / Play Store submission,
see [15_mobile.md](15_mobile.md).

The short version: run `./deliver.sh --mobile` to generate native assets, then build with
`flutter build appbundle` (Android) or `flutter build ipa` (iOS), or let Codemagic CI do it
automatically on each push.
