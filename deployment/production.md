# Production Deployment Guide

Comprehensive guide for deploying the Hosting Management Platform to production environments.

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Pre-deployment Checklist](#pre-deployment-checklist)
4. [Infrastructure Setup](#infrastructure-setup)
5. [Application Deployment](#application-deployment)
6. [Security Hardening](#security-hardening)
7. [SSL/TLS Configuration](#ssltls-configuration)
8. [Performance Optimization](#performance-optimization)
9. [Monitoring Setup](#monitoring-setup)
10. [High Availability Configuration](#high-availability-configuration)
11. [Post-deployment Verification](#post-deployment-verification)
12. [Rollback Procedures](#rollback-procedures)
13. [Best Practices](#best-practices)
14. [Troubleshooting](#troubleshooting)

## Overview

This guide covers the complete deployment process for production environments, including infrastructure setup, security hardening, performance optimization, and monitoring configuration.

### Production Architecture

```
                    ┌─────────────────┐
                    │  Load Balancer  │
                    │    (HAProxy)    │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
        ┌─────▼────┐   ┌────▼─────┐   ┌───▼──────┐
        │  Web 1   │   │  Web 2   │   │  Web 3   │
        │  Apache  │   │  Apache  │   │  Apache  │
        └─────┬────┘   └────┬─────┘   └───┬──────┘
              │              │             │
              └──────────────┼─────────────┘
                             │
                    ┌────────▼────────┐
                    │   Database      │
                    │   Cluster       │
                    │ (Master/Slave)  │
                    └─────────────────┘
```

## Prerequisites

### Hardware Requirements

#### Production Server (Minimum)
- **CPU**: 4 cores (8+ recommended)
- **RAM**: 8GB (16GB+ recommended)
- **Disk**: 100GB SSD (RAID 10 recommended)
- **Network**: 1Gbps connection
- **Redundancy**: Dual power supply, RAID storage

#### High Availability Setup
- **Web Servers**: 3+ nodes
- **Database Servers**: 2+ nodes (master/slave)
- **Load Balancer**: 2 nodes (active/passive)
- **Storage**: Shared storage or distributed filesystem

### Software Requirements
- **OS**: CentOS 8, RHEL 8, AlmaLinux 8, or Ubuntu 20.04 LTS
- **PHP**: 8.1 or higher
- **MySQL**: 8.0+ or MariaDB 10.6+
- **Web Server**: Apache 2.4+ with mod_security or Nginx 1.20+
- **Cache**: Redis 6.0+ or Memcached 1.6+
- **SSL**: Let's Encrypt or commercial certificate
- **Firewall**: firewalld or iptables
- **Monitoring**: Prometheus + Grafana or equivalent

### Network Requirements
- Static IP addresses
- DNS records configured
- SSL certificates ready
- Firewall rules defined
- Load balancer configured
- CDN (optional but recommended)

### Access Requirements
- Root or sudo access
- SSH key authentication
- VPN access (if required)
- Database credentials
- API keys for third-party services
- SSL certificates and private keys

## Pre-deployment Checklist

### Code Preparation
```bash
# 1. Ensure code is in version control
git status
git log -5

# 2. Tag the release
git tag -a v1.0.0 -m "Production release 1.0.0"
git push origin v1.0.0

# 3. Run all tests
./vendor/bin/phpunit
npm run test

# 4. Security audit
composer audit
npm audit

# 5. Code quality check
./vendor/bin/phpstan analyse
./vendor/bin/phpcs
```

### Configuration Review
- [ ] Environment variables configured
- [ ] Database credentials secured
- [ ] API keys stored in secrets management
- [ ] Debug mode disabled
- [ ] Error reporting configured for production
- [ ] Session configuration optimized
- [ ] Cache drivers configured
- [ ] Queue drivers configured
- [ ] Mail configuration tested
- [ ] File upload limits set

### Security Review
- [ ] Firewall rules defined
- [ ] SSL certificates obtained
- [ ] Security headers configured
- [ ] CORS policies defined
- [ ] Rate limiting configured
- [ ] Input validation enabled
- [ ] SQL injection protection active
- [ ] XSS protection enabled
- [ ] CSRF protection enabled
- [ ] File upload restrictions set

### Backup Plan
- [ ] Database backup strategy defined
- [ ] File backup strategy defined
- [ ] Backup retention policy set
- [ ] Restore procedure documented
- [ ] Backup monitoring configured
- [ ] Offsite backup location configured

## Infrastructure Setup

### Step 1: Prepare the Server

```bash
# Update system packages
sudo yum update -y
sudo yum upgrade -y

# Set timezone
sudo timedatectl set-timezone UTC

# Set hostname
sudo hostnamectl set-hostname prod-web-01.yourdomain.com

# Configure hosts file
sudo nano /etc/hosts
```

Add:
```
127.0.0.1   localhost
YOUR_IP     prod-web-01.yourdomain.com prod-web-01
```

### Step 2: Configure Firewall

```bash
# Install and enable firewall
sudo yum install -y firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld

# Allow necessary services
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-service=ssh

# Allow specific ports
sudo firewall-cmd --permanent --add-port=8090/tcp    # Admin panel
sudo firewall-cmd --permanent --add-port=3306/tcp    # MySQL (restrict to DB servers)
sudo firewall-cmd --permanent --add-port=6379/tcp    # Redis

# Allow from specific IPs only
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.1.0/24" port port="3306" protocol="tcp" accept'

# Reload firewall
sudo firewall-cmd --reload

# Verify rules
sudo firewall-cmd --list-all
```

### Step 3: Install Core Dependencies

```bash
# Install EPEL and Remi repositories
sudo yum install -y epel-release
sudo yum install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm

# Enable PHP 8.1
sudo yum module reset php -y
sudo yum module enable php:remi-8.1 -y

# Install PHP and extensions
sudo yum install -y php php-cli php-fpm php-mysqlnd php-pdo \
    php-xml php-json php-mbstring php-bcmath php-gd php-zip \
    php-curl php-opcache php-intl php-redis php-imagick \
    php-soap php-xmlrpc php-memcached

# Install web server
sudo yum install -y httpd mod_ssl mod_security

# Install database
sudo yum install -y mariadb-server mariadb

# Install Redis
sudo yum install -y redis

# Install Node.js 16
curl -sL https://rpm.nodesource.com/setup_16.x | sudo bash -
sudo yum install -y nodejs

# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer

# Install additional tools
sudo yum install -y git unzip wget curl vim htop
```

### Step 4: Configure PHP for Production

```bash
# Backup original configuration
sudo cp /etc/php.ini /etc/php.ini.backup

# Edit PHP configuration
sudo nano /etc/php.ini
```

Key production settings:
```ini
; Security
expose_php = Off
display_errors = Off
display_startup_errors = Off
log_errors = On
error_log = /var/log/php/error.log

; Performance
memory_limit = 512M
max_execution_time = 60
max_input_time = 60
upload_max_filesize = 64M
post_max_size = 64M

; OPcache
opcache.enable = 1
opcache.enable_cli = 0
opcache.memory_consumption = 256
opcache.interned_strings_buffer = 16
opcache.max_accelerated_files = 10000
opcache.revalidate_freq = 2
opcache.fast_shutdown = 1
opcache.validate_timestamps = 0

; Session
session.cookie_httponly = 1
session.cookie_secure = 1
session.cookie_samesite = Strict
session.use_strict_mode = 1
session.gc_maxlifetime = 3600

; Disable dangerous functions
disable_functions = exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,show_source
```

```bash
# Create log directory
sudo mkdir -p /var/log/php
sudo chown apache:apache /var/log/php
```

### Step 5: Configure MariaDB

```bash
# Start MariaDB
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Secure installation
sudo mysql_secure_installation
```

Answer prompts:
- Set root password: Yes (use strong password)
- Remove anonymous users: Yes
- Disallow root login remotely: Yes
- Remove test database: Yes
- Reload privilege tables: Yes

```bash
# Configure MariaDB for production
sudo nano /etc/my.cnf.d/server.cnf
```

Add under `[mysqld]`:
```ini
# Performance
innodb_buffer_pool_size = 4G
innodb_log_file_size = 512M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
max_connections = 500
query_cache_type = 1
query_cache_size = 128M

# Security
bind-address = 127.0.0.1
local-infile = 0
skip-name-resolve

# Logging
slow_query_log = 1
slow_query_log_file = /var/log/mariadb/slow.log
long_query_time = 2
log_error = /var/log/mariadb/error.log

# Character set
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# Binary logging (for replication)
log_bin = /var/log/mariadb/mariadb-bin
server_id = 1
expire_logs_days = 7
```

```bash
# Create log directory
sudo mkdir -p /var/log/mariadb
sudo chown mysql:mysql /var/log/mariadb

# Restart MariaDB
sudo systemctl restart mariadb
```

### Step 6: Configure Redis

```bash
# Edit Redis configuration
sudo nano /etc/redis.conf
```

Key settings:
```
# Network
bind 127.0.0.1
protected-mode yes
port 6379

# Security
requirepass YOUR_STRONG_REDIS_PASSWORD

# Performance
maxmemory 2gb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000

# Persistence
appendonly yes
appendfilename "appendonly.aof"
```

```bash
# Start Redis
sudo systemctl start redis
sudo systemctl enable redis

# Test Redis
redis-cli
> AUTH YOUR_STRONG_REDIS_PASSWORD
> PING
> EXIT
```

## Application Deployment

### Step 1: Create Application Directory Structure

```bash
# Create base directories
sudo mkdir -p /var/www/production/{whm,cpanel,admin}
sudo mkdir -p /var/www/production/shared/{storage,logs}

# Set ownership
sudo chown -R apache:apache /var/www/production
```

### Step 2: Deploy WHM Panel

```bash
# Navigate to directory
cd /var/www/production/whm

# Clone repository (or use deployment key)
sudo -u apache git clone git@github.com:juliobrasa/whm.git .

# Or download specific release
sudo -u apache wget https://github.com/juliobrasa/whm/archive/v1.0.0.tar.gz
sudo -u apache tar -xzf v1.0.0.tar.gz --strip-components=1
sudo -u apache rm v1.0.0.tar.gz

# Install Composer dependencies (production)
sudo -u apache composer install --no-dev --optimize-autoloader --no-interaction

# Create environment file
sudo -u apache cp .env.example .env
sudo -u apache nano .env
```

Production `.env` configuration:
```env
APP_NAME="WHM Panel"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://whm.yourdomain.com

LOG_CHANNEL=daily
LOG_LEVEL=warning
LOG_DAYS=14

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=whm_panel
DB_USERNAME=whm_user
DB_PASSWORD=YOUR_SECURE_PASSWORD

CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=YOUR_REDIS_PASSWORD
REDIS_PORT=6379
REDIS_DB=0

MAIL_MAILER=smtp
MAIL_HOST=smtp.yourdomain.com
MAIL_PORT=587
MAIL_USERNAME=noreply@yourdomain.com
MAIL_PASSWORD=YOUR_MAIL_PASSWORD
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@yourdomain.com
MAIL_FROM_NAME="${APP_NAME}"

SESSION_LIFETIME=120
SESSION_SECURE_COOKIE=true
SESSION_SAME_SITE=strict
```

```bash
# Generate application key
sudo -u apache php artisan key:generate

# Create database and user
mysql -u root -p << 'EOF'
CREATE DATABASE whm_panel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'whm_user'@'localhost' IDENTIFIED BY 'YOUR_SECURE_PASSWORD';
GRANT ALL PRIVILEGES ON whm_panel.* TO 'whm_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Run migrations
sudo -u apache php artisan migrate --force

# Optimize application
sudo -u apache php artisan config:cache
sudo -u apache php artisan route:cache
sudo -u apache php artisan view:cache
sudo -u apache php artisan event:cache

# Set proper permissions
sudo chown -R apache:apache /var/www/production/whm
sudo find /var/www/production/whm -type f -exec chmod 644 {} \;
sudo find /var/www/production/whm -type d -exec chmod 755 {} \;
sudo chmod -R 775 /var/www/production/whm/storage
sudo chmod -R 775 /var/www/production/whm/bootstrap/cache
```

### Step 3: Deploy cPanel System

```bash
# Navigate to directory
cd /var/www/production/cpanel

# Clone or download
sudo -u apache git clone git@github.com:juliobrasa/cpanel.git .

# Install dependencies
sudo -u apache composer install --no-dev --optimize-autoloader --no-interaction
sudo -u apache npm ci --production

# Build assets
sudo -u apache npm run production

# Configure environment
sudo -u apache cp .env.example .env
sudo -u apache nano .env

# Generate key
sudo -u apache php artisan key:generate

# Create database
mysql -u root -p << 'EOF'
CREATE DATABASE cpanel1db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'cpanel_user'@'localhost' IDENTIFIED BY 'YOUR_SECURE_PASSWORD';
GRANT ALL PRIVILEGES ON cpanel1db.* TO 'cpanel_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Run migrations
sudo -u apache php artisan migrate --force

# Optimize
sudo -u apache php artisan config:cache
sudo -u apache php artisan route:cache
sudo -u apache php artisan view:cache

# Set permissions
sudo chown -R apache:apache /var/www/production/cpanel
sudo find /var/www/production/cpanel -type f -exec chmod 644 {} \;
sudo find /var/www/production/cpanel -type d -exec chmod 755 {} \;
sudo chmod -R 775 /var/www/production/cpanel/storage
sudo chmod -R 775 /var/www/production/cpanel/bootstrap/cache
```

### Step 4: Deploy Admin Panel

```bash
# Navigate to directory
cd /var/www/production/admin

# Clone or download
sudo -u apache git clone git@github.com:juliobrasa/admin-panel.git .

# Install dependencies
sudo -u apache composer install --no-dev --optimize-autoloader --no-interaction
sudo -u apache npm ci --production

# Build assets
sudo -u apache npm run production

# Configure environment
sudo -u apache cp .env.example .env
sudo -u apache nano .env

# Generate key
sudo -u apache php artisan key:generate

# Create database
mysql -u root -p << 'EOF'
CREATE DATABASE admindb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'admin_user'@'localhost' IDENTIFIED BY 'YOUR_SECURE_PASSWORD';
GRANT ALL PRIVILEGES ON admindb.* TO 'admin_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Run migrations
sudo -u apache php artisan migrate --force

# Create admin user
sudo -u apache php artisan tinker << 'EOF'
$user = new \App\Models\User;
$user->name = 'Administrator';
$user->email = 'admin@yourdomain.com';
$user->password = Hash::make('CHANGE_THIS_PASSWORD');
$user->email_verified_at = now();
$user->save();
exit
EOF

# Optimize
sudo -u apache php artisan config:cache
sudo -u apache php artisan route:cache
sudo -u apache php artisan view:cache

# Set permissions
sudo chown -R apache:apache /var/www/production/admin
sudo find /var/www/production/admin -type f -exec chmod 644 {} \;
sudo find /var/www/production/admin -type d -exec chmod 755 {} \;
sudo chmod -R 775 /var/www/production/admin/storage
sudo chmod -R 775 /var/www/production/admin/bootstrap/cache
```

## Security Hardening

### Step 1: Configure Apache Security

```bash
# Install mod_security
sudo yum install -y mod_security mod_security_crs

# Configure mod_security
sudo nano /etc/httpd/conf.d/mod_security.conf
```

Add:
```apache
<IfModule mod_security2.c>
    SecRuleEngine On
    SecRequestBodyAccess On
    SecResponseBodyAccess Off
    SecRequestBodyLimit 13107200
    SecRequestBodyNoFilesLimit 131072
    SecRequestBodyInMemoryLimit 131072
    SecDataDir /tmp
    SecTmpDir /tmp
    SecAuditEngine RelevantOnly
    SecAuditLogRelevantStatus "^(?:5|4(?!04))"
    SecAuditLogParts ABIJDEFHZ
    SecAuditLogType Serial
    SecAuditLog /var/log/httpd/modsec_audit.log
    SecDebugLog /var/log/httpd/modsec_debug.log
</IfModule>
```

### Step 2: Configure Security Headers

```bash
# Edit Apache configuration
sudo nano /etc/httpd/conf.d/security.conf
```

Add:
```apache
# Security Headers
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';"

# Remove server information
ServerTokens Prod
ServerSignature Off
Header unset X-Powered-By

# Disable TRACE method
TraceEnable off
```

### Step 3: Configure Fail2Ban

```bash
# Install Fail2Ban
sudo yum install -y fail2ban fail2ban-systemd

# Create local configuration
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local
```

Configure:
```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = admin@yourdomain.com
sendername = Fail2Ban
action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
logpath = /var/log/secure

[apache-auth]
enabled = true
port = http,https
logpath = /var/log/httpd/error_log

[apache-badbots]
enabled = true
port = http,https
logpath = /var/log/httpd/access_log

[apache-noscript]
enabled = true
port = http,https
logpath = /var/log/httpd/error_log

[apache-overflows]
enabled = true
port = http,https
logpath = /var/log/httpd/error_log
maxretry = 2
```

```bash
# Start Fail2Ban
sudo systemctl start fail2ban
sudo systemctl enable fail2ban

# Check status
sudo fail2ban-client status
```

### Step 4: SELinux Configuration

```bash
# Set SELinux to enforcing (if not already)
sudo setenforce 1
sudo sed -i 's/SELINUX=permissive/SELINUX=enforcing/g' /etc/selinux/config

# Set correct context for web directories
sudo semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/production(/.*)?"
sudo restorecon -R /var/www/production

# Allow httpd network connections
sudo setsebool -P httpd_can_network_connect 1
sudo setsebool -P httpd_can_network_connect_db 1
sudo setsebool -P httpd_can_sendmail 1
```

## SSL/TLS Configuration

### Step 1: Install Certbot

```bash
# Install Certbot
sudo yum install -y certbot python3-certbot-apache

# Or for Nginx
# sudo yum install -y certbot python3-certbot-nginx
```

### Step 2: Obtain SSL Certificates

```bash
# Stop Apache temporarily
sudo systemctl stop httpd

# Obtain certificates for all domains
sudo certbot certonly --standalone \
    -d whm.yourdomain.com \
    -d cpanel.yourdomain.com \
    -d admin.yourdomain.com \
    --email admin@yourdomain.com \
    --agree-tos \
    --non-interactive

# Start Apache
sudo systemctl start httpd
```

### Step 3: Configure SSL Virtual Hosts

```bash
# WHM Panel SSL configuration
sudo nano /etc/httpd/conf.d/whm-ssl.conf
```

```apache
<VirtualHost *:443>
    ServerName whm.yourdomain.com
    DocumentRoot /var/www/production/whm/public

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/whm.yourdomain.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/whm.yourdomain.com/privkey.pem

    # Modern SSL configuration
    SSLProtocol -all +TLSv1.2 +TLSv1.3
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder off
    SSLSessionTickets off

    # HSTS (optional but recommended)
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"

    <Directory /var/www/production/whm/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted

        <IfModule mod_rewrite.c>
            RewriteEngine On
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteRule ^ index.php [L]
        </IfModule>
    </Directory>

    ErrorLog /var/log/httpd/whm_ssl_error.log
    CustomLog /var/log/httpd/whm_ssl_access.log combined
</VirtualHost>

# Redirect HTTP to HTTPS
<VirtualHost *:80>
    ServerName whm.yourdomain.com
    Redirect permanent / https://whm.yourdomain.com/
</VirtualHost>
```

Repeat for cPanel and Admin Panel with appropriate paths.

### Step 4: Setup Auto-Renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Create renewal script
sudo nano /etc/cron.d/certbot
```

Add:
```
0 0,12 * * * root certbot renew --quiet --post-hook "systemctl reload httpd"
```

## Performance Optimization

### Step 1: Enable Compression

```bash
# Edit Apache configuration
sudo nano /etc/httpd/conf.d/compression.conf
```

```apache
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css
    AddOutputFilterByType DEFLATE text/javascript application/javascript application/x-javascript
    AddOutputFilterByType DEFLATE application/json application/xml
    AddOutputFilterByType DEFLATE image/svg+xml

    # Don't compress images
    SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png|ico)$ no-gzip
</IfModule>
```

### Step 2: Enable Browser Caching

```bash
# Edit Apache configuration
sudo nano /etc/httpd/conf.d/caching.conf
```

```apache
<IfModule mod_expires.c>
    ExpiresActive On

    # Images
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/gif "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/webp "access plus 1 year"
    ExpiresByType image/svg+xml "access plus 1 year"
    ExpiresByType image/x-icon "access plus 1 year"

    # CSS and JavaScript
    ExpiresByType text/css "access plus 1 month"
    ExpiresByType text/javascript "access plus 1 month"
    ExpiresByType application/javascript "access plus 1 month"

    # Others
    ExpiresByType application/pdf "access plus 1 month"
    ExpiresByType application/x-font-ttf "access plus 1 year"
    ExpiresByType application/x-font-woff "access plus 1 year"
    ExpiresByType application/font-woff "access plus 1 year"
    ExpiresByType application/font-woff2 "access plus 1 year"
</IfModule>
```

### Step 3: Configure Laravel Queue Workers

```bash
# Create systemd service
sudo nano /etc/systemd/system/laravel-queue@.service
```

```ini
[Unit]
Description=Laravel Queue Worker %i
After=network.target redis.service

[Service]
Type=simple
User=apache
Group=apache
Restart=always
RestartSec=3
ExecStart=/usr/bin/php /var/www/production/%i/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start workers for each application
sudo systemctl daemon-reload
sudo systemctl enable laravel-queue@whm
sudo systemctl enable laravel-queue@cpanel
sudo systemctl enable laravel-queue@admin
sudo systemctl start laravel-queue@whm
sudo systemctl start laravel-queue@cpanel
sudo systemctl start laravel-queue@admin

# Check status
sudo systemctl status laravel-queue@whm
```

### Step 4: Setup Laravel Horizon (Optional)

```bash
# Install Horizon in each application
cd /var/www/production/whm
sudo -u apache composer require laravel/horizon

# Publish configuration
sudo -u apache php artisan horizon:install

# Create Horizon service
sudo nano /etc/systemd/system/horizon@.service
```

```ini
[Unit]
Description=Laravel Horizon %i
After=network.target redis.service

[Service]
Type=simple
User=apache
Group=apache
Restart=always
RestartSec=3
ExecStart=/usr/bin/php /var/www/production/%i/artisan horizon
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable horizon@whm
sudo systemctl start horizon@whm
```

## Monitoring Setup

### Step 1: Install Prometheus

```bash
# Create Prometheus user
sudo useradd --no-create-home --shell /bin/false prometheus

# Download and install Prometheus
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.40.0/prometheus-2.40.0.linux-amd64.tar.gz
tar -xzf prometheus-2.40.0.linux-amd64.tar.gz
sudo cp prometheus-2.40.0.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-2.40.0.linux-amd64/promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

# Create directories
sudo mkdir /etc/prometheus /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus /var/lib/prometheus

# Create configuration
sudo nano /etc/prometheus/prometheus.yml
```

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'mysql'
    static_configs:
      - targets: ['localhost:9104']

  - job_name: 'redis'
    static_configs:
      - targets: ['localhost:9121']
```

```bash
# Create systemd service
sudo nano /etc/systemd/system/prometheus.service
```

```ini
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
```

```bash
# Start Prometheus
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
```

### Step 2: Install Node Exporter

```bash
# Download and install
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
tar -xzf node_exporter-1.5.0.linux-amd64.tar.gz
sudo cp node_exporter-1.5.0.linux-amd64/node_exporter /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/node_exporter

# Create systemd service
sudo nano /etc/systemd/system/node_exporter.service
```

```ini
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
```

```bash
# Start Node Exporter
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
```

### Step 3: Setup Application Monitoring

```bash
# Install Laravel metrics package in each application
cd /var/www/production/whm
sudo -u apache composer require spatie/laravel-prometheus

# Publish configuration
sudo -u apache php artisan vendor:publish --provider="Spatie\Prometheus\PrometheusServiceProvider"

# Add route to expose metrics
sudo -u apache nano routes/web.php
```

Add:
```php
Route::get('/metrics', function () {
    return response(app(\Prometheus\CollectorRegistry::class)->getMetricFamilySamples())
        ->header('Content-Type', \Prometheus\RenderTextFormat::MIME_TYPE);
})->middleware('auth:sanctum');
```

## High Availability Configuration

### Load Balancer Setup (HAProxy)

```bash
# Install HAProxy
sudo yum install -y haproxy

# Configure HAProxy
sudo nano /etc/haproxy/haproxy.cfg
```

```
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon
    maxconn 4096

defaults
    log global
    mode http
    option httplog
    option dontlognull
    option forwardfor
    option http-server-close
    timeout connect 5000
    timeout client 50000
    timeout server 50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

frontend http_front
    bind *:80
    redirect scheme https code 301 if !{ ssl_fc }

frontend https_front
    bind *:443 ssl crt /etc/haproxy/certs/

    acl whm_domain hdr(host) -i whm.yourdomain.com
    acl cpanel_domain hdr(host) -i cpanel.yourdomain.com
    acl admin_domain hdr(host) -i admin.yourdomain.com

    use_backend whm_backend if whm_domain
    use_backend cpanel_backend if cpanel_domain
    use_backend admin_backend if admin_domain

backend whm_backend
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200
    server web1 192.168.1.10:80 check
    server web2 192.168.1.11:80 check
    server web3 192.168.1.12:80 check

backend cpanel_backend
    balance roundrobin
    option httpchk GET /health
    server web1 192.168.1.10:80 check
    server web2 192.168.1.11:80 check
    server web3 192.168.1.12:80 check

backend admin_backend
    balance roundrobin
    option httpchk GET /health
    server web1 192.168.1.10:80 check
    server web2 192.168.1.11:80 check
    server web3 192.168.1.12:80 check

listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats auth admin:YOUR_STATS_PASSWORD
```

## Post-deployment Verification

### Step 1: Service Health Checks

```bash
# Check all services
sudo systemctl status httpd
sudo systemctl status mariadb
sudo systemctl status redis
sudo systemctl status laravel-queue@whm
sudo systemctl status laravel-queue@cpanel
sudo systemctl status laravel-queue@admin

# Check logs for errors
sudo tail -f /var/log/httpd/error_log
sudo tail -f /var/www/production/whm/storage/logs/laravel.log
```

### Step 2: Application Testing

```bash
# Test URLs
curl -I https://whm.yourdomain.com
curl -I https://cpanel.yourdomain.com
curl -I https://admin.yourdomain.com

# Test SSL
openssl s_client -connect whm.yourdomain.com:443 -servername whm.yourdomain.com

# Test database connections
mysql -u whm_user -p whm_panel -e "SELECT 1"
mysql -u cpanel_user -p cpanel1db -e "SELECT 1"
mysql -u admin_user -p admindb -e "SELECT 1"

# Test Redis
redis-cli -a YOUR_REDIS_PASSWORD PING
```

### Step 3: Performance Testing

```bash
# Install Apache Bench
sudo yum install -y httpd-tools

# Run load test
ab -n 1000 -c 10 https://whm.yourdomain.com/

# Or use wrk for more advanced testing
sudo yum install -y gcc make
git clone https://github.com/wg/wrk.git
cd wrk
make
sudo cp wrk /usr/local/bin/

# Run test
wrk -t12 -c400 -d30s https://whm.yourdomain.com/
```

## Rollback Procedures

### Database Rollback

```bash
# Restore database from backup
mysql -u root -p whm_panel < /backup/whm_panel_20231023.sql

# Or using mysqldump with specific date
mysql -u root -p whm_panel < /backup/whm_panel_$(date +%Y%m%d).sql
```

### Application Rollback

```bash
# Navigate to application
cd /var/www/production/whm

# Checkout previous version
sudo -u apache git checkout v1.0.0

# Or restore from backup
sudo tar -xzf /backup/whm_20231023.tar.gz -C /var/www/production/whm

# Reinstall dependencies
sudo -u apache composer install --no-dev --optimize-autoloader

# Run migrations down if needed
sudo -u apache php artisan migrate:rollback

# Clear and rebuild caches
sudo -u apache php artisan cache:clear
sudo -u apache php artisan config:cache
sudo -u apache php artisan route:cache
sudo -u apache php artisan view:cache

# Restart services
sudo systemctl restart httpd
sudo systemctl restart laravel-queue@whm
```

## Best Practices

### 1. Deployment Automation

```bash
# Create deployment script
sudo nano /usr/local/bin/deploy.sh
```

```bash
#!/bin/bash
set -e

APP=$1
VERSION=$2

if [ -z "$APP" ] || [ -z "$VERSION" ]; then
    echo "Usage: deploy.sh <app> <version>"
    exit 1
fi

APP_DIR="/var/www/production/$APP"
BACKUP_DIR="/backup/deployments"

# Create backup
echo "Creating backup..."
tar -czf "$BACKUP_DIR/${APP}_$(date +%Y%m%d_%H%M%S).tar.gz" "$APP_DIR"

# Enter maintenance mode
cd "$APP_DIR"
sudo -u apache php artisan down

# Pull new code
sudo -u apache git fetch
sudo -u apache git checkout "$VERSION"

# Install dependencies
sudo -u apache composer install --no-dev --optimize-autoloader

# Run migrations
sudo -u apache php artisan migrate --force

# Clear and rebuild caches
sudo -u apache php artisan cache:clear
sudo -u apache php artisan config:cache
sudo -u apache php artisan route:cache
sudo -u apache php artisan view:cache

# Restart workers
sudo systemctl restart laravel-queue@$APP

# Exit maintenance mode
sudo -u apache php artisan up

echo "Deployment complete!"
```

### 2. Health Check Endpoints

Add to each Laravel application:

```php
// routes/web.php
Route::get('/health', function () {
    $checks = [
        'database' => false,
        'redis' => false,
        'storage' => false,
    ];

    try {
        DB::connection()->getPdo();
        $checks['database'] = true;
    } catch (\Exception $e) {}

    try {
        Redis::ping();
        $checks['redis'] = true;
    } catch (\Exception $e) {}

    $checks['storage'] = is_writable(storage_path());

    $healthy = !in_array(false, $checks);

    return response()->json([
        'status' => $healthy ? 'healthy' : 'unhealthy',
        'checks' => $checks,
    ], $healthy ? 200 : 503);
});
```

### 3. Logging Strategy

```bash
# Configure logrotate
sudo nano /etc/logrotate.d/laravel
```

```
/var/www/production/*/storage/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 apache apache
    sharedscripts
    postrotate
        /bin/systemctl reload httpd > /dev/null 2>/dev/null || true
    endscript
}
```

## Troubleshooting

### Common Issues

#### 1. 500 Internal Server Error

```bash
# Check Apache logs
sudo tail -100 /var/log/httpd/error_log

# Check Laravel logs
sudo tail -100 /var/www/production/whm/storage/logs/laravel.log

# Check permissions
sudo find /var/www/production/whm -type d -exec chmod 755 {} \;
sudo find /var/www/production/whm -type f -exec chmod 644 {} \;
sudo chmod -R 775 /var/www/production/whm/storage
sudo chmod -R 775 /var/www/production/whm/bootstrap/cache

# Clear caches
cd /var/www/production/whm
sudo -u apache php artisan cache:clear
sudo -u apache php artisan config:clear
sudo -u apache php artisan view:clear
```

#### 2. Database Connection Issues

```bash
# Test connection
mysql -u whm_user -p -h 127.0.0.1 whm_panel

# Check if MySQL is running
sudo systemctl status mariadb

# Check MySQL logs
sudo tail -100 /var/log/mariadb/error.log

# Verify .env database credentials
cd /var/www/production/whm
cat .env | grep DB_
```

#### 3. Queue Workers Not Processing

```bash
# Check worker status
sudo systemctl status laravel-queue@whm

# Check worker logs
sudo journalctl -u laravel-queue@whm -n 100

# Restart workers
sudo systemctl restart laravel-queue@whm

# Check Redis connection
redis-cli -a YOUR_REDIS_PASSWORD PING
redis-cli -a YOUR_REDIS_PASSWORD LLEN queues:default
```

#### 4. SSL Certificate Issues

```bash
# Check certificate expiry
sudo certbot certificates

# Test renewal
sudo certbot renew --dry-run

# Force renewal
sudo certbot renew --force-renewal

# Check Apache SSL configuration
sudo apachectl -t -D DUMP_VHOSTS
```

#### 5. High Memory Usage

```bash
# Check memory usage
free -h
top

# Check for memory leaks
ps aux --sort=-%mem | head -10

# Optimize OPcache
sudo nano /etc/php.ini
# Adjust opcache.memory_consumption

# Restart services
sudo systemctl restart httpd
sudo systemctl restart php-fpm
```

---

**Next Steps:**
- [Docker Deployment Guide](docker.md)
- [Scaling Guide](scaling.md)
- [Backup and Recovery Guide](backup.md)
