# SSL Configuration Guide

Comprehensive guide for SSL/TLS certificate installation, configuration, and management for the Hosting Management Platform.

## Table of Contents
1. [Overview](#overview)
2. [SSL/TLS Basics](#ssltls-basics)
3. [Certificate Types](#certificate-types)
4. [Installing Certbot](#installing-certbot)
5. [Obtaining SSL Certificates](#obtaining-ssl-certificates)
6. [Apache SSL Configuration](#apache-ssl-configuration)
7. [Nginx SSL Configuration](#nginx-ssl-configuration)
8. [SSL Best Practices](#ssl-best-practices)
9. [Certificate Renewal](#certificate-renewal)
10. [Wildcard Certificates](#wildcard-certificates)
11. [Troubleshooting SSL](#troubleshooting-ssl)
12. [SSL Testing and Validation](#ssl-testing-and-validation)

## Overview

SSL/TLS certificates are essential for securing web traffic, encrypting data transmission, and establishing trust with users. This guide covers complete SSL implementation for your hosting platform.

### Why SSL is Important
- **Data Encryption**: Protects sensitive information in transit
- **Authentication**: Verifies server identity
- **Trust**: Builds user confidence
- **SEO Benefits**: Search engines favor HTTPS sites
- **Compliance**: Required for many regulations (PCI DSS, HIPAA)
- **Browser Requirements**: Modern browsers warn about non-HTTPS sites

### What You'll Learn
- How to obtain free SSL certificates with Let's Encrypt
- Configure Apache/Nginx for SSL
- Implement SSL best practices
- Automate certificate renewal
- Troubleshoot SSL issues

## SSL/TLS Basics

### Understanding SSL/TLS
- **SSL (Secure Sockets Layer)**: Deprecated protocol (SSL 2.0, 3.0)
- **TLS (Transport Layer Security)**: Current standard (TLS 1.2, 1.3)
- **HTTPS**: HTTP over SSL/TLS (port 443)

### How SSL Works
1. Client initiates connection to server
2. Server presents SSL certificate
3. Client validates certificate
4. Handshake establishes encrypted connection
5. Data transmitted securely

### SSL Certificate Components
- **Certificate (.crt)**: Public key and identity information
- **Private Key (.key)**: Private key for encryption
- **Certificate Chain**: Intermediate certificates
- **Root Certificate**: Trusted root CA certificate

### Certificate Validation Levels

#### Domain Validation (DV)
- Verifies domain ownership only
- Issued quickly (minutes)
- Free with Let's Encrypt
- Suitable for most websites

#### Organization Validation (OV)
- Verifies organization identity
- Manual verification process
- Shows organization name
- Better for business sites

#### Extended Validation (EV)
- Highest validation level
- Extensive verification
- Shows green address bar
- Best for e-commerce

## Certificate Types

### Let's Encrypt (Recommended)
```bash
# Features
- Free certificates
- Automated issuance
- 90-day validity
- Automated renewal
- Wildcard support
- Trusted by all major browsers
```

### Commercial SSL Providers
- Comodo/Sectigo
- DigiCert
- GlobalSign
- GeoTrust
- Thawte

### Self-Signed Certificates (Development Only)
```bash
# Create self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/pki/tls/private/selfsigned.key \
    -out /etc/pki/tls/certs/selfsigned.crt

# Note: Not trusted by browsers, use only for testing
```

## Installing Certbot

### CentOS/RHEL 7/8

#### Install EPEL Repository
```bash
# Install EPEL
sudo yum install -y epel-release

# Update packages
sudo yum update -y
```

#### Install Certbot
```bash
# Install Certbot for Apache
sudo yum install -y certbot python3-certbot-apache

# Or for Nginx
sudo yum install -y certbot python3-certbot-nginx

# Verify installation
certbot --version
```

### Alternative: Install with Snapd
```bash
# Install snapd
sudo yum install -y snapd
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap

# Wait for snapd to initialize
sleep 10

# Install certbot
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

# Verify
certbot --version
```

## Obtaining SSL Certificates

### Prerequisites
```bash
# 1. Ensure domain points to your server
dig +short yourdomain.com
# Should return your server IP

# 2. Ensure Apache/Nginx is running
sudo systemctl status httpd
# or
sudo systemctl status nginx

# 3. Ensure port 80 is open
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload

# 4. Ensure no conflicting virtual hosts
sudo apachectl configtest
```

### Single Domain Certificate

#### Using Apache Plugin
```bash
# Obtain and install certificate automatically
sudo certbot --apache -d whm.soporteclientes.net

# Interactive prompts:
# 1. Enter email address
# 2. Agree to Terms of Service
# 3. Choose to redirect HTTP to HTTPS (recommended)
```

#### Using Webroot Plugin
```bash
# If you prefer manual configuration
sudo certbot certonly --webroot \
    -w /home/whm.soporteclientes.net/public_html/public \
    -d whm.soporteclientes.net

# Certificate files will be saved to:
# /etc/letsencrypt/live/whm.soporteclientes.net/
```

#### Using Standalone Mode
```bash
# Stop web server temporarily
sudo systemctl stop httpd

# Obtain certificate
sudo certbot certonly --standalone -d whm.soporteclientes.net

# Start web server
sudo systemctl start httpd
```

### Multiple Domain Certificates

#### Multiple Domains on One Certificate
```bash
sudo certbot --apache \
    -d whm.soporteclientes.net \
    -d cpanel1.soporteclientes.net \
    -d admin.soporteclientes.net
```

#### Separate Certificates per Domain
```bash
# WHM Panel
sudo certbot --apache -d whm.soporteclientes.net

# cPanel System
sudo certbot --apache -d cpanel1.soporteclientes.net

# Admin Panel
sudo certbot --apache -d admin.soporteclientes.net
```

### Certificate Locations

After successful installation:
```bash
# Certificate files location
/etc/letsencrypt/live/yourdomain.com/
├── cert.pem          # Domain certificate
├── chain.pem         # Intermediate certificates
├── fullchain.pem     # cert.pem + chain.pem
├── privkey.pem       # Private key
└── README            # Information file

# All certificates
ls -la /etc/letsencrypt/live/

# Renewal configuration
ls -la /etc/letsencrypt/renewal/
```

## Apache SSL Configuration

### Automatic Configuration
```bash
# Certbot automatically configures Apache
sudo certbot --apache -d whm.soporteclientes.net

# This creates/modifies SSL virtual host configuration
```

### Manual Configuration

#### Create SSL Virtual Host
```bash
sudo nano /etc/httpd/conf.d/whm-ssl.conf
```

```apache
<VirtualHost *:443>
    ServerName whm.soporteclientes.net
    DocumentRoot /home/whm.soporteclientes.net/public_html/public

    # SSL Configuration
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/whm.soporteclientes.net/cert.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/whm.soporteclientes.net/privkey.pem
    SSLCertificateChainFile /etc/letsencrypt/live/whm.soporteclientes.net/chain.pem

    # Modern SSL Configuration
    SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder off
    SSLSessionTickets off

    # HSTS (optional, 1 year)
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"

    # OCSP Stapling
    SSLUseStapling on
    SSLStaplingCache "shmcb:logs/ssl_stapling(32768)"

    <Directory /home/whm.soporteclientes.net/public_html/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/httpd/whm_ssl_error.log
    CustomLog /var/log/httpd/whm_ssl_access.log combined
</VirtualHost>
```

#### HTTP to HTTPS Redirect
```bash
sudo nano /etc/httpd/conf.d/whm.conf
```

```apache
<VirtualHost *:80>
    ServerName whm.soporteclientes.net

    # Redirect all HTTP to HTTPS
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>
```

#### Global SSL Configuration
```bash
sudo nano /etc/httpd/conf.d/ssl.conf
```

```apache
# Modern configuration
SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
SSLHonorCipherOrder off
SSLSessionTickets off

# OCSP Stapling
SSLUseStapling on
SSLStaplingCache "shmcb:logs/ssl_stapling(32768)"

# Disable compression (CRIME attack)
SSLCompression off

# Online Certificate Status Protocol
SSLStaplingResponderTimeout 5
SSLStaplingReturnResponderErrors off
```

#### Test and Reload
```bash
# Test Apache configuration
sudo apachectl configtest

# Reload Apache
sudo systemctl reload httpd

# Verify SSL is working
curl -I https://whm.soporteclientes.net
```

## Nginx SSL Configuration

### Automatic Configuration
```bash
# Certbot automatically configures Nginx
sudo certbot --nginx -d whm.soporteclientes.net
```

### Manual Configuration
```bash
sudo nano /etc/nginx/conf.d/whm-ssl.conf
```

```nginx
# HTTP server - redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name whm.soporteclientes.net;

    # Redirect all HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name whm.soporteclientes.net;

    root /home/whm.soporteclientes.net/public_html/public;
    index index.php index.html;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/whm.soporteclientes.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/whm.soporteclientes.net/privkey.pem;

    # SSL Protocols and Ciphers
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # SSL Session
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;

    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/whm.soporteclientes.net/chain.pem;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Laravel configuration
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    access_log /var/log/nginx/whm_ssl_access.log;
    error_log /var/log/nginx/whm_ssl_error.log;
}
```

```bash
# Test Nginx configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

## SSL Best Practices

### Security Configuration

#### Disable Old Protocols
```apache
# Apache
SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
```

```nginx
# Nginx
ssl_protocols TLSv1.2 TLSv1.3;
```

#### Use Strong Ciphers
```apache
# Apache - Mozilla Modern Configuration
SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
SSLHonorCipherOrder off
```

```nginx
# Nginx - Mozilla Modern Configuration
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;
```

#### Enable HSTS
```apache
# Apache
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
```

```nginx
# Nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
```

#### Enable OCSP Stapling
```apache
# Apache
SSLUseStapling on
SSLStaplingCache "shmcb:logs/ssl_stapling(32768)"
SSLStaplingResponderTimeout 5
```

```nginx
# Nginx
ssl_stapling on;
ssl_stapling_verify on;
ssl_trusted_certificate /etc/letsencrypt/live/domain.com/chain.pem;
resolver 8.8.8.8 8.8.4.4 valid=300s;
```

#### Disable SSL Compression
```apache
# Apache
SSLCompression off
```

```nginx
# Nginx
ssl_compression off;
```

### Performance Optimization

#### SSL Session Caching
```apache
# Apache
SSLSessionCache "shmcb:/var/cache/mod_ssl/scache(512000)"
SSLSessionCacheTimeout 300
```

```nginx
# Nginx
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
```

#### HTTP/2 Support
```apache
# Apache (mod_http2 required)
Protocols h2 http/1.1
```

```nginx
# Nginx
listen 443 ssl http2;
```

### Security Headers

```apache
# Apache
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
```

```nginx
# Nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

## Certificate Renewal

### Automatic Renewal

#### Test Renewal
```bash
# Dry run test
sudo certbot renew --dry-run

# This tests the renewal process without actually renewing
```

#### Setup Auto-Renewal with Cron
```bash
# Certbot installs a cron job automatically
# Verify it exists
ls -la /etc/cron.d/certbot

# Or check crontab
cat /etc/cron.d/certbot
```

#### Manual Cron Setup
```bash
# Edit crontab
sudo crontab -e

# Add renewal job (runs twice daily)
0 0,12 * * * /usr/bin/certbot renew --quiet --post-hook "systemctl reload httpd"
```

#### Setup with systemd Timer
```bash
# Create systemd service
sudo nano /etc/systemd/system/certbot-renewal.service
```

```ini
[Unit]
Description=Let's Encrypt renewal
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/certbot renew --quiet --post-hook "systemctl reload httpd"
```

```bash
# Create systemd timer
sudo nano /etc/systemd/system/certbot-renewal.timer
```

```ini
[Unit]
Description=Twice daily renewal of Let's Encrypt certificates
After=network-online.target

[Timer]
OnCalendar=0/12:00:00
RandomizedDelaySec=1h
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
# Enable and start timer
sudo systemctl enable certbot-renewal.timer
sudo systemctl start certbot-renewal.timer

# Check timer status
sudo systemctl list-timers | grep certbot
```

### Manual Renewal

```bash
# Renew all certificates
sudo certbot renew

# Force renewal (even if not due)
sudo certbot renew --force-renewal

# Renew specific certificate
sudo certbot renew --cert-name whm.soporteclientes.net

# Reload web server after renewal
sudo systemctl reload httpd
```

### Renewal Hooks

```bash
# Create pre-hook script
sudo nano /etc/letsencrypt/renewal-hooks/pre/stop-services.sh
```

```bash
#!/bin/bash
# Stop services before renewal if needed
# systemctl stop some-service
```

```bash
# Create post-hook script
sudo nano /etc/letsencrypt/renewal-hooks/post/reload-services.sh
```

```bash
#!/bin/bash
# Reload web server after renewal
systemctl reload httpd

# Restart other services if needed
# systemctl restart postfix
```

```bash
# Make executable
sudo chmod +x /etc/letsencrypt/renewal-hooks/pre/*.sh
sudo chmod +x /etc/letsencrypt/renewal-hooks/post/*.sh
```

### Monitor Certificate Expiration

```bash
# Check certificate expiration
sudo certbot certificates

# Create monitoring script
sudo nano /usr/local/bin/check_ssl_expiry.sh
```

```bash
#!/bin/bash

ALERT_EMAIL="admin@example.com"
ALERT_DAYS=30

for cert in /etc/letsencrypt/live/*/cert.pem; do
    domain=$(basename $(dirname $cert))
    expiry=$(openssl x509 -enddate -noout -in $cert | cut -d= -f2)
    expiry_epoch=$(date -d "$expiry" +%s)
    now_epoch=$(date +%s)
    days_left=$(( ($expiry_epoch - $now_epoch) / 86400 ))

    if [ $days_left -lt $ALERT_DAYS ]; then
        echo "WARNING: SSL certificate for $domain expires in $days_left days!" | \
            mail -s "SSL Certificate Expiring: $domain" $ALERT_EMAIL
    fi

    echo "$domain: $days_left days until expiry"
done
```

```bash
chmod +x /usr/local/bin/check_ssl_expiry.sh
echo "0 9 * * * /usr/local/bin/check_ssl_expiry.sh" | sudo tee -a /etc/crontab
```

## Wildcard Certificates

### Prerequisites
```bash
# Wildcard certificates require DNS validation
# You need API access to your DNS provider

# Install DNS plugin (example for Cloudflare)
sudo yum install -y python3-certbot-dns-cloudflare

# Other plugins available:
# - certbot-dns-route53 (AWS Route 53)
# - certbot-dns-google (Google Cloud DNS)
# - certbot-dns-digitalocean
# - certbot-dns-ovh
```

### Cloudflare DNS Validation

```bash
# Create credentials file
sudo mkdir -p /root/.secrets
sudo nano /root/.secrets/cloudflare.ini
```

```ini
dns_cloudflare_api_token = your_cloudflare_api_token
```

```bash
sudo chmod 600 /root/.secrets/cloudflare.ini
```

### Obtain Wildcard Certificate

```bash
# Request wildcard certificate
sudo certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials /root/.secrets/cloudflare.ini \
    -d soporteclientes.net \
    -d '*.soporteclientes.net'

# This will obtain a certificate valid for:
# - soporteclientes.net
# - *.soporteclientes.net (all subdomains)
```

### Manual DNS Validation

```bash
# If no DNS plugin available
sudo certbot certonly --manual --preferred-challenges dns -d '*.soporteclientes.net'

# Follow prompts to add TXT record to DNS
# Record name: _acme-challenge.soporteclientes.net
# Record value: (provided by certbot)

# Verify DNS record before continuing
dig +short TXT _acme-challenge.soporteclientes.net

# Press Enter in certbot to continue validation
```

## Troubleshooting SSL

### Common Issues

#### Certificate Not Trusted

**Problem**: Browser shows "Not Secure" or certificate warning

**Check**:
```bash
# Verify certificate chain
openssl s_client -connect yourdomain.com:443 -showcerts

# Check certificate dates
echo | openssl s_client -connect yourdomain.com:443 2>/dev/null | \
    openssl x509 -noout -dates

# Verify certificate matches domain
echo | openssl s_client -connect yourdomain.com:443 2>/dev/null | \
    openssl x509 -noout -text | grep DNS
```

**Solution**:
```bash
# Ensure fullchain.pem is used
# Apache
SSLCertificateFile /etc/letsencrypt/live/domain/cert.pem
SSLCertificateChainFile /etc/letsencrypt/live/domain/chain.pem

# Or use fullchain
SSLCertificateFile /etc/letsencrypt/live/domain/fullchain.pem

# Nginx (always use fullchain)
ssl_certificate /etc/letsencrypt/live/domain/fullchain.pem;
```

#### Mixed Content Warnings

**Problem**: HTTPS site loading HTTP resources

**Check**:
```bash
# Search for HTTP URLs in code
grep -r "http://" /home/*/public_html/resources/

# Check .env file
cat /home/*/public_html/.env | grep APP_URL
```

**Solution**:
```bash
# Update .env
nano .env
```

```env
APP_URL=https://yourdomain.com
```

```bash
# Add to .htaccess or Apache config
Header always set Content-Security-Policy "upgrade-insecure-requests"

# Force HTTPS in Laravel
# Add to App\Providers\AppServiceProvider
if ($this->app->environment('production')) {
    \URL::forceScheme('https');
}
```

#### Certificate Renewal Fails

**Problem**: Certbot renewal fails

**Check**:
```bash
# Test renewal with verbose output
sudo certbot renew --dry-run --verbose

# Check certbot logs
sudo tail -50 /var/log/letsencrypt/letsencrypt.log

# Verify domain resolves to server
dig +short yourdomain.com
```

**Solution**:
```bash
# Ensure port 80 is accessible
sudo firewall-cmd --list-all

# Check Apache is running
sudo systemctl status httpd

# Verify .well-known directory is accessible
curl http://yourdomain.com/.well-known/

# Manually renew
sudo certbot renew --force-renewal
```

#### Port 443 Not Working

**Problem**: Cannot access HTTPS site

**Check**:
```bash
# Test port 443
telnet yourdomain.com 443
nc -zv yourdomain.com 443

# Check firewall
sudo firewall-cmd --list-all

# Check Apache is listening
sudo netstat -tlnp | grep :443
```

**Solution**:
```bash
# Open port 443
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# Ensure SSL module loaded
httpd -M | grep ssl

# Restart Apache
sudo systemctl restart httpd
```

#### Private Key Permissions

**Problem**: Apache fails to start with SSL

**Check**:
```bash
# Check Apache error log
sudo tail -50 /var/log/httpd/error_log

# Check private key permissions
sudo ls -la /etc/letsencrypt/live/*/privkey.pem
```

**Solution**:
```bash
# Fix permissions (if needed)
sudo chmod 600 /etc/letsencrypt/archive/*/privkey*.pem
sudo chown root:root /etc/letsencrypt/archive/*/privkey*.pem

# Verify Apache user can read certificates
sudo -u apache cat /etc/letsencrypt/live/domain/privkey.pem
```

## SSL Testing and Validation

### Online SSL Testing

#### SSL Labs Test
```bash
# Test your SSL configuration
# Visit: https://www.ssllabs.com/ssltest/
# Enter your domain and analyze

# Aim for A+ rating
```

#### SecurityHeaders.com
```bash
# Test security headers
# Visit: https://securityheaders.com/
# Enter your domain

# Aim for A+ rating
```

### Command Line Testing

#### Test SSL Connection
```bash
# Basic SSL test
openssl s_client -connect yourdomain.com:443

# Test specific protocol
openssl s_client -connect yourdomain.com:443 -tls1_2
openssl s_client -connect yourdomain.com:443 -tls1_3

# Test old protocols (should fail)
openssl s_client -connect yourdomain.com:443 -ssl3
openssl s_client -connect yourdomain.com:443 -tls1
openssl s_client -connect yourdomain.com:443 -tls1_1
```

#### Check Certificate Details
```bash
# View certificate
echo | openssl s_client -connect yourdomain.com:443 2>/dev/null | \
    openssl x509 -text

# Check expiration date
echo | openssl s_client -connect yourdomain.com:443 2>/dev/null | \
    openssl x509 -noout -dates

# Check issuer
echo | openssl s_client -connect yourdomain.com:443 2>/dev/null | \
    openssl x509 -noout -issuer

# Check subject
echo | openssl s_client -connect yourdomain.com:443 2>/dev/null | \
    openssl x509 -noout -subject
```

#### Test Cipher Suites
```bash
# Test supported ciphers
nmap --script ssl-enum-ciphers -p 443 yourdomain.com

# Test specific cipher
openssl s_client -connect yourdomain.com:443 -cipher 'ECDHE-RSA-AES128-GCM-SHA256'
```

#### Verify OCSP Stapling
```bash
echo | openssl s_client -connect yourdomain.com:443 -status 2>/dev/null | \
    grep -A 17 'OCSP response:'
```

#### Check HTTP/2 Support
```bash
curl -I --http2 https://yourdomain.com
```

### Automated Testing Script

```bash
sudo nano /usr/local/bin/test_ssl.sh
```

```bash
#!/bin/bash

DOMAIN=$1

if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 domain.com"
    exit 1
fi

echo "================================"
echo "SSL Test for $DOMAIN"
echo "================================"

# Certificate expiration
echo -e "\n[Certificate Expiration]"
echo | openssl s_client -connect $DOMAIN:443 2>/dev/null | \
    openssl x509 -noout -dates

# Certificate issuer
echo -e "\n[Certificate Issuer]"
echo | openssl s_client -connect $DOMAIN:443 2>/dev/null | \
    openssl x509 -noout -issuer

# Supported protocols
echo -e "\n[Supported Protocols]"
for proto in ssl3 tls1 tls1_1 tls1_2 tls1_3; do
    result=$(echo | timeout 2 openssl s_client -connect $DOMAIN:443 -$proto 2>&1)
    if echo "$result" | grep -q "Protocol"; then
        echo "$proto: ENABLED"
    else
        echo "$proto: DISABLED"
    fi
done

# OCSP Stapling
echo -e "\n[OCSP Stapling]"
echo | openssl s_client -connect $DOMAIN:443 -status 2>/dev/null | \
    grep -q "OCSP Response Status: successful" && \
    echo "OCSP Stapling: ENABLED" || echo "OCSP Stapling: DISABLED"

# HTTP/2
echo -e "\n[HTTP/2 Support]"
curl -sI --http2 https://$DOMAIN | grep -q "HTTP/2" && \
    echo "HTTP/2: ENABLED" || echo "HTTP/2: DISABLED"

echo -e "\n================================"
echo "Test completed!"
echo "================================"
```

```bash
chmod +x /usr/local/bin/test_ssl.sh

# Run test
/usr/local/bin/test_ssl.sh yourdomain.com
```

## Best Practices Checklist

### Initial Setup
- [ ] Install certbot
- [ ] Obtain SSL certificates
- [ ] Configure web server for SSL
- [ ] Enable HTTPS redirect
- [ ] Test certificate installation

### Security Configuration
- [ ] Disable SSLv2, SSLv3, TLS 1.0, TLS 1.1
- [ ] Enable only TLS 1.2 and 1.3
- [ ] Use strong cipher suites
- [ ] Enable HSTS
- [ ] Enable OCSP stapling
- [ ] Disable SSL compression
- [ ] Add security headers

### Renewal and Maintenance
- [ ] Setup automatic renewal
- [ ] Test renewal process
- [ ] Monitor certificate expiration
- [ ] Configure renewal hooks
- [ ] Test renewal notifications

### Testing and Validation
- [ ] Test SSL configuration
- [ ] Check SSL Labs rating (aim for A+)
- [ ] Verify HSTS headers
- [ ] Test HTTP to HTTPS redirect
- [ ] Check mixed content
- [ ] Verify OCSP stapling
- [ ] Test HTTP/2 support

## Next Steps

- Configure firewall rules: See [Firewall Setup Guide](firewall.md)
- Implement security headers: See [Security Best Practices](security.md)
- Setup monitoring: See [Monitoring Guide](monitoring.md)
- Enable HTTP/2 and performance optimization
- Consider CDN for additional security and performance

For more information, see:
- [Security Best Practices](security.md)
- [Firewall Setup Guide](firewall.md)
- [Apache Documentation](https://httpd.apache.org/docs/2.4/ssl/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
