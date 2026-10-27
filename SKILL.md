---
name: playwright-cli-outlook
description: Send emails via Outlook Web using Playwright CLI Extension. Requires PLAYWRIGHT_MCP_EXTENSION_TOKEN.
---

# Outlook Email Automation via Playwright CLI Extension

## Setup

The canonical installation and its `.env` file are located at:
```
/opt/playwright-cli-outlook/scripts/.env
```

It contains `PLAYWRIGHT_MCP_EXTENSION_TOKEN` required for browser extension connection.
The copy of this skill under `~/.claude/skills_/playwright-cli-outlook/` does not contain the `.env` file. Always use the `/opt/playwright-cli-outlook` paths for scripts and configuration.
The installed CLI is `/Users/juanan/.nvm/versions/node/v22.16.0/bin/playwright-cli`. A symlink at `/Users/juanan/.local/bin/playwright-cli` exposes it on the usual `PATH`. If `playwright-cli` is unavailable in a different shell, invoke the installed CLI by its absolute path or add `/Users/juanan/.local/bin` to `PATH`.

## Browser Connection

**Always connect to Chrome using the Playwright Extension first:**

```bash
export PLAYWRIGHT_MCP_EXTENSION_TOKEN=$(grep '^PLAYWRIGHT_MCP_EXTENSION_TOKEN=' /opt/playwright-cli-outlook/scripts/.env | cut -d= -f2-)
playwright-cli attach --extension=chrome
```

**Token en macOS:** si el `.env` no existe, el token está en el llavero de macOS (Keychain):

```bash
export PLAYWRIGHT_MCP_EXTENSION_TOKEN=$(security find-generic-password -a "$USER" -s "playwright" -w)
playwright-cli attach --extension=chrome
```

Este método solo aplica a macOS; en otros sistemas usa el `.env` u otro almacén de secretos. No imprimas ni guardes el token en ficheros.

This attaches to an existing Chrome browser session. After connecting, use standard playwright-cli commands (goto, snapshot, type, click, etc.).

**Importante:** `attach --extension=chrome` crea una sesión llamada `chrome`, no `default`. Pasa `--s=chrome` en los comandos posteriores (`playwright-cli --s=chrome goto ...`, la misma forma que usa `send.sh`); sin él fallan con "The browser 'default' is not open". Comprueba las sesiones con `playwright-cli list`.

## Links to individual emails

Always format links to individual emails or conversations using `mail/deeplink/readconv`:

```text
https://outlook.office.com/mail/deeplink/readconv/<URL-encoded-conversation-id>
```

Use the conversation ID observed in Outlook and URL-encode it exactly once. When Outlook displays a URL such as `https://outlook.cloud.microsoft/mail/id/<encoded-id>`, preserve that encoded ID and present it using the `mail/deeplink/readconv` format above. Do not return `mail/id` links to the user or save them as email references in generated documents. Present links as clickable Markdown, with the email subject as the label.

## Send an email

### Option 1: Using send.sh script (Recommended)

**Important:** Run from the scripts directory:

```bash
cd /opt/playwright-cli-outlook/scripts && bash send.sh 'to@example.com' 'Subject' 'Body text'
```

The script:
- Loads the `.env` file and attaches to Chrome (session `chrome`)
- Opens Outlook and a new message
- Focuses To, Subject and the body explicitly and checks focus before typing in each
- Before sending, checks that Cc is empty, that the Subject field holds the subject and that the body contains the text; otherwise it stops with an error, leaves the draft open and sends nothing
- Exits non-zero on any failure (it only prints "Email sent" after clicking Send)

`bash send.sh --dry-run ...` fills and checks the message, then discards the draft without sending. Use it after Outlook UI changes.

The script cannot attach files (see "Attachments" below).

### Option 2: Manual steps via attached browser

After connecting with `attach --extension=chrome`:

#### Step 1: Navigate to Outlook
```bash
playwright-cli --s=chrome goto "https://outlook.cloud.microsoft/mail/"
playwright-cli --s=chrome snapshot
```

#### Step 2: Open new email
```bash
playwright-cli --s=chrome click "getByRole('button', { name: 'New mail' })"
```
Outlook may still be loading right after `goto`; retry the click for a few seconds if it does not match.

#### Step 3: Fill recipient
```bash
playwright-cli --s=chrome click 'div[aria-label="To"]'
playwright-cli --s=chrome type 'recipient@example.com'
playwright-cli --s=chrome press 'Enter'
```

#### Step 4: Fill subject — click the field, NEVER press Tab from To
```bash
playwright-cli --s=chrome click 'input[aria-label="Subject"]'
playwright-cli --s=chrome type 'Email Subject'
```
**Important:** After the To field, Tab moves to **Cc**, not Subject. Typing the subject and body after Tab turns every word group into an invalid Cc recipient ("N emails are not valid"). Always click `input[aria-label="Subject"]`.

#### Step 5: Fill body — Tab from Subject, then check focus
```bash
playwright-cli --s=chrome press 'Tab'
playwright-cli --s=chrome eval "() => document.activeElement.getAttribute('aria-label')"   # must print "Message body"
playwright-cli --s=chrome type 'Email body text here'
```
From Subject, Tab goes to the body. Do NOT click the body (the click can place the cursor inside the signature) and do NOT use `Control+Home` (the text overlaps the signature). Type directly; Outlook puts the text above the signature.

#### Step 6: Check, then send
```bash
playwright-cli --s=chrome eval "() => document.querySelector('div[aria-label=\"Cc\"]').textContent"   # must be empty
playwright-cli --s=chrome screenshot
playwright-cli --s=chrome click "getByLabel('Send', { exact: true })"
```
Look at the screenshot before sending. If Cc holds anything you did not add, discard the draft (`button[title="Discard"]`, then OK) and start again.

## Proven Approach

- **New mail button**: `getByRole('button', { name: 'New mail' })`
- **To field**: click `div[aria-label="To"]` → `type` + `press 'Enter'`
- **Cc field**: `div[aria-label="Cc"]`; recipient chips appear as its text, so empty text means no Cc
- **Subject field**: click `input[aria-label="Subject"]` → `type` (never Tab from To)
- **Message body**: `press 'Tab'` from Subject → check `document.activeElement` is "Message body" → `type`
- **Send button**: `getByLabel('Send', { exact: true })`
- **Discard button**: `button[title="Discard"]`, confirmed with `getByRole('button', { name: 'OK' })`
- With zsh, keep `playwright-cli --s=chrome` as a shell function (`P() { playwright-cli --s=chrome "$@"; }`), not a string variable: `$P type ...` fails with "command not found".

## Formatting gotchas

- Body lines starting with `- ` are turned into a bulleted list as you type; the list breaks on the next line that does not start with `- ` (later items get mis-indented or lose the bullet). Prefer bullet-free lines, or check the screenshot.
- `:)` is turned into an emoji.
- URLs become links automatically.

## Attachments

The Playwright extension cannot attach files: the file chooser's `upload` fails with `DOM.setFileInputFiles: Not allowed` and leaves a modal stuck in the CLI session (only `playwright-cli --s=chrome detach` and re-attaching clears it). Dropping a file on the body (`drop '[aria-label="Message body"]' --path ...`) does not attach it either: Outlook uploads it to OneDrive and inserts a sharing link, and the "Attach instead" toast disappears in seconds. Every attempt leaves another copy in OneDrive and the edit can drop text from the body. When an attachment is needed, prepare the draft and ask the user to drag the file in and send it themselves.

## Common Issues

- **send.sh fails**: If the script fails with "Unknown command: async", it means the browser isn't attached. Run `playwright-cli attach --extension=chrome` first.
- **Subject/body ended up in Cc** ("N emails are not valid"): Tab was used after To. Discard the draft and fill Subject by clicking `input[aria-label="Subject"]`.
- **Send button not found**: Use `{ exact: true }` parameter with `getByLabel('Send')`.
- **Body text overlaps with signature**: Do NOT use `Control+Home` before typing. Simply type directly - the text will appear in the correct position above your signature.

Use **single quotes** for arguments containing `!`.
