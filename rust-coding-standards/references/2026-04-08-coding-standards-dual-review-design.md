# Design: Coding Standards + Dual-Review Skill

> **SUPERSEDED (2026-04-18)**: 本文件中提及的 custom `codex-reviewer` skill 已整個移除 (symlink + repo)。以後所有 Codex review 都走 OpenAI 官方 codex plugin (`/codex:review` / `/codex:adversarial-review` / `/codex:rescue`)。見 `CLAUDE.md` §Cross-AI Review Workflow。本文件保留作歷史快照。

**Date**: 2026-04-08
**Status**: Draft — pending user review
**Scope**: Three coding standards docs + CLAUDE.md Red Lines + SOP update + dual-review skill

---

## 1. Problem Statement

Claude Code 必須嚴格守住三條原則: 最小化、模組化、Clean Code；每次程式碼實作後要經過雙重 review (Agent B + Codex)。目前 SOP 有 CC1-CC10 與 CA1-CA3，但範圍不夠，也沒有 Agent B review 機制。

## 2. Design Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | 在現有 CC/CA 上演進，不重新編號 | Codebase 的 doc comment、plan、SOP 已大量引用 CC9、CA2 等編號，改動成本為零 |
| D2 | 重疊規則只歸在一處 + cross-reference | 避免改一處忘另一處導致 divergence |
| D3 | 所有變更預設跑 dual-review，觸發前先問使用者 | S 級小改動可 skip，但預設是做 review |
| D4 | Docs 放 repo，skill 放 `claude-code-skills/` | Docs 要版本控制 + PR review；skill 要跨 repo 使用 |
| D5 | Review 預設不限次數直到共識 | 使用者重視 thoroughness；可指定上限或隨時喊停 |

## 3. Architecture

```
docs/coding-standards/
├── minimalism.md           ← MIN-1~MIN-6 (全新)
├── modularity.md           ← MOD-1~MOD-5 (CA1-CA3 升級 + 新規則)
├── clean-code.md           ← CC1~CC10 (保留) + CC11~CC13 (新增)
└── RESEARCH_FINDINGS.md    ← 研究資料 (設計完成後歸檔)

~/Projects/claude-code-skills/dual-review/
└── SKILL.md                ← Agent B + Codex 雙重審查流程
    symlink: ~/.claude/skills/dual-review

CLAUDE.md                   ← 新增 "Coding Standards (Red Lines)" section
DEVELOPMENT_SOP.md          ← Section 7 改為 quick reference + 指向三份 docs
```

**文件間關係:**

```
CLAUDE.md Red Lines (6 條, 每次 session 載入)
  ├─ references → minimalism.md (按需讀取)
  ├─ references → modularity.md (按需讀取)
  └─ references → clean-code.md (按需讀取)

dual-review skill (觸發時載入)
  ├─ Agent B prompt → 讀取三份 docs
  ├─ Codex stage → 引用現有 codex-reviewer skill
  └─ consensus loop → 不限次數, P1 必須 resolved

SOP Section 7 (quick reference)
  └─ 指向三份 docs, CA→MOD mapping table
```

## 4. Coding Standards — 規則分配

### 4.1 minimalism.md (MIN-1~MIN-6, 全新)

| # | Rule | Trigger | 核心 |
|---|------|---------|------|
| MIN-1 | No speculative abstractions | 新增 generic, trait, wrapper type 時 | 只寫現在需要的，不為假設的未來設計 |
| MIN-2 | Scope control | 任何 file modification | 只改被要求的範圍，improvement 報告在 text 中不實作 |
| MIN-3 | No "just in case" error paths | 新增 error variant 或 match arm 時 | 只處理硬體/協議實際可能產生的 error |
| MIN-4 | No wrapper types without justification | 新增 newtype struct 時 | newtype 必須提供 invariant enforcement 或 API 限制 |
| MIN-5 | Constant introduction threshold | 新增 const/static 時 | 2+ 次出現或語義不明才提取常數 |
| MIN-6 | Import hygiene | 任何 file modification | 只加需要的 import，移除變更導致的 unused import |

每條規則格式: Rule statement → Trigger → DO / DON'T examples (BEFORE/AFTER) → Rationale

### 4.2 modularity.md (MOD-1~MOD-5, CA 升級 + 新規則)

| # | Rule | 來源 | 核心 |
|---|------|------|------|
| MOD-1 | Dependency direction | CA1 | Inner layers 不 import outer layers (Entity → Use Case → Adapter) |
| MOD-2 | Boundary interface | CA2 | Shared code 透過參數接受 binary-specific 值 |
| MOD-3 | Layer 歸屬 | CA3 | 每個函式/struct 可明確歸屬到一個 layer |
| MOD-4 | Extraction threshold | SOP 1.3 | Rule of Three；2 binary + >100 行也可提取 |
| MOD-5 | No circular dependencies | Research | A imports B → B 不得 import A (transitively) |

Cross-references:
- CC5 (SRP) → "見 clean-code.md CC5"
- CC9 (Max depth 2) → "見 clean-code.md CC9"

CA mapping table: CA1→MOD-1, CA2→MOD-2, CA3→MOD-3

### 4.3 clean-code.md (CC1~CC10 保留 + CC11~CC13 新增)

| # | Rule | 狀態 | 備註 |
|---|------|------|------|
| CC1 | One abstraction level | 保留 | |
| CC2 | ≤40 lines per function | 保留 | |
| CC3 | Meaningful names | 保留 | |
| CC4 | No magic numbers | 保留 | |
| CC5 | Single Responsibility | 保留 | Canonical home; MOD cross-ref 到此 |
| CC6 | No duplication | 保留 | |
| CC7 | Error handling explicit | 保留 | |
| CC8 | Comments only where non-obvious | 保留 | |
| CC9 | Max depth 2 | 保留 | Canonical home; MOD cross-ref 到此 |
| CC10 | Doc comments + CC/CA 標註 | 保留 | |
| **CC11** | **Dead code policy** | **新增** | `#[allow(dead_code)]` 僅限 spn.rs protocol completeness types |
| **CC12** | **Const correctness** | **新增** | 能 const 就 const, 能 const fn 就 const fn |
| **CC13** | **No unwrap in production paths** | **新增** | Library code 用 Result; binary 入口可 unwrap + comment why safe |

新增 sections:
- Naming conventions (Rust-specific): functions=verbs, types=nouns, booleans=predicates
- Compiler-enforced subset: `#![warn(missing_docs)]` (CC10), `#![deny(unused_imports)]` (MIN-6), `#![deny(dead_code)]` (CC11)

### 4.4 每條規則的文件格式 (統一)

```markdown
### MIN-2: Scope Control

**Rule**: 只改被要求的範圍。不 drive-by refactor。

**Trigger**: 任何 file modification。

**DO**:
- 只修改 requested function/block
- 改善機會記錄在 response text "## Improvement Opportunities (out of scope)"

**DON'T**:
- Rename variables in untouched functions
- Reorganize imports unless the change requires it
- Add doc comments to functions you did not modify
- Extract helpers from code outside the change scope

**Rationale**: AI coding assistants 最常見的抱怨是 "helpfully" refactors adjacent code。
Scope control 是 community 報告中 single highest-impact rule。
```

## 5. CLAUDE.md Changes

### 5.1 Red Lines Section

插入位置: Workflow Preferences 和 Project Context Sync Checklist 之間。

```markdown
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

### 5.2 Reference Files Table 新增

```markdown
| Minimalism rules | `docs/coding-standards/minimalism.md` | MIN-1~MIN-6, scope control, anti-patterns |
| Modularity rules | `docs/coding-standards/modularity.md` | MOD-1~MOD-5, layer diagram, extraction criteria |
| Clean Code rules | `docs/coding-standards/clean-code.md` | CC1~CC13 canonical, naming, error handling, dead code |
```

### 5.3 Cross-AI Review Workflow 新增一行

```markdown
**程式碼實作**: 額外使用 `/dual-review` 流程 (Agent B + Codex 雙重審查)。見下方 Coding Standards。
```

## 6. SOP Section 7 Changes

現有 CC/CA rules tables (~80 lines) 改為 quick reference + pointer:

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

SOP 其他 section 中的 CC/CA 引用保持不變 (CC 編號未改，CA 有上方 mapping)。
```

## 7. Dual-Review Skill

### 7.1 Metadata

```yaml
name: dual-review
description: Use when code implementation is complete and needs quality review. Triggers on "/dual-review" or after code changes. Asks user confirmation before starting. Runs Agent B (Claude subagent) review against coding standards, then Codex adversarial review.
```

### 7.2 Flow

```
Implementation complete
  ↓
Ask user: "要執行 dual-review 嗎？(Y/n, rounds=unlimited)"
  ↓ yes                              ↓ no
Collect git diff + file list          Skip
  ↓
[Stage 1] Agent B Review
  Spawn Claude subagent (code-reviewer type)
  Prompt: read three coding standards docs, review diff
  Focus: Red Lines + all MIN/MOD/CC rules
  Output: | # | File:Line | Rule | P | Issue | Fix |
  ↓
Agent A evaluates each finding:
  同意 → fix
  不同意 → 附理由
  部分同意 → 說明調整
  ↓
Output consensus table
  ↓
Has fixes? → apply → re-spawn Agent B
No new issues? → Stage 2
(預設不限次數; 使用者可指定 rounds=N 或隨時喊停)
(每輪顯示 round number + remaining issues count)
  ↓
[Stage 2] Codex Adversarial Review
  使用 /codex-reviewer skill (Section 5-8 審查 + Section 9 共識)
  Adversarial focus: "找 Agent A + B 共識中的盲點"
  同樣不限次數 consensus loop
  ↓
[Stage 3] Final Summary
  Agent B: N rounds, M findings (X fixed, Y rejected)
  Codex: N rounds, M findings (X fixed, Y rejected)
  所有 P1 resolved 確認
  未解決 P2+ 列出供使用者 awareness
```

### 7.3 Agent B Prompt Template

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

### 7.4 Termination Conditions

- **預設**: 不限次數，持續 review 直到 0 new issues
- **使用者可指定**: `/dual-review rounds=3`
- **每輪結束時**: 顯示 round number + remaining issues count，使用者可隨時喊停
- **Hard requirement**: 所有 P1 必須 resolved (不論使用者是否喊停)
- **Stage transition**: Agent B 0 new issues → 進入 Codex stage

## 8. Verification Checklist

### Self-Check (實作完成後)

- [ ] 三份 docs 的規則編號無重複、無遺漏
- [ ] Cross-references 雙向一致 (MOD 引 CC5/CC9, CC5/CC9 不引 MOD)
- [ ] CLAUDE.md Red Lines 的 6 條都能在三份 docs 中找到對應規則
- [ ] SOP Section 7 的 CA→MOD mapping 正確
- [ ] dual-review skill 的 Agent B prompt 引用正確的 doc paths
- [ ] codex-reviewer skill 的引用方式正確 (不重寫其流程)

### Integration Test

- [ ] 在 can_integration_testing repo 中 `git grep "CC9"` 確認既有引用仍有效
- [ ] 在 nrg-prototype repo 中 `git grep "CA1\|CA2\|CA3"` 確認 mapping 覆蓋
- [ ] `/dual-review` 可在 Claude Code 中觸發
