
#!/usr/bin/env bash

# Linux Backup & Recovery Manager
# Creates, verifies, and restores compressed backups.

set -euo pipefail

usage() {
    cat <<'EOF'
Linux Backup & Recovery Manager

Usage:
  backup-manager.sh backup SOURCE DESTINATION
  backup-manager.sh verify ARCHIVE
  backup-manager.sh restore ARCHIVE DESTINATION

Commands:
  backup    Create a compressed backup and SHA-256 checksum
  verify    Check archive integrity
  restore   Verify and extract an archive safely

Examples:
  ./scripts/backup-manager.sh backup labs/06-backup-recovery/sample-data /tmp/linux-backups
  ./scripts/backup-manager.sh verify /tmp/linux-backups/sample-data-YYYYMMDD-HHMMSS.tar.gz
  ./scripts/backup-manager.sh restore /tmp/linux-backups/sample-data-YYYYMMDD-HHMMSS.tar.gz /tmp/restored-data
EOF
}

error() {
    echo "ERROR: $*" >&2
    exit 1
}

require_archive() {
    local archive="$1"

    [[ -f "$archive" ]] || error "Archive does not exist: $archive"
    [[ -f "${archive}.sha256" ]] || error "Checksum file does not exist: ${archive}.sha256"
}

verify_archive() {
    local archive="$1"
    local expected actual

    require_archive "$archive"

    expected=$(awk 'NR == 1 {print $1}' "${archive}.sha256")
    [[ "$expected" =~ ^[a-fA-F0-9]{64}$ ]] || error "Invalid SHA-256 checksum"

    actual=$(sha256sum "$archive" | awk '{print $1}')

    [[ "$actual" == "$expected" ]] || error "SHA-256 checksum mismatch"

    tar -tzf "$archive" >/dev/null || error "Archive validation failed"

    echo "[PASS] SHA-256 checksum verified"
    echo "[PASS] Archive structure readable"
}

backup_data() {
    local source="$1"
    local destination="$2"
    local source_abs parent base timestamp archive

    [[ -d "$source" ]] || error "Source directory does not exist: $source"

    source_abs=$(realpath "$source")
    parent=$(dirname "$source_abs")
    base=$(basename "$source_abs")

    mkdir -p "$destination"

    timestamp=$(date +%Y%m%d-%H%M%S)
    archive="${destination%/}/${base}-${timestamp}-$$.tar.gz"

    tar -czf "$archive" -C "$parent" "$base"

    sha256sum "$archive" | awk '{print $1}' > "${archive}.sha256"

    echo "[PASS] Backup created: $archive"
    echo "[PASS] Checksum created: ${archive}.sha256"
}

restore_data() {
    local archive="$1"
    local destination="$2"
    local member

    verify_archive "$archive"

    # Reject absolute paths, traversal components, and special entries.
    while IFS= read -r member; do
        [[ "$member" != /* ]] || error "Unsafe absolute path in archive"
        [[ ! "/$member" =~ /\.\.(/|$) ]] || error "Unsafe parent traversal in archive"
    done < <(tar -tzf "$archive")

    # Only allow regular files and directories in this lab.
    if tar -tvzf "$archive" | grep -Eq '^[^d-]'; then
        error "Archive contains unsupported entry types"
    fi

    mkdir -p "$destination"

    tar -xzf "$archive" -C "$destination" \
        --no-same-owner --no-same-permissions

    echo "[PASS] Restore completed: $destination"
}

[[ $# -ge 1 ]] || {
    usage
    exit 2
}

command="$1"
shift

case "$command" in
    backup)
        [[ $# -eq 2 ]] || error "Usage: backup SOURCE DESTINATION"
        backup_data "$1" "$2"
        ;;
    verify)
        [[ $# -eq 1 ]] || error "Usage: verify ARCHIVE"
        verify_archive "$1"
        ;;
    restore)
        [[ $# -eq 2 ]] || error "Usage: restore ARCHIVE DESTINATION"
        restore_data "$1" "$2"
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        error "Unknown command: $command"
        ;;
esac
