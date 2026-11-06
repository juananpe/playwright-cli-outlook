# playwright-cli-outlook

Send emails from Outlook Web (`outlook.cloud.microsoft`) through your own,
already logged-in Chrome browser, driven by the
[Playwright CLI](https://github.com/microsoft/playwright-cli) and its Chrome
extension. No Microsoft Graph API, app registration, or stored Outlook
password is needed: the script uses the Outlook session you already have open.

The project is both a shell-driven automation script and a skill definition
([SKILL.md](./SKILL.md)) that describes how an AI assistant should use it.

## Contents

```text
.
├── SKILL.md            # Skill definition and detailed UI notes for Outlook
└── scripts/
    ├── send.sh         # Main entry point: attaches to Chrome and sends an email
    ├── compose.js      # Playwright function that composes and sends a message
    └── .env            # Local secrets (not committed), holds the extension token
```

## Requirements

- macOS, Linux, or any system with a `bash` shell (the Keychain option below is macOS only)
- Google Chrome with the **Playwright** browser extension installed and enabled
- `playwright-cli` on your `PATH`
- `python3` (used to JSON-quote values during checks)
- An Outlook Web account, signed in in that Chrome profile

## Setup

1. Install the Playwright CLI (see the upstream project for the current
   instructions), then confirm it runs:

   ```bash
   playwright-cli --version
   ```

2. Create `scripts/.env` containing your extension token:

   ```bash
   PLAYWRIGHT_MCP_EXTENSION_TOKEN=<your-token>
   ```

   Do not commit `.env` or paste the token into logs or files.

## Usage

### Send an email

Run from the `scripts/` directory:

```bash
cd scripts
bash send.sh 'to@example.com' 'Subject' 'Body text'
```

The script:

1. Loads `.env` and attaches to Chrome (creates the session named `chrome`).
2. Opens Outlook and a new message.
3. Focuses the To, Subject, and body fields explicitly, checking focus before typing in each.
4. Before sending, verifies that Cc is empty, the Subject matches, and the body
   contains the text. If any check fails it stops, leaves the draft open, and
   sends nothing.
5. Prints `Email sent to ...` only after clicking Send. Any failure exits non-zero.

### Dry run

Fill and verify the message, then discard the draft without sending:

```bash
bash send.sh --dry-run 'to@example.com' 'Subject' 'Body text'
```

Use this after Outlook changes its UI to confirm the selectors still work.

### Manual control

To drive the browser step by step, attach and use the `--s=chrome` session:

```bash
playwright-cli attach --extension=chrome
playwright-cli --s=chrome goto "https://outlook.cloud.microsoft/mail/"
playwright-cli --s=chrome snapshot
```

`playwright-cli list` shows open sessions.

## Limitations

- **No attachments.** The extension cannot set file inputs, and drag-and-drop
  uploads to OneDrive instead of attaching. Prepare the draft and attach the
  file by hand.
- **Fragile selectors.** The script relies on Outlook's `aria-label` values
  (`To`, `Cc`, `Subject`, `Message body`, `Send`). Outlook UI changes can break it.
- **Keyboard order matters.** Pressing Tab after the To field moves to Cc, not
  Subject. The script always clicks the Subject field instead.
- **Formatting side effects.** Lines starting with `- ` become bullet lists,
  `:)` becomes an emoji, and URLs become links.
- **`compose.js` is a template.** It contains `__TO__`, `__SUBJECT__`, and
  `__BODY__` placeholders and is meant to be run through Playwright code
  execution. `send.sh` does not use it.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `Unknown command: async` | The browser is not attached. Run `playwright-cli attach --extension=chrome`. |
| `The browser 'default' is not open` | Use the `chrome` session: `playwright-cli --s=chrome ...`. |
| `New mail button not found` | Outlook is still loading or not signed in. Check the Chrome window. |
| `Cc is not empty` or `N emails are not valid` | Tab was pressed after To. The draft is left open; discard it and retry. |
| `Focus is not in the ...` | An Outlook UI change moved focus. Run `--dry-run` and update the selector in `send.sh`. |

## Security notes

- The extension token grants browser control. Keep `scripts/.env` private.
- The script sends email on your behalf. Test with `--dry-run` first.
- Review the draft before sending when you can. The script checks structure,
  not content.

## Related

- [SKILL.md](./SKILL.md): the full skill guide, including the proven
  selectors, formatting gotchas, and common issues.
