#!/usr/bin/env bash
# write-draft.sh — zettel-atomizer 寫檔腳本
#
# 用途: 把 stdin 的筆記正文寫到 $OBSIDIAN_VAULT/Notes/[structure-]<title>.md (直落永久區)
#
# 用法:
#   write-draft.sh atomic "<陳述句標題>" < note-body.md
#   echo "<body>" | write-draft.sh structure "<批次標籤>"
#
# 類型:
#   atomic    — 原子筆記，檔名: <title>.md
#   structure — 結構筆記，檔名: structure-<title>.md
#
# 2026-08-08 Obsidian 重定位後: 不再經 Notes/inbox/ 暫存、檔名不帶日期前綴
# (created 日期在 frontmatter)。

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "用法: $0 <atomic|structure> <標題>" >&2
    echo "  從 stdin 讀筆記正文，寫到 \$OBSIDIAN_VAULT/Notes/[structure-]<標題>.md" >&2
    exit 2
fi

TYPE="$1"
TITLE="$2"

if [ "$TYPE" != "atomic" ] && [ "$TYPE" != "structure" ]; then
    echo "ERROR: type 必須是 atomic 或 structure，收到: $TYPE" >&2
    exit 2
fi

VAULT_ROOT="${OBSIDIAN_VAULT:-$HOME/Obsidian}"
NOTES_DIR="$VAULT_ROOT/Notes"

if [ ! -d "$VAULT_ROOT" ]; then
    echo "ERROR: vault 路徑不存在: $VAULT_ROOT" >&2
    echo "設 OBSIDIAN_VAULT 環境變數或建 ~/Obsidian/ 再試" >&2
    exit 3
fi

# 過濾掉檔名危險字元 (路徑分隔符、null)，其餘保留
SAFE_TITLE="$(printf '%s' "$TITLE" | tr -d '/\0')"

mkdir -p "$NOTES_DIR"

# atomic 不加前綴；structure 加 structure- 前綴
if [ "$TYPE" = "structure" ]; then
    BASE_NAME="structure-${SAFE_TITLE}"
else
    BASE_NAME="${SAFE_TITLE}"
fi

# 同名檔案避免覆寫: 加流水號 -2, -3, ...
TARGET="$NOTES_DIR/${BASE_NAME}.md"
COUNTER=2
while [ -e "$TARGET" ]; do
    TARGET="$NOTES_DIR/${BASE_NAME}-${COUNTER}.md"
    COUNTER=$((COUNTER + 1))
done

# 先寫到暫存檔，驗證內容後再移到目標路徑 — 失敗時 Notes/ 不留空檔
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

cat > "$TMP"

# 過濾全部空白字元後檢查長度，純空白或空 stdin 都算失敗
if [ "$(tr -d '[:space:]' < "$TMP" | wc -c)" -eq 0 ]; then
    echo "ERROR: stdin 無實際內容 (僅空白字元或全空)，未產出筆記" >&2
    exit 4
fi

mv "$TMP" "$TARGET"
echo "$TARGET"
