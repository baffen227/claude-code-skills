---
name: rust-coding-standards
description: Use when reviewing or writing Rust code in BTBU firmware projects (nrg-prototype, INT-004 / INT-005 / MCU Self Test, FMEA), or when CLAUDE.md red-line references invoke clean-code / minimalism / modularity rules. Loads full Rust coding discipline (clean-code.md / minimalism.md / modularity.md) and supplementary dual-review design + idiomatic-rust plan for deep coding-quality pass.
---

# Rust Coding Standards — BTBU Firmware

This skill provides the full text of BTBU's Rust coding standards. It is the **cold path** companion to the hot-path red-line citations in each project's `CLAUDE.md` (typically `紅線 1-7`).

## When this skill fires

- Reviewer wants to cite a specific rule (CC1 ~ CC13 / MIN-1 ~ MIN-6 / MOD-1 ~ MOD-5) beyond the red-line summary
- New project being set up needs to import the full coding-standards reference
- Existing project's `CLAUDE.md` red-line bullet feels insufficient and reviewer needs supporting detail
- Code review identifies a violation that needs canonical wording for the finding

## Reference structure

- `references/clean-code.md` — CC1 ~ CC13 canonical rules (naming, error handling, function size, dead code)
- `references/minimalism.md` — MIN-1 ~ MIN-6 (scope control, anti-patterns, no future-needs coding)
- `references/modularity.md` — MOD-1 ~ MOD-5 (layer diagram, extraction criteria, dependency direction)
- `references/2026-04-08-coding-standards-dual-review-design.md` — design history for `/dual-review` workflow
- `references/2026-04-08-coding-standards-dual-review-plan.md` — implementation plan for `/dual-review`
- `references/2026-04-18-idiomatic-rust-plan.md` — idiomatic Rust improvement plan (ClickUp FW-8 work item)

## How to apply

1. Read whichever `references/<file>.md` matches the rule the user is asking about
2. Quote the specific rule (e.g. "CC2: function ≤ 40 lines") with its canonical wording
3. Refer back to project `CLAUDE.md` to confirm the red-line summary still aligns

## Migration provenance

Migrated 2026-05-20 from `can_integration_testing/docs/coding-standards/` per `can_integration_testing/docs/superpowers/specs/2026-05-20-can-integration-testing-decomposition-design.md` Path 1. Original location replaced by red-line references pointing here.
