#!/usr/bin/env bash
#
# Usage:
#   bin/install.sh [--dry-run]
#   bin/install.sh --help
#
# Safety:
#   This script links global Codex and Claude Code configuration to this
#   repository. Changes in the repository then affect both tools immediately.
#   Existing conflicting files, directories, and symlinks are moved to a
#   timestamped backup. Backups are never deleted automatically.

set -euo pipefail

usage() {
    printf '%s\n' \
        'Usage: bin/install.sh [--dry-run]' \
        '       bin/install.sh --help' \
        '' \
        'Link this repository to the global Codex and Claude Code config.' \
        '' \
        'Options:' \
        '  --dry-run  Show planned changes without modifying anything.' \
        '  -h, --help Show this help.'
}

status() {
    local level=$1
    shift
    printf '[%s] %s\n' "$level" "$*"
}

die() {
    status ERROR "$*" >&2
    exit 1
}

dry_run=false

while (($# > 0)); do
    case $1 in
        --dry-run)
            dry_run=true
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        --)
            shift
            (($# == 0)) || die "Unexpected argument: $1"
            break
            ;;
        *)
            die "Unknown option: $1"
            ;;
    esac
    shift
done

[[ -n ${HOME:-} ]] || die 'HOME is not set.'
[[ $HOME == /* && $HOME != / ]] || die "HOME must be an absolute user directory: $HOME"

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_dir=$(CDPATH= cd -- "$script_dir/.." && pwd -P)

agents_source="$repo_dir/AGENTS.md"
skills_source="$repo_dir/skills"
codex_dir=${CODEX_HOME:-"$HOME/.codex"}
claude_dir=${CLAUDE_CONFIG_DIR:-"$HOME/.claude"}
agents_skills_dir="$HOME/.agents/skills"
claude_skills_dir="$claude_dir/skills"

[[ $codex_dir == /* && $codex_dir != / ]] || die "CODEX_HOME must be an absolute config directory: $codex_dir"
[[ $claude_dir == /* && $claude_dir != / ]] || die "CLAUDE_CONFIG_DIR must be an absolute config directory: $claude_dir"
[[ -f $agents_source ]] || die "Missing source file: $agents_source"
[[ -d $skills_source ]] || die "Missing source directory: $skills_source"

skill_count=0
for skill_dir in "$skills_source"/*; do
    [[ -d $skill_dir ]] || continue
    [[ -f $skill_dir/SKILL.md ]] || die "Skill has no SKILL.md: $skill_dir"
    ((skill_count += 1))
done
((skill_count > 0)) || die "No skills found in: $skills_source"

timestamp=$(date '+%Y%m%d-%H%M%S')
last_backup=''

next_backup_path() {
    local target=$1
    local candidate="${target}.backup.${timestamp}"
    local suffix=1

    while [[ -e $candidate || -L $candidate ]]; do
        candidate="${target}.backup.${timestamp}.${suffix}"
        suffix=$((suffix + 1))
    done

    printf '%s\n' "$candidate"
}

backup_target() {
    local target=$1

    last_backup=$(next_backup_path "$target")
    if $dry_run; then
        status DRY-RUN "Would move $target to $last_backup"
        return
    fi

    if mv -- "$target" "$last_backup"; then
        status BACKUP "$target -> $last_backup"
    else
        die "Could not back up: $target"
    fi
}

restore_backup() {
    local target=$1
    local backup=$2

    [[ -n $backup && ( -e $backup || -L $backup ) ]] || return 0
    [[ ! -e $target && ! -L $target ]] || return 0

    if mv -- "$backup" "$target"; then
        status RESTORE "$backup -> $target"
    else
        status ERROR "Could not restore $backup to $target" >&2
    fi
}

ensure_config_dir() {
    local dir=$1

    if [[ -d $dir ]]; then
        status OK "$dir"
        return
    fi
    [[ ! -e $dir && ! -L $dir ]] || die "Config path exists but is not a directory: $dir"

    if $dry_run; then
        status DRY-RUN "Would create directory $dir"
    elif mkdir -p -- "$dir"; then
        status CREATE "$dir"
    else
        die "Could not create directory: $dir"
    fi
}

ensure_skill_dir() {
    local dir=$1
    local backup=''

    if [[ -d $dir && ! -L $dir ]]; then
        status OK "$dir"
        return
    fi

    if [[ -e $dir || -L $dir ]]; then
        backup_target "$dir"
        backup=$last_backup
    fi

    if $dry_run; then
        status DRY-RUN "Would create directory $dir"
    elif mkdir -p -- "$dir"; then
        status CREATE "$dir"
    else
        restore_backup "$dir" "$backup"
        die "Could not create skill directory: $dir"
    fi
}

ensure_link() {
    local source=$1
    local target=$2
    local backup=''

    if [[ -L $target && $target -ef $source ]]; then
        status OK "$target -> $source"
        return
    fi

    if [[ -e $target || -L $target ]]; then
        backup_target "$target"
        backup=$last_backup
    fi

    if $dry_run; then
        status DRY-RUN "Would link $target -> $source"
    elif ln -s -- "$source" "$target"; then
        status LINK "$target -> $source"
    else
        restore_backup "$target" "$backup"
        die "Could not create symlink: $target"
    fi
}

status INFO "Repository: $repo_dir"
$dry_run && status INFO 'Dry run enabled. No files will be changed.'

ensure_config_dir "$codex_dir"
ensure_config_dir "$claude_dir"
ensure_skill_dir "$agents_skills_dir"
ensure_skill_dir "$claude_skills_dir"

ensure_link "$agents_source" "$codex_dir/AGENTS.md"
ensure_link "$agents_source" "$claude_dir/CLAUDE.md"

for skill_dir in "$skills_source"/*; do
    [[ -d $skill_dir ]] || continue
    skill_name=${skill_dir##*/}
    ensure_link "$skill_dir" "$agents_skills_dir/$skill_name"
    ensure_link "$skill_dir" "$claude_skills_dir/$skill_name"
done

if $dry_run; then
    status DONE 'Dry run complete.'
else
    status DONE 'Global agent configuration installed.'
fi
