# System Monitoring Guide

Comprehensive guide for monitoring the Hosting Management Platform infrastructure, services, and applications.

## Table of Contents
1. [Overview](#overview)
2. [System Resource Monitoring](#system-resource-monitoring)
3. [Service Monitoring](#service-monitoring)
4. [Application Monitoring](#application-monitoring)
5. [Database Monitoring](#database-monitoring)
6. [Log Monitoring](#log-monitoring)
7. [Network Monitoring](#network-monitoring)
8. [Performance Metrics](#performance-metrics)
9. [Alerting and Notifications](#alerting-and-notifications)
10. [Monitoring Tools](#monitoring-tools)
11. [Troubleshooting](#troubleshooting)

## Overview

System monitoring is critical for maintaining platform reliability, performance, and security. This guide covers all aspects of monitoring your hosting management infrastructure.

### Monitoring Objectives
- Ensure system availability and uptime
- Detect and respond to performance issues
- Monitor resource utilization
- Track application health
- Identify security threats
- Optimize resource allocation

### Key Metrics
- CPU utilization
- Memory usage
- Disk I/O and capacity
- Network throughput
- Service availability
- Response times
- Error rates
- Database performance

## System Resource Monitoring

### CPU Monitoring

#### Real-time CPU Usage
```bash
# View current CPU usage
top -b -n 1 | head -20

# Detailed CPU statistics
mpstat 1 5

# Per-process CPU usage
ps aux --sort=-%cpu | head -10

# CPU load averages
uptime
cat /proc/loadavg
```

#### Monitor CPU Over Time
```bash
# Install sysstat if not available
sudo yum install -y sysstat

# Enable and start sysstat
sudo systemctl enable sysstat
sudo systemctl start sysstat

# View CPU statistics
sar -u 1 10

# Historical CPU data
sar -u -f /var/log/sa/sa$(date +%d)
```

#### CPU Threshold Alerts
```bash
# Create CPU monitoring script
sudo nano /usr/local/bin/monitor_cpu.sh
```

```bash
#!/bin/bash
THRESHOLD=80
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
CPU_INT=${CPU_USAGE%.*}

if [ $CPU_INT -gt $THRESHOLD ]; then
    echo "WARNING: CPU usage is ${CPU_USAGE}%" | mail -s "High CPU Alert" admin@example.com
    logger "High CPU usage detected: ${CPU_USAGE}%"
fi
```

```bash
chmod +x /usr/local/bin/monitor_cpu.sh
echo "*/5 * * * * /usr/local/bin/monitor_cpu.sh" | sudo tee -a /etc/crontab
```

### Memory Monitoring

#### Check Memory Usage
```bash
# Current memory status
free -h

# Detailed memory information
cat /proc/meminfo

# Memory usage by process
ps aux --sort=-%mem | head -10

# Virtual memory statistics
vmstat 1 5
```

#### Monitor Memory Trends
```bash
# Memory usage over time
sar -r 1 10

# Swap usage
sar -S 1 10

# Page faults
sar -B 1 10
```

#### Memory Alert Script
```bash
sudo nano /usr/local/bin/monitor_memory.sh
```

```bash
#!/bin/bash
THRESHOLD=85
MEM_USAGE=$(free | grep Mem | awk '{print ($3/$2) * 100.0}')
MEM_INT=${MEM_USAGE%.*}

if [ $MEM_INT -gt $THRESHOLD ]; then
    echo "WARNING: Memory usage is ${MEM_USAGE}%" | mail -s "High Memory Alert" admin@example.com
    logger "High memory usage detected: ${MEM_USAGE}%"

    # Log top memory consumers
    ps aux --sort=-%mem | head -10 >> /var/log/memory_alerts.log
fi
```

### Disk Monitoring

#### Disk Space Monitoring
```bash
# Disk space usage
df -h

# Inode usage
df -i

# Disk usage by directory
du -sh /home/* | sort -rh | head -10

# Find large files
find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null
```

#### Disk I/O Monitoring
```bash
# I/O statistics
iostat -x 1 5

# Per-process I/O
iotop -o -b -n 3

# Disk performance
sar -d 1 10
```

#### Disk Space Alert
```bash
sudo nano /usr/local/bin/monitor_disk.sh
```

```bash
#!/bin/bash
THRESHOLD=80

df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 " " $6 }' | while read output;
do
    usage=$(echo $output | awk '{ print $1}' | cut -d'%' -f1)
    partition=$(echo $output | awk '{ print $2 }')
    mountpoint=$(echo $output | awk '{ print $3 }')

    if [ $usage -ge $THRESHOLD ]; then
        echo "WARNING: Disk usage on $partition ($mountpoint) is ${usage}%" | \
            mail -s "Disk Space Alert: $partition" admin@example.com
        logger "High disk usage on $partition: ${usage}%"
    fi
done
```

## Service Monitoring

### Web Server Monitoring

#### Apache/httpd Monitoring
```bash
# Check Apache status
sudo systemctl status httpd

# Apache process count
ps aux | grep httpd | wc -l

# Active connections
ss -ant | grep :80 | wc -l
ss -ant | grep :443 | wc -l

# Apache server status (requires mod_status)
curl http://localhost/server-status

# Error log monitoring
tail -f /var/log/httpd/error_log

# Access log analysis
tail -f /var/log/httpd/access_log | awk '{print $1}' | sort | uniq -c | sort -rn
```

#### Apache Configuration for Monitoring
```bash
sudo nano /etc/httpd/conf.d/status.conf
```

```apache
<Location /server-status>
    SetHandler server-status
    Require local
    Require ip 127.0.0.1
</Location>

ExtendedStatus On
```

#### Nginx Monitoring (Alternative)
```bash
# Check Nginx status
sudo systemctl status nginx

# Nginx stub status
curl http://localhost/nginx_status

# Active connections
ss -ant | grep :80 | grep ESTAB | wc -l

# Monitor error logs
tail -f /var/log/nginx/error.log
```

### PHP-FPM Monitoring

```bash
# Check PHP-FPM status
sudo systemctl status php-fpm

# PHP-FPM pool status
curl http://localhost/php-fpm-status

# Monitor slow logs
tail -f /var/log/php-fpm/slow.log

# Check PHP-FPM errors
tail -f /var/log/php-fpm/error.log
```

PHP-FPM Status Configuration:
```bash
sudo nano /etc/php-fpm.d/www.conf
```

```ini
pm.status_path = /php-fpm-status
ping.path = /php-fpm-ping
slowlog = /var/log/php-fpm/slow.log
request_slowlog_timeout = 5s
```

### Database Monitoring

See [Database Monitoring](#database-monitoring) section for detailed MySQL/MariaDB monitoring.

## Application Monitoring

### Laravel Application Health

#### Application Status Check
```bash
# Check application is responding
curl -I https://whm.soporteclientes.net
curl -I https://cpanel1.soporteclientes.net
curl -I https://admin.soporteclientes.net

# Test with timeout
timeout 5 curl -f https://whm.soporteclientes.net || echo "Application not responding"
```

#### Queue Worker Monitoring
```bash
# Check queue worker status
sudo systemctl status laravel-worker

# Monitor queue length
cd /home/admin.soporteclientes.net
php artisan queue:work --once --quiet || echo "Queue worker failed"

# List failed jobs
php artisan queue:failed

# Monitor horizon (if used)
php artisan horizon:status
```

#### Laravel Logs Monitoring
```bash
# Monitor Laravel logs in real-time
tail -f /home/whm.soporteclientes.net/public_html/storage/logs/laravel.log
tail -f /home/cpanel1.soporteclientes.net/storage/logs/laravel.log
tail -f /home/admin.soporteclientes.net/storage/logs/laravel.log

# Check for errors in last hour
find /home/*/storage/logs/ -name "laravel*.log" -mmin -60 -exec grep -i "error\|exception\|fatal" {} +

# Count errors by type
grep -h "ERROR:" /home/*/storage/logs/laravel.log | awk -F: '{print $3}' | sort | uniq -c | sort -rn
```

#### Application Metrics Script
```bash
sudo nano /usr/local/bin/monitor_app.sh
```

```bash
#!/bin/bash

APPS=(
    "https://whm.soporteclientes.net"
    "https://cpanel1.soporteclientes.net"
    "https://admin.soporteclientes.net"
)

for APP in "${APPS[@]}"; do
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}:%{time_total}" --max-time 10 $APP)
    HTTP_CODE=$(echo $RESPONSE | cut -d: -f1)
    TIME=$(echo $RESPONSE | cut -d: -f2)

    if [ "$HTTP_CODE" != "200" ]; then
        echo "ALERT: $APP returned $HTTP_CODE" | mail -s "Application Down" admin@example.com
        logger "Application monitoring: $APP returned $HTTP_CODE"
    fi

    # Alert if response time > 3 seconds
    if (( $(echo "$TIME > 3.0" | bc -l) )); then
        echo "WARNING: $APP slow response: ${TIME}s" | mail -s "Slow Response" admin@example.com
    fi

    echo "$(date) - $APP - Status: $HTTP_CODE - Time: ${TIME}s" >> /var/log/app_monitoring.log
done
```

## Database Monitoring

### MySQL/MariaDB Monitoring

#### Basic Status Checks
```bash
# Check database service
sudo systemctl status mariadb

# Login and check status
mysql -u root -p -e "STATUS;"

# Show process list
mysql -u root -p -e "SHOW PROCESSLIST;"

# Show all databases
mysql -u root -p -e "SHOW DATABASES;"

# Database sizes
mysql -u root -p -e "
SELECT
    table_schema AS 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
FROM information_schema.tables
GROUP BY table_schema;"
```

#### Performance Monitoring
```bash
# Show database variables
mysql -u root -p -e "SHOW VARIABLES LIKE '%connection%';"

# Current connections
mysql -u root -p -e "SHOW STATUS LIKE 'Threads_connected';"

# Max connections
mysql -u root -p -e "SHOW VARIABLES LIKE 'max_connections';"

# Slow queries
mysql -u root -p -e "SHOW STATUS LIKE 'Slow_queries';"

# Query cache
mysql -u root -p -e "SHOW STATUS LIKE 'Qcache%';"
```

#### Enable Slow Query Log
```bash
sudo nano /etc/my.cnf
```

```ini
[mysqld]
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow-query.log
long_query_time = 2
log_queries_not_using_indexes = 1
```

```bash
sudo systemctl restart mariadb
tail -f /var/log/mysql/slow-query.log
```

#### Database Monitoring Script
```bash
sudo nano /usr/local/bin/monitor_database.sh
```

```bash
#!/bin/bash

MYSQL_USER="root"
MYSQL_PASS="your_password"

# Check if MySQL is running
if ! systemctl is-active --quiet mariadb; then
    echo "CRITICAL: MySQL is not running!" | mail -s "MySQL Down" admin@example.com
    exit 1
fi

# Check connections
CONNECTIONS=$(mysql -u$MYSQL_USER -p$MYSQL_PASS -e "SHOW STATUS LIKE 'Threads_connected';" | grep Threads | awk '{print $2}')
MAX_CONN=$(mysql -u$MYSQL_USER -p$MYSQL_PASS -e "SHOW VARIABLES LIKE 'max_connections';" | grep max | awk '{print $2}')
CONN_PERCENT=$((CONNECTIONS * 100 / MAX_CONN))

if [ $CONN_PERCENT -gt 80 ]; then
    echo "WARNING: Database connections at ${CONN_PERCENT}% ($CONNECTIONS/$MAX_CONN)" | \
        mail -s "High DB Connections" admin@example.com
fi

# Check slow queries
SLOW=$(mysql -u$MYSQL_USER -p$MYSQL_PASS -e "SHOW STATUS LIKE 'Slow_queries';" | grep Slow | awk '{print $2}')
echo "$(date) - Connections: $CONNECTIONS/$MAX_CONN - Slow Queries: $SLOW" >> /var/log/db_monitoring.log
```

## Log Monitoring

### Centralized Log Monitoring

#### Install and Configure rsyslog
```bash
# Install rsyslog
sudo yum install -y rsyslog

# Configure remote logging
sudo nano /etc/rsyslog.conf
```

```conf
# Log application messages
local0.* /var/log/application.log

# Forward to remote server (optional)
*.* @@remote-log-server:514
```

#### Important Log Files
```bash
# System logs
/var/log/messages
/var/log/secure
/var/log/cron
/var/log/boot.log

# Web server logs
/var/log/httpd/access_log
/var/log/httpd/error_log

# Application logs
/home/*/storage/logs/laravel.log

# Database logs
/var/log/mariadb/mariadb.log
/var/log/mysql/slow-query.log

# Mail logs
/var/log/maillog

# Authentication logs
/var/log/secure
```

#### Log Rotation Configuration
```bash
sudo nano /etc/logrotate.d/application
```

```conf
/home/*/storage/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 apache apache
    sharedscripts
    postrotate
        /usr/bin/killall -SIGUSR1 php-fpm 2>/dev/null || true
    endscript
}
```

#### Real-time Log Monitoring
```bash
# Monitor multiple logs
sudo tail -f /var/log/messages /var/log/httpd/error_log /home/*/storage/logs/laravel.log

# Using multitail (install first)
sudo yum install -y multitail
sudo multitail /var/log/messages /var/log/httpd/error_log

# Search logs for patterns
sudo grep -i "error\|fail\|critical" /var/log/messages | tail -20
```

#### Log Analysis Script
```bash
sudo nano /usr/local/bin/analyze_logs.sh
```

```bash
#!/bin/bash

DATE=$(date +%Y-%m-%d)
REPORT="/var/log/daily_report_${DATE}.txt"

echo "Daily Log Analysis - $DATE" > $REPORT
echo "======================================" >> $REPORT

# Count errors in system logs
echo -e "\nSystem Errors:" >> $REPORT
grep -i "error" /var/log/messages | wc -l >> $REPORT

# Failed login attempts
echo -e "\nFailed Login Attempts:" >> $REPORT
grep "Failed password" /var/log/secure | wc -l >> $REPORT

# Top IPs in access log
echo -e "\nTop 10 IP Addresses:" >> $REPORT
awk '{print $1}' /var/log/httpd/access_log | sort | uniq -c | sort -rn | head -10 >> $REPORT

# 404 errors
echo -e "\n404 Errors:" >> $REPORT
grep "404" /var/log/httpd/access_log | wc -l >> $REPORT

# Application errors
echo -e "\nApplication Errors:" >> $REPORT
grep -h "ERROR:" /home/*/storage/logs/laravel.log 2>/dev/null | wc -l >> $REPORT

# Email report
cat $REPORT | mail -s "Daily Log Report - $DATE" admin@example.com
```

## Network Monitoring

### Network Interface Monitoring
```bash
# Show network interfaces
ip addr show

# Network statistics
netstat -i

# Interface statistics
ip -s link

# Real-time bandwidth usage
iftop -i eth0

# Network throughput
sar -n DEV 1 10
```

### Connection Monitoring
```bash
# Active connections
ss -tuln

# Connections by state
ss -s

# Listening ports
netstat -tlnp

# Established connections
ss -ant | grep ESTAB | wc -l

# Connections per IP
netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10
```

### Network Performance
```bash
# Ping test
ping -c 10 google.com

# Trace route
traceroute google.com

# DNS resolution time
dig google.com

# Bandwidth test (install first)
sudo yum install -y iperf3
iperf3 -c speedtest.server.com
```

### Network Monitoring Script
```bash
sudo nano /usr/local/bin/monitor_network.sh
```

```bash
#!/bin/bash

# Check connectivity
if ! ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    echo "CRITICAL: No internet connectivity!" | mail -s "Network Down" admin@example.com
    logger "Network monitoring: No connectivity"
fi

# Check connections
CONNECTIONS=$(ss -ant | grep ESTAB | wc -l)
if [ $CONNECTIONS -gt 1000 ]; then
    echo "WARNING: High connection count: $CONNECTIONS" | mail -s "High Connections" admin@example.com
fi

# Check bandwidth usage
RX_BEFORE=$(cat /sys/class/net/eth0/statistics/rx_bytes)
TX_BEFORE=$(cat /sys/class/net/eth0/statistics/tx_bytes)
sleep 1
RX_AFTER=$(cat /sys/class/net/eth0/statistics/rx_bytes)
TX_AFTER=$(cat /sys/class/net/eth0/statistics/tx_bytes)

RX_RATE=$(( ($RX_AFTER - $RX_BEFORE) / 1024 ))
TX_RATE=$(( ($TX_AFTER - $TX_BEFORE) / 1024 ))

echo "$(date) - RX: ${RX_RATE}KB/s TX: ${TX_RATE}KB/s Connections: $CONNECTIONS" >> /var/log/network_monitoring.log
```

## Performance Metrics

### System Performance Overview
```bash
# General system info
uname -a
hostnamectl

# Uptime and load
uptime
w

# System performance summary
sar -A 1 5
```

### Create Performance Dashboard Script
```bash
sudo nano /usr/local/bin/performance_dashboard.sh
```

```bash
#!/bin/bash

clear
echo "========================================="
echo "     SYSTEM PERFORMANCE DASHBOARD"
echo "========================================="
echo "Date: $(date)"
echo ""

# CPU
echo "--- CPU Usage ---"
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
echo "CPU Usage: $CPU"
echo ""

# Memory
echo "--- Memory ---"
free -h
echo ""

# Disk
echo "--- Disk Usage ---"
df -h | grep -E "^/dev"
echo ""

# Load Average
echo "--- Load Average ---"
uptime | awk -F'load average:' '{print $2}'
echo ""

# Network
echo "--- Network ---"
echo "Active Connections: $(ss -ant | grep ESTAB | wc -l)"
echo ""

# Services
echo "--- Critical Services ---"
services=("httpd" "mariadb" "php-fpm" "laravel-worker")
for service in "${services[@]}"; do
    if systemctl is-active --quiet $service; then
        echo "$service: RUNNING"
    else
        echo "$service: STOPPED"
    fi
done
echo ""

# Database
echo "--- Database Connections ---"
mysql -u root -p"$MYSQL_PASSWORD" -e "SHOW STATUS LIKE 'Threads_connected';" 2>/dev/null | tail -1
echo ""
```

## Alerting and Notifications

### Email Alerts Setup

#### Configure Postfix
```bash
# Install mailx
sudo yum install -y mailx postfix

# Start postfix
sudo systemctl start postfix
sudo systemctl enable postfix

# Test email
echo "Test message" | mail -s "Test Subject" admin@example.com
```

#### Configure External SMTP
```bash
sudo nano /etc/postfix/main.cf
```

```conf
relayhost = [smtp.gmail.com]:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_CAfile = /etc/ssl/certs/ca-bundle.crt
```

```bash
sudo nano /etc/postfix/sasl_passwd
```

```
[smtp.gmail.com]:587 username@gmail.com:password
```

```bash
sudo postmap /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
sudo systemctl restart postfix
```

### Comprehensive Monitoring Script
```bash
sudo nano /usr/local/bin/comprehensive_monitor.sh
```

```bash
#!/bin/bash

ALERT_EMAIL="admin@example.com"
HOSTNAME=$(hostname)

# Function to send alert
send_alert() {
    SUBJECT=$1
    MESSAGE=$2
    echo "$MESSAGE" | mail -s "[$HOSTNAME] $SUBJECT" $ALERT_EMAIL
    logger "Monitoring Alert: $SUBJECT - $MESSAGE"
}

# Check CPU
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d. -f1)
if [ $CPU_USAGE -gt 80 ]; then
    send_alert "High CPU Usage" "CPU usage is ${CPU_USAGE}%"
fi

# Check Memory
MEM_USAGE=$(free | grep Mem | awk '{print ($3/$2) * 100.0}' | cut -d. -f1)
if [ $MEM_USAGE -gt 85 ]; then
    send_alert "High Memory Usage" "Memory usage is ${MEM_USAGE}%"
fi

# Check Disk
df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $6 }' | while read output;
do
    usage=$(echo $output | awk '{ print $1}' | cut -d'%' -f1)
    partition=$(echo $output | awk '{ print $2 }')
    if [ $usage -ge 80 ]; then
        send_alert "High Disk Usage" "Disk usage on $partition is ${usage}%"
    fi
done

# Check Services
for service in httpd mariadb php-fpm laravel-worker; do
    if ! systemctl is-active --quiet $service; then
        send_alert "Service Down" "$service is not running!"
    fi
done

# Check URLs
for url in "https://whm.soporteclientes.net" "https://cpanel1.soporteclientes.net" "https://admin.soporteclientes.net"; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 $url)
    if [ "$HTTP_CODE" != "200" ]; then
        send_alert "Website Down" "$url returned HTTP $HTTP_CODE"
    fi
done

echo "$(date) - Monitoring check completed" >> /var/log/comprehensive_monitor.log
```

```bash
chmod +x /usr/local/bin/comprehensive_monitor.sh
echo "*/5 * * * * /usr/local/bin/comprehensive_monitor.sh" | sudo tee -a /etc/crontab
```

## Monitoring Tools

### Install Monitoring Tools

#### htop (Enhanced top)
```bash
sudo yum install -y htop
htop
```

#### glances (System Monitoring)
```bash
sudo yum install -y python3-pip
sudo pip3 install glances
glances
```

#### nmon (Performance Monitor)
```bash
sudo yum install -y nmon
nmon
```

### Optional: Install Nagios

```bash
# Install dependencies
sudo yum install -y gcc glibc glibc-common wget gd gd-devel perl postfix

# Create nagios user
sudo useradd nagios
sudo groupadd nagcmd
sudo usermod -a -G nagcmd nagios

# Download and install
cd /tmp
wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.4.6.tar.gz
tar xzf nagios-4.4.6.tar.gz
cd nagios-4.4.6

./configure --with-command-group=nagcmd
make all
sudo make install
sudo make install-init
sudo make install-config
sudo make install-commandmode
```

### Optional: Prometheus and Grafana

See separate documentation for advanced monitoring with Prometheus and Grafana.

## Troubleshooting

### High CPU Usage
```bash
# Find CPU-intensive processes
top -b -n 1 | head -20
ps aux --sort=-%cpu | head -10

# Kill problematic process
kill -9 PID

# Check for runaway processes
ps aux | grep defunct
```

### High Memory Usage
```bash
# Clear PageCache
sync && echo 1 > /proc/sys/vm/drop_caches

# Find memory leaks
ps aux --sort=-%mem | head -10

# Check for memory exhaustion
dmesg | grep -i "out of memory"
```

### Disk Full
```bash
# Find large files
find / -type f -size +500M -exec ls -lh {} \;

# Clear old logs
find /var/log -type f -name "*.log" -mtime +30 -delete

# Clear package cache
yum clean all
```

### Service Not Responding
```bash
# Check service status
systemctl status service_name

# View service logs
journalctl -u service_name -n 50

# Restart service
sudo systemctl restart service_name

# Check for port conflicts
netstat -tlnp | grep :80
```

### Database Issues
```bash
# Check MySQL errors
tail -100 /var/log/mariadb/mariadb.log

# Kill long-running queries
mysql -u root -p -e "SHOW PROCESSLIST;"
mysql -u root -p -e "KILL query_id;"

# Optimize tables
mysqlcheck -u root -p --optimize --all-databases
```

## Best Practices

1. **Regular Monitoring**: Check systems at least daily
2. **Automate Alerts**: Set up automated monitoring scripts
3. **Baseline Metrics**: Establish normal performance baselines
4. **Log Retention**: Keep logs for at least 30 days
5. **Documentation**: Document all incidents and resolutions
6. **Capacity Planning**: Monitor trends for growth planning
7. **Security Monitoring**: Watch for suspicious activities
8. **Backup Monitoring**: Verify backup completion daily
9. **Update Monitoring**: Track system and application updates
10. **Test Alerts**: Regularly test alerting mechanisms

## Next Steps

- Set up advanced monitoring with Prometheus/Grafana
- Configure centralized logging with ELK stack
- Implement application performance monitoring (APM)
- Set up uptime monitoring services
- Configure automated incident response

For more information, see:
- [Troubleshooting Guide](troubleshooting.md)
- [Security Best Practices](security.md)
- [Performance Optimization](performance.md)
