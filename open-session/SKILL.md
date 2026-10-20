---
name: open-session
description: Use when a Claude Code session needs to start another Claude Code session in a new Herdr tab and hand it an opening prompt — triggers on /open-session, 「開新 session」, or a request to open a session for another repo or task from inside Herdr.
---

# Open-session — start a Claude Code session in a new Herdr tab

## Overview

Covers only opening the session: new tab, start Claude, rename, send the opening prompt,
confirm it landed. What the opening prompt says is the caller's job.

**REQUIRED BACKGROUND:** run `herdr --skill` and follow it for CLI syntax and agent states.
This file records only the user's conventions and known pitfalls, and overrides the Herdr
skill where they differ.

Out of scope: talking to the new session afterwards (use SendMessage), closing the tab.

## Steps

1. **Check Herdr.** `HERDR_ENV` must be `1`. If not, say so and stop.
2. **New tab, not a split.** The Herdr skill defaults to splitting the current tab; the user
   wants a new tab:
   ```bash
   herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd <target repo absolute path> --label <name> --no-focus
   ```
   Use one `<name>` throughout: tab label, Herdr agent name, and session name. It must fit
   Herdr's agent-name pattern (lowercase, digits, `-`, `_`).
3. **Start Claude** in the returned root pane: `herdr agent start <name> --kind claude --pane <root_pane id>`.
4. **`agent_not_ready`** → `herdr agent read <name>`. If the screen is the first-visit folder
   trust prompt, tell the user and let them choose. Never answer it for them. Continue only
   after they say it is done.
5. **Rename:** prompt `/rename <name>`. `agent_prompt_stalled` here is expected — slash
   commands never enter `working`. It is not a failure.
6. **Check the input box is empty** with `herdr agent read` before sending the opening. The
   user may have typed a draft there; a prompt would be appended to it and sent together.
   If it is not empty, ask the user. Do not clear it yourself.
7. **Send the opening.** Write a long opening to a file in your scratchpad first, then
   `herdr agent prompt <name> "$(cat <file>)"`. `--wait` with a timeout will time out
   because the new session is `working` — that is expected, not a failure.
8. **Confirm and report.** Read the screen again: the full opening arrived and the state is
   `working`. Then report to the user: tab label and id, working directory, session name,
   opening file path.

## Opening checklist (reminder, not a template)

An opening usually covers:

- Ticket and plan document to follow
- What this session is for, and what is out of scope
- Rules that apply (repo CLAUDE.md, what needs approval)
- Who to report back to when done, and how

## Common mistakes

- Splitting the current tab because the Herdr skill says so.
- Answering the trust prompt for the user.
- Treating `agent_prompt_stalled` after `/rename`, or a `--wait` timeout after the opening,
  as failure and retrying — this sends the text twice.
- Sending the opening without reading the input box first.
- Reporting done before reading the screen back.
