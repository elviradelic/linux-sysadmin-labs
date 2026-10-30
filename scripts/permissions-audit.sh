#!/bin/bash

# Linux File Permissions Audit
# Displays ownership and permissions for files and directories.

TARGET="${1:-.}"

if [ ! -e "$TARGET" ]; then
    echo "Error: Target does not exist: $TARGET"
    exit 1
fi

echo "=================================="
echo " Linux File Permissions Audit"
echo "=================================="

echo "Target: $TARGET"
echo "Date: $(date)"
echo

echo "File details:"
stat -c "Name: %n
Type: %F
Owner: %U
Group: %G
Permissions: %A
Numeric permissions: %a" "$TARGET"

echo
echo "Audit completed."
