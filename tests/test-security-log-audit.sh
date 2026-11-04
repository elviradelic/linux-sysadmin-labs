#!/usr/bin/env bash

# Automated tests for Linux Security Log Analyzer

set -u

SCRIPT="./scripts/security-log-audit.sh"
FIXTURE="tests/fixtures/ssh-auth.log"

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
echo " SECURITY LOG AUDIT TEST SUITE"
echo "=========================================="

run_test \
    "Successful login count" \
    0 \
    "Successful SSH logins: 2" \
    --file "$FIXTURE"

run_test \
    "Failed login count" \
    0 \
    "Failed SSH logins: 4" \
    --file "$FIXTURE"

run_test \
    "Threshold reached" \
    0 \
    "Status: REVIEW REQUIRED" \
    --file "$FIXTURE" --threshold 3

run_test \
    "Threshold not reached" \
    0 \
    "Status: OK" \
    --file "$FIXTURE" --threshold 5

run_test \
    "Repeated failed logins from one IP" \
    0 \
    "3 192.0.2.20" \
    --file "$FIXTURE"

run_test \
    "Failed login from second IP" \
    0 \
    "1 192.0.2.30" \
    --file "$FIXTURE"

run_test \
    "Missing input file" \
    2 \
    "Cannot read log file" \
    --file tests/fixtures/missing.log

run_test \
    "Invalid threshold" \
    2 \
    "requires a non-negative integer" \
    --file "$FIXTURE" --threshold abc

run_test \
    "Unknown argument" \
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
