---
name: zettel-atomizer
description: 把 vault 內以單一主題 tag 標記的素材聚合成 batch,萃取成原子筆記 + 結構筆記,直落 ~/Obsidian/Notes/ 永久區 (frontmatter 帶 source: ai-assisted)。使用者打 /zettel-atomize <tag> 觸發。
---

# zettel-atomizer

把 vault 內既有素材轉成兩類產出:

1. **原子筆記** — 每張一個概念、標題為陳述句、能精準 wikilink 引用
2. **結構筆記** — 把同主題的原子筆記織成索引/論述網絡

兩者皆直落 `Notes/` 永久區,frontmatter 帶 `source: ai-assisted` 標記來源 (2026-08-08 Obsidian 重定位後,inbox 暫存與人工核定升級流程退役)。

完整設計脈絡見 `~/Projects/knowledge-os/docs/superpowers/specs/2026-05-02-zettel-atomizer-design.md` (歷史快照,落點為 inbox 的舊設計);重定位決策見 knowledge-os memory `obsidian-repositioning`。

## 設計原則

1. **來源透明** — 筆記 frontmatter 帶 `source: ai-assisted`,AI 產出與人工筆記可隨時區分;品質關卡是 Phase 4.5 思果校稿,不是人工核定
2. **主題聚合優先,不逐篇處理** — 第一步是用 tag 把同主題素材聚成 batch,再從全景視角原子化
3. **增量式、冪等** — 重跑時自動跳過已處理素材 (反查 source-notes)
4. **嚴格純概念粒度** — 步驟與程式碼範例留 References,不進原子 namespace。軟字數 ≤500 字
5. **與 distill 共用落點 (直寫 `Notes/`) 與模板基礎**

## 觸發

使用者打 `/zettel-atomize <tag>`,例如 `/zettel-atomize ebpf`。

## Phase 1: 聚合 + 載入上下文 (Auto-execute)

### 1.1 取得 batch 檔案清單

呼叫 `obsidian` CLI 列出該 tag 下所有筆記:

```bash
obsidian tag name=<tag> verbose
```

### 1.2 計算 source-whiteboard 覆蓋率

把 1.1 的輸出 pipe 給 aggregate script:

```bash
obsidian tag name=<tag> verbose | \
  ~/.claude/skills/zettel-atomizer/scripts/aggregate-source-whiteboard.sh "$(obsidian vault info=path)"
```

輸出 TSV 含每個 source-whiteboard 值的計數,最後一行 `TOTAL=N COVERED=M COVERAGE=P%`。

### 1.3 子分群決策

依 batch 大小 + 覆蓋率決定:

- **batch ≤ 100 張** → 不切,全 batch 處理
- **batch > 100 張 且 COVERAGE ≥ 80%** → 切法 C 一級 (依 source-whiteboard 切桶)
- **batch > 100 張 且 COVERAGE < 80%** → 提示使用者選分群維度,預設不切

特殊規則: tag = `rust` 額外觸發二級切分 (TRPL Part 1/2/3 章節再切一層)。

### 1.4 反查已處理素材 (idempotent)

呼叫 reverse script,得已處理的 source notes 集合:

```bash
~/.claude/skills/zettel-atomizer/scripts/reverse-source-notes.sh "$(obsidian vault info=path)" Notes
```

把這個集合從 1.1 的 batch 清單剔除,得「待處理 batch」。

### 1.5 偵測既有索引

```bash
~/.claude/skills/zettel-atomizer/scripts/detect-existing-index.sh "$(obsidian vault info=path)" "<tag>"
```

若有輸出,結構筆記草稿頭部加提示區段 (見 Phase 3)。

### 1.6 載入內容

對每張待處理筆記,用 `obsidian read path=<rel_path>` 讀全文進入 context。

## Phase 2: 概念萃取 + 去重 (LLM 主動執行)

### 2.1 從 batch 中識別原子概念

對每張待處理筆記,找符合下列條件的「原子概念」:

**該萃取**:

- 可獨立成立、能用陳述句當標題的概念 (例: 「BPF Maps 是 kernel-userspace 共享的 key-value 結構」)
- 邊界清晰,能精準 wikilink 引用
- 軟字數上限 ≤ 500 字 (中文計算),超過要自我判斷能否再拆

**該排除**:

- 步驟性內容 (例: 「下載、編譯、安裝 libbpf」) → 留為原 References
- 純程式碼範例 (例: 「chapter2/hello.bpf.c」) → 留為原 References
- 過大概念 (例: 「eBPF 完整生態」) → 強制再拆

### 2.2 去重比對

對每個候選概念,呼叫 `obsidian search` 找既有原子筆記:

```bash
obsidian search query="<候選概念標題或關鍵詞>" path="Notes" format=json
```

依比對結果分三檔信心 (預設閾值 80% / 50%):

- **>80% 信心 (高)**: 標題與內容皆高度雷同 → 直接跳過 (去重)
- **50-80% 信心 (中)**: 標題或部分內容雷同 → 標記「可能重複,建議合併」,草稿頭部加 `> 重複檢查信心: 中` + 列出可能重複的既有筆記路徑
- **<50% 信心 (低)**: 當成新概念,寫草稿

## Phase 3: 結構織網 (LLM 主動執行)

把 Phase 2 產出的原子筆記 (本 batch + vault 內既有同 tag 原子筆記) 組成結構筆記草稿。

### 3.1 結構決策

- **無子分群 (batch ≤ 100 張)**: 結構筆記用「主索引 + 概念群組」格式
- **有子分群 (切法 C)**: 結構筆記額外保留 source-whiteboard 維度標題作為分節

### 3.2 既有索引提示

若 Phase 1.5 偵測到既有索引,結構筆記草稿在 H1 標題下方插入:

```markdown
> ⚠️ vault 中已偵測到既有索引:
> - `Categories/<file1>.md`
> - `Categories/<file2>.md`
>
> 請選: (a) 永久化為獨立概念地圖 / (b) 內容併入既有索引後刪除草稿 / (c) 拒絕
```

### 3.3 套用模板

讀 `~/.claude/skills/zettel-atomizer/templates/structure-note.md`,填入 batch tag、子分群分節、跨子分群連結觀察。

## Phase 4: 寫入 Notes/ (Auto-execute)

寫入時**記下 `write-draft.sh` 回印的每個檔案路徑**,Phase 4.5 校稿與 Phase 5 回報都靠這份清單 (檔名已無日期前綴,不能再用日期 glob 撈)。

### 4.1 原子筆記批次寫入

對每張 Phase 2 產出的原子筆記:

```bash
~/.claude/skills/zettel-atomizer/scripts/write-draft.sh atomic "<陳述句標題>" <<'EOF'
<完整草稿正文>
EOF
```

### 4.2 結構筆記寫入

```bash
~/.claude/skills/zettel-atomizer/scripts/write-draft.sh structure "<batch_tag>" <<'EOF'
<結構筆記草稿>
EOF
```

## Phase 4.5: 校稿 (Auto-execute)

對 Phase 4 寫入的所有筆記跑 `classical-chinese-rules` skill 校稿。筆記直落永久區,沒有人工核定閘門攔翻譯腔,校稿是唯一的品質關卡 — 不能讓 AI 第一輪未經修飾的中文散文進 vault。

### 4.5.1 載入思果規則

用 Skill tool 呼叫 `classical-chinese-rules`，把思果《翻譯研究》14 條鐵律 + Output Style Section I 懶惰英文清單載入 context。

### 4.5.2 grep 快掃常見違規

對 Phase 4 記下的檔案路徑清單做幾類 grep (以下 `"${FILES[@]}"` 代表該清單):

```bash
grep -nE "(被[去剔丟換用判]|會被|被 [a-z])" "${FILES[@]}"
grep -nE "[^子][^即][^未][^就][^被] 將[^軍會棋來近所]" "${FILES[@]}"
grep -nE "(replaced on the stack|unusual 之|fall back|fallback|user-controlled|實際上|事實上)" "${FILES[@]}"
grep -nE "(進行[一二三常是]|做出|做為一)" "${FILES[@]}"
grep -nE "(首先|其次|最後|此外|另外|接著)" "${FILES[@]}"
```

清單對應思果鐵律:

- 被字句 (p.100-102) → 改主動或重述行為者
- 將字 (p.82-83) → 「即將」「會」「未來」替代
- 「實際上」「事實上」(填充語) → 刪除或改「其實」
- 機械並列 (首先/其次) → 散文節奏
- 名詞動詞化 (進行/做出) → 還原動詞

### 4.5.3 Read + Edit 修正

對 grep 命中的每張筆記 Read 全文，用 Edit 修。修完再跑一次 grep 確認三類違規 (被 / 將 / 主要懶惰英文) 全 0。

### 4.5.4 過關才進 4.6

校稿完成才能往下走。Phase 5 報告加一行: 「N 張筆記已過思果校稿，修正 M 處違規」。

### 4.6 重跑索引

```bash
python3 ~/Projects/knowledge-os/scripts/reindex_vault.py
```

失敗不擋回報，但 Phase 5 要註明「索引未更新，之後手動重跑」。

> 與 CLAUDE.md `自動校稿規則` 的關係: CLAUDE.md trigger #1 對 Write/Edit tool 觸發，但本 skill 用 `write-draft.sh` 透過 Bash tool 寫入，trigger 不會觸發。Phase 4.5 補這個漏洞。

## Phase 5: 回報使用者 (Auto-execute)

回覆四段:

1. **Batch 統計** — 待處理素材 N 張,產出原子筆記 M 張、結構筆記 1 張、跳過已處理 K 張
2. **去重統計** — 高信心去重 H 張、中信心標記可能重複 M 張、低信心新概念 L 張
3. **筆記路徑樣本** — 列前 3 張原子筆記路徑 + 結構筆記路徑
4. **反悔方式** — 筆記已直落永久區;不要的用 Obsidian CLI `obsidian delete` 刪 (進 trash 可復原)。歡迎抽查後回饋去重誤判 / 粒度問題,供下個 batch 校準

## 失敗模式

- **`~/Obsidian/` 不存在** → 中止,告知「vault 路徑不存在,無法寫入」
- **obsidian CLI 未裝或 sock 不通** → 中止,告知「請先確認 Obsidian app 已啟動 + CLI 已啟用」
- **batch 下無筆記** → 直接回報「tag <X> 下無筆記」並結束
- **Phase 1.6 載入內容超 context budget** → 提示使用者「batch 過大,建議分次處理」並列建議的子分群
- **write-draft.sh exit code 非 0** → 把 stderr 給使用者,不假裝成功

## 與既有機制的關係

| 機制 | 來源 | 範圍 | 介入程度 |
|---|---|---|---|
| `distill` Skill | Claude Code 對話 | 即時、單張原子洞見 | AI 直寫 + `source: ai-assisted` 標記,使用者事後抽查 |
| **`zettel-atomizer`** | **vault 內既有素材** | **批次、多張原子 + 結構** | **同上** |
| `vault-healthcheck` (規劃中) | vault 全域 | 健檢報告 | 唯讀,不寫筆記 |

## Phase B/C 預留

- **Phase B**: 跨 tag 聚合 (處理多 tag 主題交集) + 自動更新既有結構筆記 (diff 寫入)
- **Phase C**: 自動觸發 + 多格式輸出 (簡報、圖表)
