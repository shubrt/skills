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
