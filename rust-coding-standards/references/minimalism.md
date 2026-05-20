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

**Rationale**: 泛化會吃掉 code size (monomorphization) 與認知負擔。等到第二個 concrete type 出現再泛化。YAGNI — You Aren't Gonna Need It。

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

**Rationale**: AI coding assistant 最常見的 complaint: 「helpfully」順手 refactor 旁邊的 code。社群報告中影響力最高的一條規則。

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

**Rationale**: Safety-critical code 的原則是處理所有真正會發生的 error path，不是想像得到的所有 path。Phantom error path 讓 code 變複雜，也會誤導 reviewer。

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

**Rationale**: 沒 invariant 的 newtype 只增加 boilerplate (`.0` access、`From` impl)，不帶來 safety benefit。

---

### MIN-5: Constant Introduction Threshold

**Rule**: 2+ 次出現或語義不明才提取為 named constant。

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

**Rationale**: 常數提太多會讓 code 更難讀，因為 reader 得跳到定義處確認。只有在重複出現或語義不明時才值得提。

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

**Rationale**: Unused import 就是 dead code。`#![deny(unused_imports)]` 可以讓 compiler 直接擋掉。

---

## Verification Checklist

實作完成後，self-check:

1. [ ] 是否有新增不在 task scope 的改動？(MIN-2)
2. [ ] 是否有 generic/trait 只被一個 concrete type 使用？(MIN-1)
3. [ ] 是否有 error path 處理了 impossible condition？(MIN-3)
4. [ ] 是否有 newtype 沒有 invariant？(MIN-4)
5. [ ] 是否有只出現一次的 named constant？(MIN-5)
6. [ ] 是否有 unused imports？(MIN-6)
