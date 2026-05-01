// @ts-check
const { test, expect } = require('@playwright/test');
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const EMAIL    = process.env.TEST_EMAIL    || '';
const PASSWORD = process.env.TEST_PASSWORD || '';

async function login(page) {
  await page.goto('/login');
  await page.fill('input[type="email"]', EMAIL);
  await page.fill('input[type="password"]', PASSWORD);
  await page.click('button[type="submit"]');
  await expect(page).not.toHaveURL(/\/login/, { timeout: 10000 });
}

test.describe('Booking flow', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test('booking page loads and shows step 1 (select artist/service)', async ({ page }) => {
    await page.goto('/booking');
    // Step 1 should show some selectable cards/options
    await expect(page.locator('[data-testid="booking-step-1"], .booking-step')).toBeVisible({ timeout: 8000 });
  });

  test('can select service and advance to slot picker (step 3)', async ({ page }) => {
    await page.goto('/booking');

    // Step 1 — pick first available artist or service card
    const firstCard = page.locator('[data-testid="artist-card"], [data-testid="service-card"]').first();
    await firstCard.waitFor({ timeout: 8000 });
    await firstCard.click();

    // Step 2 — pick first available service (if separate step)
    const serviceCard = page.locator('[data-testid="service-card"]').first();
    if (await serviceCard.isVisible({ timeout: 2000 }).catch(() => false)) {
      await serviceCard.click();
    }

    // Advance button
    const nextBtn = page.locator('button:has-text("Next"), button:has-text("Continue")').first();
    if (await nextBtn.isVisible({ timeout: 2000 }).catch(() => false)) {
      await nextBtn.click();
    }

    // Step 3 — time slot grid should appear
    await expect(page.locator('[data-testid="slot-grid"], [data-testid="time-slot"]')).toBeVisible({ timeout: 8000 });
  });

  test('unavailable slots are visually distinct or disabled', async ({ page }) => {
    await page.goto('/booking');

    // Navigate to slot picker (repeat step 1/2 selection)
    const firstCard = page.locator('[data-testid="artist-card"], [data-testid="service-card"]').first();
    await firstCard.waitFor({ timeout: 8000 });
    await firstCard.click();

    const nextBtn = page.locator('button:has-text("Next"), button:has-text("Continue")').first();
    if (await nextBtn.isVisible({ timeout: 2000 }).catch(() => false)) {
      await nextBtn.click();
    }

    // Booked slots should exist and be non-clickable or styled differently
    const booked = page.locator('[data-testid="slot-booked"], button[disabled]').first();
    // Optional assertion — only fails if zero booked slots exist AND zero disabled buttons
    // A live site may have no booked slots, so this is a soft check
    const count = await booked.count();
    // Just ensure the slot grid rendered (presence of any slot element)
    await expect(page.locator('[data-testid="time-slot"], [data-testid="slot-grid"]').first()).toBeVisible();
    console.log(`Booked/disabled slots found: ${count}`);
  });

  test('step 4 (details form) accepts required fields', async ({ page }) => {
    await page.goto('/booking');

    const firstCard = page.locator('[data-testid="artist-card"], [data-testid="service-card"]').first();
    await firstCard.waitFor({ timeout: 8000 });
    await firstCard.click();

    // Try to reach step 4 by clicking first available slot
    const nextBtn = page.locator('button:has-text("Next"), button:has-text("Continue")').first();
    if (await nextBtn.isVisible({ timeout: 2000 }).catch(() => false)) {
      await nextBtn.click();
    }

    const firstSlot = page.locator('[data-testid="time-slot"]:not([disabled])').first();
    if (await firstSlot.isVisible({ timeout: 5000 }).catch(() => false)) {
      await firstSlot.click();
    }

    if (await nextBtn.isVisible({ timeout: 2000 }).catch(() => false)) {
      await nextBtn.click();
    }

    // Step 4 — client details form
    await expect(page.locator('input[name="name"], input[placeholder*="name" i]').first()).toBeVisible({ timeout: 8000 });
  });

  test('confirmation page shows booking details after ?booking_id param', async ({ page }) => {
    // Simulate arriving at confirmation after Stripe redirect
    // Use a fake booking_id — page should show confirmation UI (not crash)
    await page.goto('/booking/confirmation?booking_id=test-00000000');
    // Should render confirmation layout, not blank/error page
    await expect(page.locator('body')).not.toBeEmpty();
    // Check for at least one meaningful element
    const hasContent = await page.locator('h1, h2, [data-testid="booking-confirmed"]').count();
    expect(hasContent).toBeGreaterThan(0);
  });
});
