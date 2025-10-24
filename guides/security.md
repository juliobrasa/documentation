# Security Best Practices

Comprehensive security guide for the Hosting Management Platform covering system hardening, application security, and compliance.

## Table of Contents
1. [Overview](#overview)
2. [System Security](#system-security)
3. [Web Server Security](#web-server-security)
4. [Application Security](#application-security)
5. [Database Security](#database-security)
6. [Network Security](#network-security)
7. [Access Control](#access-control)
8. [Data Protection](#data-protection)
9. [Monitoring and Auditing](#monitoring-and-auditing)
10. [Incident Response](#incident-response)
11. [Compliance](#compliance)
12. [Security Checklist](#security-checklist)

## Overview

Security is paramount for hosting management platforms. This guide provides comprehensive security measures to protect your infrastructure, data, and users.

### Security Principles
- **Defense in Depth**: Multiple layers of security
- **Least Privilege**: Minimum necessary permissions
- **Secure by Default**: Start with secure configurations
- **Regular Updates**: Keep systems patched
- **Monitoring**: Continuous security monitoring
- **Incident Response**: Prepared for security events

### Threat Landscape
- Unauthorized access attempts
- SQL injection attacks
- Cross-site scripting (XSS)
- DDoS attacks
- Data breaches
- Malware and ransomware
- Social engineering

## System Security

### Operating System Hardening

#### Update System Regularly
```bash
# Enable automatic security updates
sudo yum install -y yum-cron

# Configure yum-cron
sudo nano /etc/yum/yum-cron.conf
```

```ini
[commands]
update_cmd = security
apply_updates = yes
```

```bash
sudo systemctl enable yum-cron
sudo systemctl start yum-cron

# Manual updates
sudo yum update -y --security
```

#### Disable Unnecessary Services
```bash
# List all services
systemctl list-unit-files --type=service

# Disable unnecessary services
sudo systemctl disable bluetooth.service
sudo systemctl disable cups.service
sudo systemctl disable avahi-daemon.service

# Stop and mask unused services
sudo systemctl stop service_name
sudo systemctl mask service_name
```

#### Configure SELinux

```bash
# Check SELinux status
getenforce

# Enable SELinux
sudo nano /etc/selinux/config
```

```conf
SELINUX=enforcing
SELINUXTYPE=targeted
```

```bash
# Set proper contexts
sudo semanage fcontext -a -t httpd_sys_content_t "/home/*/public_html(/.*)?"
sudo semanage fcontext -a -t httpd_sys_rw_content_t "/home/*/storage(/.*)?"
sudo restorecon -Rv /home/*/

# Allow Apache to connect to network
sudo setsebool -P httpd_can_network_connect 1
sudo setsebool -P httpd_can_network_connect_db 1

# Check SELinux denials
sudo ausearch -m avc -ts recent
```

#### Kernel Security Parameters

```bash
sudo nano /etc/sysctl.d/99-security.conf
```

```conf
# IP Forwarding
net.ipv4.ip_forward = 0

# SYN Cookies
net.ipv4.tcp_syncookies = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Ignore source routed packets
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Ignore ICMP ping requests
net.ipv4.icmp_echo_ignore_all = 1

# Disable packet forwarding
net.ipv4.conf.all.forwarding = 0
net.ipv6.conf.all.forwarding = 0

# Enable IP spoofing protection
net.ipv4.conf.all.rp_filter = 1

# Log suspicious packets
net.ipv4.conf.all.log_martians = 1

# Disable IPv6 (if not used)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
```

```bash
# Apply changes
sudo sysctl -p /etc/sysctl.d/99-security.conf
```

### User Account Security

#### Password Policies
```bash
# Install password quality checking
sudo yum install -y libpwquality

# Configure password requirements
sudo nano /etc/security/pwquality.conf
```

```conf
minlen = 14
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
maxrepeat = 3
usercheck = 1
```

#### Account Lockout Policy
```bash
sudo nano /etc/pam.d/system-auth
```

Add before first auth line:
```
auth required pam_faillock.so preauth silent audit deny=5 unlock_time=900
auth [default=die] pam_faillock.so authfail audit deny=5 unlock_time=900
account required pam_faillock.so
```

#### Disable Root Login
```bash
# Create sudo user first
sudo useradd -G wheel admin_user
sudo passwd admin_user

# Disable root SSH login
sudo nano /etc/ssh/sshd_config
```

```conf
PermitRootLogin no
```

#### Remove Unnecessary Users
```bash
# List all users
cat /etc/passwd

# Remove unused system users
sudo userdel -r username

# Lock unused accounts
sudo passwd -l username
```

### SSH Security

#### Secure SSH Configuration
```bash
sudo nano /etc/ssh/sshd_config
```

```conf
# Change default port
Port 2222

# Disable root login
PermitRootLogin no

# Disable password authentication
PasswordAuthentication no
PubkeyAuthentication yes

# Disable empty passwords
PermitEmptyPasswords no

# Limit authentication attempts
MaxAuthTries 3
MaxSessions 2

# Set login grace time
LoginGraceTime 60

# Disable X11 forwarding
X11Forwarding no

# Use strong ciphers
Ciphers aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512,hmac-sha2-256

# Allow specific users only
AllowUsers admin_user deploy_user

# Enable strict mode
StrictModes yes

# Log level
LogLevel VERBOSE

# Disable tunneling
PermitTunnel no
AllowTcpForwarding no
```

```bash
sudo systemctl restart sshd

# Update firewall for new port
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --reload
```

#### SSH Key-Based Authentication
```bash
# Generate SSH key (on local machine)
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/hosting_key

# Copy public key to server
ssh-copy-id -i ~/.ssh/hosting_key.pub -p 2222 user@server_ip

# Test connection
ssh -i ~/.ssh/hosting_key -p 2222 user@server_ip

# Disable password authentication (after testing)
sudo nano /etc/ssh/sshd_config
```

```conf
PasswordAuthentication no
ChallengeResponseAuthentication no
```

#### Two-Factor Authentication for SSH
```bash
# Install Google Authenticator
sudo yum install -y google-authenticator

# Configure for user
google-authenticator

# Configure PAM
sudo nano /etc/pam.d/sshd
```

Add at top:
```
auth required pam_google_authenticator.so
```

```bash
# Configure SSH
sudo nano /etc/ssh/sshd_config
```

```conf
ChallengeResponseAuthentication yes
AuthenticationMethods publickey,keyboard-interactive
```

```bash
sudo systemctl restart sshd
```

### Audit Logging

#### Configure auditd
```bash
# Install auditd
sudo yum install -y audit

# Start service
sudo systemctl enable auditd
sudo systemctl start auditd

# Configure audit rules
sudo nano /etc/audit/rules.d/custom.rules
```

```conf
# Monitor unauthorized access attempts
-w /var/log/faillog -p wa -k auth_failures
-w /var/log/lastlog -p wa -k logins

# Monitor user/group modifications
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/gshadow -p wa -k identity

# Monitor sudo usage
-w /etc/sudoers -p wa -k actions
-w /etc/sudoers.d/ -p wa -k actions

# Monitor network configuration
-w /etc/sysconfig/network-scripts/ -p wa -k network_modifications

# Monitor system calls
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time_change
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k delete

# Monitor file access
-w /home/whm.soporteclientes.net/public_html/.env -p wa -k config_changes
-w /etc/httpd/conf/ -p wa -k httpd_config
-w /etc/my.cnf -p wa -k mysql_config
```

```bash
# Reload rules
sudo augenrules --load

# View audit logs
sudo ausearch -k auth_failures
sudo ausearch -k identity
```

## Web Server Security

### Apache Hardening

#### Hide Apache Version
```bash
sudo nano /etc/httpd/conf/httpd.conf
```

```apache
ServerTokens Prod
ServerSignature Off
TraceEnable Off
```

#### Security Headers
```bash
sudo nano /etc/httpd/conf.d/security.conf
```

```apache
# Security headers
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"

# HSTS (only after SSL is working properly)
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"

# Content Security Policy
Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';"

# Remove sensitive headers
Header unset X-Powered-By
Header unset Server
```

#### Disable Directory Listing
```bash
sudo nano /etc/httpd/conf/httpd.conf
```

```apache
<Directory "/home">
    Options -Indexes +FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
```

#### Restrict Access to Sensitive Files
```bash
sudo nano /etc/httpd/conf.d/restrictions.conf
```

```apache
# Deny access to .htaccess and .env files
<FilesMatch "^\.">
    Require all denied
</FilesMatch>

# Deny access to version control
<DirectoryMatch "\.git">
    Require all denied
</DirectoryMatch>

# Deny access to sensitive files
<FilesMatch "(composer\.json|composer\.lock|package\.json|package-lock\.json|\.env)">
    Require all denied
</FilesMatch>

# Limit HTTP methods
<LimitExcept GET POST HEAD>
    Require all denied
</LimitExcept>
```

#### Rate Limiting

```bash
# Install mod_evasive
sudo yum install -y mod_evasive

# Configure mod_evasive
sudo nano /etc/httpd/conf.d/mod_evasive.conf
```

```apache
<IfModule mod_evasive24.c>
    DOSHashTableSize 3097
    DOSPageCount 5
    DOSSiteCount 100
    DOSPageInterval 1
    DOSSiteInterval 1
    DOSBlockingPeriod 60
    DOSEmailNotify admin@example.com
    DOSLogDir "/var/log/mod_evasive"
</IfModule>
```

```bash
# Create log directory
sudo mkdir -p /var/log/mod_evasive
sudo chown apache:apache /var/log/mod_evasive

# Restart Apache
sudo systemctl restart httpd
```

#### ModSecurity Web Application Firewall

```bash
# Install ModSecurity
sudo yum install -y mod_security mod_security_crs

# Configure ModSecurity
sudo nano /etc/httpd/conf.d/mod_security.conf
```

```apache
<IfModule mod_security2.c>
    SecRuleEngine On
    SecRequestBodyAccess On
    SecRule REQUEST_HEADERS:Content-Type "text/xml" \
         "id:'200000',phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=XML"
    SecRequestBodyLimit 13107200
    SecRequestBodyNoFilesLimit 131072
    SecRequestBodyInMemoryLimit 131072
    SecRequestBodyLimitAction Reject
    SecPcreMatchLimit 1000
    SecPcreMatchLimitRecursion 1000

    SecAuditEngine RelevantOnly
    SecAuditLogRelevantStatus "^(?:5|4(?!04))"
    SecAuditLogParts ABIJDEFHZ
    SecAuditLogType Serial
    SecAuditLog /var/log/httpd/modsec_audit.log

    SecDebugLog /var/log/httpd/modsec_debug.log
    SecDebugLogLevel 0
</IfModule>
```

```bash
sudo systemctl restart httpd
```

### SSL/TLS Security

See [SSL Configuration Guide](ssl.md) for detailed SSL security configuration.

## Application Security

### Laravel Security Configuration

#### Environment Configuration
```bash
cd /home/whm.soporteclientes.net/public_html
nano .env
```

```env
# Set to production
APP_ENV=production
APP_DEBUG=false

# Secure app key (generate new)
php artisan key:generate

# Force HTTPS
APP_URL=https://whm.soporteclientes.net

# Session security
SESSION_DRIVER=database
SESSION_LIFETIME=120
SESSION_SECURE_COOKIE=true
SESSION_HTTP_ONLY=true
SESSION_SAME_SITE=strict

# Cookie security
COOKIE_SECURE=true
COOKIE_HTTP_ONLY=true
COOKIE_SAME_SITE=strict
```

#### CSRF Protection
```php
// Enabled by default in Laravel
// Verify middleware in app/Http/Kernel.php

protected $middlewareGroups = [
    'web' => [
        \App\Http\Middleware\VerifyCsrfToken::class,
        // ...
    ],
];
```

#### XSS Protection
```php
// Always escape output in Blade templates
{{ $variable }}  // Escaped
{!! $variable !!}  // Raw (avoid unless necessary)

// Use HTML Purifier for rich text
composer require mews/purifier
```

#### SQL Injection Prevention
```php
// Always use parameter binding
DB::table('users')->where('email', $email)->first();

// NEVER use raw queries with user input
// BAD: DB::raw("SELECT * FROM users WHERE email = '$email'")

// Use Eloquent ORM
User::where('email', $email)->first();
```

#### Input Validation
```php
// Create validation rules
$request->validate([
    'email' => 'required|email|max:255',
    'password' => 'required|min:8|confirmed',
    'name' => 'required|string|max:255',
]);

// Sanitize input
$clean = filter_var($input, FILTER_SANITIZE_STRING);
```

#### File Upload Security
```php
// Validate file uploads
$request->validate([
    'file' => 'required|file|mimes:pdf,jpg,png|max:2048',
]);

// Store with random name
$path = $request->file('file')->store('uploads', 'private');

// Never trust file extension
$mimeType = $request->file('file')->getMimeType();
```

#### Security Headers in Laravel
```bash
nano app/Http/Middleware/SecurityHeaders.php
```

```php
<?php

namespace App\Http\Middleware;

use Closure;

class SecurityHeaders
{
    public function handle($request, Closure $next)
    {
        $response = $next($request);

        $response->headers->set('X-Frame-Options', 'SAMEORIGIN');
        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set('X-XSS-Protection', '1; mode=block');
        $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');
        $response->headers->set('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');

        return $response;
    }
}
```

Register in `app/Http/Kernel.php`:
```php
protected $middleware = [
    \App\Http\Middleware\SecurityHeaders::class,
    // ...
];
```

#### API Security
```bash
# Install Laravel Sanctum
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan migrate
```

```php
// Use API rate limiting
// app/Http/Kernel.php
protected $middlewareGroups = [
    'api' => [
        'throttle:60,1',
        \Illuminate\Routing\Middleware\SubstituteBindings::class,
    ],
];

// Custom rate limits
Route::middleware('throttle:10,1')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
});
```

### Dependency Security

#### Keep Dependencies Updated
```bash
# Check for updates
composer outdated

# Update dependencies
composer update

# Check for vulnerabilities
composer audit

# Update specific package
composer update vendor/package
```

#### Security Advisories
```bash
# Install security checker
composer require --dev enlightn/security-checker

# Run security check
./vendor/bin/security-checker security:check

# Add to CI/CD pipeline
```

## Database Security

### MySQL/MariaDB Hardening

#### Secure Installation
```bash
# Run secure installation
sudo mysql_secure_installation
```

Answer YES to all:
- Set root password
- Remove anonymous users
- Disallow root login remotely
- Remove test database
- Reload privilege tables

#### Create Secure Database Users
```bash
mysql -u root -p
```

```sql
-- Create users with limited privileges
CREATE USER 'whm_user'@'localhost' IDENTIFIED BY 'strong_password_here';
GRANT SELECT, INSERT, UPDATE, DELETE ON whm_panel.* TO 'whm_user'@'localhost';

-- Never use root for applications
-- Never grant ALL PRIVILEGES unless necessary
-- Use different users for different applications

-- View user grants
SHOW GRANTS FOR 'whm_user'@'localhost';

-- Remove unnecessary privileges
REVOKE CREATE, DROP ON database.* FROM 'user'@'localhost';

FLUSH PRIVILEGES;
```

#### Bind to Localhost
```bash
sudo nano /etc/my.cnf
```

```ini
[mysqld]
bind-address = 127.0.0.1
skip-networking = 0
local-infile = 0
```

#### Database Encryption
```bash
sudo nano /etc/my.cnf
```

```ini
[mysqld]
# Enable SSL
ssl-ca=/etc/mysql/ssl/ca-cert.pem
ssl-cert=/etc/mysql/ssl/server-cert.pem
ssl-key=/etc/mysql/ssl/server-key.pem

# Require SSL for users
# GRANT ALL PRIVILEGES ON database.* TO 'user'@'localhost' REQUIRE SSL;
```

#### Audit Logging
```bash
sudo nano /etc/my.cnf
```

```ini
[mysqld]
# General query log
general_log = 1
general_log_file = /var/log/mysql/general.log

# Log suspicious queries
log_error_verbosity = 3
```

#### Regular Backups
```bash
# Create backup script
sudo nano /usr/local/bin/backup_databases.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/backup/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
MYSQL_USER="backup_user"
MYSQL_PASS="backup_password"

mkdir -p $BACKUP_DIR

# Backup all databases
mysqldump -u$MYSQL_USER -p$MYSQL_PASS --all-databases \
    --single-transaction --quick --lock-tables=false \
    > $BACKUP_DIR/all_databases_$DATE.sql

# Compress backup
gzip $BACKUP_DIR/all_databases_$DATE.sql

# Encrypt backup
openssl enc -aes-256-cbc -salt -in $BACKUP_DIR/all_databases_$DATE.sql.gz \
    -out $BACKUP_DIR/all_databases_$DATE.sql.gz.enc -k "encryption_password"

rm $BACKUP_DIR/all_databases_$DATE.sql.gz

# Keep only 30 days
find $BACKUP_DIR -name "*.enc" -mtime +30 -delete

# Upload to remote storage
# aws s3 cp $BACKUP_DIR/all_databases_$DATE.sql.gz.enc s3://bucket/
```

```bash
chmod +x /usr/local/bin/backup_databases.sh
echo "0 2 * * * /usr/local/bin/backup_databases.sh" | sudo tee -a /etc/crontab
```

## Network Security

### Firewall Configuration

See [Firewall Setup Guide](firewall.md) for detailed firewall configuration.

#### Basic Firewall Rules
```bash
# Install firewalld
sudo yum install -y firewalld

# Start and enable
sudo systemctl start firewalld
sudo systemctl enable firewalld

# Set default zone
sudo firewall-cmd --set-default-zone=public

# Add essential services
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=2222/tcp

# Remove unnecessary services
sudo firewall-cmd --permanent --remove-service=dhcpv6-client

# Reload
sudo firewall-cmd --reload
```

### Intrusion Detection

#### Install Fail2Ban
```bash
# Install fail2ban
sudo yum install -y fail2ban fail2ban-systemd

# Create local config
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local
```

```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = admin@example.com
sendername = Fail2Ban
action = %(action_mwl)s

[sshd]
enabled = true
port = 2222
logpath = /var/log/secure
maxretry = 3

[httpd-auth]
enabled = true
port = http,https
logpath = /var/log/httpd/error_log

[httpd-badbots]
enabled = true
port = http,https
logpath = /var/log/httpd/access_log
maxretry = 2

[php-url-fopen]
enabled = true
port = http,https
logpath = /var/log/httpd/access_log
```

```bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Check status
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

## Access Control

### Role-Based Access Control (RBAC)

#### Laravel Permissions
```bash
# Install Laravel Permission package
composer require spatie/laravel-permission
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
php artisan migrate
```

```php
// Create roles and permissions
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

// Create permissions
Permission::create(['name' => 'view users']);
Permission::create(['name' => 'create users']);
Permission::create(['name' => 'edit users']);
Permission::create(['name' => 'delete users']);

// Create roles
$role = Role::create(['name' => 'admin']);
$role->givePermissionTo(['view users', 'create users', 'edit users', 'delete users']);

$role = Role::create(['name' => 'user']);
$role->givePermissionTo(['view users']);

// Assign role to user
$user->assignRole('admin');

// Check permissions in controller
if ($user->can('edit users')) {
    // Allow
}

// Use middleware
Route::middleware(['role:admin'])->group(function () {
    // Admin routes
});
```

### API Authentication

```bash
# Generate API tokens
php artisan make:controller Api/AuthController
```

```php
// Implement token-based authentication
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;
}

// Generate token
$token = $user->createToken('token-name')->plainTextToken;

// Protect API routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
});
```

## Data Protection

### Encryption

#### Encrypt Sensitive Data
```php
// Use Laravel encryption
use Illuminate\Support\Facades\Crypt;

// Encrypt
$encrypted = Crypt::encryptString('sensitive data');

// Decrypt
$decrypted = Crypt::decryptString($encrypted);

// Database encryption
use Illuminate\Database\Eloquent\Model;

class User extends Model
{
    protected $casts = [
        'sensitive_field' => 'encrypted',
    ];
}
```

#### File Encryption
```bash
# Encrypt file
openssl enc -aes-256-cbc -salt -in file.txt -out file.txt.enc

# Decrypt file
openssl enc -aes-256-cbc -d -in file.txt.enc -out file.txt
```

### Data Sanitization

#### Sanitize Output
```php
// Always escape output
{{ $variable }}

// Sanitize HTML
use HTMLPurifier;
$clean_html = HTMLPurifier::clean($dirty_html);

// Sanitize SQL
DB::table('users')->where('email', $email)->first();
```

#### Data Masking
```php
// Mask sensitive data in logs
Log::info('User login', [
    'email' => Str::mask($email, '*', 3),
    'ip' => $request->ip()
]);

// Mask credit card numbers
function maskCard($number) {
    return str_repeat('*', strlen($number) - 4) . substr($number, -4);
}
```

## Monitoring and Auditing

### Security Monitoring

```bash
# Create security monitoring script
sudo nano /usr/local/bin/security_monitor.sh
```

```bash
#!/bin/bash

ALERT_EMAIL="security@example.com"
DATE=$(date +%Y-%m-%d)

# Check for failed login attempts
FAILED_LOGINS=$(grep "Failed password" /var/log/secure | wc -l)
if [ $FAILED_LOGINS -gt 10 ]; then
    echo "WARNING: $FAILED_LOGINS failed login attempts detected" | \
        mail -s "Security Alert: Failed Logins" $ALERT_EMAIL
fi

# Check for root login attempts
ROOT_ATTEMPTS=$(grep "root" /var/log/secure | grep "Failed" | wc -l)
if [ $ROOT_ATTEMPTS -gt 0 ]; then
    echo "ALERT: Root login attempts detected!" | \
        mail -s "CRITICAL: Root Login Attempts" $ALERT_EMAIL
fi

# Check for suspicious files
find /tmp -type f -name "*.php" -o -name "*.sh" | while read file; do
    echo "Suspicious file in /tmp: $file" | \
        mail -s "Security Alert: Suspicious File" $ALERT_EMAIL
done

# Check for world-writable files
find /home -type f -perm -002 | while read file; do
    echo "World-writable file detected: $file" | \
        mail -s "Security Alert: World-Writable File" $ALERT_EMAIL
done

# Check for SUID files
find / -perm -4000 -type f 2>/dev/null | while read file; do
    echo "$file" >> /var/log/suid_files_$DATE.log
done

# Log report
echo "$(date) - Security scan completed" >> /var/log/security_monitor.log
```

```bash
chmod +x /usr/local/bin/security_monitor.sh
echo "0 */6 * * * /usr/local/bin/security_monitor.sh" | sudo tee -a /etc/crontab
```

## Incident Response

### Incident Response Plan

#### Detection Phase
1. Monitor security alerts
2. Review logs regularly
3. Investigate anomalies
4. Verify security incidents

#### Containment Phase
```bash
# Isolate compromised system
sudo firewall-cmd --panic-on

# Stop compromised services
sudo systemctl stop httpd mariadb

# Block suspicious IPs
sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='suspicious_ip' reject"
```

#### Recovery Phase
```bash
# Restore from backup
sudo systemctl stop httpd mariadb
tar -xzf /backup/clean_backup.tar.gz -C /
mysql -u root -p < /backup/clean_database.sql

# Update passwords
mysql -u root -p
UPDATE mysql.user SET password=PASSWORD('new_password') WHERE user='root';
FLUSH PRIVILEGES;

# Update application keys
cd /home/whm.soporteclientes.net/public_html
php artisan key:generate

# Restart services
sudo systemctl start mariadb httpd
```

#### Post-Incident Phase
1. Document incident
2. Update security measures
3. Conduct post-mortem
4. Improve detection
5. Train team

## Compliance

### GDPR Compliance

```php
// Implement data export
public function exportData(User $user)
{
    return response()->json($user->load('data'));
}

// Implement data deletion
public function deleteData(User $user)
{
    $user->delete();
    return response()->json(['message' => 'Data deleted']);
}

// Implement consent tracking
Schema::create('user_consents', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id');
    $table->string('consent_type');
    $table->boolean('granted');
    $table->timestamp('granted_at')->nullable();
    $table->timestamps();
});
```

### PCI DSS Compliance

If handling payment data:
1. Never store CVV
2. Encrypt cardholder data
3. Use secure protocols (TLS 1.2+)
4. Implement access controls
5. Monitor and test regularly
6. Use third-party payment processors (recommended)

### Audit Logging

```php
// Implement comprehensive audit logging
use Illuminate\Support\Facades\Log;

Log::channel('audit')->info('User action', [
    'user_id' => auth()->id(),
    'action' => 'updated_user',
    'target_id' => $user->id,
    'ip' => request()->ip(),
    'user_agent' => request()->userAgent(),
    'changes' => $user->getChanges(),
]);
```

## Security Checklist

### Daily Tasks
- [ ] Review security logs
- [ ] Check failed login attempts
- [ ] Monitor system resources
- [ ] Verify backup completion
- [ ] Check for suspicious activities

### Weekly Tasks
- [ ] Review user accounts
- [ ] Update firewall rules if needed
- [ ] Check SSL certificate status
- [ ] Review application logs
- [ ] Test backup restoration
- [ ] Update security software

### Monthly Tasks
- [ ] Update system packages
- [ ] Review access controls
- [ ] Audit user permissions
- [ ] Test disaster recovery
- [ ] Review security policies
- [ ] Conduct security training
- [ ] Perform vulnerability scan

### Quarterly Tasks
- [ ] Full security audit
- [ ] Penetration testing
- [ ] Review incident response plan
- [ ] Update documentation
- [ ] Review compliance requirements
- [ ] Third-party security assessment

## Best Practices Summary

1. **Keep Systems Updated**: Regular patching
2. **Strong Authentication**: Multi-factor authentication
3. **Least Privilege**: Minimal necessary permissions
4. **Defense in Depth**: Multiple security layers
5. **Encryption**: Data at rest and in transit
6. **Monitoring**: Continuous security monitoring
7. **Incident Response**: Prepared response plan
8. **Regular Backups**: Tested backup and recovery
9. **Security Training**: Educate team members
10. **Documentation**: Maintain security documentation

## Next Steps

- Implement SSL/TLS: See [SSL Configuration Guide](ssl.md)
- Configure Firewall: See [Firewall Setup Guide](firewall.md)
- Setup Monitoring: See [Monitoring Guide](monitoring.md)
- Regular Updates: Keep systems patched
- Security Training: Educate team on security

For more information, see:
- [SSL Configuration Guide](ssl.md)
- [Firewall Setup Guide](firewall.md)
- [Monitoring Guide](monitoring.md)
- [Troubleshooting Guide](troubleshooting.md)
