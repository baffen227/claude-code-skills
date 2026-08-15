---
name: wrapup
description: Use when ending a Claude Code work session and handing it off to the next one — triggers on /wrapup, "收尾", "wrap up", "wrap-up", "close out", "end of session", or a request for a next-session handoff prompt. Also use the moment you are about to claim a session is finished / done / 收尾完成. Keywords - multi-repo commit push, gate exit codes, ClickUp update, next-session handoff.
---

# Wrapup — session close-out with a verified handoff gate

## Overview

One-command close-out of a work session, human-in-the-loop throughout. Codifies the
manual ritual that ends nearly every successful session (commit/push, gates, ClickUp,
handoff) so it stops being retyped.

The non-negotiable core is the **handoff verification gate**: the next-session handoff
must carry three machine-checked elements or you MUST NOT report the session wrapped up.
Its job is to stop unverified claims — a commit hash that does not exist, gates that were
never run — from crossing the session boundary into the next agent's context.

## When to use

- User says `/wrapup`, 收尾, "wrap up", "close out", "end of session", or asks for a handoff prompt.
- You are about to tell the user a session is finished / done — run the gate first.

Not for: mid-task pauses where nothing is being handed off, or a single trivial edit with no repo state to reconcile.

## The gate (non-negotiable)

The handoff you write MUST contain, and you MUST confirm with `verify-handoff.sh`, all three:

1. **Commit** — each touched repo's commit hash, **verified to exist right now** via
   `git rev-parse`. Derive the hash from the repo at wrap-up time (`git -C <repo> rev-parse --short HEAD`);
   never copy a hash out of the session log — the log can be wrong. A touched repo with
   nothing to commit is written `commit none <repo>`.
2. **Gate exit codes** — each gate you ran with its exit code; a gate you did not run
   written `skipped`.
3. **Open items** — the unfinished-work list, or the literal `none`.

Then run:

```bash
bash ~/.claude/skills/wrapup/scripts/verify-handoff.sh <handoff-file>
```

Exit `0` → you may report 收尾完成. Non-zero → the handoff is incomplete; fix it and
re-run. **Do not report the session wrapped up until this script exits 0.** The exit
code is the gate — not your own reading of the handoff.

## Procedure

Do these in order. Every mutating step (commit, push, ClickUp write, doc write) is
human-in-the-loop: **list exactly what you will do, then wait for the user's go before
doing it.** Never batch them into one unattended run.

1. **Enumerate touched repos.** For each repo this session changed, `git -C <repo> status`.
   Propose commits for outstanding work — but **ask first** before committing generated
   directories or dirty files this session did not create (surface them, don't fold them
   in). After the user approves, commit and push. Record each repo's resulting hash from
   `git rev-parse`.
2. **Run each repo's gate set.** Find the gate commands in that repo's CLAUDE.md or
   justfile (e.g. `just check`, `cargo fmt --check`, `cargo clippy`, tests). Run each and
   record its exit code verbatim. **Never pipe a gate through grep/awk** — the pipe masks
   the real exit code. If no gate is defined, record it `skipped` and say so — do not
   invent a green result.
3. **ClickUp ticket.** Only if the session maps to a ticket. If ClickUp MCP tools are not
   loaded in this session, record `ClickUp: skipped (MCP not available)` — never silently
   drop it. Export diagrams to PNG attachments (ClickUp Docs render neither Mermaid nor
   ASCII); do not let `**` bold markers escape into visible text. List the update, wait, then write it.
4. **Design decision → doc page.** If the session settled a design decision, offer to
   draft the Wiki / `docs/` / ADR page per that repo's file policy. If the policy is
   unsettled, ask before writing.
5. **Write the handoff into the repo.** Put it in `tasks.md` or `docs/` per repo
   convention — **never `/tmp`** (lost on reboot). Use the format below, then run the gate
   script and act on its exit code.

## Handoff format

Prose the next agent reads, followed by one machine block the gate reads:

```
# Handoff — <what this session was, one line>

## State (verified at wrap-up)
- <repo>: HEAD <hash> "<subject>", pushed to <branch>; tree clean / <N> files staged.

## Gates
- <gate>: exit <N>   (or: skipped — <reason>)

## Open items
- <thing not finished>   (or: none)

## Next steps
1. <first action for the next session>

```wrapup-verify
commit <hash|none> <repo-abs-path>
gate <exit-code|skipped> <label>
open <item, or the literal: none>
```
```

Repeat `commit` / `gate` / `open` lines as needed; at least one of each is required. The
prose sections and the machine block must agree — the block is the part the gate checks.

## Red flags — STOP, do not report 收尾完成

- About to paste a commit hash from the session log instead of from `git rev-parse` run just now.
- `verify-handoff.sh` exited non-zero and you are about to say "done anyway".
- A gate "probably passes", so you wrote `exit 0` without actually running it.
- No `open` line because "nothing is left" — write `open none` explicitly; do not omit it.
- Writing the handoff to `/tmp` or leaving it only in chat scrollback.

All of these mean: fix the handoff and re-run the gate until it exits 0.

## Degrade rules — record, never silently skip

| Situation | What to record |
|---|---|
| No gate defined in a repo | `gate skipped (no gate in <repo>)` |
| ClickUp MCP not loaded | `ClickUp: skipped (MCP not available)` |
| Session maps to no ticket | `ClickUp: n/a (no ticket)` |
| Touched repo had nothing to commit | `commit none <repo>` |
| Dirty files not created this session | list them for the user; do not commit without approval |

## Cross-harness handoff

The mattpocock `handoff` skill is user-invoked (`disable-model-invocation: true`) and
writes to the OS temp dir, so wrapup does not call it. If the user wants a cross-harness /
cross-tool handoff document, tell them they can type `/mattpocock-skills:handoff`
themselves — this skill will not run it for them.
