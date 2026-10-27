# Skills

Global instructions and reusable skills shared by Claude Code and Codex. This repository is the source of truth for both tools.

## Install

Run the installer from the main checkout. It refuses linked worktrees because removing one would break the global configuration.

```bash
./bin/install.sh --dry-run
./bin/install.sh
```

The installer validates the repository, backs up conflicts as `<target>.backup.YYYYMMDD-HHMMSS`, and creates these links:

```text
~/.codex/AGENTS.md          -> <repository>/instructions/AGENTS.md
~/.claude/CLAUDE.md        -> <repository>/instructions/AGENTS.md
~/.agents/skills/<name>    -> <repository>/skills/<name>
~/.claude/skills/<name>    -> <repository>/skills/<name>
```

`CODEX_HOME` and `CLAUDE_CONFIG_DIR` override the corresponding tool config directories. Changes to linked instructions and skills take effect immediately.

## Uninstall

```bash
./bin/install.sh --uninstall
```

This removes links managed by the repository and leaves backups and unrelated files untouched. Add `--dry-run` to preview the changes.

## Repository layout

- `instructions/AGENTS.md` contains the global instructions.
- `skills/<name>/SKILL.md` contains each reusable skill.
- `bin/install.sh` manages the global links.
- `bin/check.sh` validates skills and scripts.

To add a skill, create its `SKILL.md`, run `./bin/check.sh`, then run the installer again.

## Imported skills

Nine skills come from [t3dotgg/tstack](https://github.com/t3dotgg/tstack/tree/92e38e2cf677a84a142e8df296861c588542135c),
at commit `92e38e2cf677a84a142e8df296861c588542135c`:

- `babysit-pr`
- `council`
- `file-pr`
- `full-send`
- `full-stop`
- `leaving-pr-comments`
- `modernize`
- `sol-loop`
- `takeover`

Their MIT license is in [licenses/tstack.txt](licenses/tstack.txt).
`babysit-pr` retains the local paginated review-thread checks and handoff report.
`modernize` uses a single-line description for this repository's validator.
`file-pr` replaces the former `open-pr` skill and retains its shell requirements
and rebase rule, using the PR's intended base branch.

The PR workflows need an authenticated `gh`; `babysit-pr` also needs Python 3.
`council` and `sol-loop` need access to their requested models through T3 Code
or compatible subagent tools.
