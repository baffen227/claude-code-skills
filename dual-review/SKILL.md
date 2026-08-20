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
- ~/.claude/skills/rust-coding-standards/references/clean-code.md
- ~/.claude/skills/rust-coding-standards/references/minimalism.md
- ~/.claude/skills/rust-coding-standards/references/modularity.md
- ~/.claude/skills/rust-coding-standards/references/nova-conventions.md

Review the following changes against ALL rules in those documents.

Additionally run a FRESH-READER pass (nova-conventions DOC-10): assume you
have NOT read any design spec, have no issue-tracker access, and no chip
reference manual at hand. Every name, acronym, and citation in the diff must
stand on its own — flag anything a new teammate could not decode from the
diff plus the repo alone (undefined acronyms, spec-jargon leaked into API
names, comments citing internal planning coordinates, mechanism-level calls
that hide their intent).

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

Replace `{git_diff}` with diff output, `{file_list}` with changed file list.
(Coding standards moved to the rust-coding-standards skill 2026-05-20; the
old `{project_root}/docs/coding-standards/` path is gone.)

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
2. **每個 fix 套用後，立即 spawn 一個 fresh agent 只審該 fix 的 diff**，不等整輪 re-review——round-1 fix 曾帶進比原 bug 更糟的 P1 regression (2026-07〜08 insights 報告實例)
3. Re-spawn Agent B on updated diff (整輪)
4. 重複直到 Agent B 找不到 new issues (共識達成)
5. 每輪顯示: `Round N complete: M new issues found`
6. 使用者可隨時喊停
7. **Hard requirement**: 所有 P1 必須 resolved

## 4. Stage 2: Codex Adversarial Review

### 4.1 觸發 Codex Review

使用 OpenAI 官方 codex plugin 的 `/codex:adversarial-review` (可帶 focus prompt)，或 `/codex:review --background` + `/codex:status` 輪詢。

在 context 中加入 adversarial focus:

> Focus on finding blind spots that the implementation author and Agent B reviewer
> may have BOTH missed. Look for: implicit assumptions, edge cases in CAN protocol
> handling, CRC scope errors, timeout logic, startup race conditions.

**Codex 空輸出/未收完**: 改有界重試——最多 3 次 re-poll，每次遵守既有 codex 安全規則: 指令帶 `timeout 120`，超過 30 秒無輸出即視為卡住並終止 (規則出處: knowledge-os CLAUDE.md「Codex CLI 安全注意事項」，OOM 事故換來的)。3 次仍無輸出就停，回報「Codex 無輸出」，交使用者裁決重跑或跳過。禁止無上限輪詢。

### 4.2 Codex Consensus Loop

每輪跑 `/codex:adversarial-review`，Claude 逐項評估 findings (同意 / 不同意 / 部分同意)，apply 同意項，re-run 直到 Codex 找不到 new issues。

同樣規則:
- 預設不限次數，直到共識
- 使用者可指定 rounds 或隨時喊停
- 所有 P1 必須 resolved

## 5. Stage 3: 教訓回收 (持續累積)

Summary 之前問一次:本輪 findings (含使用者在 review 過程中親自提出的重構要求) 裡,有沒有「lint / gate 抓不到、未來會再犯」的新教訓?典型是 taste 層:命名、術語、縮寫、註解密度、文件分層。

有就蒸餾成條文,append 進
`~/.claude/skills/rust-coding-standards/references/nova-conventions.md`
對應系列 (NAME / DOC / 其他),規則:

- 一條教訓 = 一個可覆核出處 (PR 編號或 commit sha)
- 已有條文涵蓋的不重複收,必要時在既有條文補出處
- 同步更新該 skill SKILL.md 的條文計數,commit skills repo (跨機同步靠它)

這一步是條文庫保持活水的機制——出處實例: PR #90 七輪可讀性重構收成 NAME-9~11、DOC-8~10 (2026-08-20)。

## 6. Stage 4: Final Summary

```markdown
### Dual Review Summary

**Agent B**: N rounds, M total findings (X fixed, Y rejected, Z suggestions noted)
**Codex**: N rounds, M total findings (X fixed, Y rejected, Z suggestions noted)
**P1 status**: All resolved ✅

| Source | # | Finding | Rule | P | Resolution |
|--------|---|---------|------|---|------------|
```

未解決的 P2+ 列出供使用者 awareness。
