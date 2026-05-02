#!/usr/bin/env bash
# aggregate-source-whiteboard.sh
#
# 用途: 從 stdin 讀 obsidian tag verbose 輸出，對每個檔解析 source-whiteboard
#       frontmatter 列表，計算覆蓋率與分布。
#
# 用法:
#   obsidian tag name=ebpf verbose | aggregate-source-whiteboard.sh /path/to/vault
#
# stdin: obsidian CLI 輸出，第一行為 header (#tag<TAB>count)，後續為相對路徑
# $1:    vault root 絕對路徑
#
# stdout:
#   <count>\t<source-whiteboard-value>   (按 count 倒序)
#   TOTAL=<n> COVERED=<n> COVERAGE=<pct>%

set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "用法: $0 <vault_root>" >&2
    exit 2
fi

VAULT="$1"

if [ ! -d "$VAULT" ]; then
    echo "ERROR: vault 路徑不存在: $VAULT" >&2
    exit 3
fi

total=0
covered=0
declare -A buckets

while IFS= read -r line; do
    # 跳過 obsidian CLI header (#tag<TAB>count)
    [[ "$line" =~ ^# ]] && continue
    # 跳過空行
    [[ -z "$line" ]] && continue

    total=$((total + 1))
    file_path="$VAULT/$line"

    # 磁碟上找不到的檔，靜默跳過
    if [ ! -f "$file_path" ]; then
        continue
    fi

    # 抓 frontmatter 中 source-whiteboard 列表的值
    # 支援 0 空格縮排 (- item) 與 2 空格縮排 (  - item)
    # 注意：僅支援 YAML block-sequence (每行 - item) 與單列陣列，inline flow form
    # 例如「source-whiteboard: [A, B]」或單值「source-whiteboard: A」目前不解析。
    vals=$(awk '
        BEGIN{fm=0; sw=0}
        /^---[[:space:]]*$/{fm++; if(fm==2) exit; next}
        fm==1 && /^source-whiteboard:[[:space:]]*$/{sw=1; next}
        fm==1 && sw==1 {
            if (/^[[:space:]]*-[[:space:]]+/) {
                sub(/^[[:space:]]*-[[:space:]]+/, "")
                print
                next
            }
            if (/^[^[:space:]-]/) sw=0
        }
    ' "$file_path" 2>/dev/null)

    if [ -n "$vals" ]; then
        covered=$((covered + 1))
        while IFS= read -r v; do
            [ -z "$v" ] && continue
            buckets["$v"]=$((${buckets["$v"]:-0} + 1))
        done <<< "$vals"
    fi
done

# 印 buckets 按 count 倒序
for k in "${!buckets[@]}"; do
    printf "%d\t%s\n" "${buckets[$k]}" "$k"
done | sort -rn

# 最後一行：覆蓋率統計
if [ "$total" -gt 0 ]; then
    pct=$(awk -v c="$covered" -v t="$total" 'BEGIN{printf "%.0f", c*100/t}')
else
    pct=0
fi
echo "TOTAL=$total COVERED=$covered COVERAGE=${pct}%"
