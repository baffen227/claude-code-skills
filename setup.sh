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
OUTPUT_STYLES_DIR="$HOME/.claude/output-styles"

mkdir -p "$SKILLS_DIR" "$OUTPUT_STYLES_DIR"

SKILLS=(uv-python-setup codex-reviewer tea-gitea classical-chinese-rules distill)

# Output styles managed by this repo. Format: <repo-relative-source>:<filename-in-output-styles-dir>
OUTPUT_STYLES=(
    "classical-chinese-rules/output-styles/concise-tw.md:concise-tw.md"
)

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

for entry in "${OUTPUT_STYLES[@]}"; do
    source_rel="${entry%%:*}"
    filename="${entry##*:}"
    source="$SCRIPT_DIR/$source_rel"
    target="$OUTPUT_STYLES_DIR/$filename"

    if [ ! -f "$source" ]; then
        echo "SKIP: output-style $filename (source not found: $source_rel)"
        continue
    fi

    if [ -L "$target" ]; then
        existing="$(readlink -f "$target")"
        if [ "$existing" = "$source" ]; then
            echo "OK:   output-style $filename (symlink already correct)"
            continue
        fi
        echo "UPDATE: output-style $filename (replacing symlink $existing -> $source)"
        rm "$target"
    elif [ -f "$target" ]; then
        echo "BACKUP: output-style $filename (moving existing file to ${target}.bak)"
        mv "$target" "${target}.bak"
    fi

    ln -s "$source" "$target"
    echo "LINK: output-style $filename -> $source"
done

echo ""
echo "Done. Skills installed:"
for skill in "${SKILLS[@]}"; do
    if [ -L "$SKILLS_DIR/$skill" ]; then
        echo "  ~/.claude/skills/$skill -> $(readlink "$SKILLS_DIR/$skill")"
    fi
done

echo ""
echo "Output styles installed:"
for entry in "${OUTPUT_STYLES[@]}"; do
    filename="${entry##*:}"
    if [ -L "$OUTPUT_STYLES_DIR/$filename" ]; then
        echo "  ~/.claude/output-styles/$filename -> $(readlink "$OUTPUT_STYLES_DIR/$filename")"
    fi
done

echo ""
echo "Note: 新啟用的 output style 必須開新 Claude Code session 才會生效"
echo "      /config → Output style → 選對應風格，然後重新啟動 session"
