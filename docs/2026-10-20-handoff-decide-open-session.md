---
audience: agent
---

# Handoff — added global skills `decide` and `open-session` (2026-10-20)

## State (verified at wrap-up)
- claude-code-skills: HEAD 716d251 "open-session: add skill for starting a Claude Code session in a new Herdr tab", pushed to origin/main; tree clean. This handoff file is committed on top of it.
- `decide` landed in 73c3f4e. Both skills are in `setup.sh` `SKILLS` and symlinked under `~/.claude/skills/`.
- `executive-briefing` stays in the private dotfiles repo by the user's decision (not moved here; this repo is public).

## Gates
- `bash -n setup.sh`: exit 0
- `./setup.sh`: exit 0
- No gate is defined in this repo's CLAUDE.md; the two above are ad-hoc checks.
- ClickUp: n/a (no ticket)

## Open items
- `open-session` has not been exercised on a real session yet; the 8 steps come from the tracker session's two manual runs (2026-10-19, 2026-10-20).
- Tracker session was messaged about completion; no reply seen before wrap-up.

## Next steps
1. On the first real `/open-session` run, watch each step's Herdr response and fold any new pitfall into `open-session/SKILL.md` "Common mistakes".

```wrapup-verify
commit 716d251 /home/bagfen/Projects/claude-code-skills
gate 0 bash -n setup.sh
gate 0 ./setup.sh
open open-session not yet exercised on a real session
open tracker has not confirmed receipt of the completion message
```
