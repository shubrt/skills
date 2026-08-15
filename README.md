# Forge

Forge is the central, tool-independent home for my global agent configuration.
Instructions and skills are maintained once and shared by Claude Code and Codex.
The repository remains the single source of truth for all self-managed global agent rules.

## Structure

- `AGENTS.md` contains the global instructions.
- `skills/<name>/SKILL.md` contains a reusable skill.
- `bin/install.sh` links the repository to Claude Code and Codex.
- Shared support files can live in `references/`, `templates/`, or `scripts/`.

## Installation

The script works from any current working directory. It resolves the repository path relative to its own location.

First, inspect the planned changes:

```bash
./bin/install.sh --dry-run
```

Then install the links:

```bash
./bin/install.sh
```

From another working directory, run the script using its absolute path:

```bash
/path/to/forge/bin/install.sh
```

Installation only runs from the main checkout. A linked Git worktree is refused, because removing that worktree would break the global configuration of both tools at once. The error message names the correct path.

## Uninstallation

```bash
./bin/install.sh --uninstall
```

This removes the instruction and skill symlinks that point into this repository, in both tools, and leaves everything else untouched. Backups of foreign files stay in place. Unlike installation, this also works from a worktree. Combine it with `--dry-run` to see the plan first.

## What gets installed

The global instructions are linked directly:

```text
~/.codex/AGENTS.md   -> <repository>/AGENTS.md
~/.claude/CLAUDE.md -> <repository>/AGENTS.md
```

Each repository skill is linked into both tools separately:

```text
~/.agents/skills/<name> -> <repository>/skills/<name>
~/.claude/skills/<name> -> <repository>/skills/<name>
```

The skill directories remain intact. Existing, synced, and tool-specific skills can continue to live alongside Forge skills.

Codex uses `${CODEX_HOME}` instead of `~/.codex` when the variable is set. Claude Code uses `${CLAUDE_CONFIG_DIR}` instead of `~/.claude`.

## Safety and backups

After installation, changes to `AGENTS.md` and existing skills affect both tools immediately.
Review repository changes before applying them.

If a target already contains another file, directory, or incorrect symlink, the script moves it to a timestamped backup:

```text
<target>.backup.YYYYMMDD-HHMMSS
```

Backups of conflicting files, directories, and third-party symlinks are never deleted automatically. The script does not overwrite existing configuration and can be run repeatedly. Correct symlinks remain unchanged.

When a skill is removed from this repository, the next install removes its stale symlinks. It also removes Forge symlink backups left by older installer runs, both in the skill directories and next to `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md`. The installer recognizes Forge links across Git worktrees, while symlinks to third-party skill directories remain unchanged.

A backup symlink whose target no longer exists cannot be attributed to this repository. The installer reports it as `WARN` and leaves the removal to you.

To restore a backup, remove the generated symlink and move the backup to its original name.

## Adding skills

Create a new skill at `skills/<name>/SKILL.md`, then run the installation script again. Existing skill links do not need to be reinstalled after content changes.

## Checks

```bash
./bin/check.sh
```

Installation runs this first and refuses to link anything when it fails, because a broken skill breaks both tools at once. Uninstallation skips it, so the way back stays open. The checks cover what a broken file does not report on its own:

- `name` in the frontmatter matches the directory name, otherwise the skill never loads.
- `description` exists, stays on one line, and stays under 1024 characters, otherwise the router silently truncates it.
- `SKILL.md` stays under 500 lines. Longer content belongs in a reference file.
- A frontmatter field outside the six the Agent Skills spec defines is tool-specific, so the skill also needs `agents/openai.yaml` to behave the same in Codex.
- Tracked Markdown contains no em dashes.
- Tracked shell scripts parse, and pass `shellcheck` when it is installed.
