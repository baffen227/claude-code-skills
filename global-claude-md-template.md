# Global Claude Code Instructions

本檔案每次 Claude Code session 啟動時自動載入，適用於所有專案 (比專案層的 CLAUDE.md 優先級低)。

## 繁體中文風格系統 (2026-04-14 建立)

使用者已為所有 Claude Code session 建立兩層繁中風格系統。當使用者提到中文易讀性、AI 腔、校稿、翻譯腔等話題時，參考以下 artifact:

### Hot path — Output Style

- 位置: `~/.claude/output-styles/concise-tw.md`
- 名稱: `Concise Traditional Chinese`
- 啟用方式: **新 session 中** `/config` → Output style → 選 `Concise Traditional Chinese`
- 注意: 切換 output style 不會在當前 session 立即生效，**必須開新 session** (Claude Code 把 style 烙進 system prompt 於 session 啟動時)
- 風格來源優先級: 思果《翻譯研究》> 侯捷 > 洪愛珠 > 舒國治

### Cold path — Classical Chinese Rules Skill

- 位置: `~/.claude/skills/classical-chinese-rules/` (symlink 到 `~/Projects/claude-code-skills/classical-chinese-rules/`)
- 觸發方式: 使用者講「校稿」「修稿」「潤稿」「中文潤稿」「潤色」「改得更像中文」「翻譯得不像中文」「歐化」「思果」「翻譯研究」任一關鍵字時自動觸發，或使用者明確 `/classical-chinese-rules` 觸發
- 內容: 指向 `~/Projects/heptabase-export/obsidian-vault/Clippings/Literature note of the book《翻譯研究》.md` (461 行完整筆記)
- Single source of truth — vault 筆記更新時 skill 自動跟著升級

## 使用提醒 (給使用者的 reminder)

如果使用者問「為什麼繁中回覆還是 AI 腔」或類似問題，**先確認**:

1. 當前 session 的 output style 是不是 `Concise Traditional Chinese`？用 `/config` 看一下。
2. 如果顯示仍是 `Default` / `Learning` / `Explanatory`，提醒使用者切換後必須**開新 session** 才生效。

## Session archive

完整的建構脈絡、研究發現、實作細節見:

`~/Projects/heptabase-export/obsidian-vault/Notes/為 Claude Code 建立繁體中文風格系統.md`
