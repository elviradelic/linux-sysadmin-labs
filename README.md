
# Linux Sysadmin Labs

Hands-on Linux system administration labs using Ubuntu Server 24.04 LTS running in Oracle VirtualBox.

## Environment

- OS: Ubuntu Server 24.04 LTS
- Virtualization: Oracle VirtualBox
- Remote Access: OpenSSH
- Version Control: Git and GitHub
- Scripting: Bash

## Project Structure

- `scripts/` - Bash automation scripts
- `labs/01-system-information/` - System inspection and resource monitoring
- `labs/02-user-management/` - Linux users, groups and sudo permissions
- `labs/03-ssh-configuration/` - SSH configuration and remote access

## Implemented

### System Information Script

Created a Bash script to collect:

- Hostname and operating system
- Current user and system uptime
- CPU architecture and processor information
- RAM and swap usage
- Disk utilization
- Network IP addresses

Run:

```bash
chmod +x scripts/system-info.sh
./scripts/system-info.sh
```

## Learning Goals

Build practical Linux administration skills, including user management, permissions, services, networking, security, monitoring and Bash automation.

This repository documents hands-on exercises and incremental improvements.
