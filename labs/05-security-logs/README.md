


# Lab 05 — Linux Security Log Analysis

## Overview

This lab focuses on analyzing SSH authentication events on an Ubuntu Server using systemd journal logs and Bash.

The goal was to build a small command-line tool for reviewing SSH login activity, identifying repeated authentication failures, and generating a readable security summary.

## Implementation

The `security-log-audit.sh` script supports two input sources:

- Live SSH authentication logs collected with `journalctl`.
- Local log files used for reproducible testing.

The script reports:

- Successful SSH logins.
- Failed SSH login attempts.
- Failed attempts grouped by source IP address.
- A configurable threshold for reviewing authentication failures.
- Input validation and error messages.

The tool only reads log data and does not modify SSH settings, firewall rules, or user accounts.

## Usage

Run the audit against the SSH journal:

```bash
sudo ./scripts/security-log-audit.sh --since "1 hour ago"
```

Set a custom failure threshold:

```bash
sudo ./scripts/security-log-audit.sh --since "24 hours ago" --threshold 5
```

Analyze a saved log file:

```bash
./scripts/security-log-audit.sh --file tests/fixtures/ssh-auth.log --threshold 3
```

## Automated Testing

A separate Bash test suite validates the analyzer using synthetic SSH authentication events.

Run the tests from the repository root:

```bash
./tests/test-security-log-audit.sh
```

The test suite covers nine scenarios, including authentication counts, threshold handling, source IP grouping, missing files, and invalid arguments.

## Security Notes

The threshold currently applies to the total number of failed SSH logins within the selected input, not separately to each source IP address.

A `REVIEW REQUIRED` result indicates that the configured threshold has been reached. It does not automatically indicate a security incident.

The included fixture uses documentation-only IP addresses and contains no real credentials or private authentication logs.

## Outcome

Implemented and tested a read-only SSH log analyzer using Bash, `journalctl`, `grep`, `awk`, `sort`, and `uniq`.

The lab demonstrates practical Linux log inspection, shell scripting, input validation, and automated testing.





