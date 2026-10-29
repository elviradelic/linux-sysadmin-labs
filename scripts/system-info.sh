#!/bin/bash

# Linux System Information Script
# Displays basic system information for administration.

echo "================================="
echo "       LINUX SYSTEM INFO"
echo "================================="

echo
echo "Hostname:"
hostname

echo
echo "Operating System:"
grep PRETTY_NAME /etc/os-release

echo
echo "Current User:"
whoami

echo
echo "System Uptime:"
uptime -p

echo
echo "CPU Information:"
lscpu | grep -E "Architecture:|CPU\(s\):|Model name:"

echo
echo "Memory Usage:"
free -h

echo
echo "Disk Usage:"
df -h /

echo
echo "IP Addresses:"
hostname -I

echo
echo "================================="
echo "System information collected."
