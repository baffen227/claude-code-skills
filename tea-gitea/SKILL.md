---
name: tea-gitea
description: |
  DEPRECATED 2026-05-13 — BTBU 部門已把 nrg-prototype repo 從 Gitea (`git.fortune-battery-systems-lab.com.tw`) 遷至 GitHub (`github.com/fortuneBTBU`)。日常 PR / issue / comment 應改用 `gh` CLI 操作 GitHub。本 skill 僅保留供讀取舊 Gitea repo 歷史 issue / PR / comment (如 #1334 / #1338 / #1341 / #1345 / #1357 等) 之用,**不要**用於新工作流程。等 GitHub 工作流穩定後評估是否整個刪除。
  歷史觸發詞 (僅限 archived Gitea repo 讀取): "Gitea issue", "建立 issue", "tea issues create", "tea pr", "edit PR", "更新 PR", "post comment", "gitea comment", "tea CLI"。
---

# tea-gitea — Gitea Operations via tea CLI (DEPRECATED 2026-05-13)

> **遷移備註**: BTBU 部門 nrg-prototype repo 已從 Gitea 遷至 GitHub (`git@github.com:fortuneBTBU/nrg-prototype.git`)。新 PR / issue / comment 走 `gh` CLI。本 skill 僅供讀取 Gitea archived repo 歷史紀錄使用,**不再是日常工作流程的一部分**。

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
| Create issue | `tea issues create --login btbu-gitea --repo FortuneElectric/nrg-prototype --title "..." --description "..."` |
| Search issues | `tea issues --login btbu-gitea --repo FortuneElectric/nrg-prototype --state open --output simple` |
| List PRs | `tea pulls --login btbu-gitea --repo FortuneElectric/nrg-prototype` |
| Edit PR title/body | REST API `PATCH /pulls/{N}` (see Recipes) |

## Critical Quirks (tea v0.12.0)

1. **`tea comment` does NOT support `--body` flag**. Use `tea api -F` instead.
2. **`tea api` does NOT support `--body`**. Use `-F "key=value"` for fields, `-F "key=@file"` to read from file.
3. **`tea issues details` does NOT show issue body**. Use `tea api GET` to read full content.
4. **`tea issues create` uses `--description`, NOT `--body`**. `--body` flag does not exist and will error.
5. **`tea pr edit` does NOT exist**. PR title/body edits require REST API `PATCH /pulls/{N}`.
6. **`tea labels list` only shows repo-level labels**. Org-level labels return empty — infer from existing issues instead.
7. **Token scope**: `write:issue` covers issues only. PR edits need `write:repository`.
8. **JSON output**: Pipe `tea api` through `python3 -c "import json,sys; ..."` for parsing.

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

### Edit PR Title / Body

`tea pr edit` does not exist. Use REST API with `curl` (requires `write:repository` token scope):

```bash
# Update PR title
curl -s -X PATCH \
  -H "Authorization: token $(grep -A5 'btbu-gitea' ~/.config/tea/config.yml | grep token | head -1 | awk '{print $2}')" \
  -H "Content-Type: application/json" \
  -d '{"title": "New PR Title"}' \
  "https://git.fortune-battery-systems-lab.com.tw/api/v1/repos/FortuneElectric/nrg-prototype/pulls/{N}"

# Update PR body (use python to JSON-encode multiline content)
BODY_JSON=$(python3 -c "import json; print(json.dumps(open('/tmp/pr_body.md').read()))")
curl -s -X PATCH \
  -H "Authorization: token $(grep -A5 'btbu-gitea' ~/.config/tea/config.yml | grep token | head -1 | awk '{print $2}')" \
  -H "Content-Type: application/json" \
  -d "{\"body\": $BODY_JSON}" \
  "https://git.fortune-battery-systems-lab.com.tw/api/v1/repos/FortuneElectric/nrg-prototype/pulls/{N}"
```

**Verify**: Parse response for `number` and `title`.

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
| `tea issues create --body "..."` | Use `--description "..."` (no `--body` flag) |
| `tea pr edit 1331 --title "..."` | Use REST API `PATCH /pulls/{N}` (`tea pr edit` does not exist) |
| Inline JSON in `-F` with newlines | Write to temp file first, use `@file` |
| Forget `--login btbu-gitea` | Always include — no repo-local context |
| Expect `tea issues details` to show body | Use `tea api GET` instead |
| PR edit returns 403 / scope error | Token needs `write:repository`, not just `write:issue` |
| `tea labels list` returns empty | Labels are org-level; infer from existing issues |

## Reference

- Gitea API docs: `https://git.fortune-battery-systems-lab.com.tw/api/swagger`
- tea CLI help: `tea <command> --help`
- Setup guide: `docs/tea-gitea-setup.md` (in can_integration_testing repo)
