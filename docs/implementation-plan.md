# 全域 Skills 實施計畫：uv-python-setup + codex-reviewer

> **狀態：✅ 全部完成**（2026-03-09）

**Goal:** 建立兩個全域 Claude Code Skills — `uv-python-setup`（Python uv 開發環境初始化）和 `codex-reviewer`（整合 Codex CLI 的程式碼與文件審查）。

**Architecture:** 兩個 skill 皆部署在 `~/.claude/skills/`，跨倉庫使用。`uv-python-setup` 是前置 skill，`codex-reviewer` 的 Python 腳本依賴 uv 環境。`uv-python-setup` 包含 SKILL.md 與 references/；`codex-reviewer` 額外包含 scripts/。

**Tech Stack:** Claude Code Skills（SKILL.md）、Bash、Python 3、uv、Codex CLI (`codex-cli` 0.112.0)

## 實施過程中的重要發現

### codex-cli 0.112.0 的 CLI 限制

1. **`codex review --uncommitted` 不能搭配自訂 `[PROMPT]`** — argument parser 衝突，會直接報錯
2. **`codex review` 不支援 `-o` 旗標** — 必須用 stdout 重導向（`>`）
3. **`cat prompt.md | codex review --uncommitted -` 會觸發 fork bomb** — 在 5 分鐘內產生 2,165 個 bash 子進程，耗盡 61GB RAM 觸發 OOM killer

### 因應措施（已寫入 SKILL.md）

- 所有 codex 指令前綴 `timeout 120`
- 禁止透過 stdin pipe 傳遞 prompt
- `references/*.md` 僅供 Claude 理解審查維度，不直接傳給 codex CLI
- 文件 review 使用 `-s read-only` 而非 `--full-auto`

---

## Task 1: 建立 uv-python-setup SKILL.md

**Files:**
- Create: `~/.claude/skills/uv-python-setup/SKILL.md`

**Step 1: 建立目錄**

```bash
mkdir -p ~/.claude/skills/uv-python-setup/references
```

**Step 2: 撰寫 SKILL.md**

建立 `~/.claude/skills/uv-python-setup/SKILL.md`，內容包含：

- **Frontmatter:**
  - `name: uv-python-setup`
  - `description:` 觸發條件（初始化 Python 環境、設定 uv、setup python、被其他 skill 前置引用時）
- **Body（祈使句）:**
  - 第一階段：核心自動執行流程（檢查/安裝 uv → 檢查/建立 pyproject.toml → 建立 scripts/ tests/ → 更新 CLAUDE.md）
  - 第二階段：可選互動（ruff、pre-commit），使用 AskUserQuestion 詢問
  - 第三階段：收尾（uv sync → 摘要）
  - 包含 CLAUDE.md 更新模板
  - 引用 `references/ruff-config.md`

**Step 3: 驗證 SKILL.md 格式**

確認：
- YAML frontmatter 有 `name` 和 `description`
- Body 使用祈使句（「檢查 uv 是否已安裝」而非「你應該檢查」）
- 引用的 references/ 路徑正確

---

## Task 2: 建立 ruff-config 參考文件

**Files:**
- Create: `~/.claude/skills/uv-python-setup/references/ruff-config.md`

**Step 1: 撰寫 ruff 設定模板**

內容包含：
- `pyproject.toml` 中 `[tool.ruff]` 的建議設定（line-length、target-version、select rules）
- `[tool.ruff.format]` 的建議設定
- `.pre-commit-config.yaml` 中 ruff hook 的模板

```toml
[tool.ruff]
target-version = "py312"
line-length = 88

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP"]

[tool.ruff.format]
quote-style = "double"
```

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.11.12
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
```

---

## Task 3: 在 knowledge-os 測試 uv-python-setup

**Step 1: 觸發 skill**

在 knowledge-os 倉庫中對 Claude Code 說「初始化 Python 環境」，確認 skill 被觸發。

**Step 2: 驗證核心階段**

預期結果：
- [ ] uv 已安裝，`uv --version` 有輸出
- [ ] `pyproject.toml` 已建立
- [ ] `scripts/` 和 `tests/` 目錄已建立
- [ ] CLAUDE.md 中有 Python 開發環境區塊

**Step 3: 驗證可選階段**

- [ ] 被詢問是否要 ruff，回答「是」後 `uv add --dev ruff` 成功
- [ ] 被詢問是否要 pre-commit，回答「是」後 `.pre-commit-config.yaml` 已建立

**Step 4: 驗證收尾**

- [ ] `uv sync` 成功
- [ ] 顯示摘要

**Step 5: Commit**

```bash
git add pyproject.toml uv.lock scripts/ tests/ CLAUDE.md .pre-commit-config.yaml .python-version
git commit -m "初始化 Python uv 開發環境"
```

---

## Task 4: 建立 codex-reviewer SKILL.md

**Files:**
- Create: `~/.claude/skills/codex-reviewer/SKILL.md`

**Step 1: 建立目錄**

```bash
mkdir -p ~/.claude/skills/codex-reviewer/{references,scripts}
```

**Step 2: 撰寫 SKILL.md**

建立 `~/.claude/skills/codex-reviewer/SKILL.md`，內容包含：

- **Frontmatter:**
  - `name: codex-reviewer`
  - `description:` 觸發條件（使用者要求 review、請 Codex 檢查；建議觸發情境：設計文件完成後、commit 前、修改 CLAUDE.md 或 skill 後）
- **Body（祈使句）:**
  - 分流邏輯判斷規則（git diff 存在 → codex review、指定文件 → codex exec、混合 → 兩者都跑）
  - 程式碼 review 流程：呼叫 `codex review --uncommitted` 或 `codex review --base <branch>`，stdout 重導向捕捉結果
  - 文件 review 流程：呼叫 `codex exec --full-auto -s read-only -o <output>`，prompt 引用 `references/doc-review-prompt.md` 的審查維度
  - 結果彙整：呼叫 `scripts/run-codex-review.py` 組裝 review 報告存入 `docs/reviews/`
  - 向使用者摘要呈現重點發現
  - 引用 `references/code-review-prompt.md` 和 `references/doc-review-prompt.md`

**Step 3: 驗證格式**

確認 YAML frontmatter、祈使句、引用路徑皆正確。

---

## Task 5: 建立 code-review-prompt 參考文件

**Files:**
- Create: `~/.claude/skills/codex-reviewer/references/code-review-prompt.md`

**Step 1: 撰寫程式碼 review 補充指令**

作為 `codex review` 的自訂 prompt 傳入，聚焦於：
- 安全性審查（OWASP Top 10、命令注入、敏感資訊洩漏）
- 與 CLAUDE.md 約定的一致性（命名慣例、架構原則）
- 過度工程警示（YAGNI 檢查）
- 輸出格式要求（結構化 markdown，分「重點發現」「建議改善」「無問題確認」）

---

## Task 6: 建立 doc-review-prompt 參考文件

**Files:**
- Create: `~/.claude/skills/codex-reviewer/references/doc-review-prompt.md`

**Step 1: 撰寫文件 review 審查維度**

依文件類型定義 prompt 模板：

| 文件類型 | 審查維度 |
|---------|---------|
| `docs/plans/*.md` | 邏輯完整性、可行性、依賴關係合理性、完成標準可驗證性 |
| `CLAUDE.md` | 與專案狀態一致性、過時資訊、指令明確性 |
| `SKILL.md` | 觸發條件精準度、祈使句用法、漸進式披露合理性 |
| 通用文件 | 結構清晰度、用詞一致性、遺漏或矛盾 |

每種類型提供完整的 prompt 模板，可直接傳給 `codex exec`。

---

## Task 7: 建立 run-codex-review.py 腳本

**Files:**
- Create: `~/.claude/skills/codex-reviewer/scripts/run-codex-review.py`

**Step 1: 撰寫腳本**

功能：
- 接收參數：`--mode code|doc|mixed`、`--files <file list>`、`--base <branch>`、`--subject <name>`
- code 模式：執行 `codex review --uncommitted`（或 `--base`），捕捉 stdout
- doc 模式：讀取 `references/doc-review-prompt.md`，組合 prompt，執行 `codex exec --full-auto -s read-only -o <tmpfile>`
- mixed 模式：依序執行兩者
- 將結果組裝為 markdown 報告，寫入 `docs/reviews/YYYY-MM-DD-<subject>.md`
- 使用標準庫：`subprocess`、`pathlib`、`datetime`、`argparse`、`sys`

**Step 2: 加入 inline script metadata（uv 格式）**

在檔案頂部加入 PEP 723 inline metadata，讓 `uv run` 可直接執行：

```python
# /// script
# requires-python = ">=3.12"
# ///
```

**Step 3: 驗證腳本可執行**

```bash
chmod +x ~/.claude/skills/codex-reviewer/scripts/run-codex-review.py
uv run ~/.claude/skills/codex-reviewer/scripts/run-codex-review.py --help
```

預期：顯示 argparse 的 help 訊息。

---

## Task 8: 端到端測試 codex-reviewer

**Step 1: 測試程式碼 review**

在 knowledge-os 倉庫中製造一個小變更（例如在 CLAUDE.md 加一行註解），然後對 Claude Code 說「請 Codex review 一下」。

預期：
- [ ] Skill 被觸發
- [ ] 偵測到 git diff，走 code 模式
- [ ] `codex review --uncommitted` 被執行
- [ ] 結果存入 `docs/reviews/` 並向使用者摘要

**Step 2: 測試文件 review**

對 Claude Code 說「請 Codex 審查 docs/plans/ 下的設計文件」。

預期：
- [ ] 走 doc 模式
- [ ] `codex exec` 搭配 doc-review-prompt 被執行
- [ ] 結果存入 `docs/reviews/` 並向使用者摘要

**Step 3: 測試混合 review**

在有未提交變更的狀態下，對 Claude Code 說「請 Codex 全面 review」。

預期：
- [ ] 走 mixed 模式
- [ ] 兩個命令依序執行
- [ ] 統一結果報告

**Step 4: Commit 測試產出的 review 檔案**

```bash
git add docs/reviews/
git commit -m "新增 codex-reviewer 端到端測試結果"
```

---

## Task 9: 將設計文件與實施記錄 commit

**Step 1: Commit 更新後的設計文件**

```bash
cd ~/Projects/knowledge-os
git add docs/plans/2026-03-09-uv-python-setup-skill-design.md \
        docs/plans/2026-03-09-codex-reviewer-skill-design.md \
        docs/plans/2026-03-09-global-skills-implementation.md
git commit -m "新增全域 skills 設計文件與實施計畫

包含 uv-python-setup 與 codex-reviewer 兩個全域 skill 的
設計文件與分步實施計畫。"
```
