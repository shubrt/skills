---
name: pushdraft-read
description: Use when the user provides a pushdraft.dev URL to read.
metadata:
    harness: [claude, codex]
    platform: [darwin, linux]
    requires: "curl, jq"
---

# Pushdraft Read

Fetch the uploaded HTML with the shell. Do not use web search or a browser.

1. Remove a trailing slash, then append `/raw` unless the URL already ends in `/raw`.
2. Run `(PUSHDRAFT_API_KEY=$(jq -er '.apiKey' "$HOME/.pushdraft/credentials.json") && curl --fail --silent --show-error --location --max-time 30 --header "Authorization: Bearer ${PUSHDRAFT_API_KEY}" --output /tmp/pushdraft.html '<raw-url>')`.
3. Read `/tmp/pushdraft.html` and continue the user's request from its contents.

If credentials are missing, ask the user to run `pushdraft auth login`, then retry.
If `curl` fails, report its actual status or network error. Do not substitute search results.
