---
description: Flutter widget and file conventions. Apply when editing any Dart file in lib/features/ or lib/core/theme/.
globs: ["execution/frontend/app/lib/features/**/*.dart", "execution/frontend/app/lib/core/theme/**/*.dart"]
---

# Flutter Style Rules

## Widget Architecture
- Views extend `GetView<TController>` — never `StatefulWidget` for business state
- `StatefulWidget` only for pure animation state (`AnimationController`, etc.)
- Zero business logic in widgets. Any `if` on API data belongs in the controller.

## File Size Limit
**300 lines maximum.** Extract at 250 lines. Naming convention for extracted parts:
```
booking_step4_view.dart      ← main entry point, stays lean
_step4_notes_field.dart      ← extracted widget, prefixed with _
_step4_summary_card.dart     ← another extracted widget
```
The `_` prefix signals "private to this view — not reusable globally."

## Design Token Usage (Mandatory)
```dart
// ✅ Correct
color: EColors.primary,
padding: EdgeInsets.all(ESpacing.md),
style: ETextStyles.headline,

// ❌ Wrong
color: Color(0xFF58E3EF),
padding: EdgeInsets.all(16),
style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
```

## Reactive State
```dart
// ✅ Correct — reactive rebuild scoped to just this widget
Obx(() => Text(controller.userName.value))

// ❌ Wrong — rebuilds entire view on any state change
GetBuilder<MyController>(builder: (c) => Text(c.userName))
```

## Navigation
```dart
// ✅ Named routes only
Get.toNamed(ERoutes.profile, arguments: {'id': id});

// ❌ Never push widget instances directly
Get.to(ProfileView());
```

## Const Constructors
Mark every widget `const` where possible. The analyzer will warn when missing.

## Client Delivery Rules
- Never hardcode client names, colors, or content — use `AppEnv` dart-defines
- All brand values come from `EColors` / `ESpacing` / `ETextStyles` (derived from dart-defines)
- `client.json` is source of truth; it feeds dart-defines at build time

## Known Lint Gotchas (Dart 3.8+)
- `Color.alpha`/`.opacity` deprecated — use `.a` (0.0–1.0 range)
- `unnecessary_underscores`: use `(_, _)` not `(_, __)` for double ignores
- File-level `///` before imports → `dangling_library_doc_comments` — use `//` instead
- `deprecated_member_use` on `RegExp()` in Dart 3.8 — prefer string operations
