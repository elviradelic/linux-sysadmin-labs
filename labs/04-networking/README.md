# Lab 04 — Linux Networking and Troubleshooting

This lab covers practical Linux networking and troubleshooting on Ubuntu Server.

The exercises focus on inspecting network interfaces, understanding routing, testing DNS resolution, identifying listening ports, and diagnosing TCP connectivity problems.

## Environment

- Ubuntu Server
- Oracle VirtualBox (NAT networking)
- SSH remote administration
- Bash
- iproute2, systemd-resolved, ping and coreutils

## Network Configuration

The following commands were used to inspect the server's network configuration:

```bash
ip -br addr
ip -br link
ip route
ip route get 1.1.1.1
```

The lab environment uses a VirtualBox NAT network with a private IPv4 address and a default gateway.

## DNS Troubleshooting

DNS configuration and name resolution were inspected using:

```bash
resolvectl status
resolvectl query github.com
getent ahostsv4 github.com
```

A deliberately invalid domain was used to observe DNS lookup failures:

```bash
resolvectl query nonexistent-host.invalid
```

## TCP and Port Diagnostics

Listening ports and established connections were inspected using:

```bash
sudo ss -tulnp
ss -tn state established
sudo ss -tlnp '( sport = :22 )'
```

Local TCP connectivity was tested against an available SSH port and an unused port.

These exercises demonstrated the difference between listening sockets, established connections, and failed TCP connection attempts.

## Network Diagnostics Script

The project includes a Bash diagnostic utility:

`scripts/network-diagnostics.sh`

It performs the following checks:

- Displays network interfaces and assigned addresses
- Checks for a default IPv4 route
- Resolves target hostnames or recognizes IPv4 addresses
- Tests ICMP connectivity
- Tests TCP connectivity to a specified port
- Reports PASS, WARNING and FAIL results
- Returns exit codes suitable for automation
- Supports saving diagnostic output to a file

### Usage

```bash
./scripts/network-diagnostics.sh --host github.com --port 443
```

Test the local SSH server:

```bash
./scripts/network-diagnostics.sh --host 127.0.0.1 --port 22
```

Test a closed port:

```bash
./scripts/network-diagnostics.sh --host 127.0.0.1 --port 65000
```

Save a report:

```bash
./scripts/network-diagnostics.sh \
  --host github.com \
  --port 443 \
  --output reports/network-diagnostics.log
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All checks passed |
| 1 | One or more warnings, no failures |
| 2 | At least one failed check or invalid arguments |

## Automated Tests

The repository includes:

`tests/test-network-diagnostics.sh`

Run the test suite:

```bash
./tests/test-network-diagnostics.sh
```

The tests cover:

- Successful local SSH connectivity
- Failed connection to an unused TCP port
- Invalid TCP port validation
- Missing hostname argument
- Unknown command-line options

The initial test run completed with five passing tests and zero failures.

## Troubleshooting Approach

The lab follows a structured diagnostic process:

1. Check network interface status and IP addresses.
2. Inspect the routing table.
3. Verify DNS resolution.
4. Check whether the target service is listening.
5. Test connectivity to the required TCP port.
6. Interpret results before changing system configuration.

## Limitations

- ICMP responses may be blocked even when TCP connectivity works.
- A successful TCP connection does not guarantee that the application is healthy.
- The utility primarily targets IPv4 connectivity.
- A default gateway is not required for local loopback communication.
- Tests assume the local SSH service is available on port 22.
- The utility does not modify firewall, DNS, routing or network interface settings.

## Outcome

This lab demonstrates Linux networking fundamentals, practical troubleshooting, Bash scripting, argument validation, automated testing, and diagnostic reporting.
