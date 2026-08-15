---
name: find-docs
description: Retrieves current documentation, API references, and code examples for a named library, framework, SDK, CLI tool, or cloud service. Use for API syntax, configuration options, version migrations, setup steps, and library-specific debugging, including well-known tools like React, Next.js, Prisma, and Tailwind, and including cases where the answer seems obvious, because training data lags behind releases. Prefer it over web search for library documentation. Not for refactoring, writing scripts from scratch, debugging business logic, code review, or general programming concepts.
metadata:
    harness: [claude, codex]
    platform: [darwin, linux]
    requires: "npx (ctx7 is run via npx)"
---

# Documentation Lookup

Retrieve current documentation and code examples for any library using the Context7 CLI.

Make sure the CLI is up to date before running commands:

```bash
npm install -g ctx7@latest
```

Or run directly without installing:

```bash
npx ctx7@latest <command>
```

## Workflow

Two-step process: resolve the library name to an ID, then query docs with that ID.

```bash
# Step 1: Resolve library ID
ctx7 library <name> <query>

# Step 2: Query documentation
ctx7 docs <libraryId> <query>
```

You MUST call `ctx7 library` first to obtain a valid library ID UNLESS the user explicitly provides a library ID in the format `/org/project` or `/org/project/version`.

IMPORTANT: Do not run these commands more than 3 times per question. If you cannot find what you need after 3 attempts, use the best result you have.

## Step 1: Resolve a Library

Resolves a package/product name to a Context7-compatible library ID and returns matching libraries.

```bash
ctx7 library react "How to clean up useEffect with async operations"
ctx7 library nextjs "How to set up app router with middleware"
ctx7 library prisma "How to define one-to-many relations with cascade delete"
```

Always pass a `query` argument. It is required and directly affects result ranking. Use the user's intent to form the query, which helps disambiguate when multiple libraries share a similar name. Do not include any sensitive or confidential information such as API keys, passwords, credentials, personal data, or proprietary code in your query.

Use the official library name with its real punctuation: "Next.js" rather than "nextjs", "Customer.io" rather than "customerio", "Three.js" rather than "threejs". If the results look wrong, retry with an alternate spelling or a rephrased question before settling for a weak match.

### Result fields

Each result includes:

- **Library ID**: Context7-compatible identifier (format: `/org/project`)
- **Name**: library or package name
- **Description**: short summary
- **Code Snippets**: number of available code examples
- **Source Reputation**: authority indicator (High, Medium, Low, or Unknown)
- **Benchmark Score**: quality indicator (100 is the highest score)
- **Versions**: list of versions if available. Use one of those versions if the user provides a version in their query. The format is `/org/project/version`.

### Selection process

1. Analyze the query to understand what library/package the user is looking for
2. Select the most relevant match based on:
   - Name similarity to the query (exact matches prioritized)
   - Description relevance to the query's intent
   - Documentation coverage (prioritize libraries with higher Code Snippet counts)
   - Source reputation (consider libraries with High or Medium reputation more authoritative)
   - Benchmark score (higher is better, 100 is the maximum)
3. If multiple good matches exist, acknowledge this but proceed with the most relevant one
4. If no good matches exist, clearly state this and suggest query refinements
5. For ambiguous queries, request clarification before proceeding with a best-guess match

### Version-specific IDs

If the user mentions a specific version, use a version-specific library ID:

```bash
# General (latest indexed)
ctx7 docs /vercel/next.js "How to set up app router"

# Version-specific
ctx7 docs /vercel/next.js/v14.3.0-canary.87 "How to set up app router"
```

The available versions are listed in the `ctx7 library` output. Use the closest match to what the user specified.

## Step 2: Query Documentation

Retrieves up-to-date documentation and code examples for the resolved library.

```bash
ctx7 docs /facebook/react "How to clean up useEffect with async operations"
ctx7 docs /vercel/next.js "How to add authentication middleware to app router"
ctx7 docs /prisma/prisma "How to define one-to-many relations with cascade delete"
```

### Writing good queries

The query directly affects the quality of results. Be specific and include relevant details. Do not include any sensitive or confidential information such as API keys, passwords, credentials, personal data, or proprietary code in your query.

| Quality | Example |
|---------|---------|
| Good | `"How to set up authentication with JWT in Express.js"` |
| Good | `"React useEffect cleanup function with async operations"` |
| Bad | `"auth"` |
| Bad | `"hooks"` |

Use the user's full question as the query when possible, vague one-word queries return generic results.

The output contains two types of content: **code snippets** (titled, with language-tagged blocks) and **info snippets** (prose explanations with breadcrumb context).

### Retry with `--research` if you weren't satisfied

If the default `ctx7 docs` answer didn't satisfy, re-run the same command **with `--research`** before giving up or answering from training data. This retries using sandboxed agents that git-pull the actual source repos plus a live web search, then synthesizes a fresh answer. More costly than the default, so use it as a targeted retry.

```bash
ctx7 docs /vercel/next.js "How does middleware matcher handle dynamic segments in v15?" --research
```

## Authentication

Works without authentication. For higher rate limits:

```bash
# Option A: environment variable
export CONTEXT7_API_KEY=your_key

# Option B: OAuth login
ctx7 login
```

## Error Handling

If a command fails with a quota error ("Monthly quota reached" or "quota exceeded"):
1. Inform the user their Context7 quota is exhausted
2. Suggest they authenticate for higher limits: `ctx7 login`
3. If they cannot or choose not to authenticate, answer from training knowledge and clearly note it may be outdated

Do not silently fall back to training data. Always tell the user why Context7 was not used.

## Common Mistakes

- Library IDs require a `/` prefix: `/facebook/react`, not `facebook/react`
- Always run `ctx7 library` first, `ctx7 docs react "hooks"` fails without a valid ID
- Use descriptive queries, not single words: `"React useEffect cleanup function"`, not `"hooks"`
- Do not include sensitive information (API keys, passwords, credentials) in queries
