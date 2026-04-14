# CLAUDE.md — claude-code-skills

## What is this repo

個人的 Claude Code 全域 Skills + Output Styles 合集。Skills 部署在 `~/.claude/skills/`，output styles 部署在 `~/.claude/output-styles/`，跨倉庫使用。

## Skill 目錄結構慣例

每個 skill 遵循以下結構:
```
skill-name/
├── SKILL.md              # 核心指令 (Claude Code 讀取的主文件)
├── references/           # 提供給 Claude 的參考資料 (prompts, templates, known issues)
└── scripts/              # 輔助腳本 (optional)
```

- `SKILL.md` 是 Claude Code 的進入點，定義觸發條件、執行流程、安全護欄
- `references/` 內的檔案由 SKILL.md 引用，不直接被 Claude Code 載入
- `scripts/` 內的腳本由 SKILL.md 中的 Bash 指令呼叫

## 部署機制

`setup.sh` 管理兩類 symlink:

**Skills** — 在 `~/.claude/skills/` 建立 symlink 指向此 repo 的各 skill 目錄 (dir 層級):
```
~/.claude/skills/codex-reviewer → ~/Projects/claude-code-skills/codex-reviewer
~/.claude/skills/tea-gitea → ~/Projects/claude-code-skills/tea-gitea
~/.claude/skills/uv-python-setup → ~/Projects/claude-code-skills/uv-python-setup
~/.claude/skills/classical-chinese-rules → ~/Projects/claude-code-skills/classical-chinese-rules
```

**Output styles** — 在 `~/.claude/output-styles/` 建立 symlink 指向特定檔案 (file 層級):
```
~/.claude/output-styles/concise-tw.md → ~/Projects/claude-code-skills/classical-chinese-rules/output-styles/concise-tw.md
```

修改 skill 或 output style 檔案後不需要重新部署 — symlink 自動反映變更。新增 skill 後在 `setup.sh` 的 `SKILLS` 陣列加入名稱；新增 output style 後在 `OUTPUT_STYLES` 陣列加入 `<repo-relative-path>:<filename>` 格式，再重跑 `./setup.sh`。

## Skills 與 Output Styles 的分工

- **Skill**: 按需觸發的 task-specific prompt (使用者講關鍵字或 `/skill-name` 載入)。用來封裝可重用的 workflow 或 reference material (e.g., `classical-chinese-rules` 載入思果筆記做深度校稿)。
- **Output Style**: 每 session 一次、決定 Claude 預設 voice / tone / format 的 system prompt 改寫。用來建立跨所有工作的 baseline 風格 (e.g., `concise-tw.md` 讓繁中回覆一律簡潔)。
- **組合模式 (hot path + cold path)**: 常見模式 — output style 作 hot path (always active, 小成本, 處理大部分情況)，skill 作 cold path (on-demand, 大成本, 處理例外或深度情境)。`classical-chinese-rules` + `concise-tw` 是典型範例。

## 自訂 Skills vs OpenAI Codex Plugin

兩者各自獨立，不衝突:

| | 自訂 skills (此 repo) | OpenAI codex plugin |
|---|---|---|
| 位置 | `~/.claude/skills/` (symlink) | `~/.claude/plugins/cache/openai-codex/` |
| 管理 | 此 repo + `setup.sh` | `claude plugin install` |
| 範例 | `/codex-reviewer`, `/tea-gitea` | `/codex:rescue`, `/codex:setup` |

## 已知 Codex CLI Quirks

詳見 `codex-reviewer/references/known-issues.md`:
- `codex review` 不支援 stdin pipe (會觸發 fork bomb → OOM)
- `--uncommitted` / `--base` 不能與自訂 prompt 同時使用
- 所有 codex 指令須用 `timeout 120` 包裝

## Language

- 技術文件: 中英混合
- SKILL.md: English (Claude Code 消費)
- README.md: Traditional Chinese (人類閱讀)
