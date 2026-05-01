# STUDIO_PLAN_SERVICE_PAGES.md — Auto-Generated SEO Service Pages

**Feature:** Individual SEO-optimised pages at `/services/[slug]` for each service
**Workflow Mode:** STUDIO
**Status:** APPROVED — Ready for implementation

---

## Key Discoveries

1. **`seo_wrapper_web.dart` does not exist.** `seo_wrapper.dart` comments say "implemented in seo_wrapper_web.dart" but the file is absent. Meta injection (`<title>`, `<meta description>`, OG tags) has been silently no-op since it was written. Phase B must create this file — and should be tested on the home page immediately after.
2. **`services_section.dart` is at 293 lines.** Extracting `_SectionWrapper` + `_SectionHeader` to `section_shared_widgets.dart` (~85 lines) before modifying the file keeps it under 300.
3. **`HomeController` already has `services` obs.** No new repository calls or controllers needed for either the list or detail page.
4. **Booking pre-selection is blocked.** `BookingController._applyBookAgainArgs()` requires both `artistId` + `serviceIds` together — can't pre-select service alone. CTA is a plain `/booking` link in v1.0.
5. **`_slugify()` exists in `blog_manager_view.dart` as a private method.** Must be extracted to a shared `slugify.dart` utility.

---

## Architecture Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | **`ServicesModule`** owns `/services` and `/services/:slug` | Follows `BlogModule` pattern; keeps `HomeModule` clean |
| D2 | **Slug derived client-side** via `ServiceModel.slug` getter | No DB migration; consistent with blog slugify logic |
| D3 | **`slugify()` extracted to `lib/core/utils/slugify.dart`** | Shared by blog manager and new services code; prevents duplication |
| D4 | **`SeoWrapper` extended** with `canonical`, `jsonLd`, `jsonLdId` params | Centralises all head injection; avoids a second mechanism |
| D5 | **`seo_wrapper_web.dart` uses `dart:js_interop`** | Same pattern as `gdpr_bridge_web.dart`; avoids deprecated `dart:html` |
| D6 | **Booking CTA is plain `/booking` link** in v1.0 | Pre-selection requires `artistId` too; v1.1 enhancement |
| D7 | **`/services` is always available** (no MODULES gate) | Services are core content used across booking and home |
| D8 | **`ServiceDetailBinding` guards `HomeController` with `Get.isRegistered`** | Ensures deep-linked `/services/balayage` works without visiting home first |
| D9 | **Sitemap fetches service names from Supabase REST at build time** | Same pattern as blog post slugs in `prepare.sh` |
| D10 | **`canonical` param also sets `og:url`** | Open Graph shares must point to the correct per-page URL |

---

## New Files

| File | Purpose | Est. Lines |
|------|---------|-----------|
| `lib/core/utils/slugify.dart` | Shared `slugify(String)` utility, extracted from blog manager | 25 |
| `lib/core/widgets/seo_wrapper_stub.dart` | No-op stubs for native (moved from bottom of `seo_wrapper.dart`) | 10 |
| `lib/core/widgets/seo_wrapper_web.dart` | `dart:js_interop` DOM impl: title, meta, canonical, JSON-LD injection | 55 |
| `lib/modules/home/views/sections/section_shared_widgets.dart` | Extracted `_SectionWrapper` + `_SectionHeader` to keep `services_section.dart` under 300 | 60 |
| `lib/modules/services/services_module.dart` | `AppModule`: nav item, 2 routes | 45 |
| `lib/modules/services/bindings/service_detail_binding.dart` | Ensures `HomeController` in scope for deep-linked detail pages | 22 |
| `lib/modules/services/views/services_list_view.dart` | `/services` index — responsive grid of all services | 165 |
| `lib/modules/services/views/service_detail_view.dart` | `/services/:slug` — full SEO page with JSON-LD, breadcrumb, CTA | 200 |

**New total: ~582 lines**

---

## Modified Files

| File | Change | Δ Lines |
|------|--------|---------|
| `lib/core/router/app_router.dart` | Add `services`, `serviceDetail` route constants | +2 |
| `lib/core/widgets/seo_wrapper.dart` | Add `canonical`/`jsonLd`/`jsonLdId` params; swap stubs to conditional import | +25 |
| `lib/modules/booking/models/service_model.dart` | Add `slug` getter + `slugify` import | +4 |
| `lib/modules/home/views/sections/services_section.dart` | Make cards tappable → detail; extract shared widgets; net ~−75 lines after extraction | −75 |
| `lib/modules/admin/views/master/blog_manager_view.dart` | Remove private `_slugify()`; import shared utility | −14 |
| `lib/main.dart` | Register `ServicesModule`; add `/services` to deeplink allowlist | +4 |
| `execution/frontend/app/prepare.sh` | Python `slugify()` fn + services REST fetch + sitemap entries | +35 |
| `planning/client/12_qa-checklist.md` | Add "Service Pages" QA section | +14 |

---

## Implementation Checklist

### Phase A — Shared Utilities

- [ ] **A1.** Create `lib/core/utils/slugify.dart`
  ```dart
  String slugify(String text) {
    // lowercase, keep [a-z][0-9], convert spaces/dashes to single dash, trim trailing dash
    // Exact algorithm from blog_manager_view.dart _slugify()
  }
  ```
- [ ] **A2.** Update `blog_manager_view.dart` — remove `_slugify()` private method, import `slugify.dart`, replace call sites
- [ ] **A3.** Add `ServiceModel.slug` getter in `service_model.dart`:
  ```dart
  import '../../core/utils/slugify.dart'; // (adjust path)
  String get slug => slugify(name);
  ```

---

### Phase B — SEO Infrastructure

- [ ] **B1.** Create `lib/core/widgets/seo_wrapper_stub.dart`
  Move the existing no-op function bodies from the bottom of `seo_wrapper.dart` into this file. Confirm 5 functions: `_setDocumentTitle`, `_setMetaContent`, `_setCanonical`, `_injectJsonLd`, `_removeJsonLd`.

- [ ] **B2.** Create `lib/core/widgets/seo_wrapper_web.dart`

  Implement with `dart:js_interop`. Follow the exact pattern of `gdpr_bridge_web.dart`:
  ```dart
  import 'dart:js_interop';
  // Use @JS interop to access document.title, querySelector, createElement, head.appendChild
  // Or use package:web/web.dart if already in pubspec.yaml

  void _setDocumentTitle(String title) { ... }
  void _setMetaContent(String name, String content) {
    // querySelector 'meta[name="$name"]' or 'meta[property="$name"]'
    // set content attribute; create element if missing
  }
  void _setCanonical(String url) {
    // querySelector 'link[rel="canonical"]'
    // set href; create <link rel="canonical"> if missing
  }
  void _injectJsonLd(String id, String json) {
    // querySelector 'script#ld-$id'
    // update innerHTML if exists; else create <script type="application/ld+json" id="ld-$id">
  }
  void _removeJsonLd(String id) {
    // querySelector 'script#ld-$id'?.remove()
  }
  ```

- [ ] **B3.** Modify `lib/core/widgets/seo_wrapper.dart`
  - Add conditional import at top:
    ```dart
    import 'seo_wrapper_stub.dart'
        if (dart.library.js_interop) 'seo_wrapper_web.dart';
    ```
  - Remove inline no-op functions from bottom of file (they move to stub)
  - Add `canonical`, `jsonLd`, `jsonLdId` constructor params
  - In `_updateMeta()`: call `_setCanonical(canonical)`, `_injectJsonLd(jsonLdId, jsonLd)`, `_setMetaContent('og:url', canonical)`
  - In `dispose()` or on route change: call `_removeJsonLd(jsonLdId)` to clean up

- [ ] **B4.** Smoke test — after Phase B, navigate to `/` and verify `<title>` and `<meta name="description">` actually update in browser DevTools. This confirms the long-broken SEO injection now works for all pages.

---

### Phase C — Routing and Module

- [ ] **C1.** Add to `ERoutes` in `app_router.dart`:
  ```dart
  static const services      = '/services';
  static const serviceDetail = '/services/:slug';
  ```

- [ ] **C2.** Create `lib/modules/services/services_module.dart`
  Mirror `BlogModule` structure:
  - `moduleId` = `'services'`
  - `navItem` = `NavItem(label: 'Services', icon: Icons.spa_outlined, route: ERoutes.services)`
  - Route 1: `ERoutes.services` → `ServicesListView`, binding: `HomeBinding()`
  - Route 2: `ERoutes.serviceDetail` → `ServiceDetailView`, binding: `ServiceDetailBinding()`
  - `binding` = null

- [ ] **C3.** Create `lib/modules/services/bindings/service_detail_binding.dart`
  ```dart
  class ServiceDetailBinding extends Bindings {
    @override
    void dependencies() {
      if (!Get.isRegistered<HomeController>()) {
        Get.lazyPut<HomeController>(() => HomeController());
      }
    }
  }
  ```

- [ ] **C4.** Modify `main.dart`:
  - Import `ServicesModule`
  - Add `ServicesModule()` to `ModuleRegistry.init([...])` after `HomeModule()`
  - Add `'/services'` to the `_handleDeepLink` allowed set

---

### Phase D — Views

- [ ] **D1.** Extract to `lib/modules/home/views/sections/section_shared_widgets.dart`
  Move `_SectionWrapper` and `_SectionHeader` out of `services_section.dart`. Import in `services_section.dart`.

- [ ] **D2.** Update `services_section.dart`
  - Wrap `_ServiceCard` in `InkWell(onTap: () => Get.toNamed('/services/${service.slug}'))`
  - Add a small "View details →" `TextButton` at the bottom of each card's column
  - Import `section_shared_widgets.dart`

- [ ] **D3.** Create `lib/modules/services/views/services_list_view.dart` (~165 lines)

  Structure:
  ```
  SeoWrapper(
    title: 'Services — ${AppEnv.clientName}',
    description: 'Browse all services offered at ${AppEnv.clientName}.',
    canonical: '${AppEnv.siteUrl}/services',
  )
  → AppShell (or plain Scaffold matching home page layout)
  → SingleChildScrollView → Column:
      _PageHeader('Our Services')
      Obx(() => loading? spinner : _ServiceGrid(services))
      _BookingBanner() [only if moduleEnabled('booking')]
  ```

  `_ServiceGrid`: `Wrap` or `GridView` of `_ServiceListCard` widgets — each taps to `/services/${s.slug}`. Shows service name, category, duration, price. Matches existing `_ServiceCard` visual style.

- [ ] **D4.** Create `lib/modules/services/views/service_detail_view.dart` (~200 lines)

  **Route parameter:** `final slug = Get.parameters['slug'] ?? ''`

  **Service lookup:** `ctrl.services.firstWhereOrNull((s) => s.slug == slug)`

  **Structure:**
  ```
  Obx(() {
    loading + not-found states handled first
    return SeoWrapper(
      title: '${service.name} — ${AppEnv.clientName}',
      description: service.description ?? '${service.name} at ${AppEnv.clientName} — ...',
      canonical: '${AppEnv.siteUrl}/services/$slug',
      ogImage: service.imageUrl,
      jsonLdId: 'service-$slug',
      jsonLd: _buildServiceJsonLd(service),
    )
    → Scaffold → SingleChildScrollView → Column:
        _Breadcrumb(['Home', 'Services', service.name])  // tappable first two
        _ServiceHero(service)                            // image + name + chips
        _ServiceMeta(service)                            // duration, price
        if description: _Description(service.description)
        _BookingCta(service)                             // CTA → /booking
  })
  ```

  **`_buildServiceJsonLd()`** returns a JSON string:
  ```json
  {
    "@context": "https://schema.org",
    "@type": "Service",
    "name": "<service.name>",
    "description": "<service.description ?? ''>",
    "provider": {
      "@type": "LocalBusiness",
      "name": "<AppEnv.clientName>",
      "url": "<AppEnv.siteUrl>"
    },
    "offers": {
      "@type": "Offer",
      "price": "<service.price.toStringAsFixed(2)>",
      "priceCurrency": "USD"
    }
  }
  ```
  Escape double quotes in description/name using `.replaceAll('"', '\\"')`.

  **`_BookingCta`**: only rendered when `AppEnv.moduleEnabled('booking')`.

---

### Phase E — Sitemap and Docs

- [ ] **E1.** Update `prepare.sh` — add services sitemap block

  Inside the Python heredoc (after blog slugs block):
  ```python
  # ── Services pages ─────────────────────────────────────────────────────────
  def slugify(text):
      result = []
      prev_dash = False
      for ch in text.lower():
          c = ord(ch)
          if (97 <= c <= 122) or (48 <= c <= 57):
              result.append(ch)
              prev_dash = False
          elif ch in ('-', ' ') and not prev_dash and result:
              result.append('-')
              prev_dash = True
      return ''.join(result).rstrip('-')

  if supabase_url and supabase_anon:
      try:
          req = urllib.request.Request(
              supabase_url + '/rest/v1/services?is_active=eq.true&select=name',
              headers={'apikey': supabase_anon, 'Authorization': 'Bearer ' + supabase_anon},
          )
          with urllib.request.urlopen(req, timeout=10) as r:
              services = json.loads(r.read())
          blocks.append(url_block(site_url + '/services', 'weekly', '0.8'))
          for svc in services:
              sl = slugify(svc.get('name', '').strip())
              if sl:
                  blocks.append(url_block(site_url + '/services/' + sl, 'weekly', '0.7'))
          print(f'   ✅ sitemap: {len(services)} service page(s) added')
      except Exception as e:
          print(f'   ⚠  services sitemap skipped: {e}')
  ```

  > **Python `slugify()` must match the Dart implementation exactly.** The algorithm is identical — same char ranges, same dash collapse, same trim.

- [ ] **E2.** Update `planning/client/12_qa-checklist.md` — add Service Pages section:
  ```
  ## Service Pages (SEO)
  - [ ] `/services` renders and lists all active services
  - [ ] Each card links to `/services/[slug]`
  - [ ] `/services/[slug]` page shows correct name, description, price, duration
  - [ ] Browser tab title shows "[Service Name] — [Client Name]"
  - [ ] `<meta name="description">` in page source reflects service description
  - [ ] `<link rel="canonical">` present with the correct service URL
  - [ ] `<script type="application/ld+json">` contains Service schema with name/price
  - [ ] Booking CTA navigates to `/booking` (if booking module enabled)
  - [ ] Breadcrumb "Home → Services → [name]" renders; Home + Services are tappable links
  - [ ] `/services` and each service slug appear in `sitemap.xml`
  - [ ] Direct navigation to `/services/some-slug` works (deep link, no 404)
  - [ ] Slug collision check: no two services produce the same slug
  - [ ] Not-found state shown for unknown slug (e.g. `/services/does-not-exist`)
  - [ ] Service cards on home page (`/`) link to their detail pages
  ```

---

## Gotchas

### G1. `seo_wrapper_web.dart` has been missing — test immediately after Phase B
All existing `SeoWrapper` usage (home, contact, blog posts, etc.) has been silently not updating meta tags. Creating the web file fixes ALL pages at once. Run a smoke test on `/` after Phase B before touching any views.

### G2. JSON-LD script deduplication
`_injectJsonLd(id, json)` must use the `id` to find an existing `<script>` and update its `innerHTML` rather than appending a new one. Without this, navigating A → B → A accumulates duplicate JSON-LD blocks.

### G3. HomeController lifecycle on deep link
`ServiceDetailView` reads `HomeController.services`. On a direct `/services/balayage` deep link, `HomeController.onInit()` fires (via `ServiceDetailBinding`) but `services` may be empty while loading. The `Obx` loading check (`ctrl.isLoading.value && service == null`) must show a spinner — do not show "not found" until loading is complete.

### G4. Slug collision
Two services with names that slugify identically (e.g. "Hair Color" and "Hair-Color" both → `hair-color`) will result in the first match being returned on the detail page. Add a QA checklist note; no v1.0 code guard needed.

### G5. `dart:js_interop` vs `package:web`
Check `pubspec.yaml` for `web:` dependency. If present, use `package:web/web.dart` (`document.querySelector`, `document.createElement`). If absent, use `dart:js_interop` with `@JS` external declarations (follow `gdpr_bridge_web.dart` exactly).

### G6. `og:url` must be set per page
Add `_setMetaContent('og:url', canonical)` alongside `_setCanonical(canonical)` so Open Graph link previews (Slack, iMessage, Twitter) point to the correct service page URL rather than the static home page URL baked into `index.html.tpl`.

### G7. Services nav item always visible
`ServicesModule` always registers its nav item. If a client has no services in the DB, the `/services` page shows an empty state. For clients who don't want the nav item, omit `ServicesModule` from `main.dart` at delivery time (or add a future `SERVICES_ENABLED` flag).

---

## Phase Sequence

```
A1 (slugify.dart) → A2 (blog_manager refactor) + A3 (ServiceModel.slug)
  → B1 (stub) + B2 (web impl) → B3 (SeoWrapper extended) → B4 (smoke test)
    → C1 (ERoutes) → C2 (ServicesModule) → C3 (ServiceDetailBinding)
      → D1 (extract section_shared_widgets) → D2 (services_section update)
      → D3 (ServicesListView) + D4 (ServiceDetailView)
        → C4 (main.dart registration)
          → E1 (prepare.sh) → E2 (docs)
```

---

## v1.1 Enhancements (out of scope)

- **Booking pre-selection:** Extend `BookingController.onInit()` to read `Get.parameters['service']` and pre-select that service ID. CTA becomes `Get.toNamed(ERoutes.booking, parameters: {'service': service.id})`.
- **`og:url` for all pages:** Add canonical + og:url to booking confirmation, blog posts, gallery, events detail pages.
- **`SERVICES_ENABLED` flag:** Gate `ServicesModule` nav item and sitemap entries for clients who only want the home page section.
- **Category filter on `/services`:** Tab bar or chip group to filter by category on the list page.

---

## File Summary

| Category | Files | Lines |
|----------|-------|-------|
| New files | 8 | ~582 |
| Modified files | 8 | +70 net |
| **Grand total** | **16** | **~650** |
