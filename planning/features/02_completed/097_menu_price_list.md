# Feature — Menu / Price List Module
**Created:** 2026-03-26 | **Updated:** 2026-03-26 (2nd pass) | **Mode:** FLOW | **Status:** COMPLETE
**Priority:** Low | **Complexity:** Low
**Flag:** `menu` added to `MODULES` in client.json

---

## Objective

A CMS-managed menu or price list page for businesses that don't take bookings — cafes, restaurants,
tattoo studios, barbershops with service menus. Filterable by category. Admin-managed.

---

## What's Already in Place

- `services` table exists but is booking-linked (artist_services join, is_active, pricing tied to
  `book_appointment()`). Do NOT reuse — coupling is unsafe when booking module is also active.
- `ServiceManagerView` admin pattern can be cloned almost 1:1 for the menu admin view.
- `GallerySection` grid layout is reusable for a visual menu.
- `AppModule` registration pattern confirmed — `moduleEnabled('menu')` gates nav + routes.
- `ModuleRegistry` in `main.dart` registers modules — `MenuModule` added here conditionally:
  `if (AppEnv.moduleEnabled('menu')) MenuModule()` (same pattern as ShopModule, EventsModule).
- `admin_shell.dart` uses `_NavEntry(label, icon, route)` (positional args) — NOT `_NavItem`.
  Menu entry added here gated on `AppEnv.moduleEnabled('menu')`.
- `home_view.dart` routes home sections through `_sectionForId()` switch (lines 47–57).
  Must add a `'menu'` case — without it, `menu_section.dart` never renders even if `'menu'`
  is in `HOME_SECTIONS`.
- `setup.sh` runs module migrations via `run_if_enabled "menu" "097_menu.sql"` — this line
  must be added to `setup.sh`. Migrations are NOT deployed from `deliver.sh` directly.

### Decision: new `menu_items` table (not reusing `services`)
`services` has artist_services joins, availability logic, and booking RLS dependencies.
`menu_items` is a clean standalone table. The small code duplication is worth the isolation.

---

## Schema Changes

**Migration: `097_menu.sql`** (next after 096_invoice_generation.sql)

```sql
CREATE TABLE menu_items (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category     text NOT NULL DEFAULT 'General',
  name         text NOT NULL,
  description  text,
  price        integer,           -- cents (null = "Price on request"). $15.00 stored as 1500.
  image_url    text,
  is_available boolean DEFAULT true,
  sort_order   integer DEFAULT 0,
  created_at   timestamptz DEFAULT now()
);

ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public read" ON menu_items FOR SELECT USING (true);
CREATE POLICY "admin write" ON menu_items FOR ALL USING (
  EXISTS (
    SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role IN ('master', 'staff')
  )
);
```

Price convention: stored as **integer cents** (avoids float rounding). `price = 1500` → display
`$15.00`. `price = null` → display `"Price on request"` (never `"$0.00"` or blank).

---

## Flutter Changes

### `app_env.dart`
No new flag — gated by `AppEnv.moduleEnabled('menu')`, consistent with all other modules
(blog, gallery, events, etc.). No `MENU_ENABLED` dart-define needed.

### New: `lib/modules/menu/`

**`menu_item_model.dart`** — fields: id, category, name, description, price (nullable int, cents),
imageUrl, isAvailable, sortOrder. Display helper:
```dart
String get displayPrice => price == null ? 'Price on request' : '\$${(price! / 100).toStringAsFixed(2)}';
```

**`menu_repository.dart`** (abstract):
```dart
abstract class MenuRepository {
  Future<List<MenuItemModel>> getMenuItems();
  Future<List<String>> getCategories();
}
```

**`supabase_menu_repository.dart`** (concrete) — queries `menu_items` ordered by
`category, sort_order`. `getCategories()` returns distinct category strings from the result.

**`menu_controller.dart`** — `items` obs, `selectedCategory` obs (`'All'` default),
`filteredItems` getter returning items matching selected category (or all when `'All'`).

**`menu_section.dart`** — home page preview: first 6 available items in a grid, "View Full Menu"
CTA button navigating to `/menu`.

**`menu_catalog_view.dart`** — full `/menu` page with category filter chips + item grid/list.

**`menu_binding.dart`** — registers the **concrete** implementation:
```dart
Get.lazyPut<MenuRepository>(() => SupabaseMenuRepository());
Get.lazyPut<MenuController>(() => MenuController());
```
Do NOT register `MenuRepository` with the abstract class — `Get.lazyPut<MenuRepository>(() => MenuRepository())` will fail (abstract).

**`menu_module.dart`** — `AppModule` with navItem (`/menu`), routes, binding.

**Admin:**
- `menu_manager_view.dart` — add/edit/delete menu items (clone of `service_manager_view.dart`).

### `admin_shell.dart` — add Menu nav entry

```dart
if (AppEnv.moduleEnabled('menu'))
  _NavEntry('Menu', Icons.menu_book_outlined, ERoutes.adminMenu),
```

Note: `_NavEntry` takes positional args (label, icon, route) — NOT named args like `_NavItem`.

### `home_view.dart` — add `'menu'` case to `_sectionForId()`

```dart
'menu' => AppEnv.moduleEnabled('menu') ? const MenuSection() : null,
```

Without this, `menu_section.dart` never renders even when `'menu'` is in `HOME_SECTIONS`.

### `ERoutes`
Add `menu = '/menu'` and `adminMenu = '/admin/menu'`.

### `main.dart`
```dart
if (AppEnv.moduleEnabled('menu')) MenuModule(),
```

---

## setup.sh

Add to the module migration block (after the last `run_if_enabled` line):
```bash
run_if_enabled "menu" "097_menu.sql"
```

Migrations run via `setup.sh` (called by `deliver.sh` Step 3), not directly from `deliver.sh`.

---

## client.json / deliver.sh

```json
"MODULES": "...,menu"
```

`deliver.sh`: no additional deploy block needed (no Edge Functions, no secrets). The migration
runs automatically via `setup.sh` when `menu` is in `MODULES`.

---

## Acceptance Criteria

- [ ] `menu` not in MODULES — no route, no nav, no admin section, no DB migration
- [ ] `menu` in MODULES — `/menu` accessible, admin Menu item in sidebar
- [ ] Items grouped by category with correct sort order
- [ ] `price = null` → displays "Price on request" (not "$0.00" or blank)
- [ ] `price = 1500` → displays "$15.00" (cents convention)
- [ ] `is_available = false` → item shown greyed out or hidden (design decision at implementation)
- [ ] Admin can add/edit/delete items
- [ ] `menu_section.dart` renders on home page when `'menu'` in `HOME_SECTIONS`
- [ ] `setup.sh` includes `run_if_enabled "menu" "097_menu.sql"`
- [ ] All files ≤ 300 lines
