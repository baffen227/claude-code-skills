# 通用模板 Plan v0.7 → v1.0 抽象化 sweep — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按 abstraction design spec `docs/2026-05-28-idiomatic-rust-plan-abstraction-design.md` §8 落地動作清單 #1-#10,把 `rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md` v0.7 (659 行,原 nrg-prototype anchor) 抽象化升為 v1.0 通用模板 + illustrative example 雙層結構。

**Architecture:** 雙層結構 — 規格層 (normative,用 mapping doc §A 13 個 placeholder) + illustrative 層 (didactic,nrg-prototype lived example + PR α provenance,包 `> **Illustrative (nrg-prototype ...):** ...` callout framing)。163 列 anchor 落地依 mapping doc §A.1 已 frozen 的 4-class framework 分流處理 ((a) placeholder substitution / (b) illustrative carve-out / (c) N/A 抽象化 / (d) provenance 收入 callout)。§3.5.4 `<consensus-reviewer>` Phase 1 1B routing 用 3 維度分解 (reviewer 集合 / ack 媒介 / 拍板頻率) 重訂;Phase 3 啟動 gate 用 state-machine driven (anchor spec §3.5.1 衍生) 重訂;v0.8 9 條 plan 內條目 (A/D/F/G/H/I/J/K/L) 落 Task 2.1 sub-section (含新增 §testing 規範 / §審查流程 兩個 sub-section)。

**Tech Stack:** ripgrep + Edit tool + classical-chinese-rules skill + codex:rescue skill + git。

**不在本 plan scope:**

- adlink-can 端 follow-up (spec §8 動作 #11-#13:mapping doc §A.1 註記更新 / `<consensus-reviewer>` state landing / anchor spec frontmatter coupling SHA reference) — 由 adlink-can 端 maintainer 在本 v1.0 落地後同步,不擋本 plan 完成
- 通用模板新規格 round 7+ Codex adversarial review — v0.7 已 escalation out, v1.0 是 abstraction sweep 非新規格 (per spec §1.3);只跑 General Workflow 紅線要求的單輪 Codex review (Task 7)
- mapping doc §A.1 內容變更 — mapping doc 為 SOT 已 frozen,本 plan 只讀不寫

---

## General Workflow — 適用全部 doc-related task

依全域 `~/.claude/CLAUDE.md` 設計文件紅線 + 本 spec §10 Meta,**本 plan 改寫的 `rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md` 與本 plan / spec 自身 (`docs/2026-05-28-idiomatic-rust-plan-abstraction-*.md`) 整體 commit 前必須跑過**:

1. **Codex review** — 依 `codex:rescue` skill review v0.7 → v1.0 完整 diff,處理 critical / high 級 finding (Task 7)
2. **繁中校稿** — 觸發 `classical-chinese-rules` skill (寫入路徑符合 trigger #2:`.md` 檔散文正文主要為繁中),掃懶惰英文 / 翻譯腔 / 被字 / 將字 / 過度名詞化 (Task 8)

Task 1-6 是逐項改寫 v0.7 plan,**每完成一個 Task commit 一次** (頻繁 commit),但 Codex review / 繁中校稿留 Task 7 / 8 一次跑完整 diff (避免 6 次重複跑 review)。Push 留 Task 9 human-gated。

`<repo-root>` 在 Task command 內指 `~/Projects/claude-code-skills/`;Plan executor 在該目錄下執行所有 git / ripgrep / 檔案操作。

---

## Task 1: 在 v0.7 plan line 1 前插入 YAML frontmatter

**Files:**
- Modify: `rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md` (在 line 1 前插入)

per spec §7.1 規格。

- [ ] **Step 1: 讀 v0.7 plan line 1-3 確認當前無 frontmatter**

```bash
head -3 rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
```

Expected: 第 1 行為 `# Idiomatic Rust 最佳實踐計畫 (2026-04-18)`,第 2 行為空行,第 3 行為「**For agentic workers**」blockquote 開頭。**無** YAML frontmatter (line 1 不是 `---`)。

- [ ] **Step 2: 用 Edit 在 line 1 前插入 YAML block**

Edit tool:
- `old_string` = `# Idiomatic Rust 最佳實踐計畫 (2026-04-18)`
- `new_string` (下面 YAML block + 一行空行 + 原 H1 — 為求清楚,完整新內容如下):

```
---
audience: dual
version: v1.0
status: living-template
coupling:
  - target: adlink-can anchor design spec
    path: docs/superpowers/specs/2026-05-28-idiomatic-rust-anchor-design.md
    location: ~/Projects/fortune_btbu_github_repos/adlink-can/
    constraint: anchor spec ≥ 本 v1.0 (per anchor spec §6.3)
  - target: adlink-can idiomatic rust mapping doc
    path: docs/coding-standards/idiomatic-rust-mapping.md
    location: ~/Projects/fortune_btbu_github_repos/adlink-can/
    constraint: mapping doc §A 13 個 placeholder 命名必須對映本 v1.0 §A
---

# Idiomatic Rust 最佳實踐計畫 (2026-04-18)
```

> Edit tool 是 literal 替換,實際 `new_string` 內容為上面 fence 之間的完整文字。

- [ ] **Step 3: 驗證 frontmatter 寫入**

```bash
head -20 rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
```

Expected: 第 1 行為 `---`,第 2-14 行為 YAML block,第 15 行為 `---`,第 16 行空行,第 17 行為 `# Idiomatic Rust 最佳實踐計畫 (2026-04-18)`。

- [ ] **Step 4: Commit**

```bash
git add rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
git commit -m "docs(rust-coding-standards): add v1.0 frontmatter to idiomatic Rust plan (Task 1 of abstraction sweep)"
```

---

## Task 2: 跑 163 列 anchor systematic substitution

**Files:**
- Modify: `rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md` (全檔 systematic 改)

per spec §2.3 / §3。Anchor inventory 已 frozen 於 adlink-can mapping doc §A.1 (163 列,2026-05-28 commit `f61ff67`)。本 task **不重列** 163 列;executor 直接讀 mapping §A.1 對照處理。

Mapping doc 絕對路徑:`~/Projects/fortune_btbu_github_repos/adlink-can/docs/coding-standards/idiomatic-rust-mapping.md` (§A.1 inventory matrix 在該檔內)

依 4-class framework 分 3 個 sub-pass (sequential,避免同行多 anchor term 互相 overwrite):

| Sub-pass | Class | 處理 | 對應 spec §2.3 子段 |
|---|---|---|---|
| 2A | (a) Placeholder candidate | 直接 grep-and-replace 為 §A 13 個 placeholder | §2.3 (a) |
| 2B | (c) N/A | 依 spec §2.3 (c) 表 case-by-case 抽象化 | §2.3 (c) |
| 2C | (b) + (d) Local example + retained provenance | 段落級重寫:包 `> **Illustrative (nrg-prototype ...):** ...` callout framing | §2.3 (b) / (d) |

- [ ] **Step 1: 跑 ripgrep 取 anchor term hit baseline**

在 `<repo-root>` 跑:

```bash
rg -n -E 'she_j1939|she_bms_masterboard|nrg-prototype|Vincent|Eden|Harry|Gitea|ti_001_can_comm|crates/lib|crates/bin|29117d7b|353e24ae|ef363dba|PR α|PR β|J1939Id::from_raw|pgn::adlink::protocol|cortex-m|embassy-stm32|critical-section|hse_8mhz|tasks\.md|int_004|INT-004|ExtendedId::new_unchecked|frame::tests|frame\.rs|hse_8mhz' \
  rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md > /tmp/v07-anchor-hits.txt

wc -l /tmp/v07-anchor-hits.txt
```

Expected: hit list 大致對應 mapping §A.1 163 列 (實際 line 數比 163 少,因為一行多 anchor term 在 ripgrep 算一行)。預估 100-130 行 hits。記錄實際數值作為 Step 6 對照 baseline。

- [ ] **Step 2: 讀 mapping doc §A.1 把每 hit 對映到 row**

```bash
sed -n '/§A\.1/,/§B/p' ~/Projects/fortune_btbu_github_repos/adlink-can/docs/coding-standards/idiomatic-rust-mapping.md > /tmp/mapping-A1.txt
wc -l /tmp/mapping-A1.txt
```

Expected: §A.1 段約 175 行 (含 heading + framework + 163 列 inventory + §B 起始)。Executor 開 `/tmp/v07-anchor-hits.txt` 與 `/tmp/mapping-A1.txt` side-by-side 對照,確認每 hit 對應到 §A.1 哪 row 的 class。

**若 hit 對不到 §A.1 row**: 表示 v0.7 plan 在 mapping §A.1 frozen 後 (2026-05-28) 有改動;先 audit 該 hit 屬哪 class (4-class framework 在 mapping §A 段內),再決定 sub-pass 處理。Audit 結果記在本 Step 註記,Task 9 changelog 提及。

- [ ] **Step 3: Sub-pass 2A — (a) Class placeholder substitution**

對 mapping §A.1 標 (a) 的 row,依該 row 「處理」欄指示用 Edit 跑 substitution。範例 (mapping §A.1 row 6,v0.7 line 7 `she_j1939` → `<library-crate>`):

Edit tool:
- `old_string` = `**目標**: 透過 Claude Code 達成 Rust 社群公認的最嚴格 Idiomatic Rust 實踐,覆蓋 library crate (`she_j1939`) 與 embedded binary crate (`she_bms_masterboard`) 兩側。`
- `new_string` = `**目標**: 透過 Claude Code 達成 Rust 社群公認的最嚴格 Idiomatic Rust 實踐,覆蓋 library crate (`<library-crate>`) 與 embedded binary crate (`<binary-crate>`) 兩側。`

Per mapping §A.1 13 個 placeholder 對映:

| Placeholder (per mapping §A) | (a) Class 對映原 anchor term |
|---|---|
| `<library-crate>` | `she_j1939` |
| `<binary-crate>` | `she_bms_masterboard` |
| `<workspace-pub-crates>` | (mapping §A.1 無此 row,Task 2A 不處理;通用模板若需用此 placeholder 由 v0.8 9 條落地時引入) |
| `<library-crate-paths>` | `crates/lib/she_j1939/` / `crates/lib/she_j1939/src/...` 等 path 形式 |
| `<binary-crate-paths>` | `crates/bin/she_bms_masterboard/` / `crates/bin/she_bms_masterboard/src/...` 等 path 形式 |
| `<unsafe-targeted-test>` | `crates/lib/she_j1939/src/frame.rs:44` / `frame.rs:44` 縮寫 (when 用作 host-testable unsafe target reference) |
| `<unsafe-binary-side>` | `crates/bin/she_bms_masterboard/src/heap_allocation.rs:25` / `spawner.rs:32-39` 五處 |
| `<consensus-reviewer>` | (Task 5 改寫 Task 1.3 / 1.4 處理,Task 2A 不動) |
| `<sync-reviewer>` | `Harry` (作 reviewer / 拍板者 / 計畫把關等 context) |
| `<detailed-reviewer-profile>` | (PR α detailed-review profile 引用 context,Task 2C 含入 illustrative callout 時處理) |
| `<ci-platform>` | (mapping §A.1 無直接 (a) row;Gitea CI / GitHub Actions 走 (c) Class) |
| `<vc-ref-mechanism>` | (mapping §A.1 內 Gitea 走 (c) Class) |
| `<release-branch>` | (mapping §A.1 無直接 (a) row;若 plan 內出現 `main` / `master` 等 hard-coded branch ref,屬 (a) substitution) |

對 §A.1 標 (a) 的每 row 重複 Edit 操作。實際操作數預估 80-90 次 Edit (一 row 一 Edit;同行多 term 拆多次 Edit)。

**Note** (per spec §3.2):同一行多 anchor term 場景 (如 v0.7 line 80 含 `crates/lib/she_j1939/src/frame.rs:44` + `she_j1939` + `ExtendedId::new_unchecked` — §A.1 row 24 / 25 / 26 不同 class):
- row 24 (a) → `<library-crate-paths>` + `<unsafe-targeted-test>`
- row 25 (a) → `<library-crate>`
- row 26 (b) → 留 Task 2C 包入 illustrative callout

逐 term 處理,不一次性 replace 整行。

- [ ] **Step 4: Sub-pass 2A 完成後 acceptance check**

```bash
rg -n -E 'she_j1939|she_bms_masterboard|crates/lib/she_j1939|crates/bin/she_bms_masterboard|Harry' \
  rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
```

Expected: 剩餘 hits **只**屬 (b) Class 的「helper context」(例如 `ExtendedId::new_unchecked` 用 `she_j1939` 模組 context;或 `J1939Id::from_raw` 帶 `pgn::adlink::protocol` module path)。**完全沒有獨立 (a) Class hit 留下**。若仍有 (a) hit 未替換,回 Step 3 補。

- [ ] **Step 5: Sub-pass 2B — (c) Class N/A 抽象化**

對 mapping §A.1 標 (c) 的 row,依 spec §2.3 (c) 表 case-by-case 改寫:

| v0.7 reference | v1.0 處理 |
|---|---|
| `Gitea` / `Gitea issue` / `Gitea comment` / `Gitea CI` | → `<vc-ref-mechanism>` |
| `Vincent` (作 reviewer / 拍板對象) | → `<consensus-reviewer>` (1B 拍板情境) 或 `<detailed-reviewer-profile>` (PR α detailed-review profile 引用) |
| `Eden` (作 reviewer) | → `<consensus-reviewer>` |
| `nrg-prototype` (作 repo 名) | → repo-neutral prose (例「the Rust workspace」/「current codebase」/「本專案」) |
| `tasks.md` (作 work tracking) | → 通用 prose (例「project work tracking system」/「ticket queue」/「工作追蹤系統」) |
| `int_004` / `INT-004` | → 刪除整段或整句 (屬已停 work item,通用模板不引用) |
| `crates/lib/` (作通用 path pattern) | → `<library-crate-paths>` |
| `crates/bin/` (作通用 path pattern) | → `<binary-crate-paths>` |

**遷移備註 (2026-05-13)** 段 (v0.7 line 5,Gitea → GitHub 遷移歷史記錄):整段刪除,改為一行通用 placeholder doc 引導:

Edit tool:
- `old_string` = `> **遷移備註 (2026-05-13)**: 本檔下文「Gitea issue 追蹤」「Gitea comment 拍板」「Gitea CI」等流程引用,從 2026-05-13 起改在 GitHub `github.com/fortuneBTBU/nrg-prototype` 走 (`gh` CLI / Issue / PR review)。舊 Gitea repo retired,留檔供歷史參考。Phase 1/2 落地時對應的 enforcement 媒介改為 GitHub Actions / `gh` 通知,實質內容 (lints / api-maturity tag / `cargo deny` 共識) 不變。`
- `new_string` = `> **VC / CI 媒介**: 本檔下文出現的 `<vc-ref-mechanism>` (PR review / Issue / comment ack 等媒介) 與 `<ci-platform>` (CI 執行媒介) 由 individual project 在 mapping doc §B 填具體值 (例 Gitea + Gitea CI / GitHub + GitHub Actions / GitLab + GitLab CI 等)。本通用模板不指定具體工具。`

對其餘 (c) Class row 逐 row Edit。實際操作數預估 30-40 次 Edit。

- [ ] **Step 6: Sub-pass 2B 完成後 acceptance check**

```bash
rg -n -E 'Gitea|Vincent|Eden|nrg-prototype|tasks\.md|int_004|INT-004' \
  rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
```

Expected: 剩餘 hits **只**屬 (d) Class 的 retained provenance (例如 `PR α merge 後` 的 PR α historical reference 仍提及 `nrg-prototype`),且該 hits 將在 Sub-pass 2C 包入 illustrative callout。**完全沒有獨立 (c) Class hit 留下** (Gitea / Vincent / Eden / int_004 / INT-004 應為 0 hits,因為這些 4 個 term 沒有歷史 provenance value)。`nrg-prototype` / `tasks.md` 若仍有 hit,確認皆為 (d) Class context 後留給 Sub-pass 2C。

- [ ] **Step 7: Sub-pass 2C — (b) + (d) Class illustrative callout framing**

對 mapping §A.1 標 (b) 或 (d) 的 row,段落級重寫包 callout framing。範例 (v0.7 line 91 「PR α (HEAD `29117d7b`...)」相關段):

Edit tool:
- `old_string` (v0.7 line 89-91 原段落):

```markdown
### 正在進行的 PR

PR α (HEAD `29117d7b`,10 commits,未 push) 是第一個會經過新 pipeline 的 PR。本計畫不阻擋 PR α push,但 Phase 2 會把 PR α 當試跑樣本回頭補 audit。
```

- `new_string` (改寫為通用 prose + illustrative callout):

```markdown
### 第一個試跑 PR (concept)

通用模板的 Phase 1 落地後,個別專案的第一個進入新 pipeline 的 PR 可作為 Phase 2 試跑樣本回頭補 audit (不阻擋 push)。

> **Illustrative (nrg-prototype PR α `29117d7b`)**: PR α (HEAD `29117d7b`,10 commits,未 push) 是 nrg-prototype 第一個經過新 pipeline 的 PR;Task 2.6 audit 對 PR α `she_j1939::pgn::adlink::protocol` 新 module + `J1939Id::from_raw` / `to_raw` 跑 checklist 試跑。此例為 didactic reference,非通用模板規格。
```

對 (b) Class row (`J1939Id::from_raw` / `ExtendedId::new_unchecked` / `ti_001_can_comm::wait_with_demux` / `cortex-m` / `critical-section` / `hse_8mhz` / `frame::tests::new_extended_with_max_id_constructs_ok` / `frame::tests::new_extended_with_boundary_ids_round_trip` / `pgn::adlink::protocol` 等) 與 (d) Class row (`PR α` / `29117d7b` / `353e24ae` / `ef363dba` / `PR β`),段落級重寫:
- 把原段落內具體 API 名稱抽離到 illustrative callout 內
- 主段落改寫成 normative 描述 (placeholder + 規則)
- Callout 末標「此例為 didactic reference,非通用模板規格」

**特殊處理 PR β**:
- mapping §A.1 row 104 / 129 標 (a),原註記「待抽象化 spec 新增 `<phase3-gate-pr>` placeholder」。本 v1.0 採 state-machine driven gate (per spec §5),**不**新增 placeholder。PR β 兩處 (v0.7 line 346 / 464) 在 Task 4 (Phase 3 gate 改寫) 處理,不在 Sub-pass 2C scope。Task 2C executor 跳過 PR β,留 Task 4 處理。

實際操作數預估 40-50 次 Edit (一 (b)/(d) row 一段落重寫;同段落多 (b)/(d) row 合併一次 Edit)。

- [ ] **Step 8: Sub-pass 2C 完成後 acceptance check**

```bash
rg -n -E 'she_j1939|she_bms_masterboard|nrg-prototype|Vincent|Eden|Harry|Gitea|ti_001_can_comm|29117d7b|353e24ae|ef363dba|PR α|J1939Id::from_raw|pgn::adlink::protocol|cortex-m|critical-section|hse_8mhz|tasks\.md|int_004|INT-004|ExtendedId::new_unchecked|frame::tests|frame\.rs' \
  rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md | rg -v '^[^:]+:[0-9]+:\s*>' | head -20
```

第二個 `rg -v '^[^:]+:[0-9]+:\s*>'` 排除 blockquote (`>` 開頭) 內的 hits。

Expected: 第二個 `rg` 後輸出**為空** (per spec §3.3 Acceptance #1) — 所有 anchor terms 只出現在 illustrative callout (blockquote) 內,normative 段全乾淨。

若有 hit 留下,回 Sub-pass 2A / 2B / 2C 補。

- [ ] **Step 9: spec §3.3 Acceptance #2 — placeholder 涵蓋驗證**

```bash
for p in '<library-crate>' '<binary-crate>' '<library-crate-paths>' '<binary-crate-paths>' '<unsafe-targeted-test>' '<unsafe-binary-side>' '<sync-reviewer>' '<vc-ref-mechanism>'; do
  count=$(rg -c "$p" rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md || echo 0)
  echo "$p: $count hits"
done
```

Expected: 上述 8 個 placeholder 每個 hits ≥ 1。其餘 5 個 placeholder (`<workspace-pub-crates>` / `<consensus-reviewer>` / `<detailed-reviewer-profile>` / `<ci-platform>` / `<release-branch>`) 由 Task 5 / 7 (`<consensus-reviewer>`) / 後續 v0.8 落地 (`<workspace-pub-crates>` / `<detailed-reviewer-profile>`) / 通用 prose (`<ci-platform>` / `<release-branch>` 可選) 處理,Task 2 不要求覆蓋。

- [ ] **Step 10: Commit**

```bash
git add rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
git commit -m "docs(rust-coding-standards): run 163-row anchor systematic substitution (Task 2 of abstraction sweep, per spec §2.3 / §3)"
```

---

## Task 3: 改寫 Task 1.3 / 1.4 Acceptance (per spec §4)

**Files:**
- Modify: `rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md` (Task 1.3 / 1.4 段,原 v0.7 line 241-249)

per spec §4.4。

- [ ] **Step 1: 讀 Task 1.3 / 1.4 段確認當前 Acceptance**

```bash
sed -n '/\*\*Task 1\.3\*\*/,/\*\*Task 1\.4\*\*/p' rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
```

Expected: Task 1.3 段 Acceptance 第 1 條為「Harry + Vincent 至少一方在 Gitea comment 留下拍板...」之類 (Task 2 substitution 後 `Harry` → `<sync-reviewer>`、`Vincent` → `<consensus-reviewer>`、`Gitea comment` → `<vc-ref-mechanism>`)。

- [ ] **Step 2: 用 Edit 改寫 Task 1.3 Acceptance**

Edit tool 替換 Task 1.3 整段 Acceptance bullet (基於 Task 2 substitution 後的版本,具體 `old_string` executor 依當下實際內容抓)。新版 Acceptance 內容:

```markdown
- [ ] **Task 1.3**: 評估 `cargo audit` 從月度升為 PR 級。執行成本約 5 秒;個別專案 embedded 相依套件多寡與 CVE 風險面由 mapping doc §B `<workspace-pub-crates>` / `<binary-crate>` 列出的具體 crate 集合決定。
  - **Acceptance**:
    1. `<consensus-reviewer>` 在 `<vc-ref-mechanism>` 留下拍板 (PR 級 / 月度) 並標示理由
    2. project `CLAUDE.md` Rust verification checklist 對應段落更新,引用該拍板 URL / SHA
    3. 若升 PR 級,`<library-crate>` 與 `<binary-crate>` 對應的 quality-check script 涵蓋該 step
  - **§1B reviewer routing** (per v1.0 §3.5.4):`<consensus-reviewer>` 拆 3 維度由 individual project 在 mapping doc §B 填:
    - Reviewer 集合: solo / pair / committee (預設 solo)
    - Ack 媒介: `<vc-ref-mechanism>` PR comment / commit message footer / issue ack / async written doc / dated meeting note (預設 any immutable written ack)
    - 拍板頻率: per-PR / per-release / monthly (預設 per-PR)
    - 預設策略適用條件:single-maintainer / single-developer codebase + CI / CVE feed 已自動化 + 拍板頻率 per-PR 不會卡住 developer feedback loop。不符合時 project 必 override。

  > **Illustrative (nrg-prototype PR α 期間)**: `<consensus-reviewer>` 預期填 Vincent + Harry,`<vc-ref-mechanism>` 預期填 Gitea comment (後遷移 GitHub PR review)。此例為 didactic reference,非通用模板規格。
```

- [ ] **Step 3: 用 Edit 改寫 Task 1.4 Acceptance**

Edit tool 替換 Task 1.4 整段 Acceptance bullet。新版:

```markdown
- [ ] **Task 1.4**: 評估 `cargo deny check` (workspace 層,license / duplicate / banned deps)。需跟 `<consensus-reviewer>` 共識。
  - **Acceptance**:
    1. `<consensus-reviewer>` 合入 project `Cargo.toml` 的 `[workspace.metadata.deny]` 段落,或在 `<vc-ref-mechanism>` 留下明確同意 / 拒絕 ack
    2. 頻率決策 (PR 級 / 月度) 寫進 project `CLAUDE.md`,引用拍板 ack URL / SHA
    3. **§1B reviewer routing** 同 Task 1.3 (per v1.0 §3.5.4,3 維度 + 預設策略)

  > **Illustrative (nrg-prototype PR α 期間)**: `<consensus-reviewer>` 預期填 Vincent,合入 `nrg-prototype/Cargo.toml` 由 Vincent 主導。此例為 didactic reference,非通用模板規格。
```

- [ ] **Step 4: 驗證 Task 1.3 / 1.4 改寫成功**

```bash
sed -n '/\*\*Task 1\.3\*\*/,/\*\*Task 1\.5\*\*/p' rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md | head -40
```

Expected: 兩段 Acceptance 都含「§1B reviewer routing」section 與 3 維度說明,且帶 illustrative callout (blockquote)。

- [ ] **Step 5: Commit**

```bash
git add rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
git commit -m "docs(rust-coding-standards): rewrite Task 1.3 / 1.4 acceptance with §1B reviewer routing (Task 3 of abstraction sweep, per spec §4)"
```

---

## Task 4: 改寫 Phase 3 開頭啟動 gate + Acceptance (per spec §5)

**Files:**
- Modify: `rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md` (Phase 3 段開頭,原 v0.7 line 344-353;以及 PR β references in line 346 / 464)

per spec §5.2 + §5.3。

- [ ] **Step 1: 讀 Phase 3 段開頭確認當前內容**

```bash
sed -n '/^### Phase 3/,/^- \[ \] \*\*Task 3\.1\*\*/p' rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
```

Expected: 看到 Phase 3 heading + Target 段 + v0.3 邊界重劃段 + Task 3.1 heading。其中 Target 段或 line 346 含「PR β 前完成 Phase 3」之類字樣 (Task 2 substitution 後可能 PR β 仍未替換,因為標 (a) 但 spec §5.3 留 Task 4 處理)。

- [ ] **Step 2: 用 Edit 改寫 Phase 3 開頭加入啟動 gate**

Edit tool 在 Phase 3 heading 之後 (Target 段之前或之內) 加入啟動 gate section。新內容:

```markdown
### Phase 3 — Unsafe / concurrency verification

**啟動 gate** (per v1.0 §5, state-machine driven, derived from anchor spec §3.5.1 — `<unsafe-targeted-test>` / `<unsafe-binary-side>` state machine `TBD` / `N/A-no-current-target` / `landed`):

| `<unsafe-targeted-test>` state | `<unsafe-binary-side>` state | Phase 3 狀態 |
|---|---|---|
| `TBD` | `TBD` | block (待 codebase audit 清 unsafe 分佈) |
| `landed` | * | **啟動** |
| * | `landed` | **啟動** |
| `N/A-no-current-target` | `N/A-no-current-target` | **skipped (N/A per audit YYYY-MM-DD)**,跳 Phase 4 |

**Phase 3 啟動 gate Acceptance**:
1. Phase 3 啟動時 mapping doc §B 上 `<unsafe-targeted-test>` 或 `<unsafe-binary-side>` 任一 state ≠ `TBD`
2. 若 Phase 3 標 `skipped (N/A per audit YYYY-MM-DD)`,mapping doc §B 兩 placeholder state 必皆 `N/A-no-current-target`,且 audit commit reference 已寫入 §B「Source / 驗證」欄
3. 啟動或 skip 決策必在 mapping doc §D Sync log 留一列 (per anchor spec §3.5.3 pre-v1.0 provisional / post-v1.0 three-way 兩階段規則)

Target: pipeline 第 5 步的完整建置。本通用模板因應 embedded + no_std 場景,不能照搬 std 專案慣例。
```

(原 Target 段「本專案因為 embedded + no_std」字樣改為「本通用模板因應 embedded + no_std 場景」)

- [ ] **Step 3: 處理 PR β 兩處 references (v0.7 line 346 / 464)**

v0.7 line 346 原文「Target: pipeline 第 5 步的完整建置。本專案因為 embedded + no_std,不能照搬 std 專案慣例。」附近的 PR β reference (per mapping §A.1 row 104):

```bash
rg -n 'PR β|PR beta' rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
```

Expected: 找到 2-3 處 PR β 引用 (v0.7 line 346 / 464 與相關段落)。

對每處 Edit:
- 若該處是「Phase 3 啟動 gate」context (例 line 346「### Phase 3 — Unsafe / concurrency verification (PR β 前)」段 heading) → 改寫為 state-machine gate (per spec §5.1),把 `(PR β 前)` 從 heading 刪除 (Step 2 已重新加入 Phase 3 heading 與啟動 gate,確認新 heading 不含 `(PR β 前)`)
- 若該處是 v0.7 line 464「Phase β 之前完成 Phase 3」之類 prose → 改寫為「Phase 3 啟動 / skip 決策由 mapping doc §B `<unsafe-*>` placeholder state 驅動 (per v1.0 §5)」+ illustrative callout 保留 PR β 為 nrg-prototype 歷史 context

Example (v0.7 line 462-464 「實施時機與專案關係」段):

Edit tool:
- `old_string`:
```markdown
- **不阻 PR α push**: PR α (HEAD `29117d7b`) 照原計畫 push,本計畫不插隊
- **PR α 當 Phase 2 試跑樣本**: Task 2.6 自用試跑拿 PR α 回頭補 audit,不擋 merge (試跑結果寫 `PR_ALPHA_API_GUIDELINES_AUDIT.md`)
- **PR β 之前完成 Phase 3**: PR β 會動更多 `crates/bin/she_bms_masterboard` 硬體層 code,unsafe / concurrency verification 要先做完
- **Phase 4 持續**: 不設期限,每月 checkpoint
```

- `new_string`:
```markdown
- **不阻第一個試跑 PR push**: individual project 的第一個進入新 pipeline 的 PR 照原計畫 push,本計畫不插隊
- **第一個試跑 PR 當 Phase 2 試跑樣本**: Task 2.6 自用試跑拿該 PR 回頭補 audit,不擋 merge (試跑結果歸檔)
- **Phase 3 啟動 / skip 由 state machine 驅動** (per v1.0 §5): mapping doc §B `<unsafe-targeted-test>` 或 `<unsafe-binary-side>` 任一從 `TBD` → `landed` 啟動 Phase 3;兩者皆 `N/A-no-current-target` 標 skipped 跳 Phase 4
- **Phase 4 持續**: 不設期限,每月 checkpoint

> **Illustrative (nrg-prototype PR α / PR β)**: nrg-prototype 對應 — PR α `29117d7b` 是第一個試跑 PR,Task 2.6 audit 對其跑 checklist;PR β 是預期會動更多 `crates/bin/she_bms_masterboard` 硬體層 code 的 follow-up PR,在 nrg-prototype 流程內作為 Phase 3 完成 milestone。此例為 didactic reference,非通用模板規格 (v1.0 改用 state-machine driven gate)。
```

- [ ] **Step 4: 驗證 PR β references 處理完**

```bash
rg -n 'PR β|PR beta' rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md | rg -v '^[^:]+:[0-9]+:\s*>'
```

Expected: 輸出**為空** (所有 PR β 引用只在 illustrative callout blockquote 內)。

- [ ] **Step 5: Commit**

```bash
git add rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
git commit -m "docs(rust-coding-standards): rewrite Phase 3 startup gate as state-machine driven (Task 4 of abstraction sweep, per spec §5)"
```

---

## Task 5: 改寫 Task 2.1 章節結構 + 落 9 條 v0.8 (per spec §6)

**Files:**
- Modify: `rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md` (Task 2.1 段,原 v0.7 line 272-285)

per spec §6.1-§6.5。

- [ ] **Step 1: 讀 Task 2.1 段確認當前結構**

```bash
sed -n '/^- \[ \] \*\*Task 2\.1\*\*/,/^- \[ \] \*\*Task 2\.2\*\*/p' rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
```

Expected: 看到 Task 2.1 段,含 §MUST / §SHOULD / §MAY 三 sub-bullet + 5 項 Acceptance。

- [ ] **Step 2: 落 D 條 (v0.8 §MUST C-CASE / C-CONV 命名反例)**

Edit tool 在 §MUST sub-bullet 「命名 (C-CASE / C-CONV)」項下方加 D 條:

(於 §MUST sub-bullet 「命名 (C-CASE / C-CONV)」之後)
- `new_string` 段 (插入到 `命名 (C-CASE / C-CONV)、` 之後):

```markdown
  - **命名一致性 (v0.8 D)**: helper / private fn 命名須符合 module 既有 identifier 慣例 (同 module 內 `parse_x` / `build_y` pattern 不可混 `do_x` / `make_y`)

    > **Illustrative (nrg-prototype PR α `<commit-sha-D>`)**: `J1939Frame` module 內 helper fn 命名 anti-pattern 範例 — 原 helper fn 用 `do_parse_*` 與 module 既有 `parse_*` 不一致,review 後改齊。此例為 didactic reference,非通用模板規格。
```

`<commit-sha-D>` placeholder 由 executor 從 nrg-prototype repo `~/Projects/fortune_btbu_github_repos/nrg-prototype/` `tasks.md` §v0.8 待併入清單 D 條補實際 SHA;若 tasks.md 已刪,改寫為「PR α nrg-prototype 自審期間 (provenance reference deferred)」 + 在 Task 8 self-review 紀錄。

- [ ] **Step 3: 落 A / H / I 條 (v0.8 §SHOULD 三條)**

Edit tool 在 §SHOULD sub-bullet 末尾加 A / H / I 三條:

(於 §SHOULD sub-bullet 末尾,「smart-pointer conversion」之後)

```markdown
  - **rustdoc 跨 repo 隔離 (v0.8 A)**: rustdoc 引用必須消費者看得見;跨 repo internal doc / commit URL / work-tracking-system 條目引用要降級為「以下文件僅供 maintainer」之類 marker,或乾脆刪除

    > **Illustrative (nrg-prototype PR α `<commit-sha-A>`)**: `she_j1939::pgn::adlink::protocol` 早期 rustdoc 引用 nrg-prototype 內 design doc,ADLINK 套用時看不到 — 已修。此例為 didactic reference,非通用模板規格。

  - **位元組順序轉換 (v0.8 H)**: 跨 byte-order boundary 優先用 `u32::from_le_bytes` / `from_be_bytes`,不用手寫 bit shift (後者隱藏 endianness 意圖,reader 必須 inline reason 才能判斷哪邊是 LSB)

    > **Illustrative (nrg-prototype PR α `353e24ae`)**: J1939 ID 解析從手寫 `(b[0] as u32) | ((b[1] as u32) << 8) | ((b[2] as u32) << 16) | ((b[3] as u32) << 24)` 改為 `u32::from_le_bytes([b[0], b[1], b[2], b[3]])`,intent 一眼可見。此例為 didactic reference,非通用模板規格。

  - **spec 覆蓋範圍 (v0.8 I)**: API doc 對應 spec 多 variant 場景時,明示 `# Covered` / `# Not covered` 或等價段 (`# Spec coverage`)。Silent partial implementation 視為 doc 缺漏

    > **Illustrative (nrg-prototype PR α `<commit-sha-I>`)**: `J1939Id` `pgn::adlink::protocol` v1.2 PGN 部分 covered / 部分 deferred,doc 補 `# Covered` 段範例。此例為 didactic reference,非通用模板規格。
```

`<commit-sha-A>` / `<commit-sha-I>` 同 Step 2 處理。

- [ ] **Step 4: 新增 §testing 規範 sub-section (落 J / L)**

Edit tool 在 §MAY sub-bullet 之後 (Acceptance 之前) 插入新 sub-section:

```markdown
  - **§testing 規範** (v0.8 J / L 落地):

    - **測試目的區分 (v0.8 J)**: test 寫進 codebase 前須區分 — independent regression guard (獨立 invariant 驗證) vs explanatory overlap (輔助理解特定 behaviour)。後者不算 coverage gain,只是 documentation aid

      > **Illustrative (nrg-prototype PR α `<commit-sha-J>`)**: `frame::tests` 內 divergence test 原 framed 為 regression guard,review 後重新 framed 為 explanatory overlap (該 test 本質是輔助理解 `J1939Frame::new` 與 `from_raw` 兩種建構路徑分歧)。此例為 didactic reference,非通用模板規格。

    - **MIN-1 引至 test 範疇 (v0.8 L)**: MIN-1 (不為假設的未來需求寫 code) 在 test code 同樣適用 — 不為假設的 edge case 寫 test;若該 edge case 不在 spec / requirements,不該寫 regression test

      > **Illustrative (nrg-prototype PR α `<commit-sha-L>`)**: `frame::tests` 內 boundary test 原寫了假設的 max ID + 1 edge case (J1939 spec 未要求),review 後砍掉。此例為 didactic reference,非通用模板規格。
```

- [ ] **Step 5: 新增 §審查流程 sub-section (落 F / G / K)**

Edit tool 在 §testing 規範 之後 (Acceptance 之前) 插入:

```markdown
  - **§審查流程** (v0.8 F / G / K 落地):

    - **lint 與內容審視分層 (v0.8 F)**: clippy auto-fix 完不代表 rustdoc 語意完整 / API doc 完整性合格;reviewer 必跑手動 §MUST 條目 walk-through

      > **Illustrative (nrg-prototype PR α `<commit-sha-F>`)**: PR α clippy clean 後手動 walkthrough 發現 `# Errors` / `# Safety` 漏寫,clippy 沒抓到因為兩者屬 doc-completeness 而非 lint 範疇。此例為 didactic reference,非通用模板規格。

    - **雙重通讀 (v0.8 G)**: reviewer 須做 commit-by-commit pass + file-by-file 整體 pass 兩輪;前者抓 incremental change correctness,後者抓 cross-commit consistency / dead code / 早期 commit 缺漏 doc

      > **Illustrative (nrg-prototype PR α `<commit-sha-G>`)**: PR α 21 → 5 commit 收斂後 file-by-file pass 發現 4 commit 前的 helper fn 無 rustdoc (commit-by-commit pass 漏)。此例為 didactic reference,非通用模板規格。

    - **雙視角審查 (v0.8 K)**: 大型 PR 跑 dual sub-agent review (例 codex + agent B / `/dual-review` skill),兩 agent finding 預期 30% 重疊 (同一 bug 高度顯著) + 70% 互補 (各抓不同類 bug)。0% 重疊表示視角太窄,100% 重疊表示 reviewer profile 太相似

      > **Illustrative (nrg-prototype PR α `<commit-sha-K>`)**: PR α `/dual-review` 跑 codex + agent B,實際重疊比例範例 — codex 抓 8 finding / agent B 抓 6 finding / 重疊 2 finding (約 25-33%)。此例為 didactic reference,非通用模板規格。
```

- [ ] **Step 6: 新增 Acceptance 第 6 項 (per spec §6.4)**

Edit tool 在 Task 2.1 Acceptance 第 5 項之後加第 6 項:

```markdown
    6. §testing 規範 sub-section 必涵蓋 v0.8 J / L 兩條;§審查流程 sub-section 必涵蓋 v0.8 F / G / K 三條;§MUST 內 C-CASE / C-CONV sub-bullet 必含 D 命名反例;§SHOULD sub-bullet 必含 A / H / I 三條。每條 normative + illustrative 兩段格式須一致 (per v1.0 spec §6.3)
```

- [ ] **Step 7: 補 commit SHA references (per spec §6.5)**

`<commit-sha-A>` / `<commit-sha-D>` / `<commit-sha-F>` / `<commit-sha-G>` / `<commit-sha-I>` / `<commit-sha-J>` / `<commit-sha-K>` / `<commit-sha-L>` 8 個 placeholder 由 executor 從 nrg-prototype repo 查實際 SHA:

```bash
# Option A: 查 tasks.md §v0.8 待併入清單
sed -n '/§v0.8 待併入清單/,/##/p' ~/Projects/fortune_btbu_github_repos/nrg-prototype/tasks.md 2>/dev/null | head -100

# Option B: 若 tasks.md 已刪,查 git log
cd ~/Projects/fortune_btbu_github_repos/nrg-prototype/
git log --all --oneline --grep='v0.8' | head -20
git log --all --oneline --grep='condition_A\|condition_D\|condition_F\|condition_G\|condition_H\|condition_I\|condition_J\|condition_K\|condition_L' | head -20
```

對每條 A / D / F / G / H / I / J / K / L (H 已 frozen 為 `353e24ae`),從 tasks.md 或 git log 找出對應 commit SHA,用 Edit tool replace `<commit-sha-X>` 為實際 SHA。

**若 SHA 已遺失** (tasks.md 已刪 + git log 已 rewrite):
- 對該條 illustrative callout 用 Edit replace `<commit-sha-X>` 為 `provenance reference deferred`
- 把 callout 末「此例為 didactic reference,非通用模板規格。」之前加註「(provenance reference deferred,待 tasks.md 歷史回溯)」
- 在 Task 8 self-review 紀錄哪幾條 SHA 失落,寫進 commit message 與 spec §9 待解問題狀態

- [ ] **Step 8: 驗證 Task 2.1 結構完整**

```bash
sed -n '/^- \[ \] \*\*Task 2\.1\*\*/,/^- \[ \] \*\*Task 2\.2\*\*/p' rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md > /tmp/task-2-1.txt
grep -c '§testing 規範' /tmp/task-2-1.txt
grep -c '§審查流程' /tmp/task-2-1.txt
grep -c 'v0.8 A\|v0.8 D\|v0.8 F\|v0.8 G\|v0.8 H\|v0.8 I\|v0.8 J\|v0.8 K\|v0.8 L' /tmp/task-2-1.txt
```

Expected: §testing 規範 ≥ 1 hit、§審查流程 ≥ 1 hit、v0.8 A-L 9 條各 ≥ 1 hit (合計 ≥ 9 hits;若同條在 sub-section heading 與 callout 內各出現,可 > 9)。

- [ ] **Step 9: Commit**

```bash
git add rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
git commit -m "docs(rust-coding-standards): restructure Task 2.1 with v0.8 9-rule landing (A/D/F/G/H/I/J/K/L per spec §6)"
```

---

## Task 6: 改 §v0.8 暫存 為 §v0.8 落地紀錄 + 加 v0.7 → v1.0 changelog

**Files:**
- Modify: `rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md` (§v0.8 暫存 section,原 v0.7 line 508-544;status line 與 changelog 段,原 v0.7 line 19-52)

per spec §2.4 + §8 動作 #7。

- [ ] **Step 1: 讀 §v0.8 暫存 section 確認當前結構**

```bash
sed -n '/^## v0\.8 暫存/,/^---$/p' rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md | head -50
```

Expected: 看到「## v0.8 暫存 — PR α 實證心得 (待併入清單)」heading + status / table (12 條) / 合併規則 (drift-check / landing matrix / atomicity gate) / 「為何 v0.8 暫存拆兩處」段。

- [ ] **Step 2: 用 Edit 改寫整個 §v0.8 暫存 section 為 §v0.8 落地紀錄**

Edit tool:
- `old_string` = 整個 §v0.8 暫存 section (從 `## v0.8 暫存 — PR α 實證心得 (待併入清單)` 到下一個 `---` 之間)
- `new_string`:

```markdown
## v0.8 落地紀錄

v0.7 plan 內 §v0.8 暫存 12 條 PR α 實證心得已於 v1.0 abstraction sweep 全數落地。原暫存表 (drift-check / landing matrix / atomicity gate) 已不適用 (v1.0 sweep 同步落地,無暫存態);本段保留落地矩陣作為歷史紀錄。

**落地矩陣** (12 條雙軌記錄):

| 代號 | 一句摘要 | 落地狀態 | 落地錨點 |
|---|---|---|---|
| A | Library crate rustdoc 不可引用消費者看不見的設計文件 | landed | v1.0 Task 2.1 §SHOULD「rustdoc 跨 repo 隔離」(per spec §6.2) |
| D | Helper naming 看 module 既有 identifier 脈絡 | landed | v1.0 Task 2.1 §MUST「命名一致性」(per spec §6.2) |
| E | 安全性修正的 commit message 必須含 caller 清查段 | landed (plan 外) | adlink-can `CLAUDE.md` §Coding Standards (Red Lines) 紅線 2 (per anchor spec §5.2 + §7.1) |
| F | Clippy 機械式 fix 不等於 rustdoc 乾淨 | landed | v1.0 Task 2.1 §審查流程「lint 與內容審視分層」(per spec §6.2) |
| G | Holistic file-by-file review 補 commit-by-commit 漏網 issue | landed | v1.0 Task 2.1 §審查流程「雙重通讀」(per spec §6.2) |
| H | `u32::from_le_bytes` 是表達 byte-order 意圖的 idiomatic 寫法 | landed | v1.0 Task 2.1 §SHOULD「位元組順序轉換」(per spec §6.2) |
| I | Spec 多變體時 doc 要明說 covered / not covered | landed | v1.0 Task 2.1 §SHOULD「spec 覆蓋範圍」(per spec §6.2) |
| J | Divergence test 是 explanatory overlap,不是 independent regression guard | landed | v1.0 Task 2.1 §testing 規範「測試目的區分」(per spec §6.2) |
| K | Dual sub-agent review 30% overlap + 70% 互補 | landed | v1.0 Task 2.1 §審查流程「雙視角審查」(per spec §6.2) |
| L | MIN-1 紅線在 test 同樣適用 | landed | v1.0 Task 2.1 §testing 規範「MIN-1 引至 test 範疇」(per spec §6.2) |
| M | 逐筆搬比 git rebase --squash 對 PR history 收斂更乾淨 | landed (plan 外) | adlink-can `CLAUDE.md` §Workflow Preferences (per anchor spec §5.2 + §7.2) |
| N | PR description for detailed reviewer 必須含 commit walkthrough + review order | landed (plan 外) | adlink-can `CLAUDE.md` §Workflow Preferences (per anchor spec §5.2 + §7.2) |
```

- [ ] **Step 3: 改 status line + 加 v1.0 changelog 段**

讀當前 status line:

```bash
sed -n '/^\*\*狀態\*\*/,/^---$/p' rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md | head -10
```

Expected: 看到「**狀態**: v0.7 拍板為定稿...」line。

Edit tool 改 status line:
- `old_string` = `**狀態**: v0.7 拍板為定稿 (Harry 2026-04-29 核可,round 6 跳出迴圈判定成立,見 Appendix F)。Codex round 1-6 共 28 findings 全採納 + 三輪繁中品質驗證達標。v0.8 暫存進行中 — PR α 自審累積 12 條實證心得待併入 Task 2.1 / Phase 5,索引見 §v0.8 暫存,全文證據留在 `tasks.md` 同名章節。`
- `new_string` = `**狀態**: v1.0 通用模板 (2026-05-28 abstraction sweep,per spec `docs/2026-05-28-idiomatic-rust-plan-abstraction-design.md`)。原 v0.7 nrg-prototype hard-coded 已抽象化為 placeholder + illustrative example 雙層結構;v0.8 暫存 12 條心得全數落地 (9 條 plan 內 → Task 2.1 sub-section;3 條 plan 外 → adlink-can `CLAUDE.md`;見 §v0.8 落地紀錄)。`

Edit tool 在「**v0.7 相對 v0.6 的主要變動**」段之前 (line 21 附近) 插入「**v1.0 相對 v0.7 的主要變動**」段:

```markdown
**v1.0 相對 v0.7 的主要變動** (2026-05-28 abstraction sweep,per spec `docs/2026-05-28-idiomatic-rust-plan-abstraction-design.md`):

- 163 列 hard-coded anchor 全數抽象化:(a) 80+ 列 → 13 個 placeholder substitution;(b)(d) 46+ 列 → illustrative callout framing;(c) 35+ 列 → repo-neutral prose / `<vc-ref-mechanism>` / `<consensus-reviewer>` 等抽象化
- 新增 YAML frontmatter (audience / version / status / coupling) 標明跨 spec coupling (per spec §7)
- 改寫 Task 1.3 / 1.4 Acceptance,加入 §1B reviewer routing 3 維度分解 (reviewer 集合 / ack 媒介 / 拍板頻率 + 預設策略,per spec §4)
- 改寫 Phase 3 啟動 gate 為 state-machine driven (綁 anchor spec §3.5.1 `<unsafe-targeted-test>` / `<unsafe-binary-side>` state machine,per spec §5);PR β 引用全部移入 illustrative callout
- Task 2.1 章節結構擴展:新增 §testing 規範 / §審查流程 兩個 sub-section;落 v0.8 9 條 plan 內條目 (A 至 SHOULD / D 至 MUST / F G K 至 §審查流程 / H I 至 §SHOULD / J L 至 §testing 規範);Acceptance 加第 6 項
- §v0.8 暫存 section 改寫為 §v0.8 落地紀錄,只留 12 條雙軌落地矩陣 (9 條 plan 內 + 3 條 plan 外),原 atomicity gate / drift-check 移除

```

- [ ] **Step 4: 驗證 §v0.8 落地紀錄 與 v1.0 changelog 寫入**

```bash
grep -c "## v0\.8 落地紀錄" rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
grep -c "v1\.0 相對 v0\.7 的主要變動" rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
grep -c "v1\.0 通用模板" rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
```

Expected: 三個 grep 各回 ≥ 1 hits。

- [ ] **Step 5: Commit**

```bash
git add rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
git commit -m "docs(rust-coding-standards): rewrite §v0.8 暫存 → §v0.8 落地紀錄 + add v1.0 changelog (Task 6 of abstraction sweep, per spec §2.4 + §8 #7)"
```

---

## Task 7: Codex review v0.7 → v1.0 完整 diff

**Files:**
- 無新增。Review `rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md` v0.7 → v1.0 diff

per General Workflow + spec §8 動作 #8。

- [ ] **Step 1: 確認 diff baseline**

```bash
git log --oneline rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md | head -10
```

Expected: 看到 Task 1 / 2 / 3 / 4 / 5 / 6 共 6 commits 在頂部。前一個 commit (Task 1 之前) 是 v0.7 baseline。

```bash
BASELINE_SHA=$(git log --pretty=format:'%h' -n 1 --skip=6 rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md)
echo "Baseline SHA: $BASELINE_SHA"
git diff "$BASELINE_SHA"..HEAD -- rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md | wc -l
```

Expected: 印出 baseline SHA + diff 行數 (預估 > 1500 行,因為 v0.7 → v1.0 改動量大)。

- [ ] **Step 2: 觸發 Codex review**

呼叫 `codex:rescue` skill review v0.7 → v1.0 diff。focus 建議:

- **抽象化邊界一致性**:normative 段是否仍含 nrg-prototype specific reference (per spec §3.3 Acceptance #1)
- **Illustrative callout framing 一致性**:所有 callout 是否末標「此例為 didactic reference,非通用模板規格」
- **§1B reviewer routing 3 維度完整性**:Task 1.3 / 1.4 是否都含 3 維度說明 + 預設策略 + illustrative callout
- **Phase 3 state-machine gate 完整性**:啟動 gate table 4 行 state 組合 + Acceptance 3 項是否齊全
- **v0.8 9 條落地完整性**:A / D / F / G / H / I / J / K / L 是否各有 normative + illustrative 兩段
- **v1.0 changelog 與 §v0.8 落地紀錄一致性**:落地矩陣 12 條狀態 vs changelog 描述
- **YAML frontmatter validity**:coupling 段 path / location / constraint 三 field 是否完整

Codex review 報告寫入 `/tmp/codex-review-v0.7-to-v1.0.txt`。

- [ ] **Step 3: 處理 critical / high 級 finding**

對 Codex review 報告內的 critical / high 級 finding 用 Edit tool 修正。每處修正完跑對應 acceptance check (例 spec §3.3 Acceptance #1 grep 重跑、§6.4 Acceptance grep 重跑等)。

low / info 級 finding 視情況採納;明顯不影響規格正確性的可記錄在 commit message 但不修。

- [ ] **Step 4: 若有 critical / high finding 修正,commit 修正**

```bash
git add rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
git commit -m "docs(rust-coding-standards): apply Codex review findings on v0.7 → v1.0 abstraction sweep (Task 7)"
```

若 zero critical / high finding,跳過 commit,在 Task 8 commit message 記「Codex review zero critical / high finding」。

---

## Task 8: 繁中校稿 (classical-chinese-rules skill)

**Files:**
- 無新增。Review v1.0 完整內容

per General Workflow + spec §8 動作 #9 + 全域 CLAUDE.md trigger #2。

- [ ] **Step 1: 觸發 `classical-chinese-rules` skill**

呼叫 `classical-chinese-rules` skill 對 `rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md` v1.0 完整內容跑校稿。重點掃:

- 思果 14 條核心規則違規 (「被」字 / 「將」字 / 「曾經」 / 「著」字 / 「在...方面」 / 動詞 > 名詞化 / 「對」字濫用 等)
- Section I 懶惰英文 (一般英文名詞 / 動詞 / 形容詞有自然中文對應時要換)
- Task 2C / Task 5 寫入的 illustrative callout 段落特別重點掃 (新寫的中文段最易犯懶惰英文)
- Task 1.3 / 1.4 / Phase 3 gate / Task 2.1 sub-section 新寫段落

- [ ] **Step 2: 用 Edit 修正違規**

對每處違規用 Edit tool 修正。可批次跑多個 Edit。

- [ ] **Step 3: 驗證校稿後 spec §3.3 Acceptance 仍 hold**

```bash
rg -n -E 'she_j1939|she_bms_masterboard|nrg-prototype|Vincent|Eden|Harry|Gitea|ti_001_can_comm|29117d7b|353e24ae|ef363dba|PR α|J1939Id::from_raw|pgn::adlink::protocol|cortex-m|critical-section|hse_8mhz|tasks\.md|int_004|INT-004|ExtendedId::new_unchecked|frame::tests|frame\.rs' \
  rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md | rg -v '^[^:]+:[0-9]+:\s*>' | head -10
```

Expected: 輸出**為空** (校稿不應引入新的 normative-層 nrg-prototype reference)。

- [ ] **Step 4: Commit**

```bash
git add rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
git commit -m "docs(rust-coding-standards): apply classical-chinese-rules polishing on v1.0 (Task 8 of abstraction sweep, per spec §8 #9)"
```

---

## Task 9: 端對端 acceptance + push (human-gated)

**Files:** 無新增。跑既有 acceptance + push (待 user 核可)

per spec §8 動作 #10。

- [ ] **Step 1: 跑 spec §3.3 整體 Acceptance**

```bash
# Acceptance #1: normative 段不含 nrg-prototype reference
echo "=== Acceptance #1: normative 段乾淨 ==="
rg -n -E 'she_j1939|she_bms_masterboard|nrg-prototype|Vincent|Eden|Harry|Gitea|ti_001_can_comm|29117d7b|353e24ae|ef363dba|PR α|J1939Id::from_raw|pgn::adlink::protocol|cortex-m|critical-section|hse_8mhz|tasks\.md|int_004|INT-004|ExtendedId::new_unchecked|frame::tests|frame\.rs' \
  rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md | rg -v '^[^:]+:[0-9]+:\s*>'

# Acceptance #2: 13 個 placeholder 每個 ≥ 1 hit (除特定例外)
echo "=== Acceptance #2: placeholder 涵蓋 ==="
for p in '<library-crate>' '<binary-crate>' '<library-crate-paths>' '<binary-crate-paths>' '<unsafe-targeted-test>' '<unsafe-binary-side>' '<consensus-reviewer>' '<sync-reviewer>' '<vc-ref-mechanism>'; do
  count=$(rg -c -F "$p" rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md || echo 0)
  echo "$p: $count hits"
done

# Acceptance #3: v0.8 9 條皆有 normative + illustrative 兩段
echo "=== Acceptance #3: v0.8 9 條 ==="
grep -E '\(v0\.8 [ADFGHIJKL]\)' rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md | wc -l

# Acceptance #4: frontmatter coupling 存在
echo "=== Acceptance #4: frontmatter coupling ==="
head -20 rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md | grep -c "coupling:"
```

Expected:
- Acceptance #1: 為空
- Acceptance #2: 9 個 placeholder 各 ≥ 1 hits (除 `<workspace-pub-crates>` / `<detailed-reviewer-profile>` / `<ci-platform>` / `<release-branch>` 視 plan 是否引用)
- Acceptance #3: ≥ 9 hits (9 條 normative heading;加 illustrative callout 內可能 > 9)
- Acceptance #4: = 1

任一 fail 回 Task 2-6 對應 sub-task 補。

- [ ] **Step 2: 跑 commit log audit 確認 6 個 Task commits 全在**

```bash
git log --oneline rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md | head -10
```

Expected: 至少 6 commits (Task 1 + 2 + 3 + 4 + 5 + 6),加上 Task 7 / 8 修正 commit (若有)。

- [ ] **Step 3: 跑 file-level diff stat**

```bash
BASELINE_SHA=$(git log --pretty=format:'%h' -n 1 --skip=$(git log --oneline rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md | wc -l | xargs -I {} expr {} - 1) rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md)
git diff --stat "$BASELINE_SHA"..HEAD -- rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md
```

Expected: 看到 v0.7 → v1.0 完整 diff stat (預估 +200 / -150 行左右,因為新增 frontmatter / changelog / v0.8 9 條 / Phase 3 gate / §1B routing 段;原 §v0.8 暫存 / Gitea 遷移備註等段被改寫)。

- [ ] **Step 4: Push (human-gated)**

User 核可後執行:

```bash
git push origin main
```

若 user 還未核可,跳過 Step 4,改記錄「commits 累積在本機,待人工核可後 push」。push 屬「affects shared state」類動作,依全域 CLAUDE.md 預設不可主動 push,必須 user 明確同意才動。

- [ ] **Step 5: 通知 adlink-can 端 follow-up (per spec §8 動作 #11-#13)**

本 plan 完成後 (push 成功後),通知 adlink-can 端 maintainer 啟動 follow-up:

1. mapping doc §A.1 #104 / #129 註記改「Superseded by state-machine gate (per v1.0 §5),no new placeholder needed」
2. mapping doc §B `<consensus-reviewer>` state `provisional` → `landed`,填 adlink-can 對應 3 維度具體值 (per v1.0 §4.3:solo Harry / GitHub PR review comment / per-PR)
3. anchor spec frontmatter coupling row 改寫為本 v1.0 land 後的 commit SHA reference (per anchor spec §6.3)

通知形式:在 push 後的 commit message footer 或本機 follow-up note 記載。不在本 plan scope (本 plan 是 claude-code-skills repo,無權動 adlink-can 內容)。

無 commit (external notification)。

---

## Self-review checklist (plan 寫完後我自己跑的 sweep,not for executor)

(此段保留給 plan 作者於本 plan 寫完後 inline 跑一次,**不對 executor 暴露**;executor 跳過。)

1. **Spec coverage** — abstraction design spec §8 動作 #1 (frontmatter) → Task 1;#2 (163 列 substitution) → Task 2;#3 (Task 1.3 / 1.4) → Task 3;#4 (Phase 3 gate) → Task 4;#5 (Task 2.1 + 9 條 v0.8) → Task 5;#6 (§v0.8 改寫) → Task 6;#7 (version + changelog) → Task 6 Step 3;#8 (Codex review) → Task 7;#9 (繁中校稿) → Task 8;#10 (Commit + push) → Tasks 1-6 各自 commit + Task 9 Step 4 push。覆蓋完整。

2. **Placeholder scan** — 本 plan 內 `<commit-sha-A>` / `<commit-sha-D>` 等 8 個是 deliberate 開放 (Task 5 Step 7 處理),非 plan 缺漏;`<repo-root>` 是 executor cwd reference,非 plan 缺漏;mapping §A.1 內 `<phase3-gate-pr>` placeholder 是 spec §5.3 frozen 為「不新增」,本 plan 不引用。無其他 TBD / TODO 字樣。

3. **Type consistency** — placeholder 命名:本 plan 與 spec §A / mapping §A 13 個 placeholder 字串完全一致 (`<library-crate>` 不寫成 `<lib-crate>`,等等);v0.8 9 條代號 A/D/F/G/H/I/J/K/L 在 Task 5 / Task 6 各 sub-section 對映一致;Task 1.3 / 1.4 內 「§1B reviewer routing」段名與 spec §4 一致;Phase 3「啟動 gate」與 spec §5 一致;§testing 規範 / §審查流程 / §v0.8 落地紀錄 段名與 spec §6 / §2.4 一致。
