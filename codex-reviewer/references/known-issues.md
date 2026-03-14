# Codex CLI — Known Issues & Safe Usage

> **Last verified**: codex-cli 0.114.0 on 2026-03-14. Earlier versions (0.112.0+) exhibit the same behavior. Versions prior to 0.112.0 have not been tested.

## Unsupported Argument Combination

`codex review` **does not allow** a custom prompt when using `--uncommitted` or `--base`. The CLI argument parser rejects this combination:

```bash
# WRONG — argument error: '--uncommitted' cannot be used with '[PROMPT]'
codex review --uncommitted "Focus on security."
codex review --base main "Review for YAGNI."
```

### Correct Usage

```bash
# Use --uncommitted or --base WITHOUT a custom prompt
codex review --uncommitted
codex review --base main

# Custom prompt only works WITHOUT --uncommitted/--base
codex review "Focus on security and YAGNI."
```

> **Workaround**：若需要 `--uncommitted` 或 `--base` 搭配自訂審查維度，先用 `codex review --uncommitted`（或 `codex review --base <branch>`）取得內建審查結果，再由 Claude 根據自訂維度補充分析。詳見 SKILL.md Section 5。

## Unsafe stdin/pipe Pattern

透過 stdin 或 pipe 傳遞 prompt 給 `codex review` 會導致災難性的 fork bomb。這與上述參數限制是**不同的問題**——即使 CLI 不報錯，shell 層的 pipe 行為會觸發失控的子進程產生。

```bash
# WRONG — causes 2000+ bash forks and OOM (see incident below)
cat prompt.md | codex review --uncommitted -
```

**Rule: Never pipe stdin to `codex review`, regardless of flags.**

## Process Safety

Always wrap `codex review` and `codex exec` commands with:

1. **`timeout 300`** — 防止 runaway execution（review 與 exec 皆使用 300 秒上限）
2. **`ulimit -u 256`** — cap child process count as OOM safety net

```bash
# Safe patterns
(ulimit -u 256; timeout 300 codex review --uncommitted)
(ulimit -u 256; timeout 300 codex exec -s read-only "Review these files...")
```

## Incident Reference

On 2026-03-09, `cat prompt.md | codex review --uncommitted -` spawned 2,165 bash processes in 5 minutes, consuming ~88GB RSS and triggering kernel OOM killer on a 61GB machine. All desktop applications were killed.

**Takeaway**: This incident is the direct reason for the stdin/pipe prohibition and the `timeout` + `ulimit` safety wrappers above.
