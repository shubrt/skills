#!/usr/bin/env bash
#
# Usage:
#   bin/check.sh
#
# Validates this repository against the rules that a broken file does not
# announce on its own: a skill silently never loads, a Claude-only frontmatter
# field silently does nothing in Codex, and a description over the spec limit is
# silently truncated. bin/install.sh runs this before it links anything.
#
# Prose rules are checked in tracked Markdown only. Shell scripts are code, and
# their comments are not subject to the writing rules.

set -euo pipefail

# The only frontmatter fields the Agent Skills spec defines. Anything else is a
# tool-specific extension and needs a counterpart for the other tool.
spec_fields='name description license compatibility metadata allowed-tools'
description_limit=1024
skill_line_limit=500

failures=0

status() {
    local level=$1
    shift
    printf '[%s] %s\n' "$level" "$*"
}

fail() {
    status FAIL "$*" >&2
    failures=$((failures + 1))
}

# Print the YAML frontmatter of a Markdown file, without the delimiters.
# Exits non-zero when the file does not open with a frontmatter block.
frontmatter() {
    awk 'NR == 1 && $0 != "---" { exit 1 }
         NR == 1 { next }
         $0 == "---" { exit }
         { print }' <"$1"
}

# Print the value of a top-level frontmatter key. Nested keys are indented and
# therefore never match.
field_value() {
    local key=$1
    printf '%s\n' "$2" | awk -v key="$key" '
        $0 ~ "^" key ":" {
            sub("^" key ": *", "")
            print
            exit
        }'
}

# Print every top-level key of a frontmatter block.
field_names() {
    printf '%s\n' "$1" | awk -F: '/^[A-Za-z][A-Za-z0-9_-]*:/ { print $1 }'
}

check_skill() {
    local skill_dir=$1
    local name=${skill_dir##*/}
    local skill_file="$skill_dir/SKILL.md"
    local block
    local declared_name
    local description
    local lines
    local key

    if [[ ! -f $skill_file ]]; then
        fail "$name: no SKILL.md"
        return
    fi

    if ! block=$(frontmatter "$skill_file"); then
        fail "$name: SKILL.md does not start with a frontmatter block"
        return
    fi

    declared_name=$(field_value name "$block")
    if [[ $declared_name != "$name" ]]; then
        fail "$name: frontmatter name is '${declared_name:-missing}', which must match the directory"
    fi

    description=$(field_value description "$block")
    if [[ -z $description ]]; then
        fail "$name: description is missing or empty, so the router has no trigger to match"
    elif [[ $description == '>'* || $description == '|'* ]]; then
        fail "$name: description is a YAML block scalar. Keep it on one line so its length can be checked."
    elif ((${#description} > description_limit)); then
        fail "$name: description is ${#description} characters, over the spec limit of $description_limit"
    fi

    lines=$(($(wc -l <"$skill_file")))
    if ((lines > skill_line_limit)); then
        fail "$name: SKILL.md is $lines lines, over the $skill_line_limit line guideline. Move detail into a reference file."
    fi

    while read -r key; do
        [[ -n $key ]] || continue
        [[ " $spec_fields " == *" $key "* ]] && continue
        if [[ ! -f $skill_dir/agents/openai.yaml ]]; then
            fail "$name: '$key' is a Claude-only field, so Codex needs agents/openai.yaml to match the behaviour"
        fi
    done < <(field_names "$block")
}

repo_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd -- "$repo_dir"

for skill_dir in skills/*; do
    [[ -d $skill_dir ]] || continue
    check_skill "$skill_dir"
done

while read -r file; do
    if grep -n -- '—' "$file" >/dev/null; then
        fail "$file: contains an em dash"
        grep -n -- '—' "$file" >&2
    fi
done < <(git ls-files '*.md')

while read -r script; do
    bash -n -- "$script" || fail "$script: bash syntax error"
    if command -v shellcheck >/dev/null 2>&1; then
        shellcheck -- "$script" || fail "$script: shellcheck findings"
    fi
done < <(git ls-files '*.sh')

if ((failures > 0)); then
    status FAIL "$failures problem(s) found." >&2
    exit 1
fi

status PASS 'All checks passed.'
