# Review threads

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
