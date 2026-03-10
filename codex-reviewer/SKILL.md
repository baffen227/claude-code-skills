---
name: codex-reviewer
description: Review code and documents using OpenAI Codex CLI. Use when user asks for review ("幫我 review", "請 Codex 檢查", "codex review"), or suggest (non-mandatory) after design docs are completed, before commits, or after modifying CLAUDE.md or skill files. Supports code review (git changes), document review (plans, CLAUDE.md, SKILL.md files), and mixed review.
---

# Codex Reviewer

整合 OpenAI Codex CLI 對程式碼與文件進行審查，產出結構化審查報告。

## 1. 觸發行為

### 主動觸發

當使用者明確要求審查時立即執行（例如「幫我 review」、「請 Codex 檢查」、「codex review」）。

### 建議觸發（非強制）

在以下情境中，詢問「要不要請 Codex review 一下？」而非自動執行：

- 設計文件撰寫完成後
- 執行 `git commit` 之前
- 修改 `CLAUDE.md` 或任何 `SKILL.md` 之後

## 2. 前置檢查：確保 Codex CLI 為最新版本

每次執行審查前，先確認 Codex CLI 為最新版本：

```bash
codex --version
```

若非最新版本，執行更新：

```bash
sudo npm i -g @openai/codex@latest
```

更新後重新確認版本，再繼續後續流程。

---

## 3. 安全護欄

**所有 codex 指令必須遵守以下規則。違反任何一條都可能導致系統 OOM。**

### 3.1 必須使用 timeout 包裝

依指令類型使用不同的 timeout 上限：

- **`codex review`**：`timeout 300`（300 秒，大型 diff 可能需要數分鐘）
- **`codex exec`**：`timeout 300`（300 秒，文件審查需讀取多檔案、web search 與交叉比對）

```bash
timeout 300 codex review --uncommitted
timeout 300 codex exec -s read-only ...
```

### 3.2 禁止透過 stdin 傳遞 prompt

`codex review` **不支援** stdin 輸入。以下用法會導致 fork bomb：

```bash
# 禁止 — 會產生數千個 bash 子進程並觸發 OOM
cat prompt.md | codex review --uncommitted -
codex review --uncommitted "$(cat very-long-prompt.md)"
```

正確做法：將 prompt 精簡為一行內的關鍵指示，直接作為位置引數傳入。

### 3.3 `--uncommitted` / `--base` 不接受自訂 prompt

codex-cli 0.112.0 的 `codex review` 在搭配 `--uncommitted` 或 `--base` 時**不允許**位置引數 `[PROMPT]`。`references/code-review-prompt.md` 的完整內容僅供 Claude 理解審查維度，用於在 codex review 完成後補充分析，**不得**傳給 codex CLI。

### 3.4 零輸出監控

若 codex 指令在 **30 秒內無任何 stdout 輸出**，視為異常，立即終止。不要等待 timeout 到期。

詳細的事故記錄與 CLI 限制參見 `references/known-issues.md`。

---

## 4. 審查範圍偵測

執行以下檢查以決定審查模式：

```bash
git diff --stat
git diff --cached --stat
```

- 若有程式碼變更 → 標記為 **code review**
- 若變更包含 `docs/plans/*.md`、`CLAUDE.md`、`**/SKILL.md`，或使用者指定了特定文件 → 標記為 **doc review**
- 若兩者皆有 → **mixed mode**，依序執行程式碼審查與文件審查

## 5. 程式碼審查流程

針對 git 變更，執行 `codex review`。**必須遵守第 3 節的安全護欄。**

先閱讀 `references/code-review-prompt.md` 理解完整審查維度。注意：`codex review` 在搭配 `--uncommitted` 或 `--base` 時**不允許**自訂 prompt（CLI 限制），只能使用 codex 內建的 review 邏輯。

**審查未提交的變更：**

```bash
timeout 300 codex review --uncommitted > /tmp/codex-code-review.txt 2>&1
```

**審查相對於基礎分支的變更：**

```bash
timeout 300 codex review --base main > /tmp/codex-code-review.txt 2>&1
```

> **禁止**：`--uncommitted` 和 `--base` 不能與 `[PROMPT]` 位置引數同時使用。也不得透過 pipe/stdin 傳遞 prompt。詳見 `references/known-issues.md`。

Codex 內建 review 已涵蓋安全性與程式碼品質檢查。review 完成後，Claude 應對照 `references/code-review-prompt.md` 的維度，**補充 codex 未涵蓋的審查面向**（如 CLAUDE.md 一致性、YAGNI 檢查）。

## 6. 文件審查流程

針對文件審查，使用 `codex exec`。**必須遵守第 3 節的安全護欄。**

先閱讀 `references/doc-review-prompt.md` 選擇對應文件類型的審查維度，然後濃縮為短 prompt。

```bash
timeout 300 codex exec -s read-only \
  -o /tmp/codex-doc-review.txt \
  "Review the following files for: structural clarity, internal consistency, actionability, CLAUDE.md alignment. Files: [file list]. Output as markdown: 重點發現, 建議改善, 無問題確認."
```

將 `[file list]` 替換為實際的檔案路徑清單（以空格分隔）。

> **注意**：避免使用 `--full-auto`，改用明確的 sandbox 層級（`-s read-only`）以限制 codex 的自主行為。

若 codex 指令產出為空或執行失敗，由 Claude 自行根據 `references/doc-review-prompt.md` 的維度直接審查文件，不再重試 codex。

## 7. 報告組裝

執行 Python 腳本組裝結構化審查報告：

```bash
uv run ~/.claude/skills/codex-reviewer/scripts/run-codex-review.py \
  --mode code|doc|mixed \
  --subject "<descriptive-name>" \
  --output-dir docs/reviews/
```

參數說明：

- `--mode`：`code`、`doc`、或 `mixed`，對應偵測到的審查模式
- `--subject`：報告的描述性名稱（例如 `auth-refactor`、`q1-roadmap`）
- `--output-dir`：報告輸出目錄，預設為 `docs/reviews/`

腳本從 `/tmp/codex-code-review.txt` 和/或 `/tmp/codex-doc-review.txt` 讀取原始審查結果，組裝為結構化 markdown 報告，輸出至 `docs/reviews/YYYY-MM-DD-<subject>.md`。

若腳本不存在，手動將審查結果整合為報告，包含以下區段：

- **審查摘要** — 審查範圍、模式、日期
- **重點發現** — 需要關注的問題
- **建議改善** — 可選的改進建議
- **無問題確認** — 確認通過的項目

## 8. 結果呈現

報告產出後，向使用者呈現精簡摘要：

1. 列出審查模式與涵蓋範圍
2. 摘要重點發現（若有嚴重問題，明確標示）
3. 提供報告完整路徑供使用者參閱
4. 若有建議改善項目，詢問是否要逐項處理

## 附帶資源

| 檔案 | 用途 |
|------|------|
| `references/code-review-prompt.md` | 程式碼審查的完整 prompt 模板（供 Claude 理解維度，不直接傳給 codex） |
| `references/doc-review-prompt.md` | 各文件類型的審查維度與 prompt 模板（供 Claude 理解維度，不直接傳給 codex） |
| `references/known-issues.md` | Codex CLI 已知問題、安全用法與 OOM 事故記錄 |
| `scripts/run-codex-review.py` | 報告組裝腳本 |
