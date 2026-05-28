---
audience: dual
version: v1.0-spec
status: 草稿(待審閱)
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

# 通用模板 Plan v0.7 → v1.0 抽象化 sweep — Design Spec

> **部署位置**:`~/Projects/claude-code-skills/docs/` (本 repo 內 design spec)
> **設計日期**:2026-05-28
> **對象 plan**:`rust-coding-standards/references/2026-04-18-idiomatic-rust-plan.md` v0.7 (659 行)
> **升版目標**:v0.7 → v1.0
> **上游觸發**:adlink-can anchor spec §8 #1 動作清單

| 欄位 | 內容 |
|---|---|
| 狀態 | 草稿 (待審閱) |
| 來源 | brainstorming session 2026-05-28 (claude-code-skills repo 內) |
| Mapping SOT | adlink-can `docs/coding-standards/idiomatic-rust-mapping.md` (§A.1 163 列 inventory matrix 已 frozen,2026-05-28 commit `f61ff67`) |
| 跨 spec coupling | 配合 adlink-can anchor design spec ≥ 對應 v1.0 commit (per anchor spec §6.3) |

> 本 spec 規定通用模板 plan v0.7 (659 行,原 nrg-prototype anchor) 抽象化為 v1.0 (placeholder + illustrative example 雙層結構) 的設計。Anchor spec §8 #1 動作清單觸發本 sweep。Adlink-can 端的 anchor 設計與 mapping schema 由 anchor spec 處理,本 spec **不負責** adlink-can 內部任何動作 — 只負責 skill repo 內通用模板自身的抽象化。

---

## Summary (English)

This spec defines the abstraction sweep that converts plan v0.7 (659 lines, hard-coded to nrg-prototype's `she_j1939` / `she_bms_masterboard`) into a v1.0 general template plus illustrative examples. The abstraction follows the 163-row inventory matrix already frozen in adlink-can mapping doc §A.1, processing each anchor by class: (a) placeholder substitution, (b) illustrative-example carve-out with explicit `> **Illustrative (nrg-prototype):** ...` framing, (c) abstraction to placeholder or repo-neutral prose, (d) retained provenance inside illustrative callouts. The spec also redefines two items deferred by anchor spec to this sweep: §3.5.4 `<consensus-reviewer>` Phase 1 1B reviewer routing (3-dimension decomposition) and Phase 3 startup gate (state-machine driven, derived from anchor spec §3.5.1). Nine v0.8 in-plan rules (A/D/F/G/H/I/J/K/L) accumulated from PR α self-review are landed into restructured Task 2.1 sub-sections (§testing 規範 / §審查流程 newly introduced). Frontmatter coupling marker per anchor spec §6.3 added. v0.7 §v0.8 暫存 section becomes §v0.8 落地紀錄 with two-track landing matrix.

---

## 1. 背景與目標

### 1.1 為什麼要 sweep

adlink-can 是新一代 Rust 韌體架構 (per anchor spec §1.1);沿用 v0.7 plan 累積的 Rust 工程實踐知識,前提是把 plan 從 nrg-prototype hard-coded 抽出來,變成跨專案可重用的通用模板。Anchor spec 已負責 adlink-can 端的 mapping doc + thin reference deliverable;本 sweep 負責 skill repo 端通用模板自身的抽象化。

### 1.2 設計目標

- v1.0 通用模板讓個別專案透過 mapping doc + thin reference 直接套用,不必每個專案重新 anchor 整份 plan
- 保留 v0.7 累積的實證範例教學價值 (用 illustrative callout framing,不混入 normative 規格)
- 落 v0.8 暫存 9 條 plan 內條目 (A/D/F/G/H/I/J/K/L) 到通用模板對應 sub-section,實質產出 v1.0 規格擴充
- §3.5.4 `<consensus-reviewer>` Phase 1 1B routing + Phase 3 啟動 gate 兩處 anchor spec 委派的設計議題收斂

### 1.3 範圍與不在範圍

**本 spec scope**:

- 通用模板 plan v0.7 → v1.0 文檔抽象化規範
- 163 列 anchor 落地操作規則 (依 mapping doc §A.1 已 frozen 分類,分四 class 處理)
- §3.5.4 `<consensus-reviewer>` Phase 1 1B reviewer routing 維度分解
- Phase 3 啟動 gate state-machine driven 重訂
- v0.8 9 條 plan 內條目落 Task 2.1 sub-section (含 Task 2.1 章節結構擴充)
- v0.8 暫存 section 改寫為 v0.8 落地紀錄
- Frontmatter YAML coupling 標記

**不在本 spec scope**:

- adlink-can 內部 anchor 設計與 mapping schema (歸 anchor spec)
- adlink-can mapping doc 與 deliverable 落地 (歸 anchor spec implementation plan)
- v0.8 plan 外條目 (E / M / N) 落地 — 已落 adlink-can `CLAUDE.md`,per anchor spec §5.2 / §7
- 通用模板新規格 round 7+ Codex adversarial review (v0.7 已 escalation out,v1.0 是 abstraction sweep 非新規格)
- Phase 4 (深度閱讀) 結構改寫 — 該段純 reading list,無 anchor 強綁

**Follow-up** (本 spec 不展開):

- adlink-can mapping doc §A.1 第 104 / 129 列註記更新為「Superseded by state-machine gate」(由 adlink-can 端 maintainer 同步)
- adlink-can mapping doc §B `<consensus-reviewer>` state 從 `provisional` → `landed`,套本 v1.0 §4 維度填具體值
- adlink-can anchor spec frontmatter coupling row 改寫為 commit SHA reference (per anchor spec §6.3)

### 1.4 上游決策依據

本 spec 沿用 brainstorming session 2026-05-28 拍板:

| Q | 答案 |
|---|---|
| Q1 v0.7 plan §A.1 Class (b)/(d) 處理策略 | Illustrative-example carve-out — 保留 nrg-prototype 具體實例與 PR α provenance,統一 `> **Illustrative (nrg-prototype):** ...` callout framing |
| Q2 `<consensus-reviewer>` Phase 1 1B routing 深度 | 維度分解 — reviewer 集合 / ack 媒介 / 拍板頻率 3 維度 + 預設策略 (solo + any immutable written ack + per-PR) |
| Q3 Phase 3 啟動 gate 設計 | State-machine driven — 直接綁 anchor spec §3.5.1 state machine,不新增 placeholder |

---

## 2. 抽象化策略

### 2.1 雙層結構 (規格 + illustrative)

v1.0 通用模板採雙層結構:

- **規格層** (normative): placeholder + 規則描述。Reader 套用通用模板時看的就是這層。
- **illustrative 層** (didactic): 來自 v0.7 nrg-prototype 的 lived example 與 PR α provenance。包在 callout 內,明示「非通用模板規格」。

兩層界線靠 markdown blockquote 區隔。Normative 段落為一般散文 / 條列 / 表格;illustrative 段落用 `> **Illustrative (nrg-prototype ...):** ...` blockquote 包起來,末標「此例為 didactic reference,非通用模板規格」。

### 2.2 為什麼選 carve-out 而非 total purge

brainstorming Q1 已答,本段 archive 理由:

1. v0.7 plan 大量 lived-example (`J1939Id::from_raw` / `ti_001_can_comm::wait_with_demux` / `frame.rs:44 ExtendedId::new_unchecked` 等) 是 didactic anchor — 抽空了 reader 看不到具體怎麼套規則。
2. v0.8 9 條心得來自 PR α 自審,落地進 Task 2.1 sub-section 時必然帶 PR α commit SHA;一刀切會破壞 v0.8 落地。
3. Future Rust 韌體專案 onboarding 時,有 illustrative example 對照才知道怎麼填空。

### 2.3 163 列 anchor 落地分類處理

依 mapping doc §A.1 已 frozen 的 4-class framework:

#### (a) Placeholder candidate — 直接 substitution

對 §A.1 標 (a) 列依 mapping doc §A 命名替換。Mapping 已 frozen 13 個 placeholder,本 spec 不另外定義新 placeholder (Phase 3 gate 不必新增 `<phase3-gate-pr>`,per §5)。

#### (b) Local example — illustrative carve-out

對 §A.1 標 (b) 列保留 nrg-prototype 具體實例 (`J1939Id::from_raw` / `ExtendedId::new_unchecked` / `ti_001_can_comm` / `cortex-m` / `critical-section` / `hse_8mhz` / `frame::tests::new_extended_with_max_id_constructs_ok` 等) 作為 illustrative example。實作規則:

- 包在 `> **Illustrative (nrg-prototype <crate-or-component>):** ...` blockquote 內
- Callout 末標「此例為 didactic reference,非通用模板規格」或等價句
- Callout 之外的 normative 段落不出現具體 API 名稱

範例 (Task 2.1 §SHOULD 內):

```markdown
- **位元組順序轉換**: 跨 byte-order boundary 時優先用 `u32::from_le_bytes` /
  `from_be_bytes` 而非手寫 bit shift。Manual shift 隱藏 endianness 意圖,
  reader 必須 inline reason 才能判斷哪邊是 LSB。

  > **Illustrative (nrg-prototype PR α `353e24ae`)**: J1939 ID 解析從手寫
  > `(b[0] as u32) | ((b[1] as u32) << 8) | ((b[2] as u32) << 16) | ((b[3] as u32) << 24)`
  > 改為 `u32::from_le_bytes([b[0], b[1], b[2], b[3]])` 後,intent 一眼可見。
  > 此例為 didactic reference,非通用模板規格。
```

#### (c) N/A — 抽象化

對 §A.1 標 (c) 列逐項改寫:

| v0.7 reference | v1.0 處理 |
|---|---|
| `Gitea` / `Gitea issue` / `Gitea comment` / `Gitea CI` | → `<vc-ref-mechanism>` (per §A) |
| `Vincent` (作 reviewer / 拍板對象) | → `<consensus-reviewer>` 或 `<detailed-reviewer-profile>` (依語境;1B 拍板情境用前者,PR α detailed-review profile 用後者) |
| `Eden` (作 reviewer) | → `<consensus-reviewer>` |
| `nrg-prototype` (作 repo 名) | → repo-neutral prose (例「the Rust workspace」/「current codebase」) |
| `tasks.md` (作 work tracking) | → 通用 prose (例「project work tracking system」/「ticket queue」),不指定具體工具 |
| `int_004` / `INT-004` | → 刪除 (屬已停 work item,通用模板不引用) |
| `crates/lib/` / `crates/bin/` (作通用 path pattern) | → `<library-crate-paths>` / `<binary-crate-paths>` |

對 (c) 列也要清乾淨「遷移備註 (2026-05-13)」段 (v0.7 line 5 那段純 nrg-prototype Gitea → GitHub 遷移歷史記錄),改為一行通用 placeholder doc 引導 (例「`<vc-ref-mechanism>` 由 individual project 在 mapping doc §B 填具體值」)。

#### (d) Retained provenance — illustrative carve-out

對 §A.1 標 (d) 列 (PR α / commit SHA `29117d7b` / `353e24ae` / `ef363dba`) 保留作為 illustrative-example 歷史出處,實作規則同 class (b) — 包在 illustrative callout 內,callout 末標「非通用模板規格」。歷史出處引用不獨立成段,必跟伴隨的 illustrative example 一起出現。

### 2.4 §v0.8 暫存 section 改寫

v0.7 line 508-544 §v0.8 暫存 section (待併入清單) 在 v1.0 改寫為 §v0.8 落地紀錄,結構:

- 原 12 條 routing table 改成「落地矩陣」雙軌記錄:
  - 9 條 plan 內 (A/D/F/G/H/I/J/K/L) 狀態 = `landed (in v1.0 Task 2.1 §<sub-section>)`
  - 3 條 plan 外 (E/M/N) 狀態 = `landed (in adlink-can CLAUDE.md §<section>, per anchor spec §7)`
- 原 atomicity gate / drift-check 步驟刪除 (已不適用 — v1.0 sweep 同步落地,無暫存態)
- 原「為何 v0.8 暫存拆兩處」段刪除 (同理)

---

## 3. 163 列 anchor 落地實作 framework

mapping doc §A.1 已 frozen 163 列分類,本 sweep implementation plan 階段按本表規則跑系統性 substitution。本 spec **不重列** 163 列 (避免 SOT 重複)。

### 3.1 Substitution rules (implementation plan executor 依此跑)

| Class | 對應 §A.1 列 | 動作 |
|---|---|---|
| (a) Placeholder candidate | mapping §A.1 標 (a) 各列 | 用 mapping §A 13 個 placeholder 直接 grep-and-replace (具體對映在 §A.1 該列「處理」欄已 frozen) |
| (b) Local example | mapping §A.1 標 (b) 各列 | 保留具體值 (`J1939Id::from_raw` 等),周邊段落改寫為 illustrative callout |
| (c) N/A | mapping §A.1 標 (c) 各列 | 依本 spec §2.3 (c) 表抽象化 |
| (d) Retained provenance | mapping §A.1 標 (d) 各列 | 保留 PR α / commit SHA,移至伴隨的 illustrative callout 內 |

### 3.2 Substitution 操作建議 (non-normative,executor 參考)

- 用 ripgrep 對 v0.7 plan 跑每 placeholder 對應 anchor terms,`rg -n` 拿到 v0.7 line 範圍
- 對照 mapping doc §A.1「v0.7 line」欄 + 「Anchor text」欄,確認每處 hit 對應 row 的 class
- 同一行多 anchor term 場景 (如 v0.7 line 80 同時含 `crates/lib/she_j1939/src/frame.rs:44` + `she_j1939` + `ExtendedId::new_unchecked` — 對應 mapping §A.1 row 24 / 25 / 26 不同 class),逐 term 分別處理

### 3.3 Acceptance (本 sweep 整體)

1. 跑完 sweep 後,grep `she_j1939` / `she_bms_masterboard` / `nrg-prototype` / `Vincent` / `Eden` / `Gitea` / `tasks.md` / `int_004` / `INT-004` / `ti_001_can_comm` / `J1939Id::from_raw` / `pgn::adlink::protocol` / `PR α` / `PR β` / `29117d7b` / `353e24ae` / `ef363dba` 各 anchor terms 對 v1.0 plan,結果應**只**出現在 illustrative callout 內 (blockquote `>` 開頭的段) — normative 段全乾淨
2. mapping doc §A 13 個 placeholder 每個都必須在 v1.0 plan 出現至少一次 (除非該 placeholder 在 v0.7 對應 anchor 為 N/A — 由 §A.1 確認)
3. v0.8 9 條條目每條都有 normative + illustrative 兩段落地進 Task 2.1 對應 sub-section (per §6)
4. v1.0 plan frontmatter YAML 含 `version: v1.0` + `coupling` 段 (per §7)

---

## 4. §3.5.4 `<consensus-reviewer>` Phase 1 1B reviewer routing 重訂

### 4.1 結構: 3 維度

v0.7 Phase 1 1B (`cargo audit` / `cargo deny`) 拍板原來是 Vincent + Harry 在 Gitea 留 ack。抽象化為 `<consensus-reviewer>` 後,routing 拆 3 維度:

| 維度 | 選項 | 預設 |
|---|---|---|
| Reviewer 集合 | solo / pair / committee | solo |
| Ack 媒介 | `<vc-ref-mechanism>` PR comment / commit message footer / issue ack / async written doc / dated meeting note | any immutable written ack |
| 拍板頻率 | per-PR / per-release / monthly | per-PR |

Individual project 在 mapping doc §B `<consensus-reviewer>` 列填 3 維度具體選擇,即可從 `provisional` state 轉 `landed`。

### 4.2 預設策略適用條件

預設 (solo + any immutable written ack + per-PR) 適用條件:

- Single-maintainer / single-developer codebase (無外部 peer reviewer)
- CI / CVE feed 已自動化 (audit 結果有 immutable trail)
- 拍板頻率 per-PR 不會卡住 developer feedback loop (`cargo audit` 約 5 秒成本)

不符合時 project 必 override (例團隊規模 > 1 必走 pair;多人協作必走 committee;等等)。

### 4.3 範例填法 (adlink-can,non-normative)

adlink-can mapping doc §B 預期填:

| 維度 | adlink-can 值 |
|---|---|
| Reviewer 集合 | solo (Harry) |
| Ack 媒介 | GitHub PR review comment (對應 `<vc-ref-mechanism>` = `gh` CLI + GitHub PR review) |
| 拍板頻率 | per-PR (`cargo audit` 5 秒 cost,不卡 PR throughput) |

由 adlink-can 端 maintainer 在本 v1.0 land 後執行 (follow-up,本 spec 不展開)。

### 4.4 v0.7 受影響段落

走本 routing 規則的 v0.7 段落:

- Task 1.3 (`cargo audit` 升 PR 級 vs 月度) Acceptance 第 1-2 條
- Task 1.4 (`cargo deny check`) Acceptance 第 1-2 條

兩 Task 的 acceptance 改寫範例 (Task 1.3):

```markdown
- [ ] **Task 1.3**: 評估 `cargo audit` 從月度升為 PR 級。
  - **Acceptance**:
    1. `<consensus-reviewer>` 在 `<vc-ref-mechanism>` 留下拍板 (PR 級 / 月度)
       並標示理由
    2. project `CLAUDE.md` Rust verification checklist 對應段落更新,
       引用該拍板 URL / SHA
    3. 若升 PR 級,`<library-crate>` 與 `<binary-crate>` 對應的
       quality-check script 涵蓋該 step

  > **Illustrative (nrg-prototype PR α 期間)**: `<consensus-reviewer>`
  > 預期填 Vincent + Harry,`<vc-ref-mechanism>` 預期填 Gitea comment
  > (後遷移 GitHub PR review)。此例為 didactic reference,非通用模板規格。
```

---

## 5. Phase 3 啟動 gate 重訂 (state-machine driven)

### 5.1 設計: 綁 anchor spec §3.5.1 state machine

v0.7 line 346 寫「PR β 前完成 Phase 3」,nrg-prototype specific。Anchor spec §3.5.1 已 frozen `<unsafe-targeted-test>` / `<unsafe-binary-side>` state machine (`TBD` / `N/A-no-current-target` / `landed` 3 state)。v1.0 Phase 3 啟動 gate 直接沿用該 state machine:

| `<unsafe-targeted-test>` state | `<unsafe-binary-side>` state | Phase 3 狀態 |
|---|---|---|
| `TBD` | `TBD` | block (待 codebase audit 清 unsafe 分佈) |
| `landed` | * | **啟動** |
| * | `landed` | **啟動** |
| `N/A-no-current-target` | `N/A-no-current-target` | **skipped (N/A per audit YYYY-MM-DD)**,跳 Phase 4 |

### 5.2 Phase 3 整體啟動 Acceptance

Phase 3 Task 3.1-3.5 各自的 Acceptance 不動 (已 frozen);新增 Phase 3 整體啟動 Acceptance:

```markdown
**Phase 3 啟動 gate Acceptance**:

1. Phase 3 啟動時 mapping doc §B 上 `<unsafe-targeted-test>` 或
   `<unsafe-binary-side>` 任一 state ≠ `TBD`
2. 若 Phase 3 標 `skipped (N/A per audit YYYY-MM-DD)`,mapping doc §B
   兩 placeholder state 必皆 `N/A-no-current-target`,且 audit commit
   reference 已寫入 §B「Source / 驗證」欄
3. 啟動或 skip 決策必在 mapping doc §D Sync log 留一列
   (per anchor spec §3.5.3 pre-v1.0 provisional / post-v1.0 three-way 兩階段規則)
```

### 5.3 不新增 `<phase3-gate-pr>` placeholder

Mapping doc §A.1 第 104 / 129 列 (對應 v0.7 line 346 / 464 的 `PR β`) 原註記「待抽象化 spec 新增 `<phase3-gate-pr>` placeholder」。v1.0 改用 state-machine driven gate,不需新 placeholder;故該兩列在 v1.0 land 後改註記「Superseded by state-machine gate (per v1.0 §5), no new placeholder needed」。

此改動由 adlink-can 端 maintainer 同步至 mapping doc §A.1,本 spec 不展開 (follow-up,§8 動作 #11)。

---

## 6. v0.8 9 條 plan 內條目落 Task 2.1 sub-section

### 6.1 Task 2.1 章節結構擴展

v0.7 Task 2.1 章節結構 (line 272-285):

- 觸發範圍
- §MUST (5 sub-bullet)
- §SHOULD (6 sub-bullet)
- §MAY (3 sub-bullet)
- Acceptance (5 items)

v1.0 改為:

- 觸發範圍 (unchanged)
- §MUST (5 sub-bullet + 新增 D 條 — C-CASE / C-CONV 命名反例)
- §SHOULD (6 sub-bullet + 新增 A / H / I 三條)
- §MAY (unchanged)
- §testing 規範 (新增 sub-section,落 J / L)
- §審查流程 (新增 sub-section,落 F / G / K)
- §Maturity tag 啟用規則 (unchanged)
- §Trigger 規則 (unchanged)
- §範例表 (unchanged)
- Acceptance (5 items + 新增第 6 項 — §testing 規範 + §審查流程 涵蓋 v0.8 對應條文)

### 6.2 9 條落地 routing matrix

每條對應的 Task 2.1 sub-section 已在 v0.7 §v0.8 暫存表 (line 516-529) 明確 frozen,本表只是把 sub-section heading 與 normative 條文骨架明確化:

| 代號 | v0.8 摘要 | v1.0 落點 | Normative 條文骨架 | Illustrative callout 引用 |
|---|---|---|---|---|
| A | Library crate rustdoc 不可引用消費者看不見的設計文件 | §SHOULD 新增 sub-bullet「rustdoc 跨 repo 隔離」 | rustdoc 引用必須消費者看得見;跨 repo internal doc / commit URL / work-tracking-system 條目引用要降級為「以下文件僅供 maintainer」之類 marker,或乾脆刪除 | PR α `<commit-sha>` `she_j1939::pgn::adlink::protocol` 早期 rustdoc 引用 nrg-prototype 內 design doc 已修 |
| D | Helper naming 看 module 既有 identifier 脈絡 | §MUST 內 C-CASE / C-CONV sub-bullet 補命名反例 | helper / private fn 命名須符合 module 既有 identifier 慣例 (同 module 內 `parse_x` / `build_y` pattern 不可混 `do_x` / `make_y`) | PR α `<commit-sha>` `J1939Frame` 內 helper fn 命名 anti-pattern 範例 |
| F | Clippy 機械式 fix 不等於 rustdoc 乾淨 | §審查流程 新增 sub-bullet「lint 與內容審視分層」 | clippy auto-fix 完不代表 rustdoc 語意完整 / API doc 完整性合格;reviewer 必跑手動 §MUST 條目 walk-through | PR α clippy clean 後手動 walkthrough 發現 `# Errors` / `# Safety` 漏寫 |
| G | Holistic file-by-file review 補 commit-by-commit 漏網 issue | §審查流程 新增 sub-bullet「雙重通讀」 | reviewer 須做 commit-by-commit pass + file-by-file 整體 pass 兩輪;前者抓 incremental change correctness,後者抓 cross-commit consistency / dead code / 早期 commit 缺漏 doc | PR α 21 → 5 commit 收斂後 file-by-file pass 發現 4 commit 前的 helper fn 無 rustdoc |
| H | `u32::from_le_bytes` 是表達 byte-order 意圖的 idiomatic 寫法 | §SHOULD 新增 sub-bullet「位元組順序轉換」 | 跨 byte-order boundary 優先用 `u32::from_le_bytes` / `from_be_bytes`,不用手寫 bit shift (後者隱藏 endianness 意圖) | PR α `353e24ae` J1939 ID 解析改用 `from_le_bytes` 範例 |
| I | Spec 多變體時 doc 要明說 covered / not covered | §SHOULD 新增 sub-bullet「spec 覆蓋範圍」 | API doc 對應 spec 多 variant 場景時,明示 `# Covered` / `# Not covered` 或等價段 (`# Spec coverage`)。Silent partial implementation 視為 doc 缺漏 | PR α `J1939Id` `pgn::adlink::protocol` v1.2 PGN 部分 covered / 部分 deferred,doc 補 `# Covered` 段範例 |
| J | Divergence test 是 explanatory overlap,不是 independent regression guard | §testing 規範 新增 sub-bullet「測試目的區分」 | test 寫進 codebase 前須區分 — independent regression guard (獨立 invariant 驗證) vs explanatory overlap (輔助理解特定 behaviour)。後者不算 coverage gain,只是 documentation aid | PR α `frame::tests` 內 divergence test 從 regression guard 重新 framed 為 explanatory overlap 範例 |
| K | Dual sub-agent review 30% overlap + 70% 互補 | §審查流程 新增 sub-bullet「雙視角審查」 | 大型 PR 跑 dual sub-agent review (例 codex + agent B / `/dual-review` skill),兩 agent finding 預期 30% 重疊 (同一 bug 高度顯著) + 70% 互補 (各抓不同類 bug)。0% 重疊表示視角太窄,100% 重疊表示 reviewer profile 太相似 | PR α `/dual-review` 跑 codex + agent B,實際重疊比例範例 |
| L | MIN-1 紅線在 test 同樣適用 | §testing 規範 新增 sub-bullet「MIN-1 引至 test 範疇」 | MIN-1 (不為假設的未來需求寫 code) 在 test code 同樣適用 — 不為假設的 edge case 寫 test;若該 edge case 不在 spec / requirements,不該寫 regression test | PR α `frame::tests` 內 boundary test 從假設的 edge case 砍掉範例 |

### 6.3 9 條落地的 normative + illustrative 兩段格式

每條落地時統一格式:

1. **Normative 條文** (一段 prose,bullet 形式):placeholder 化的規則描述,不含具體 API / commit SHA / nrg-prototype reference
2. **Illustrative callout** (緊接 normative 段下):`> **Illustrative (nrg-prototype PR α <commit-sha>):** ...` blockquote,描述 PR α 該條心得的 lived example。末標「此例為 didactic reference,非通用模板規格」

範例 (H 條):

```markdown
- **位元組順序轉換**: 跨 byte-order boundary 時優先用 `u32::from_le_bytes` /
  `from_be_bytes` 而非手寫 bit shift。Manual shift 隱藏 endianness 意圖,
  reader 必須 inline reason 才能判斷哪邊是 LSB。

  > **Illustrative (nrg-prototype PR α `353e24ae`)**: J1939 ID 解析從手寫
  > `(b[0] as u32) | ((b[1] as u32) << 8) | ((b[2] as u32) << 16) | ((b[3] as u32) << 24)`
  > 改為 `u32::from_le_bytes([b[0], b[1], b[2], b[3]])` 後,intent 一眼可見。
  > 此例為 didactic reference,非通用模板規格。
```

### 6.4 Acceptance 新增第 6 項

Task 2.1 Acceptance 第 1-5 項 unchanged,新增:

```markdown
6. §testing 規範 sub-section 必涵蓋 v0.8 J / L 兩條;§審查流程 sub-section
   必涵蓋 v0.8 F / G / K 三條;§MUST 內 C-CASE / C-CONV sub-bullet 必含
   D 命名反例;§SHOULD sub-bullet 必含 A / H / I 三條。每條 normative +
   illustrative 兩段格式須一致 (per v1.0 spec §6.3)
```

### 6.5 commit SHA 確認 (implementation plan executor 跑)

每條 illustrative callout 內的 PR α commit SHA (`<commit-sha>` placeholder) 由 implementation plan executor 在落地時補實際 SHA。SHA 來源:

- v0.7 line 91 (`29117d7b` PR α HEAD) / line 512 (`ef363dba` PR α v0.8 狀態 HEAD)
- adlink-can anchor spec §7.1 line 374 (`353e24ae` 安全性修正 commit)
- nrg-prototype repo (`~/Projects/fortune_btbu_github_repos/nrg-prototype/`) `tasks.md` §v0.8 待併入清單 (其餘條目 commit SHA;若 tasks.md 已刪則查 PR α 的 git log)

若 implementation 階段 SHA 已遺失 (`tasks.md` 已刪 + git log 已 rewrite),illustrative callout 改寫為「PR α nrg-prototype 自審期間 (provenance reference deferred)」,並在 §9 待解問題標「provenance reference 待補」。

---

## 7. Frontmatter YAML coupling 標記

### 7.1 v1.0 plan 新增 YAML block

v0.7 plan 開頭 (line 1) 目前是 `# Idiomatic Rust 最佳實踐計畫 (2026-04-18)`,沒 YAML frontmatter。v1.0 在 line 1 前插入:

```yaml
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
```

### 7.2 對應 adlink-can 端的 cross-ref

adlink-can anchor spec frontmatter 已有 (per anchor spec line 15):

```
| 跨 spec coupling | 配合通用模板抽象化 spec(待另開於 `~/Projects/claude-code-skills`) ≥ v1.0 |
```

本 v1.0 落地後,anchor spec 該行可改寫為 commit SHA reference (per anchor spec §6.3),由 adlink-can 端 maintainer 同步 (follow-up,§8 動作 #13)。

---

## 8. 落地動作清單 (post-spec,implementation plan 階段做)

| # | 動作 | Repo |
|---|---|---|
| 1 | 在 `references/2026-04-18-idiomatic-rust-plan.md` line 1 前插入 YAML frontmatter (per §7) | claude-code-skills |
| 2 | 依 mapping doc §A.1 163 列跑 systematic substitution (per §2.3 / §3) | claude-code-skills |
| 3 | 改寫 Task 1.3 / 1.4 Acceptance (per §4.4) | claude-code-skills |
| 4 | 改寫 Phase 3 開頭啟動 gate + Acceptance (per §5.2) | claude-code-skills |
| 5 | 改寫 Task 2.1 章節結構,落 9 條 v0.8 (per §6) | claude-code-skills |
| 6 | 改寫 §v0.8 暫存 section 為 §v0.8 落地紀錄 (per §2.4) | claude-code-skills |
| 7 | 升 plan version 號到 v1.0,加 changelog 段「v1.0 相對 v0.7 的主要變動」 | claude-code-skills |
| 8 | Codex review (依 General Workflow 紅線;本檔符合 `*-plan.md` 樣式) | claude-code-skills |
| 9 | 繁中校稿 (依全域 CLAUDE.md trigger #2:`.md` 檔散文正文主要為繁中;手動觸發 `classical-chinese-rules` skill) | claude-code-skills |
| 10 | Commit + push (human-gated) | claude-code-skills |
| 11 | (follow-up) mapping doc §A.1 #104 / #129 註記改「Superseded by state-machine gate」 | adlink-can |
| 12 | (follow-up) mapping doc §B `<consensus-reviewer>` state `provisional` → `landed`,填本 v1.0 §4 維度具體值 | adlink-can |
| 13 | (follow-up) anchor spec frontmatter coupling row 改寫為 commit SHA reference (per anchor spec §6.3) | adlink-can |

---

## 9. 待解問題

- **v0.8 commit SHA reference** (per §6.5):若實作階段 PR α `tasks.md` 已刪 + git log 已 rewrite,illustrative callout 怎麼處理 — 維持「provenance reference 待補」標 vs 改寫 callout 改用 prose 描述 (不引用具體 SHA)。實作階段判定。
- **是否需要 v1.0 round 7 Codex adversarial review**:本 spec 預設不跑 (v0.7 已 escalation out;sweep 非新規格)。但若 sweep 過程出現 design decision 偏離本 spec (例 illustrative callout 邊界 reviewer 判定不一致),可能需 round 7。實作階段判定。
- **adlink-can 端 follow-up 時點**:落地動作 #11-#13 由 adlink-can 端 maintainer 在本 v1.0 land 後執行,具體時點待 adlink-can implementation plan 安排。本 spec 不規定。

---

## 10. Meta

- **Spec scope**:通用模板 plan v0.7 → v1.0 抽象化規範
- **Language**:繁中 (指令、工具名、placeholder 字串、檔案路徑、commit SHA 保留英文)
- **Commit 前要求**:
  - Codex review (依 CLAUDE.md 設計文件紅線;本檔符合 `*-design.md` pattern)
  - 繁中品質審核 (依全域 CLAUDE.md trigger #2:`.md` 檔散文正文主要為繁中)
- **Related**:
  - `rust-coding-standards` skill `references/2026-04-18-idiomatic-rust-plan.md` v0.7 (sweep 對象)
  - adlink-can `docs/superpowers/specs/2026-05-28-idiomatic-rust-anchor-design.md` (上游 anchor spec,§8 #1 觸發本 sweep)
  - adlink-can `docs/coding-standards/idiomatic-rust-mapping.md` (mapping SOT,§A.1 163 列 inventory)
  - adlink-can `docs/superpowers/plans/2026-05-28-idiomatic-rust-anchor-implementation.md` (anchor implementation plan,background reference)
