# Document Review Prompt Templates

This file contains prompt templates for reviewing different types of documents.
The skill reads this file and selects the appropriate template based on the
document path or type being reviewed.

---

## 1. Plan Documents (`docs/plans/*.md`)

```
Review this plan document thoroughly. Evaluate it along the following dimensions:

1. **Logical completeness** — Identify any gaps in reasoning. Are there steps or
   considerations that are implied but never stated? Does the plan account for
   failure modes?

2. **Feasibility** — Assess whether the proposed steps are actually achievable
   given the context. Flag any steps that assume unavailable resources, unrealistic
   timelines, or unproven capabilities.

3. **Dependency correctness** — Examine dependency relationships between tasks,
   phases, or projects. Are there circular dependencies? Are there implicit
   dependencies that should be made explicit? Is the ordering logical?

4. **Completion criteria verifiability** — For each success criterion or
   deliverable, determine whether it can be objectively tested or verified.
   Flag vague criteria like "improve performance" that lack measurable targets.

5. **Scope creep** — Evaluate whether the plan stays focused on its stated goal.
   Identify any sections that drift beyond the original scope or introduce
   tangential concerns.

Format your output as follows:

## 重點發現
- [List critical issues that must be addressed before the plan can proceed]

## 建議改善
- [List non-critical suggestions that would strengthen the plan]

## 無問題確認
- [List aspects of the plan that are well-constructed and need no changes]
```

---

## 2. CLAUDE.md Files

```
Review this CLAUDE.md file for correctness and usefulness as an AI instruction
file. Evaluate it along the following dimensions:

1. **Consistency with actual project state** — Cross-reference the instructions
   against the repository structure. Does the file describe tools, directories,
   or workflows that actually exist? Flag any claims that contradict the
   observable project state.

2. **Outdated information** — Identify references to files, dependencies,
   commands, or conventions that may no longer exist or have changed. Look for
   version-specific instructions that may have become stale.

3. **Instruction clarity** — Assess whether each instruction is unambiguous and
   actionable. Flag instructions that use vague language, could be interpreted
   multiple ways, or lack enough context to follow correctly.

4. **Completeness** — Identify important project conventions, constraints, or
   patterns that are observable in the codebase but not documented in this file.
   Note any missing sections that would help an AI assistant work more effectively.

Format your output as follows:

## 重點發現
- [List critical issues: incorrect information, misleading instructions, or dangerous gaps]

## 建議改善
- [List non-critical suggestions for improving clarity or coverage]

## 無問題確認
- [List aspects of the file that are accurate, clear, and well-structured]
```

---

## 3. Skill Files (`SKILL.md`)

```
Review this SKILL.md file for correctness and adherence to Claude Code skill
conventions. Evaluate it along the following dimensions:

1. **Trigger description precision** — Examine the trigger block. Determine
   whether the described conditions will cause the skill to activate correctly.
   Flag triggers that are too broad (will fire on unrelated requests) or too
   narrow (will miss valid use cases).

2. **Imperative form usage** — Verify that the skill body uses imperative verbs
   (e.g., "Read the file", "Run the command"). Flag any instances of second-person
   phrasing (e.g., "You should read the file") or passive voice that reduces
   clarity.

3. **Progressive disclosure** — Assess whether the SKILL.md file stays lean and
   delegates detailed information to files in the references/ directory. Flag
   cases where the SKILL.md embeds large data blocks, lengthy examples, or
   reference tables that belong in separate files.

4. **Referenced files existence** — List every file path referenced in the
   SKILL.md. For each path, verify whether the file actually exists. Flag any
   broken references.

Format your output as follows:

## 重點發現
- [List critical issues: broken references, incorrect triggers, or convention violations]

## 建議改善
- [List non-critical suggestions for improving precision or structure]

## 無問題確認
- [List aspects of the skill that are well-defined and follow conventions correctly]
```

---

## 4. General Documents

```
Review this document for overall quality. Evaluate it along the following
dimensions:

1. **Structural clarity** — Assess the document's organization. Are headings
   logical and hierarchical? Is information grouped coherently? Can a reader
   find what they need without reading the entire document?

2. **Terminology consistency** — Identify terms that are used inconsistently
   (e.g., different names for the same concept, or the same term used with
   different meanings). Flag any undefined jargon or acronyms.

3. **Missing content or contradictions** — Identify sections where important
   information is absent or where different parts of the document contradict
   each other. Note any claims that lack necessary context or justification.

4. **Readability** — Evaluate sentence clarity, paragraph length, and overall
   flow. Flag overly dense sections, unnecessary repetition, or unclear
   phrasing.

Format your output as follows:

## 重點發現
- [List critical issues: contradictions, missing essential content, or structural problems]

## 建議改善
- [List non-critical suggestions for improving clarity, flow, or completeness]

## 無問題確認
- [List aspects of the document that are clear, well-organized, and complete]
```
