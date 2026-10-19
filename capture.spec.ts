import { test } from '@playwright/test';

test('capture page', async ({ page }) => {
  await page.goto('http://localhost:3000');
  await page.waitForTimeout(3000);
  await page.screenshot({ path: 'verified_with_postcss.png', fullPage: false });
});
