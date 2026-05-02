#!/usr/bin/env bats

setup() {
    SCRIPT="$BATS_TEST_DIRNAME/../scripts/reverse-source-notes.sh"
    VAULT="$BATS_TEST_DIRNAME/fixtures/vault"
}

@test "reverse: 從 inbox + Notes/ 反查所有 zettel-atomized 筆記的 source-notes" {
    run "$SCRIPT" "$VAULT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"BPF Maps"* ]]
    [[ "$output" == *"Hash Table Map"* ]]
}

@test "reverse: 不抓非 zettel-atomized 的筆記 (distilled-from 不對)" {
    cat > "$VAULT/inbox/2026-05-02-test-distill.md" <<'INNER_EOF'
---
distilled-from: claude-code-session
source-notes:
  - "[[Should Not Appear]]"
status: draft
---
# Test distill
INNER_EOF
    run "$SCRIPT" "$VAULT"
    [ "$status" -eq 0 ]
    [[ "$output" != *"Should Not Appear"* ]]
    rm "$VAULT/inbox/2026-05-02-test-distill.md"
}

@test "reverse: vault 路徑不存在時 exit 非 0" {
    run "$SCRIPT" "/nonexistent/vault"
    [ "$status" -ne 0 ]
}
