# Rust Embedded Coding Guideline — 可貼用 Prompt / Context

來源：Firmware Wiki（專案結構與模組佈局規範 Part 0–IX + Coding Standards CC/MIN/MOD）。
用法：日常小改動貼 **§A**；新模組 / 重構 / code review / 大改貼 **§A + §B**。

> **Provenance（Harry 收檔註記,2026-08-20）**: Eden 提供的可貼用濃縮版;正本在 Firmware Wiki,本檔是 snapshot,Wiki 更新時手動同步。**團隊層文件** — 與本 skill 其餘 references(個人 enforcement 層)的關係:CC/MIN/MOD 編號同源;引用時本檔代表團隊共識,個人層條文(nova-conventions NAME/DOC/…)未經 co-design,以「建議 + 出處」提出。
>
> **與 nova 現況的已知衝突 — 引用本檔前必讀**:
>
> 1. **B5 `[workspace.lints]`**:nova 現況「無 `[workspace.lints]`,lint 靠各 recipe 的 `-D warnings` CLI flag;新 crate 加 `[lints] workspace = true` 會報 workspace.lints was not defined」(nova CLAUDE.md)。B5 是目標態,遷移是獨立工作項,不得在一般 PR 順手照抄。profile 設定同理,先比對 nova root `Cargo.toml` 現況。
> 2. **§A「task/ 只透過 trait 碰 bsp」**:與 nova co-design 紅線直接衝突 —「別引入 `CanDriver` trait;`tasks` 維持 concrete `AdlinkBufferedCanFd`,泛型化是 co-design 後的事」(nova CLAUDE.md co-design 邊界)。不得據本檔單方引入 trait 邊界。
> 3. **六資料夾架構與 mod.rs 模組佈局**:目標態。nova 現況 = `bins/crates/tests/vendor/experiments`,crates 內多為平鋪檔案。既有碼不因本檔順手重構(MIN-2);新模組可照本檔佈局。
>
> 衝突時優先序:**專案 CLAUDE.md 紅線 + co-design 邊界 > 本檔(團隊層) > 個人層條文 > reviewer judgment**。§C 的「尚未拍板」清單遇到就問,不自行決定。

---

## §A 極簡版（約 40 行，日常貼用）

```
你在協助一個 no_std / embassy / STM32H5(F4) 的 Rust 韌體專案。所有產出遵守以下規範，
違反規範視同 protocol correctness bug，同等嚴重。

【架構】六資料夾，依賴單向不可逆：
  bin ──▶ task ──▶ lib
   │        └──▶ (trait) ──▶ bsp ──▶ vendor
   └──────────────────────────▶ bsp
  bin/ 只有 main 與接線｜bsp/ 碰硬體(暫存器/DMA/中斷/FFI)｜lib/ 純邏輯不碰硬體不 spawn
  task/ async loop/狀態機/IPC，只透過 trait 碰 bsp｜tests/ on-target/on-qemu｜vendor/ 第三方 C
  lib/ 不得依賴 bsp/ 或 task/；bsp/ 不得依賴 task/。

【這段程式碼放哪】依序套用，第一個成立者勝出：
  1. 讀寫暫存器 / 設中斷 / vendor FFI → bsp/
  2. 有 #[embassy_executor::task] 或長駐 loop 或擁有 Channel/Signal → task/<module>/
  3. 有 fn main → bin/ 或 tests/
  4. 皆非 → lib/
  抽取門檻 Rule of Three：bsp 與 task 都要用 → 直接拆 lib/；同層第三次出現才拆。

【模組佈局】一模組 = 一資料夾，只放 .rs，不得再開子資料夾（協定模組 server/+handler/ 兩層為硬上限）
  mod.rs [MUST] 門面：只有 mod 宣告 + 明列 pub use，不寫邏輯，禁止 pub use xxx::*
  error.rs [MUST] snafu，本模組唯一 Error + type Result
  impls.rs [MUST] 核心邏輯（絕不叫 core.rs）
  可選：types.rs / api.rs(trait 契約) / consts.rs(編譯期) / config.rs(執行期可調) / state.rs / ipc.rs
  外部只看一層：use task::bms::{BmsTask, BmsError}；內部 mod 一律私有。consts 保留 namespace 不攤平。

【禁則】core.rs / alloc.rs / test.rs / utils.rs / common.rs / helper.rs / misc.rs / dto.rs /
  globals.rs / static mut ── 一律禁止新增。

【型別】跨模組物理量一律 newtype，禁裸 u16/i16/f32：Millivolt(u16)、DeciCelsius(i16)、CanId(u32)。
  wire format → 協定模組根 frame.rs/pdu.rs/regs.rs｜domain model → lib/model（不得複製）｜私有 → types.rs

【共享狀態】blackboard 不是 database。純 struct 在 lib/，static 只有一行在 task/。
  每欄位單一寫入者（表維護在 task/database/mod.rs doc）。值帶時間戳，get() 回 Result<T, Stale>。
  寫入 fn 一律 pub(crate)，讀取才 pub。用 blocking_mutex，臨界區內絕不 .await。

【分派】bsp 邊界 / ISR / hot path / 任何 async trait → 泛型或 impl Trait [MUST]。
  冷路徑大函式 × 多型別才用 &dyn。泛型留薄殼、肥邏輯收進非泛型 inner fn（outlining）。
  任何以「省 flash」為由的改動，必須附 cargo bloat / cargo size 前後數據。

【Clean Code】一函式一抽象層｜≤40 行｜巢狀 ≤2 層｜無魔術數字｜錯誤顯式處理不可 let _ =｜
  lib 路徑不得 unwrap｜mask+cast 優於 #[allow(cast_possible_truncation)]｜無死碼｜const 優先。
【Minimalism】不做投機抽象、只改被要求的範圍、不寫硬體不可能產生的錯誤路徑、常數 2 次以上才提。

不確定時先問，不要臆測；引用規則時標明是哪一條，沒有依據就註明「reviewer judgment」。
```

---

## §B 完整版（新模組 / 重構 / review 時追加）

### B1. 協定模組（modbus / ems_can / adlink_can / uds）

* **共用的一律上提到協定模組根** [MUST]：`error.rs` / `frame.rs` / `regs.rs` / `transport.rs` / `config.rs` / `consts.rs`。
  `regs.rs` 是**協定契約**（client 組位址、server 路由、tests 斷言），埋進 `server/` 是錯的。
* **Client 與 Server 不必對稱** [SHOULD]：`client.rs` 單檔 + `server/` 一棵樹是正確的不對稱。
* **Handler 的切分軸 = 協定自己的切分軸** [MUST]：
  Modbus→register block｜UDS→SID/DID｜J1939/adlink→PGN｜CANopen→OD index。
  配套三條：① 檔名 = `regs::X.name`；② 所有 handler 簽章一致 `fn handle(&Request, &mut Ctx) -> Result<Response>`；③ 不用 `dyn Handler`，router 退化成平的 match 對照表。
* `handler/`：≤4 group 或 <600 行 → 單檔 `handlers.rs`；≥5 group → 資料夾。兩者並存不需統一。
  `handler/bms.rs` 太長 → 拆成 `handler/bms_measure.rs` + `bms_command.rs`，**不可**開 `handler/bms/`。
* 不該待在 `handler/` 的：`helper.rs`（併入 `server/response.rs` 或改成 `lib/model` newtype 方法）、`test_hooks.rs`（移 `server/hooks.rs` 並 feature-gate）。

### B2. 共享狀態 primitive 對照表

| 存取型態 | Primitive |
|---|---|
| 多欄位需一致快照（電壓+電流算功率） | `blocking_mutex::Mutex<CS, RefCell<Db>>` |
| 單寫多讀，要最新值 + 變更通知 | `Watch<CS, T, N>` |
| 單寫單讀，「有新資料叫我」 | `Signal<CS, T>` |
| 不能掉的事件序列（命令、告警） | `Channel<CS, T, N>` |
| 單一計數器 / 旗標 | `AtomicU32` / `AtomicBool` |
| 開機後才 init 的 peripheral handle | `StaticCell<T>` |
| 唯讀查表 | 不可變 `static`（落 `.rodata`，不吃 RAM） |

* 鎖粒度按**一致性域**分組：`pack`+`cells` 同一把；`relay` 另一把；`faults` 用 atomic bitfield（emergency path 不等鎖）。
* `Db::new()` 必須 `const fn` 且全零初始化 → 落 `.bss`；有非零預設值會變 `.data`（flash + RAM + 開機 memcpy）。
* ISR 會碰 → `CriticalSectionRawMutex`；確定同 executor → `NoopRawMutex`，但此假設**必須寫在 doc comment**。
* 連帶效果：`Err(Stale)` 剛好映射成 Modbus exception（`SlaveDeviceFailure` 0x04），優於回傳陳舊的 `0`。

### B3. 分派與尺寸

* vtable 在 `.rodata`（flash），**不佔 RAM**；`&dyn` 是 2-word fat pointer 在 stack。`.data` 的兇手是非零初始化 mutable static。
* 泛型 = 可 inline / const-propagate，代價 `.text` 隨型別數線性成長；`dyn` = 一份程式碼，代價失去 inline 與 const-fold。HAL 層 const-propagation 特別值錢 → `bsp` 必須靜態分派。
* `no_std` 下 `&dyn` / `&mut dyn` 完全可用，只有 `Box<dyn>` 需要 alloc。AFIT 不可直接 dyn → **async trait 邊界一律靜態分派**。
* `#[embassy_executor::task]` 對泛型支援有限 → task 邊界收斂成具體型別，泛型留內層。
* Sealed trait [SHOULD]：`api.rs` 中不打算讓外部實作的 trait 應 seal。
* 量測指令：`cargo bloat --release --bin X -n 30`、`cargo size --release -- -A`、`arm-none-eabi-nm --size-sort -S`。
  profile（`opt-level="z"` / `lto="fat"` / `codegen-units=1` / `panic="abort"`）影響通常大於分派方式選擇。

### B4. 測試佈局

* 共用邏輯收進 crate 的 `lib.rs`；每個測試 bin **只留一個檔 + 一份 `TestSpec` 常數**。
* 差異若無法用 `TestSpec` 欄位表達 → 用 `api.rs` 的 trait hook 注入，**不得複製 scaffold**。

### B5. CI 強制（workspace root Cargo.toml）

```toml
[workspace.lints.clippy]
mod_module_files              = "deny"   # 與 self_named_module_files 互斥，本專案選 mod.rs
wildcard_imports              = "deny"
missing_docs_in_private_items = "allow"

[workspace.lints.rust]
missing_docs           = "warn"
unsafe_op_in_unsafe_fn = "deny"
static_mut_refs        = "deny"

[profile.release]
opt-level = "z"; lto = "fat"; codegen-units = 1; panic = "abort"; debug = true
```
各 member crate 加 `[lints] workspace = true`。

### B6. 規則編號速查（Coding Standards）

* **CC1–CC14**：一函式一抽象層｜≤40 行｜意圖命名｜無魔術數字｜SRP｜DRY（受 MOD-4 節制）｜顯式錯誤處理 + deadline timeout｜註解只寫非顯而易見｜巢狀 ≤2｜pub item 要 doc｜無死碼｜const correctness｜lib 不得 unwrap｜mask+cast 優於 `#[allow]`。
* **MIN-1–6**：不投機抽象｜範圍控制不順手重構｜不寫「以防萬一」錯誤路徑｜wrapper 要有正當理由｜常數 2 次以上才提｜import 潔癖。
* **MOD-1–5**：依賴方向 Adapter→UseCase→Entity｜邊界以參數傳入不硬編｜每個 fn/struct 只屬一層且 module doc 註明｜抽取門檻 Rule of Three（或 2 binaries + >100 行）｜禁循環依賴（含 transitive）。

### B7. 採用的設計模式

Ports & Adapters（`api.rs` = port、`bsp` = adapter、`tests` 注入 mock）｜Facade / re-export（`mod.rs`）｜Blackboard（`lib/database` + `task/database`）｜Newtype（`lib/model`）｜Type State（`Relay<Open>` → `Relay<Closed>`）｜Sealed Trait｜RAII Guard｜Table-driven dispatch｜Builder｜盡量用 `embedded-hal` 標準 trait 而非自訂。

### B8. PR Review Checklist

**結構**：新模組有 mod.rs/error.rs/impls.rs｜mod.rs 無邏輯｜無 glob re-export｜無禁用檔名｜模組內無子資料夾｜依賴方向未反向
**型別**：跨模組物理量用 `lib/model` newtype｜未複製 domain 型別到 `types.rs`
**協定**：共用項在模組根｜handler 檔名對得上 `regs.rs` block name｜handler 簽章一致
**狀態**：無 `static mut`｜新共享狀態已登記唯一寫入者｜寫 `pub(crate)` / 讀強制時效檢查｜臨界區內無 `.await`
**效能**：bsp 邊界與 async trait 為靜態分派｜引入 `dyn` 附 `cargo bloat` 前後數據
**測試**：未複製 scaffold，差異以 `TestSpec` 或 trait hook 表達

---

## §C 尚未拍板（別讓我自行決定，遇到請先問）

1. **函式長度**：韌體 CC2 為 ≤40 行，Backend 為 50±25 — 尚未統一。
2. **`Trait` 後綴**：韌體跟隨 std 不加後綴（`AsyncCan`、`Frame`）；Backend 要求加 `ContainerTrait` — nova 合併時未決。
3. **Heap / `no_std` 政策**：nova-wide 尚無書面規則（defmt `alloc` + 小 static heap vs heap-free）。
4. **錯誤表示法**：CC7「顯式處理」已定案，但 error taxonomy、`snafu` 適用範圍、`no_std`/host 邊界未定。
5. **Type-alias 邊界規則**（`AdlinkBufferedCanFd` 這類具體 alias 收斂泛型傳染）：已在實作，尚未寫成規則。
6. **嚴重度分級與豁免流程**、**agent review 是否 merge-blocking**：未定。

---

## §D 引用來源階層（給我下判斷時用）

hand-curated atomic notes → 官方 canon（Rust API Guidelines / Rust Reference / Rustonomicon / Embassy Book / Clippy lint index）→ crate docs。
無 canon 可引時，**明確標示「reviewer judgment」**，不得把個人意見包裝成規範。
