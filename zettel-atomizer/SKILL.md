---
name: zettel-atomizer
description: 把 vault 內以單一主題 tag 標記的素材聚合成 batch,萃取成原子筆記 + 結構筆記草稿,落到 ~/Obsidian/Notes/inbox/ 等 HITL 核定。使用者打 /zettel-atomize <tag> 觸發。Phase A 第一個 batch 為 ebpf。
---

# zettel-atomizer

把 vault 內既有素材轉成兩類產出:

1. **原子筆記** — 每張一個概念、標題為陳述句、能精準 wikilink 引用
2. **結構筆記** — 把同主題的原子筆記織成索引/論述網絡

兩者皆走 HITL 草稿閘門,不直接寫永久筆記區。

完整設計脈絡見 `~/Projects/knowledge-os/docs/superpowers/specs/2026-05-02-zettel-atomizer-design.md`。

## 設計原則

1. **HITL 不可繞過** — AI 永遠只產草稿到 inbox,永遠不直接寫入永久筆記區
2. **主題聚合優先,不逐篇處理** — 第一步是用 tag 把同主題素材聚成 batch,再從全景視角原子化
3. **增量式、冪等** — 重跑時自動跳過已處理素材 (反查 source-notes)
4. **嚴格純概念粒度** — 步驟與程式碼範例留 References,不進原子 namespace。軟字數 ≤500 字
5. **與 distill 共用 inbox 與模板基礎**

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
~/.claude/skills/zettel-atomizer/scripts/reverse-source-notes.sh "$(obsidian vault info=path)" Notes/inbox Notes
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
