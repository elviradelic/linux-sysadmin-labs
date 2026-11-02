#!/usr/bin/env bash

# Linux Network Diagnostics
# Read-only network troubleshooting utility.

set -u

HOST="github.com"
PORT=443
OUTPUT=""
TIMEOUT=3

usage() {
    cat <<EOF
Linux Network Diagnostics

Usage:
  $0 [OPTIONS]

Options:
  --host HOST       Target hostname or IPv4 address
  --port PORT       TCP port (default: 443)
  --output FILE     Save report to a file
  --help            Show help

Examples:
  $0
  $0 --host github.com --port 443
  $0 --host 127.0.0.1 --port 22
  $0 --host github.com --output reports/network.log
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --host)
            if [[ $# -lt 2 || -z "$2" || "$2" == --* ]]; then
                echo "ERROR: --host requires a value." >&2
                exit 2
            fi
            HOST="$2"
            shift 2
            ;;
        --port)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --port requires a value." >&2
                exit 2
            fi
            PORT="$2"
            shift 2
            ;;
        --output)
            if [[ $# -lt 2 || -z "$2" || "$2" == --* ]]; then
                echo "ERROR: --output requires a path." >&2
                exit 2
            fi
            OUTPUT="$2"
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

if ! [[ "$PORT" =~ ^[0-9]+$ ]] ||
   (( ${#PORT} > 5 )); then
    echo "ERROR: Invalid TCP port." >&2
    exit 2
fi

PORT=$((10#$PORT))

if (( PORT < 1 || PORT > 65535 )); then
    echo "ERROR: Port must be between 1 and 65535." >&2
    exit 2
fi

for cmd in ip getent ping timeout; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: Missing command: $cmd" >&2
        exit 2
    fi
done

if [[ -n "$OUTPUT" ]]; then
    mkdir -p "$(dirname "$OUTPUT")" || exit 2
    touch "$OUTPUT" || exit 2
    exec > >(tee "$OUTPUT")
fi

PASS=0
WARNING=0
FAIL=0

pass() {
    echo "[PASS] $1"
    ((PASS+=1))
}

warn() {
    echo "[WARNING] $1"
    ((WARNING+=1))
}

fail() {
    echo "[FAIL] $1"
    ((FAIL+=1))
}

is_ipv4() {
    local address="$1"
    local octet

    [[ "$address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1

    local IFS=.
    read -r -a octets <<< "$address"

    for octet in "${octets[@]}"; do
        [[ ${#octet} -le 3 ]] || return 1
        (( 10#$octet <= 255 )) || return 1
    done
}

echo "=========================================="
echo "       LINUX NETWORK DIAGNOSTICS"
echo "=========================================="
echo "Server: $(hostname)"
echo "Date: $(date)"
echo "Target: $HOST"
echo "TCP port: $PORT"
echo

echo "[1] Network Interfaces"
echo "------------------------------------------"
ip -br addr
echo

echo "[2] Default Gateway"
echo "------------------------------------------"

GATEWAY=$(ip -4 route show default | head -n 1)

if [[ -n "$GATEWAY" ]]; then
    echo "$GATEWAY"
    pass "Default IPv4 route exists"
else
    warn "No default IPv4 route configured"
fi

echo

echo "[3] DNS Resolution"
echo "------------------------------------------"

if is_ipv4 "$HOST"; then
    echo "Target is an IPv4 address."
    pass "DNS lookup not required"
else
    DNS_RESULT=$(getent ahostsv4 "$HOST" 2>/dev/null | head -n 1)

    if [[ -n "$DNS_RESULT" ]]; then
        echo "$DNS_RESULT"
        pass "DNS resolution successful"
    else
        fail "DNS resolution failed"
    fi
fi

echo

echo "[4] ICMP Connectivity"
echo "------------------------------------------"

if ping -c 2 -W "$TIMEOUT" "$HOST" >/dev/null 2>&1; then
    pass "ICMP response received"
else
    warn "No ICMP response received"
fi

echo

echo "[5] TCP Connectivity"
echo "------------------------------------------"

if timeout "$TIMEOUT" bash -c \
    'echo > /dev/tcp/"$1"/"$2"' _ "$HOST" "$PORT" \
    >/dev/null 2>&1; then
    pass "TCP connection to $HOST:$PORT succeeded"
else
    fail "TCP connection to $HOST:$PORT failed"
fi

echo

echo "=========================================="
echo " DIAGNOSTIC SUMMARY"
echo "=========================================="
echo "Passed: $PASS"
echo "Warnings: $WARNING"
echo "Failed: $FAIL"

if (( FAIL > 0 )); then
    echo "Overall status: FAIL"
    exit 2
elif (( WARNING > 0 )); then
    echo "Overall status: WARNING"
    exit 1
else
    echo "Overall status: PASS"
    exit 0
fi
