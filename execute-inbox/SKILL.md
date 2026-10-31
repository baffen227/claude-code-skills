---
name: execute-inbox
description: 執行 dispatcher 調度員派來的任務單。使用時機：收到「/execute-inbox <id>」或「請用 execute-inbox 執行 <id>」。讀 ~/dispatch/inbox/<id>.md 照做，回報寫到 ~/dispatch/outbox/<id>.md。
---

# execute-inbox

完整協定見 repo `btbu_tasks_tracker` 的 `docs/dispatch-protocol.md`。本 skill 是執行時的精簡版。

## 步驟
1. 讀 `~/dispatch/inbox/<id>.md`。任務單是唯一依據，假設你沒看過任何聊天紀錄。
2. 會改檔案的任務：
   - 用 git worktree 開在 `~/dispatch/worktrees/<id>`（不要放 /tmp，重開機會消失）。
   - 新分支 `exp/<id>`，從任務單指定的起點開；沒指定就從 `main`。
   - 只 commit。禁止 merge、push、改 main、動主 repo 工作區、刪任何分支。
3. 只讀的任務不開 worktree，也不改任何檔案。
4. 中途不提問。可逆的決定自己做，記進「決策紀錄」。只有不可逆或缺資訊時才停下，寫 `NEEDS_DECISION`。
5. 不改 CLAUDE.md 以外的設定、不改 Claude Code／Herdr 設定、不改自己的 memory，除非任務單明確要求。
6. 結束時寫 `~/dispatch/outbox/<id>.md`，章節：結果摘要／收據（機器、worktree、分支、commit、有無 push）／改了哪些檔案／已驗證（指令、退出碼、輸出片段）／未驗證／決策紀錄／阻擋與待決問題／STATUS。
7. 最後一行必須是其一：`STATUS: DONE`、`STATUS: BLOCKED: <原因>`、`STATUS: NEEDS_DECISION: <問題>`。
8. 追問不在 pane 裡來回；調度員會開新任務單。

## 主動訊息（不是回應任務單）
要主動通知 Harry 或某個 bot 時，寫 `~/dispatch/outbox/YYYYMMDD-HHMM-<主題>.md`：第一行「給：Harry」或「給：<bot 名>」，最後一行 `STATUS: DONE`、`STATUS: BLOCKED: <原因>` 或 `STATUS: INFO`。Harry 叫調度員「讀信箱」時才會被讀取。
