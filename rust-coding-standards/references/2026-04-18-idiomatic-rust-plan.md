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

> **For agentic workers**: 本檔是計畫與設計合併,不另附獨立設計文件。Phase 執行時建議搭配 `superpowers:executing-plans` skill 一條一條跑。

> **VC / CI 媒介**: 本檔下文出現的 `<vc-ref-mechanism>` (PR review / Issue / comment ack 等媒介) 與 `<ci-platform>` (CI 執行媒介) 由 individual project 在 mapping doc §B 填具體值 (例 Gitea + Gitea CI / GitHub + GitHub Actions / GitLab + GitLab CI 等)。本通用模板不指定具體工具。

**目標**: 透過 Claude Code 達成 Rust 社群公認的最嚴格 Idiomatic Rust 實踐,覆蓋 library crate (`<library-crate>`) 與 embedded binary crate (`<binary-crate>`) 兩側。

**範圍分層**:

- **工具基線** (Phase 1): clippy / fmt / doc / audit / deny 接入工作流程。**不構成 idiomatic Rust 本體**,是前置條件。
- **設計層 review gates** (Phase 2): API Guidelines / error taxonomy / ownership idioms / Embassy async checklist / binary-side idiom gate。這層是 clippy 永遠碰不到的核心。
- **Unsafe / concurrency verification** (Phase 3): miri (host-testable unsafe) + 手動 unsafe audit (binary-side) + Embassy concurrency review。
- **深度閱讀** (Phase 4): 持續性 reviewer 能力養成。
- **計畫把關** (Phase 5): 本計畫自身的 agent review + `<sync-reviewer>` 拍板。

**範圍**: 本專案涉及的 Rust crate — `<library-crate>` (workspace library) 與 `<binary-crate>` (workspace-excluded binary)。不涵蓋其他 crate。

**狀態**: v1.0 通用模板 (2026-05-28 abstraction sweep,per spec `docs/2026-05-28-idiomatic-rust-plan-abstraction-design.md`)。原 v0.7 hard-coded anchor 已抽象化為 placeholder + illustrative example 雙層結構;v0.8 暫存 12 條心得全數落地 (9 條 plan 內 → Task 2.1 sub-section;3 條 plan 外 → 對應 project `CLAUDE.md`;見 §v0.8 落地紀錄)。

**v1.0 相對 v0.7 的主要變動** (2026-05-28 abstraction sweep,per spec `docs/2026-05-28-idiomatic-rust-plan-abstraction-design.md`):

- 163 列 hard-coded anchor 全數抽象化:(a) 80+ 列 → 13 個 placeholder substitution;(b)(d) 46+ 列 → illustrative callout framing;(c) 35+ 列 → repo-neutral prose / `<vc-ref-mechanism>` / `<consensus-reviewer>` 等抽象化
- 新增 YAML frontmatter (audience / version / status / coupling) 標明跨 spec coupling (per spec §7)
- 改寫 Task 1.3 / 1.4 Acceptance,加入 §1B reviewer routing 3 維度分解 (reviewer 集合 / ack 媒介 / 拍板頻率 + 預設策略,per spec §4)
- 改寫 Phase 3 啟動 gate 為 state-machine driven (綁 anchor spec §3.5.1 `<unsafe-targeted-test>` / `<unsafe-binary-side>` state machine,per spec §5);PR β 引用全部移入 illustrative callout
- Task 2.1 章節結構擴展:新增 §testing 規範 / §審查流程 兩個 sub-section;落 v0.8 9 條 plan 內條目 (A 至 SHOULD / D 至 MUST / F G K 至 §審查流程 / H I 至 §SHOULD / J L 至 §testing 規範);Acceptance 加第 6 項
- §v0.8 暫存 section 改寫為 §v0.8 落地紀錄,只留 12 條雙軌落地矩陣 (9 條 plan 內 + 3 條 plan 外),原 atomicity gate / drift-check 移除

**v0.7 相對 v0.6 的主要變動** (round 6 的 1 個結構 finding 落地,並作為 escalation out 前的最後一輪):

- Inventory scan 的 pub item 覆蓋範圍由 7 類 hard-coded enumeration,改為「**crate-externally-visible** `pub` 全種類 non-exhaustive list」,顯式列出 `pub use` / `pub mod` / `pub macro_rules!` / `pub async fn` / `pub unsafe fn` / `pub const fn` / `pub union` 等遺漏種類,並明示排除 `pub(crate)` / `pub(super)` / `pub(in path)` 等 restricted visibility

**v0.6 相對 v0.5 的主要變動** (round 5 的 1 個結構 finding 落地):

- Script spec 從 diff-based scan 改為**全庫 inventory scan**。原因: diff-based 只涵蓋新增 `pub` 行,漏掉「changed pub item」(簽名變、visibility promotion、doc 改但 `pub` 行未動)。全庫掃描 cost < 1 秒 (`<library-crate>` pub 項 < 100),換取 scope 完整涵蓋 new / changed / pre-existing 三類

**v0.5 相對 v0.4 的主要變動** (round 4 的 2 個 P1 finding 全數落地,皆聚焦在 R3-2 API maturity tag enforcement 實作):

- v0.4 的 awk one-liner 已驗證為錯誤實作 (hunk-wide flag 誤判 + 未處理 EOF),**從 plan 移除**,改寫為 `scripts/check-api-maturity-tags.sh` 的 behaviour spec,實作由 Task 1.6 同批產出
- Task 2.1 Acceptance 從 4 項增至 5 項,第 5 項明確 bind: 必須存在 `check-api-maturity-tags.sh` + pass / fail fixture
- Task 1.6 Acceptance 第 4 項新增: 一併產出 `check-api-maturity-tags.sh`

**v0.4 相對 v0.3 的主要變動** (round 3 的 4 個 finding 全數落地):

- Cross-task bug routing table 改為 **primary owner + backlink** 結構,嚴守「每列單一 primary owner」規則;L151 `UnsafeCell` 共享 / L156 `From` vs `TryFrom` 的 dual-owner 問題修正
- Task 2.3 vs Task 3.5 在 Send / Sync 上的分工釘清: 2.3 負責 documentation,3.5 負責 runtime correctness (兩處 scope 段都加釐清 bullet)
- API maturity tag 從「建議」升級為「強制 + 可 grep 檢查」: 無 silent default、格式固定、附可執行 shell 檢查、Task 2.1 acceptance 必跑
- Task 1.1 clippy 命令改用 `--manifest-path` 格式 (workspace-excluded crate 不能用 `-p`)
- Task 1.2 fixture 從 `docs/_test_broken.md` 改成 crate rustdoc 內的 broken intra-doc link (`cargo doc` 實際偵測路徑)

**v0.3 相對 v0.2 的主要變動** (round 2 的 7 個 finding 全數落地):

- Task 2.4 / 3.3 / 3.5 邊界重劃: 2.4 專注 `.await` 點局部 obligations,3.5 專注跨 context interleaving / ordering / affinity,3.3 只留 meta-policy
- 新增「跨 Task bug routing 表」以具體 bug 範例釘每個 concern 的 canonical home
- Acceptance 全部改寫成可檢驗 (required heading / mandatory example count / testable outcome / explicit fixtures)
- 權威性 crosswalk 補 Task 2.5 (binary-idioms) 與 Task 3.5 (concurrency) 列,且自 day 0 inline authoritative;Task 2.7 降為 follow-up 整合,不再擋 Phase 2 前置
- 新增「API maturity tag」章節 (`stable public` / `workspace-internal pub` / `temporary pub`),Task 2.1 的 MUST / SHOULD 綁 tag,解決 MIN-1 vs future-proof 建議的長年拉扯
- 新增「Ownership concern canonical home 表」,Send / Sync、ISR handoff、static / executor ownership 各指定唯一 owner,其他 task 只 link 不 restate
- Trigger example path 統一 `<library-crate-paths>` / `<binary-crate-paths>`
- 新增 Appendix A「Round 1 closeout matrix」+ Appendix B「Round 2 closeout matrix」,讀者可據此稽核每個 finding 是否真正落地

---

## 背景

2026-04-18 的討論「`cargo clippy` 足以達到嚴格 idiomatic Rust 嗎?」結論: **不足**。即使開到本專案 workspace 的 `-D pedantic -D nursery` (`Cargo.toml:209-210`) 都只是規則引擎層天花板,設計層 (API 設計、error taxonomy、ownership idiom、unsafe soundness、async idiom、typestate、並發選型) clippy 幾乎都碰不到。

Codex round 1 adversarial review (2026-04-18) 指出 v0.1 的三個結構盲點,v0.2 補齊後 Codex round 2 再指出 7 個待處理問題,v0.3 全數落地。詳細 closeout 見 Appendix A / B。

---

## 現況盤點

### Clippy 層

- `Cargo.toml:209-210` 的 `[workspace.lints.clippy]`:
  - `nursery = { level = "deny", priority = -1 }`
  - `pedantic = { level = "deny", priority = -1 }`
- `<library-crate-paths>Cargo.toml` 有 `[lints] workspace = true`,繼承 workspace 設定
- `<binary-crate-paths>` 排除在 workspace 外 (per-package-target 限制),workspace lints 不套用;需 crate 自己的 `[lints.clippy]` 跟上 (Task 1.1)

### Unsafe 分佈

全專案 `unsafe` 共 6 處:

| 位置 | 用途 | Host-testable | Phase 3 對應 |
|------|------|--------------|---------------|
| `<library-crate-paths>` `<unsafe-targeted-test>` | unsafe wrapper (見下方 illustrative) | Yes (conditional no_std) | miri targeted test (Task 3.1) |
| `<binary-crate-paths>` `<unsafe-binary-side>` (heap init) | Heap 初始化 | No | unsafe-audit.md (Task 3.4) |
| `<binary-crate-paths>` `<unsafe-binary-side>` (ISR decl 1) | I2C1_ER interrupt handler decl | No | unsafe-audit.md + concurrency review (Task 3.5) |
| `<binary-crate-paths>` `<unsafe-binary-side>` (on_interrupt 1) | `EXECUTOR_HIGH.on_interrupt()` | No | 同上 |
| `<binary-crate-paths>` `<unsafe-binary-side>` (ISR decl 2) | I2C1_EV interrupt handler decl | No | 同上 |
| `<binary-crate-paths>` `<unsafe-binary-side>` (on_interrupt 2) | `EXECUTOR_MEDIUM.on_interrupt()` | No | 同上 |

Host-testable 只有 1/N (`<unsafe-targeted-test>`)。其餘 N-1 處 Phase 3 用手動 audit + Embassy concurrency review。

> **Illustrative (nrg-prototype)**: Host-testable 1 處為 `crates/lib/she_j1939/src/frame.rs:44` 的 `ExtendedId::new_unchecked` wrapper;其餘 5 處為 `she_bms_masterboard` 的 heap init / ISR handler。個別專案的 unsafe 分佈由 Phase 3 audit 確認。此例為 didactic reference,非通用模板規格。

### 第一個試跑 PR (concept)

通用模板的 Phase 1 落地後,個別專案的第一個進入新 pipeline 的 PR 可作為 Phase 2 試跑樣本回頭補 audit (不阻擋 push)。

> **Illustrative (nrg-prototype PR α `29117d7b`)**: PR α (HEAD `29117d7b`,10 commits,未 push) 是 nrg-prototype 第一個經過新 pipeline 的 PR;Task 2.6 audit 對 PR α `<library-crate>::pgn::adlink::protocol` 新 module + `J1939Id::from_raw` / `to_raw` 跑 checklist 試跑。此例為 didactic reference,非通用模板規格。

---

## 六層驗證 pipeline

把 `cargo clippy` 的嚴格設定視為「第 2 步」,目標推到第 6 步:

| 步 | 工具 / 流程 | 當前狀態 |
|---|-----------|---------|
| 1 | `cargo clippy --all-targets` (default lint) | 已跑 |
| 2 | `+ -D pedantic -D nursery` | **本專案目前位置** (library 側;binary 側待 Task 1.1) |
| 3 | `+ cargo fmt --check` + `cargo doc -D rustdoc::broken_intra_doc_links -D rustdoc::invalid_rust_codeblocks` | CLAUDE.md 已寫但還沒接 hook |
| 4 | `+ cargo audit` + `cargo deny check` (+ `cargo semver-checks` 略過) | `cargo audit` 月度,`cargo deny` 未設 |
| 5 | **Unsafe / concurrency verification** — miri (host-testable unsafe) + `unsafe-audit.md` (binary-side) + Embassy concurrency checklist | 未評估 |
| 6 | **設計層 review gates** — Rust API Guidelines + error taxonomy + ownership idioms + Embassy async checklist + binary-side idiom gate | 無 |

補齊第 3 ~ 6 步是本計畫的核心目標。

---

## 權威性 crosswalk (inline, day-0 authoritative)

Phase 2 新增的審查準則可能與既有 MIN / MOD / CC 紅線在同一次審查互相牴觸 (例如 API future-proofing vs MIN-1「不為假設的未來需求寫 code」)。審查者遇到衝突時依下表判斷權威來源。此表從計畫 day 0 就 authoritative,所有 Phase 2 / Phase 3 checklist 實作時必須同步更新這份表 (Task 2.7 改為後續「抽出獨立文件」的整合工作,不再是 Phase 2 前置)。

| 主題 | Authoritative | 次要 / 補充 | 衝突解法 |
|------|--------------|-------------|---------|
| 抽象 / 泛型化時機 | **MIN-1 / MIN-4** (minimalism) | API Guidelines C-GENERIC / C-SMART-PTR | MIN 禁止「為假設需求」抽象;只有現有 ≥2 處重複且語意相等時才抽。API Guidelines 推薦的 future-proof 模式 (sealed trait / non_exhaustive) 僅對 API maturity tag = `stable public` 才強制 |
| 模組依賴方向 | **MOD-1** (內層不 import 外層) | API Guidelines visibility convention | MOD-1 先 |
| 函式長度 / 巢狀 | **CC2 / CC9** | — | CC 先 |
| 命名 / case / convention | **API Guidelines C-CASE / C-CONV** | CC naming | API Guidelines 先 |
| Error handling 顯式性 | **CC7** + error taxonomy policy (Task 2.2) | API Guidelines C-GOOD-ERR | CC7 要求 explicit,taxonomy policy 決定 enum 形狀 |
| `# Errors` / `# Panics` / `# Safety` doc | **API Guidelines C-FAILURE / C-SAFETY** | CC doc conventions | API Guidelines 先 |
| 公開型別 auto-trait (Send / Sync) justification | **Task 2.3 ownership-idioms** (canonical home) | API Guidelines C-SEND-SYNC | 每個 `stable public` / `workspace-internal pub` 型別都要 explicit 論證;盲目 MUST 已棄用 |
| 局部 `.await` 點 cancellation safety | **Task 2.4 embassy-async-checklist** | Embassy Book | 對應每個 `.await` 點的 local obligation,不涉及跨 context 互動 |
| 跨 context interleaving / ordering / affinity | **Task 3.5 embassy-concurrency-review** | Rustonomicon 並發章節 | ISR ↔ task、wakeup ordering、executor affinity、`Send` / `Sync` 跨邊界 |
| Concurrency 工具可行性 meta-policy | **Task 3.3 concurrency-verification** | loom / miri docs | 不定義個別規則,僅說明為何 loom 不直接適用與三層替代管控的關係 |
| Binary-side idiom (heapless / feature gating / panic handler) | **Task 2.5 binary-idioms-checklist** | — | 對 `<binary-crate-paths>` 內部 PR 的可實作標準;unsafe soundness 仍由 Task 3.4 主導 |
| Binary-side unsafe soundness | **Task 3.4 unsafe-audit.md** | Rustonomicon | per-block justify,與 Task 3.5 交互引用 |

---

## Ownership concern canonical home

v0.2 有數項 concern (Send / Sync、ISR handoff、static / executor ownership) 同時出現在三個以上 task 的範圍描述,造成 reviewer 不知到底該在哪個 checklist 處理 bug。以下表釘每項 concern 的 canonical home,其餘 task 只 link,**不**重述規則。

| Concern | Canonical home | 引用方式 |
|---------|---------------|----------|
| Public type `Send` / `Sync` / `!Send` / `!Sync` justification | **Task 2.3** (`ownership-idioms.md`) | Task 2.4 與 3.5 在範圍描述處以 "see Task 2.3 §auto-trait" 引用,不複述格式 |
| Local `.await` cancellation safety + drop invariants | **Task 2.4** (`embassy-async-checklist.md`) | Task 3.5 在跨 context 範例裡若需要 local 論證,cite Task 2.4 |
| ISR ↔ task handoff pattern (wakeup ordering、interleaving 假設) | **Task 3.5** (`embassy-concurrency-review.md`) | Task 2.4 在 checklist 不重述跨 context;Task 3.4 unsafe-audit cite Task 3.5 |
| `static` Executor lifetime、`#[interrupt]` handler ownership、可重入性 | **Task 3.4** (`unsafe-audit.md`) | Task 3.5 cite Task 3.4 做 soundness proof,不複述 |
| `no_std` 環境 heapless / const-generic buffer sizing、feature gating | **Task 2.5** (`binary-idioms-checklist.md`) | 與 Task 3.4 互引 (unsafe audit 看 soundness,binary idioms 看風格) |
| Concurrency 工具可行性 meta-policy | **Task 3.3** (`concurrency-verification.md`) | 不 host 個別規則,只說明 loom 不適用與三層替代管控機制 |

---

## API maturity tag

為解決 MIN-1 (minimalism) 與 API Guidelines future-proof 建議之間長期的拉扯,本計畫導入 API maturity tag。每個 `pub` item 都要在 rustdoc 裡以 `<!-- api-maturity: <tag> -->` 註記,Task 2.1 checklist 的 MUST / SHOULD 分級依 tag 啟用。

| Tag | 定義 | 範例 | MUST 啟用範圍 |
|-----|------|------|---------------|
| `stable public` | 已確認會對外發布或跨組消費,semver 承諾已 establish | 未來 `<library-crate>` 若 publish 到 crates.io 或外部直接 link | 完整 API Guidelines MUST + SHOULD (含 sealed trait / `non_exhaustive` / `From` / `TryFrom` 對稱性) |
| `workspace-internal pub` | `pub` 但消費者只在 workspace 內 (現 `<library-crate>` 大部分 API 屬此類) | 由 mapping doc §B 填 | API Guidelines MUST (命名、Debug、`# Errors` / `# Panics` / `# Safety`、`Clone` / `Default` 立場);future-proof 項目 (sealed trait / `non_exhaustive` / smart-pointer conversion) 降為 SHOULD,待 tag 升級到 `stable public` 才 MUST |
| `temporary pub` | 短期過渡 (為了測試或 migration 暫時 `pub`),commit 必須附刪除計畫 | 過渡期間的 `pub(crate)` 擴展成 `pub` | API Guidelines 全降為 MAY;必須有 TODO comment + issue 追蹤 deprecation |

> **Illustrative (nrg-prototype workspace-internal pub)**: `J1939Id::from_raw` / `to_raw` / `pgn::adlink::protocol::*` 是 nrg-prototype 的 `workspace-internal pub` 典型範例。個別專案的對等 API 清單由 mapping doc §B 填入。此例為 didactic reference,非通用模板規格。

**綁定規則** (v0.4 強化,Task 2.1 checklist 必帶此規則):

- **Mandatory tagging**: 每個 new / changed `pub` item 必須顯式標 tag,**無預設降級**。未標 tag = Task 2.1 acceptance 直接 fail
- **Syntax**: tag marker 必須緊鄰 `pub` item 的 rustdoc,格式 `<!-- api-maturity: <stable public | workspace-internal pub | temporary pub> -->` (中間 tag 字串完整一致,不得縮寫)
- **Executable enforcement** (Task 2.1 acceptance 必跑): 由 `scripts/check-api-maturity-tags.sh` 執行,script spec 如下 (實作由 Task 1.6 同批產出)。**採全庫 inventory scan,不用 diff-based** — v0.5 已驗證 diff-based 無法涵蓋「changed pub item」(簽名變、visibility promotion `pub(crate)` → `pub`、doc 改但 `pub` 行未動) 的情境;v0.4 的 awk 實作也在 round 4 已驗證為錯誤 (hunk-wide flag 誤判 + 未處理 EOF),兩者皆**移除不用**:
  - **Full inventory scan**: script 對 `<library-crate-paths>` 所有 source file 內**所有 crate-externally-visible** `pub` item 逐項掃描 (`<library-crate>` pub 項 < 100,全掃成本可忽略,執行 < 1 秒)。覆蓋種類**不限於但至少包含**:
    - `pub fn` / `pub async fn` / `pub unsafe fn` / `pub const fn`
    - `pub struct` / `pub enum` / `pub union` / `pub trait`
    - `pub const` / `pub static`
    - `pub type` (type alias)
    - `pub use` (re-export — 必檢,因為 re-export 是 public API surface)
    - `pub mod` (module declaration — 必檢,子樹內的 pub item 皆可由此 module path 訪問)
    - `pub macro_rules!` / `pub macro` (macro export)
    - 其他未來 Rust edition 引入的 `pub` 形式
  - **排除**: `pub(crate)` / `pub(super)` / `pub(in path)` 等 restricted visibility **不**計為 crate-externally-visible,不需 marker。若 reviewer 把 `pub(crate)` promote 為 `pub`,全庫掃描下次執行就會抓到
  - **Per-item marker check**: 每個 pub item 的定義行**前 10 行**必須存在正則 `<!-- api-maturity: (stable public|workspace-internal pub|temporary pub) -->` 的 match
  - **Output contract**: 缺失 marker 的 item 以 `file:line: missing api-maturity marker (kind=<pub_kind>, name=<item_name>)` 格式 print 到 stderr;最後 exit code 非 0 且列出缺失總數。全部符合則 exit 0 無輸出
  - **Scope coverage**: 全庫掃描涵蓋 new / changed / pre-existing 三種 pub item,不依 diff,不漏「changed pub item」
  - **觸發時機**: pre-commit hook + PR CI 都跑 (成本 < 1 秒,不影響 developer feedback loop);另建議 nightly inventory report
  - **實作語言**: bash + `rg` 或 Python,由 Task 1.6 決定,但 behaviour spec 依此文件
- **Tag 升級** (`workspace-internal pub` → `stable public`): 需在 PR description 明確提及 + 獨立 commit (不與 API 新增混在同一 commit)
- **Temporary pub deprecation**: 每個 `temporary pub` item 必須在 `<vc-ref-mechanism>` 開對應 issue,issue number 寫在 rustdoc 的 `<!-- api-maturity-deprecation: #NNNN -->` 第二個 marker

---

## Cross-task bug routing

為避免 reviewer 把同一個 bug 重複登在多個 checklist,或該 bug 無人認領,以下列出 Phase 2 / Phase 3 共同範圍的常見 bug pattern 與其 **primary owner**。

**Ownership 規則** (v0.4 釐清): 每一列只有**一個 primary owner**。若某 bug 的修正會連帶觸發其他 task 的副作用 (例如 primary owner 是 Task 3.5 但連帶需要 Task 3.4 補 in-code `// Safety:` 註解),寫在「Backlink (mandatory cross-ref)」欄,不是 co-ownership。Review 的判斷、簽核、acceptance 依 primary owner,backlink 只是必須補的交叉引用,不分攤責任。

| Bug pattern (具體範例) | Primary owner | Backlink (mandatory cross-ref) |
|-----------------------|---------------|-------------------------------|
| `task_A` 的 `signal.wait().await` 在 `.await` 中途取消 (future drop),`signal` 是否留下 pending-but-unwaited state | **Task 2.4** (local cancellation safety) | — |
| `async fn foo(&mut self)` 跨越 `.await`,`self` 是 `static` 單例 | **Task 2.4** (local `.await` 點 drop + Pin 義務) | — |
| ISR 在 `task_A.await` 時觸發,`channel.try_send` 後 `task_A` 醒來讀到 unexpected value | **Task 3.5** (ISR ↔ task interleaving) | — |
| 兩個 task 競爭 poll 同一 `Channel`,wakeup ordering 決定誰先贏 | **Task 3.5** (wakeup ordering) | — |
| ISR 和 task 共享 `UnsafeCell<T>`,無 atomic 或 適當的同步 primitive 包裹 | **Task 3.5** (跨 context Send / Sync correctness) | Task 3.4 (`// Safety:` in-code 註解必須 cite 3.5 finding ID) |
| `#[embassy_executor::task]` 簽名是否符合慣例 (例如 static borrow vs owned) | **Task 2.4** (local state obligations) | — |
| `static` Executor 生命週期 + `#[interrupt]` handler ownership 是否合格 | **Task 3.4** (unsafe-audit.md soundness) | — |
| `<library-crate>` 的 workspace-internal pub API 是否有 `# Errors` + `impl Debug` + `#[must_use]` | **Task 2.1** (API Guidelines MUST) | — |
| public `struct` 欄位加了 `pub` 而非 getter | **Task 2.1** + tag 升級評估 | — |
| `AckFrame` 新增 variant 該用 `From` 還是 `TryFrom` | **Task 2.2** (error taxonomy — 先決定 fallible 與否) | Task 2.3 (conversion idiom — 依 2.2 結論選型) |
| `<binary-crate>` 的 `static FOO: Mutex<...> = Mutex::new(...)` buffer 大小用 magic number | **Task 2.5** (binary-idioms: heapless / const-generic buffer sizing) | — |

> **Illustrative (nrg-prototype embedded crate stack)**: nrg-prototype 對「適當的同步 primitive」的具體選擇為 `critical-section` crate (Embassy 跨 context atomic 邊界)。此例為 didactic reference,非通用模板規格。

Task 2.4 與 Task 3.5 的分界原則: **一個 `.await` 點內部看得到的義務 → 2.4;超越該 `.await` 點、需要考慮同時存在的其他 context → 3.5**。

Task 2.3 與 Task 3.5 在 Send / Sync 上的分工 (v0.4 釐清): **Task 2.3 負責「public type 的 Send / Sync justification documentation」(靜態 API doc 的完整度)**;**Task 3.5 負責「跨 context runtime correctness」(實際 interleaving / ordering 下 Send / Sync 是否真的成立)**。前者是 doc completeness,後者是 behavioural correctness,兩者都需,但一次 review 只歸一個 owner。

---

## Phase 分期

### Phase 1 — 工具基線 (1A 本週;1B 視 `<sync-reviewer>` 決策時間)

Target: 把 pipeline 第 3-4 步完整接入工作流程,讓 commit 前 checklist 不再掛漏。拆成 1A / 1B 兩組,避免外部決策拖住可獨立落地部分。

**1A — 可獨立落地 (不需跨人共識)**:

- [ ] **Task 1.1**: 確認 `<binary-crate-paths>Cargo.toml` 的 `[lints.clippy]` 跟 workspace 對齊 (因為排除在 workspace 外,workspace lints 不自動套用)。若沒對齊,補上 `nursery = deny` + `pedantic = deny`。
  - **Acceptance** (必須三項全過才算完成):
    1. `cargo clippy --manifest-path <binary-crate-paths>Cargo.toml --all-targets -- -D warnings` 退出碼 0 (注意: 因為 `<binary-crate>` 是 workspace-excluded,**不可**用 `-p <binary-crate>`,必須 `--manifest-path`)
    2. 任何 `#[allow(...)]` 必須附註單行 justification (grep `#\[allow` 每個 hit 都有 `// reason:` 下一行)
    3. `Cargo.toml` diff 加入 PR,在 `<vc-ref-mechanism>` 有留 `ack` 或 emoji ack
- [ ] **Task 1.2**: `cargo doc -D rustdoc::broken_intra_doc_links -D rustdoc::invalid_rust_codeblocks` 落到 pre-commit 腳本。
  - **Acceptance**:
    1. `scripts/` 存在 pre-commit hook 檔,內容包含上述 command
    2. 測試 fixture (必須在 `cargo doc` 偵測範圍內,不可用 `docs/_test_broken.md` 這種非 rustdoc 檔): 在 `<library-crate-paths>lib.rs` 或任一 `pub` item 的 rustdoc 內加一個刻意 broken 的 intra-doc link (例如 `//! [`NonexistentType`]`),執行 `cargo doc` 應報 error,hook 應擋下 `git commit`;測試完成後 revert fixture
    3. CLAUDE.md §Rust verification checklist 對應段落的指令與腳本一致 (diff 對比)
- [ ] **Task 1.5**: **略過** `cargo-semver-checks`。理由 (internal crate 不發布 crates.io) 寫進 CLAUDE.md 略過清單。
  - **Acceptance**: CLAUDE.md 略過清單該條存在,含一句具體理由 (不只「無意義」)
- [ ] **Task 1.6**: 產出 `scripts/rust-quality-check.sh`。介面拆成兩段避免工具語義錯配:
  - `--crate <name>`: 跑 `fmt / test-or-check / clippy / doc` (per-crate)
  - `--workspace-policy`: 跑 `audit / deny` (workspace-level,不做 per-crate 假裝)
  - `<binary-crate>` 是 workspace-excluded,只吃 `--crate` 不吃 `--workspace-policy`
  - **Acceptance**:
    1. 腳本存在且 `bash -n scripts/rust-quality-check.sh` 語法檢查過
    2. 4 種情境實測: `--crate <library-crate>` 成功 / `--crate <binary-crate>` 成功 / `--workspace-policy` 成功 / `--crate <binary-crate> --workspace-policy` 必須退出碼 2 + stderr 印錯誤訊息
    3. 每種情境 exit code 表記在 `README.md` §rust-quality-check
    4. **一併產出 `scripts/check-api-maturity-tags.sh`** (Task 2.1 Acceptance 第 5 條會用到): behaviour spec 依 §API maturity tag 的 executable enforcement 段。Task 1.6 只負責實作 + 語法檢查 (`bash -n`),功能性 pass/fail fixture 驗證在 Task 2.1 做

**1B — 需共識 (不擋 1A 落地)**:

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

- [ ] **Task 1.4**: 評估 `cargo deny check` (workspace 層,license / duplicate / banned deps)。需跟 `<consensus-reviewer>` 共識。
  - **Acceptance**:
    1. `<consensus-reviewer>` 合入 project `Cargo.toml` 的 `[workspace.metadata.deny]` 段落,或在 `<vc-ref-mechanism>` 留下明確同意 / 拒絕 ack
    2. 頻率決策 (PR 級 / 月度) 寫進 project `CLAUDE.md`,引用拍板 ack URL / SHA
    3. **§1B reviewer routing** 同 Task 1.3 (per v1.0 §3.5.4,3 維度 + 預設策略)

  > **Illustrative (nrg-prototype PR α 期間)**: `<consensus-reviewer>` 預期填 Vincent,合入 `nrg-prototype/Cargo.toml` 由 Vincent 主導。此例為 didactic reference,非通用模板規格。

**交付物**:

- `scripts/rust-quality-check.sh` (1A)
- CLAUDE.md 更新 Rust verification checklist (月度 → PR 級標註,依 1B 結果)
- 共識達成後的 `cargo deny` workspace 設定 (1B)

**Agent review**: Codex adversarial 審查腳本可移植性與 exit code 處理。

---

### Phase 2 — 設計層 review gates (接下來 2-3 週)

Target: 把 pipeline 第 6 步建出來。clippy 永遠取代不了的設計層。

**v0.3 邊界重劃**:

- Task 2.4 = 單一 `.await` 點的 local state-machine obligations (cancellation safety / drop / Pin 義務)
- Task 3.5 = 跨 context 的 interleaving / ordering / affinity (見 Phase 3)
- Task 3.3 = concurrency 工具的 meta-policy 論述,不重述個別 bug 規則
- 重複出現在多個 task 的 concern (Send / Sync、ISR handoff、static ownership) 已抽到「Ownership concern canonical home」表,每個 task 只 link 不 restate

- [ ] **Task 2.1**: **Rust API Guidelines checklist** (`<library-crate>` public API gate)。從 `https://rust-lang.github.io/api-guidelines/checklist.html` 擷取全項,依本專案適用性分三級;**MUST / SHOULD 的啟用範圍綁定 API maturity tag** (見 §API maturity tag)。
  - **觸發範圍**: library crate (`<library-crate-paths>`) 的 new / changed `pub` item。Binary-only PR 不觸發此層。
  - **MUST** (library 對外 API 必檢;`workspace-internal pub` 以上啟用): 命名 (C-CASE / C-CONV)、`#[must_use]` (C-MUST-USE)、doc 章節規範 (`# Errors` / `# Panics` / `# Safety`)、`impl Debug` (C-DEBUG)、公開型別對 `Clone` / `Default` 的 explicit 立場
  - **命名一致性 (v0.8 D)**: helper / private fn 命名須符合 module 既有 identifier 慣例 (同 module 內 `parse_x` / `build_y` pattern 不可混 `do_x` / `make_y`)

    > **Illustrative (nrg-prototype PR α `422692a5`)**: `J1939Frame` module 內 helper fn 命名 anti-pattern 範例 — 原 helper fn 用 `do_parse_*` 與 module 既有 `parse_*` 不一致,review 後改齊。此例為 didactic reference,非通用模板規格。

  - **SHOULD** (對外 API 推薦;`stable public` 啟用,`workspace-internal pub` 可豁免): sealed trait、`non_exhaustive`、`From` / `TryFrom` 對稱性、`AsRef` / `Borrow` 正確選擇、iterator adaptors、smart-pointer conversion
  - **rustdoc 跨 repo 隔離 (v0.8 A)**: rustdoc 引用必須消費者看得見;跨 repo internal doc / commit URL / work-tracking-system 條目引用要降級為「以下文件僅供 maintainer」之類 marker,或乾脆刪除

    > **Illustrative (nrg-prototype PR α `422692a5`)**: `she_j1939::pgn::adlink::protocol` 早期 rustdoc 引用 nrg-prototype 內 design doc,ADLINK 套用時看不到 — 已修。此例為 didactic reference,非通用模板規格。

  - **位元組順序轉換 (v0.8 H)**: 跨 byte-order boundary 優先用 `u32::from_le_bytes` / `from_be_bytes`,不用手寫 bit shift (後者隱藏 endianness 意圖,reader 必須 inline reason 才能判斷哪邊是 LSB)

    > **Illustrative (nrg-prototype PR α `353e24ae`)**: J1939 ID 解析從手寫 `(b[0] as u32) | ((b[1] as u32) << 8) | ((b[2] as u32) << 16) | ((b[3] as u32) << 24)` 改為 `u32::from_le_bytes([b[0], b[1], b[2], b[3]])`,intent 一眼可見。此例為 didactic reference,非通用模板規格。

  - **spec 覆蓋範圍 (v0.8 I)**: API doc 對應 spec 多 variant 場景時,明示 `# Covered` / `# Not covered` 或等價段 (`# Spec coverage`)。Silent partial implementation 視為 doc 缺漏

    > **Illustrative (nrg-prototype PR α `422692a5`)**: `J1939Id` `pgn::adlink::protocol` v1.2 PGN 部分 covered / 部分 deferred,doc 補 `# Not covered` 段範例。此例為 didactic reference,非通用模板規格。

  - **MAY** (特定情境): builder pattern、custom derive、cfg-gated feature
  - **§testing 規範** (v0.8 J / L 落地):

    - **測試目的區分 (v0.8 J)**: test 寫進 codebase 前須區分 — independent regression guard (獨立 invariant 驗證) vs explanatory overlap (輔助理解特定 behaviour)。後者不算 coverage gain,只是 documentation aid

      > **Illustrative (nrg-prototype PR α `1a618e61`)**: `frame::tests` 內 rejection test 原 framed 為 regression guard,review 後重新 framed 為 explanatory overlap (該 test 本質是輔助理解 `J1939Frame::new` 與 rejection contract 兩種建構路徑分歧)。此例為 didactic reference,非通用模板規格。

    - **MIN-1 引至 test 範疇 (v0.8 L)**: MIN-1 (不為假設的未來需求寫 code) 在 test code 同樣適用 — 不為假設的 edge case 寫 test;若該 edge case 不在 spec / requirements,不該寫 regression test

      > **Illustrative (nrg-prototype PR α `provenance reference deferred`,待 tasks.md 歷史回溯)**: `frame::tests` 內 boundary test 原寫了假設的 max ID + 1 edge case (J1939 spec 未要求),review 後砍掉。此例為 didactic reference,非通用模板規格。

  - **§審查流程** (v0.8 F / G / K 落地):

    - **lint 與內容審視分層 (v0.8 F)**: clippy auto-fix 完不代表 rustdoc 語意完整 / API doc 完整性合格;reviewer 必跑手動 §MUST 條目 walk-through

      > **Illustrative (nrg-prototype PR α `422692a5`)**: PR α clippy clean 後手動 walkthrough 發現 `# Errors` / `# Safety` 漏寫,clippy 沒抓到因為兩者屬 doc-completeness 而非 lint 範疇。此例為 didactic reference,非通用模板規格。

    - **雙重通讀 (v0.8 G)**: reviewer 須做 commit-by-commit pass + file-by-file 整體 pass 兩輪;前者抓 incremental change correctness,後者抓 cross-commit consistency / dead code / 早期 commit 缺漏 doc

      > **Illustrative (nrg-prototype PR α `422692a5`)**: PR α 21 → 5 commit 收斂後 file-by-file pass 發現 4 commit 前的 helper fn 無 rustdoc (commit-by-commit pass 漏)。此例為 didactic reference,非通用模板規格。

    - **雙視角審查 (v0.8 K)**: 大型 PR 跑 dual sub-agent review (例 codex + agent B / `/dual-review` skill),兩 agent finding 預期 30% 重疊 (同一 bug 高度顯著) + 70% 互補 (各抓不同類 bug)。0% 重疊表示視角太窄,100% 重疊表示 reviewer profile 太相似

      > **Illustrative (nrg-prototype PR α `422692a5`)**: PR α `/dual-review` 跑 codex + agent B,實際重疊比例範例 — codex 抓多條 finding / agent B 抓多條 finding / 兩者重疊約 25-33%。此例為 didactic reference,非通用模板規格。

  - **Acceptance** (必須六項全過):
    1. 產出 `docs/coding-standards/rust-api-guidelines-checklist.md`
    2. 文件含固定 section headings: `## MUST`、`## SHOULD`、`## MAY`、`## Maturity tag 啟用規則`、`## Trigger 規則`、`## 範例表`
    3. `## 範例表`下,每個三級項**至少一個** `<library-crate>` pass 範例 + 一個 fail 範例 (或標 `[pending: 待 Task 2.6 試跑累積]`,不得空白)
    4. `## Trigger 規則` 段有 diff pattern 的 shell one-liner 範例 (例如 `git diff --name-only ... | grep '^<library-crate-paths>' && git diff | grep -qE '^\+.*pub '`)
    5. **API maturity tag checker 綁定** (R4-1 / R4-2 修正): `scripts/check-api-maturity-tags.sh` (spec 見 §API maturity tag 的 executable enforcement) 必須存在,且 Task 2.1 文件的 `## Maturity tag 啟用規則` 段附兩個 fixture:
       - **Pass fixture**: 一個 new `pub` item,上方 10 行內有合法 marker。Checker 預期輸出為空,exit code 0
       - **Fail fixture**: 一個 new `pub` item,上方 10 行內無 marker。Checker 預期輸出該 item 的 `file:line: missing api-maturity marker`,exit code 非 0
       - Fixture 以 before/after code block 呈現在文件中,不需要真的在 repo 留 broken code
    6. §testing 規範 sub-section 必涵蓋 v0.8 J / L 兩條;§審查流程 sub-section 必涵蓋 v0.8 F / G / K 三條;§MUST 內 C-CASE / C-CONV sub-bullet 必含 D 命名反例;§SHOULD sub-bullet 必含 A / H / I 三條。每條 normative + illustrative 兩段格式須一致 (per v1.0 spec §6.3)
- [ ] **Task 2.2**: **Error taxonomy policy**。定義本專案的 error 設計策略。
  - **範圍**: `<library-crate>` public errors / `<binary-crate>` internal errors 各自的 policy
  - **決策要點**: 用 `thiserror` 還是手寫 enum / 何時用 typed enum 而非 anyhow-style / `no_std` 如何處理 error context / 跨越 boundary (hardware → application) 時的 error 轉換策略
  - **Acceptance**:
    1. 產出 `docs/coding-standards/error-taxonomy.md`,含 section: `## Library 公開 error` / `## Binary 內部 error` / `## Cross-boundary 轉換` / `## 與 CC7 互補`
    2. 每個 section 至少一個 `<library-crate>` 或 `<binary-crate>` 現存或預定範例 (不接受純敘述)
    3. 明確寫出 2 個以上 `thiserror` 使用時機 + 2 個以上不使用時機
- [ ] **Task 2.3**: **Ownership & conversion idioms**。定義公開 API 的 ownership 慣例與 auto-trait justification。此為 Send / Sync justification 的 canonical home (見 §Ownership concern canonical home)。
  - **範圍**: `&T` vs `T` vs `Cow<T>` param 選擇、`AsRef` / `Borrow` / `Into` / `From` 使用界線、`to_owned` vs `into_owned` 的 builder 慣例、iterator 回傳 vs collection 回傳、auto-trait (`Send` / `Sync` / `Unpin`) explicit justification 要求
  - **Acceptance**:
    1. 產出 `docs/coding-standards/ownership-idioms.md`,section: `## 參數 ownership` / `## Conversion 選型` / `## Auto-trait justification`
    2. `## Auto-trait justification`提供 code review note 的固定範本 (range:固定 bullets `- 是否持有 UnsafeCell / *const / *mut / NonNull / executor-affine state?` / `- 是否跨 task 傳遞?` / `- 是否為 public type?`),reviewer 可直接拷貝填寫
    3. 每個 section 至少 3 個 `<library-crate>` 範例,範例的狀態用 `pass` / `pending` / `fail` 明確標記
- [ ] **Task 2.4**: **Embassy async checklist** — **local `.await` 點的 state-machine obligations**。
  - **範圍 (v0.3 收窄)**: 單一 `.await` 點內部看得到的義務 — cancellation safety (`.await` 中途取消、future drop 時 state invariant 是否保存)、`Pin` 用法、`async fn` 簽名 convention、drop order、每個 `.await` 的 "what dies here" 清單
  - **跨 context 範疇 (interleaving / wakeup ordering / Send / Sync 跨邊界 / ISR handoff)**: 不在此 task,見 **Task 3.5**。Task 2.4 若 reviewer 遇到跨 context 疑慮,只做一次轉指到 Task 3.5,不複述規則
  - **Acceptance**:
    1. 產出 `docs/coding-standards/embassy-async-checklist.md`,section: `## 每個 .await 點的 local obligations` / `## 與 Task 3.5 (跨 context) 的 redirect FAQ`
    2. `## 每個 .await 點的 local obligations` 至少 5 個 `<binary-crate-paths>` 現存 `.await` 點的逐點對照
    3. `## Trigger 規則` 段給 diff pattern shell one-liner (例如 `git diff | grep -qE '^\+.*\.await|^\+.*async fn|^\+.*select!'`),且必須 path 限縮 `<binary-crate-paths>`
- [ ] **Task 2.5**: **Binary-side idiom review gate** (`<binary-crate-paths>` 內部 PR 可實作標準)。
  - **範圍**: 涵蓋 MIN / MOD / CC 紅線之外的 Embassy / no_std 慣例 — heapless / const-generic buffer sizing、`static` lifetime 管理、feature gating 使用原則、panic handler / 跨 context 同步 primitive convention。**不**處理 Send / Sync justification (歸 Task 2.3)、ISR handoff pattern (歸 Task 3.5)、soundness (歸 Task 3.4)
  - **Acceptance**:
    1. 產出 `docs/coding-standards/binary-idioms-checklist.md`,section: `## heapless / const-generic sizing` / `## static lifetime` / `## feature gating` / `## panic handler / 同步 primitive convention` / `## 與 Task 2.3 / 3.4 / 3.5 redirect`
    2. 每個 section 至少 2 個 `<binary-crate-paths>` 範例
    3. `## redirect` 段列出本 task **不處理**的 3 類 concern (Send / Sync、ISR handoff、soundness),各給 owning task 連結

> **Illustrative (nrg-prototype binary-idioms deliverable)**: nrg-prototype 的 `binary-idioms-checklist.md` 對應段名為 `## panic handler / critical-section` (因 nrg-prototype 用 `critical-section` crate 作跨 context atomic 邊界)。此例為 didactic reference,非通用模板規格。

- [ ] **Task 2.6**: **第一個試跑 PR 的 audit**。拿第一個進入新 pipeline 的 PR (含新 library module + workspace-internal pub API) 跑一次 Task 2.1 + 2.2 + 2.3 checklist,作為自用試跑。
  - **Acceptance**:
    1. 產出 `references/<project-id>/FIRST_PR_API_GUIDELINES_AUDIT.md` (一次性,PR merge 後歸檔)
    2. 至少 15 個 checklist 項評估 (每個 MUST 項至少一項;SHOULD 若不適用須明示 `NA + 理由`)
    3. 發現缺口時回寫對應 checklist 作為範例累積 (PR description 記錄哪些 checklist 因試跑而回寫)

> **Illustrative (nrg-prototype PR α)**: PR α 拿 `<library-crate>::pgn::adlink::protocol` 新 module + `J1939Id::from_raw` / `to_raw` 跑 Task 2.1 + 2.2 + 2.3;audit 結果歸檔於 `references/<project-id>/FIRST_PR_API_GUIDELINES_AUDIT.md`。此例為 didactic reference,非通用模板規格。

- [ ] **Task 2.7**: **Crosswalk 整合獨立文件** (v0.3 降級為 follow-up)。把本檔 §權威性 crosswalk 抽成 `docs/coding-standards/review-precedence-crosswalk.md`,**不擋** Phase 2 任何 checklist 的完成。inline 版本在 day 0 就 authoritative,獨立文件只是後續整合。
  - **Acceptance**:
    1. Crosswalk 文件存在且 Task 2.1-2.5 全部 checklist 文件均在表內有列
    2. Task 2.1-2.5 各自的 `## 衝突` 段若引用 crosswalk,須 cite 獨立文件章節 ID (非 inline section)
- [ ] **Task 2.8**: **`/dual-review` skill trigger spec**。把 skill 觸發規則寫成 repo 內的規範文件,不依賴 `~/.claude/skills/` 這個 repo 外的外部狀態。
  - **Acceptance**:
    1. 產出 `docs/coding-standards/dual-review-trigger-spec.md`,含 section: `## Trigger 規則` / `## Task 對映` / `## 最小可重現範例`
    2. 每個 Task 2.1-2.5 有對應 diff pattern 的 shell one-liner + expected checklist list
    3. `## 最小可重現範例` 至少 3 個 git diff 片段 (example / counter-example / edge-case),每個標 expected trigger
    4. `/dual-review` skill 的 `SKILL.md` 更新**不**擋 Phase 2 完成,僅需與此 spec 保持一致即可

**Phase 2 交付物**:

- `docs/coding-standards/rust-api-guidelines-checklist.md` (Task 2.1)
- `docs/coding-standards/error-taxonomy.md` (Task 2.2)
- `docs/coding-standards/ownership-idioms.md` (Task 2.3)
- `docs/coding-standards/embassy-async-checklist.md` (Task 2.4)
- `docs/coding-standards/binary-idioms-checklist.md` (Task 2.5)
- `references/<project-id>/FIRST_PR_API_GUIDELINES_AUDIT.md` (Task 2.6,一次性)
- `docs/coding-standards/review-precedence-crosswalk.md` (Task 2.7,follow-up)
- `docs/coding-standards/dual-review-trigger-spec.md` (Task 2.8)

**Agent review**:

1. Codex adversarial: 五份 checklist 的漏項、三級分類、與 MIN / MOD / CC 的 precedence 是否一致
2. Agent B: 試跑第一個試跑 PR 的 audit 結果 (Task 2.6)

---

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

**v0.3 邊界重劃**:

- Task 3.3 = **meta-policy only** — 說明 loom 為何不直接適用、三層替代管控機制如何協同,**不**定義個別 concurrency bug 規則
- Task 3.5 = 跨 context interleaving / ordering / affinity 的具體 review 清單 (個別規則的 canonical home)

- [ ] **Task 3.1**: **miri targeted tests for `<library-crate>`**。
  - **指定 target tests**: Phase 3 要明列具體 test function 名稱跑到 `<library-crate-paths>` `<unsafe-targeted-test>`。必須有 test 實際實例化觸及 unsafe block,否則 `cargo miri test` 等於 no-op。

> **Illustrative (nrg-prototype frame.rs)**: 候選 test 函式 `frame::tests::new_extended_with_max_id_constructs_ok` / `frame::tests::new_extended_with_boundary_ids_round_trip`,觸及 `ExtendedId::new_unchecked` wrapper。個別專案的對等 test 名稱由 Phase 3 實做時確認。此例為 didactic reference,非通用模板規格。

  - **Acceptance**:
    1. 產出 `docs/coding-standards/miri-plan.md`,section: `## Targeted tests` / `## 執行命令` / `## 預期輸出` / `## 觸發規則` / `## 月度 drift`
    2. `## Targeted tests`列出至少 2 個 test function 完整路徑 (`module::submodule::fn_name`)
    3. `## 執行命令`給完整 `cargo +nightly miri test -p <library-crate> --test <name> -- <filter>` 範例
    4. `## 預期輸出`同時記 pass output 片段 + UB hit 時的處理步驟
- [ ] **Task 3.2**: **miri 工具比較表**。
  - **範圍**: 比較 baseline miri / `-Zmiri-tree-borrows` (Tree Borrows aliasing model) / `-Zmiri-strict-provenance` (pointer provenance strict mode) / `cargo-careful` (debug assertion amplifier) 四者:適用性、預期訊號、PR 級 vs 月度、nightly 相依性
  - **Acceptance**:
    1. 比較表寫進 `miri-plan.md` §`## 工具比較`
    2. 至少對 `<unsafe-targeted-test>` targeted test 跑過 baseline + `-Zmiri-tree-borrows` 兩組,結果 (pass / UB + 原因) 記錄在表下方
- [ ] **Task 3.3**: **Concurrency verification meta-policy** (v0.3 收窄為 meta-policy)。
  - **範圍 (v0.3 收窄)**: 只論述 — loom 不直接適用的理由、三層替代管控機制 (Task 3.5 人工 checklist / `Send` / `Sync` assertion / host-model tests) 如何協同、工具選擇的判準。**不**複述個別 bug 規則 (那是 Task 3.5 的範圍)
  - **結論修正**: loom 以當前 API 直接用於 Embassy 不適用 (loom 目標是 `std::sync::{Arc, Mutex, RwLock}` 的 memory ordering,Embassy `Signal` / `Channel` / `Mutex` 是 cooperative executor 內部 primitive,不走 `std::sync`);但「Embassy = 單 executor = 無並發驗證」的推理錯誤。Embassy 仍有 interrupt ↔ task interleaving、跨 context 同步 primitive 使用假設、wakeup ordering、executor affinity、`Send` / `Sync` 跨任務邊界等正確性問題,由 Task 3.5 接手

> **Illustrative (nrg-prototype embedded crate stack)**: nrg-prototype 的「跨 context 同步 primitive」具體選擇為 `critical-section` crate (Embassy interrupt ↔ task atomic 邊界);個別專案的等價選擇由 Task 3.5 checklist 審查確認。此例為 didactic reference,非通用模板規格。

  - **替代管控機制**:
    1. Manual Embassy concurrency checklist → Task 3.5
    2. `Send` / `Sync` assertion (例如 `const _: fn() = || { fn assert_send<T: Send>() {} assert_send::<MyType>(); };`) → library crate 範圍
    3. Host-model tests → 若 library 有 queue / signal wrapper,以 `std::sync` 版本做 state machine test (邏輯 invariant,非 memory ordering)
  - **Acceptance**:
    1. 產出 `docs/coding-standards/concurrency-verification.md`,section: `## 為何 loom 不直接適用` / `## 三層替代管控的協同` / `## 工具選擇判準` / `## 與 Task 3.5 / 2.4 的邊界`
    2. `## 與 Task 3.5 / 2.4 的邊界` 明確列 3 種 "if you hit X, go to Y" redirect
    3. 文件長度上限 400 行 (若超過代表在複述 Task 3.5 規則)
- [ ] **Task 3.4**: **`unsafe-audit.md` — binary-side 5 處 unsafe**。
  - **每處 unsafe block 要求 in-code `// Safety:` 註解**,說明該處 invariant
  - **audit 文件每處列**: 位置、用途、invariants、替代 safe 做法 (若存在)
  - **Embassy interrupt handler 特別 proof obligations**: 單次初始化 (`#[interrupt]` + `embassy_executor` 的 ownership)、IRQ 綁定正確 (`bind_interrupts!` 或等價機制,不重複綁定)、Executor ownership (`static` Executor 安全)、可重入性假設
  - **Acceptance**:
    1. 產出 `docs/coding-standards/unsafe-audit.md`,5 處 unsafe 各自一節,每節 section headings: `### 位置` / `### 用途` / `### Invariants` / `### 替代 safe 做法` / `### 與 Task 3.5 交互`
    2. 每處 `// Safety:` in-code comment 必須 cite `unsafe-audit.md` 的章節 ID (例如 `// Safety: see unsafe-audit.md §3.4.2`)
    3. audit 文件反向 cite 每處 `file:line`
- [ ] **Task 3.5**: **Embassy concurrency review checklist** (跨 context interleaving / ordering / affinity 的 canonical home)。
  - **範圍 (v0.4 釐清)**: ISR ↔ task interleaving、wakeup ordering 依賴、atomics / 跨 context 同步 primitive 使用假設、**`Send` / `Sync` 跨 context 的 runtime correctness** (實際 interleaving 下是否成立;**不**涵蓋 public type 的 Send / Sync justification doc — 見 Task 2.3)、executor affinity (哪個 executor 跑哪個 task)。**個別規則的 canonical home**,Task 2.4 / 3.3 / 3.4 都 link 到此,不複述
  - **Acceptance**:
    1. 產出 `docs/coding-standards/embassy-concurrency-review.md`,section: `## ISR ↔ task interleaving` / `## wakeup ordering` / `## atomics / 同步 primitive` / `## Send / Sync 跨邊界` / `## executor affinity` / `## 與 Task 2.4 / 3.3 / 3.4 redirect`
    2. 每個 section 至少一個 `<binary-crate-paths>` pass 範例 + 一個 anti-pattern fail 範例
    3. 與 `unsafe-audit.md` 互引 (每處 interrupt handler unsafe 必有對應 concurrency review 項目)

> **Illustrative (nrg-prototype concurrency-review deliverable)**: nrg-prototype 的 `embassy-concurrency-review.md` 對應段名為 `## atomics / critical-section` (因 nrg-prototype 用 `critical-section` crate 作 interrupt ↔ task 同步邊界)。此例為 didactic reference,非通用模板規格。

**Miri 觸發頻率**:

- **PR 級**: 觸發於 `<library-crate-paths>` unsafe 相關 test 或 unsafe code 變動時 (diff pattern: `<library-crate-paths>` 變動或 test 檔變動且檔內有 unsafe 相關 fn)。若 nightly toolchain 破損,跳過並在工作追蹤系統記錄,不擋主流程
- **月度**: 跑 baseline + `-Zmiri-tree-borrows` 兩組,作為 drift detection (補 unsafe 相關 test coverage 沒跟著 unsafe code 成長的情況)

**Phase 3 交付物**:

- `docs/coding-standards/miri-plan.md` (Task 3.1 + 3.2)
- `docs/coding-standards/concurrency-verification.md` (Task 3.3, meta-policy)
- `docs/coding-standards/unsafe-audit.md` (Task 3.4)
- `docs/coding-standards/embassy-concurrency-review.md` (Task 3.5, 跨 context canonical home)

**Agent review**: Codex 驗算 miri 在 conditional no_std crate 的執行可行性 (nightly toolchain / features flag 細節);Codex adversarial review `unsafe-audit.md` 的 invariant 完整度與 `concurrency-verification.md` 的替代管控機制邏輯。

---

### Phase 4 — 深度閱讀 (持續,每月 review)

Target: reviewer 審查能力養成。規則引擎 / checklist 是「能辨識」,深度閱讀是「能設計」。

**閱讀清單優先順序**:

| # | 資源 | 形式 | 為什麼現在讀 |
|---|-----|------|------------|
| 1 | Rust API Guidelines (`https://rust-lang.github.io/api-guidelines/`) | HTML checklist | Phase 2 Task 2.1 直接依據 |
| 2 | Effective Rust (David Drysdale,2024) | 書,約 35 項 `[UNVERIFIED: 版本確認待補]` | 第 4 項 (error handling) + 第 10-15 項 (idiom) 對應 Phase 2 Task 2.2 / 2.3 |
| 3 | Rustonomicon (`https://doc.rust-lang.org/nomicon/`) | 官方 unsafe book | Phase 3 Task 3.4 aliasing / provenance 論證依據 |
| 4 | Rust for Rustaceans (Jon Gjengset,2021) | 書 | 進階 API 設計,第 2 章 + 第 6 章 跟 Effective Rust 互補 |
| 5 | Embassy Book (`https://embassy.dev/book/`) | HTML | Phase 2 Task 2.4 async checklist 依據;Phase 3 Task 3.5 concurrency review 依據 |
| 6 | Crust of Rust (Jon Gjengset) | 系列影片 | 針對 #3-5 特定主題深入 |
| 7 | Rust Async Book (`https://rust-lang.github.io/async-book/`) | HTML | `Pin` / `Future` / `Waker` 基礎,支撐 Task 2.4 的 `Pin in async fn` 部分 |

**Fallback**: 若 Effective Rust (#2) / Rust for Rustaceans (#4) 暫時無法取得,以官方 HTML 來源 (#1 / #3 / #5 / #7) 先補位。書目 #2 的 `[UNVERIFIED]` 版本註記不宜作為月度進度硬依賴,待現場確認後移除。

- [ ] **Task 4.1**: 產出 `docs/coding-standards/rust-reading-list.md` (持續更新)。包含上表 + 每月 checkpoint 格式 (讀了哪一章、啟發了什麼、應用在哪個 PR / checklist 更新)
- [ ] **Task 4.2**: 每月一對一同步進度 (或以 `<vc-ref-mechanism>` 留言非同步更新)

**Acceptance**:

1. `rust-reading-list.md` 存在且至少一個月 checkpoint 填入
2. 每次 checkpoint 必須 cite 至少一處 Phase 2 / Phase 3 checklist 因閱讀而更新的 diff (commit hash 或 PR 號),不接受純閱讀紀錄

**Agent review**: 不適用 — 閱讀人工驅動,不外包。

---

### Phase 5 — Plan 本身的 Agent review 流程

本計畫自己要跑過三關才算定案:

- [x] **Checkpoint 5.1** (必要): Codex adversarial review。CLAUDE.md 設計文件紅線要求,本檔名符合 `*-plan.md` pattern。focus 建議: Phase 分期、idiomatic Rust 覆蓋面、Phase 3 推理。
  - **v0.1 → v0.2**: round 1 已完成 (2026-04-18,13 findings 全部接受,plan 重寫 → v0.2)
  - **v0.2 → v0.3**: round 2 已完成 (2026-04-18,7 條 finding:6 條完整採納 + 1 條部分採納,plan 重寫 → v0.3 於 2026-04-21)
  - **v0.3 → v0.4**: round 3 已完成 (2026-04-21,4 條 finding 全為結構性:P1 ×2 + P2 ×2,全數採納,plan 重寫 → v0.4 於 2026-04-21)
  - **v0.4 → v0.5**: round 4 已完成 (2026-04-21,2 條 P1 finding 皆聚焦在 R3-2 API maturity tag enforcement 實作細節,全數採納,plan 重寫 → v0.5 於 2026-04-21)
  - **v0.5 → v0.6**: round 5 已完成 (2026-04-21,1 條新結構 finding: script spec diff-based 漏掉「changed pub item」,已改全庫 inventory scan,plan 重寫 → v0.6 於 2026-04-21)
  - **v0.6 → v0.7**: round 6 已完成 (2026-04-21,1 條結構 finding: enumeration 漏 `pub use` / `pub mod`,已改 non-exhaustive list + 明示排除 restricted visibility,plan 重寫 → v0.7 於 2026-04-21)
  - **v0.7 → 定稿**: **closed (`<sync-reviewer>` 2026-04-29 核可跳出迴圈判定)** — Claude 依 CLAUDE.md `feedback_consensus_loop_escalation` 判跳出迴圈 (round 3-6 連 4 輪皆在同一 spec 抓 edge case,層次從結構 → 實作 → scope → enumeration 收斂到細節),`<sync-reviewer>` 2026-04-29 接受此判定,v0.7 為定稿
- [ ] ~~**Checkpoint 5.2** (非必要): Agent B sanity review。focus: 每個 Task 的交付物是否具體可驗證~~ — **skipped (`<sync-reviewer>` 2026-04-29 選 C 直接拍板 + 起 v0.8 暫存,跳過 5.2)**
- [x] **Checkpoint 5.3** (必要): `<sync-reviewer>` 人工拍板 — **done (2026-04-29)**

所有**必要** checkpoint (5.1 + 5.3) 完成後才開跑 Phase 1。5.2 可跳。**2026-04-29 已達成,Phase 1 解鎖**。

**2026-05-02 進度盤點**: Phase 1-2 進度盤點,必要時調整 Phase 3-4 順序。

---

## 實施時機與專案關係

- **不阻第一個試跑 PR**: 第一個試跑 PR 照原計畫 push,本計畫不插隊
- **第一個試跑 PR 當 Phase 2 試跑樣本**: Task 2.6 自用試跑拿第一個試跑 PR 回頭補 audit,不擋 merge (試跑結果寫 `<project-id>/FIRST_PR_API_GUIDELINES_AUDIT.md`)

> **Illustrative (nrg-prototype PR α)**: PR α (HEAD `29117d7b`) 照計畫 push 未阻擋,Phase 2 以 PR α 為 Task 2.6 試跑樣本。此例為 didactic reference,非通用模板規格。

- **Phase 3 啟動 / skip 決策**: 由 mapping doc §B `<unsafe-targeted-test>` / `<unsafe-binary-side>` placeholder state 驅動 (per v1.0 §5),不再綁定特定 PR milestone

> **Illustrative (nrg-prototype PR β)**: nrg-prototype 以「PR β 之前完成 Phase 3」為觸發點,因 PR β 會動更多硬體層 code。此例為 didactic reference,通用模板改以 state-machine gate 取代 PR milestone 硬綁定。

- **Phase 4 持續**: 不設期限,每月 checkpoint

---

## 待解問題

- **Q1**: `cargo audit` 升為 PR 級 vs 月度? (Phase 1 Task 1.3)
  - 成本約 5 秒、訊號中
  - embedded 相依套件不多,但核心 embedded crate 一出 CVE 就要追
  - 建議升 PR 級,等 `<sync-reviewer>` 拍板

> **Illustrative (nrg-prototype)**: `cortex-m` / `embassy-*` / `critical-section` 是 nrg-prototype 的核心 embedded crate,個別專案的對等 crate 由 mapping doc §B 填入。此例為 didactic reference,非通用模板規格。

- **Q2**: `miri` 在本專案實際覆蓋度? (Phase 3 Task 3.1)
  - 全專案 unsafe 只有少數 host-testable,其餘須手動 audit
  - Host-testable 的 `<unsafe-targeted-test>` 是 miri 強項 — 值得 PR 級跑 (條件觸發 + 月度 drift detection)

> **Illustrative (nrg-prototype)**: 6 處 unsafe 只 1 處 host-testable (`frame.rs:44` 的 `new_unchecked`);此分佈為 nrg-prototype 的具體狀況,個別專案由 Phase 3 audit 確認。此例為 didactic reference,非通用模板規格。

- **Q3**: Rust for Rustaceans vs Effective Rust 選一還是都讀? (Phase 4)
  - Drysdale (2024) 較新,Gjengset (2021) 較深入進階 idiom
  - 建議: Drysdale 先,Gjengset 補第 2 章 (API design) + 第 6 章 (unsafe)
- **Q4**: `cargo-llvm-cov` 是否重啟評估?
  - CLAUDE.md 略過清單先前理由「成本高、訊號低」對 embedded + no_std 仍成立
  - 保持略過,Phase 5 進度盤點時重評

---

## Agent Review Checkpoints (完整清單)

| # | Checkpoint | Agent | 觸發時機 |
|---|-----------|-------|---------|
| 1 | Plan v0.1 | Codex adversarial | 2026-04-18 round 1 完成 (13 findings 全部接受) |
| 2 | Plan v0.2 | Codex adversarial | 2026-04-18 round 2 完成 (7 條 finding:6 完整採納 + 1 部分採納) |
| 3 | Plan v0.3 | Codex adversarial | 2026-04-21 round 3 完成 (4 條 finding 全為結構性,P1 ×2 + P2 ×2,全數採納) |
| 4 | Plan v0.4 | Codex adversarial | 2026-04-21 round 4 完成 (2 條 P1 finding,聚焦 R3-2 enforcement 實作,全數採納) |
| 5 | Plan v0.5 | Codex adversarial | 2026-04-21 round 5 完成 (1 條結構 finding: script spec diff→全庫 inventory,全數採納) |
| 6 | Plan v0.6 | Codex adversarial | 2026-04-21 round 6 完成 (1 條結構 finding: enumeration 漏 `pub use`/`pub mod`,全數採納) |
| 7 | — | — | **Claude 判跳出迴圈** (round 3-6 同一 spec 4 輪 edge-case chain);若 `<sync-reviewer>` 明示需 round 7 再跑 |
| 8 | Plan v0.7 | Agent B (非必要) | 定稿後 (Phase 5.2) |
| 5 | Phase 1 scripts | Codex | `rust-quality-check.sh` 完成後 |
| 6 | Phase 2 每份 checklist 草稿 | Codex adversarial | 五份 checklist 分別完成後 |
| 7 | Phase 2 試跑 (第一個 PR audit) | Agent B | 跑完 Task 2.6 audit 後 |
| 8 | Phase 3 unsafe-audit + concurrency-verification | Codex | Task 3.3-3.5 完成後 |

必要 checkpoint 完成後才往下走 (5.2 非必要可跳),不跳步。

---

## v0.8 落地紀錄

v0.7 plan 內 §v0.8 暫存 12 條實證心得已於 v1.0 abstraction sweep 全數落地。原暫存表 (drift-check / landing matrix / atomicity gate) 已不適用 (v1.0 sweep 同步落地,無暫存態);本段保留落地矩陣作為歷史紀錄。

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

---

## Meta

- **Spec**: 本文件兼具規格與計畫功能
- **Language**: 以繁中撰寫 (指令、工具名與必要技術名詞保留英文)
- **Commit 前要求**:
  - Codex review (CLAUDE.md 設計文件紅線;本檔名符合 `*-plan.md` pattern,不得跳過)
  - 繁中品質審核通過 (CLAUDE.md trigger #3 路徑 `docs/**/*.md`)
- **Related docs**:
  - `docs/coding-standards/minimalism.md` — MIN-1 ~ MIN-6 (規則引擎層補充)
  - `docs/coding-standards/modularity.md` — MOD-1 ~ MOD-5 (設計層補充)
  - `docs/coding-standards/clean-code.md` — CC1 ~ CC13 (設計層補充)
  - `docs/superpowers/specs/2026-04-16-claude-code-workflow-improvement-design.md` — Verification Policy 源頭

---

## Appendix A — Round 1 closeout matrix

讀者可據此稽核 v0.2 對 round 1 每個 finding 是否真正落地。

| # | Round 1 finding | 嚴重度 | v0.2 落地位置 | 狀態 | Residual risk |
|---|-----------------|-------|--------------|------|---------------|
| P1-1 | `<binary-crate>` 無 operational idiom review gate | P1 | Phase 2 Task 2.5 (binary-idioms-checklist) | fixed | 無 — v0.3 以 ownership concern canonical home 進一步釐清 Task 2.5 不處理 unsafe / ISR / Send-Sync |
| P1-2 | Pipeline step 5 = miri+loom 但 5/6 unsafe 在 unsafe-audit.md 外圍 | P1 | Pipeline 表第 5 步改名「Unsafe / concurrency verification」;binary unsafe 5 處升格到 Phase 3 範疇 | fixed | 無 |
| P1-3 | Phase 2 新 criteria vs MIN / MOD / CC 沒 precedence mapping | P1 | 新增§權威性 crosswalk | fixed | round 2 發現 Task 2.5 / 3.5 缺列,v0.3 已補;日後加新 task 必須同步擴表 |
| P1-4 | Deliverables「produce a doc」adequacy 不可驗 | P1 | 每個 Task 加 Acceptance bullet | reframed | v0.2 部分 Acceptance 仍不 falsifiable (「完整填寫」等);round 2 P2-2 指出,v0.3 已全改 |
| P1-5 | `/dual-review` skill update 是 workstation state | P2 | Task 2.8 改 repo-local trigger spec normative | fixed | 無 |
| P1-6 | 無 error taxonomy | P1 | Phase 2 Task 2.2 加入 | fixed | 無 |
| P1-7 | 漏 ownership / conversion idiom | P1 | Phase 2 Task 2.3 加入 | fixed | round 2 指出 Send / Sync 在 2.3 / 2.4 / 3.5 / 3.3 重複出現,v0.3 已去重到 canonical home |
| P1-8 | `impl Send + Sync` 無條件 MUST 錯 | P1 | Task 2.3 改「auto-trait story 必須論證」 | fixed | 無 |
| P1-9 | async idiom 只 reading | P1 | Phase 2 Task 2.4 升格 | reframed | v0.2 Task 2.4 範圍過寬跟 Task 3.5 重疊;round 2 P1 指出,v0.3 收窄為 local `.await` obligations |
| P1-10 | trait object / lifetime elision / typestate | P2 | Task 2.1 appendix | fixed | 無 |
| P1-11 | Loom 結論不 sound | P1 | Task 3.3 改「不直接適用,替代管控機制」 | reframed | v0.2 Task 3.3 與 3.5 邊界模糊;round 2 P1 指出,v0.3 收窄 3.3 為 meta-policy |
| P1-12 | miri 沒 targeted test | P1 | Task 3.1 前置「指定 target test」 | fixed | 無 |
| P1-13 | 漏 tree-borrows / strict-provenance / cargo-careful | P2 | Task 3.2 加入比較表 | fixed | 無 |

---

## Appendix B — Round 2 closeout matrix (v0.3 self-audit)

讀者可據此稽核 v0.3 對 round 2 每個 finding 是否真正落地。

| # | Round 2 finding | 嚴重度 | v0.3 落地位置 | 狀態 | Residual risk |
|---|-----------------|-------|--------------|------|---------------|
| R2-P1 | Task 2.4 / 3.3 / 3.5 邊界不清楚;「task A await channel,ISR fires,ISR posts,task A wakes in unexpected state」落在三個 task 的交界 | P1 | §Cross-task bug routing + Phase 2 / Phase 3 Task 2.4 / 3.3 / 3.5 範圍全面改寫;Task 2.4 = local `.await` obligation / Task 3.5 = 跨 context / Task 3.3 = meta-policy | fixed | 待 round 3 驗證 routing table 的具體 bug 範例是否夠涵蓋常見 pattern |
| R2-P2-1 | 沒 round 1 closeout matrix | P2 | Appendix A (本矩陣) | fixed | 無 |
| R2-P2-2 | Acceptance 多處 unfalsifiable (「完整填寫」「保持一致」「明確」) | P2 | Phase 1 / Phase 2 / Phase 3 全部 Acceptance 改寫為 required heading / mandatory example count / testable outcome / explicit fixture | fixed | 待 round 3 驗證每個 Acceptance 是否真正 falsifiable |
| R2-P2-3 | Crosswalk 缺 Task 2.5 / 3.5 row;Task 2.7 時序循環 | P2 | §權威性 crosswalk 補 Task 2.5 / 3.5 列 + day 0 inline authoritative;Task 2.7 降為 follow-up 整合 | fixed | 無 |
| R2-P2-4 | MIN-1 vs future-proof 建議長期拉扯;缺 API maturity tag | P2 | §API maturity tag 新增 (3 tag);Task 2.1 MUST / SHOULD 綁 tag | fixed | 每個 `pub` item 的 tag 選擇需 reviewer 判斷,預設 `workspace-internal pub` 並可升級;待 Task 2.6 試跑第一個試跑 PR 時驗證 |
| R2-P2-5 | Send / Sync (3x) + ISR handoff (2x) + static / executor ownership (3x) 在多個 task 重複計算 | P2 partial | §Ownership concern canonical home 新增 matrix;**未** merge Task 2.5 (理由:heapless / buffer sizing / feature gating 是 Task 2.5 獨有 concern,不該合併) | fixed (依設計為 partial) | 無 |

---

## Appendix C — Round 3 closeout matrix (v0.4 self-audit)

讀者可據此稽核 v0.4 對 round 3 每個 finding 是否真正落地。Round 3 共 4 條 finding (P1 ×2 + P2 ×2),全為結構性 (Codex 建議 round 4 而非跳出迴圈)。

| # | Round 3 finding | 嚴重度 | v0.4 落地位置 | 狀態 | Residual risk |
|---|-----------------|-------|--------------|------|---------------|
| R3-1 | Cross-task bug routing 違反「每 pattern 單一 owner」規則;L151 `UnsafeCell` 與 L156 `From` vs `TryFrom` 雙 owner;Task 3.5 scope 仍提 `Send/Sync 跨邊界` 與 Task 2.3 canonical home 衝突 | P1 | §Cross-task bug routing 改為「primary owner + backlink」結構 (v0.4);Task 3.5 scope 段加釐清 bullet 切分 2.3 doc vs 3.5 runtime correctness | fixed | 待 round 4 驗證 primary/backlink 區分是否 reviewer 執行得了 |
| R3-2 | API maturity tag 無 enforcement;未標 tag 默默降級為 `workspace-internal pub`,無 falsifiable check | P1 | §API maturity tag 的「綁定規則」v0.4 改寫:強制標 tag、格式固定、附可 grep shell one-liner、Task 2.1 acceptance 必跑 | **partially fixed (awk 實作錯誤,v0.5 改為 script spec)** | Round 4 後續抓出兩條 residual risk:R4-1 awk 用 hunk-wide flag 誤判、R4-2 Task 2.1 acceptance 未真的 bind。v0.5 兩處皆修 (見 Appendix D) |
| R3-3 | Task 1.2 fixture (`docs/_test_broken.md`) 在 `cargo doc` 偵測範圍外,驗不到 hook | P2 | Task 1.2 Acceptance 第 2 條改為「在 crate rustdoc 內加 broken intra-doc link」(`<library-crate-paths>lib.rs` 或任一 `pub` item) | fixed | 無 |
| R3-4 | Task 1.1 用 `-p <binary-crate>` 與 workspace-excluded 矛盾 | P2 | Task 1.1 Acceptance 第 1 條改為 `--manifest-path <binary-crate-paths>Cargo.toml`,附註說明 | fixed | 無 |

---

## Appendix D — Round 4 closeout matrix (v0.5 self-audit)

讀者可據此稽核 v0.5 對 round 4 每個 finding 是否真正落地。Round 4 共 2 條 P1 finding,皆聚焦在 R3-2 API maturity tag enforcement 實作細節 (非新議題,是 round 4 從 R3-2 抓出的 residual risk)。Codex round 4 判 R3-1 / R3-3 / R3-4 皆 closed。

| # | Round 4 finding | 嚴重度 | v0.5 落地位置 | 狀態 | Residual risk |
|---|-----------------|-------|--------------|------|---------------|
| R4-1 | awk one-liner 實作錯誤:用 hunk-wide `marked` flag,早先 marker 誤判後續 pub item 已標 tag;未處理 EOF,最後 hunk 的 untagged item 不 flush | P1 | §API maturity tag 的 awk one-liner 整段刪除,改為 `scripts/check-api-maturity-tags.sh` 的 behaviour spec (per-item 10-line window scan、marker 正則、`file:line` 輸出契約、EOF handling);實作由 Task 1.6 產出 | fixed | Script 實際實作還沒寫;待 Task 1.6 落地時依 spec 產出,可能再抓 bug,但 plan 層面的 spec 已 falsifiable |
| R4-2 | Task 2.1 acceptance 未真的 bind tag 檢查;「必跑」只在 prose 講,acceptance 只要求 generic shell one-liner example,沒要求 tag checker 本身 | P1 | Task 2.1 Acceptance 從 4 項增至 5 項,第 5 項明確要求 `check-api-maturity-tags.sh` 存在 + pass/fail fixture 呈現於文件;Task 1.6 Acceptance 新增第 4 項一併產出 script | fixed | 無 |

---

## Appendix E — Round 5 closeout matrix (v0.6 self-audit)

Round 5 共 1 條新結構 finding。Codex 判 R4-1 / R4-2 皆 closed。

| # | Round 5 finding | 嚴重度 | v0.6 落地位置 | 狀態 | Residual risk |
|---|-----------------|-------|--------------|------|---------------|
| R5-1 | Script spec 用 diff-based 掃描,但 plan 規則 scope 說「new / changed pub item」;「changed pub item」(簽名變、visibility promotion `pub(crate)` → `pub`、doc 改但 `pub` 行未動) 無法檢測 | structural | §API maturity tag 的「Executable enforcement」段改為**全庫 inventory scan**;每次 pre-commit / CI 掃 `<library-crate-paths>` 全部現存 pub item,不依 diff。Cost < 1 秒 | fixed | 無 |

---

## Appendix F — Round 6 closeout + escalation decision (v0.7 self-audit)

Round 6 找到 1 條結構 finding。Claude 依 CLAUDE.md `feedback_consensus_loop_escalation` 判定跳出迴圈 — round 3-6 連 4 輪都在同一 spec (API maturity tag enforcement) 抓 edge case,收斂模式符合「sweep 漏洞」pattern。

| # | Round 6 finding | 嚴重度 | v0.7 落地位置 | 狀態 | Residual risk |
|---|-----------------|-------|--------------|------|---------------|
| R6-1 | Inventory scan 只列 7 類 hard-coded enumeration (`pub fn` / `struct` / `enum` / `trait` / `const` / `static` / `type`),漏 `pub use` (re-export) / `pub mod` (module decl);plan prose 說「每個 pub item」與 enumeration 不一致 | structural | §API maturity tag 的「Full inventory scan」段改為 **non-exhaustive list**,顯式列出 `pub use` / `pub mod` / `pub macro_rules!` / `pub async fn` / `pub unsafe fn` / `pub const fn` / `pub union`,並明示排除 `pub(crate)` / `pub(super)` / `pub(in path)` | fixed | Non-exhaustive list 仍可能漏未來 Rust edition 引入的新 `pub` 形式;script 實作時以 `^pub(\s|\()` 類 regex 做 forward-compat,不依賴 enumeration 完整性 |

### Escalation decision rationale (Claude 判定,等 `<sync-reviewer>` 核可)

Round 3-6 findings 的 owning concern 分佈:

| Round | Finding 主題 | 層次 |
|-------|-------------|------|
| 3 (4 條) | routing dual-owner / tag enforcement 存在性 / fixture 位置 / clippy path | 設計層結構 |
| 4 (2 條) | awk 實作錯誤 / Task 2.1 acceptance bind 不足 | 實作層 |
| 5 (1 條) | diff-based 漏 changed item | Scope 邊界 |
| 6 (1 條) | enumeration 漏種類 | Enumeration 完整性 |

模式: 層次**單調收斂**(結構 → 實作 → scope → enumeration),每輪抓的問題範圍越來越窄,且過去 3 輪 (4, 5, 6) 都圍繞同一個 spec (API maturity tag enforcement) 的不同 facet。Round 7 預期的 finding 類型: `pub` item regex false positive / restricted visibility 例外 / macro-generated pub item / `#[cfg]` gated pub item。皆為 enumeration 邊緣,非新架構。

CLAUDE.md `feedback_consensus_loop_escalation` 原則: 「Codex adversarial review 跑到後幾輪如果只抓...sweep 漏洞,就跳出迴圈」。當前模式符合此定義,故跳出迴圈。

若 `<sync-reviewer>` 核可,v0.7 即為 Phase 5.1 final draft;否則 `<sync-reviewer>` 可推翻此判定,繼續 round 7。
| R2-P2-6 | Trigger example path 不一致 (`<library-crate>/src/...` vs `<library-crate-paths>`) | P2 | 全檔統一 `<library-crate-paths>` / `<binary-crate-paths>` path | fixed | 無 |
