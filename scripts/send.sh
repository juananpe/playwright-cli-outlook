#!/bin/bash
# Usage: bash send.sh [--dry-run] <to> <subject> <body>
# Sends an email via Outlook Web using Playwright CLI Extension.
#
# Each field is focused explicitly (never with Tab from the To field: in Outlook
# Web, Tab after To lands in Cc, and the subject and body end up as invalid Cc
# recipients). Before sending, the script checks that Cc is empty and that the
# subject and body landed in the right fields; if not, it aborts without sending.
# --dry-run fills and checks the message, then discards it instead of sending.

dry_run=0
if [ "$1" = "--dry-run" ]; then
    dry_run=1
    shift
fi

if [ $# -lt 3 ]; then
    echo "Usage: bash send.sh [--dry-run] <to> <subject> <body>"
    exit 1
fi

to="$1"
subject="$2"
body="$3"

# Load environment variables
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$script_dir/.env" ]; then
    export $(grep -v '^#' "$script_dir/.env" | xargs)
fi

# attach --extension=chrome creates a session named "chrome"
pw() { playwright-cli --s=chrome "$@"; }

# Print the value returned by a playwright-cli eval (the line after "### Result")
pw_eval() { pw eval "$1" 2>&1 | sed -n '/^### Result/{n;p;q;}'; }

# Fail if the command printed a playwright-cli error
pw_ok() {
    local out
    out=$(pw "$@" 2>&1)
    if grep -q '^Error' <<<"$out"; then
        grep '^Error' <<<"$out" >&2
        return 1
    fi
}

# JSON-quote a string, as playwright-cli prints eval results
json() { printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read(), ensure_ascii=False))'; }

die() { echo "❌ $1" >&2; exit 1; }

focused_label() { pw_eval "() => document.activeElement && document.activeElement.getAttribute('aria-label')"; }

# Attach to browser
echo "🔗 Attaching to Chrome browser..."
playwright-cli attach --extension=chrome > /dev/null 2>&1

# Navigate to Outlook
echo "📧 Navigating to Outlook..."
pw goto "https://outlook.cloud.microsoft/mail/" > /dev/null 2>&1

# Open new email (Outlook may still be loading)
echo "📝 Opening new email..."
opened=0
for _ in 1 2 3 4 5 6 7 8 9 10; do
    if pw_ok click "getByRole('button', { name: 'New mail' })" 2>/dev/null; then
        opened=1
        break
    fi
    sleep 1.5
done
[ $opened -eq 1 ] || die "Could not open a new message (New mail button not found)."
sleep 1.5

# Fill recipient
echo "👤 Adding recipient: $to"
pw_ok click 'div[aria-label="To"]' || die "To field not found."
[ "$(focused_label)" = '"To"' ] || die "Focus is not in the To field."
pw type "$to" > /dev/null 2>&1
sleep 1
pw press 'Enter' > /dev/null 2>&1
sleep 0.5

# Fill subject: click the field itself, never Tab from To (Tab goes to Cc)
echo "📋 Setting subject: $subject"
pw_ok click 'input[aria-label="Subject"]' || die "Subject field not found."
[ "$(focused_label)" = '"Subject"' ] || die "Focus is not in the Subject field."
pw type "$subject" > /dev/null 2>&1
sleep 0.5

# Fill body: Tab from Subject goes to the body; check before typing.
# Clicking the body could put the cursor inside the signature.
echo "📄 Writing email body..."
pw press 'Tab' > /dev/null 2>&1
sleep 0.3
[ "$(focused_label)" = '"Message body"' ] || die "Focus is not in the message body."
pw type "$body" > /dev/null 2>&1
sleep 1

# Check the fields before sending
echo "🔎 Checking the message..."
keep="The draft is left open in Outlook; nothing was sent."
cc_text=$(pw_eval "() => document.querySelector('div[aria-label=\"Cc\"]').textContent.replace(/[\\u200b\\s]/g, '')")
[ "$cc_text" = '""' ] || die "Cc is not empty ($cc_text). $keep"
subject_now=$(pw_eval "() => document.querySelector('input[aria-label=\"Subject\"]').value")
[ "$subject_now" = "$(json "$subject")" ] || die "Subject field holds $subject_now. $keep"
first_line=$(printf '%s\n' "$body" | sed -n '/[^[:space:]]/{p;q;}')
body_ok=$(pw_eval "() => document.querySelector('div[aria-label=\"Message body\"]').innerText.includes($(json "$first_line"))")
[ "$body_ok" = "true" ] || die "Body text not found in the message body. $keep"

if [ $dry_run -eq 1 ]; then
    echo "🧪 Dry run: fields OK, discarding the draft."
    pw_ok click 'button[title="Discard"], button[aria-label="Discard"]' || die "Discard button not found; delete the draft by hand."
    sleep 1
    pw_ok click "getByRole('button', { name: 'OK' })" || die "Could not confirm the discard."
    echo "✅ Dry run passed; nothing was sent."
    exit 0
fi

# Send email
echo "🚀 Sending email..."
pw_ok click "getByLabel('Send', { exact: true })" || die "Send button not found. $keep"
sleep 2

echo "✅ Email sent to $to"
