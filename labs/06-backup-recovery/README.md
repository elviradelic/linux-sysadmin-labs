
# Lab 06 — Backup and Recovery

## Overview

This lab covers Linux backup and recovery operations using Bash, tar, and SHA-256 checksums.

The goal was to build a reusable backup utility that can create compressed archives, verify their integrity, and restore files when needed.

## Environment

- Ubuntu Server
- Bash
- GNU tar
- SHA-256 checksum utilities
- VirtualBox

## Implementation

The `scripts/backup-manager.sh` utility supports three operations:

- `backup` — creates a timestamped `.tar.gz` archive and SHA-256 checksum file.
- `verify` — checks the archive checksum and verifies that its structure is readable.
- `restore` — verifies the archive before extracting its contents.

Backup archives are stored outside the repository during testing.

## Usage

Run these commands from the repository root.

### Create a backup

```bash
./scripts/backup-manager.sh backup labs/06-backup-recovery/sample-data /tmp/linux-backups
```

### Verify a backup

```bash
./scripts/backup-manager.sh verify /path/to/backup.tar.gz
```

### Restore a backup

```bash
./scripts/backup-manager.sh restore /path/to/backup.tar.gz /tmp/linux-restored
```

## Automated Testing

The test suite is located at:

`tests/test-backup-manager.sh`

Run it using:

```bash
./tests/test-backup-manager.sh
```

The tests cover:

1. Backup archive creation
2. SHA-256 checksum file creation
3. Archive integrity verification
4. Restoration and comparison of original files
5. Rejection of a missing archive
6. Detection of a corrupted archive

Latest test result:

- Passed: 6
- Failed: 0

## Key Takeaways

- Backups should be verified rather than assumed to be valid.
- SHA-256 checksums help detect accidental or unauthorized changes to archive contents.
- Recovery testing confirms that archived data can actually be restored.
- Automated tests make backup operations easier to validate after future code changes.

## Limitations

This is a learning and portfolio project, not a production backup system.

Production use would require additional safeguards, including scheduled backups, retention policies, off-site storage, access controls, and stronger validation of archive contents before extraction.
