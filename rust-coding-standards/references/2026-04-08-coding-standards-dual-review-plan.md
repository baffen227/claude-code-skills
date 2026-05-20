# Coding Standards + Dual-Review Skill Implementation Plan

> **SUPERSEDED (2026-04-18)**: 本文件中提及的 custom `codex-reviewer` skill 已整個移除 (symlink + repo)。以後所有 Codex review 都走 OpenAI 官方 codex plugin (`/codex:review` / `/codex:adversarial-review` / `/codex:rescue`)。見 `CLAUDE.md` §Cross-AI Review Workflow。本文件保留作歷史快照。

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create three coding standards docs (MIN/MOD/CC), update CLAUDE.md + SOP, create dual-review skill.

**Architecture:** Three standalone docs in `docs/coding-standards/` with numbered rules (MIN-1~6, MOD-1~5, CC1~13), each following "Rule → Trigger → DO/DON'T → Rationale" format. CLAUDE.md gets 6 Red Lines + Reference Files entries. SOP Section 7 becomes a pointer. Dual-review skill in `claude-code-skills/dual-review/` orchestrates Agent B + Codex review.

**Tech Stack:** Markdown docs, Claude Code skill (YAML frontmatter + markdown)

**Spec:** `docs/coding-standards/2026-04-08-coding-standards-dual-review-design.md`

---

### Task 1: Create minimalism.md (MIN-1~MIN-6)

**Files:**
- Create: `docs/coding-standards/minimalism.md`

- [ ] **Step 1: Write minimalism.md**

```markdown
# Minimalism Coding Standard

**Scope**: 所有程式碼變更 (STM32H563 Master Board CAN integration testing)
**Severity**: 違規 = HIGH (與 protocol correctness 同級)
**Cross-references**: modularity.md (MOD-1~MOD-5), clean-code.md (CC1~CC13)

---

## Rules

### MIN-1: No Speculative Abstractions

**Rule**: 只寫現在需要的 code。不為假設的未來需求設計 generic、trait、或 wrapper type。

**Trigger**: 新增 generic type parameter、trait definition、或 wrapper struct 時。

**DO**:
```rust
// 目前只有一個 CAN peripheral → 直接用具體型別
fn read_cell_voltage(can: &mut BufferedCanFd<'_, FDCAN1>) -> Result<u8, ReadError> {
```

**DON'T**:
```rust
// "未來可能用 FDCAN2" → 過早泛化
fn read_cell_voltage<T: CanPeripheral>(can: &mut T) -> Result<u8, ReadError> {
```

**Rationale**: 泛化增加 code size (monomorphization) 和認知負擔。等到第二個 concrete type 出現再泛化。YAGNI — You Aren't Gonna Need It。

---

### MIN-2: Scope Control

**Rule**: 只改被要求的範圍。不 drive-by refactor。

**Trigger**: 任何 file modification。

**DO**:
- 只修改 requested function/block
- 發現改善機會 → 記錄在 response text "## Improvement Opportunities (out of scope)"

**DON'T**:
- Rename variables in untouched functions
- Reorganize imports unless the change requires it
- Add doc comments to functions you did not modify
- Extract helpers from code outside the change scope
- Add error handling to code paths that already work

**Rationale**: AI coding assistants 最常見的 complaint: "helpfully" refactors adjacent code。Community 報告中 single highest-impact rule。

---

### MIN-3: No "Just in Case" Error Paths

**Rule**: 只處理硬體和協議實際可能產生的 error。不加 defensive code for impossible conditions。

**Trigger**: 新增 error variant、match arm、或 if-else branch 時。

**DO**:
```rust
// CAN read 可能 timeout — 這是真實的 error
match with_timeout(deadline, can.read()).await {
    Ok(frame) => process(frame),
    Err(_) => return Err(ReadError::Timeout),
}
```

**DON'T**:
```rust
// SA 只可能是 0x00~0xFF (u8 range) — 不需要 range check
if sa > 0xFF {
    return Err(Error::InvalidSa); // impossible for u8
}
```

**Rationale**: Safety-critical code 的原則是處理所有 real error paths，不是所有 conceivable error paths。Phantom error paths 增加 code complexity 且誤導 reviewer。

---

### MIN-4: No Wrapper Types Without Justification

**Rule**: Newtype struct 必須提供 invariant enforcement 或 API 限制，才有存在理由。

**Trigger**: 新增 `struct Foo(inner_type)` 時。

**DO**:
```rust
// NodeId 限制 0x00~0x53 的 valid range → invariant enforcement
struct NodeId(u8);
impl NodeId {
    fn new(raw: u8) -> Option<Self> {
        if raw <= 0x53 { Some(Self(raw)) } else { None }
    }
}
```

**DON'T**:
```rust
// 只是給 u8 一個名字，沒有 invariant → 用 type alias 或直接 u8
struct Voltage(u8); // no validation, no API restriction
```

**Rationale**: 無 invariant 的 newtype 增加 boilerplate (`.0` access, From impl) 卻不提供 safety benefit。

---

### MIN-5: Constant Introduction Threshold

**Rule**:2+ 次出現或語義不明才提取為 named constant。

**Trigger**: 新增 `const` 或 `static` 時。

**DO**:
```rust
const MASTER_SA: u8 = 0x00;          // 出現 5+ 次，語義重要
const HBT_INTERVAL_MS: u64 = 2000;   // 語義不明 (2000 = ?)
```

**DON'T**:
```rust
const FIRST_INDEX: usize = 0;        // 0 as index 不需要常數
const ONE: u8 = 1;                   // self-explanatory literal
```

**Rationale**: 過度提取常數使 code 更難讀 (需要跳到定義處)。只在重複出現或語義不明時才有價值。

---

### MIN-6: Import Hygiene

**Rule**: 只加需要的 import。移除你的變更導致的 unused import。

**Trigger**: 任何 file modification。

**DO**:
```rust
// 只 import 你的新 code 用到的
use embassy_stm32::can::{BufferedCanFd, FdFrame};
```

**DON'T**:
```rust
// "might need later" imports
use embassy_stm32::can::{BufferedCanFd, FdFrame, TxFrame, RxFrame, CanConfig};
```

**Rationale**: Unused imports 是 dead code。`#![deny(unused_imports)]` 可 machine-enforce。

---

## Verification Checklist

實作完成後，self-check:

1. [ ] 是否有新增不在 task scope 的改動？(MIN-2)
2. [ ] 是否有 generic/trait 只被一個 concrete type 使用？(MIN-1)
3. [ ] 是否有 error path 處理了 impossible condition？(MIN-3)
4. [ ] 是否有 newtype 沒有 invariant？(MIN-4)
5. [ ] 是否有只出現一次的 named constant？(MIN-5)
6. [ ] 是否有 unused imports？(MIN-6)
```

- [ ] **Step 2: Verify file renders correctly**

Run: `head -5 docs/coding-standards/minimalism.md`
Expected: First 5 lines of the file visible.

- [ ] **Step 3: Commit**

```bash
git add docs/coding-standards/minimalism.md
git commit -m "Add minimalism coding standard (MIN-1~MIN-6)"
```

---

### Task 2: Create modularity.md (MOD-1~MOD-5)

**Files:**
- Create: `docs/coding-standards/modularity.md`

- [ ] **Step 1: Write modularity.md**

```markdown
# Modularity Coding Standard

**Scope**: 涉及 shared code 或多模組改動時必讀；所有程式碼變更建議參考
**Severity**: 違規 = HIGH (與 protocol correctness 同級)
**Cross-references**: minimalism.md (MIN-1~MIN-6), clean-code.md (CC1~CC13)
**CA Mapping**: CA1→MOD-1, CA2→MOD-2, CA3→MOD-3

---

## Rules

### MOD-1: Dependency Direction (原 CA1)

**Rule**: Inner layers 不 import outer layers。依賴方向: Adapter → Use Case → Entity。

**Trigger**: 新增 `use` statement 跨模組邊界時。

**DO**:
```rust
// test_harness.rs (Use Case) imports protocol.rs (Entity)
use crate::domain::protocol::{read_data, write_command};

// ti_001_can_comm.rs (Adapter/Binary) imports test_harness.rs (Use Case)
use crate::domain::test_harness::{run_test_plan};
```

**DON'T**:
```rust
// protocol.rs (Entity) imports binary-local types → 違反 dependency rule
use crate::bin::ti_001::TestConfig;
```

**Layer diagram:**
```
[Adapter] ti_001_can_comm.rs, ti_004_cell_voltage.rs (binaries)
    ↓ depends on
[Use Case] test_harness.rs
    ↓ depends on
[Entity] protocol.rs, j1939.rs, crc.rs
```

**Rationale**: Clean Architecture Dependency Rule — inner layers 是穩定的 business rules，outer layers 是 volatile 的 delivery mechanism。反向依賴使 inner layers 無法獨立測試或重用。

---

### MOD-2: Boundary Interface (原 CA2)

**Rule**: Shared code 透過參數接受 binary-specific 值，不 hardcode。

**Trigger**: 在 shared module (protocol.rs, test_harness.rs) 中使用 binary-specific 值時。

**DO**:
```rust
// test_harness.rs — SPM SA 由 caller 傳入
pub async fn run_hbt_cycle(can: &mut CanFd, spm_sa: u8) -> Result<(), TestError> {
```

**DON'T**:
```rust
// test_harness.rs — hardcode SPM SA
const SPM_SA: u8 = 0x01; // binary-specific!
pub async fn run_hbt_cycle(can: &mut CanFd) -> Result<(), TestError> {
```

**Rationale**: Hardcoded values 使 shared code 無法被不同配置的 binary 重用。TI-004 經驗: SPM_SA hardcode 分 3 輪 review 才抓完。

---

### MOD-3: Layer 歸屬 (原 CA3)

**Rule**: 每個函式和 struct 可明確歸屬到一個 layer (Entity / Use Case / Adapter)。

**Trigger**: 新增函式或 struct 時。

**DO**:
- Module doc comment 標明 layer: `//! Use Case layer — depends on protocol (Entity)`
- 函式 doc comment 在 design-motivated 情境標註: `/// (CA2: parameterized spm_sa)`

**DON'T**:
- 一個函式同時做 protocol parsing (Entity) 和 test orchestration (Use Case)
- 一個 struct 混合 CAN frame data (Entity) 和 test statistics (Adapter)

**Rationale**: 混合 layer 的函式無法獨立測試，且 change 原因不單一 (違反 CC5 SRP)。

---

### MOD-4: Extraction Threshold

**Rule**: Rule of Three — 3+ binary 使用相同 code 時必須提取為 shared module。2 binary + >100 行相同 code 也可提取。

**Trigger**: 發現重複 code 跨 binary 時。

**DO**:
```
Binary A: 105 行 identical code  ─┐
Binary B: 105 行 identical code  ─┤→ 提取至 test_harness.rs (TI-004 precedent)
```

**DON'T**:
```
Binary A: 15 行 similar code  ─┐
Binary B: 15 行 similar code  ─┤→ 不提取 (too few lines, premature abstraction)
```

**Rationale**: 過早提取 creates coupling harder to undo than duplication。Rule of Three 是 guideline，2+>100 行是 project-specific precedent (TI-004 test_harness.rs extraction)。

---

### MOD-5: No Circular Dependencies

**Rule**: A imports B → B 不得 import A，即使 transitively。

**Trigger**: 新增跨模組 `use` statement 時。

**DO**:
```
protocol.rs → (no imports from test_harness or binary)
test_harness.rs → imports protocol.rs (one direction)
binary → imports test_harness.rs + protocol.rs (one direction)
```

**DON'T**:
```
module_a.rs → use crate::module_b::Foo;
module_b.rs → use crate::module_a::Bar;  // circular!
```

**Rationale**: Circular dependencies 使模組無法獨立編譯或測試，且 Rust compiler 在 binary crate 中允許但 library crate 中可能阻礙拆分。

---

## Cross-References

以下規則與 modularity 相關但 canonical home 在 clean-code.md:
- **CC5 (Single Responsibility)** → 見 clean-code.md CC5
- **CC9 (Max depth 2)** → 見 clean-code.md CC9

## Verification Checklist

1. [ ] 新增的 `use` statement 是否違反 dependency direction？(MOD-1)
2. [ ] Shared code 是否 hardcode binary-specific 值？(MOD-2)
3. [ ] 每個新函式/struct 是否可歸屬到一個 layer？(MOD-3)
4. [ ] 有重複 code 但不到 extraction threshold？(MOD-4)
5. [ ] 是否有 circular import？(MOD-5)
```

- [ ] **Step 2: Verify file renders correctly**

Run: `head -5 docs/coding-standards/modularity.md`
Expected: First 5 lines of the file visible.

- [ ] **Step 3: Commit**

```bash
git add docs/coding-standards/modularity.md
git commit -m "Add modularity coding standard (MOD-1~MOD-5, CA1-CA3 evolved)"
```

---

### Task 3: Create clean-code.md (CC1~CC13)

**Files:**
- Create: `docs/coding-standards/clean-code.md`

- [ ] **Step 1: Write clean-code.md**

```markdown
# Clean Code Standard

**Scope**: 所有程式碼變更
**Severity**: 違規 = HIGH (與 protocol correctness 同級)
**Cross-references**: minimalism.md (MIN-1~MIN-6), modularity.md (MOD-1~MOD-5)
**Origin**: CC1~CC10 from DEVELOPMENT_SOP.md v1.2; CC11~CC13 新增

---

## Rules (CC1~CC10, 保留)

### CC1: One Abstraction Level

**Rule**: 每個函式只在一個抽象層級操作。Orchestration 不混 data manipulation。

**Trigger**: 函式同時包含 high-level flow control 和 low-level byte operation 時。

**DO**:
```rust
/// Execute one round of cell voltage reads. (CC1: delegates to read_one_cell_group)
async fn execute_round(can: &mut CanFd, stats: &mut Stats) -> Result<(), TestError> {
    for group in 0..GROUPS_PER_ROUND {
        read_one_cell_group(can, group, stats).await?;
    }
    Ok(())
}
```

**DON'T**:
```rust
async fn execute_round(can: &mut CanFd, stats: &mut Stats) -> Result<(), TestError> {
    for group in 0..GROUPS_PER_ROUND {
        let frame = can.read().await;
        let bytes = frame.data();
        // low-level: parse voltage from bytes
        let v0 = bytes[0] as f32 * 0.1;
        stats.update(v0);
        // ... mixing orchestration with parsing
    }
}
```

**Rationale**: Clean Code Ch.3 — "one level of abstraction per function"。Mixed levels 使函式難以理解和測試。

---

### CC2: Function Size ≤ 40 Lines

**Rule**: 每個函式 body ≤ 40 行。超過時提取 helper。

**Trigger**: 函式 body > 40 行。

**Accepted Deviation**: `wait_with_demux` — select! macro 展開需要較多行數，提取 helper 會 break ownership。需記錄在 Accepted Deviations Table。

**Rationale**: Clean Code Ch.3 — "Small!" Functions。40 行 = 大約一個螢幕，可一次理解。

---

### CC3: Meaningful Names

**Rule**: Names 是 intention-revealing。不需 comment 解釋命名。

**Trigger**: 新增 variable, function, type, constant 時。

**DO**: `spm_source_address`, `read_cell_voltage`, `HbtTimeoutError`
**DON'T**: `sa`, `read`, `Err3`

**Naming conventions (Rust-specific)**:
- Functions: verbs — `read_cell_voltage`, `validate_crc`, `send_relay_command`
- Types: nouns — `CellVoltage`, `ProtocolError`, `TestHarness`
- Booleans: predicates — `is_valid`, `has_response`, `should_retry`
- Constants: SCREAMING_SNAKE — `MASTER_SA`, `HBT_INTERVAL_MS`

**Rationale**: Clean Code Ch.2 — "intention-revealing names"。

---

### CC4: No Magic Numbers

**Rule**: 有語義的 literal 值用 named constant。

**Trigger**: 程式碼中出現非自明的 literal 時。

**DO**: `const REQUEST_PRIORITY: u8 = 6;`
**DON'T**: `J1939Id::new(6, pgn, sa)` (6 的意義是什麼？)

**Exception**: 0, 1, `0xFF` (padding) 在 context 中自明時不需常數 (配合 MIN-5)。

**Rationale**: Clean Code Ch.17 — "replace magic numbers with named constants"。

---

### CC5: Single Responsibility

**Rule**: 每個函式只有一個改變的理由。Logging 和 logic 分離。

**Trigger**: 函式同時做兩件不相關的事。

**DO**: `read_voltage()` + `log_voltage_result()` 分開
**DON'T**: `read_and_log_voltage()` 混合 CAN 操作和 defmt logging

**Cross-reference**: modularity.md 的 MOD-3 (layer 歸屬) 與此相關。

**Rationale**: Clean Code Ch.10 — SRP。

---

### CC6: No Duplication

**Rule**: DRY — Don't Repeat Yourself。但搭配 MOD-4 extraction threshold。

**Trigger**: 發現兩處以上相同或近似的 code block。

**注意**: 三行重複 code 勝過一個過早抽象 (MIN-1)。只在 MOD-4 threshold 以上才提取。

**Rationale**: Clean Code Ch.17 — DRY。

---

### CC7: Error Handling Explicit

**Rule**: 宣告了就要用。Invalid CRC 不可 silently ignore。每個 CRC/timeout failure 必須 counted and reported。

**Trigger**: match on Result/Option、error propagation、CRC validation。

**DO**:
```rust
match validate_crc(data) {
    Ok(()) => process(data),
    Err(e) => {
        stats.crc_errors += 1;
        return Err(TestError::CrcMismatch(e));
    }
}
```

**DON'T**:
```rust
let _ = validate_crc(data); // silently ignored!
process(data);
```

**Embedded-specific additions**:
- 每個 CAN read 的 timeout 必須用 deadline-based (不是 per-iteration `with_timeout`)
- 每個 CRC validation failure 必須 counted 且 reported
- `unwrap()` 禁止在 production paths (見 CC13)

**Rationale**: Clean Code Ch.7 — "don't return null / don't pass null"。Silent failures 是 safety-critical code 的大敵。

---

### CC8: Comments Only Where Non-Obvious

**Rule**: 不寫多餘 comment。Name + signature 已清楚的不需額外解釋。

**Trigger**: 撰寫 comment 時。

**DO**: CRC scope、transparent mode、protocol quirks → comment
**DON'T**: `let count = 0; // initialize count to zero`

**CC8/CC10 共存**: CC10 要求 doc comment 存在，CC8 管內容品質。自明的 helper 一行 doc 即可。

**Rationale**: Clean Code Ch.4 — "don't comment bad code, rewrite it"。

---

### CC9: Max Nesting Depth 2

**Rule**: 最大 indent depth = 2。`for` + `match` + `if` = depth 3 → 提取 inner block 為 helper。

**Trigger**: 程式碼中出現 depth ≥ 3 的 nesting。

**DO**:
```rust
for item in items {                    // depth 1
    match item.kind {                  // depth 2
        Kind::A => handle_a(item),     // helper, not inline
        Kind::B => handle_b(item),
    }
}
```

**DON'T**:
```rust
for item in items {                    // depth 1
    match item.kind {                  // depth 2
        Kind::A => {
            if item.is_valid() {       // depth 3 — violation!
                process(item);
            }
        }
    }
}
```

**Cross-reference**: modularity.md 參照此規則。

**Rationale**: Clean Code Ch.3 — "indent level should not be greater than two"。CC9 是本專案最常違反的規則 (SOP Lessons Learned)。

---

### CC10: Doc Comments + CC/CA 標註

**Rule**: 所有 public items 和 private items 必須有 doc comment。Design-motivated 情境標註 CC/CA 原則。

**Trigger**: 新增或修改任何 function, struct, enum, constant, module。

**Enforcement**:
- Machine-checkable: `#![warn(missing_docs)]` — public items
- Reviewer-only: private items + CC/CA annotations

**CC8/CC10 共存**: 自明 helper 只需一行 doc，不需 CC/CA annotation。只在 annotation 能回答「為什麼這樣設計」時才加。

**詳細格式**: 見 DEVELOPMENT_SOP.md Section 3.1a。

**Rationale**: Project rule — 設計理由可溯源。

---

## Rules (CC11~CC13, 新增)

### CC11: Dead Code Policy

**Rule**: 不留 dead code。`#[allow(dead_code)]` 僅限 `spn.rs` 中為 protocol completeness 定義的 types。

**Trigger**: 出現 commented-out code、unused function、或 `#[allow(dead_code)]` 時。

**DO**: 刪除 unused code。如果未來可能需要，git history 有記錄。
**DON'T**: `// let old_value = compute(); // might need later`

**Machine-enforce**: `#![deny(dead_code)]` on new modules。

**Rationale**: Dead code 誤導 reviewer，增加認知負擔，且在 embedded 中浪費 flash。

---

### CC12: Const Correctness

**Rule**: 能 `const` 就 `const`，能 `const fn` 就 `const fn`。

**Trigger**: 新增 variable, function, 或 value 時。

**DO**:
```rust
const MAX_CELLS: usize = 20;
const fn crc_scope_len(sub_pgn: u8) -> usize { /* ... */ }
```

**DON'T**:
```rust
let max_cells = 20; // should be const
fn crc_scope_len(sub_pgn: u8) -> usize { /* ... */ } // could be const fn
```

**Rationale**: `const` 讓 compiler 在 compile time evaluate，減少 runtime overhead 且明確表達 intent。

---

### CC13: No Unwrap in Production Paths

**Rule**: Library code 用 `Result`/`Option`，不 panic。Binary 入口可 `unwrap()` 但必須 comment why safe。

**Trigger**: 出現 `.unwrap()`, `.expect()` 時。

**DO**:
```rust
// In library code:
fn parse_frame(data: &[u8]) -> Option<CellVoltage> {
    let raw = data.get(0)?;
    Some(CellVoltage(*raw))
}

// In binary main:
let peripherals = embassy_stm32::init(config); // infallible per embassy contract
```

**DON'T**:
```rust
// In library code:
fn parse_frame(data: &[u8]) -> CellVoltage {
    CellVoltage(data[0]) // panics on empty slice!
}
```

**Rationale**: Safety-critical embedded code 不應 panic in library paths。Binary 入口的 `unwrap` 是 acceptable 因為 failure = hardware misconfiguration (no recovery possible)。

---

## Compiler-Enforced Subset

| Lint | Rule | Scope |
|------|------|-------|
| `#![warn(missing_docs)]` | CC10 | Public items |
| `#![deny(unused_imports)]` | MIN-6 | All code |
| `#![deny(dead_code)]` | CC11 | New modules |

## Verification Checklist

1. [ ] 每個新/修改函式 ≤ 40 行？(CC2)
2. [ ] Max nesting depth ≤ 2？(CC9)
3. [ ] 每個 Result/Option 都有 explicit handling？(CC7)
4. [ ] 無 `.unwrap()` in library code？(CC13)
5. [ ] 無 dead code 或 commented-out code？(CC11)
6. [ ] 每個新 item 有 doc comment？(CC10)
7. [ ] 命名自明 (verbs for functions, nouns for types)？(CC3)
```

- [ ] **Step 2: Verify file renders correctly**

Run: `head -5 docs/coding-standards/clean-code.md`
Expected: First 5 lines of the file visible.

- [ ] **Step 3: Commit**

```bash
git add docs/coding-standards/clean-code.md
git commit -m "Add clean code standard (CC1~CC10 preserved + CC11~CC13 new)"
```

---

### Task 4: Update CLAUDE.md (Red Lines + Reference Files + Cross-AI note)

**Files:**
- Modify: `CLAUDE.md:38` (add one line after Cross-AI Review Workflow)
- Modify: `CLAUDE.md:70-74` (insert Red Lines section after Workflow Preferences)
- Modify: `CLAUDE.md:114` (add 3 rows to Reference Files table)

- [ ] **Step 1: Add dual-review note to Cross-AI Review Workflow**

Check if the line already exists (unstaged from earlier session):

```bash
git diff CLAUDE.md | grep "dual-review"
```

If the diff already shows `+**程式碼實作**: 額外使用 /dual-review ...`, skip to Step 2 — the line is already in place.

If NOT present, in `CLAUDE.md` after line 39 (`**流程**: Claude 產出 -> ...`), add:

```markdown
**程式碼實作**: 額外使用 `/dual-review` 流程 (Agent B + Codex 雙重審查)。見下方 Coding Standards。
```

- [ ] **Step 2: Insert Coding Standards Red Lines section**

In `CLAUDE.md`, between `## Workflow Preferences` (ends at line 74) and `## Project Context Sync Checklist` (starts at line 77), insert:

```markdown
---

## Coding Standards (Red Lines)

三份 reference documents 定義完整 coding standards。進入 coding phase 時讀取相關文件。
以下紅線 ALWAYS active — 每次程式碼變更都必須遵守:

1. **MIN-2**: 只改被要求的範圍。不 drive-by refactor。
2. **MIN-1**: 不為假設的未來需求寫 code。
3. **CC2**: 每個 function ≤ 40 行。
4. **CC9**: Max nesting depth 2。depth 3+ 提取 helper。
5. **CC7**: Error handling 必須 explicit。CRC/timeout failure 不可 silently ignore。
6. **MOD-1**: Inner layers 不 import outer layers。

Full rules: `docs/coding-standards/minimalism.md`, `modularity.md`, `clean-code.md`
每次程式碼實作完成後，使用 `/dual-review` 執行雙重審查 (預設觸發，使用者可 skip)。
```

- [ ] **Step 3: Add Reference Files entries**

In `CLAUDE.md` Reference Files table (after line 114), add three rows:

```markdown
| Minimalism rules | `docs/coding-standards/minimalism.md` | MIN-1~MIN-6, scope control, anti-patterns |
| Modularity rules | `docs/coding-standards/modularity.md` | MOD-1~MOD-5, layer diagram, extraction criteria |
| Clean Code rules | `docs/coding-standards/clean-code.md` | CC1~CC13 canonical, naming, error handling, dead code |
```

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "CLAUDE.md: add Coding Standards Red Lines + Reference Files"
```

---

### Task 5: Update SOP Section 7

**Files:**
- Modify: `design/DEVELOPMENT_SOP.md:316-353` (replace CC/CA tables with quick reference)

- [ ] **Step 1: Replace SOP Section 7**

Replace lines 318-353 (from `### CC Rules` through `### 原則標註要求` block end) with:

```markdown
## 7. CC/MOD/MIN Rules Quick Reference

完整規則見 `docs/coding-standards/` 三份文件:

- **Minimalism (MIN-1~MIN-6)**: `docs/coding-standards/minimalism.md`
- **Modularity (MOD-1~MOD-5)**: `docs/coding-standards/modularity.md` (含原 CA1-CA3)
- **Clean Code (CC1~CC13)**: `docs/coding-standards/clean-code.md` (含原 CC1-CC10 + 新增 CC11-CC13)

### CA → MOD Mapping

| 舊編號 | 新編號 | Rule |
|--------|--------|------|
| CA1 | MOD-1 | Dependency direction |
| CA2 | MOD-2 | Boundary interface |
| CA3 | MOD-3 | Layer 歸屬 |

CC 編號不變。SOP 其他 section 中的 CC/CA 引用保持有效 (CC 編號未改，CA 有上方 mapping)。

### 原則標註要求
```

Note: 保留 `### 原則標註要求` 以下的內容 (lines 345-353) 不動 — 那是 doc comment annotation 規則。

- [ ] **Step 2: Verify remaining SOP references still valid**

Run: `grep -n "CC[0-9]\|CA[0-9]" design/DEVELOPMENT_SOP.md | head -20`
Expected: All CC/CA references in other sections still point to valid rule numbers.

- [ ] **Step 3: Commit**

```bash
git add design/DEVELOPMENT_SOP.md
git commit -m "SOP Section 7: replace CC/CA tables with quick reference to coding standards docs"
```

---

### Task 6: Create dual-review skill

**Files:**
- Create: `~/Projects/claude-code-skills/dual-review/SKILL.md`
- Create symlink: `~/.claude/skills/dual-review`

- [ ] **Step 1: Create skill directory**

```bash
mkdir -p ~/Projects/claude-code-skills/dual-review
```

- [ ] **Step 2: Write SKILL.md**

```markdown
---
name: dual-review
description: Use when code implementation is complete and needs quality review. Triggers on "/dual-review" or after code changes. Asks user confirmation before starting. Runs Agent B (Claude subagent) then Codex adversarial review against project coding standards.
---

# Dual Review — Agent B + Codex Adversarial

程式碼實作完成後的雙重審查流程。

## 1. 觸發

### 主動觸發
使用者輸入 `/dual-review` 或要求 code review。

### 自動建議
程式碼實作 (新函數、新測試、新 binary) 完成後，詢問:

> "要執行 dual-review 嗎？(Y/n, 預設不限次數，可指定 rounds=N)"

使用者回 n → 跳過。使用者回 y 或直接 Enter → 開始。
使用者可指定: `rounds=3` 限制最大輪數。

## 2. 收集變更

```bash
git diff          # unstaged
git diff --cached # staged
git diff --stat   # summary
```

若無變更，告知使用者並結束。

## 3. Stage 1: Agent B Review (Claude Subagent)

### 3.1 Spawn Agent B

使用 Agent tool，subagent_type: `superpowers:code-reviewer`。

Prompt:

```
You are a strict code reviewer for a safety-critical embedded Rust project.
Project: STM32H563 Master Board CAN bus integration testing.
Safety: IEC 60730-1 Annex H Class B.

Read these coding standards before reviewing:
- {project_root}/docs/coding-standards/minimalism.md
- {project_root}/docs/coding-standards/modularity.md
- {project_root}/docs/coding-standards/clean-code.md

Review the following changes against ALL rules in those documents.

For each issue found, classify severity:
- P1 (must fix): Violates a rule or introduces defect
- P2 (should fix): Reduces clarity or maintainability
- P3 (suggestion): Optional improvement

Changes:
{git_diff}

Files modified:
{file_list}

Output format:
| # | File:Line | Rule | P | Issue | Suggested Fix |
```

Replace `{project_root}` with actual working directory, `{git_diff}` with diff output, `{file_list}` with changed file list.

### 3.2 Evaluate Findings

對 Agent B 的每一項 finding，獨立評估:

- **同意**: Fix it
- **不同意 (附理由)**: Agent B 判斷有誤或不適用
- **部分同意**: Valid concern，但用不同方式解決

輸出 consensus table:

```markdown
### Agent A ↔ B Consensus (Round N)
| # | Agent B Finding | Agent A Response | Action |
|---|----------------|-----------------|--------|
| 1 | [finding] | 同意 | Fix |
| 2 | [finding] | 不同意: [reason] | Skip |
```

### 3.3 Iterate

1. Apply 同意的 fixes
2. Re-spawn Agent B on updated diff
3. 重複直到 Agent B 找不到 new issues (共識達成)
4. 每輪顯示: `Round N complete: M new issues found`
5. 使用者可隨時喊停
6. **Hard requirement**: 所有 P1 必須 resolved

## 4. Stage 2: Codex Adversarial Review

### 4.1 觸發 Codex Review

使用 `/codex-reviewer` skill (Section 5-8 審查流程)。

在 context 中加入 adversarial focus:

> Focus on finding blind spots that the implementation author and Agent B reviewer
> may have BOTH missed. Look for: implicit assumptions, edge cases in CAN protocol
> handling, CRC scope errors, timeout logic, startup race conditions.

### 4.2 Codex Consensus Loop

使用 `/codex-reviewer` Section 9 共識評估模式。

同樣規則:
- 預設不限次數，直到共識
- 使用者可指定 rounds 或隨時喊停
- 所有 P1 必須 resolved

## 5. Stage 3: Final Summary

```markdown
### Dual Review Summary

**Agent B**: N rounds, M total findings (X fixed, Y rejected, Z suggestions noted)
**Codex**: N rounds, M total findings (X fixed, Y rejected, Z suggestions noted)
**P1 status**: All resolved ✅

| Source | # | Finding | Rule | P | Resolution |
|--------|---|---------|------|---|------------|
```

未解決的 P2+ 列出供使用者 awareness。
```

- [ ] **Step 3: Create symlink**

```bash
ln -sf ~/Projects/claude-code-skills/dual-review ~/.claude/skills/dual-review
```

- [ ] **Step 4: Verify skill is discoverable**

Run: `ls -la ~/.claude/skills/dual-review`
Expected: Symlink pointing to `~/Projects/claude-code-skills/dual-review`

- [ ] **Step 5: Commit skill to claude-code-skills repo**

```bash
cd ~/Projects/claude-code-skills
git add dual-review/SKILL.md
git commit -m "Add dual-review skill: Agent B + Codex adversarial review"
```

---

### Task 7: Archive research findings + final verification

**Files:**
- Move: `docs/coding-standards/RESEARCH_FINDINGS.md` → `references/archive/docs/RESEARCH_FINDINGS_CODING_STANDARDS.md`

- [ ] **Step 1: Archive research findings**

```bash
mkdir -p references/archive/docs
git mv docs/coding-standards/RESEARCH_FINDINGS.md references/archive/docs/RESEARCH_FINDINGS_CODING_STANDARDS.md
```

- [ ] **Step 2: Verify all cross-references**

```bash
# CC references in codebase still valid
git grep "CC[0-9]" -- '*.md' | grep -v archive | grep -v RESEARCH | head -10

# Check new docs exist
ls docs/coding-standards/*.md

# Check skill symlink
ls -la ~/.claude/skills/dual-review/SKILL.md
```

- [ ] **Step 3: Run /dual-review to test skill loads**

Manually trigger `/dual-review` in Claude Code to verify the skill is recognized.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "Archive research findings, verify coding standards + dual-review integration"
```

- [ ] **Step 5: Push both repos**

```bash
git push  # can_integration_testing
cd ~/Projects/claude-code-skills && git push  # claude-code-skills
```
