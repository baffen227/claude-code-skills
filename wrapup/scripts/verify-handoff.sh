#!/usr/bin/env bash
# wrapup handoff outbound gate.
#
# Machine-verifies the three required elements of a next-session handoff BEFORE a
# session may be reported "wrapped up / 收尾完成". Concept borrowed from
# swarm-forge's swarm_handoff.sh machine-verified outbound gate; the three
# elements are per the 2026-08-15 Claude Code workflow-improvement plan (C3):
#
#   (i)   a commit hash for each touched repo, verified to exist via git rev-parse
#   (ii)  each gate's exit code (a skipped gate marked skipped)
#   (iii) an unfinished-items list (or the literal: none)
#
# The handoff file must contain exactly one fenced machine block. The prose above
# it is what the next agent reads; this block is what the gate reads:
#
#   ```wrapup-verify
#   commit <hash|none> <repo-abs-path>
#   gate <exit-code|skipped> <freeform label>
#   open <freeform item, or the literal: none>
#   ```
#
# Repeat commit/gate/open lines as needed. At least one of each is required.
# `commit none <repo>` records a touched repo that had nothing to commit.
#
# Usage: verify-handoff.sh <handoff-file>
# Exit:  0  all three elements present and every commit hash verified
#        1  one or more elements missing/invalid (do NOT report wrapped up)
#        2  usage / unreadable file / missing machine block

set -uo pipefail

die() { printf 'verify-handoff: %s\n' "$1" >&2; exit 2; }

[ $# -eq 1 ] || die "usage: verify-handoff.sh <handoff-file>"
file=$1
[ -f "$file" ] && [ -r "$file" ] || die "cannot read handoff file: $file"

grep -q '^```wrapup-verify[[:space:]]*$' "$file" \
  || die 'handoff has no ```wrapup-verify machine block (see script header for format)'

block=$(awk '
  /^```wrapup-verify[[:space:]]*$/ { inb=1; next }
  inb && /^```[[:space:]]*$/       { inb=0; next }
  inb                              { print }
' "$file")

commits=0; gates=0; opens=0; fail=0
report() { printf '  [FAIL] %s\n' "$1" >&2; fail=1; }

while IFS= read -r line; do
    # trim surrounding whitespace; skip blanks
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [ -z "$line" ] && continue

    read -r directive value rest <<<"$line"
    case "$directive" in
        commit)
            commits=$((commits + 1))
            if [ -z "$value" ] || [ -z "$rest" ]; then
                report "commit line needs '<hash|none> <repo-path>': $line"
            elif [ "$value" = "none" ]; then
                printf '  [ok]   commit none (nothing committed) in %s\n' "$rest" >&2
            elif git -C "$rest" rev-parse --verify --quiet "${value}^{commit}" >/dev/null 2>&1; then
                printf '  [ok]   commit %s exists in %s\n' "$value" "$rest" >&2
            else
                report "commit '$value' NOT found in repo '$rest' (git rev-parse failed)"
            fi
            ;;
        gate)
            gates=$((gates + 1))
            if [ "$value" = "skipped" ] || [[ "$value" =~ ^[0-9]+$ ]]; then
                printf '  [ok]   gate %s %s\n' "$value" "$rest" >&2
            else
                report "gate line needs '<exit-code|skipped> <label>': $line"
            fi
            ;;
        open)
            opens=$((opens + 1))
            [ -n "$value" ] || report "open line needs an item or the literal 'none': $line"
            ;;
        *)
            report "unknown directive '$directive' (expected commit|gate|open): $line"
            ;;
    esac
done <<<"$block"

[ "$commits" -ge 1 ] || report "no 'commit' line (element i: verified commit hash)"
[ "$gates" -ge 1 ]   || report "no 'gate' line (element ii: gate exit codes)"
[ "$opens" -ge 1 ]   || report "no 'open' line (element iii: unfinished items)"

if [ "$fail" -ne 0 ]; then
    printf 'verify-handoff: HANDOFF INCOMPLETE — do NOT report the session wrapped up.\n' >&2
    exit 1
fi
printf 'verify-handoff: OK — three handoff elements present and commit(s) verified.\n'
exit 0
