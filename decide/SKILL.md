---
name: decide
description: Use when the user wants to walk through the decisions still waiting on them, one at a time — triggers on /decide, 「逐項來看要決定的事情」, 「逐項決定」, or any request to go through open decisions item by item.
---

# Decide — walk pending decisions one at a time

## Overview

Turns the open questions left in this session into answered and executed decisions:
one question, one action, one report line per item, then a closing table.

## Step 1: Collect pending items

1. Scan your previous reply for anything still waiting on the user's decision.
2. If it has none, scan back through this session for decisions raised and never closed.
3. If nothing is pending, say so in one line and stop. Do not invent decisions.

Order items so ones that block others come first. Show the count and a one-line title
per item, then start.

## Step 2: Ask one item at a time

Use AskUserQuestion with exactly one question per call.

- Recommended option first, label ending in ` (Recommended)`.
- Every option's description is a one-sentence reason.
- 2–4 options. The tool adds "Other" itself; do not add one.
- An option that leads to an irreversible or outward-facing action (sending email,
  deleting, `git push`, commenting where others can see) names that action in its label
  or description, e.g. 「寄信給 PM」「push 到 origin/main」「刪除 ClickUp task X」.

## Step 3: Execute, report, then ask the next

As soon as the user answers, carry it out — file edits, calendar, ClickUp, Notion,
memory, whatever the decision needs. Then report in one line what changed and where
(path, task link, event), and ask the next item.

**Consent.** Choosing an option that names an irreversible or outward action is consent
to that action. Do not ask again. An irreversible or outward action the chosen option
did not name needs its own confirmation before you do it.

**Write permission.** Whether you may write directly (vs. draft first, ask first) follows
the current repo's CLAUDE.md. This skill does not override project rules.

If an action fails or is blocked, report it in one line, mark the item unfinished,
and move on. Same for items the user defers.

## Step 4: Closing table

After the last item:

| 項目 | 決定 | 改了哪裡 |
|---|---|---|

Then list unfinished items separately, each with the reason (failed, deferred, blocked
by project rules).

## Language

Replies follow the active output style (Traditional Chinese under `concise-tw`). This
file being English does not change the reply language.

## Common mistakes

- Packing several items into one AskUserQuestion call.
- Asking 「確定要寄嗎？」 after the user picked an option that already said 寄信.
- Doing an outward action the chosen option never mentioned.
- Collecting all answers first and executing at the end.
- Turning finished items or open-ended discussion into fake decisions.
