#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $(basename "$0") <vault-root> <tag>" >&2
    exit 2
fi

VAULT="$1"
TAG="$2"

if [ ! -d "$VAULT" ]; then
    echo "Error: vault root not found: $VAULT" >&2
    exit 3
fi

CATEGORIES="$VAULT/Categories"

if [ ! -d "$CATEGORIES" ]; then
    exit 0
fi

tag_lower="$(printf '%s' "$TAG" | tr '[:upper:]' '[:lower:]')"

results=()

while IFS= read -r -d '' filepath; do
    basename_no_ext="$(basename "$filepath" .md)"
    name_lower="$(printf '%s' "$basename_no_ext" | tr '[:upper:]' '[:lower:]')"

    matched=0

    # Condition 1: filename (without .md) contains the tag string (case-insensitive)
    if [[ "$name_lower" == *"$tag_lower"* ]]; then
        matched=1
    fi

    # Condition 2: frontmatter tags: block-list contains the tag exactly
    if [ "$matched" -eq 0 ]; then
        # 假設 frontmatter 形式良好 (有開頭 --- 與閉合 ---)。
        # 缺閉合 --- 的檔會掃到 EOF,但 body 的 markdown unordered list 只在
        # 行首為「- 」格式且前面剛好出現 tags: 字串時才會誤觸,實際 vault 不會發生。
        if awk '
            BEGIN { in_front=0; in_tags=0 }
            /^---/ { in_front++; if (in_front > 1) exit }
            in_front==1 && /^tags:/ { in_tags=1; next }
            in_tags && /^  - / {
                val = substr($0, 5)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
                # tag 比對在 frontmatter 為 case-sensitive (vault 慣例 tag 全小寫,Steph Ango 規則);
                # filename 比對則是 case-insensitive。caller 應傳 lowercase tag。
                if (val == tag) { print "found"; exit }
                next
            }
            in_tags && !/^[[:space:]]/ { in_tags=0 }
        ' tag="$TAG" "$filepath" | grep -q "found"; then
            matched=1
        fi
    fi

    if [ "$matched" -eq 1 ]; then
        rel="${filepath#"$VAULT/"}"
        results+=("$rel")
    fi
done < <(find "$CATEGORIES" -maxdepth 1 -name "*.md" -print0)

if [ "${#results[@]}" -gt 0 ]; then
    printf '%s\n' "${results[@]}" | sort -u
fi
