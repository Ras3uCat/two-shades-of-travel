# Appendix 18 — Courses Module Setup

Use this appendix when `courses` is included in the client's `MODULES` list.

---

## 18.1 client.json flags

Add both flags to `client.json`:

```json
"MODULES": "...,courses",
"COURSES_ENABLED": "true"
```

- `MODULES` enables the public catalog, detail, and player routes plus the admin nav entry.
- `COURSES_ENABLED` is a separate dart-define that gates the `AppEnv.coursesEnabled` check.
  Both must be present for the full feature to activate.

---

## 18.2 Supabase Storage buckets

Create two buckets manually in the Supabase dashboard → Storage:

| Bucket | Access | Purpose |
|--------|--------|---------|
| `course-videos` | **Private** | Video files — served only via signed URLs |
| `course-thumbnails` | **Public** | Thumbnail images — served directly |

Steps:
1. Supabase dashboard → Storage → New bucket
2. Name: `course-videos` → toggle **Private** → Create
3. New bucket → Name: `course-thumbnails` → toggle **Public** → Create

---

## 18.3 Upload content

All uploads are done via the Supabase dashboard (no file upload in the Flutter admin UI).

**Videos:**
1. Dashboard → Storage → `course-videos`
2. Upload each `.mp4` (or other format)
3. Note the storage path (e.g. `intro/01-welcome.mp4`)

**Thumbnails:**
1. Dashboard → Storage → `course-thumbnails`
2. Upload each thumbnail image
3. Note the storage path (e.g. `thumbnails/flutter-course.jpg`)

---

## 18.4 Add courses and lessons in Admin

1. Log in as master → Admin → Courses (`/admin/courses`)
2. Create a course — set slug, title, description, `thumbnail_storage_path`, price
3. Open the course editor → add sections and lessons
4. For each lesson, set `video_storage_path` to the path noted in §18.3
5. Toggle `is_preview = true` on the first lesson (free preview, no auth required)
6. Publish the course by toggling `is_published`

---

## 18.5 Stripe setup (one-time purchase)

Course purchases flow through `stripe-dispatcher` — no separate webhook registration needed.

1. In Stripe dashboard, create a Product for the course (for record-keeping)
2. Note the Price ID and add it to the course row as `stripe_price_id` (optional — used for future subscription gating)
3. Ensure `STRIPE_SK` and `STRIPE_WEBHOOK_SECRET` are set in Supabase secrets
4. The `stripe-dispatcher` webhook already handles `metadata.type=course` — no extra endpoint needed

---

## 18.6 Subscription access (optional)

To grant access to a course for active subscribers:

1. Find the subscription plan UUID(s) from the `subscription_plans` table
2. In the Supabase table editor, add the plan UUIDs to `courses.subscription_plan_ids` for the relevant course
3. `get-lesson-video` will check both enrollment and active subscription — either grants access

---

## 18.7 QA checklist

- [ ] `course-videos` bucket is **Private** — direct URL returns 403
- [ ] `course-thumbnails` bucket is **Public** — thumbnail loads without auth
- [ ] Preview lesson plays without logging in
- [ ] Non-preview lesson redirects to login for unauthenticated users
- [ ] After purchase, enrollment activates and confirmation email received
- [ ] Video player seeks back to saved position after URL refresh (4-hour TTL)
- [ ] Admin Courses nav item absent when `COURSES_ENABLED` not in dart-defines
- [ ] `courses` route absent from nav when not in `MODULES`
- [ ] `flutter analyze` zero errors
