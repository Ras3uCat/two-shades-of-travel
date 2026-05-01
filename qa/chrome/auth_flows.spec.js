// @ts-check
const { test, expect } = require('@playwright/test');
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const EMAIL    = process.env.TEST_EMAIL    || '';
const PASSWORD = process.env.TEST_PASSWORD || '';

test.describe('Auth flows', () => {
  test('signup page loads and shows email field', async ({ page }) => {
    await page.goto('/register');
    await expect(page.locator('input[type="email"]')).toBeVisible();
    await expect(page.locator('input[type="password"]')).toBeVisible();
  });

  test('login with valid credentials reaches authenticated route', async ({ page }) => {
    await page.goto('/login');
    await page.fill('input[type="email"]', EMAIL);
    await page.fill('input[type="password"]', PASSWORD);
    await page.click('button[type="submit"]');

    // Should redirect away from /login on success
    await expect(page).not.toHaveURL(/\/login/);
  });

  test('login with wrong password shows error', async ({ page }) => {
    await page.goto('/login');
    await page.fill('input[type="email"]', EMAIL);
    await page.fill('input[type="password"]', 'wrong-password-xyz');
    await page.click('button[type="submit"]');

    // Stay on login page and show an error
    await expect(page).toHaveURL(/\/login/);
    await expect(page.locator('text=/invalid|incorrect|failed/i')).toBeVisible({ timeout: 5000 });
  });

  test('password reset page loads and accepts email', async ({ page }) => {
    await page.goto('/reset-password');
    await expect(page.locator('input[type="email"]')).toBeVisible();
    await page.fill('input[type="email"]', EMAIL);
    await page.click('button[type="submit"]');
    // Success state — any confirmation message
    await expect(page.locator('text=/sent|check|email/i')).toBeVisible({ timeout: 8000 });
  });

  test('session persists across page reload', async ({ page }) => {
    await page.goto('/login');
    await page.fill('input[type="email"]', EMAIL);
    await page.fill('input[type="password"]', PASSWORD);
    await page.click('button[type="submit"]');
    await expect(page).not.toHaveURL(/\/login/);

    const authedUrl = page.url();
    await page.reload();
    // Should still be on authenticated route (not redirected to login)
    await expect(page).not.toHaveURL(/\/login/);
    await expect(page).toHaveURL(authedUrl);
  });

  test('auth-gated route redirects unauthenticated user to login', async ({ page }) => {
    // Navigate to profile without a session
    await page.context().clearCookies();
    await page.goto('/profile');
    await expect(page).toHaveURL(/\/login/);
  });
});
