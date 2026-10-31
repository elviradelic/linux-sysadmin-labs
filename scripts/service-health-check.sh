#!/usr/bin/env bash

# Linux Service Health Monitor
# Monitors systemd services, process resources and recent errors.

set -u

SERVICES=()
OUTPUT=""
SINCE="1 hour ago"
WARNING_ERRORS=1
CRITICAL_ERRORS=5

usage() {
    cat <<EOF
Linux Service Health Monitor

Usage:
  $0 [OPTIONS]

Options:
  --services NAME...   Services to monitor
  --output FILE        Save report to a file
  --since TIME         Journal time window (default: "1 hour ago")
  --help               Show this help message

Examples:
  $0 --services ssh cron
  $0 --services ssh cron --output reports/health.log
  $0 --services ssh --since "30 minutes ago"
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --services)
            shift

            while [[ $# -gt 0 && "$1" != --* ]]; do
                SERVICES+=("$1")
                shift
            done
            ;;
        --output)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --output requires a file path." >&2
                exit 2
            fi
            OUTPUT="$2"
            shift 2
            ;;
        --since)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --since requires a time value." >&2
                exit 2
            fi
            SINCE="$2"
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: Unknown argument: $1" >&2
            usage
            exit 2
            ;;
    esac
done

if [[ ${#SERVICES[@]} -eq 0 ]]; then
    SERVICES=(ssh cron systemd-journald)
fi

if ! command -v systemctl >/dev/null 2>&1; then
    echo "ERROR: systemctl is required." >&2
    exit 2
fi

if [[ -n "$OUTPUT" ]]; then
    OUTPUT_DIR=$(dirname "$OUTPUT")

    if ! mkdir -p "$OUTPUT_DIR"; then
        echo "ERROR: Cannot create output directory." >&2
        exit 2
    fi

    if ! touch "$OUTPUT"; then
        echo "ERROR: Cannot write report file." >&2
        exit 2
    fi

    exec > >(tee "$OUTPUT")
fi

HEALTHY=0
WARNINGS=0
CRITICAL=0
CHECKED=0

echo "=========================================="
echo "       LINUX SERVICE HEALTH MONITOR"
echo "=========================================="
echo "Host: $(hostname)"
echo "Date: $(date)"
echo "Services: ${SERVICES[*]}"
echo "Log window: $SINCE"
echo

for SERVICE in "${SERVICES[@]}"; do
    ((CHECKED+=1))

    echo "[$CHECKED] $SERVICE"
    echo "------------------------------------------"

    LOAD_STATE=$(systemctl show "$SERVICE" \
        -p LoadState --value 2>/dev/null)

    if [[ "$LOAD_STATE" != "loaded" ]]; then
        echo "Status: NOT FOUND"
        echo "Result: CRITICAL"
        ((CRITICAL+=1))
        echo
        continue
    fi

    ACTIVE_STATE=$(systemctl is-active "$SERVICE" 2>/dev/null || true)

    MAIN_PID=$(systemctl show "$SERVICE" \
        -p MainPID --value 2>/dev/null)

    ENABLED_STATE=$(systemctl is-enabled "$SERVICE" 2>/dev/null || true)

    echo "State: $ACTIVE_STATE"
    echo "Enabled: $ENABLED_STATE"
    echo "PID: $MAIN_PID"

    if [[ "$ACTIVE_STATE" != "active" ]]; then
        echo "Result: CRITICAL"
        ((CRITICAL+=1))
        echo
        continue
    fi

    if [[ "$MAIN_PID" =~ ^[0-9]+$ ]] && (( MAIN_PID > 0 )); then
        PROCESS_INFO=$(ps -p "$MAIN_PID" \
            -o %cpu=,%mem=,rss= 2>/dev/null || true)

        if [[ -n "$PROCESS_INFO" ]]; then
            read -r CPU MEM RSS <<< "$PROCESS_INFO"

            MEMORY_MB=$(awk -v rss="$RSS" \
                'BEGIN {printf "%.1f", rss/1024}')

            echo "CPU: ${CPU}%"
            echo "Memory: ${MEMORY_MB} MB"
            echo "Memory usage: ${MEM}%"
        else
            echo "Process metrics: unavailable"
        fi
    else
        echo "Process metrics: no main PID"
    fi

    ERROR_COUNT="unknown"

    if command -v journalctl >/dev/null 2>&1; then
        JOURNAL_OUTPUT=$(journalctl \
            -u "$SERVICE" \
            --since "$SINCE" \
            -p err \
            --no-pager \
            -q \
            --output=short 2>/dev/null)

        JOURNAL_STATUS=$?

        if [[ "$JOURNAL_STATUS" -eq 0 ]]; then
            if [[ -z "$JOURNAL_OUTPUT" ]]; then
                ERROR_COUNT=0
            else
                ERROR_COUNT=$(printf '%s\n' "$JOURNAL_OUTPUT" | wc -l)
            fi
        fi
    fi

    echo "Recent error entries: $ERROR_COUNT"

    if [[ "$ERROR_COUNT" == "unknown" ]]; then
        echo "Result: WARNING"
        ((WARNINGS+=1))
    elif (( ERROR_COUNT >= CRITICAL_ERRORS )); then
        echo "Result: CRITICAL"
        ((CRITICAL+=1))
    elif (( ERROR_COUNT >= WARNING_ERRORS )); then
        echo "Result: WARNING"
        ((WARNINGS+=1))
    else
        echo "Result: OK"
        ((HEALTHY+=1))
    fi

    echo
done

echo "=========================================="
echo " SUMMARY"
echo "=========================================="
echo "Services checked: $CHECKED"
echo "Healthy: $HEALTHY"
echo "Warnings: $WARNINGS"
echo "Critical: $CRITICAL"

if (( CRITICAL > 0 )); then
    echo "Overall status: CRITICAL"
    exit 2
elif (( WARNINGS > 0 )); then
    echo "Overall status: WARNING"
    exit 1
else
    echo "Overall status: OK"
    exit 0
fi
