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

**Rationale**: Clean Code Ch.3 — "one level of abstraction per function"。層級混用的函式難懂也難測。

---

### CC2: Function Size ≤ 40 Lines

**Rule**: 每個函式 body ≤ 40 行。超過時提取 helper。

**Trigger**: 函式 body > 40 行。

**Accepted Deviation**: `wait_with_demux` — `select!` macro 展開行數多，硬抽 helper 會打破 ownership。已記錄在 Accepted Deviations Table。

**Rationale**: Clean Code Ch.3 "Small!" Functions。40 行大約是一個螢幕，可以一次讀完。

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

**Rationale**: Clean Code Ch.7 "don't return null / don't pass null"。Silent failure 是 safety-critical code 的頭號殺手。

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

**Rationale**: Clean Code Ch.3 "indent level should not be greater than two"。CC9 是本專案最常被違反的規則 (SOP Lessons Learned)。

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

**Rationale**: Dead code 會誤導 reviewer、增加認知負擔，在 embedded 還會吃掉 flash。

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

**Rationale**: `const` 讓 compiler 在 compile time 就算好值，省掉 runtime overhead，也把意圖講清楚。

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

**Rationale**: Safety-critical embedded code 在 library path 不該 panic。Binary 入口的 `unwrap` 可以接受，因為失敗等同 hardware misconfiguration，沒救了。

---

### CC14: Mask + Cast 優於 `#[allow(cast_possible_truncation)]`

**Rule**: Narrowing 整數 cast (例如 `u32 → u16`、`u16 → u8`) 若目的是取低 N bit,用 `(x & MASK) as SmallerType` 的 mask + cast 寫法,不用 `#[allow(clippy::cast_possible_truncation)] + x as SmallerType`。

**Trigger**: workspace `pedantic` / `nursery` deny-level 擋住 `as` narrowing cast,準備加 local `#[allow]` 時。

**DO**:
```rust
// 明確表達「只要低 16 bit」,mask 的數學結果保證落在 u16 範圍內,clippy 不擋
let pgn_low16 = (pgn.pgn_number() & 0xFFFF) as u16;
```

**DON'T**:
```rust
// 需要 local opt-out + comment 解釋 truncation,reader 得多一步理解
#[allow(clippy::cast_possible_truncation)]
let pgn_low16 = pgn.pgn_number() as u16;
```

**Rationale**: Mask + cast 把「我只要低 N bit」的意圖寫進 code 本身,clippy 看得懂不擋,也不需要 `#[allow]` 當 escape hatch。`#[allow]` 每用一次都增加未來審查成本 (reviewer 要判定是否仍合理);mask 是 semantic 層描述,無需豁免。

**Source**: PR α commit #1 self-review empirical (2026-04-22)。原 `#[allow]` 版本通過 Codex round 2 review,self-review 發現 mask 版本在語意、工具相容性、`#[allow]` 庫存三個維度都較佳。

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
