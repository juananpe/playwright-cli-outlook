async (page) => {
  const to = "__TO__";
  const subject = "__SUBJECT__";
  const bodyText = "__BODY__";

  page.setDefaultTimeout(15000);

  // 1. Navigate to Outlook
  await page.goto("https://outlook.cloud.microsoft/mail/");
  await page.waitForTimeout(2000);

  // 2. Click "New Mail" button
  await page.getByRole("button", { name: "New mail" }).click();
  await page.waitForTimeout(1500);

  // 3. Fill in the To field
  await page.locator('[aria-label="To"]').click();
  await page.keyboard.type(to);
  await page.keyboard.press("Tab");
  await page.waitForTimeout(500);

  // 4. Fill in the Subject field
  await page.locator('input[aria-label="Subject"]').fill(subject);
  await page.waitForTimeout(300);

  // 5. Click and fill the message body (place cursor before signature)
  const body = page.locator('div[aria-label="Message body"]');
  await body.click({ position: { x: 10, y: 10 } });
  await page.keyboard.press("Control+Home");
  await page.keyboard.type(bodyText);
  await page.waitForTimeout(500);

  // 6. Click Send
  await page.locator('[aria-label="Send"]').click();
  await page.waitForTimeout(2000);
};
