# Codex CLI — Known Issues & Safe Usage

## CRITICAL: `--uncommitted` / `--base` Cannot Be Combined with `[PROMPT]`

As of codex-cli 0.112.0, `codex review` **does not allow** a custom prompt when using `--uncommitted` or `--base`. The CLI argument parser rejects this combination:

```bash
# WRONG — argument error: '--uncommitted' cannot be used with '[PROMPT]'
codex review --uncommitted "Focus on security."
codex review --base main "Review for YAGNI."

# WRONG — causes 2000+ bash forks and OOM (see incident below)
cat prompt.md | codex review --uncommitted -
```

### Correct Usage

```bash
# Use --uncommitted or --base WITHOUT a custom prompt
codex review --uncommitted
codex review --base main

# Custom prompt only works WITHOUT --uncommitted/--base
codex review "Focus on security and YAGNI."
```

## Process Safety

Always wrap codex commands with:

1. **`timeout`** — prevent runaway execution, differentiated by command type:
   - `codex review`：`timeout 60`（review 通常 10-30 秒完成）
   - `codex exec`：`timeout 180`（文件審查需讀取多檔案）
2. **`ulimit -u 256`** — cap child process count as OOM safety net

```bash
# Safe patterns
timeout 60 codex review --uncommitted
timeout 180 codex exec -s read-only "Review these files..."
```

## Incident Reference

On 2026-03-09, `cat prompt.md | codex review --uncommitted -` spawned 2,165 bash processes in 5 minutes, consuming ~88GB RSS and triggering kernel OOM killer on a 61GB machine. All desktop applications were killed.
