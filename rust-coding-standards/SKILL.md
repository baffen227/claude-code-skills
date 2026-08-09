---
name: rust-coding-standards
description: Use when reviewing or writing Rust code in BTBU firmware projects — nova (adlink-protocol / coordinator-core / tasks / self-test / bsp-* / firmware bins, incl. justfile and bench gate scripts) or sibling BTBU embedded Rust repos — or when a review finding needs canonical rule wording (CC / MIN / MOD, or nova-era ERR / BND / CON / FFI / NAME / DOC / TEST / GATE / REV covering snafu error conventions, fail-closed design, const-assert discipline, no_std / embassy patterns, STL / FFI rules, gate-script hardening).
---

# Rust Coding Standards — BTBU Firmware

本 skill 收 BTBU 韌體 Rust 撰碼準則全文,是各專案 `CLAUDE.md` 紅線引用的 cold path 正本,也是 dual-review 時 Agent B / Codex 引規則的 canonical 依據。

## 定位 (2026-08-09 更新)

- **個人 agent enforcement 層,不是團隊 SOT**。團隊正本候選是 ClickUp Firmware Wiki 的〈she-bms Firmware — Coding Standards (co-design draft)〉(Design 節下),該頁 §8 / §9 列出尚未拍板的開放問題。
- **Review 隊友的程式碼時**:未拍板的規則(CC2 的 40 行 vs Backend 的 50±25、trait 命名後綴等衝突項)以「建議 + 出處」提出,不當紅線。
- nova 的 co-design 邊界(`CanDriver` trait、`coordinator-core` 拆分、heap 政策等)以 nova `CLAUDE.md` 為準,本 skill 規則不得推翻。

## When this skill fires

- 在 nova 寫或 review Rust code(含 justfile recipe 與 bench 工具腳本)
- Reviewer 要 cite 具體規則編號:CC1~14 / MIN-1~6 / MOD-1~5,或 nova-conventions 的 ERR / BND / CON / FFI / NAME / DOC / TEST / GATE / REV
- Code review finding 需要 canonical 措辭與出處
- 新專案要匯入 coding-standards 參考

## Reference structure

- `references/clean-code.md` — CC1~CC14(命名、函式形狀、error handling、註解、dead code、cast)
- `references/minimalism.md` — MIN-1~MIN-6(範圍控制、反過度設計;**MIN-3 有 2026-08 界線修訂**)
- `references/modularity.md` — MOD-1~MOD-5(layer 圖含 nova 對映、依賴方向、抽取門檻)
- `references/nova-conventions.md` — **nova 時代慣例與教訓 (2026-08-09)**:snafu error 慣例 (ERR-1~9)、契約進碼與編譯期防線 (BND-1~7)、no_std / embassy / 全域狀態 (CON-1~9)、FFI / vendor / 暫存器 (FFI-1~6)、命名增補 (NAME-1~8)、註解紀律 (DOC-1~7)、測試與驗證 (TEST-1~6)、建置關卡與工具腳本 (GATE-1~10)、review 工作流 (REV-1~5),共 67 條。蒸餾自 nova PR #1~#73 全部 review 意見與 FW-211/212/215、FW-164 工作項紀錄,每條附可覆核出處
- `references/2026-04-08-coding-standards-dual-review-design.md` — dual-review 工作流設計史(SUPERSEDED;CC/MIN/MOD 編號體系的出生證明)
- `references/2026-04-18-idiomatic-rust-plan.md` — idiomatic Rust 計畫(HISTORICAL;FW-8 停在 Phase 1,留作點子庫)

## How to apply

1. 選對層:函式形狀 / 範圍 / 分層 → CC / MIN / MOD;error、契約、no_std、FFI、測試、關卡 → `nova-conventions.md` 對應段
2. 引規則給編號 + canonical 措辭(例:「BND-1: 靜默毀損類契約必須 runtime enforce」),出處在條目內(PR 編號 / commit sha)
3. 三層 SOT 都查無依據的判斷,標「reviewer judgment」,不冒充有據(全域 CLAUDE.md 的 Rust Code Review SOT 階層)
4. 回頭確認專案 `CLAUDE.md` 紅線摘要與本 skill 對齊

## Provenance

2026-05-20 自 `can_integration_testing/docs/coding-standards/` 遷入(decomposition design Path 1)。2026-08-09 大改版:新增 `nova-conventions.md`(nova PR #1~#73 蒸餾);MIN-3 界線修訂、MIN-4 / CC13 / CC14 增補、MOD-1 nova 對映;`2026-04-08-coding-standards-dual-review-plan.md` 移出至 repo `docs/archive/`(一次性計畫早已執行完,且內嵌的規則草稿複本日後恐與 canonical 檔分岔);idiomatic plan 由 living-template 降級 historical。
