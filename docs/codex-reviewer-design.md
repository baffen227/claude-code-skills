# Codex Reviewer Skill 設計文件

> **部署位置**：`~/.claude/skills/codex-reviewer/`（全域，跨倉庫使用）
> **設計日期**：2026-03-09
> **Skill 名稱**：`codex-reviewer`

## 概述

一個整合 OpenAI Codex CLI 的 Claude Code Skill，讓 Claude Code 呼叫 `codex` 命令對程式碼和文件進行獨立審查。透過雙命令分流策略，針對不同 review 對象選用最適合的 Codex 子命令。

## 檔案結構

```
~/.claude/skills/codex-reviewer/
├── SKILL.md                    # 核心指令（觸發條件、安全護欄、流程、分流邏輯）
├── references/
│   ├── code-review-prompt.md   # 程式碼 review 審查維度（供 Claude 理解，不直接傳給 codex）
│   ├── doc-review-prompt.md    # 文件 review 的審查維度與 prompt 模板
│   └── known-issues.md         # Codex CLI 已知問題、安全用法與 OOM 事故記錄
└── scripts/
    └── run-codex-review.py     # 報告組裝腳本（Python，使用 uv run 執行）
```

## 觸發條件

### 主動觸發

使用者手動要求 review（「幫我 review」、「請 Codex 檢查」）。

### 建議觸發（非強制）

以下情境中，Claude 會詢問「要不要請 Codex review 一下？」而非自動執行：

- 設計文件完成後，其他 skill 可建議執行 review
- commit 前，可建議先跑一次 review
- 修改 CLAUDE.md 或 skill 檔案後，可建議檢查一致性

## 分流邏輯

根據 review 對象自動選擇不同的 Codex 子命令：

| 情境 | 子命令 | 沙箱模式 | 典型用法 |
|------|--------|---------|---------|
| 有 git 變更需要 review | `codex review` | — | `codex review --uncommitted` 或 `codex review --base main` |
| 審查特定文件（計畫、CLAUDE.md、skill） | `codex exec` | `read-only` | 傳入自訂 prompt，讓 Codex agent 讀取指定檔案 |
| 混合情境（既有程式碼變更又有文件） | 兩者都執行 | — | 先跑 `codex review`，再跑 `codex exec` 審查文件 |

## 安全護欄

> **2026-03-09 實作經驗**：端到端測試時，錯誤的 codex CLI 用法導致 fork bomb（2,165 個 bash 子進程），耗盡 61GB RAM 觸發 OOM killer。以下護欄為必要防護。

1. **timeout 包裝**：所有 codex 指令必須前綴 `timeout 120`
2. **禁止 stdin pipe**：`codex review` 不支援 stdin 輸入（`cat | codex review -` 會觸發 fork bomb）
3. **`--uncommitted`/`--base` 不接受自訂 prompt**：codex-cli 0.112.0 的 CLI 限制，兩者不能同時使用
4. **零輸出監控**：30 秒無輸出即終止

詳見 `references/known-issues.md`。

## 執行流程

```
1. 判斷 review 範圍
   ├── 有 git diff？ → 標記「需要程式碼 review」
   └── 有指定文件或 docs/plans/*.md 變更？ → 標記「需要文件 review」

2. 程式碼 review（若需要）
   timeout 120 codex review --uncommitted > /tmp/codex-code-review.txt 2>&1
   或
   timeout 120 codex review --base main > /tmp/codex-code-review.txt 2>&1
   注意：必須使用 stdout 重導向，codex review 不支援 -o 旗標

3. 文件 review（若需要）
   timeout 120 codex exec -s read-only \
     -o /tmp/codex-doc-review.txt \
     "審查以下檔案：[檔案清單]。檢查：結構清晰度、內部一致性、可執行性。"
   注意：避免 --full-auto，改用 -s read-only 限制自主行為

4. 彙整結果
   uv run ~/.claude/skills/codex-reviewer/scripts/run-codex-review.py \
     --mode code|doc|mixed --subject <name>
   → 存入 docs/reviews/YYYY-MM-DD-<subject>.md

5. 向使用者摘要呈現重點發現
   codex 完成後，Claude 對照 references/ 的審查維度補充分析
```

## Review 維度

### 程式碼 review（`references/code-review-prompt.md`）

`codex review` 已內建程式碼審查能力。此模板供 Claude 理解完整審查維度，在 codex review 完成後補充 codex 未涵蓋的面向：

- 安全性（OWASP Top 10、命令注入、敏感資訊洩漏）
- 與 CLAUDE.md 約定的一致性（命名慣例、架構原則）
- 過度工程警示（YAGNI 檢查）

### 文件 review（`references/doc-review-prompt.md`）

針對不同文件類型定義審查維度：

| 文件類型 | 審查維度 |
|---------|---------|
| 計畫文件 `docs/plans/*.md` | 邏輯完整性、可行性、依賴關係是否合理、完成標準是否可驗證 |
| CLAUDE.md | 與實際專案狀態是否一致、是否有過時資訊、指令是否明確無歧義 |
| Skill 檔案 `SKILL.md` | description 觸發條件是否精準、指令是否用祈使句、漸進式披露是否合理 |
| 通用文件 | 結構清晰度、用詞一致性、是否有遺漏或矛盾 |

## Review 結果格式

每次 review 的結果存入 `docs/reviews/YYYY-MM-DD-<subject>.md`：

```markdown
# Codex Review: <subject>
- **日期**：YYYY-MM-DD
- **範圍**：[程式碼 / 文件 / 混合]
- **審查檔案**：[清單]

## 重點發現
- ...

## 建議改善
- ...

## 無問題確認
- ...
```
