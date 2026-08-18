---
name: typescript
description: Apply TypeScript coding preferences. Use when writing, editing, reviewing, or refactoring TypeScript or TSX code, including architecture and library choices for web and React Native apps.
---

# TypeScript

Follow these preferences for TypeScript work:

- Avoid `any`. Prefer inferred types so the system adapts to changes without requiring edits everywhere.
- Write idiomatic TypeScript, not code shaped like Python.
- Avoid one-line functions that only wrap a cast.
- Write TypeScript in ways that Matt Pocock and Theo would be proud of.
- For complex web and React Native apps, prefer Zustand, React Query, TanStack Start, Clerk or better-auth when self-hosting, and ArkType or Zod when its performance is sufficient.
