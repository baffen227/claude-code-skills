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

**Rationale**: Clean Architecture 的 Dependency Rule — inner layer 是穩定的 business rule，outer layer 是容易變動的 delivery mechanism。反向依賴會讓 inner layer 無法獨立測試或重用。

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

**Rationale**: Hardcode 的值會讓 shared code 無法在不同配置的 binary 之間重用。TI-004 的教訓: SPM_SA hardcode 經過 3 輪 review 才抓完。

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

**Rationale**: 跨 layer 的函式無法獨立測試，而且 change 的原因不單一，違反 CC5 SRP。

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

**Rationale**: 過早提取會製造比重複更難回退的 coupling。Rule of Three 是通則，「2 個 binary + >100 行」是本專案的 precedent (來自 TI-004 test_harness.rs 的抽取經驗)。

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

**Rationale**: Circular dependency 讓模組無法獨立編譯或測試。Rust compiler 在 binary crate 會允許，但 library crate 可能會擋下拆分。

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
