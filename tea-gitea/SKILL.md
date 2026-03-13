---
name: tea-gitea
description: Use when interacting with Gitea — posting comments, reading issues, listing PRs, creating issues, or any operation on the BTBU Gitea server. Triggers on "update Gitea", "post to issue", "Gitea issue", "gitea comment", "tea CLI".
---

# tea-gitea — Gitea Operations via tea CLI

## Overview

Encode working patterns for `tea` v0.12.0 CLI + Gitea REST API. Avoids trial-and-error with undocumented quirks.

## Defaults

- **Login**: `btbu-gitea`
- **Repo**: `FortuneElectric/nrg-prototype`
- **Server**: `https://git.fortune-battery-systems-lab.com.tw`

All `tea` commands below assume `--login btbu-gitea --repo FortuneElectric/nrg-prototype` unless noted.

## Quick Reference

| Operation | Command |
|-----------|---------|
| List open issues | `tea issues --login btbu-gitea --repo FortuneElectric/nrg-prototype --limit 20` |
| Read issue body | `tea api --login btbu-gitea "/repos/FortuneElectric/nrg-prototype/issues/{N}"` |
| Read issue comments | `tea api --login btbu-gitea "/repos/FortuneElectric/nrg-prototype/issues/{N}/comments"` |
| Post comment | `tea api --login btbu-gitea -X POST "/repos/FortuneElectric/nrg-prototype/issues/{N}/comments" -F "body=@/tmp/comment.md"` |
| Create issue | `tea issues create --login btbu-gitea --repo FortuneElectric/nrg-prototype --title "..." --body "..."` |
| Search issues | `tea issues --login btbu-gitea --repo FortuneElectric/nrg-prototype --state open --output simple` |
| List PRs | `tea pulls --login btbu-gitea --repo FortuneElectric/nrg-prototype` |

## Critical Quirks (tea v0.12.0)

1. **`tea comment` does NOT support `--body` flag**. Use `tea api -F` instead.
2. **`tea api` does NOT support `--body`**. Use `-F "key=value"` for fields, `-F "key=@file"` to read from file.
3. **`tea issues details` does NOT show issue body**. Use `tea api GET` to read full content.
4. **JSON output**: Pipe `tea api` through `python3 -c "import json,sys; ..."` for parsing.

## Recipes

### Post Comment to Issue

**This is the most common operation.** Always write to temp file first, then post via API.

```bash
# Step 1: Write comment to temp file
cat > /tmp/gitea_comment.md << 'EOF'
## Comment Title

Comment body here...
EOF

# Step 2: Post via API
tea api --login btbu-gitea -X POST \
  "/repos/FortuneElectric/nrg-prototype/issues/{N}/comments" \
  -F "body=@/tmp/gitea_comment.md"
```

**Verify success**: Parse response JSON for `id` and `created_at`.

```bash
tea api ... 2>&1 | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(f'Comment posted: id={d[\"id\"]}, created={d[\"created_at\"][:10]}')
"
```

### Post ZH/EN Comment Pair

Issue #1334 follows a convention: each update is posted as two comments (Traditional Chinese first, then English), using collapsible `<details>` sections.

```bash
# Write ZH comment
cat > /tmp/gitea_comment_zh.md << 'EOF'
## 標題 — 簡短摘要

<details>
<summary>詳細內容 (點擊展開)</summary>

### 子標題
- 內容...

</details>
EOF

# Write EN comment
cat > /tmp/gitea_comment_en.md << 'EOF'
## Title — Short Summary

<details>
<summary>Details (click to expand)</summary>

### Subsection
- Content...

</details>
EOF

# Post both
tea api --login btbu-gitea -X POST \
  "/repos/FortuneElectric/nrg-prototype/issues/1334/comments" \
  -F "body=@/tmp/gitea_comment_zh.md"

tea api --login btbu-gitea -X POST \
  "/repos/FortuneElectric/nrg-prototype/issues/1334/comments" \
  -F "body=@/tmp/gitea_comment_en.md"
```

### Read Issue Comments

```bash
tea api --login btbu-gitea \
  "/repos/FortuneElectric/nrg-prototype/issues/{N}/comments" \
  2>&1 | python3 -c "
import json, sys
comments = json.load(sys.stdin)
for c in comments:
    print(f'--- #{c[\"id\"]} by {c[\"user\"][\"login\"]} ({c[\"created_at\"][:10]}) ---')
    body = c['body']
    print(body[:200] + '...' if len(body) > 200 else body)
    print()
"
```

### Read Issue Body

```bash
tea api --login btbu-gitea \
  "/repos/FortuneElectric/nrg-prototype/issues/{N}" \
  2>&1 | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(f'#{d[\"number\"]} [{d[\"state\"]}] {d[\"title\"]}')
print(f'Labels: {[l[\"name\"] for l in d[\"labels\"]]}')
print('---')
print(d['body'])
"
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| `tea comment 1334 --body "..."` | Use `tea api -X POST -F "body=@file"` |
| `tea api --body '{"body":"..."}'` | Use `-F "body=@file"` (no `--body` flag) |
| Inline JSON in `-F` with newlines | Write to temp file first, use `@file` |
| Forget `--login btbu-gitea` | Always include — no repo-local context |
| Expect `tea issues details` to show body | Use `tea api GET` instead |

## Reference

- Gitea API docs: `https://git.fortune-battery-systems-lab.com.tw/api/swagger`
- tea CLI help: `tea <command> --help`
- Setup guide: `docs/tea-gitea-setup.md` (in can_integration_testing repo)
