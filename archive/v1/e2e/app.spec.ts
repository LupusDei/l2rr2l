import { test, expect } from '@playwright/test';

test.describe('L2RR2L App', () => {
  test('displays the main heading and tagline', async ({ page }) => {
    await page.goto('/');

    await expect(page.getByRole('heading', { name: 'L2RR2L' })).toBeVisible();
    await expect(page.getByText('Learn to Read, Read to Learn')).toBeVisible();
  });

  test('has correct viewport for mobile', async ({ page }) => {
    await page.goto('/');

    const viewport = page.viewportSize();
    expect(viewport).not.toBeNull();
    expect(viewport!.width).toBeLessThanOrEqual(500);
  });
});
