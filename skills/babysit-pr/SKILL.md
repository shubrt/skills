---
name: babysit-pr
description: Watch an open pull request and act on new CI results, review comments, and unresolved review threads until it is ready to merge. Use when the user asks to monitor, babysit, or keep an eye on a PR.
metadata:
    harness: [claude, codex]
    platform: [darwin, linux]
---

# Babysit PR

Needs a shell with `gh`. Without command execution, say so and stop. Never report a step you could not run as done.

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

## Unresolved threads

`gh pr view` does not report resolution state. A thread that looks handled in the
comment feed can still be open on the PR page, so ask GraphQL.

```bash
repo_json=$(gh repo view --json owner,name)
owner=$(jq -r '.owner.login // .owner.name' <<<"$repo_json")
repo=$(jq -r '.name' <<<"$repo_json")

threads='query($owner:String!,$repo:String!,$number:Int!,$cursor:String){repository(owner:$owner,name:$repo){pullRequest(number:$number){reviewThreads(first:100,after:$cursor){pageInfo{hasNextPage endCursor}nodes{id,isResolved,isOutdated,path,line,comments(last:1){nodes{author{login},body,createdAt,url}}}}}}}'
cursor_args=()

while :; do
    page=$(gh api graphql -f query="$threads" -f owner="$owner" -f repo="$repo" -F number=<number> "${cursor_args[@]}")

    jq -r '.data.repository.pullRequest.reviewThreads.nodes[]
        | select(.isResolved == false)
        | [.id, .path, (.line // ""), (.isOutdated | tostring),
           (.comments.nodes[-1].author.login // ""),
           (.comments.nodes[-1].body | gsub("\n"; " ") | .[0:240])]
        | @tsv' <<<"$page"

    jq -e '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage' >/dev/null <<<"$page" || break
    cursor_args=(-f cursor="$(jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor' <<<"$page")")
done
```

Drop the `-f cursor` on the first page. Paginate whenever `hasNextPage` is true,
or a long review looks finished at thread 100.

Resolve a thread only after reading the current code and seeing it answer the
comment. `isOutdated` is not that proof. It means the lines moved, which a
rebase does on its own.

```bash
gh api graphql \
    -f query='mutation($threadId:ID!){resolveReviewThread(input:{threadId:$threadId}){thread{id,isResolved}}}' \
    -f threadId=<thread-id>
```

If the repository ships a generated file, check that the source and the artifact
agree before you resolve anything that touches either.

## Failing checks

Separate a real break from a known infra flake. Fix the break. Name the flake
and move on rather than pushing empty commits to reroll it.

## Waiting

Poll while checks run, every 30 to 60 seconds unless the user sets a cadence.
Stay with them instead of handing back a half-answer. Every push restarts the
round: the new head gets its own checks, and its own comments answering it.

## Stopping

Stop when the checks pass or fail for a reason you named, no unresolved thread
is left, and nothing new has landed since the last push. Sweep the PR and
`git status` once more first. Then report the head SHA, each check and its
result, how many threads you closed, what you ran locally, and any dirty file
you left alone.

## Silence

If nothing is new, say so and stop. Never post a comment that only reports that
you looked.
