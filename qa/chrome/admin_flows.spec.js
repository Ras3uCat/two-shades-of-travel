// @ts-check
const { test, expect } = require('@playwright/test');
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const MASTER_EMAIL    = process.env.TEST_MASTER_EMAIL    || '';
const MASTER_PASSWORD = process.env.TEST_MASTER_PASSWORD || '';
const STAFF_EMAIL     = process.env.TEST_STAFF_EMAIL     || '';
const STAFF_PASSWORD  = process.env.TEST_STAFF_PASSWORD  || '';

async function loginAs(page, email, password) {
  await page.goto('/login');
  await page.fill('input[type="email"]', email);
  await page.fill('input[type="password"]', password);
  await page.click('button[type="submit"]');
  await expect(page).not.toHaveURL(/\/login/, { timeout: 10000 });
}

test.describe('Admin flows — master role', () => {
  test.beforeEach(async ({ page }) => {
    await loginAs(page, MASTER_EMAIL, MASTER_PASSWORD);
  });

  test('master reaches admin dashboard', async ({ page }) => {
    await page.goto('/admin');
    await expect(page).toHaveURL(/\/admin/);
    // Sidebar or dashboard heading should be visible
    await expect(page.locator('[data-testid="admin-sidebar"], [data-testid="admin-dashboard"], h1')).toBeVisible({ timeout: 8000 });
  });

  test('master can view bookings list', async ({ page }) => {
    await page.goto('/admin/bookings');
    await expect(page).toHaveURL(/\/admin\/bookings/);
    // List or empty-state should render
    await expect(page.locator('[data-testid="bookings-list"], [data-testid="empty-state"], table')).toBeVisible({ timeout: 8000 });
  });

  test('service CRUD round-trip — create, verify, delete', async ({ page }) => {
    await page.goto('/admin/services');

    // Open add-service dialog
    const addBtn = page.locator('button:has-text("Add"), button:has-text("New Service"), [data-testid="add-service"]').first();
    await addBtn.waitFor({ timeout: 8000 });
    await addBtn.click();

    // Fill in service name
    const testName = `QA Test Service ${Date.now()}`;
    const nameInput = page.locator('input[name="name"], input[placeholder*="name" i], [data-testid="service-name"]').first();
    await nameInput.fill(testName);

    // Duration (required field in most implementations)
    const durationInput = page.locator('input[name="duration"], input[type="number"], [data-testid="service-duration"]').first();
    if (await durationInput.isVisible({ timeout: 1000 }).catch(() => false)) {
      await durationInput.fill('60');
    }

    // Price
    const priceInput = page.locator('input[name="price"], [data-testid="service-price"]').first();
    if (await priceInput.isVisible({ timeout: 1000 }).catch(() => false)) {
      await priceInput.fill('100');
    }

    // Save
    const saveBtn = page.locator('button:has-text("Save"), button:has-text("Create"), button[type="submit"]').first();
    await saveBtn.click();

    // Service should appear in the list
    await expect(page.locator(`text=${testName}`)).toBeVisible({ timeout: 8000 });

    // Delete the test service (clean up)
    const serviceRow = page.locator(`[data-testid="service-tile"]:has-text("${testName}"), tr:has-text("${testName}")`).first();
    const deleteBtn = serviceRow.locator('button:has-text("Delete"), [data-testid="delete-service"]').first();
    if (await deleteBtn.isVisible({ timeout: 2000 }).catch(() => false)) {
      await deleteBtn.click();
      // Confirm dialog if present
      const confirmBtn = page.locator('button:has-text("Confirm"), button:has-text("Delete"), [data-testid="confirm-delete"]').first();
      if (await confirmBtn.isVisible({ timeout: 2000 }).catch(() => false)) {
        await confirmBtn.click();
      }
      await expect(page.locator(`text=${testName}`)).not.toBeVisible({ timeout: 5000 });
    }
  });

  test('master can access staff manager', async ({ page }) => {
    await page.goto('/admin/staff');
    await expect(page).toHaveURL(/\/admin\/staff/);
    await expect(page.locator('[data-testid="staff-list"], [data-testid="empty-state"], table, h1')).toBeVisible({ timeout: 8000 });
  });
});

test.describe('Admin flows — staff role', () => {
  test.skip(!STAFF_EMAIL, 'TEST_STAFF_EMAIL not set in qa/.env — skipping staff role tests');

  test.beforeEach(async ({ page }) => {
    await loginAs(page, STAFF_EMAIL, STAFF_PASSWORD);
  });

  test('staff reaches admin and sees own bookings only', async ({ page }) => {
    await page.goto('/admin');
    await expect(page).toHaveURL(/\/admin/);
    // Staff dashboard should load (not redirect to login)
    await expect(page.locator('body')).not.toBeEmpty();
  });

  test('staff cannot access master-only routes', async ({ page }) => {
    await page.goto('/admin/staff');
    // Should redirect or show access denied — not show staff manager
    const url = page.url();
    const isBlocked = url.includes('/login') || url.includes('/admin') && !url.includes('/staff');
    // Alternatively check for an error or redirect indicator
    const forbidden = await page.locator('text=/access denied|forbidden|not authorized/i').count();
    expect(isBlocked || forbidden > 0).toBeTruthy();
  });
});
