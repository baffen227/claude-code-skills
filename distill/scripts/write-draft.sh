#!/usr/bin/env bash
# write-draft.sh — distill skill 寫檔腳本
#
# 用途: 把 stdin 的草稿正文寫到 ~/Obsidian/Notes/inbox/YYYY-MM-DD-<title>.md
#
# 用法:
#   write-draft.sh "<陳述句標題>" < draft-body.md
#   echo "<draft body>" | write-draft.sh "<陳述句標題>"
#
# Phase A: 直接寫檔備援。Obsidian CLI 整合預留 (見 maybe_use_cli)。

set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "用法: $0 <標題>" >&2
    echo "  從 stdin 讀草稿正文，寫到 ~/Obsidian/Notes/inbox/YYYY-MM-DD-<標題>.md" >&2
    exit 2
fi

TITLE="$1"
VAULT_ROOT="${OBSIDIAN_VAULT:-$HOME/Obsidian}"
INBOX_DIR="$VAULT_ROOT/Notes/inbox"
TODAY="$(date +%Y-%m-%d)"

if [ ! -d "$VAULT_ROOT" ]; then
    echo "ERROR: vault 路徑不存在: $VAULT_ROOT" >&2
    echo "設 OBSIDIAN_VAULT 環境變數或建 ~/Obsidian/ 再試" >&2
    exit 3
fi

if [ -z "$TITLE" ]; then
    echo "ERROR: 標題不可空" >&2
    exit 2
fi

# 過濾掉檔名危險字元 (路徑分隔符、null)，其餘 (空格、中文、標點) 保留
SAFE_TITLE="$(printf '%s' "$TITLE" | tr -d '/\0')"

mkdir -p "$INBOX_DIR"

# 同名檔案避免覆寫: 加流水號 -2, -3, ...
BASE_NAME="${TODAY}-${SAFE_TITLE}"
TARGET="$INBOX_DIR/${BASE_NAME}.md"
COUNTER=2
while [ -e "$TARGET" ]; do
    TARGET="$INBOX_DIR/${BASE_NAME}-${COUNTER}.md"
    COUNTER=$((COUNTER + 1))
done

# Phase B 升級點: 偵測 obsidian CLI 在 PATH 時優先呼叫，否則直寫
maybe_use_cli() {
    if command -v obsidian >/dev/null 2>&1; then
        # TODO: 確認 Flatpak 包裝下 obsidian CLI 是否能寫入本機 vault 路徑
        # 目前 Phase A 仍走直寫，CLI 整合另案處理
        return 1
    fi
    return 1
}

# 先寫到暫存檔，驗證內容後再移到目標路徑 — 失敗時 inbox 不留空檔
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

if maybe_use_cli; then
    : # CLI 路徑 (Phase B)
else
    cat > "$TMP"
fi

# 過濾全部空白字元後檢查長度，純空白或空 stdin 都算失敗
if [ "$(tr -d '[:space:]' < "$TMP" | wc -c)" -eq 0 ]; then
    echo "ERROR: stdin 無實際內容 (僅空白字元或全空)，未產出草稿" >&2
    exit 4
fi

mv "$TMP" "$TARGET"
echo "$TARGET"
