---
name: distill
description: 在 Claude Code 對話中萃取核心知識洞見，產出符合 Steph Ango 筆記法的原子筆記，直落 ~/Obsidian/Notes/ 永久區。使用者打 /distill、要求「distill 對話」、或提到「把這段對話的洞見寫進 vault」「knowledge distillation」「Karpathy 蒸餾迴路」時觸發。目前支援手動觸發、單張原子洞見輸出。
---

# distill

把當前 Claude Code 對話的高價值洞見蒸餾成原子筆記，符合 Steph Ango 筆記法，直落 `~/Obsidian/Notes/` 永久區。

設計原則:

1. **來源透明** — 筆記 frontmatter 帶 `source: ai-assisted`，AI 產出與人工筆記可隨時區分（2026-08-08 Obsidian 重定位後，inbox 暫存與人工核定升級流程退役，改直落永久區）
2. **單一原子洞見優先** — 預設輸出一張原子筆記，標題為陳述句
3. **校稿不可繞過** — 寫入前過 classical-chinese-rules 思果校稿（Phase 3.5），不讓翻譯腔進 vault
4. **與 auto memory 區隔** — memory 記「我怎麼工作」(程序記憶)，distill 記「我學到什麼」(宣告知識)

完整設計脈絡見 `~/Projects/knowledge-os/docs/superpowers/specs/2026-04-20-distill-skill-design.md`（歷史快照，落點為 inbox 的舊設計）；重定位決策見 knowledge-os memory `obsidian-repositioning`。

## 觸發

使用者打 `/distill`，或在對話中明確要求「把這段洞見寫成 Obsidian 筆記」「distill 一下」。

## Phase 1: 識別洞見 (Auto-execute)

掃描當前對話脈絡，找符合下列條件的內容:

**該收**:

- **架構決策** — 選了 A 而非 B，且記錄了理由與取捨
- **跨領域連結** — 把 X 領域的概念類比到 Y 領域
- **反直覺結論** — 挑戰原先假設的發現
- **可重複的模式** — 可命名的重複行為或設計模式
- **取捨表** — 比較表格中濃縮的權衡

**該忽略**:

- 純粹的 how-to (歸 memory 或 docs)
- 工具操作步驟 (歸 docs/guides)
- 任務追蹤 (歸 Notion 或 tasks.md)
- 純情緒回饋 (不算知識洞見)
- vault 內已有同主題筆記的重複內容 (先 grep `~/Obsidian/Notes/` 或查 `Notes/INDEX.md` 同主題組；高度雷同就不另開新檔，改建議使用者補寫進既有筆記)

**找不到任何洞見時**:

直接回覆「本次對話無顯著知識洞見可蒸餾」並結束。不浪費使用者時間生湊筆記。

## Phase 2: 生筆記 (Auto-execute)

**標題語言**: 跟隨對話主要語言。繁中為主時用繁中標題，英文為主時用英文標題。混語對話以散文正文語言為準。

**標題形式**: 一句陳述句，不用問句、不用標籤式短語。例:

- ✅ `Karpathy 知識蒸發迴路缺對話回流環節`
- ❌ `Karpathy distill 流程` (標籤式)
- ❌ `如何避免知識蒸發？` (問句)

**檔名**: `<陳述句標題>.md`，保留空格、保留中文，**不帶日期前綴** (created 日期在 frontmatter)。

**正文**: 套用 `templates/distill-note.md` 模板，填入:

- `2-4 段核心論述` — 每段聚焦一個面向，不灌水
- `關鍵脈絡` — 為什麼值得記、在什麼情境下成立 / 不成立
- `相關連結` — wikilinks (未解析連結是合法的未來筆記標記)

**Properties 必填欄位** (照模板):

- `created`、`session-date` — 用今日 ISO 8601 日期
- `model` — 當前 model ID (例: `claude-opus-4-7`)
- `source: ai-assisted`、`status: permanent` — 寫死，不變
- `tags` — 從 vault 既有主題 tag 挑 1 個最貼切的 (讀 `~/Obsidian/Notes/INDEX.md` 的組名清單當 taxonomy；不確定就挑最接近的，不發明新 tag)

## Phase 3: 寫檔 (Auto-execute)

呼叫 `scripts/write-draft.sh`，把筆記傳入 stdin:

```bash
~/Projects/claude-code-skills/distill/scripts/write-draft.sh "<陳述句標題>" <<'EOF'
<完整筆記正文>
EOF
```

腳本會:

1. 組檔名 `<陳述句標題>.md`，同名時加 `-2`、`-3` 流水號不覆寫
2. 寫入 stdin 內容到 `~/Obsidian/Notes/`
3. 回印最終檔案路徑

目前直寫檔案系統。Obsidian CLI 整合另案處理 — 啟用後 Skill 會優先呼叫 `obsidian` CLI，腳本內已預留切換點。新建檔案走檔案系統符合寫入紀律（改既有筆記才走 CLI）。

## Phase 3.5: 校稿 (Auto-execute)

寫檔後、回報前，對剛寫入的筆記跑 `classical-chinese-rules` skill 校稿。筆記直落永久區，沒有人工核定閘門攔翻譯腔，校稿是唯一的品質關卡:

1. 用 Skill tool 呼叫 `classical-chinese-rules` 載入思果規則
2. Read 剛寫入的檔案，對照 14 條鐵律 + 懶惰英文清單自審
3. 有違規就用 Edit 修正（被字 / 將字 / 曾經 / 名詞化 / 懶惰英文）
4. 修完才進 Phase 4

## Phase 4: 更新索引 + 回報 (Auto-execute)

1. **重跑索引**: `python3 ~/Projects/knowledge-os/scripts/reindex_vault.py`。失敗不擋回報，但要註明「索引未更新，之後手動重跑」
2. **回報使用者**兩段:
   - **筆記路徑** — 完整絕對路徑 + 預覽前 10 行 (frontmatter 與標題)
   - **反悔方式** — 筆記已在永久區；不要就用 Obsidian CLI `obsidian delete` 刪 (進 trash 可復原)，或自行編輯

## 失敗模式

- **`~/Obsidian/` 不存在** — 中止，告知使用者「vault 路徑不存在，無法寫入」
- **`Notes/` 已有同名檔案** — 腳本自動加 `-2`、`-3` 流水號，不覆寫；回報時提醒使用者確認是否撞了既有筆記
- **腳本 exit code 非 0** — 把 stderr 給使用者，不假裝成功

## 與既有機制的關係

| 機制 | 記什麼 | 範圍 | 介入程度 |
|---|---|---|---|
| Claude Code auto memory | 工作偏好、慣例 | 單一專案 | 自動，背景 |
| `knowledge-os` CLAUDE.md | 環境、決策歷史 | 跨 session 共用大腦 | 人工編輯 |
| **`distill` Skill** | **知識洞見** | **直落 Obsidian vault 永久區** | **AI 寫入 + `source: ai-assisted` 標記，使用者事後抽查** |
| `zettel-atomizer` | 文獻原子化 | vault 內既有素材 → 永久筆記 | 同上 |

## Phase B/C 預留

- **Phase B**: 自動觸發 (SessionStop hook) + 多洞見一次拆多張原子筆記
- **Phase C**: 跨 session 累積分析 (與 `vault-healthcheck` 整合，找反覆出現的模式)
- **Obsidian CLI 整合**: `write-draft.sh` 偵測 `obsidian` 在 PATH 後優先用 CLI，否則回到目前的直寫
