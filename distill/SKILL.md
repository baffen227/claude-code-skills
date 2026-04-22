---
name: distill
description: 在 Claude Code 對話中萃取核心知識洞見，產出符合 Steph Ango 筆記法的 Obsidian 草稿至 ~/Obsidian/Notes/inbox/。使用者打 /distill、要求「distill 對話」、或提到「把這段對話的洞見寫進 vault」「knowledge distillation」「Karpathy 蒸餾迴路」時觸發。Phase A 僅支援手動觸發、單張原子洞見輸出。
---

# distill

把當前 Claude Code 對話的高價值洞見蒸餾成 Obsidian 草稿，符合 Steph Ango 筆記法，落到 `~/Obsidian/Notes/inbox/` 等使用者核定。

設計原則:

1. **HITL 不可繞過** — AI 只產草稿至 inbox，永不直接寫入永久筆記區
2. **單一原子洞見優先** — 預設輸出一張原子筆記，標題為陳述句
3. **不取代思考** — 草稿是「省去抄錄成本」，最終論述須使用者核定
4. **與 auto memory 區隔** — memory 記「我怎麼工作」(程序記憶)，distill 記「我學到什麼」(宣告知識)

完整設計脈絡見 `~/Projects/knowledge-os/docs/superpowers/specs/2026-04-20-distill-skill-design.md`。

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
- vault 內已有同主題筆記的重複內容 (Phase A 不做自動偵測，但若使用者明顯重述既有結論，標題前綴 `[可能重複]` 提示人工核定時合併)

**找不到任何洞見時**:

直接回覆「本次對話無顯著知識洞見可蒸餾」並結束。不浪費使用者時間生湊草稿。

## Phase 2: 生草稿 (Auto-execute)

**標題語言**: 跟隨對話主要語言。繁中為主時用繁中標題，英文為主時用英文標題。混語對話以散文正文語言為準。

**標題形式**: 一句陳述句，不用問句、不用標籤式短語。例:

- ✅ `Karpathy 知識蒸發迴路缺對話回流環節`
- ❌ `Karpathy distill 流程` (標籤式)
- ❌ `如何避免知識蒸發？` (問句)

**檔名**: `YYYY-MM-DD-<陳述句標題>.md`，標題保留空格、保留中文。`YYYY-MM-DD` 用今日日期 (台北時區)。

**正文**: 套用 `templates/distill-note.md` 模板，填入:

- `2-4 段核心論述` — 每段聚焦一個面向，不灌水
- `關鍵脈絡` — 為什麼值得記、在什麼情境下成立 / 不成立
- `相關連結` — 草擬的 wikilinks (AI 推測，明確標示「請核定後保留有效者」)

**Properties 必填欄位** (照模板):

- `created`、`session-date` — 用今日 ISO 8601 日期
- `model` — 當前 model ID (例: `claude-opus-4-7`)
- `source: ai-assisted`、`status: draft`、`tags: [inbox, distilled]` — 寫死，不變

## Phase 3: 寫檔 (Auto-execute)

呼叫 `scripts/write-draft.sh`，把草稿傳入 stdin:

```bash
~/Projects/claude-code-skills/distill/scripts/write-draft.sh "<陳述句標題>" <<'EOF'
<完整草稿正文>
EOF
```

腳本會:

1. 確保 `~/Obsidian/Notes/inbox/` 存在 (首次執行會建)
2. 組檔名 `YYYY-MM-DD-<陳述句標題>.md`
3. 寫入 stdin 內容
4. 回印最終檔案路徑

目前直寫檔案系統 (Phase A 備援)。Obsidian CLI 整合另案處理 — 啟用後 Skill 會優先呼叫 `obsidian` CLI，腳本內已預留切換點。

## Phase 4: 回報使用者 (Auto-execute)

寫檔成功後回覆三段:

1. **草稿路徑** — 完整絕對路徑
2. **預覽前 10 行** — 讓使用者一眼看到 frontmatter 與標題
3. **三個選項提示**:

   - **接受** — 草稿留在 inbox，週回顧時人工編輯後升永久筆記
   - **我來編輯** — 你自己改 (告知檔案路徑)
   - **刪除** — 直接刪掉，回覆刪除指令 `rm <path>`

不主動執行任何後續動作 — 採納 / 合併 / 拒絕都是使用者責任，HITL 閘門在這裡。

## 失敗模式

- **`~/Obsidian/` 不存在** — 中止，告知使用者「vault 路徑不存在，無法寫入」
- **inbox 已有同名檔案** — 在標題後加 `-2`、`-3` 流水號，不覆寫
- **腳本 exit code 非 0** — 把 stderr 給使用者，不假裝成功

## 與既有機制的關係

| 機制 | 記什麼 | 範圍 | 介入程度 |
|---|---|---|---|
| Claude Code auto memory | 工作偏好、慣例 | 單一專案 | 自動，背景 |
| `knowledge-os` CLAUDE.md | 環境、決策歷史 | 跨 session 共用大腦 | 人工編輯 |
| **`distill` Skill** | **知識洞見** | **流向 Obsidian vault** | **HITL：AI 草稿 + 人核定** |
| `zettel-atomizer` (規劃中) | 文獻原子化 | vault 內既有素材 → 永久筆記 | HITL |

## Phase B/C 預留

- **Phase B**: 自動觸發 (SessionStop hook) + 多洞見一次拆多張原子筆記
- **Phase C**: 跨 session 累積分析 (與 `vault-healthcheck` 整合，找反覆出現的模式)
- **Obsidian CLI 整合**: `write-draft.sh` 偵測 `obsidian` 在 PATH 後優先用 CLI，否則回到目前的直寫
