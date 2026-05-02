#!/usr/bin/env bash
# reverse-source-notes.sh
#
# 用途: 掃 vault 中所有 zettel-atomized 原子筆記，反查其 source-notes frontmatter，
#       輸出已處理過的 source note 名稱集合 (sorted-unique)。
#       供 zettel-atomizer 冪等重跑時過濾已處理的來源筆記。
#
# 用法:
#   reverse-source-notes.sh <vault_root> [search_dir...]
#
# $1:         vault root 絕對路徑
# $2..(可選): 在 vault_root 下要掃的子目錄，預設 Notes inbox
#
# stdout: 已處理 source note 標題，每行一個，sorted-unique (去除 [[ ]] 與引號)
# 注意：僅支援 source-notes 的 YAML block-sequence (每行 - item) 形式

set -euo pipefail

if [ "$#" -eq 0 ]; then
    echo "Usage: $(basename "$0") <vault_root> [search_dir...]" >&2
    exit 2
fi

VAULT="$1"
shift

if [ ! -d "$VAULT" ]; then
    echo "Error: vault root not found: $VAULT" >&2
    exit 3
fi

# 預設搜尋 Notes 與 inbox；Notes 下的 inbox/ 在真實 vault 中已涵蓋，
# inbox 兜底測試 fixture 中 inbox/ 擺在 vault root 的情況
if [ "$#" -eq 0 ]; then
    set -- Notes inbox
fi

# 收集存在的搜尋目錄；不存在者靜默跳過
search_dirs=()
for d in "$@"; do
    full="$VAULT/$d"
    if [ -d "$full" ]; then
        search_dirs+=("$full")
    fi
done

if [ "${#search_dirs[@]}" -eq 0 ]; then
    # 全部搜尋目錄都不存在，仍正常結束，輸出空
    exit 0
fi

# 對每個 .md 檔跑兩段 awk:
#   第一段：確認 distilled-from 以 zettel-atomizer 開頭
#   第二段：抽出 source-notes block-list 的值
extract_source_notes() {
    local file="$1"

    # 第一段：確認是 zettel-atomized 筆記
    local is_atomized
    is_atomized=$(awk '
        BEGIN { fm=0 }
        /^---[[:space:]]*$/ { fm++; if (fm==2) exit; next }
        fm==1 && /^distilled-from:[[:space:]]*zettel-atomizer/ { print "yes"; exit }
    ' "$file" 2>/dev/null)

    [ "$is_atomized" = "yes" ] || return 0

    # 第二段：抽出 source-notes 列表值，去除引號與 [[ ]] wikilink 括號
    # 使用 /^[^[:space:]-]/ 作為 sn 結束守衛，比 /^[a-zA-Z]/ 更嚴格：
    # 可正確處理 CJK 或其他非 ASCII YAML key 緊接在 source-notes 後的情況
    awk '
        BEGIN { fm=0; sn=0 }
        /^---[[:space:]]*$/ { fm++; if (fm==2) exit; next }
        fm==1 && /^source-notes:[[:space:]]*$/ { sn=1; next }
        fm==1 && sn==1 {
            if (/^[[:space:]]*-[[:space:]]+/) {
                sub(/^[[:space:]]*-[[:space:]]+/, "")
                gsub(/^"/, "")
                gsub(/"$/, "")
                gsub(/^\[\[/, "")
                gsub(/\]\]$/, "")
                print
                next
            }
            if (/^[^[:space:]-]/) sn=0
        }
    ' "$file" 2>/dev/null
}

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

find "${search_dirs[@]}" -type f -name '*.md' -print0 \
    | while IFS= read -r -d '' file; do
        extract_source_notes "$file"
    done >> "$tmp"

sort -u "$tmp"
