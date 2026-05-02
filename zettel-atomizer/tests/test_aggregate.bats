#!/usr/bin/env bats

setup() {
    SCRIPT="$BATS_TEST_DIRNAME/../scripts/aggregate-source-whiteboard.sh"
    FIXTURES="$BATS_TEST_DIRNAME/fixtures"
    VAULT="$FIXTURES/vault"
}

@test "aggregate: 計算 source-whiteboard 覆蓋率" {
    run bash -c "cat '$FIXTURES/ebpf-tag-output.txt' | '$SCRIPT' '$VAULT'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"TOTAL=4"* ]]
    [[ "$output" == *"COVERED=2"* ]]
    [[ "$output" == *"COVERAGE=50%"* ]]
}

@test "aggregate: 列出 source-whiteboard 值的計數" {
    run bash -c "cat '$FIXTURES/ebpf-tag-output.txt' | '$SCRIPT' '$VAULT'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"《Learning eBPF》"* ]]
    count=$(echo "$output" | awk '/《Learning eBPF》/{print $1}')
    [ "$count" = "2" ]
}

@test "aggregate: 處理空 stdin" {
    run bash -c "echo '' | '$SCRIPT' '$VAULT'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"TOTAL=0"* ]]
}

@test "aggregate: vault 路徑不存在時 exit 非 0" {
    run bash -c "cat '$FIXTURES/ebpf-tag-output.txt' | '$SCRIPT' '/nonexistent/vault'"
    [ "$status" -ne 0 ]
}

@test "aggregate: 不抓 source-whiteboard 後的 CJK YAML key" {
    run bash -c "cat '$FIXTURES/cjk-after-sw-input.txt' | '$SCRIPT' '$VAULT'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"《Real Source》"* ]]
    [[ "$output" != *"should-not-be-captured"* ]]
    [[ "$output" == *"COVERAGE=100%"* ]]
}
