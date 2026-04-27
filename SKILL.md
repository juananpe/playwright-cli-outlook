---
name: playwright-cli-outlook
description: Send emails via Outlook Web using Playwright CLI Extension. Requires PLAYWRIGHT_MCP_EXTENSION_TOKEN.
---

# Outlook Email Automation via Playwright CLI Extension

## Setup

The `.env` file is located at:
```
~/.claude/skills/playwright-cli-outlook/scripts/.env
```

It contains `PLAYWRIGHT_MCP_EXTENSION_TOKEN` required for browser extension connection.

## Browser Connection

**Always connect to Chrome using the Playwright Extension first:**

```bash
export PLAYWRIGHT_MCP_EXTENSION_TOKEN=$(grep PLAYWRIGHT_MCP_EXTENSION_TOKEN ~/.claude/skills/playwright-cli-outlook/scripts/.env | cut -d= -f2)
playwright-cli attach --extension=chrome
```

This attaches to an existing Chrome browser session. After connecting, use standard playwright-cli commands (goto, snapshot, type, click, etc.).

## Send an email

### Option 1: Using send.sh script (Recommended)

**Important:** Run from the scripts directory:

```bash
cd ~/.claude/skills/playwright-cli-outlook/scripts && bash send.sh 'to@example.com' 'Subject' 'Body text'
```

The script automatically:
- Loads the `.env` file
- Attaches to Chrome browser
- Navigates to Outlook
- Composes and sends the email
- Uses proper Playwright selectors for reliable automation

### Option 2: Manual steps via attached browser

After connecting with `attach --extension=chrome`:

#### Step 1: Navigate to Outlook
```bash
playwright-cli goto "https://outlook.cloud.microsoft/mail/"
playwright-cli snapshot
```

#### Step 2: Open new email
```bash
playwright-cli click "getByRole('button', { name: 'New mail' })"
```

#### Step 3: Fill recipient (cursor is already focused in To field)
```bash
playwright-cli type 'recipient@example.com'
playwright-cli press 'Enter'
```
**Important:** When the compose window opens, the cursor is already focused in the To field. Just type the email and press Enter to confirm. Do NOT try to click or fill the To field - use keyboard input instead.

#### Step 4: Fill subject
```bash
playwright-cli press 'Tab'
playwright-cli type 'Email Subject'
```

#### Step 5: Fill body
```bash
playwright-cli press 'Tab'
playwright-cli type 'Email body text here'
```
**Important:** Use Tab to navigate from subject to body. Do NOT use `Control+Home` before typing. This places text at the very beginning of the body field, which can cause overlap with the email signature. Simply type directly - Outlook will place the text in the correct position above your signature.

#### Step 6: Send
```bash
playwright-cli click "getByLabel('Send', { exact: true })"
```

## Proven Approach

The following keyboard navigation approach has been tested and works reliably with Outlook Web:

- **To field**: Cursor is auto-focused when compose opens → `playwright-cli type` + `playwright-cli press 'Enter'`
- **Subject field**: Navigate with `playwright-cli press 'Tab'` → `playwright-cli type`
- **Message body**: Navigate with `playwright-cli press 'Tab'` → `playwright-cli type`
- **Send button**: `getByLabel('Send', { exact: true })`
- **New mail button**: `getByRole('button', { name: 'New mail' })`

## Common Issues

- **send.sh fails**: If the script fails with "Unknown command: async", it means the browser isn't attached. Run `playwright-cli attach --extension=chrome` first.
- **To field not accepting input**: The To field may match many elements with `getByLabel('To')`. Always use `playwright-cli type` directly since cursor is auto-focused, then press Enter to confirm.
- **Send button not found**: Use `{ exact: true }` parameter with `getByLabel('Send')`.
- **Body text overlaps with signature**: Do NOT use `Control+Home` before typing. Simply type directly - the text will appear in the correct position above your signature.

Use **single quotes** for arguments containing `!`.
