# Video / Course Platform — STUDIO PLAN
**Status:** DRAFT — awaiting approval
**Mode:** STUDIO
**Complexity:** HIGH — Supabase Storage streaming + significant Flutter UI
**Last reviewed:** 2026-03-14

---

## Overview

Gated video courses delivered via signed Supabase Storage URLs.
Three access models: free preview, one-time purchase, subscription gate.
Fully optional module (`courses` in MODULES). Zero impact if disabled.

---

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Video storage | Supabase Storage (`course-videos` private bucket) | Per-client isolation, no separate CDN config |
| Thumbnail storage | Separate `course-thumbnails` **public** bucket | Thumbnails need public URLs for home/catalog SEO; videos must stay private |
| Video delivery | Signed URLs via `get-lesson-video` Edge Fn | Never expose raw paths; access verified server-side every request |
| Signed URL TTL | **4 hours** (not 1 hour) | Reduces mid-lesson refresh frequency; most lessons < 2h |
| URL refresh strategy | Dispose + reinit `VideoPlayerController` then seek to saved position | `VideoPlayerController` has no seamless `setNetworkUrl()` — brief pause is acceptable |
| Playback | `video_player` + `chewie` Flutter packages | Works on web (HTML `<video>`), iOS, Android |
| Access gate | Edge Function checks enrollment OR active subscription | Server-side only — client-side check is UX only (ADR-009) |
| Guest enrollment | **Require auth for all purchased/subscription content** | Eliminates token-for-guest complexity; consistent with ADR-009. Free previews remain unauthenticated |
| Stripe | One-time purchase: `create-course-checkout` → `stripe-dispatcher` | Follows shop pattern (ADR-005) |
| Pending enrollment | Created at checkout time (status=`pending`) → webhook marks `active` | Matches shop order pattern; prevents lost enrollment if webhook fails |
| Progress tracking | Debounced writes every 10s → `save-lesson-progress` Edge Fn | Avoid hammering DB; saves position for resume |
| Admin upload | Storage path entry only (Supabase dashboard upload) | No `file_picker` / `dart:html` — avoids web library lint (gallery pattern) |
| stripe-dispatcher handler | `_handlers/course.ts` subfolder | Matches existing `_handlers/shop.ts`, `_handlers/subscription.ts` pattern; keeps dispatcher file ≤ 300 lines |

---

## Database — `090_video_courses.sql`

```sql
-- Courses
CREATE TABLE courses (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug                 TEXT UNIQUE NOT NULL,
  title                TEXT NOT NULL,
  description          TEXT,
  thumbnail_storage_path TEXT,           -- path in course-thumbnails PUBLIC bucket
  price_cents          INT NOT NULL DEFAULT 0,
  stripe_price_id      TEXT,            -- null = free or subscription-only
  subscription_plan_ids UUID[],         -- active subscription in any of these grants access
  instructor_id        UUID REFERENCES auth.users(id),
  is_published         BOOLEAN NOT NULL DEFAULT FALSE,
  display_order        INT NOT NULL DEFAULT 0,
  created_at           TIMESTAMPTZ DEFAULT now()
);

-- Sections (chapters)
CREATE TABLE course_sections (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id     UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  title         TEXT NOT NULL,
  display_order INT NOT NULL DEFAULT 0
);

-- Lessons (individual videos)
-- course_id is denormalized here to avoid 2-level JOIN in get-lesson-video
CREATE TABLE course_lessons (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id           UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  section_id          UUID NOT NULL REFERENCES course_sections(id) ON DELETE CASCADE,
  title               TEXT NOT NULL,
  description         TEXT,
  video_storage_path  TEXT,            -- path in course-videos PRIVATE bucket
  duration_seconds    INT,
  is_preview          BOOLEAN NOT NULL DEFAULT FALSE,
  display_order       INT NOT NULL DEFAULT 0
);

-- Enrollments — created PENDING at checkout, marked ACTIVE by webhook
CREATE TABLE course_enrollments (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id                UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  client_email             TEXT NOT NULL,
  status                   TEXT NOT NULL DEFAULT 'pending',  -- pending | active | cancelled
  enrolled_at              TIMESTAMPTZ,                      -- set when status → active
  stripe_checkout_session  TEXT,
  expires_at               TIMESTAMPTZ,                      -- null = lifetime access
  UNIQUE(course_id, client_email)
);

-- Per-lesson progress (auth users only — guest previews don't track)
CREATE TABLE lesson_progress (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id       UUID NOT NULL REFERENCES course_lessons(id) ON DELETE CASCADE,
  client_email    TEXT NOT NULL,
  watched_seconds INT NOT NULL DEFAULT 0,
  completed_at    TIMESTAMPTZ,
  updated_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE(lesson_id, client_email)
);

-- RLS
ALTER TABLE courses              ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_sections      ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_lessons       ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_enrollments   ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress      ENABLE ROW LEVEL SECURITY;

-- Public can read published courses/sections/lessons
CREATE POLICY "public_read_courses"   ON courses         FOR SELECT USING (is_published = TRUE);
CREATE POLICY "public_read_sections"  ON course_sections FOR SELECT USING (TRUE);
CREATE POLICY "public_read_lessons"   ON course_lessons  FOR SELECT USING (TRUE);

-- Enrollments: master full access; clients read own active enrollments
CREATE POLICY "master_enrollments"        ON course_enrollments FOR ALL    USING (auth.jwt() ->> 'role' = 'master');
CREATE POLICY "client_read_enrollment"    ON course_enrollments FOR SELECT USING (client_email = auth.jwt() ->> 'email');

-- Progress: authenticated client read/write own rows
CREATE POLICY "client_progress"           ON lesson_progress    FOR ALL    USING (client_email = auth.jwt() ->> 'email');

-- Master full write on content tables
CREATE POLICY "master_courses"    ON courses         FOR ALL USING (auth.jwt() ->> 'role' = 'master');
CREATE POLICY "master_sections"   ON course_sections FOR ALL USING (auth.jwt() ->> 'role' = 'master');
CREATE POLICY "master_lessons"    ON course_lessons  FOR ALL USING (auth.jwt() ->> 'role' = 'master');
```

**Storage buckets** (manual steps, listed in deliver.sh checklist):
- `course-videos` — **Private**. No public read. Signed URLs only.
- `course-thumbnails` — **Public**. Read-only public. Thumbnails served directly.

---

## Edge Functions

### `get-lesson-video` (NEW)
**Auth:** Requires valid JWT. Unauthenticated callers can only access `is_preview=true` lessons.

```
Input:  { lesson_id: string }
Access check order:
  1. lesson.is_preview = true → allow (no auth required)
  2. JWT present → check course_enrollments (status='active', no expiry or expires_at > now())
  3. JWT present → check subscriptions (status='active'/'trialing', plan_id in course.subscription_plan_ids)
  → 403 if none match / no JWT and not preview

Output: { signed_url: string, expires_at: string }  (4-hour TTL)
Note:   lesson.course_id available directly (denormalized column) — no multi-level JOIN
```

### `create-course-checkout` (NEW)
Follows `create-shop-checkout` pattern exactly — pending row before Stripe session.

```
Input:  { course_id, success_url, cancel_url }
Steps:
  1. Load course; verify is_published=true and price_cents > 0
  2. Upsert course_enrollments row: status='pending', stripe_checkout_session=null
     (ignoreDuplicates: true — idempotent if user retries)
  3. Create Stripe Checkout session: mode='payment', metadata: { type: 'course', course_id, client_email }
  4. Update enrollment row: stripe_checkout_session = session.id
Output: { url: string }
```

### `stripe-dispatcher/_handlers/course.ts` (NEW file in existing subfolder)
Triggered when `metadata.type === 'course'`.

```typescript
// On checkout.session.completed:
// 1. Update course_enrollments: status='active', enrolled_at=now()
//    WHERE stripe_checkout_session = session.id
// 2. Send enrollment confirmation email via Resend (RESEND_KEY — skip gracefully if absent)
//    Subject: "You're enrolled in {course_title}"
//    Body: course title, link to /courses/:slug
```

Update `stripe-dispatcher/index.ts` routing: add `else if (type === 'course')` branch.

### `save-lesson-progress` (NEW)
**Auth:** Requires JWT. Silently no-ops if unauthenticated (preview watchers don't track).

```
Input:  { lesson_id, watched_seconds, completed: bool }
→ Upsert lesson_progress WHERE (lesson_id, client_email)
→ Set completed_at = now() if completed=true and not already set
```

---

## AppEnv additions (`client.json`)

```
COURSES_ENABLED=true
```

Dart:
```dart
static bool get coursesEnabled => bool.fromEnvironment('COURSES_ENABLED', defaultValue: false);
```

`COURSES_REQUIRE_AUTH` dropped — over-engineered for v1. Auth is always required for gated content; previews are always open.

Admin sidebar nav item also gated:
```dart
// admin_shell.dart _masterNav — same pattern as reviewsEnabled, waitlistEnabled:
if (AppEnv.coursesEnabled)
  const _NavEntry('Courses', Icons.play_circle_outline, ERoutes.adminCourses),
```

---

## pubspec.yaml additions

```yaml
video_player: ^2.9.5
chewie: ^1.9.0
```

Both packages must be added in Phase C before implementing `LessonPlayerView`.
Test on Flutter Web first — `video_player_web` delegates to `<video>` tag, which handles signed HTTPS URLs correctly.

---

## Flutter Module Structure

```
lib/modules/courses/
  models/
    course_model.dart              // Course, CourseSection, CourseLesson
    enrollment_model.dart          // CourseEnrollment, LessonProgress
  repositories/
    course_repository.dart         // abstract
    supabase_course_repository.dart
  controllers/
    course_catalog_controller.dart // published courses list
    course_detail_controller.dart  // single course, enrollment status, progress aggregation
    lesson_player_controller.dart  // signed URL lifecycle, progress timer
  views/
    courses_section.dart           // home section (module-gated, max 3 featured)
    course_catalog_view.dart       // /courses — responsive grid
    course_detail_view.dart        // /courses/:slug — syllabus + CTA
    lesson_player_view.dart        // /courses/:slug/lesson/:id — player + lesson sidebar
  admin/
    course_manager_view.dart       // list + create/archive courses
    course_section_editor.dart     // sections + lessons editor for one course
    course_enrollments_view.dart   // enrollment list + manual grant
  bindings/
    courses_binding.dart           // catalog + detail controllers
    lesson_binding.dart            // player controller
  courses_module.dart              // AppModule impl
```

**`courses_module.dart` must implement `AppModule`:**
```dart
class CoursesModule implements AppModule {
  @override String get moduleId => 'courses';
  @override NavItem? get navItem => NavItem(label: 'Courses', icon: Icons.play_circle_outline, route: ERoutes.courses);
  @override List<GetPage> get routes => [ /* catalog, detail, player */ ];
  @override Bindings? get binding => CoursesBinding();
}
```

**Routes to add to `ERoutes`:**
```dart
static const courses                  = '/courses';
static const courseDetail             = '/courses/:slug';
static const lessonPlayer             = '/courses/:slug/lesson/:id';
static const adminCourses             = '/admin/courses';
static const adminCourseEnrollments   = '/admin/courses/:id/enrollments';
```

---

## Key Flutter Implementation Notes

### SEO — `CourseDetailView` (ADR-008)
Wrap with `SeoWrapper` and include JSON-LD `Course` schema:
```json
{ "@type": "Course", "name": "...", "description": "...", "provider": { "@type": "Organization" } }
```
`CourseCatalogView` gets standard meta tags (title, description, OG image from first course thumbnail).

### `CourseDetailController` — enrollment + progress loading
On `onInit`:
1. Load course by slug (with sections + lessons)
2. If authenticated: load `course_enrollments` row for (course_id, currentUser.email)
3. If authenticated: load all `lesson_progress` rows for this course's lesson IDs
4. Derive: `isEnrolled`, `hasActiveAccess` (enrollment active OR subscription match), `completedLessonIds`, `overallProgressPct`

### Video Playback — URL refresh (corrected from original plan)
`VideoPlayerController` does NOT support seamless URL replacement.
Refresh strategy in `LessonPlayerController`:
1. Timer fires at `expires_at - 10min`
2. Save current `position = _videoController.value.position`
3. Dispose old `VideoPlayerController`
4. Call `get-lesson-video` → new signed URL
5. Init new `VideoPlayerController`, seek to `position`, resume play
Brief pause (~1s) is acceptable given 4-hour TTL means this happens at most once per session for very long lessons.

### Video Playback — progress save
- Start 10s timer on play
- On timer tick: call `save-lesson-progress(lesson_id, watched_seconds: position.inSeconds)`
- On lesson end (`_videoController.value.isCompleted`): call with `completed: true`
- Cancel timer on controller `onClose()`

### Admin — Course Manager split
- `course_manager_view.dart`: course list (cards), create/archive, navigate to editor
- `course_section_editor.dart`: full editor for one course — sections (reorder) + lessons per section (title, storage path, duration, is_preview toggle)
- Video upload: admin enters the Storage path manually (uploaded via Supabase dashboard → `course-videos` bucket)

### Admin sidebar gating
```dart
// admin_shell.dart _masterNav
if (AppEnv.coursesEnabled)
  const _NavEntry('Courses', Icons.play_circle_outline, ERoutes.adminCourses),
```
Place after "Settings", before "Compliance".

---

## deliver.sh Changes

```bash
# Gated on courses module:
if has_module "courses"; then
  deploy_fn "get-lesson-video"
  deploy_fn "create-course-checkout"
  deploy_fn "save-lesson-progress"
fi
```

Checklist additions:
```
□  Create Supabase Storage bucket: 'course-videos'      (Private — no public access)
□  Create Supabase Storage bucket: 'course-thumbnails'  (Public — read-only)
□  Upload video files via Supabase dashboard → Storage → course-videos
□  Upload thumbnail images → Storage → course-thumbnails
□  Set video_storage_path + thumbnail_storage_path on each course/lesson in Admin → Courses
□  Register STRIPE_WEBHOOK_SECRET in Supabase secrets (stripe-dispatcher handles course payments)
```

`CLIENT_DELIVERY_GUIDE.md` — add Courses section to "Module Setup" chapter covering:
- client.json `MODULES` + `COURSES_ENABLED` flags
- Storage bucket creation steps (above)
- Stripe product/price setup for one-time course purchase
- Subscription plan linking (optional)

---

## File Count Estimate

| Layer | Files | Notes |
|-------|-------|-------|
| SQL migration | 1 | `090_video_courses.sql` |
| Edge Functions | 3 new + 1 new handler + 1 update | `get-lesson-video`, `create-course-checkout`, `save-lesson-progress`, `_handlers/course.ts`, `stripe-dispatcher` routing update |
| Dart models | 2 | `course_model.dart`, `enrollment_model.dart` |
| Repository | 2 | abstract + Supabase impl |
| Controllers | 3 | catalog, detail, player |
| Views (public) | 4 | section, catalog, detail, player |
| Views (admin) | 3 | manager, section editor, enrollments |
| Bindings + module | 3 | |
| AppEnv + ERoutes | updates only | |
| pubspec.yaml | update only | +2 packages |
| **Total new files** | **~21** | All ≤ 300 lines |

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| URL refresh causes playback restart | 4h TTL + dispose/seek pattern. Document expected 1s pause in admin UX notes |
| `chewie` web compatibility | `video_player_web` handles `<video>` tag natively; test Phase C on web before mobile |
| Webhook fails before enrollment activated | `pending` row exists at checkout time → retry-safe; master can manually activate |
| Guest tries to access paid content | Hard requirement: auth before gated content. `get-lesson-video` returns 401 without JWT; Flutter shows login CTA |
| Admin upload friction | Same accepted trade-off as gallery. Checklist note in delivery guide |
| Thumbnail not loading | Separate public bucket (`course-thumbnails`) solves this — no signed URL needed |
| `flutter analyze` web library lint | No `dart:html` / `file_picker` — storage path input only |
| Large video file storage costs | Client concern, not implementation concern — noted in delivery guide |

---

## Phase Breakdown

**Phase A — Backend**
- `090_video_courses.sql` (with denormalized `course_id` on lessons, `status` on enrollments)
- `get-lesson-video` Edge Fn
- `create-course-checkout` Edge Fn (pending enrollment pattern)
- `save-lesson-progress` Edge Fn
- `stripe-dispatcher/_handlers/course.ts` + routing update
- `deliver.sh` + `CLIENT_DELIVERY_GUIDE.md` updates

**Phase B — Flutter core (no player)**
- Models + repository
- `CourseCatalogController`, `CourseDetailController` (enrollment + progress aggregation)
- `CourseCatalogView`, `CourseDetailView` with SEO / JSON-LD
- `CoursesSection` home widget
- `CoursesModule` AppModule impl + routes + bindings + `AppEnv` + `ERoutes`
- Admin: `CourseManagerView` + `CourseSectionEditor`

**Phase C — Video player**
- Add `video_player: ^2.9.5` + `chewie: ^1.9.0` to `pubspec.yaml`
- `LessonPlayerController` (signed URL, 10s progress timer, URL refresh with seek)
- `LessonPlayerView` (player + lesson sidebar nav)

**Phase D — Progress + admin finish**
- `lesson_progress` completed state in `CourseDetailView` (checkmarks, overall %)
- `CourseEnrollmentsView` admin (list + manual activate/cancel)
- Admin sidebar gating on `AppEnv.coursesEnabled`

---

## Acceptance Criteria

- `flutter analyze` zero errors
- `get-lesson-video` returns 401 for unauthenticated non-preview request
- `get-lesson-video` returns 403 for authenticated user with no enrollment/subscription
- Pending enrollment row created at checkout; marked active by webhook
- Video plays on Flutter Web (HTML renderer) and Flutter mobile
- URL refresh seeks back to correct position (no content lost)
- Thumbnails load without signed URL (public bucket)
- Admin nav item absent when `COURSES_ENABLED` not set
- `courses` module absent from nav/routes when not in `MODULES`
- All files ≤ 300 lines
- `deliver.sh` deploys course Edge Fns only when `courses` in MODULES
- `CLIENT_DELIVERY_GUIDE.md` updated with Courses setup section
