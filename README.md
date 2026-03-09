# claude-code-skills

個人的 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 全域 Skills 合集。每個 skill 部署在 `~/.claude/skills/`，跨倉庫使用。

## Skills 一覽

| Skill | 用途 | 觸發方式 |
|-------|------|---------|
| [uv-python-setup](./uv-python-setup/) | 在任何倉庫初始化 Python uv 開發環境 | 「初始化 Python 環境」、「設定 uv」、「setup python」 |
| [codex-reviewer](./codex-reviewer/) | 整合 OpenAI Codex CLI 進行程式碼與文件審查 | 「幫我 review」、「請 Codex 檢查」、「codex review」 |

## 快速安裝

```bash
git clone https://github.com/baffen227/claude-code-skills.git ~/Projects/claude-code-skills
cd ~/Projects/claude-code-skills
./setup.sh
```

`setup.sh` 會在 `~/.claude/skills/` 建立 symlink 指向此 repo 的各 skill 目錄。若已有同名目錄會自動備份為 `.bak`。

安裝後即可在任何專案中透過 Claude Code 觸發這些 skills。

## 前置需求

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)（CLI）
- [uv](https://docs.astral.sh/uv/)（`codex-reviewer` 的報告組裝腳本需要）
- [Codex CLI](https://github.com/openai/codex) v0.112.0+（僅 `codex-reviewer` 需要）

---

## Skill 詳細說明

### uv-python-setup

在任何倉庫中一鍵初始化 Python uv 開發環境。

**執行流程：**

1. **核心階段**（自動）：檢查/安裝 uv → 檢查/建立 `pyproject.toml` → 建立 `scripts/` `tests/` → 更新 CLAUDE.md
2. **可選階段**（互動）：詢問是否設定 ruff（linter/formatter）和 pre-commit hooks
3. **收尾階段**（自動）：`uv sync` → 顯示摘要

**檔案結構：**

```
uv-python-setup/
├── SKILL.md              # 核心指令與流程
└── references/
    └── ruff-config.md    # ruff 與 pre-commit 設定模板
```

---

### codex-reviewer

整合 [OpenAI Codex CLI](https://github.com/openai/codex) 對程式碼與文件進行獨立審查，產出結構化審查報告。

**分流邏輯：**

| 情境 | 使用的 Codex 子命令 |
|------|---------------------|
| 有 git 變更 | `codex review --uncommitted` 或 `codex review --base <branch>` |
| 審查特定文件 | `codex exec -s read-only` |
| 混合情境 | 依序執行兩者 |

**執行流程：**

1. 偵測審查範圍（code / doc / mixed）
2. 執行 codex review 和/或 codex exec（所有指令前綴 `timeout 120`）
3. 組裝結構化報告至 `docs/reviews/YYYY-MM-DD-<subject>.md`
4. 向使用者摘要呈現重點發現

**檔案結構：**

```
codex-reviewer/
├── SKILL.md                       # 核心指令（含安全護欄）
├── references/
│   ├── code-review-prompt.md      # 程式碼審查維度（供 Claude 理解）
│   ├── doc-review-prompt.md       # 文件審查維度與 prompt 模板
│   └── known-issues.md            # Codex CLI 已知問題與安全用法
└── scripts/
    └── run-codex-review.py        # 報告組裝腳本（PEP 723，uv run 直接執行）
```

**安全護欄：**

此 skill 內建多層安全防護，源自實作過程中的 OOM 事故經驗：

1. **timeout 包裝** — 所有 codex 指令前綴 `timeout 120`（120 秒上限）
2. **禁止 stdin pipe** — `codex review` 不支援 stdin 輸入，錯誤用法會觸發 fork bomb
3. **CLI 引數限制** — `--uncommitted`/`--base` 不能與自訂 `[PROMPT]` 同時使用
4. **零輸出監控** — 30 秒無輸出即視為異常終止

詳細的事故分析與 CLI 限制記錄在 [`codex-reviewer/references/known-issues.md`](./codex-reviewer/references/known-issues.md)。

---

## 設計文件

完整的設計決策與實施記錄保存在 [`docs/`](./docs/) 目錄：

| 文件 | 內容 |
|------|------|
| [uv-python-setup-design.md](./docs/uv-python-setup-design.md) | uv-python-setup 的設計規格與決策 |
| [codex-reviewer-design.md](./docs/codex-reviewer-design.md) | codex-reviewer 的設計規格、安全護欄與 CLI 限制 |
| [implementation-plan.md](./docs/implementation-plan.md) | 兩個 skills 的分步實施計畫與過程中的重要發現 |

## 新增 Skill

1. 在 repo 根目錄建立新的 skill 目錄（含 `SKILL.md`）
2. 在 `setup.sh` 的 `SKILLS` 陣列中加入新 skill 名稱
3. 重新執行 `./setup.sh`

## 授權

MIT
