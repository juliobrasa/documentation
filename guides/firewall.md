# Firewall Setup Guide

Comprehensive guide for configuring and managing firewall rules for the Hosting Management Platform using firewalld and iptables.

## Table of Contents
1. [Overview](#overview)
2. [Firewall Basics](#firewall-basics)
3. [firewalld Installation](#firewalld-installation)
4. [Basic Configuration](#basic-configuration)
5. [Service Management](#service-management)
6. [Port Management](#port-management)
7. [Rich Rules](#rich-rules)
8. [Zone Management](#zone-management)
9. [Advanced Configuration](#advanced-configuration)
10. [Rate Limiting and DDoS Protection](#rate-limiting-and-ddos-protection)
11. [Troubleshooting](#troubleshooting)
12. [Best Practices](#best-practices)

## Overview

Firewall configuration is critical for securing your hosting infrastructure. This guide covers comprehensive firewall setup using firewalld, the default firewall management tool for CentOS/RHEL 7 and later.

### Why Firewall is Important
- **Network Security**: Control incoming/outgoing traffic
- **Attack Prevention**: Block malicious traffic
- **Service Protection**: Restrict access to specific services
- **Compliance**: Meet security requirements
- **Access Control**: Manage who can access services

### What You'll Learn
- Install and configure firewalld
- Manage services and ports
- Create advanced firewall rules
- Implement DDoS protection
- Troubleshoot firewall issues

## Firewall Basics

### Understanding Firewall Concepts

#### Packet Filtering
- Examines network packets
- Allows or blocks based on rules
- Stateful vs stateless filtering

#### Firewall Components
- **Zones**: Predefined trust levels
- **Services**: Predefined port/protocol combinations
- **Ports**: TCP/UDP port numbers
- **Rich Rules**: Advanced rule syntax
- **Direct Rules**: Low-level iptables rules

### firewalld vs iptables

#### firewalld (Recommended)
```bash
# Modern, dynamic firewall
# Runtime and permanent configuration
# Zone-based management
# D-Bus interface
# No service restart required
```

#### iptables (Legacy)
```bash
# Traditional Linux firewall
# Requires rules reload for changes
# More complex syntax
# Still available as backend
```

### Firewall Zones

#### Pre-defined Zones (from least to most trusted)
```bash
drop        # Drop all incoming, only outgoing allowed
block       # Reject all incoming with icmp-host-prohibited
public      # Default zone, allow selected services
external    # NAT masquerading, allow selected services
dmz         # DMZ zone, limited access
work        # Work environment, trust most computers
home        # Home environment, trust most services
internal    # Internal network, trust all computers
trusted     # Trust all network traffic
```

## firewalld Installation

### Check Installation Status
```bash
# Check if firewalld is installed
rpm -qa | grep firewalld

# Check service status
systemctl status firewalld

# Check version
firewall-cmd --version
```

### Install firewalld
```bash
# Install firewalld
sudo yum install -y firewalld

# Start firewalld
sudo systemctl start firewalld

# Enable firewalld at boot
sudo systemctl enable firewalld

# Verify status
sudo systemctl status firewalld
```

### Disable iptables (if running)
```bash
# Check iptables status
sudo systemctl status iptables

# Stop and disable iptables
sudo systemctl stop iptables
sudo systemctl disable iptables

# Or mask it
sudo systemctl mask iptables
```

## Basic Configuration

### Initial Setup

#### Check Current Configuration
```bash
# Get default zone
sudo firewall-cmd --get-default-zone

# List all zones
sudo firewall-cmd --get-zones

# Get active zones
sudo firewall-cmd --get-active-zones

# List all configured rules
sudo firewall-cmd --list-all

# List all zones with rules
sudo firewall-cmd --list-all-zones
```

#### Set Default Zone
```bash
# Set default zone to public
sudo firewall-cmd --set-default-zone=public

# Verify
sudo firewall-cmd --get-default-zone
```

#### Essential Services Configuration
```bash
# Add essential services
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

# Reload firewall
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-services
```

### Runtime vs Permanent Configuration

#### Runtime Configuration (Temporary)
```bash
# Add service temporarily (lost on reload/reboot)
sudo firewall-cmd --add-service=http

# Remove service temporarily
sudo firewall-cmd --remove-service=http
```

#### Permanent Configuration
```bash
# Add service permanently
sudo firewall-cmd --permanent --add-service=http

# Must reload after permanent changes
sudo firewall-cmd --reload

# Or apply both runtime and permanent
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --add-service=http
```

## Service Management

### Pre-defined Services

#### List Available Services
```bash
# List all available services
sudo firewall-cmd --get-services

# Show service definition
sudo firewall-cmd --info-service=ssh
sudo firewall-cmd --info-service=http
```

#### Add Services
```bash
# Add common web services
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

# Add SSH (if not already added)
sudo firewall-cmd --permanent --add-service=ssh

# Add database services (only if remote access needed)
sudo firewall-cmd --permanent --add-service=mysql
# Or
sudo firewall-cmd --permanent --add-service=postgresql

# Add mail services
sudo firewall-cmd --permanent --add-service=smtp
sudo firewall-cmd --permanent --add-service=smtps

# Reload
sudo firewall-cmd --reload
```

#### Remove Services
```bash
# Remove service
sudo firewall-cmd --permanent --remove-service=dhcpv6-client
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-services
```

### Custom Service Definitions

#### Create Custom Service
```bash
# Create custom service file
sudo nano /etc/firewalld/services/custom-app.xml
```

```xml
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>Custom Application</short>
  <description>Custom application service for hosting platform</description>
  <port protocol="tcp" port="8090"/>
  <port protocol="tcp" port="8091"/>
</service>
```

```bash
# Reload firewalld to read new service
sudo firewall-cmd --reload

# Add custom service
sudo firewall-cmd --permanent --add-service=custom-app
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --info-service=custom-app
```

## Port Management

### Add Ports

#### Single Port
```bash
# Add single TCP port
sudo firewall-cmd --permanent --add-port=8080/tcp

# Add single UDP port
sudo firewall-cmd --permanent --add-port=53/udp

# Add both TCP and UDP
sudo firewall-cmd --permanent --add-port=8090/tcp
sudo firewall-cmd --permanent --add-port=8090/udp

# Reload
sudo firewall-cmd --reload
```

#### Port Ranges
```bash
# Add port range
sudo firewall-cmd --permanent --add-port=8000-8100/tcp
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-ports
```

#### Common Ports for Hosting Platform
```bash
# SSH (custom port if changed from 22)
sudo firewall-cmd --permanent --add-port=2222/tcp

# Web servers
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

# Application ports (if needed)
sudo firewall-cmd --permanent --add-port=8090/tcp

# Control panel ports (if needed)
sudo firewall-cmd --permanent --add-port=2086/tcp  # cPanel
sudo firewall-cmd --permanent --add-port=2087/tcp  # WHM

# Reload
sudo firewall-cmd --reload
```

### Remove Ports

```bash
# Remove port
sudo firewall-cmd --permanent --remove-port=8080/tcp
sudo firewall-cmd --reload

# Remove port range
sudo firewall-cmd --permanent --remove-port=8000-8100/tcp
sudo firewall-cmd --reload
```

### List Ports

```bash
# List all open ports
sudo firewall-cmd --list-ports

# List all (services and ports)
sudo firewall-cmd --list-all
```

## Rich Rules

Rich rules provide advanced firewall rule syntax for complex scenarios.

### Rich Rule Syntax

#### Basic Structure
```bash
rule family="ipv4|ipv6"
  [source [address="address[/mask]"] [invert="bool"]]
  [destination [address="address[/mask]"] [invert="bool"]]
  [service name="service name"]
  [port port="port value" protocol="tcp|udp"]
  [forward-port port="port value" protocol="tcp|udp" to-port="port value" to-addr="address"]
  [icmp-block name="icmptype name"]
  [masquerade]
  [log [prefix="prefix text"] [level="log level"] [limit value="rate/duration"]]
  [audit]
  [accept|reject|drop]
```

### Allow from Specific IP

```bash
# Allow SSH from specific IP
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="192.168.1.100"
  service name="ssh"
  accept'

# Allow HTTP from IP range
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="10.0.0.0/24"
  service name="http"
  accept'

# Reload
sudo firewall-cmd --reload
```

### Block Specific IP

```bash
# Block all traffic from IP
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="192.168.1.50"
  reject'

# Block IP range
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="10.0.1.0/24"
  drop'

# Reload
sudo firewall-cmd --reload
```

### Port Restrictions

```bash
# Allow port 3306 only from specific IP (database access)
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="192.168.1.100"
  port port="3306" protocol="tcp"
  accept'

# Allow SSH only from office network
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="203.0.113.0/24"
  service name="ssh"
  accept'

# Remove default SSH service if using rich rule
sudo firewall-cmd --permanent --remove-service=ssh

# Reload
sudo firewall-cmd --reload
```

### Rate Limiting

```bash
# Limit SSH connections (5 per minute from same IP)
sudo firewall-cmd --permanent --add-rich-rule='
  rule service name="ssh"
  limit value="5/m"
  accept'

# Limit HTTP requests (100 per minute)
sudo firewall-cmd --permanent --add-rich-rule='
  rule service name="http"
  limit value="100/m"
  accept'

# Reload
sudo firewall-cmd --reload
```

### Logging

```bash
# Log dropped packets
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  log prefix="FIREWALL-DROP: " level="info" limit value="5/m"
  drop'

# Log SSH connections
sudo firewall-cmd --permanent --add-rich-rule='
  rule service name="ssh"
  log prefix="SSH-CONNECTION: " level="info" limit value="3/m"
  accept'

# View logs
sudo journalctl -f | grep FIREWALL
# Or
sudo tail -f /var/log/messages | grep FIREWALL
```

### Remove Rich Rules

```bash
# List rich rules
sudo firewall-cmd --list-rich-rules

# Remove specific rich rule
sudo firewall-cmd --permanent --remove-rich-rule='
  rule family="ipv4"
  source address="192.168.1.50"
  reject'

# Reload
sudo firewall-cmd --reload
```

## Zone Management

### Working with Zones

#### Assign Interface to Zone
```bash
# List network interfaces
ip link show

# Assign interface to zone
sudo firewall-cmd --permanent --zone=public --add-interface=eth0

# Verify
sudo firewall-cmd --get-active-zones

# Change interface zone
sudo firewall-cmd --permanent --zone=internal --change-interface=eth0
sudo firewall-cmd --reload
```

#### Configure Zone Rules

```bash
# Add service to specific zone
sudo firewall-cmd --permanent --zone=public --add-service=http

# Add port to specific zone
sudo firewall-cmd --permanent --zone=public --add-port=8080/tcp

# Add rich rule to specific zone
sudo firewall-cmd --permanent --zone=public --add-rich-rule='
  rule family="ipv4"
  source address="192.168.1.0/24"
  accept'

# Reload
sudo firewall-cmd --reload
```

#### Create Custom Zone

```bash
# Create new zone
sudo firewall-cmd --permanent --new-zone=dmz-web

# Configure zone
sudo firewall-cmd --permanent --zone=dmz-web --add-service=http
sudo firewall-cmd --permanent --zone=dmz-web --add-service=https

# Set target (default action)
sudo firewall-cmd --permanent --zone=dmz-web --set-target=DROP

# Reload
sudo firewall-cmd --reload

# Assign interface
sudo firewall-cmd --permanent --zone=dmz-web --add-interface=eth1
sudo firewall-cmd --reload
```

### Zone Configuration Examples

#### DMZ Zone for Web Servers
```bash
# Configure DMZ zone
sudo firewall-cmd --permanent --zone=dmz --set-target=DROP
sudo firewall-cmd --permanent --zone=dmz --add-service=http
sudo firewall-cmd --permanent --zone=dmz --add-service=https

# Allow SSH from specific management network
sudo firewall-cmd --permanent --zone=dmz --add-rich-rule='
  rule family="ipv4"
  source address="10.0.0.0/24"
  service name="ssh"
  accept'

sudo firewall-cmd --reload
```

#### Internal Zone for Database Servers
```bash
# Configure internal zone
sudo firewall-cmd --permanent --zone=internal --set-target=DROP

# Allow MySQL only from application servers
sudo firewall-cmd --permanent --zone=internal --add-rich-rule='
  rule family="ipv4"
  source address="192.168.1.10"
  port port="3306" protocol="tcp"
  accept'

sudo firewall-cmd --reload
```

## Advanced Configuration

### Port Forwarding

#### Forward Port to Different Port
```bash
# Forward external port 8080 to internal port 80
sudo firewall-cmd --permanent --add-forward-port=port=8080:proto=tcp:toport=80

# Forward to different host
sudo firewall-cmd --permanent --add-forward-port=port=8080:proto=tcp:toport=80:toaddr=192.168.1.10

# Reload
sudo firewall-cmd --reload
```

#### NAT and Masquerading
```bash
# Enable masquerading (NAT)
sudo firewall-cmd --permanent --add-masquerade

# Forward traffic to internal network
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="192.168.1.0/24"
  masquerade'

sudo firewall-cmd --reload
```

### ICMP Filtering

#### Block ICMP (Ping)
```bash
# Block all ICMP
sudo firewall-cmd --permanent --add-icmp-block-inversion
sudo firewall-cmd --permanent --add-icmp-block=echo-request

# Or block all ICMP types
sudo firewall-cmd --permanent --add-icmp-block={echo-reply,echo-request,timestamp-reply,timestamp-request}

# Reload
sudo firewall-cmd --reload
```

#### Allow ICMP from Specific Sources
```bash
# Allow ping from specific network
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="192.168.1.0/24"
  icmp-block name="echo-request" invert="True"
  accept'

sudo firewall-cmd --reload
```

### Direct Rules (iptables)

#### Add iptables Rule Directly
```bash
# Add custom iptables rule
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 \
  -p tcp --dport 8080 -j ACCEPT

# List direct rules
sudo firewall-cmd --direct --get-all-rules

# Remove direct rule
sudo firewall-cmd --permanent --direct --remove-rule ipv4 filter INPUT 0 \
  -p tcp --dport 8080 -j ACCEPT

# Reload
sudo firewall-cmd --reload
```

### Panic Mode

```bash
# Enable panic mode (block all traffic immediately)
sudo firewall-cmd --panic-on

# Disable panic mode
sudo firewall-cmd --panic-off

# Check panic status
sudo firewall-cmd --query-panic
```

## Rate Limiting and DDoS Protection

### Connection Limiting

#### Limit Connection Rate
```bash
# Limit SSH connection attempts
sudo firewall-cmd --permanent --add-rich-rule='
  rule service name="ssh"
  limit value="3/m"
  log prefix="SSH-RATE-LIMIT: " level="info"
  accept'

# Block excessive HTTP connections
sudo firewall-cmd --permanent --add-rich-rule='
  rule service name="http"
  limit value="100/m"
  log prefix="HTTP-RATE-LIMIT: " level="warning"
  reject'

sudo firewall-cmd --reload
```

### Block Known Bad IPs

```bash
# Create script to block malicious IPs
sudo nano /usr/local/bin/block_malicious_ips.sh
```

```bash
#!/bin/bash

# List of malicious IP ranges
MALICIOUS_IPS=(
    "185.220.100.0/24"
    "185.220.101.0/24"
    "192.42.116.0/24"
)

for IP in "${MALICIOUS_IPS[@]}"; do
    firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$IP' drop"
done

firewall-cmd --reload
echo "Malicious IPs blocked"
```

```bash
chmod +x /usr/local/bin/block_malicious_ips.sh
sudo /usr/local/bin/block_malicious_ips.sh
```

### Automated IP Blocking (Fail2Ban Integration)

```bash
# Install fail2ban
sudo yum install -y fail2ban

# Configure fail2ban with firewalld
sudo nano /etc/fail2ban/jail.local
```

```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
banaction = firewallcmd-ipset

[sshd]
enabled = true
port = 2222
logpath = /var/log/secure

[httpd-auth]
enabled = true
port = http,https
logpath = /var/log/httpd/error_log

[httpd-badbots]
enabled = true
port = http,https
logpath = /var/log/httpd/access_log
maxretry = 2
```

```bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### SYN Flood Protection

```bash
# Add SYN flood protection
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 \
  -p tcp --syn -m limit --limit 10/s --limit-burst 20 -j ACCEPT

sudo firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 1 \
  -p tcp --syn -j DROP

sudo firewall-cmd --reload
```

### Monitor Blocked Connections

```bash
# Create monitoring script
sudo nano /usr/local/bin/monitor_firewall.sh
```

```bash
#!/bin/bash

echo "=== Firewall Activity Monitor ==="
echo ""

# Show recent dropped packets
echo "Recently Dropped Connections:"
sudo journalctl -u firewalld -n 50 | grep -i "drop\|reject" | tail -20

echo ""
echo "=== Current Firewall Rules ==="
sudo firewall-cmd --list-all

echo ""
echo "=== Active Rich Rules ==="
sudo firewall-cmd --list-rich-rules

echo ""
echo "=== Connection Statistics ==="
ss -s
```

```bash
chmod +x /usr/local/bin/monitor_firewall.sh
```

## Troubleshooting

### Common Issues

#### Firewall Blocking Legitimate Traffic

**Problem**: Service not accessible after firewall configuration

**Check**:
```bash
# Check if service is allowed
sudo firewall-cmd --list-services
sudo firewall-cmd --list-ports

# Check rich rules
sudo firewall-cmd --list-rich-rules

# Check if interface is in correct zone
sudo firewall-cmd --get-active-zones
```

**Solution**:
```bash
# Add required service or port
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload

# Or temporarily disable to test
sudo systemctl stop firewalld
# Test service access
# If works, add proper firewall rule
sudo systemctl start firewalld
```

#### Configuration Not Persistent

**Problem**: Rules disappear after reboot

**Check**:
```bash
# Check if rule is permanent
sudo firewall-cmd --permanent --list-all
```

**Solution**:
```bash
# Always use --permanent flag
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload

# Or make runtime rules permanent
sudo firewall-cmd --runtime-to-permanent
```

#### Zone Configuration Issues

**Problem**: Interface in wrong zone

**Check**:
```bash
# Check active zones
sudo firewall-cmd --get-active-zones

# Check default zone
sudo firewall-cmd --get-default-zone
```

**Solution**:
```bash
# Assign interface to correct zone
sudo firewall-cmd --permanent --zone=public --change-interface=eth0
sudo firewall-cmd --reload
```

#### Service Start Failures

**Problem**: firewalld fails to start

**Check**:
```bash
# Check service status
sudo systemctl status firewalld -l

# Check logs
sudo journalctl -u firewalld -n 50

# Check configuration syntax
sudo firewall-cmd --check-config
```

**Solution**:
```bash
# Fix configuration errors
# Remove problematic rules
# Restore default configuration if needed
sudo rm -f /etc/firewalld/zones/*.xml
sudo systemctl restart firewalld
```

### Diagnostic Commands

```bash
# View all firewall rules
sudo firewall-cmd --list-all-zones

# Check specific zone
sudo firewall-cmd --zone=public --list-all

# View direct rules
sudo firewall-cmd --direct --get-all-rules

# Check service status
sudo systemctl status firewalld -l

# View firewall logs
sudo journalctl -u firewalld -f

# Test port connectivity
telnet yourdomain.com 80
nc -zv yourdomain.com 80

# Check listening ports
sudo netstat -tlnp
sudo ss -tlnp
```

### Reset Firewall Configuration

```bash
# Backup current configuration
sudo cp -r /etc/firewalld /etc/firewalld.backup

# Reset to defaults
sudo rm -f /etc/firewalld/zones/*.xml
sudo rm -f /etc/firewalld/services/*.xml

# Restart firewalld
sudo systemctl restart firewalld

# Reconfigure from scratch
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

## Best Practices

### Security Best Practices

#### 1. Principle of Least Privilege
```bash
# Only open necessary ports
# Close all other ports by default
sudo firewall-cmd --set-default-zone=drop
sudo firewall-cmd --permanent --zone=public --add-service=ssh
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --reload
```

#### 2. Use IP Whitelisting for Admin Access
```bash
# Allow SSH only from specific IPs
sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="203.0.113.0/24"
  service name="ssh"
  accept'
sudo firewall-cmd --reload
```

#### 3. Regular Monitoring
```bash
# Create monitoring cron job
echo "0 */6 * * * /usr/local/bin/monitor_firewall.sh > /var/log/firewall_monitor.log" | sudo tee -a /etc/crontab
```

#### 4. Change Default SSH Port
```bash
# After changing SSH port in sshd_config
sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --reload
```

#### 5. Enable Logging
```bash
# Log dropped packets
sudo firewall-cmd --permanent --set-log-denied=all
sudo firewall-cmd --reload

# View logs
sudo journalctl -f | grep -i drop
```

### Operational Best Practices

#### 1. Test Before Production
```bash
# Test in development environment first
# Use --timeout for temporary rules
sudo firewall-cmd --timeout=300 --add-service=http
# Rule expires in 5 minutes
```

#### 2. Document Changes
```bash
# Keep documentation of firewall rules
sudo firewall-cmd --list-all > /root/firewall-config-$(date +%Y%m%d).txt
```

#### 3. Regular Backups
```bash
# Backup firewall configuration
sudo tar -czf /backup/firewalld-$(date +%Y%m%d).tar.gz /etc/firewalld/
```

#### 4. Version Control
```bash
# Store configuration in git
cd /etc/firewalld
sudo git init
sudo git add .
sudo git commit -m "Initial firewall configuration"
```

#### 5. Regular Audits
```bash
# Create audit script
sudo nano /usr/local/bin/audit_firewall.sh
```

```bash
#!/bin/bash

echo "Firewall Audit Report - $(date)"
echo "================================"

echo -e "\nActive Zones:"
firewall-cmd --get-active-zones

echo -e "\nEnabled Services:"
firewall-cmd --list-services

echo -e "\nOpen Ports:"
firewall-cmd --list-ports

echo -e "\nRich Rules:"
firewall-cmd --list-rich-rules

echo -e "\nBlocked IPs:"
firewall-cmd --list-rich-rules | grep "drop\|reject" | wc -l

echo -e "\n================================"
```

### Configuration Template

#### Complete Firewall Setup Script
```bash
sudo nano /usr/local/bin/configure_firewall.sh
```

```bash
#!/bin/bash

echo "Configuring firewall for Hosting Management Platform..."

# Set default zone
firewall-cmd --set-default-zone=public

# Remove unnecessary services
firewall-cmd --permanent --remove-service=dhcpv6-client
firewall-cmd --permanent --remove-service=cockpit

# Add essential services
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https

# Add SSH with rate limiting
firewall-cmd --permanent --add-rich-rule='
  rule service name="ssh"
  limit value="3/m"
  accept'

# Block known malicious networks (example)
firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="185.220.100.0/24"
  drop'

# Enable logging for dropped packets
firewall-cmd --permanent --set-log-denied=all

# Add custom application ports if needed
# firewall-cmd --permanent --add-port=8090/tcp

# Reload firewall
firewall-cmd --reload

echo "Firewall configuration completed!"

# Display current configuration
firewall-cmd --list-all

# Save configuration
firewall-cmd --runtime-to-permanent
```

```bash
chmod +x /usr/local/bin/configure_firewall.sh
sudo /usr/local/bin/configure_firewall.sh
```

## Security Checklist

### Initial Setup
- [ ] Install firewalld
- [ ] Enable firewalld at boot
- [ ] Disable iptables (if applicable)
- [ ] Set default zone
- [ ] Configure essential services

### Service Configuration
- [ ] Add HTTP service
- [ ] Add HTTPS service
- [ ] Configure SSH (custom port if changed)
- [ ] Remove unnecessary services
- [ ] Add custom application ports

### Access Control
- [ ] Implement IP whitelisting for SSH
- [ ] Configure rate limiting
- [ ] Block known malicious IPs
- [ ] Set up fail2ban integration
- [ ] Configure zone-based access

### Monitoring and Logging
- [ ] Enable firewall logging
- [ ] Set up monitoring scripts
- [ ] Configure log rotation
- [ ] Create alerting for suspicious activity
- [ ] Regular audit schedule

### Maintenance
- [ ] Backup configuration regularly
- [ ] Document all changes
- [ ] Test rules before production
- [ ] Review rules quarterly
- [ ] Update malicious IP lists

## Next Steps

- Configure SSL certificates: See [SSL Configuration Guide](ssl.md)
- Implement fail2ban: See [Security Best Practices](security.md)
- Set up monitoring: See [Monitoring Guide](monitoring.md)
- Review security policies regularly
- Keep firewall rules updated

For more information, see:
- [Security Best Practices](security.md)
- [SSL Configuration Guide](ssl.md)
- [Monitoring Guide](monitoring.md)
- [firewalld Documentation](https://firewalld.org/documentation/)
- [Red Hat Security Guide](https://access.redhat.com/documentation/)
