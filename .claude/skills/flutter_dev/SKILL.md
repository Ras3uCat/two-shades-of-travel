# Flutter Development Skill
**Scope:** `/lib/`
**Purpose:** Build production-grade Flutter applications with clean architecture and distinctive, memorable UI design.

## Architectural Blueprint
- **State:** GetX (Controllers + Bindings).
- **Organization:** Feature-First (`features/<name>/`).
- **Layers:** - `screens/`: UI only.
    - `controllers/`: Reactive logic + State.
    - `models/`: Data structures.
    - `widgets/`: Local components.
- **Shared:** `common/widgets/` for cross-feature components.
- **Data Layer:** `data/repositories/` (all API/data flow goes here)
- **Imports System:** Centralized export files (exports.dart) per feature and optionally at root level.
- **Bindings Structure:** All global or app-wide dependencies must be registered in:
    - /lib/common/bindings/general_bindings.dart
    - Each feature may also define its own binding file:
    - features/<feature>/bindings/<feature>_bindings.dart
    - general_bindings.dart is initialized at app start (e.g., in main.dart via initialBinding).
    - Controllers must never instantiate dependencies directly. Always use GetX dependency injection via bindings.
- **Exports System**
    - To eliminate long import chains and keep files clean:
    - Each feature must include an exports.dart file:
    - features/<feature>/exports.dart
    - This file re-exports:
        - screens
        - controllers
        - widgets
        - models
        - bindings
    - Example:
        - export 'screens/home_screen.dart';
        - export 'controllers/home_controller.dart';
        - export 'widgets/home_card.dart';
        - export 'models/home_model.dart';
        - export 'bindings/home_bindings.dart';
    - A root-level export file is also recommended:
        - /lib/exports.dart
    - This can export commonly used features, shared widgets, constants, and utilities.
    - All files across the app should import only from export files, never deep relative paths.

## Implementation Rules
- **Pure Widgets:** Zero business logic. Use `GetView<TController>`.
- **E-Constants:** Use `EColors`, `ESizes`, `EImages`, `EText` strictly.
- **The 300 Rule:** If a file exceeds 300 lines, extract widgets/logic to new files immediately.
- **Repositories:** All data fetching must go through `data/repositories/`.
- **Controller Responsibility:** Business logic, validation, formatting, state.

## Naming & Style
- Class: `UpperCamelCase`
- Variables: `lowerCamelCase`
- Suffixes: `...Controller`, `...Widget` (if reusable), `...Repository`.

## Brand Directives (Client Sites)
When building UI for a client site, check for `planning/client/brand_alignment.md`.
If it exists: load `.claude/skills/brand-directives/SKILL.md` before writing any widgets.
The brand directives translate inspiration analysis findings into concrete Flutter decisions —
animations, layout order, guest flow, CTA placement. They take precedence over defaults.
If it does not exist: proceed with client.json values only.

## Usage
Trigger this skill for any task involving UI, State, or Flutter-specific refactoring.