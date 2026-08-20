# nova 時代慣例與教訓

**Scope**: nova(BTBU 產品韌體 repo)與後續 BTBU 嵌入式 Rust 專案
**Status**: 個人 agent enforcement 層,非團隊 SOT。團隊正本候選是 Wiki〈she-bms Firmware — Coding Standards (co-design draft)〉。本檔規則未經 co-design 拍板;引用到隊友的程式碼時,以「建議 + 出處」提出,不當紅線。
**Origin**: 2026-08-09 蒸餾自 nova PR #1–#73 全部 review 意見(181 則 inline comments)、review-fix commits,以及 FW-211/212/215、FW-164 等工作項紀錄。出處標 PR 編號或 commit sha,皆可在 GitHub 覆核。**本檔是活文件**:重大 review 的 taste 層教訓(lint/gate 抓不到的命名、術語、註解、文件分層)持續追加 — 2026-08-20 自 PR #90 七輪可讀性重構補入 NAME-9~11、DOC-8~10;回收動作掛在 dual-review skill 的收尾步驟。
**Cross-references**: clean-code.md (CC1~CC14)、minimalism.md (MIN-1~6)、modularity.md (MOD-1~5)

三份舊 canonical 檔管「函式怎麼寫」;本檔收 nova 實戰長出的新層:error 慣例、契約進碼、no_std 紀律、FFI/vendor 紀律、測試與建置關卡。條目按主題分組,ID 與 CC/MIN/MOD 不重疊。

---

## ERR — Error handling(snafu 慣例)

nova 全 repo 被 review 講最多次的主題(PR #11、#31、#34、#40、#47、#59、#62、#64 至少 9 處)。error 慣例以 she-ems repo 為樣板(`a0c3820`「adopt she-ems error conventions」)。

### ERR-1: 每個 module 一個 `error.rs`,snafu derive

Error enum 集中在該 module 的 `error.rs`,`#[derive(Snafu)]`,每個 variant 帶 `#[snafu(display(...))]`。derive 集依需要加 `Clone` / `Copy` / `Eq` / `defmt::Format`。workspace 用 `snafu = { default-features = false }`(`no_std` 相容)。
出處: PR #34 Eden「if you create `error.rs` in self-test mod, it will be crystal clear that `crate::error::Something` is called by others」;PR #11、#59 整支 PR 就在做這件事。

### ERR-2: error 型別靠 module path 消歧義

命名 `region::Error` 不是 `RegionError`;不冠模組前綴、不在 crate root re-export。每個 error module 配 `pub type Result<T>` alias,簽名用 alias 拼寫;snafu 加 `visibility(pub)`。一個 module 恰一個 `Error` — 同 module 兩個 enum 有同名 variant 會生撞名的 snafu selector,多個 error 就拆 module。
出處: nova issue #54(contract v1.3 定案)、FW-164 M2。

### ERR-3: 豁免 — wire 協議回應碼不套 snafu

會轉成協議回應碼送上 bus 的值(UDS NRC 這類)保持原始數值型別;snafu 只管內部錯誤。
出處: PR #62 Eden 問「why not snafu」、Leo 以 wire 對映理由回覆成立。

### ERR-4: typed error vs `debug_assert!` 的分界

違規與否取決於 runtime 資料的,用 typed error;`debug_assert!` 只留給純程式端不變量 — release build 會把它編掉,而 release 正是會出事的場合。
出處: PR #63 Jerry(`page_program` 跨頁檢查)。

### ERR-5: 安全判定型別 fail-closed decode

`Default` / 未初始化 / 全零表示必須解讀為「未通過」,並以回歸測試鎖死。外部編碼進來的值只認白名單 pattern(ST 的 sparse pattern 設計),raw 0 與 raw 1 都落 Error 臂 — 預設值不得等於通過。
出處: FW-211 contract(`PostReport::default().passed()` 必為 false)。

### ERR-6: Make invalid states unrepresentable

參數型別只涵蓋合法值域:注入用的 forced verdict 收窄成 `ForcedFailure { Failed, Error }`,「注入一個 pass」直接變編譯錯誤。error variant 歸屬精確到失敗元件 — 寧可加 `SchedulerInitKo` 也不重用 `SchedulerKo { tm }` 讓某顆 TM 背 scheduler 的鍋。
出處: FW-211 PR #28 前對抗式 review。

### ERR-7: 兩類事實用型別分開,不從殘值重建

「排程器故障」與「硬體 fault verdict」是兩類事實:用 `Slice::Faulted(TmVerdict)` 這類 Ok variant 沿回傳值傳遞,不要折疊成同一個 `Err` 再回頭讀 out-param 猜 — 文件明說 KO 時 out-param 無意義。
出處: PR #36 Eden(CHANGES_REQUESTED 主項)。

### ERR-8: default-fallback 要分類上報

讀不到持久化設定可以用 default,但 Loaded / Unprovisioned / Corrupt / HardwareFault 四類結果必須區分並各自 latch 告警。「用了預設值」本身是需要被觀測到的事件,不得把 Corrupt 與新板未 provision 混為一談。
出處: FW-164 v2 設計決策。

### ERR-9: 緊急路徑不因錯誤處理引入額外轉移

EmergencyStop 這類最高優先路徑,錯誤處理不得改變狀態轉移(導向 Fault 等於降低這條路徑的優先度)— log error 後仍走最保守的固定轉移。fail-safe 優先於錯誤精確性。
出處: PR #68 Eden 對 Leo 的裁示。

---

## BND — 契約進碼與編譯期防線

nova 兩則最重量級的外部 review(Jerry 的 PR #56、#63)都屬此類。

### BND-1: 靜默毀損類契約必須 runtime enforce(壓過 MIN-3)

違反後果是靜默資料毀損的前置條件,必須在程式碼裡擋,不能只寫 doc comment 叫 caller 保證。`page_program` 跨頁 wrap 當年以「別加 impossible check」(MIN-3)豁免 — 誤判:由 runtime 資料長度決定的契約不是 impossible condition。見 minimalism.md MIN-3 的 2026-08 修訂。
出處: PR #63 Jerry「bytes that look plausible and are wrong」;PR #40、#46、#53 同型(「寫進文件叫 caller 保證」在此團隊不被接受)。

### BND-2: 守衛放在第一個副作用之前

guard 要放在 `write_enable()` 之類有副作用的步驟前面 — 否則失敗路徑殘留已武裝的硬體狀態(WEL latched)。
出處: PR #63 Jerry。

### BND-3: 編碼合法性 ≠ 語意合法性

「是合法編碼」與「是合法語意」分開驗,各在該驗的邊界驗(`SpmID` 1..=0xF 可編碼,但只有 1..=12 有 grid 位置)。反向轉換要能失敗;成對轉換配 round-trip test。還沒有 caller 的 API 正是修邊界最便宜的時機。
出處: PR #56 Jerry「Nothing calls `from_raw()` yet, which is exactly why now is the cheap time to fix it」。

### BND-4: const assert 當測試替身

拉了 embassy-stm32 等硬體依賴的 crate 無法 host test — 用 `const _: () = assert!(...)` 把不變量交給編譯器,每次 target build 都驗。註解裡「不可能截斷」「不可能出界」的宣稱,一律換成 const assert 讓編譯器背書。
出處: PR #64 Eden、PR #56 / #63 Jerry 與 Harry 三處成形。

### BND-5: Validate-before-narrow

先在寬型別(`usize`)上驗範圍,再 `as` 窄化;每個窄化旁邊配 const assert 釘住無損前提(`MAX_NUM_CELL <= u16::MAX as usize`),或用 mask + cast(CC14)。
出處: FW-164 M2 + Eden review PR #64。

### BND-6: 衍生值單一來源,const fn 推導

一個事實只寫一份:`ICPSC` 暫存器編碼從 `LSI_PERIODS_PER_CAPTURE` 用 `const fn` 推導,非法值在 const 求值時直接變 build failure(E0080);派生常數寫成 const 算式(`MAX_FD_SINGLE_FRAME_LEN = MAX_FD_DATA_LEN - 2`)讓編譯器維護。負向對照要實測一次(注意 const fn 裡 `todo!("msg")` 是 E0015,用 `panic!` 加字面字串)。
出處: FW-211 ICPSC 節、PR #40 Eden。

### BND-7: 協議常數用 module 分組

裸數字入 const + doc comment 講語意(CC4 的 nova 高頻重申:PR #3、#10、#11、#55、#60、#67,三位 reviewer 都講過)。協議常數用 `mod sf / ff / cf / fc` 分組取代長前綴;打包函式內建不變量檢查(`pack_pci_nibble` 綁 debug_assert)。
出處: PR #40 Eden 長篇建議。

---

## CON — no_std / embassy / 全域狀態

### CON-1: IPC 滿載策略顯式選擇

channel 滿時 `try_send` + drop + log,還是回壓,是設計決策 — 顯式選、寫下理由(stale response 不得回壓 RX 路徑)。
出處: PR #3 Eden。

### CON-2: spawn `.expect()` 的可接受條件

結構上不可能失敗(每個 task 恰 spawn 一次,pool 不會耗盡)且註解論證「為什麼不可能」的 `.expect()` 可接受 — 這是 embassy 0.10 的預期寫法。unwrap 政策(CC13)的豁免要件是那行註解。
出處: PR #3 Eden 認可。

### CON-3: 可變 static 是公認風險點

runtime 設定的全域(topology spec 類):讀取端要確認 critical-section 需求;索引維度從 spec 物件動態取,不得寫死。
出處: PR #48、#53(Eden「it introduces a huge risk」)。

### CON-4: 純函式抽取換 host-testability

硬體 poll 迴圈 / 暫存器解碼的判定邏輯抽成純狀態機(`CaptureState::on_poll`),PAC 讀寫留殼層 — 這不是整潔問題,是 bug 可達性問題:FW-211 clock.rs 兩個 P1 都活在 host test 照不到的 poll 迴圈裡。stub/real 雙態 crate 中要 host-test 的純函式用 `cfg(any(feature = "...", test))` 讓 test build 看得到。FFI 回傳碼 → 領域結果的分類函式同理(`classify_slice`)。
出處: PR #33、#36。

### CON-5: cfg 雙態檔案的 import 紀律

同檔案有 cfg 互斥分支時,只在單一分支用到的名字不放頂層 import(另一態下變 unused,`-D warnings` 紅)— cfg 分支內寫全路徑、tests module 自己 import。每次改動,兩種 cfg 組態都要過關卡。
出處: FW-211(post.rs 與 rt.rs 各中一次)。

### CON-6: RAII disarm guard + happy path 顯式 cleanup

會改變全域行為的 arm 操作(artificial failing 注入這類 sticky mode)必須配 RAII disarm guard,保證每條 return 路徑都解除。但 `Drop` 無法回報錯誤 — 可能失敗的 cleanup 要在正常路徑顯式呼叫並檢查結果,guard 帶 `disarmed` 旗標只當最後防線。注入時非目標欄位填 NOT_TESTED,絕不填 PASSED。
出處: FW-211(一個 `Err` 提早 return,之後所有 verdict 都是捏造的)。

### CON-7: 殘留狀態會製造假陽性

讀共享 status 變數判定結果前,先確立該值是本次操作寫入的(先清為 sentinel 再跑,或驗證狀態轉移)— Configure 後殘留 `STL_PASSED` 曾讓測試沒跑就回 `Ok(Passed)`。測試序列的前置條件要包含清除前輪殘留。
出處: FW-211 `run_mem_test`、FW-164 M4 Run E。

### CON-8: Reject-and-retry 優於 in-band 補償

複雜的補救機制(wrap 仲裁 + 順序判定)若能換成「這輪量測不乾淨就整筆丟棄重來」,選後者 — 前提是兩者失效方向等價(都 fail-closed)。任何「此設計必 fail-closed」的論述本身要當成待驗證的斷言攻擊一次。
出處: FW-211 PR #33 重新設計(對抗式複核第五輪還抓到初稿裡過寬的安全論述)。

### CON-9: build-time 檔案生成 feature 與自訂 linker 佈局互斥

`embassy-stm32` 的 `memory-x` 這類 feature 會往 link search path 塞生成檔,跟手寫 memory.x 對撞。自訂佈局的 crate 要稽核依賴 feature 清單。
出處: FW-199 M5。

---

## FFI — unsafe / vendor lib / 暫存器

STL(ST 認證 library)整合期成形的紀律,適用一切 closed-source vendor 整合。

### FFI-1: 指標交給 C 端之後,Rust 端只走 raw pointer

C 端在 init 時保留指標、後續自行 deref 的資料:Rust 端 init 後立刻降級為 `*mut` 持有,之後不得 re-form `&mut`(aliasing UB)。「不得再造參考」這件事寫進欄位型別(持 `*mut` 而非 `&'static mut`)。
出處: FW-199 Codex major finding。

### FFI-2: rc_w0 狀態暫存器禁 read-modify-write

`sr().modify()` 是整暫存器 RMW,會把 read 與 write 之間硬體剛升的旗標寫回 0。一律用顯式 `write` 構造值,且只清同一次讀取快照中確認見到的旗標。語意不明的位置布林參數以意圖命名(`clear_uif` 而非 `uif`)。
出處: FW-211 Codex round 2。

### FFI-3: FFI mirror 層與 vendor header 逐字一致

鏡像 vendor header 的常數拼字逐字照抄(`NOT_TESTED` 不改 `UNTESTED`)— 稽核者要能把每個常數對回 vendor symbol。鏡像檔的可稽核性優先於本地命名品味。
出處: PR #34,Harry 對 Eden nit 的成立 push back。

### FFI-4: 授權 / target 不變量在原始碼層 cfg-gate

「STL 不連非 ST 目標」這類授權條款,要 source-level 落實(`#[cfg(not(feature = "stl"))]` 鎖 stub 測試;build.rs 斷言 target triple),不能靠 CI 設定剛好沒開。build.rs 檢查「實際會出事的變因」(target triple),不是它的代理(feature flag)。每道 gate 配一次負向對照,證明真的擋得住。
出處: PR #36 Eden「the gate makes the source state the invariant instead of relying on CI config」、FW-223。

### FFI-5: vendor 黑盒行為的假設要一手出處

對 closed-source binary 行為的每個斷言引 vendor example code 行號或 UM 章節,不能用「試過會動」。編譯期表達不了的硬體組態假設(TrustZone 是 option byte,cfg 表達不了)至少落成註解 — 先窮盡強 guard,不行才降級成註解。
出處: PR #36(Harry 補 X-CUBE-CLASSB-H5 main.c:688 引用)。

### FFI-6: 環境常數對「實際跑的 init 路徑」驗證

CMSIS 註解說 reset 後 HSI 64 MHz — 前提是跑過 `SystemInit`,而 cortex-m-rt 不跑,實際 32 MHz。寫進 code 的 boot 時脈 / 預設分頻,要對照手冊 reset 值與本專案 runtime 實際執行的初始化序列雙重查證;框架註解的前提未必在你的 runtime 成立。
出處: FW-211 32 MHz 陷阱(對抗式複核查 RM0481 抓到)。

---

## NAME — 命名與 API 形狀

CC3 的 nova 增補。兩個成立的 push back 案例說明:命名意見可以用具體理由拒絕。

### NAME-1: 判定型 getter 用過去分詞

`is_pass()` → `passed()` — 被動語直接用過去分詞,不用 `is_` + 名詞。此案升格為 frozen contract v1.3 的正式 rename。
出處: PR #34 Eden;issue #54。

### NAME-2: 函式動詞開頭,module path 當語意的一部分

`spm_heartbeat` → `verify_spm_heartbeat`;task 函式直接叫 `task`,呼叫端讀成 `can_io::task(...)`。函式名不重複 module 名(`clock::clock_setup()` → `clock::setup()`)。
出處: PR #3 Eden(引 Clean Code)、`b0eabce`。

### NAME-3: module-qualified 命名要看 caller 的路徑

`post::Config` 這種寫法的前提是主要 caller 走 module path;若 caller 都寫 `self_test::PostConfig`(crate root),名字要在 root 也自明 — `PostConfig` 保留。不是無條件套用的規則。
出處: PR #34,Harry 的成立 push back。

### NAME-4: const 全名不縮寫

`SPM_SOURCE_ADDRESS` 不是 `SPM_SA` — const 不影響 binary size,全名讓後續閱讀明確。
出處: PR #3 Eden。

### NAME-5: 一個識別字兩種角色時,名字抽到共同語意層

SA 同時當 TX 欄位與 RX 過濾:改名 `node_addr`,方向差異寫進 doc(「TX 時放 SA 欄、RX 時對 TA 欄過濾」)。
出處: PR #47 Eden。

### NAME-6: wire 值 ↔ enum 用 `#[repr(u8)]` discriminant

discriminant 一處定義 + `self as u8`,取代手工 nibble 對映;反向能用 infallible `From<u8>` 就不要 fallible 轉換 + default 補救。
出處: PR #40、#59 Eden。

### NAME-7: `From` 只給永遠 1:1 的轉換

`From` 的語意假設是全域、無損、1:1 — 對映關係可能變一對多的(`FaultKind → Fault`),用普通具名函式,別把它鎖死。
出處: `46faf1b`(Eden PR #4 review 定案)。

### NAME-8: 欄位預設 private + `const` getter;API 遷移標 deprecated

struct 欄位收 private、getter 標 `const`(PR #33 `ClockLimits`;注意封裝擋「外部亂建」但擋不住「內部算錯」,use-time 檢查仍有位置)。API 遷移期舊符號標 deprecated 留線索,不直接刪(PR #62、#67)。但 `#[deprecated]` 在 `-D warnings --all-targets` 下會對內部呼叫者連環爆 — 無呼叫者的遺留碼直接刪(見 DOC-5),deprecated 只用於還有 caller 的過渡。
成對 API 型別要對稱:`from_grid` 收 `usize` 而 `to_grid` 回 `u8` 會逼兩端 cast — 陣列索引一律 `usize` 貫穿(PR #56 Jerry)。

### NAME-9: spec 詞彙會鑄進 code — 命名在規劃期就要審

實作 agent 忠實沿用 spec 術語(spec §8 的「settle」「marker」原樣進了 crate API),而 spec 的對抗式 review 只審機制不審詞彙,名字的問題一路活到 PR review 才爆。plan 定稿前對核心概念跑一次命名審查,判準:「這個詞給沒讀過 spec 的人看得懂嗎?」。概念名優先名值合一 — slot 叫 `SLOT_IN_PROGRESS`、值叫 `IN_PROGRESS`、判定叫 `is_in_progress`,一個詞貫穿到文件。
出處: PR #90 `ac0db07`(settle→judge_last_boot、marker→IN_PROGRESS flag,review 期整組翻名)。

### NAME-10: 函式名受詞完整;意圖名過不了誠實性測試就退回機制名

`clear_in_progress` 缺受詞(clear 的是旗標,不是「進行中」這個狀態)→ `clear_in_progress_flag`。更高語意層的意圖名(如 `arm_hang_detection`)要先過誠實性測試:名字聲稱的效果若依賴函式外的條件才成立(hang 偵測 = 旗標 + IWDG armed 兩者;`dev-no-watchdog` build 下 set 了旗標也沒有偵測),名字就會在某些組態下說謊 — 退回誠實的機制名,意圖寫進 doc。重複的 slot+值配對收成具名 helper(`write_checked(SLOT_IN_PROGRESS, CLEARED)` → `clear_in_progress_flag()`),配對只存在 helper 內一處。
出處: PR #90 `aa3831c`、`0c66081`。

### NAME-11: crate alias 避開生態慣用縮寫

`use failsafe_core as fs` 讓讀者先想到 file system。alias 不與慣用縮寫(fs / io / os / rt …)相撞,寧可長一點(`as failsafe`)。
出處: PR #90 `aa3831c`。

---

## DOC — 註解與文件

FW-212 stack(PR #30~#37)的貫穿主題。在認證導向的 crate,「comments are the argument handed to certification」— 註解本身是交給稽核者的論證。

### DOC-1: doc comment 在 PR 範圍內自足

不得懸空引用 diff 裡看不到的「spec §1.5 A3」「M4/M5」— 要嘛把實質內容 inline,要嘛只留 repo 內可直接開啟的路徑(`stl_user_api.h` 可以,「knowledge base §7.6」不行)。
出處: PR #30 起系統性掃過 #31、#32、#33、#35、#36。

### DOC-2: 註解裡的技術宣稱要可覆核

PR #32 self-review 抓到三處錯註解,最毒的一種:錯的「理由」會讓後人理直氣壯地刪掉必要程式碼(信了「cc 會發 rerun-if-changed」就會把手寫的追蹤迴圈當冗餘刪掉,換來靜默連舊 STL)。環境 / 工具能力的宣稱被實測推翻就立刻改(`f0a73b1`)。量化斷言分級:有自動關卡釘住的數字可寫死;沒有的必附量測條件、工具版本或日期。
出處: PR #32、`f0a73b1`、pr32 註解修正。

### DOC-3: 註解與緊鄰程式碼矛盾必改寫

「Comment says "not an Err" directly above `Err(...)`」— 這種措辭在邀請別人「好心修壞」。註解要防好心人。
出處: PR #36 Eden。

### DOC-4: 刻意收窄的解析要留 provenance

只接受子集的解析邏輯(`AckCode` 只認 0x00/0x01),註解必須保留來源與日期(「SPM firmware 只實作這兩值 — Leo, 2026-04」)— 那是防止後人好心放寬的護欄。同理:參數恰巧同值的呼叫點(`f(pgn, sa, sa)`)要註明何時不再同值。
出處: `d1e2e26`、`b0eabce`。

### DOC-5: 遺留碼直接刪,不加註解供著

與權威 spec 牴觸、又無呼叫者的繼承碼一律刪(she_j1939 single-shot 路徑 570 行),歷史查 git — 「標 LEGACY 豁免」把誤用風險轉嫁給每一位讀者。遷移完成後的血緣敘事註解也清掉。刪 dead code 時,它承載的領域知識轉成留存碼的 doc(TDC 顧慮寫進留存函式)。
出處: PR #3 三部曲(`1e9c214` → `ccf0669` → `3615a2c`)、`b0eabce`。

### DOC-6: 註解上收 item-level,不切割程式主體

散落的行間註解整併成 enum / fn 的 doc comment(Eden:「讓 code 不會被過多 comment 給切割閱讀」)。量化實踐:PR #33 註解 318 行減到 243 行,長推導移去 Wiki,程式內只留沒有 gate 能抓的陷阱全文。每個 module 要有 `//!`;複製樣板時同步改敘述(PR #56 的 "UDS-lite" 殘留)。
呼叫處註解不重複定義處 doc:函式做什麼的列舉歸定義處;呼叫處只留 call-site 特有的 why(為何在這個位置、為何帶這個 attribute)。簽名看不出的契約(如「可能不返回」)是定義處 doc 的責任,不是呼叫處的。
出處: PR #3、#33、#56;PR #90 `ff76863`(pre_executor 呼叫處 6 行去重成 3 行,park 契約移回定義處)。

### DOC-7: 駁回 review finding 也要留書面理由

拒絕採納的意見,rationale 落在下一個 reviewer 看得到的地方(檔頭註解 / PR body)— 否則同一條會被反覆提出或被誤修(FW-215 TOCTOU 駁回理由寫進 `.sh` 檔頭)。
出處: `1d0a674`。

### DOC-8: 縮寫與暫存器旗標在每個 crate 首現處展開一次

`IWDGRSTF` 裸用,沒 RM 在手的讀者無錨。每個獨立閱讀單位(crate)在縮寫首現處展開一次(全名、住哪個暫存器、誰設誰清),後續沿用短名。
出處: PR #90 `f8c9d68`(bringup 與 failsafe-core 各定義一次)。

### DOC-9: 註解不引內部規劃座標(spec §N / tracker-ID)

「(spec §8)」「(FW-247)」對讀 code 沒有幫助 — 實質內容不在 diff 裡,座標也打不開。DOC-1 的強化:內部規劃文件的節號與 ClickUp tracker-ID 一律不進註解;歷史歸 commit message 與 PR。外部權威引用(RM0481 §、UM3267 §、errata 編號)後面接著它規定了什麼、是可覆核的事實出處 — 保留。
出處: PR #90 `6b2258c`、`838484a`(Harry 拍板)。

### DOC-10: 新讀者測試 — 收尾用「沒有 spec 的人」的眼睛掃 diff

agent 寫 code 時 context 裡有 spec、tracker、RM,座標與縮寫自然流進註解,而 agent 模擬不出人類新讀者的無知。收尾自檢與 review 各跑一條 lens:「假裝你是沒有 spec、沒有 ClickUp 權限、手上沒有 RM 的新同事讀這個 diff — 每個名字、縮寫、引用都要能自立」。實證:PR #90 七輪可讀性重構全程 gates 綠 — 這一層 lint 全抓不到,只有這條 lens 能前移。
出處: PR #90 `117a36c`〜`0c66081` 七輪重構總結。

---

## TEST — 測試與驗證

### TEST-1: 期望值來自外部權威,不從實作重算

測試斷言 `31_248 - 31_248/4` 是在復述實作;改斷言外部已知值 `23_436`(ST 的數字)。協議常數附 SOT 引用;來源矛盾時在 code 註記「未決」,不得把任一方當事實,定案後同 commit 更新 code 與文件(`039a2cf`)。
出處: PR #33、TI-002。

### TEST-2: 自寫演算法雙錨

自寫 CRC / codec 用公開 check value(`crc32("123456789") = 0xCBF43926`)+ 獨立語言實作的 golden vectors 雙錨。凡能離線重算的板上判定,關卡裡放離線預驗,別上板猜。
出處: FW-164 M2、FW-198 golden table、FW-215 zlib 預驗。

### TEST-3: 機率性缺陷要統計驗收

1/16 機率的 regression,單次上板 94% 誤判為綠 —「Do not accept a single run」。驗收次數要對得上缺陷頻率(46 次 power cycle 對 95% 信心),算術寫進 runbook。
出處: PR #33。

### TEST-4: doc 描述的行為要有測試釘住

reviewer 附完整測試碼建議「add a test to guard what doc describes」是通行做法。刪 guard 前先論證不可達,並比對相似形狀的 guard 是否同理(有的可達、不同類)。
出處: PR #30 Leo。

### TEST-5: 變更操作驗「狀態後果」,不信「命令回報」

erase 後逐 byte blank-check(寫保護下 SE 無聲失效,WIP 照樣清);program 後回讀。狀態暫存器只證明忙完了,不證明做對了。掉電安全寫入用 magic-last 兩段式 commit marker — 不得假設「部分寫入必然毀損校驗」(NOR 1→0 可停在全自洽但錯誤的 record,反例逐 byte 驗過)。
出處: FW-164 M1/M2/M3。

### TEST-6: 表格測試用 rstest;PR 附關卡證據

團隊表格測試工具是 rstest(`[dev-dependencies]`)。PR 描述附 lint / test / 整合測試證據(截圖或文字紀錄),「gates green」不是口頭宣稱。
出處: PR #19、#41、#43、#46、#56、#67。

---

## GATE — 建置關卡與工具腳本

韌體交付物包含 bench 工具(Python / shell / justfile),它們與 Rust 同標準受 review。FW-215 五輪 review 全在這層。

### GATE-1: 每個 crate 掛進某道關卡;recipe 名單只增不換

加 crate 的 checklist 必含「掛進對應 justfile recipe」— nova 一度有三個 workspace member 漂在關卡外(`model` 22 個 test case 從未跑過)。改 recipe 的 `-p` 名單一律 additive;一次 PR 把 `-p self-test` 換成 `-p model`,self-test host test 自此靜默停跑。任何移除要在 PR 明文宣告。
出處: FW-211 07-31 紀錄、PR #46。

### GATE-2: build.rs 的 `rerun-if-changed` 要窮舉全部外部輸入

一旦發出任何 `rerun-if-changed`,cargo 只盯列出的路徑 — vendored lib、header、C source 全部要掛,漏一路 = 靜默連舊 artifact 還全綠。`cc` crate 不會替你發(這正是 PR #32 抓到的錯註解)。
出處: FW-223。

### GATE-3: FFI 正確性只有真連結能證明

lib crate 的 check / clippy 不呼叫 linker — 拼錯的符號、走樣的 ABI 全部無感。CI 必須有真連結 bin 的關卡(`llvm-nm` 量 0 未解符號);每道關卡的涵蓋範圍要如實記載,type-check 關卡不得宣稱涵蓋連結。
出處: FW-211(`check-h5-stl` 只 clippy 的教訓)。

### GATE-4: cwd-scoped 建置設定是建置契約的一部分

crate 層 `.cargo/config.toml` 的 `[env]`(`DEFMT_LOG`)/ runner 只在該目錄下生效 — 從 repo 根 `cargo build -p` 會靜默丟掉它(defmt 編譯期裁光 `info!`,燒錄成功但 RTT 靜默)。recipe 要 `cd` 進 crate 目錄,並配離線驗證(`strings <elf> | grep -c defmt_info`)。
出處: `7e96197`。

### GATE-5: 工具 exit code 是契約,先分割命名空間

0 = 通過、1 = 實質發現、2 = 用法 / 工具錯誤 — 然後用 catch-all handler 把每條殘餘例外路徑收斂到工具錯誤碼;外部工具失敗不得落在「實質發現」碼上(工具壞掉被讀成「比對失敗」)。收斂 exit code 不等於吞診斷:handler 先印 traceback 到 stderr 再 die。空集合比對是 fail-open,必須報錯而非默默通過。
出處: FW-215 `8e39995`、`27b3a9c`、`304cecc`。

### GATE-6: 驗證對「實際交付的 artifact」,位址與內容都驗

pipeline 每個轉換步驟(objcopy / 注入 / 正規化)之後,關卡對轉換後真正上板的那份驗,或證明兩份逐 byte 等值。placement(位址、大小)與 payload 同為契約 — 表內容對但落錯位址,板上照樣讀到空白 flash。第三方工具改寫過的 artifact 交給下一工具前先正規化(`-sl` 會寫壞 ELF phdr);關鍵外部工具用絕對路徑呼叫並檢查存在性,「找不到工具」不得退化成靜默跳過。
出處: FW-215 `5690902`、`1d0a674`;FW-198 兩坑。

### GATE-7: 解析工具輸出的三律

(1) regex 錨定行首結構性前綴,字面值一律 `re.escape`,收集全部命中並斷言恰一筆 — substring 命中與 first-match 都是繞過面(decoy section 攻擊確定性繞過裸 `re.search`)。(2) 先用旗標縮小輸出(`nm --extern-only --defined-only`),多筆命中顯式報錯 — 拒絕猜測優於隱性 last-wins。(3) linker 符號不等於 image 內容尾端(`__eflash` 後面還有 orphan sections)— 邊界對齊到雙方語意一致的整段單位。
出處: FW-215 `1d0a674`、`49f9bed`;FW-198。

### GATE-8: 鏡射別處不變量時,守衛整組搬

從參考實作(`region.rs`)移植前置條件,逐條對照原始碼搬齊並註明鏡射來源 — round 1 只搬了兩道 guard 之一,負的 `section_count` 繞過空集合檢查,缺一道就是新的 fail-open 邊。
出處: FW-215 `5690902`。

### GATE-9: shell 關卡的 exit code 紀律

`cmd | tail -40` 的 `$?` 是 tail 的;`cmd && echo OK` 在 `set -e` 下 cmd 失敗不中止。輸出落地用 `> log 2>&1` 再獨立讀 `$?`;多道關卡逐一驗 exit code。script 的環境前置檢查集中開頭、便宜的先跑,錯誤訊息告訴使用者怎麼修。
出處: FW-211 07-28 踩坑、FW-215 各輪。

### GATE-10: 本機與 CI 工具版本歪掉是已知類故障

cspell 本機紅 CI 綠 → 先查 `cspell --version` 字典版本差。doc comment 換行交給 rustfmt,手工折行必掛 fmt-check。
出處: PR #25(Harry 自關 PR 留的教訓)、PR #35。

---

## REV — review 工作流慣例

### REV-1: 大改動拆 stacked PR

4600 行 bundle 主動拆成 8 個 ≤500 行的 stacked PR,附 split plan,tip byte-identical 驗證。review 修改後逐一以 commit hash 回覆每則意見 — Eden、Leo、Harry 三人都如此。
出處: PR #28 → #30~#37。

### REV-2: push back 要具體理由,且會成立

命名 / 設計意見可以拒絕,但要給可檢驗的理由(`PostConfig` 的 crate-root caller、`NOT_TESTED` 的 vendor 對映)。空泛的「我覺得原樣好」不算。
出處: PR #34 兩例。

### REV-3: 攻擊類 finding 的收斂標準是重現 → 修 → 重演驗殺

安全 / 關卡類缺陷,先在本機重現攻擊,修完重放同一攻擊確認被擋 — 只有推理沒有重演的修正不算收斂。
出處: FW-215 `1d0a674`、`49f9bed`(兩輪 commit message 都記錄 attack reproduced / replayed → caught)。

### REV-4: 對抗式第二視角有實質產出

表位址驗證、decoy regex 繞過、rc_w0 RMW、cleanup 只跑成功路徑 — 全是第一 reviewer 白紙黑字說「安全」或連續多輪沒看到的地方。修 bug 本身會引入新 bug(clock.rs 四輪連環),安全關鍵碼每次修正都重新過模擬 / 掃描,不能只驗原缺陷。
出處: FW-215、FW-211 clock.rs。

### REV-5: 負面斷言要查內容,不查標題

「grep 某標題沒中」不得當「內容不存在」的證據 — 生成碼要 multi-line aware(`grep -A4`),照片轉錄的腳位要兩路獨立來源交叉。單一查法查無,不構成不存在。
出處: FW-164 教訓(SPI5 誤判、腳位偏一根)、FW-211 M5-provenance 錯字。
