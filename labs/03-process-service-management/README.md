# Lab 03 — Linux Process and Service Management

This lab focuses on Linux process management, systemd service administration, and automated service monitoring on Ubuntu Server.

The practical work includes inspecting running processes, managing process priorities, analyzing system logs, and implementing a Bash-based monitoring tool with scheduled execution.

## Environment

- Ubuntu Server
- Oracle VirtualBox
- SSH remote administration
- Bash
- systemd and journalctl

## Process Management

The following commands were used to inspect and manage Linux processes:

```bash
ps aux
ps -ef
top
jobs -l
kill
```

A background process was created using:

```bash
sleep 300 &
```

Its PID and PPID were inspected, and the process was terminated using SIGTERM.

Process scheduling priorities were also explored using `nice` and `renice`.

## Service Management

The SSH service was inspected using:

```bash
systemctl status ssh
systemctl is-active ssh
systemctl is-enabled ssh
```

System logs were examined using:

```bash
journalctl -u ssh --no-pager
```

These commands help identify service failures, inspect runtime states, and troubleshoot startup problems.

## Linux Service Health Monitor

The lab includes a Bash monitoring tool located at:

`scripts/service-health-check.sh`

The tool supports:

- Monitoring multiple systemd services
- Detecting inactive or missing services
- Inspecting main process IDs
- Reporting CPU and memory usage
- Counting recent error-level journal entries
- Generating timestamped reports through systemd
- Returning exit codes for automation

### Manual execution

```bash
./scripts/service-health-check.sh --services ssh cron
```

### Generate a report

```bash
./scripts/service-health-check.sh \
  --services ssh cron \
  --output reports/service-health.log
```

### Check a missing service

```bash
./scripts/service-health-check.sh \
  --services ssh nonexistent-service
```

The monitor uses the following exit codes:

| Exit code | Meaning |
|-----------|---------|
| 0 | All checked services passed |
| 1 | At least one warning |
| 2 | Critical finding or invalid invocation |

## Automated Monitoring with systemd

The monitoring tool can be executed automatically using a systemd service and timer.

Configuration files:

- `systemd/service-health-monitor.service`
- `systemd/service-health-monitor.timer`

The service runs the monitoring script as a non-root user.

The timer schedules recurring executions approximately every five minutes.

### Installation

The example service configuration uses the `sysadmin` account and `/home/sysadmin/linux-sysadmin-labs`. Adjust these paths for another environment.

```bash
sudo cp systemd/service-health-monitor.service /etc/systemd/system/
sudo cp systemd/service-health-monitor.timer /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable --now service-health-monitor.timer
```

### Verify the timer

```bash
systemctl status service-health-monitor.timer
systemctl list-timers --all
```

### Inspect execution logs

```bash
journalctl -u service-health-monitor.service --no-pager
```

### Disable automated monitoring

```bash
sudo systemctl disable --now service-health-monitor.timer
```

## Monitoring Reports

Each scheduled execution generates a timestamped report in the `reports/` directory.

Example:

```text
service-health-20261031-224242.log
```

Reports are excluded from Git because they contain environment-specific monitoring data.

## Notes and Limitations

CPU and memory statistics are collected from the main service process and do not represent all processes belonging to the service.

Recent errors are determined from journal entries with error priority. Journal access permissions may affect the results.

An active systemd service is not necessarily proof that its application is fully operational.

The monitoring tool does not automatically restart services or modify system configuration.

## Outcome

This lab demonstrates practical experience with Linux process management, systemd service administration, log inspection, Bash automation, and scheduled monitoring.
