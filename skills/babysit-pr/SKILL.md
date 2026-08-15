---
name: babysit-pr
description: Watch an open pull request and act on new CI results and review comments. Use when the user asks to monitor, babysit, or keep an eye on a PR.
metadata:
    harness: [claude, codex]
    platform: [darwin, linux]
---

# Babysit PR

Keep one pull request moving without adding noise to it.

## Scope

Only look at checks and comments newer than the last push. Everything older was
either handled already or is answering code that no longer exists.

```bash
gh pr view <number> --json headRefOid,statusCheckRollup,comments,reviews
gh pr checks <number>
```

## Review findings

Read the source a bot points at before acting on it. Review bots are confidently
wrong often enough that an unverified fix is just a new bug.

-  A finding that holds up gets fixed and pushed.
-  A false positive gets dismissed with a written reason, so the next reader
   does not have to re-derive it.

## Failing checks

Separate a real break from a known infra flake. Fix the break. Name the flake
and move on rather than pushing empty commits to reroll it.

## Silence

If nothing is new, say so and stop. Never post a comment that only reports that
you looked.
