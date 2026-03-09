#!/usr/bin/env bash
# Install claude-code-skills by creating symlinks in ~/.claude/skills/
#
# Usage:
#   git clone https://github.com/bagfen/claude-code-skills.git
#   cd claude-code-skills
#   ./setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

mkdir -p "$SKILLS_DIR"

SKILLS=(uv-python-setup codex-reviewer)

for skill in "${SKILLS[@]}"; do
    source="$SCRIPT_DIR/$skill"
    target="$SKILLS_DIR/$skill"

    if [ ! -d "$source" ]; then
        echo "SKIP: $skill (directory not found in repo)"
        continue
    fi

    if [ -L "$target" ]; then
        existing="$(readlink -f "$target")"
        if [ "$existing" = "$source" ]; then
            echo "OK:   $skill (symlink already correct)"
            continue
        fi
        echo "UPDATE: $skill (replacing symlink $existing -> $source)"
        rm "$target"
    elif [ -d "$target" ]; then
        echo "BACKUP: $skill (moving existing directory to ${target}.bak)"
        mv "$target" "${target}.bak"
    fi

    ln -s "$source" "$target"
    echo "LINK: $skill -> $source"
done

echo ""
echo "Done. Skills installed:"
for skill in "${SKILLS[@]}"; do
    if [ -L "$SKILLS_DIR/$skill" ]; then
        echo "  ~/.claude/skills/$skill -> $(readlink "$SKILLS_DIR/$skill")"
    fi
done
