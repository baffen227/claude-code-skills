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

使用 OpenAI 官方 codex plugin 的 `/codex:adversarial-review` (可帶 focus prompt)，或 `/codex:review --background` + `/codex:status` 輪詢。

在 context 中加入 adversarial focus:

> Focus on finding blind spots that the implementation author and Agent B reviewer
> may have BOTH missed. Look for: implicit assumptions, edge cases in CAN protocol
> handling, CRC scope errors, timeout logic, startup race conditions.

### 4.2 Codex Consensus Loop

每輪跑 `/codex:adversarial-review`，Claude 逐項評估 findings (同意 / 不同意 / 部分同意)，apply 同意項，re-run 直到 Codex 找不到 new issues。

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
