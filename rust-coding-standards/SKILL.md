---
name: rust-coding-standards
description: Use when reviewing or writing Rust code in any project, or when a review finding needs canonical rule wording with rule IDs. Generic sets CC (clean code) / MIN (minimalism) / MOD (modularity) apply to all Rust code; nova-era sets ERR / BND / CON / FFI / NAME / DOC / TEST / GATE / REV (snafu error conventions, fail-closed design, const-assert discipline, no_std / embassy patterns, STL / FFI rules, gate-script hardening) bind BTBU firmware repos — nova (adlink-protocol / coordinator-core / tasks / self-test / bsp-* / firmware bins, incl. justfile and bench gate scripts) and siblings — and serve as reference elsewhere.
---

# Rust Coding Standards

本 skill 收個人 Rust 撰碼準則全文,適用所有 Rust 專案:CC / MIN / MOD 三組通用;`nova-conventions.md` 是 BTBU 韌體 (nova 與 sibling repos) 的紅線,其他專案當參考。也是各專案 `CLAUDE.md` 紅線引用的 cold path 正本、dual-review 時 Agent B / Codex 引規則的 canonical 依據。

## 定位 (2026-08-09 更新)

- **個人 agent enforcement 層,不是團隊 SOT**。團隊正本候選是 ClickUp Firmware Wiki 的〈she-bms Firmware — Coding Standards (co-design draft)〉(Design 節下),該頁 §8 / §9 列出尚未拍板的開放問題。
- **Review 隊友的程式碼時**:未拍板的規則(CC2 的 40 行 vs Backend 的 50±25、trait 命名後綴等衝突項)以「建議 + 出處」提出,不當紅線。
- nova 的 co-design 邊界(`CanDriver` trait、`coordinator-core` 拆分、heap 政策等)以 nova `CLAUDE.md` 為準,本 skill 規則不得推翻。

## When this skill fires

- 在任何專案寫或 review Rust code(nova 含 justfile recipe 與 bench 工具腳本)
- Reviewer 要 cite 具體規則編號:CC1~14 / MIN-1~6 / MOD-1~5,或 nova-conventions 的 ERR / BND / CON / FFI / NAME / DOC / TEST / GATE / REV
- Code review finding 需要 canonical 措辭與出處
- 新專案要匯入 coding-standards 參考

## Reference structure

- `references/clean-code.md` — CC1~CC14(命名、函式形狀、error handling、註解、dead code、cast)
- `references/minimalism.md` — MIN-1~MIN-6(範圍控制、反過度設計;**MIN-3 有 2026-08 界線修訂**)
- `references/modularity.md` — MOD-1~MOD-5(layer 圖含 nova 對映、依賴方向、抽取門檻)
- `references/nova-conventions.md` — **nova 時代慣例與教訓 (2026-08-09)**:snafu error 慣例 (ERR-1~9)、契約進碼與編譯期防線 (BND-1~7)、no_std / embassy / 全域狀態 (CON-1~9)、FFI / vendor / 暫存器 (FFI-1~7)、命名增補 (NAME-1~11)、註解紀律 (DOC-1~11)、測試與驗證 (TEST-1~7)、建置關卡與工具腳本 (GATE-1~11)、review 工作流 (REV-1~5),共 77 條。蒸餾自 nova PR #1~#73 全部 review 意見與 FW-211/212/215、FW-164 工作項紀錄,每條附可覆核出處;活文件,重大 review 的 taste 層教訓持續追加 (2026-08-20 起,PR #90 補 NAME-9~11、DOC-8~10;2026-08-27 FW-247 ECC 補 FFI-7、GATE-11;2026-08-28 上板補 TEST-7;2026-09-03 PR #113 補 DOC-11)
- `references/team-embedded-guideline.md` — **團隊層 guideline snapshot (Eden 提供,2026-08-20 收檔)**:Firmware Wiki「專案結構與模組佈局規範 Part 0–IX + Coding Standards」的可貼用濃縮——六資料夾架構、模組佈局(mod.rs/error.rs/impls.rs)、newtype 物理量、blackboard 規則、共享狀態 primitive 對照表、分派與尺寸、PR checklist(§B8)、未拍板清單(§C)。正本在 Wiki;**檔頭列了與 nova 現況的三個已知衝突(workspace.lints / trait 邊界 vs co-design 紅線 / 目標態架構),引用前必讀**
- `references/2026-04-08-coding-standards-dual-review-design.md` — dual-review 工作流設計史(SUPERSEDED;CC/MIN/MOD 編號體系的出生證明)
- `references/2026-04-18-idiomatic-rust-plan.md` — idiomatic Rust 計畫(HISTORICAL;FW-8 停在 Phase 1,留作點子庫)

## How to apply

1. 選對層:函式形狀 / 範圍 / 分層 → CC / MIN / MOD;error、契約、no_std、FFI、測試、關卡 → `nova-conventions.md` 對應段;架構落點、模組佈局、共享狀態 primitive、協定模組切分 → `team-embedded-guideline.md`(團隊層,衝突註記先讀)。非 BTBU 專案引 nova-conventions 時以「建議 + 出處」提出,不當紅線——條文蒸餾自 nova,snafu / embassy 這類選型慣例未必適用他處
2. 引規則給編號 + canonical 措辭(例:「BND-1: 靜默毀損類契約必須 runtime enforce」),出處在條目內(PR 編號 / commit sha)
3. 三層 SOT 都查無依據的判斷,標「reviewer judgment」,不冒充有據(SOT 階層見 `~/.claude/rules/rust-review-sot.md`,碰 Rust 檔自動載入)
4. 回頭確認專案 `CLAUDE.md` 紅線摘要與本 skill 對齊

## Provenance

2026-05-20 自 `can_integration_testing/docs/coding-standards/` 遷入(decomposition design Path 1)。2026-08-09 大改版:新增 `nova-conventions.md`(nova PR #1~#73 蒸餾);MIN-3 界線修訂、MIN-4 / CC13 / CC14 增補、MOD-1 nova 對映;`2026-04-08-coding-standards-dual-review-plan.md` 移出至 repo `docs/archive/`(一次性計畫早已執行完,且內嵌的規則草稿複本日後恐與 canonical 檔分岔);idiomatic plan 由 living-template 降級 historical。
