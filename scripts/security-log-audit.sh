#!/usr/bin/env bash

# Linux Security Log Analyzer
# Read-only SSH authentication log analysis.

set -uo pipefail

SOURCE="journal"
INPUT_FILE=""
SINCE="24 hours ago"
THRESHOLD=5

usage() {
    cat <<EOF
Linux Security Log Analyzer

Usage:
  $0 [OPTIONS]

Options:
  --file PATH        Analyze a log file
  --since TIME       Journal time range (default: 24 hours ago)
  --threshold N      Failed attempts threshold (default: 5)
  --help             Show help

Examples:
  sudo $0
  sudo $0 --since "1 hour ago"
  $0 --file tests/fixtures/ssh-auth.log
  $0 --file tests/fixtures/ssh-auth.log --threshold 3
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --file)
            [[ $# -ge 2 && -n "$2" ]] || {
                echo "ERROR: --file requires a path." >&2
                exit 2
            }
            SOURCE="file"
            INPUT_FILE="$2"
            shift 2
            ;;
        --since)
            [[ $# -ge 2 && -n "$2" ]] || {
                echo "ERROR: --since requires a value." >&2
                exit 2
            }
            SINCE="$2"
            shift 2
            ;;
        --threshold)
            [[ $# -ge 2 && "$2" =~ ^[0-9]+$ ]] || {
                echo "ERROR: --threshold requires a non-negative integer." >&2
                exit 2
            }
            THRESHOLD="$2"
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

if [[ "$SOURCE" == "file" ]]; then
    if [[ ! -f "$INPUT_FILE" || ! -r "$INPUT_FILE" ]]; then
        echo "ERROR: Cannot read log file: $INPUT_FILE" >&2
        exit 2
    fi
    LOGS=$(cat "$INPUT_FILE") || exit 2
else
    if [[ "$EUID" -ne 0 ]]; then
        echo "ERROR: Journal analysis requires sudo." >&2
        exit 2
    fi

    LOGS=$(journalctl -u ssh --since "$SINCE" --no-pager -o cat) || {
        echo "ERROR: Failed to read SSH journal." >&2
        exit 2
    }
fi

FAILED_LOGS=$(printf '%s\n' "$LOGS" | grep -E 'Failed password for ' || true)
SUCCESS_LOGS=$(printf '%s\n' "$LOGS" | grep -E 'Accepted (password|publickey) for ' || true)

count_lines() {
    local data="$1"

    if [[ -z "$data" ]]; then
        echo 0
    else
        printf '%s\n' "$data" | wc -l
    fi
}

FAILED_COUNT=$(count_lines "$FAILED_LOGS")
SUCCESS_COUNT=$(count_lines "$SUCCESS_LOGS")

echo "=========================================="
echo "       LINUX SECURITY LOG AUDIT"
echo "=========================================="
echo "Date: $(date)"
echo "Host: $(hostname)"
echo "Source: $SOURCE"

if [[ "$SOURCE" == "journal" ]]; then
    echo "Time range: $SINCE"
else
    echo "Input file: $INPUT_FILE"
fi

echo
echo "[1] Authentication Summary"
echo "------------------------------------------"
echo "Successful SSH logins: $SUCCESS_COUNT"
echo "Failed SSH logins: $FAILED_COUNT"

echo
echo "[2] Failed Login Source IPs"
echo "------------------------------------------"

if [[ "$FAILED_COUNT" -gt 0 ]]; then
    printf '%s\n' "$FAILED_LOGS" |
        awk '{
            for (i = 1; i <= NF; i++) {
                if ($i == "from") {
                    print $(i+1)
                    break
                }
            }
        }' |
        sort |
        uniq -c |
        sort -nr
else
    echo "No failed SSH logins found."
fi

echo
echo "[3] Security Assessment"
echo "------------------------------------------"

if (( FAILED_COUNT >= THRESHOLD && FAILED_COUNT > 0 )); then
    echo "Status: REVIEW REQUIRED"
    echo "Reason: Failed SSH login threshold reached."
else
    echo "Status: OK"
    echo "Reason: Failed SSH login count is below threshold."
fi

echo
echo "Security log audit completed."
