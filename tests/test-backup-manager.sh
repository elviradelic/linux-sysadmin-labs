
#!/usr/bin/env bash

set -u

SCRIPT="./scripts/backup-manager.sh"
TEST_DIR=$(mktemp -d)
SOURCE="$TEST_DIR/source"
BACKUPS="$TEST_DIR/backups"
RESTORED="$TEST_DIR/restored"

PASSED=0
FAILED=0

cleanup() {
    rm -rf -- "$TEST_DIR"
}

trap cleanup EXIT

check() {
    local name="$1"
    shift

    if "$@"; then
        echo "[PASS] $name"
        PASSED=$((PASSED + 1))
    else
        echo "[FAIL] $name"
        FAILED=$((FAILED + 1))
    fi
}

echo "========================================"
echo " BACKUP MANAGER TEST SUITE"
echo "========================================"

mkdir -p "$SOURCE" "$BACKUPS"
printf 'Test configuration\n' > "$SOURCE/app.conf"
printf 'Database settings\n' > "$SOURCE/database.conf"

echo
echo "[1] Backup creation"

if "$SCRIPT" backup "$SOURCE" "$BACKUPS"; then
    ARCHIVE=$(find "$BACKUPS" -maxdepth 1 -type f \
        -name '*.tar.gz' -print -quit)
else
    ARCHIVE=""
fi

check "Backup archive created" test -f "$ARCHIVE"
check "SHA-256 file created" test -f "$ARCHIVE.sha256"

echo
echo "[2] Archive verification"

check "Archive integrity" "$SCRIPT" verify "$ARCHIVE"

echo
echo "[3] Restore operation"

if "$SCRIPT" restore "$ARCHIVE" "$RESTORED"; then
    check "Restored files match original" \
        diff -r "$SOURCE" "$RESTORED/source"
else
    echo "[FAIL] Restore operation"
    FAILED=$((FAILED + 1))
fi

echo
echo "[4] Invalid input"

if "$SCRIPT" verify "$TEST_DIR/missing.tar.gz" >/dev/null 2>&1; then
    echo "[FAIL] Missing archive rejected"
    FAILED=$((FAILED + 1))
else
    echo "[PASS] Missing archive rejected"
    PASSED=$((PASSED + 1))
fi


echo
echo "[5] Corrupted archive detection"

if [ -f "$ARCHIVE" ]; then
    printf 'CORRUPTED DATA\n' >> "$ARCHIVE"

    if "$SCRIPT" verify "$ARCHIVE" >/dev/null 2>&1; then
        echo "[FAIL] Corrupted archive rejected"
        FAILED=$((FAILED + 1))
    else
        echo "[PASS] Corrupted archive rejected"
        PASSED=$((PASSED + 1))
    fi
else
    echo "[FAIL] Corrupted archive test could not run"
    FAILED=$((FAILED + 1))
fi


echo
echo "========================================"
echo " TEST SUMMARY"
echo "========================================"
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [ "$FAILED" -eq 0 ]; then
    echo "All tests passed."
    exit 0
else
    exit 1
fi
