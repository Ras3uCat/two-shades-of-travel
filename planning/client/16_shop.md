# Shop Module — Delivery Guide

> **Off by default.** Add `shop` to `MODULES` in `client.json` to enable.

---

## Overview

The shop module adds a full e-commerce storefront to the client app:

- Public product catalogue at `/shop` (browse by category, no login required)
- Product detail pages with image carousel, pricing, and add-to-cart
- Cart with discount code support
- Stripe Checkout for payment (one-time, `payment` mode)
- Order confirmation page
- Admin panel: product management, order management, discount codes
- Analytics integration: shop KPIs + shop revenue chart added to the Analytics dashboard when both `shop` and `booking` are enabled

---

## 1. Enable in client.json

Add `shop` to the `MODULES` field:

```json
"MODULES": "booking,newsletter,shop"
```

Leave `STRIPE_SHOP_WEBHOOK_SECRET` **empty** until after the live endpoint is registered:

```json
"STRIPE_SHOP_WEBHOOK_SECRET": ""
```

---

## 2. What deliver.sh does automatically

When `shop` is in `MODULES`, `deliver.sh` will:

1. Apply `085_shop.sql` — creates the shop tables and RLS policies
2. Apply `086_shop_analytics.sql` — extends `get_revenue_summary()` with shop data (runs only if `booking` is also enabled)
3. Deploy `create-shop-checkout` edge function
4. Deploy `shop-webhook` edge function
5. Print the manual steps below in the post-delivery checklist

---

## 3. Post-deploy manual steps

### 3.1 — Add products (before going live)

1. Open the admin panel → **Products** (`/admin/shop/products`)
2. Click **+** to create a product — fill in name, description, price, optional compare-at price, images (comma-separated URLs), tags, inventory count
3. Toggle **Active** — only active products appear in the public shop
4. Create categories as needed and assign products

> Images are stored as external URLs. Upload images to Supabase Storage, Cloudinary, or any CDN first, then paste the public URL into the product form.

### 3.2 — Register the Stripe webhook

1. Go to **Stripe dashboard → Developers → Webhooks → Add endpoint**
2. URL: `https://<YOUR_SUPABASE_REF>.supabase.co/functions/v1/shop-webhook`
3. Events to listen for: `checkout.session.completed`
4. Click **Add endpoint**, then copy the **Signing secret** (starts with `whsec_...`)

> This is a **separate** endpoint from the booking `stripe-webhook`. They use different signing secrets.

### 3.3 — Push the webhook secret to Supabase

Option A — add to `client.json` and re-run deliver.sh:

```json
"STRIPE_SHOP_WEBHOOK_SECRET": "whsec_..."
```

```bash
./deliver.sh --skip-db --skip-build
```

Option B — push directly:

```bash
cd execution/backend/supabase
supabase secrets set STRIPE_SHOP_WEBHOOK_SECRET=whsec_...
```

### 3.4 — Test the checkout flow

1. Add a product to cart → proceed to checkout → enter a test email
2. Complete payment with Stripe test card `4242 4242 4242 4242`
3. Verify order status updates to `paid` in Admin → Orders
4. Verify inventory decremented (if inventory tracking is enabled)
5. Verify confirmation email received (if `RESEND_KEY` is set)

---

## 4. Discount codes

Discount codes are managed at Admin → Products → (discount codes tab, or direct SQL).

Each code has:
- `code` — the string clients enter at checkout
- `discount_pct` — integer (e.g. `20` for 20% off)
- `expires_at` — optional expiry date
- `max_uses` — optional cap (leave null for unlimited)
- `used_count` — auto-incremented by `shop-webhook` on successful payment

---

## 5. Order lifecycle

| Status | Meaning |
|--------|---------|
| `pending` | Order created, awaiting payment |
| `paid` | Stripe payment confirmed (set by shop-webhook) |
| `processing` | Manually advanced by admin |
| `shipped` | Manually advanced by admin |
| `delivered` | Manually advanced by admin |
| `cancelled` | Cancelled by admin |

Admin can advance or cancel orders via Admin → Orders (`/admin/shop/orders`).

---

## 6. Analytics

When both `booking` and `shop` are in `MODULES`:

- `086_shop_analytics.sql` is applied — it replaces `get_revenue_summary()` with a version that includes shop data
- The Analytics dashboard (`/admin/analytics`) gains a **Shop** section:
  - Shop Revenue (30d), Orders (30d), Avg Order Value
  - Shop revenue bar chart (same week/month toggle as booking revenue)
  - Top Products chart (90-day sales)

---

## 7. Module dependencies

| Dependency | Required? | Notes |
|------------|-----------|-------|
| `booking` | No | Shop works standalone; analytics integration is additive |
| Stripe | Yes | `STRIPE_PK` + `STRIPE_SHOP_WEBHOOK_SECRET` both needed |
| Resend (`RESEND_KEY`) | No | Order confirmation email is skipped if not set |

---

## 8. QA checklist

- [ ] Products appear at `/shop` (public, no login)
- [ ] Category filter works
- [ ] Product detail page shows images, price, add-to-cart
- [ ] Cart quantity controls work; total recalculates
- [ ] Discount code applies / invalid code shows error
- [ ] Checkout dialog collects name + email; pre-fills for logged-in users
- [ ] Stripe test payment completes; order confirmation page shows
- [ ] Cart clears after successful checkout
- [ ] Admin → Orders shows new order with status `paid`
- [ ] Admin can advance order status (paid → processing → shipped → delivered)
- [ ] Admin can cancel order
- [ ] Analytics dashboard shows shop KPIs (if `booking` also enabled)
- [ ] `STRIPE_SHOP_WEBHOOK_SECRET` set in Supabase secrets
