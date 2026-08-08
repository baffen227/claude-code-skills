# claude-code-skills

個人的 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 全域 Skills + Output Styles 合集。Skills 部署在 `~/.claude/skills/`，output styles 部署在 `~/.claude/output-styles/`，跨倉庫使用。

## Skills 一覽

| Skill | 用途 | 觸發方式 |
|-------|------|---------|
| [uv-python-setup](./uv-python-setup/) | 在任何倉庫初始化 Python uv 開發環境 | 「初始化 Python 環境」、「設定 uv」、「setup python」 |
| [classical-chinese-rules](./classical-chinese-rules/) | 依思果《翻譯研究》對繁體中文 prose 做深度潤稿，對抗歐化中文 | 「校稿」、「修稿」、「潤稿」、「中文潤稿」、「改得更像中文」、「歐化」、「思果」 |
| [distill](./distill/) | 從 Claude Code 對話萃取核心洞見，寫成 Steph Ango 筆記法的原子筆記直落 `Notes/` 永久區 | `/distill`、「distill 對話」、「把這段對話的洞見寫進 vault」 |
| [zettel-atomizer](./zettel-atomizer/) | 把 vault 內單一主題 tag 的素材聚合成 batch，萃取成原子筆記 + 結構筆記直落 `Notes/` 永久區 | `/zettel-atomize <tag>` |
| [rust-coding-standards](./rust-coding-standards/) | 審查或撰寫 BTBU 韌體 Rust 時載入完整的 clean-code / minimalism / modularity 紀律 | 「review Rust」、CLAUDE.md red-line 引用 clean-code / minimalism / modularity |
| [dual-review](./dual-review/) | 實作完成後的雙重品質審查：先 Agent B（Claude subagent）再 Codex 對抗審查 | `/dual-review`、程式碼改動後 |

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

### 2. `classical-chinese-rules` skill 的思果筆記（已收進 repo，無需額外準備）

此 skill 讀的思果《翻譯研究》讀書筆記收在 repo 內:

```
~/.claude/skills/classical-chinese-rules/references/翻譯研究筆記.md
```

跑完 `setup.sh` 就隨 skill symlink 一起到位，**不需要 Obsidian vault**。skill 觸發時直接讀這個 repo 內檔案，任何部署了 skills repo 的機器都能用。

vault 裡 `~/Obsidian/Clippings/Literature note of the book《翻譯研究》.md` 留一份封存原稿（筆記的來源），但 skill 不再讀它；若在 vault 改了內容，要手動同步回 `references/翻譯研究筆記.md`。

### 部署檢查清單 (新機器一次性)

```bash
# 1. Clone repo + 跑 setup.sh
git clone https://github.com/baffen227/claude-code-skills.git ~/Projects/claude-code-skills
cd ~/Projects/claude-code-skills && ./setup.sh

# 2. 複製全域 CLAUDE.md 模板
cp global-claude-md-template.md ~/.claude/CLAUDE.md

# 3. classical-chinese-rules 的思果筆記已隨 repo 附帶 (references/翻譯研究筆記.md)，無需另外準備 vault

# 4. 啟動新 Claude Code session
# 5. /config → Output style → Concise Traditional Chinese
# 6. 再開一個新 session — output style 才真正生效
```

## Plugins (第三方)

自訂 skill 之外，另外用官方 plugin 系統管理兩組第三方 skill，兩者並存不衝突:

| Plugin | 來源 | 用途 |
|--------|------|------|
| [openai/codex-plugin-cc](https://github.com/openai/codex) | Claude Code marketplace | `/codex:rescue`、`/codex:setup` 等 Codex 整合指令 |
| [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) | Claude Code marketplace | `obsidian:obsidian-cli`、`obsidian:obsidian-markdown` 等 Obsidian 檔案操作 skill |

安裝:

```bash
claude plugin marketplace add openai/codex-plugin-cc && claude plugin install codex@openai-codex
claude plugin marketplace add kepano/obsidian-skills && claude plugin install obsidian@obsidian-skills
```

第三方 skill 走 plugin 系統（`claude plugin update` 更新），本 repo 的自訂 skill 走 symlink（改完存檔即生效）。分流理由: plugin 適合不會去改的 upstream，symlink 適合自己開發中的 skill。

## 前置需求

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)（CLI）
- [Codex CLI](https://github.com/openai/codex)（`dual-review` 的 Codex 對抗審查階段需要）
- 個人 Obsidian vault（`distill` 與 `zettel-atomizer` 寫草稿到 vault 時需要；`classical-chinese-rules` 已不需 vault，思果筆記收在 repo 內）

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

### classical-chinese-rules

對繁體中文 prose 做深度潤稿，以[思果](https://zh.wikipedia.org/zh-tw/%E8%94%A1%E6%BF%AF%E5%A0%82)《翻譯研究》為 canonical reference，對抗 English-trained LLM 常產生的歐化中文 / 翻譯腔。

**兩層架構 (hot path + cold path)**

這個 skill 是 cold path，需要搭配 hot path 使用才完整:

| 層 | 位置 | 觸發 | 作用 |
|----|------|------|------|
| **Hot path** — Output Style | `~/.claude/output-styles/concise-tw.md` | 每 session 自動載入 system prompt (需先用 `/config` 啟用) | 14 條思果語法鐵律 + 8 類 anti-pattern (50+ 禁例)，always active，處理 80% 常見錯 |
| **Cold path** — 本 skill | `~/.claude/skills/classical-chinese-rules/` | 使用者說「校稿」「潤稿」「歐化」等關鍵字，或手動 `/classical-chinese-rules` | 載入完整的 `references/翻譯研究筆記.md` (464 行)，處理 hot path 之外的深度規則 (十條「的」字細則、代名詞使用、節奏平仄) |

**Single source of truth**: 思果筆記收在 repo 內 `references/翻譯研究筆記.md`，skill 直接讀它、隨 repo 跨機同步，不需 Obsidian vault。要擴充筆記就改這個檔再 commit，skill 下次觸發自動跟上。

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
- 思果讀書筆記已收進 repo (`references/翻譯研究筆記.md`)，跑完 `setup.sh` 即到位，不需 Obsidian vault

**檔案結構**

```
classical-chinese-rules/
├── SKILL.md                          # 指向 references/ 筆記的路由 + scope map + usage procedure
├── references/
│   └── 翻譯研究筆記.md               # 思果《翻譯研究》完整讀書筆記 (464 行) — SOT
└── output-styles/
    └── concise-tw.md                 # Hot path — 每 session 自動載入 system prompt
```

---

### distill

從 Claude Code 對話萃取核心知識洞見，寫成符合 Steph Ango 筆記法的原子筆記，直落 `~/Obsidian/Notes/` 永久區（frontmatter 帶 `source: ai-assisted` 標記來源）。閉合 Karpathy 說的「對話洞見蒸發」問題：把散在對話裡的高價值判斷回流進 vault。

**觸發**：`/distill`、要求「distill 對話」、或提到「把這段對話的洞見寫進 vault」「knowledge distillation」「Karpathy 蒸餾迴路」。

**現況**：手動觸發、單張原子洞見輸出。2026-08-08 Obsidian 重定位後直落永久區：品質關卡是寫入前的 classical-chinese-rules 校稿，inbox 暫存與人工核定升級流程退役。

**檔案結構**

```
distill/
├── SKILL.md                 # 萃取流程 + 落草稿規則
├── scripts/
│   └── write-draft.sh       # 寫筆記到 Notes/ 永久區
└── templates/
    └── distill-note.md      # 原子洞見模板
```

---

### zettel-atomizer

把 vault 內以單一主題 tag 標記的素材聚合成 batch，萃取成原子筆記 + 結構筆記，直落 `~/Obsidian/Notes/` 永久區（frontmatter 帶 `source: ai-assisted` 標記來源）。

**觸發**：`/zettel-atomize <tag>`。

**現況**：選 batch 的第一順位仍是「使用者能否抽查」——不熟的主題就算規模剛好也先擱著，因為沒人能判斷對錯的 batch 比沒跑更糟。2026-08-08 Obsidian 重定位後筆記直落永久區，品質關卡是寫入前的思果校稿（Phase 4.5），事後抽查取代逐張核定。

**檔案結構**

```
zettel-atomizer/
├── SKILL.md
├── scripts/                 # 聚合 / 反查來源 / 偵測既有 index / 寫草稿
├── templates/               # 原子筆記 + 結構筆記模板
└── tests/                   # bats 測試
```

---

### rust-coding-standards

審查或撰寫 BTBU 韌體 Rust（`nrg-prototype`、INT-004 / INT-005 / MCU Self Test、FMEA）時，載入一整套 Rust 品質紀律做深度把關。

**觸發**：「review Rust」、撰寫韌體 Rust，或 CLAUDE.md 的 red-line 引用 clean-code / minimalism / modularity 規則時。

**載入內容**：`clean-code.md`、`minimalism.md`、`modularity.md` 三份核心紀律，外加 dual-review 設計與 idiomatic-rust 計畫作補充。

**檔案結構**

```
rust-coding-standards/
├── SKILL.md
└── references/
    ├── clean-code.md
    ├── minimalism.md
    ├── modularity.md
    └── ...                  # dual-review 設計 + idiomatic-rust 計畫
```

---

### dual-review

實作完成後的雙重品質審查。先跑 Agent B（Claude subagent）審一輪，再跑 Codex 對抗審查，兩者都對照專案的 coding standards。

**觸發**：`/dual-review`，或程式碼改動後。開跑前會先問使用者確認。

**與其他 skill 的關係**：Codex 對抗審查階段需要 Codex CLI；審查依據是 `rust-coding-standards` 之類的專案紀律。

**檔案結構**

```
dual-review/
└── SKILL.md                 # 雙重審查流程 + 確認機制
```

---

## 設計文件

完整的設計決策與實施記錄保存在 [`docs/`](./docs/) 目錄，主要有:

| 文件 | 內容 |
|------|------|
| [uv-python-setup-design.md](./docs/uv-python-setup-design.md) | uv-python-setup 的設計規格與決策 |
| [implementation-plan.md](./docs/implementation-plan.md) | 早期 skills 的分步實施計畫與過程中的重要發現 |
| [2026-05-28-idiomatic-rust-plan-abstraction-design.md](./docs/2026-05-28-idiomatic-rust-plan-abstraction-design.md) | rust-coding-standards 的 idiomatic-rust 抽象化設計 |

## 新增 Skill

1. 在 repo 根目錄建立新的 skill 目錄（含 `SKILL.md`）
2. 在 `setup.sh` 的 `SKILLS` 陣列中加入新 skill 名稱
3. 重新執行 `./setup.sh`

## 授權

MIT
