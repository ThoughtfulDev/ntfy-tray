#!/bin/zsh

set -euo pipefail

release_ref=${1:?"Usage: release_notes.sh <tag-or-ref> [output-path]"}
output_path=${2:-/dev/stdout}

git rev-parse --verify --quiet "${release_ref}^{commit}" >/dev/null || {
    print -u2 "Unknown release ref: $release_ref"
    exit 1
}

previous_tag=$(git describe --tags --abbrev=0 "${release_ref}^" 2>/dev/null || true)
commit_range=$release_ref
if [[ -n "$previous_tag" ]]; then
    commit_range="$previous_tag..$release_ref"
fi

typeset -a features fixes quality maintenance other_changes

while IFS=$'\t' read -r commit_hash subject; do
    description="${subject#*: }"
    if [[ "$description" == "$subject" ]]; then
        description="$subject"
    fi

    short_hash=${commit_hash[1,7]}
    if [[ -n ${GITHUB_REPOSITORY:-} ]]; then
        commit_reference="[\`$short_hash\`](https://github.com/$GITHUB_REPOSITORY/commit/$commit_hash)"
    else
        commit_reference="\`$short_hash\`"
    fi
    entry="$description ($commit_reference)"

    case "$subject" in
        feat:* | feat\(*)
            features+=("$entry")
            ;;
        fix:* | fix\(*)
            fixes+=("$entry")
            ;;
        test:* | test\(* | refactor:* | refactor\(* | perf:* | perf\(*)
            quality+=("$entry")
            ;;
        chore:* | chore\(* | ci:* | ci\(* | build:* | build\(*)
            maintenance+=("$entry")
            ;;
        *)
            other_changes+=("$entry")
            ;;
    esac
done < <(git log --format='%H%x09%s' "$commit_range")

print_section() {
    local title=$1
    shift
    (( $# > 0 )) || return 0

    print -r -- "## $title"
    for item in "$@"; do
        print -r -- "- $item"
    done
    print
}

{
    print "# ntfy-tray $release_ref"
    print

    if [[ -n "$previous_tag" ]]; then
        print "Changes since \`$previous_tag\`."
        if [[ -n ${GITHUB_REPOSITORY:-} ]]; then
            print "[Full changelog](https://github.com/$GITHUB_REPOSITORY/compare/$previous_tag...$release_ref)"
        fi
    else
        print "Initial release."
    fi
    print

    print_section "Features" "${features[@]}"
    print_section "Fixes" "${fixes[@]}"
    print_section "Quality" "${quality[@]}"
    print_section "Maintenance" "${maintenance[@]}"
    print_section "Other changes" "${other_changes[@]}"
} > "$output_path"
