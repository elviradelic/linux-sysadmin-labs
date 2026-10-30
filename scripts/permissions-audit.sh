#!/bin/bash

# Linux File Permissions Security Audit
# Checks files and directories for potential security risks.

TARGET="${1:-.}"

if [ ! -d "$TARGET" ]; then
    echo "Error: Directory does not exist: $TARGET"
    exit 1
fi

echo "=========================================="
echo " Linux File Permissions Security Audit"
echo "=========================================="
echo "Target: $TARGET"
echo "Date: $(date)"
echo

# 1. World-writable files

echo "[1] World-writable files"
echo "------------------------------------------"

WORLD_WRITABLE=$(find "$TARGET" -type f -perm -0002 -print)

if [ -n "$WORLD_WRITABLE" ]; then
    printf '%s\n' "$WORLD_WRITABLE"
else
    echo "No world-writable files found."
fi

WORLD_WRITABLE_COUNT=$(find "$TARGET" -type f -perm -0002 -printf '.' | wc -c)

echo

# 2. SUID files

echo "[2] SUID files"
echo "------------------------------------------"

SUID_FILES=$(find "$TARGET" -type f -perm -4000 -print)

if [ -n "$SUID_FILES" ]; then
    printf '%s\n' "$SUID_FILES"
else
    echo "No SUID files found."
fi

SUID_COUNT=$(find "$TARGET" -type f -perm -4000 -printf '.' | wc -c)

echo

# 3. SGID files

echo "[3] SGID files"
echo "------------------------------------------"

SGID_FILES=$(find "$TARGET" -type f -perm -2000 -print)

if [ -n "$SGID_FILES" ]; then
    printf '%s\n' "$SGID_FILES"
else
    echo "No SGID files found."
fi

SGID_COUNT=$(find "$TARGET" -type f -perm -2000 -printf '.' | wc -c)

echo

# 4. Files without valid owners

echo "[4] Files without valid owners"
echo "------------------------------------------"

ORPHAN_FILES=$(find "$TARGET" -type f \( -nouser -o -nogroup \) -print)

if [ -n "$ORPHAN_FILES" ]; then
    printf '%s\n' "$ORPHAN_FILES"
else
    echo "No orphaned files found."
fi

ORPHAN_COUNT=$(find "$TARGET" -type f \( -nouser -o -nogroup \) -printf '.' | wc -c)

echo

# 5. Security audit summary

TOTAL_FINDINGS=$((WORLD_WRITABLE_COUNT + SUID_COUNT + SGID_COUNT + ORPHAN_COUNT))

echo "=========================================="
echo " Security Audit Summary"
echo "=========================================="

echo "World-writable files: $WORLD_WRITABLE_COUNT"
echo "SUID files: $SUID_COUNT"
echo "SGID files: $SGID_COUNT"
echo "Orphaned files: $ORPHAN_COUNT"

echo "------------------------------------------"
echo "Total findings: $TOTAL_FINDINGS"

if [ "$TOTAL_FINDINGS" -gt 0 ]; then
    echo "Status: REVIEW REQUIRED"
else
    echo "Status: PASS"
fi

echo
echo "Security audit completed."
