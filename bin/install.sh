#!/usr/bin/env bash
#
# Usage:
#   bin/install.sh [--dry-run]
#   bin/install.sh --uninstall [--dry-run]
#   bin/install.sh --help
#
# Safety:
#   This script links global Codex and Claude Code configuration to this
#   repository. Changes in the repository then affect both tools immediately.
#   Existing conflicting files, directories, and third-party symlinks are moved
#   to a timestamped backup. Obsolete links from this Git repository are
#   removed, including symlink backups created by earlier installer runs.
#   Installing from a linked Git worktree is refused: deleting that worktree
#   would break the global configuration of both tools at once.

set -euo pipefail

usage() {
    printf '%s\n' \
        'Usage: bin/install.sh [--dry-run]' \
        '       bin/install.sh --uninstall [--dry-run]' \
        '       bin/install.sh --help' \
        '' \
        'Link this repository to the global Codex and Claude Code config.' \
        '' \
        'Options:' \
        '  --dry-run   Show planned changes without modifying anything.' \
        '  --uninstall Remove the links this repository installed and leave' \
        '              everything else in place.' \
        '  -h, --help  Show this help.'
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

# Print an absolute, symlink-free Git directory for a checkout. The flag selects
# which one: --git-common-dir is shared by every worktree of a repository and
# identifies the repository, --git-dir is specific to one worktree.
resolve_git_path() {
    local checkout=$1
    local flag=$2
    local git_dir

    git_dir=$(git -C "$checkout" rev-parse "$flag" 2>/dev/null) || return 1
    if [[ $git_dir != /* ]]; then
        git_dir="$checkout/$git_dir"
    fi

    CDPATH= cd -- "$git_dir" && pwd -P
}

resolve_git_common_dir() {
    resolve_git_path "$1" --git-common-dir
}

dry_run=false
uninstall_mode=false

while (($# > 0)); do
    case $1 in
        --dry-run)
            dry_run=true
            ;;
        --uninstall)
            uninstall_mode=true
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

agents_source="$repo_dir/instructions/AGENTS.md"
skills_source="$repo_dir/skills"
codex_dir=${CODEX_HOME:-"$HOME/.codex"}
claude_dir=${CLAUDE_CONFIG_DIR:-"$HOME/.claude"}
agents_skills_dir="$HOME/.agents/skills"
claude_skills_dir="$claude_dir/skills"

[[ $codex_dir == /* && $codex_dir != / ]] || die "CODEX_HOME must be an absolute config directory: $codex_dir"
[[ $claude_dir == /* && $claude_dir != / ]] || die "CLAUDE_CONFIG_DIR must be an absolute config directory: $claude_dir"
[[ -f $agents_source ]] || die "Missing source file: $agents_source"
[[ -d $skills_source ]] || die "Missing source directory: $skills_source"
repo_git_dir=$(resolve_git_common_dir "$repo_dir") || die "Could not identify Git repository: $repo_dir"

skill_count=0
for skill_dir in "$skills_source"/*; do
    [[ -d $skill_dir ]] || continue
    [[ -f $skill_dir/SKILL.md ]] || die "Skill has no SKILL.md: $skill_dir"
    ((skill_count += 1))
done
((skill_count > 0)) || die "No skills found in: $skills_source"

# Linking a broken skill breaks it in both tools at once, so validate first.
# Uninstalling only removes links and stays available when the tree is broken.
if ! $uninstall_mode; then
    "$script_dir/check.sh" || die 'Repository checks failed. Fix the problems above, then install again.'
fi

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

# Refuse to install from a linked worktree. Its path disappears when the
# worktree is pruned, which would leave the global instructions and every skill
# dangling in Codex and Claude Code at the same time. In the main checkout the
# worktree Git directory and the shared Git directory are the same path.
assert_main_checkout() {
    local worktree_git_dir
    local main_checkout=''

    worktree_git_dir=$(resolve_git_path "$repo_dir" --git-dir) || die "Could not identify Git repository: $repo_dir"
    [[ $worktree_git_dir != "$repo_git_dir" ]] || return 0

    main_checkout=$(git -C "$repo_dir" worktree list --porcelain 2>/dev/null |
        awk 'NR == 1 && $1 == "worktree" { print substr($0, 10); exit }') || main_checkout=''

    die "Refusing to link global config to the worktree $repo_dir. Run bin/install.sh from ${main_checkout:-the main checkout} instead."
}

remove_link() {
    local target=$1
    local link_source=$2

    if $dry_run; then
        status DRY-RUN "Would remove link $target -> $link_source"
    elif rm -- "$target"; then
        status REMOVE "$target -> $link_source"
    else
        die "Could not remove link: $target"
    fi
}

# A backup link whose target no longer exists cannot be attributed to this
# repository, so it is reported instead of removed.
warn_dangling_backup() {
    local target=$1
    local link_source=$2

    [[ ${target##*/} == *.backup.* ]] || return 0
    status WARN "Dangling backup link, remove by hand if it is stale: $target -> $link_source"
}

# Resolve a symlink to an absolute path without requiring the target to exist.
read_link_source() {
    local target=$1
    local link_source

    link_source=$(readlink -- "$target") || die "Could not read symlink: $target"
    if [[ $link_source != /* ]]; then
        link_source="$(dirname -- "$target")/$link_source"
    fi

    printf '%s\n' "$link_source"
}

# Remove instruction links this repository owns from a config directory. Only
# symlinks pointing at an AGENTS.md inside this repository qualify, so real
# files and third-party links are never touched. During install this clears the
# symlink backups older runs left behind; during uninstall it also clears the
# active link.
remove_obsolete_config_links() {
    local dir=$1
    local name=$2
    local targets=("$dir/$name".backup.*)
    local target
    local link_source
    local source_dir
    local source_git_dir

    if $uninstall_mode; then
        targets+=("$dir/$name")
    fi

    for target in "${targets[@]}"; do
        [[ -L $target ]] || continue

        link_source=$(read_link_source "$target")
        [[ ${link_source##*/} == 'AGENTS.md' ]] || continue

        if ! source_dir=$(CDPATH= cd -- "$(dirname -- "$link_source")" 2>/dev/null && pwd -P); then
            warn_dangling_backup "$target" "$link_source"
            continue
        fi
        source_git_dir=$(resolve_git_common_dir "$source_dir") || continue
        [[ $source_git_dir == "$repo_git_dir" ]] || continue

        remove_link "$target" "$link_source"
    done
}

remove_obsolete_skill_links() {
    local dir=$1
    local target
    local link_source
    local source_dir
    local source_repo_dir
    local source_git_dir
    local source_name
    local target_name
    local current_source

    for target in "$dir"/*; do
        [[ -L $target ]] || continue

        link_source=$(read_link_source "$target")

        if ! source_dir=$(CDPATH= cd -- "$(dirname -- "$link_source")" 2>/dev/null && pwd -P); then
            warn_dangling_backup "$target" "$link_source"
            continue
        fi
        source_repo_dir=$(CDPATH= cd -- "$source_dir/.." 2>/dev/null && pwd -P) || continue
        [[ $source_dir == "$source_repo_dir/skills" ]] || continue

        source_git_dir=$(resolve_git_common_dir "$source_repo_dir") || continue
        [[ $source_git_dir == "$repo_git_dir" ]] || continue

        source_name=${link_source##*/}
        target_name=${target##*/}
        current_source="$skills_source/$source_name"

        if [[ $target_name == "$source_name" ]]; then
            if ! $uninstall_mode && [[ -d $current_source && $target -ef $current_source ]]; then
                continue
            fi
        elif [[ $target_name != "$source_name.backup."* ]]; then
            continue
        fi

        remove_link "$target" "$link_source"
    done
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
if $dry_run; then
    status INFO 'Dry run enabled. No files will be changed.'
fi

if $uninstall_mode; then
    remove_obsolete_config_links "$codex_dir" 'AGENTS.md'
    remove_obsolete_config_links "$claude_dir" 'CLAUDE.md'
    remove_obsolete_skill_links "$agents_skills_dir"
    remove_obsolete_skill_links "$claude_skills_dir"

    if $dry_run; then
        status DONE 'Dry run complete.'
    else
        status DONE 'Global agent configuration uninstalled. Backups of foreign files were left in place.'
    fi
    exit 0
fi

assert_main_checkout

ensure_config_dir "$codex_dir"
ensure_config_dir "$claude_dir"
ensure_skill_dir "$agents_skills_dir"
ensure_skill_dir "$claude_skills_dir"

remove_obsolete_config_links "$codex_dir" 'AGENTS.md'
remove_obsolete_config_links "$claude_dir" 'CLAUDE.md'
remove_obsolete_skill_links "$agents_skills_dir"
remove_obsolete_skill_links "$claude_skills_dir"

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
