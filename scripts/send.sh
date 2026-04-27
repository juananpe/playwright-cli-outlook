#!/bin/bash
# Usage: bash send.sh <to> <subject> <body>
# Sends an email via Outlook Web using Playwright CLI Extension

if [ $# -lt 3 ]; then
    echo "Usage: bash send.sh <to> <subject> <body>"
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

# Attach to browser
echo "🔗 Attaching to Chrome browser..."
playwright-cli attach --extension=chrome > /dev/null 2>&1

# Navigate to Outlook
echo "📧 Navigating to Outlook..."
playwright-cli goto "https://outlook.cloud.microsoft/mail/" > /dev/null 2>&1
sleep 2

# Open new email
echo "📝 Opening new email..."
playwright-cli click "getByRole('button', { name: 'New mail' })" > /dev/null 2>&1
sleep 1

# Fill recipient (cursor is already focused in To field when compose opens)
echo "👤 Adding recipient: $to"
playwright-cli type "$to" > /dev/null 2>&1
sleep 0.5
playwright-cli press 'Enter' > /dev/null 2>&1
sleep 0.5

# Navigate to subject and fill it (Tab twice to skip Cc field)
echo "📋 Setting subject: $subject"
playwright-cli press 'Tab' > /dev/null 2>&1
sleep 0.3
playwright-cli press 'Tab' > /dev/null 2>&1
sleep 0.3
playwright-cli type "$subject" > /dev/null 2>&1
sleep 0.5

# Navigate to body and fill it
echo "📄 Writing email body..."
playwright-cli press 'Tab' > /dev/null 2>&1
sleep 0.3
# Type directly without Control+Home to avoid overlapping with signature
playwright-cli type "$body" > /dev/null 2>&1
sleep 0.5

# Send email
echo "🚀 Sending email..."
playwright-cli click "getByLabel('Send', { exact: true })" > /dev/null 2>&1
sleep 2

echo "✅ Email sent successfully to $to"
