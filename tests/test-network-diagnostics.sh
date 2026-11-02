#!/usr/bin/env bash

# Automated tests for Linux Network Diagnostics

set -u

SCRIPT="./scripts/network-diagnostics.sh"

PASSED=0
FAILED=0

run_test() {
    local name="$1"
    local expected_code="$2"
    local expected_text="$3"
    shift 3

    local output
    local actual_code

    output=$("$SCRIPT" "$@" 2>&1)
    actual_code=$?

    if [[ "$actual_code" -eq "$expected_code" ]] &&
       [[ "$output" == *"$expected_text"* ]]; then
        echo "[PASS] $name"
        ((PASSED+=1))
    else
        echo "[FAIL] $name"
        echo "Expected exit code: $expected_code"
        echo "Actual exit code: $actual_code"
        echo "Expected text: $expected_text"
        echo "$output"
        ((FAILED+=1))
    fi
}

echo "=========================================="
echo " NETWORK DIAGNOSTICS TEST SUITE"
echo "=========================================="

run_test \
    "Local SSH connectivity" \
    0 \
    "TCP connection to 127.0.0.1:22 succeeded" \
    --host 127.0.0.1 --port 22

run_test \
    "Closed TCP port" \
    2 \
    "TCP connection to 127.0.0.1:65000 failed" \
    --host 127.0.0.1 --port 65000

run_test \
    "Invalid TCP port" \
    2 \
    "Port must be between 1 and 65535" \
    --host 127.0.0.1 --port 99999

run_test \
    "Missing hostname" \
    2 \
    "requires a value" \
    --host

run_test \
    "Unknown option" \
    2 \
    "Unknown option" \
    --unknown

echo
echo "=========================================="
echo " TEST SUMMARY"
echo "=========================================="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if (( FAILED > 0 )); then
    exit 1
fi

echo "All tests passed."
exit 0
