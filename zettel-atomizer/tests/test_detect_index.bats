#!/usr/bin/env bats

setup() {
    SCRIPT="$BATS_TEST_DIRNAME/../scripts/detect-existing-index.sh"
    VAULT="$BATS_TEST_DIRNAME/fixtures/vault"
}

@test "detect: 找到 Categories/ 下檔名含 tag (case-insensitive) 的索引檔" {
    run "$SCRIPT" "$VAULT" "ebpf"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Categories/eBPF.md"* ]]
}

@test "detect: 找不到時回空字串並 exit 0" {
    run "$SCRIPT" "$VAULT" "nonexistent-tag"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "detect: vault 路徑不存在時 exit 非 0" {
    run "$SCRIPT" "/nonexistent/vault" "ebpf"
    [ "$status" -ne 0 ]
}

@test "detect: 找到 frontmatter tags 含 tag 的檔 (filename 不含 tag)" {
    run "$SCRIPT" "$VAULT" "my-tag-X"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Categories/foo-only-frontmatter-tag.md"* ]]
}
