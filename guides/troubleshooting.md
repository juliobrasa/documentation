# Troubleshooting Guide

Comprehensive troubleshooting guide for the Hosting Management Platform covering common issues, diagnostic procedures, and solutions.

## Table of Contents
1. [Overview](#overview)
2. [General Troubleshooting Methodology](#general-troubleshooting-methodology)
3. [Installation Issues](#installation-issues)
4. [Web Server Issues](#web-server-issues)
5. [Application Issues](#application-issues)
6. [Database Issues](#database-issues)
7. [PHP Issues](#php-issues)
8. [Email Issues](#email-issues)
9. [SSL Certificate Issues](#ssl-certificate-issues)
10. [Performance Issues](#performance-issues)
11. [Network Issues](#network-issues)
12. [Authentication Issues](#authentication-issues)
13. [File Permission Issues](#file-permission-issues)
14. [Advanced Diagnostics](#advanced-diagnostics)

## Overview

This guide provides systematic approaches to identify, diagnose, and resolve common issues in the Hosting Management Platform.

### When to Use This Guide
- Application not responding
- Error messages appearing
- Performance degradation
- Service failures
- Authentication problems
- Configuration issues

### Required Access
- SSH access to server
- Root or sudo privileges
- Database credentials
- Application configuration access

## General Troubleshooting Methodology

### Step 1: Identify the Problem
```bash
# Check overall system status
systemctl status

# Check system logs
tail -100 /var/log/messages

# Check service status
systemctl status httpd mariadb php-fpm

# Check resource usage
top
free -h
df -h
```

### Step 2: Gather Information
```bash
# System information
uname -a
cat /etc/redhat-release

# Check recent changes
rpm -qa --last | head -20
tail -100 /var/log/yum.log

# Review error logs
tail -100 /var/log/httpd/error_log
tail -100 /home/*/storage/logs/laravel.log
```

### Step 3: Isolate the Issue
```bash
# Test connectivity
ping -c 3 google.com
curl -I http://localhost

# Test services individually
systemctl restart httpd
systemctl restart mariadb

# Check dependencies
php -v
mysql --version
composer --version
```

### Step 4: Implement Solution
- Apply appropriate fix
- Test thoroughly
- Document changes
- Monitor for recurrence

### Step 5: Verify Resolution
```bash
# Confirm services running
systemctl status httpd mariadb php-fpm

# Test application
curl -I https://whm.soporteclientes.net

# Check logs for errors
tail -f /var/log/httpd/error_log
```

## Installation Issues

### Installation Script Fails

#### Problem: Script exits with errors
```bash
# Check script permissions
ls -la install.sh
chmod +x install.sh

# Run with debug mode
bash -x install.sh

# Check available disk space
df -h

# Check internet connectivity
ping -c 3 github.com
```

#### Solution: Missing dependencies
```bash
# Install missing packages
sudo yum install -y epel-release
sudo yum update -y
sudo yum install -y wget curl git

# Verify installations
which wget curl git
```

### Database Creation Fails

#### Problem: Cannot create databases
```bash
# Check MariaDB status
systemctl status mariadb

# Start if stopped
sudo systemctl start mariadb

# Check MariaDB logs
tail -50 /var/log/mariadb/mariadb.log

# Test root access
mysql -u root -p
```

#### Solution: Reset root password
```bash
# Stop MariaDB
sudo systemctl stop mariadb

# Start in safe mode
sudo mysqld_safe --skip-grant-tables &

# Reset password
mysql -u root
UPDATE mysql.user SET Password=PASSWORD('new_password') WHERE User='root';
FLUSH PRIVILEGES;
exit

# Restart normally
sudo killall mysqld
sudo systemctl start mariadb
```

### Composer Install Fails

#### Problem: Composer dependencies fail
```bash
# Update composer
sudo composer self-update

# Clear cache
composer clear-cache

# Install with verbose output
composer install -vvv

# Check PHP version
php -v

# Check memory limit
php -i | grep memory_limit
```

#### Solution: Increase PHP memory
```bash
sudo nano /etc/php.ini
```

```ini
memory_limit = 512M
```

```bash
sudo systemctl restart php-fpm
composer install --no-dev --optimize-autoloader
```

### Permission Issues During Installation

```bash
# Fix ownership
sudo chown -R apache:apache /home/whm.soporteclientes.net
sudo chown -R apache:apache /home/cpanel1.soporteclientes.net
sudo chown -R apache:apache /home/admin.soporteclientes.net

# Set correct permissions
find /home/*/public_html -type d -exec chmod 755 {} \;
find /home/*/public_html -type f -exec chmod 644 {} \;
chmod -R 775 /home/*/storage
chmod -R 775 /home/*/bootstrap/cache
```

## Web Server Issues

### Apache Won't Start

#### Problem: httpd service fails to start
```bash
# Check Apache status
systemctl status httpd -l

# Check Apache configuration
sudo apachectl configtest

# Check error logs
tail -50 /var/log/httpd/error_log

# Check port conflicts
netstat -tlnp | grep :80
netstat -tlnp | grep :443
```

#### Solution: Fix configuration errors
```bash
# Test configuration syntax
sudo httpd -t

# Find specific error
sudo httpd -S

# Fix common issues
sudo nano /etc/httpd/conf/httpd.conf

# Restart Apache
sudo systemctl restart httpd
```

### 404 Not Found Errors

#### Problem: Pages return 404
```bash
# Check document root
grep -r DocumentRoot /etc/httpd/conf*

# Verify files exist
ls -la /home/whm.soporteclientes.net/public_html/public

# Check .htaccess
cat /home/whm.soporteclientes.net/public_html/public/.htaccess

# Test mod_rewrite
httpd -M | grep rewrite
```

#### Solution: Enable mod_rewrite and fix .htaccess
```bash
# Enable mod_rewrite
sudo nano /etc/httpd/conf/httpd.conf
```

```apache
LoadModule rewrite_module modules/mod_rewrite.so

<Directory "/home">
    AllowOverride All
</Directory>
```

```bash
# Restart Apache
sudo systemctl restart httpd
```

### 500 Internal Server Error

#### Problem: Application returns 500 errors
```bash
# Check Apache error log
tail -50 /var/log/httpd/error_log

# Check Laravel logs
tail -50 /home/*/storage/logs/laravel.log

# Check PHP errors
tail -50 /var/log/php-fpm/error.log

# Enable debug mode temporarily
cd /home/whm.soporteclientes.net/public_html
nano .env
```

```env
APP_DEBUG=true
APP_ENV=local
```

#### Solution: Common fixes
```bash
# Clear Laravel caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Regenerate autoload
composer dump-autoload

# Check file permissions
chmod -R 775 storage bootstrap/cache
chown -R apache:apache storage bootstrap/cache

# Disable debug when done
nano .env
```

```env
APP_DEBUG=false
APP_ENV=production
```

### Slow Page Load

#### Problem: Pages load slowly
```bash
# Check Apache process count
ps aux | grep httpd | wc -l

# Check MaxClients setting
grep MaxRequestWorkers /etc/httpd/conf/httpd.conf

# Monitor in real-time
tail -f /var/log/httpd/access_log

# Check PHP-FPM slow log
tail -f /var/log/php-fpm/slow.log
```

#### Solution: Optimize Apache and PHP-FPM
```bash
sudo nano /etc/httpd/conf/httpd.conf
```

```apache
<IfModule mpm_prefork_module>
    StartServers 5
    MinSpareServers 5
    MaxSpareServers 10
    MaxRequestWorkers 150
    MaxConnectionsPerChild 3000
</IfModule>
```

```bash
sudo nano /etc/php-fpm.d/www.conf
```

```ini
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
```

## Application Issues

### White Screen / Blank Page

#### Problem: Application shows white screen
```bash
# Enable error display
nano /home/whm.soporteclientes.net/public_html/.env
```

```env
APP_DEBUG=true
```

```bash
# Check PHP errors
tail -50 /var/log/php-fpm/error.log

# Check Laravel logs
tail -50 /home/whm.soporteclientes.net/public_html/storage/logs/laravel.log

# Check web server logs
tail -50 /var/log/httpd/error_log
```

#### Solution: Fix common causes
```bash
# Storage permissions
chmod -R 775 storage bootstrap/cache

# Clear all caches
php artisan cache:clear
php artisan config:clear
php artisan view:clear

# Verify .env file exists
ls -la .env

# Check composer autoload
composer dump-autoload -o
```

### Database Connection Failed

#### Problem: Cannot connect to database
```bash
# Test database connection
mysql -u whm_user -p -h localhost whm_panel

# Check .env configuration
cat .env | grep DB_

# Verify database exists
mysql -u root -p -e "SHOW DATABASES;"

# Check user privileges
mysql -u root -p -e "SHOW GRANTS FOR 'whm_user'@'localhost';"
```

#### Solution: Fix database configuration
```bash
# Update .env file
nano .env
```

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=whm_panel
DB_USERNAME=whm_user
DB_PASSWORD=correct_password
```

```bash
# Clear config cache
php artisan config:clear

# Test connection
php artisan tinker
>>> DB::connection()->getPdo();
```

### Queue Jobs Not Processing

#### Problem: Jobs stuck in queue
```bash
# Check queue worker status
systemctl status laravel-worker

# View failed jobs
cd /home/admin.soporteclientes.net
php artisan queue:failed

# Check queue table
mysql -u root -p admindb -e "SELECT * FROM jobs;"
```

#### Solution: Restart queue workers
```bash
# Restart worker service
sudo systemctl restart laravel-worker

# Process jobs manually
php artisan queue:work --once

# Retry failed jobs
php artisan queue:retry all

# Clear failed jobs (if needed)
php artisan queue:flush
```

### Migration Errors

#### Problem: Migrations fail
```bash
# Check migration status
php artisan migrate:status

# View migration error
php artisan migrate --verbose

# Check database connection
php artisan tinker
>>> Schema::hasTable('users');
```

#### Solution: Fix migration issues
```bash
# Rollback last migration
php artisan migrate:rollback

# Rollback specific migration
php artisan migrate:rollback --step=1

# Fresh migration (CAUTION: deletes data)
php artisan migrate:fresh

# Seed database
php artisan db:seed
```

### Routes Not Working

#### Problem: Routes return 404
```bash
# List all routes
php artisan route:list

# Clear route cache
php artisan route:clear

# Cache routes
php artisan route:cache

# Check .htaccess
cat public/.htaccess
```

#### Solution: Fix routing
```bash
# Verify .htaccess exists
nano public/.htaccess
```

```apache
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteRule ^(.*)$ public/$1 [L]
</IfModule>
```

```bash
# Clear and rebuild cache
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
```

## Database Issues

### High Database Load

#### Problem: Database consuming high CPU
```bash
# Show running processes
mysql -u root -p -e "SHOW PROCESSLIST;"

# Identify slow queries
mysql -u root -p -e "SHOW FULL PROCESSLIST;" | grep -i "Sending data"

# Check slow query log
tail -50 /var/log/mysql/slow-query.log

# View query cache stats
mysql -u root -p -e "SHOW STATUS LIKE 'Qcache%';"
```

#### Solution: Optimize queries and database
```bash
# Kill long-running query
mysql -u root -p -e "KILL <process_id>;"

# Optimize tables
mysqlcheck -u root -p --optimize --all-databases

# Analyze tables
mysqlcheck -u root -p --analyze --all-databases

# Add indexes to slow queries
mysql -u root -p database_name
ALTER TABLE table_name ADD INDEX idx_column (column_name);
```

### Database Connection Limit Reached

#### Problem: Too many connections
```bash
# Check current connections
mysql -u root -p -e "SHOW STATUS LIKE 'Threads_connected';"

# Check max connections
mysql -u root -p -e "SHOW VARIABLES LIKE 'max_connections';"

# Show all connections
mysql -u root -p -e "SHOW PROCESSLIST;"
```

#### Solution: Increase connection limit
```bash
sudo nano /etc/my.cnf
```

```ini
[mysqld]
max_connections = 500
```

```bash
sudo systemctl restart mariadb

# Verify change
mysql -u root -p -e "SHOW VARIABLES LIKE 'max_connections';"
```

### Database Corruption

#### Problem: Table is marked as crashed
```bash
# Check table status
mysqlcheck -u root -p --check database_name

# Check all databases
mysqlcheck -u root -p --check --all-databases
```

#### Solution: Repair tables
```bash
# Repair specific table
mysqlcheck -u root -p --repair database_name table_name

# Repair all tables
mysqlcheck -u root -p --auto-repair --all-databases

# Optimize after repair
mysqlcheck -u root -p --optimize --all-databases
```

### Transaction Deadlock

#### Problem: Deadlock errors in logs
```bash
# Show engine status
mysql -u root -p -e "SHOW ENGINE INNODB STATUS\G" | grep -A 20 "LATEST DETECTED DEADLOCK"

# Check for locked tables
mysql -u root -p -e "SHOW OPEN TABLES WHERE In_use > 0;"
```

#### Solution: Resolve deadlocks
```bash
# Identify blocking query
mysql -u root -p
SELECT * FROM information_schema.INNODB_LOCKS;

# Kill blocking process
KILL <process_id>;

# Optimize transaction handling in application
# Use shorter transactions
# Add proper indexes
# Use row-level locking appropriately
```

## PHP Issues

### PHP Errors Not Displaying

#### Problem: PHP errors not shown
```bash
# Check PHP error settings
php -i | grep error

# Check php.ini
grep -E "display_errors|error_reporting" /etc/php.ini

# Check PHP-FPM logs
tail -50 /var/log/php-fpm/error.log
```

#### Solution: Enable error display (development only)
```bash
sudo nano /etc/php.ini
```

```ini
display_errors = On
error_reporting = E_ALL
log_errors = On
error_log = /var/log/php-fpm/error.log
```

```bash
sudo systemctl restart php-fpm
```

### Memory Exhausted Errors

#### Problem: PHP memory limit reached
```bash
# Check current limit
php -i | grep memory_limit

# Check error log
grep "memory" /var/log/php-fpm/error.log
```

#### Solution: Increase memory limit
```bash
sudo nano /etc/php.ini
```

```ini
memory_limit = 512M
```

```bash
sudo systemctl restart php-fpm

# Verify change
php -i | grep memory_limit
```

### Maximum Execution Time Exceeded

#### Problem: Scripts timeout
```bash
# Check timeout settings
php -i | grep max_execution_time

# Check for long-running scripts
tail -f /var/log/php-fpm/slow.log
```

#### Solution: Increase timeout
```bash
sudo nano /etc/php.ini
```

```ini
max_execution_time = 300
max_input_time = 300
```

```bash
sudo nano /etc/php-fpm.d/www.conf
```

```ini
request_terminate_timeout = 300
```

```bash
sudo systemctl restart php-fpm
```

### Upload Size Limit

#### Problem: Cannot upload large files
```bash
# Check upload limits
php -i | grep upload_max_filesize
php -i | grep post_max_size
```

#### Solution: Increase upload limits
```bash
sudo nano /etc/php.ini
```

```ini
upload_max_filesize = 100M
post_max_size = 100M
memory_limit = 512M
```

```bash
sudo systemctl restart php-fpm
```

## Email Issues

### Emails Not Sending

#### Problem: Application cannot send emails
```bash
# Check mail queue
mailq

# Test mail command
echo "Test" | mail -s "Test" user@example.com

# Check postfix status
systemctl status postfix

# Check mail logs
tail -50 /var/log/maillog
```

#### Solution: Configure mail properly
```bash
# Start postfix
sudo systemctl start postfix
sudo systemctl enable postfix

# Test SMTP connection
telnet smtp.gmail.com 587

# Configure Laravel mail
nano .env
```

```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your@email.com
MAIL_PASSWORD=your_password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@yourdomain.com
MAIL_FROM_NAME="${APP_NAME}"
```

```bash
# Clear config cache
php artisan config:clear
```

### Emails Marked as Spam

#### Problem: Sent emails go to spam
```bash
# Check SPF record
dig +short txt yourdomain.com | grep spf

# Check DKIM
dig +short txt default._domainkey.yourdomain.com

# Check mail headers
tail /var/log/maillog
```

#### Solution: Configure SPF and DKIM
```bash
# Install OpenDKIM
sudo yum install -y opendkim

# Configure DKIM
sudo nano /etc/opendkim.conf
```

Add DNS records:
```
TXT record: v=spf1 mx a ip4:your_server_ip ~all
TXT record: default._domainkey IN TXT "v=DKIM1; k=rsa; p=public_key"
```

## SSL Certificate Issues

### Certificate Expired

#### Problem: SSL certificate has expired
```bash
# Check certificate expiration
echo | openssl s_client -connect yourdomain.com:443 2>/dev/null | openssl x509 -noout -dates

# Check with certbot
sudo certbot certificates
```

#### Solution: Renew certificate
```bash
# Renew specific certificate
sudo certbot renew --cert-name yourdomain.com

# Force renewal
sudo certbot renew --force-renewal

# Restart Apache
sudo systemctl restart httpd

# Verify renewal
sudo certbot certificates
```

### Mixed Content Warnings

#### Problem: Browser shows mixed content errors
```bash
# Check for HTTP resources
grep -r "http://" /home/*/public_html/resources/

# Check .env file
cat .env | grep APP_URL
```

#### Solution: Force HTTPS
```bash
# Update .env
nano .env
```

```env
APP_URL=https://yourdomain.com
```

```bash
# Add to .htaccess
nano public/.htaccess
```

```apache
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
```

### Certificate Chain Issues

#### Problem: Certificate chain incomplete
```bash
# Test SSL chain
openssl s_client -connect yourdomain.com:443 -showcerts

# Check certificate files
ls -la /etc/letsencrypt/live/yourdomain.com/
```

#### Solution: Fix certificate chain
```bash
# Reinstall certificate
sudo certbot --apache -d yourdomain.com

# Verify Apache SSL config
cat /etc/httpd/conf.d/ssl.conf | grep SSLCertificate
```

## Performance Issues

### High Server Load

#### Problem: Server load very high
```bash
# Check load average
uptime

# Find CPU-intensive processes
top -b -n 1 | head -20

# Check I/O wait
iostat -x 1 5

# Check memory usage
free -h
```

#### Solution: Identify and resolve bottleneck
```bash
# Kill problematic process
kill -9 <pid>

# Restart services
sudo systemctl restart httpd php-fpm

# Check for DDoS
netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -n

# Implement rate limiting
sudo nano /etc/httpd/conf.d/ratelimit.conf
```

### Slow Database Queries

#### Problem: Queries taking too long
```bash
# Enable slow query log
sudo nano /etc/my.cnf
```

```ini
[mysqld]
slow_query_log = 1
long_query_time = 2
```

```bash
# Analyze slow queries
mysqldumpslow /var/log/mysql/slow-query.log

# Use EXPLAIN on slow queries
mysql -u root -p
EXPLAIN SELECT * FROM table WHERE condition;
```

#### Solution: Optimize queries
```bash
# Add missing indexes
ALTER TABLE users ADD INDEX idx_email (email);

# Optimize tables
OPTIMIZE TABLE tablename;

# Update table statistics
ANALYZE TABLE tablename;
```

## Network Issues

### Cannot Connect to Server

#### Problem: SSH or HTTP not responding
```bash
# Check if server is reachable
ping server_ip

# Check SSH port
telnet server_ip 22

# Check HTTP ports
telnet server_ip 80
telnet server_ip 443
```

#### Solution: Check firewall and services
```bash
# Check firewall status
sudo firewall-cmd --list-all

# Open required ports
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload

# Restart services
sudo systemctl restart httpd sshd
```

### DNS Resolution Issues

#### Problem: Domain not resolving
```bash
# Test DNS resolution
dig yourdomain.com
nslookup yourdomain.com

# Check /etc/hosts
cat /etc/hosts

# Test with different DNS
dig @8.8.8.8 yourdomain.com
```

#### Solution: Update DNS settings
```bash
# Update DNS servers
sudo nano /etc/resolv.conf
```

```
nameserver 8.8.8.8
nameserver 8.8.4.4
```

```bash
# Flush DNS cache
sudo systemctl restart NetworkManager
```

## Authentication Issues

### Cannot Login to Application

#### Problem: Login fails with correct credentials
```bash
# Check user in database
mysql -u root -p
USE whm_panel;
SELECT * FROM users WHERE email='user@example.com';

# Check password hash
SELECT password FROM users WHERE email='user@example.com';

# Check session configuration
cat .env | grep SESSION
```

#### Solution: Reset user password
```bash
cd /home/whm.soporteclientes.net/public_html
php artisan tinker
```

```php
$user = App\Models\User::where('email', 'user@example.com')->first();
$user->password = Hash::make('newpassword');
$user->save();
exit
```

### Session Issues

#### Problem: Users logged out frequently
```bash
# Check session driver
cat .env | grep SESSION_DRIVER

# Check session storage
ls -la storage/framework/sessions/

# Check permissions
ls -ld storage/framework/sessions/
```

#### Solution: Fix session configuration
```bash
# Set proper permissions
chmod -R 775 storage/framework/sessions/
chown -R apache:apache storage/framework/sessions/

# Clear sessions
rm -rf storage/framework/sessions/*
php artisan session:clear

# Update session lifetime
nano .env
```

```env
SESSION_DRIVER=file
SESSION_LIFETIME=120
SESSION_ENCRYPT=false
```

## File Permission Issues

### Permission Denied Errors

#### Problem: Application cannot write files
```bash
# Check ownership
ls -la /home/whm.soporteclientes.net/public_html/

# Check SELinux
getenforce
```

#### Solution: Fix permissions
```bash
# Set correct ownership
sudo chown -R apache:apache /home/*/

# Set correct permissions
sudo find /home/*/public_html -type d -exec chmod 755 {} \;
sudo find /home/*/public_html -type f -exec chmod 644 {} \;
sudo chmod -R 775 /home/*/storage
sudo chmod -R 775 /home/*/bootstrap/cache

# If SELinux enabled
sudo semanage fcontext -a -t httpd_sys_rw_content_t "/home/*/storage(/.*)?"
sudo restorecon -R /home/*/storage
```

## Advanced Diagnostics

### System Trace

```bash
# Trace system calls
strace -p <pid> -o trace.log

# Trace Apache process
strace -p $(pgrep httpd | head -1)

# Trace PHP process
strace -p $(pgrep php-fpm | head -1)
```

### Network Packet Analysis

```bash
# Install tcpdump
sudo yum install -y tcpdump

# Capture HTTP traffic
sudo tcpdump -i any port 80 -w http.pcap

# Capture HTTPS traffic
sudo tcpdump -i any port 443 -w https.pcap

# Analyze with tcpdump
sudo tcpdump -r http.pcap
```

### Core Dump Analysis

```bash
# Enable core dumps
ulimit -c unlimited

# Set core pattern
echo "/tmp/core.%e.%p" > /proc/sys/kernel/core_pattern

# Analyze core dump
gdb /usr/sbin/httpd /tmp/core.httpd.12345
```

## Emergency Recovery

### Complete System Restore

```bash
# Stop all services
sudo systemctl stop httpd mariadb php-fpm

# Restore from backup
sudo tar -xzf /backup/files_YYYYMMDD.tar.gz -C /

# Restore database
mysql -u root -p < /backup/mysql_YYYYMMDD.sql

# Fix permissions
sudo chown -R apache:apache /home/*/
sudo chmod -R 775 /home/*/storage

# Restart services
sudo systemctl start mariadb httpd php-fpm

# Verify
systemctl status httpd mariadb php-fpm
```

## Support Resources

- Check logs: Always start with log files
- Documentation: Refer to official documentation
- Community: Laravel, Apache, MySQL communities
- Professional support: Contact system administrators
- Monitoring: Implement proactive monitoring

For more information, see:
- [Monitoring Guide](monitoring.md)
- [Security Best Practices](security.md)
- [Installation Guide](installation.md)
