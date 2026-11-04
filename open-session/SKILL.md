---
name: open-session
description: Use when a Claude Code session needs to start another Claude Code session in a new Herdr tab and hand it an opening prompt — triggers on /open-session, 「開新 session」, or a request to open a session for another repo or task from inside Herdr, under the personal or the company (work) Claude account.
---

# Open-session — start a Claude Code session in a new Herdr tab

## Overview

Covers only opening the session: new tab, start Claude, rename, send the opening prompt,
confirm it landed. What the opening prompt says is the caller's job.

**REQUIRED BACKGROUND:** run `herdr --skill` and follow it for CLI syntax and agent states.
This file records only the user's conventions and known pitfalls, and overrides the Herdr
skill where they differ.

Out of scope: talking to the new session afterwards (SendMessage; across accounts see below), closing the tab.

## Steps

1. **Check Herdr.** `HERDR_ENV` must be `1`. If not, say so and stop.
2. **Pick the account.** The user has two Claude accounts, each with its own config dir:

   | Account | Config dir | `tab create` flag |
   |---|---|---|
   | `personal` | `~/.claude` (Claude Code's built-in location) | none |
   | `work` (company, org BTBU) | `~/.claude-work` | `--env CLAUDE_CONFIG_DIR=$HOME/.claude-work` |

   There is no default. The request must name the account. If it does not, ask the user
   which one before creating the tab — do not infer it from the target path or from the
   calling session's account. A new tab without `--env` starts with `CLAUDE_CONFIG_DIR`
   unset, even if the calling session is `work`, so `personal` needs no flag.
3. **New tab, not a split.** The Herdr skill defaults to splitting the current tab; the user
   wants a new tab. Add the account flag from step 2:
   ```bash
   herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd <target repo absolute path> --label <name> --no-focus [--env CLAUDE_CONFIG_DIR=$HOME/.claude-work]
   ```
   Use one `<name>` throughout: tab label, Herdr agent name, and session name. It must fit
   Herdr's agent-name pattern (lowercase, digits, `-`, `_`).
4. **Start Claude** in the returned root pane: `herdr agent start <name> --kind claude --pane <root_pane id>`.
5. **`agent_not_ready`** → `herdr agent read <name>`. If the screen is the first-visit folder
   trust prompt, tell the user and let them choose. Never answer it for them. Continue only
   after they say it is done. Each account keeps its own trust list, so a folder already
   trusted under `personal` asks again the first time under `work`.
6. **Rename:** prompt `/rename <name>`. `agent_prompt_stalled` here is expected — slash
   commands never enter `working`. It is not a failure.
7. **Check the input box is empty** with `herdr agent read` before sending the opening. The
   user may have typed a draft there; a prompt would be appended to it and sent together.
   If it is not empty, ask the user. Do not clear it yourself.
8. **Send the opening.** Write a long opening to a file in your scratchpad first, then
   `herdr agent prompt <name> "$(cat <file>)"`. `--wait` with a timeout will time out
   because the new session is `working` — that is expected, not a failure.
9. **Confirm and report.** Read the screen again with `herdr agent read <name> --source visible`:
   the full opening arrived and the state is `working`. Do not use the default `--source recent`
   or `recent-unwrapped` with `--lines` here — while the session is `working` they return
   `agent_not_idle` (scrollback can only be captured while idle). That error is expected, not a
   failure; do not resend the opening. Then report to the user: tab label and id, working
   directory, session name, account, opening file path.

## Talking to the new session across accounts

Sessions under different accounts do not see each other in `ListAgents`, so SendMessage
cannot reach them (verified 2026-11-04). Use `herdr agent prompt <name>` or `~/dispatch/`
task files instead. Put the right channel in the opening's "who to report back to" line.

## Opening checklist (reminder, not a template)

An opening usually covers:

- Ticket and plan document to follow
- What this session is for, and what is out of scope
- Rules that apply (repo CLAUDE.md, what needs approval)
- Who to report back to when done, and how

## Common mistakes

- Splitting the current tab because the Herdr skill says so.
- Guessing the account when the request did not name one, instead of asking.
- Telling a `work` session to report back with SendMessage to a `personal` session.
- Answering the trust prompt for the user.
- Treating `agent_prompt_stalled` after `/rename`, or a `--wait` timeout after the opening,
  as failure and retrying — this sends the text twice.
- Reading the screen back with `--source recent` / `recent-unwrapped` while the new session is
  `working`, then taking `agent_not_idle` as a failed send and resending the opening. Use
  `--source visible`.
- Sending the opening without reading the input box first.
- Reporting done before reading the screen back.
