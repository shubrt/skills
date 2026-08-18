I'm shubrt. You're my agent. We will be working together a lot, so I thought it would be worth introducing myself.

I love to build. I focus on building complex things as simple as possible. I love to find ways to reduce complexity when solving problems.

I wanted to share some of my preferences here so we can be more aligned as we work together.

## Coding preferences - general

* Keep things simple. Channel "yagni" energy unless told otherwise.
* Typesafety is useful, take advantage of it.
* Don't be scared to propose bold ideas if they can meaningfully benefit our work.
* Be careful with destructive actions that are not explicitly requested by the user.
* Tests are good! Endless smoke tests, "regression tests" for feature deletions, etc., much less good. Tests should be focused, not slop.
* Comments are a great way to clarify functionality and how code is used. Don't comment every line, but feel free to describe (concisely) how functions are used above function definitions, classes, etc.
* Keep comments up to date! When making changes, it's important to keep things in sync.

## Coding preferences (Typescript focused)

* `any` is the enemy. Inferred types are our friend. Our systems should adapt to changes, instead of requiring changes everywhere.
* If your TS code looks like a Python dev wrote it, it is bad TS code.
* Avoid one-line functions that are just casting wrappers.
* Write TypeScript in ways that Matt Pocock and Theo would be proud of.
* When building more complex web and react native apps, I like to pull in Zustand, React Query, Tanstack Start, Clerk (or better-auth if selfhosting), and ArkType (or zod if perf isn't an issue)

## Questions are read-only

* A question is a request for an answer, not for changes. If the message opens with "how hard would it be", "what are your thoughts", "why does", "should we", "is it possible", "can X do Y", or otherwise asks rather than instructs: answer it, and do not edit files.
* If the answer is obvious and the change is trivial, still answer first and offer the change. Ask before making it.

## Match ceremony to the task

* Do not spawn subagents or a multi-agent panel for work a single agent finishes in one pass. Delegation is for breadth or adversarial review, not for ordinary tasks.
* When several agents do work in parallel, state file ownership up front so they do not collide.

## Visual and design work

* Do not edit real components first. Any non-trivial UI, layout, or copy change starts as mocks in the `pushdraft` skill, which holds that procedure.
* Standing constraints: dark mode, true black (`#000`) background, white primary text. Information-dense, no decorative card/pill chrome, no light-gray subtitle lines above sections. Minimal copy. No em dashes.
* Avoid continuously repainting CSS animations (pulse, shimmer, blur, spinners); they peg the GPU on high-refresh displays.

## Blast radius

* Never touch production, live databases, or daily-driver build/preview channels unless explicitly told to. When a task is adjacent to any of them, name what you are about to touch before touching it.

## Git branches

* Before the first push or pull request, rename a current `t3code/*` branch to the same suffix under `shubrt/*`.
* If the suffix is still a temporary eight-character hash, choose a descriptive `shubrt/*` branch name instead.
* Never push a branch to a remote under `t3code/*`.

## Pull Requests

* Open PRs with the `open-pr` skill, monitor them with `babysit-pr`. The skills hold the procedure: title conventions, description shape, rebase, no drafts, and the closing note about model and harness.
