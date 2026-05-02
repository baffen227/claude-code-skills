#!/usr/bin/env bats

setup() {
    SCRIPT="$BATS_TEST_DIRNAME/../scripts/write-draft.sh"
    TMPVAULT=$(mktemp -d)
    export OBSIDIAN_VAULT="$TMPVAULT"
    mkdir -p "$TMPVAULT/Notes/inbox"
}

teardown() {
    rm -rf "$TMPVAULT"
}

@test "write-draft: 寫一張原子筆記到 inbox" {
    run bash -c "printf '%s\n' '---' 'status: draft' '---' '# Test' 'body' | '$SCRIPT' atomic 'Test atomic title'"
    [ "$status" -eq 0 ]
    [ -f "$TMPVAULT/Notes/inbox/$(date +%Y-%m-%d)-Test atomic title.md" ]
}

@test "write-draft: 同名檔案加流水號" {
    echo "first" > "$TMPVAULT/Notes/inbox/$(date +%Y-%m-%d)-Dup.md"
    run bash -c "printf '%s\n' '---' 'status: draft' '---' 'body' | '$SCRIPT' atomic 'Dup'"
    [ "$status" -eq 0 ]
    [ -f "$TMPVAULT/Notes/inbox/$(date +%Y-%m-%d)-Dup-2.md" ]
}

@test "write-draft: structure 類型加 structure- 前綴" {
    run bash -c "echo 'body' | '$SCRIPT' structure 'ebpf'"
    [ "$status" -eq 0 ]
    [ -f "$TMPVAULT/Notes/inbox/$(date +%Y-%m-%d)-structure-ebpf.md" ]
}

@test "write-draft: 空 stdin 失敗" {
    run bash -c "echo '' | '$SCRIPT' atomic 'Empty'"
    [ "$status" -ne 0 ]
}

@test "write-draft: vault 路徑不存在時失敗" {
    OBSIDIAN_VAULT="/nonexistent/vault" run bash -c "echo 'body' | '$SCRIPT' atomic 'Title'"
    [ "$status" -ne 0 ]
}
