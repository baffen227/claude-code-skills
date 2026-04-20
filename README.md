# claude-code-skills

個人的 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 全域 Skills + Output Styles 合集。Skills 部署在 `~/.claude/skills/`，output styles 部署在 `~/.claude/output-styles/`，跨倉庫使用。

## Skills 一覽

| Skill | 用途 | 觸發方式 |
|-------|------|---------|
| [uv-python-setup](./uv-python-setup/) | 在任何倉庫初始化 Python uv 開發環境 | 「初始化 Python 環境」、「設定 uv」、「setup python」 |
| [codex-reviewer](./codex-reviewer/) | 整合 OpenAI Codex CLI 進行程式碼與文件審查 | 「幫我 review」、「請 Codex 檢查」、「codex review」 |
| [tea-gitea](./tea-gitea/) | BTBU Gitea 操作 (issues, comments, PRs) via tea CLI | 「update Gitea」、「post to issue」、「gitea comment」 |
| [classical-chinese-rules](./classical-chinese-rules/) | 依思果《翻譯研究》對繁體中文 prose 做深度潤稿，對抗歐化中文 | 「校稿」、「修稿」、「潤稿」、「中文潤稿」、「改得更像中文」、「歐化」、「思果」 |

## 快速安裝

```bash
git clone https://github.com/baffen227/claude-code-skills.git ~/Projects/claude-code-skills
cd ~/Projects/claude-code-skills
./setup.sh
```

`setup.sh` 會在 `~/.claude/skills/` 建立 symlink 指向此 repo 的各 skill 目錄，並在 `~/.claude/output-styles/` 建立 symlink 指向本 repo 管理的 output style 檔案。若已有同名目錄/檔案會自動備份為 `.bak`。

安裝後 skills 即可在任何專案中透過 Claude Code 觸發，output styles 則需要在新 session 中用 `/config` → Output style 手動選擇啟用。

## 跨機器部署備忘 (手動步驟)

`./setup.sh` **不會自動處理**下列兩件事。在新機器上首次部署或遷移時必須手動做，否則某些 skill 的功能會退化:

### 1. 全域 `~/.claude/CLAUDE.md`

本 repo 備有一份模板: [`global-claude-md-template.md`](./global-claude-md-template.md)。新機器上:

```bash
cp ~/Projects/claude-code-skills/global-claude-md-template.md ~/.claude/CLAUDE.md
# 視機器情境編輯 (例如不同機器的 vault 路徑、不同的全域偏好)
```

這個檔案的作用是讓每個 Claude Code session 在啟動時就知道此機器上啟用了什麼 skill/style 組合、有哪些使用提醒。沒有它 Claude 不會主動提醒你「為什麼繁中回覆還是 AI 腔」這類設定問題。

不納入 setup.sh 自動安裝的原因: 全域 CLAUDE.md 可能有機器特定的內容 (如硬體路徑、偏好的工具組合)，強制覆寫有風險。手動複製後再 HITL 編輯最安全。

### 2. `classical-chinese-rules` skill 的 Obsidian vault 筆記

此 skill 的 `SKILL.md` 寫死了一個絕對路徑:

```
~/Obsidian/Clippings/Literature note of the book《翻譯研究》.md
```

新機器上需要:

1. 在 `~/Obsidian/` 準備好 vault (透過 Obsidian Sync、Syncthing、或從 `heptabase-export` 匯出後搬至此路徑)
2. 確認該路徑下有《翻譯研究》讀書筆記
3. 若 vault 位置不同，手動編輯 `~/Projects/claude-code-skills/classical-chinese-rules/SKILL.md` 的路徑

沒做這步的後果: skill 會被觸發但 Read tool 會失敗，Claude 會 fallback 到 hot path (output style) 的 14 條規則，深度潤稿功能不可用。

### 部署檢查清單 (新機器一次性)

```bash
# 1. Clone repo + 跑 setup.sh
git clone https://github.com/baffen227/claude-code-skills.git ~/Projects/claude-code-skills
cd ~/Projects/claude-code-skills && ./setup.sh

# 2. 複製全域 CLAUDE.md 模板
cp global-claude-md-template.md ~/.claude/CLAUDE.md

# 3. 確認 Obsidian vault 可達 (僅 classical-chinese-rules 需要)
ls "$HOME/Obsidian/Clippings/Literature note of the book《翻譯研究》.md"
# 若不存在: 部署 vault 至 ~/Obsidian/ 或編輯 SKILL.md 的路徑

# 4. 啟動新 Claude Code session
# 5. /config → Output style → Concise Traditional Chinese
# 6. 再開一個新 session — output style 才真正生效
```

## Plugins (第三方)

| Plugin | 來源 | 用途 | 與自訂 skill 的關係 |
|--------|------|------|-------------------|
| [openai/codex-plugin-cc](https://github.com/openai/codex) | Claude Code marketplace | `/codex:rescue`, `/codex:setup` | 與 `codex-reviewer` 各自獨立，不衝突 |

安裝: `claude plugin marketplace add openai/codex-plugin-cc && claude plugin install codex@openai-codex`

## 前置需求

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)（CLI）
- [uv](https://docs.astral.sh/uv/)（`codex-reviewer` 的報告組裝腳本需要）
- [Codex CLI](https://github.com/openai/codex) v0.112.0+（僅 `codex-reviewer` 需要）
- [tea](https://about.gitea.com/products/tea/) v0.12.0+（僅 `tea-gitea` 需要）

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

### classical-chinese-rules

對繁體中文 prose 做深度潤稿，以[思果](https://zh.wikipedia.org/zh-tw/%E8%94%A1%E6%BF%AF%E5%A0%82)《翻譯研究》為 canonical reference，對抗 English-trained LLM 常產生的歐化中文 / 翻譯腔。

**兩層架構 (hot path + cold path)**

這個 skill 是 cold path，需要搭配 hot path 使用才完整:

| 層 | 位置 | 觸發 | 作用 |
|----|------|------|------|
| **Hot path** — Output Style | `~/.claude/output-styles/concise-tw.md` | 每 session 自動載入 system prompt (需先用 `/config` 啟用) | 14 條思果語法鐵律 + 8 類 anti-pattern (50+ 禁例)，always active，處理 80% 常見錯 |
| **Cold path** — 本 skill | `~/.claude/skills/classical-chinese-rules/` | 使用者說「校稿」「潤稿」「歐化」等關鍵字，或手動 `/classical-chinese-rules` | 載入完整的 `Literature note of the book《翻譯研究》.md` (461 行)，處理 hot path 之外的深度規則 (十條「的」字細則、代名詞使用、節奏平仄) |

**Single source of truth**: skill 內容不複製思果筆記，直接指向 Obsidian vault 的絕對路徑。使用者擴充 vault 筆記時，skill 自動跟著升級，不需改 `SKILL.md`。

**⚠️ 使用提醒**

1. **新 output style 必須開新 session 才生效**。切換 `Concise Traditional Chinese` output style 之後，Claude Code 在當前 session 仍是舊行為 — style 烙進 system prompt 於 session 啟動時，之後不會 hot-reload。`/config` 切換後要再開一個新 session。

2. **深度校稿用關鍵字觸發 skill**。Hot path 已經永遠生效處理常見錯，需要深度潤稿 (十條「的」字細則、代名詞使用、節奏平仄) 時才 invoke 本 skill。Auto-trigger 關鍵字: 校稿 / 修稿 / 潤稿 / 中文潤稿 / 潤色 / 改得更像中文 / 翻譯得不像中文 / 歐化 / 思果 / 翻譯研究。

**完整安裝 (hot path + cold path)**

```bash
# 1. 跑 setup.sh — 會同時 symlink skill 和 output style
./setup.sh

# 2. 啟動新的 Claude Code session
# 3. /config → Output style → 選 Concise Traditional Chinese
# 4. 再開一個新 session — output style 才真正生效
```

**⚠️ 新 output style 必須開新 session 才生效** — Claude Code 在 session 啟動時把 output style 烙進 system prompt，之後不會 hot-reload。`/config` 切換完後要再開一個 session 才會套用。

**前置需求**

- Claude Code (CLI)
- 個人的 Obsidian vault 裡有對應的思果讀書筆記。預設路徑 (在 `SKILL.md` 裡寫死): `~/Obsidian/Clippings/Literature note of the book《翻譯研究》.md`。若路徑不同需手動編輯 `SKILL.md`

**檔案結構**

```
classical-chinese-rules/
├── SKILL.md                          # 指向 vault 筆記的路由 + scope map + usage procedure
└── output-styles/
    └── concise-tw.md                 # Hot path — 每 session 自動載入 system prompt
```

---

### tea-gitea

透過 [tea CLI](https://about.gitea.com/products/tea/) 操作 BTBU Gitea server，編碼 `tea` v0.12.0 的 working patterns 與已知 quirks。

**主要 Recipes：**

| 操作 | 方式 |
|------|------|
| 發 comment | `tea api -X POST -F "body=@file"`（`tea comment` 不支援 `--body`） |
| 讀 issue body | `tea api GET` + JSON parse（`tea issues details` 不顯示 body） |
| 讀 comments | `tea api GET /issues/{N}/comments` + JSON parse |
| ZH/EN comment pair | 寫入 temp file → 分別 POST（Issue #1334 慣例） |

**已知 Quirks（tea v0.12.0）：**

1. `tea comment` 沒有 `--body` flag — 必須用 `tea api -F`
2. `tea api` 沒有 `--body` flag — 用 `-F "key=@file"` 讀檔
3. `tea issues details` 不顯示 issue body — 用 `tea api GET`

**檔案結構：**

```
tea-gitea/
└── SKILL.md    # Recipes + quick reference + quirks
```

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
