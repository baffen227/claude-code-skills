---
name: classical-chinese-rules
description: Use when reviewing, critiquing, or polishing Traditional Chinese prose for 歐化中文 (translationese from English), or when the user cites 思果 / 翻譯研究 / 蔡濯堂, or when the user requests deep Chinese style polishing beyond the basic Concise Traditional Chinese output style rules. Auto-triggers on keywords — "校稿"、"修稿"、"潤稿"、"中文潤稿"、"潤色"、"改得更像中文"、"翻譯得不像中文"、"歐化"、"思果"、"翻譯研究" — or when the user asks to review / critique / refine any Traditional Chinese text for style.
---

# Classical Chinese Grammar Rules — 思果《翻譯研究》

Canonical literature note (461 lines, covering p.14–156) lives at:

`~/Projects/heptabase-export/obsidian-vault/Clippings/Literature note of the book《翻譯研究》.md`

**When this skill fires**: Read the full note above with the Read tool and apply 思果's rules to the current task. Do NOT duplicate the note's content into this SKILL.md — the vault file is the single source of truth. When the user adds new chapters to the vault note, this skill automatically picks them up on the next invocation.

## Scope (chapter anchors in the note)

These are the sections currently covered. Read the full note for the actual rules — this list is only a router so you know what 思果 covers:

- **p.74** 主詞省略 — 中文主詞可省，英文 we/he/they 不必一一譯出
- **p.75–77** 「們」與複數 — 中文副詞/形容詞已暗示複數，少用「們」
- **p.79** 冠詞「一個」 — `a/an` 多半可刪
- **p.79–81** 副詞與副詞位置 — 中文地方副詞前置，「所有」位置，「約略」位置
- **p.81** 名詞短語改短句 — 「他的不肯就範」→「他不肯就範」
- **p.82** 名詞與動詞 — 同一個中文詞能當名詞還是動詞要分清
- **p.82–83** 時態「曾經」/「將」 — 英文過去式不要「曾經」，未來式不要「將」
- **p.85–87** 「的」字十條細則 — 規則 1–10 針對不同語境
- **p.88–89** 「在...上/中/方面」 — `in` 的直譯多半可刪
- **p.89** 「太...以致不...」 — `too X to Y` 改寫
- **p.90** 「和/及/與」 — 多餘連接詞
- **p.90** 「大約」位置 — 句首或後接「左右」
- **p.91** 「著」字 — `-ing` 不必用「著」
- **p.91** 「是」 — 可有可無
- **p.92** 「相」、「救起/救出」、「沒有/不」、「無/未」等雜項
- **p.93–95** 代名詞 — 白話文可儘量不用代名詞
- **p.100–102** 被動語氣 — 惡劣譯文照譯「被」
- **p.107** 文白不相混 — 「係」「其」「於」是文言
- **p.112** 「同時」、「是」相等律
- **p.113–115** 中文修辭雜項 — 動詞優先、「直到...之時」
- **p.115** 「說話」引述格式
- **p.119** 單字詞 vs 雙字詞 — 單字詞常常更好
- **p.123** 詞的縮短 — 「取代」的誤用
- **p.149–150** 白話文的節奏與平仄 — 避免兩字組連續堆疊，注意句末平仄
- **p.154–156** 用名詞代動詞 / 「接受」濫用 / 「進行」濫用

## How to apply

When fired, follow this procedure:

1. **Read the canonical note** via Read tool, using absolute path above.
2. **Identify which chapter anchors apply** to the text under review. Not every rule applies to every piece of prose.
3. **Apply rules concretely** — quote the specific sentence that violates, cite the anchor (e.g., "p.85 「的」字規則六"), propose a rewrite.
4. **Prefer rewriting over commenting**. 思果 himself gives before/after examples; follow that style.
5. **Do not be pedantic about rules that don't materially improve clarity**. 思果's goal is "翻譯要像中文", not rule-counting. If a sentence is already natural Chinese, leave it.

## Relationship to the Concise Traditional Chinese output style

The output style at `~/.claude/output-styles/concise-tw.md` includes a condensed 14-rule version of 思果 as "always-on" hot path. This skill provides the full 461-line reference for:

- Deep polishing passes (`/classical-chinese-rules` or the user asking for 校稿/修稿/潤稿)
- Rules outside the 14-rule hot path (十條「的」字細則、代名詞使用、節奏平仄、副詞位置 etc.)
- Cases where the hot path rules are ambiguous and you need the full context

When the output style and this skill both cover a rule, this skill (with direct access to 思果's original text) is authoritative.

## Vault-sync note

If the user extends the canonical vault note (e.g., reads past p.156 into new chapters), the new content becomes available automatically on the next invocation of this skill because the skill reads the live file. No need to update this SKILL.md unless the file path itself changes.

## Related references (canon)

Harry's self-declared Chinese style canon (from `~/Projects/heptabase-export/obsidian-vault/Categories/如何精進中英文能力.md`):

- 思果《翻譯研究》— this skill's primary source
- 洪愛珠《老派少女購物路線》— 日常散文節奏參考
- Zinsser《On Writing Well》— 英文寫作的簡潔原則
- 舒國治《門外漢的京都》《台北小吃札記》— 短句留白參考
- 侯捷 — 技術翻譯術語的精確處理
