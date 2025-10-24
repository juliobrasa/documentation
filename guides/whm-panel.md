# WHM Panel Guide

Complete guide to the WHM (Web Host Manager) Panel component of the Hosting Management Platform.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Installation and Setup](#installation-and-setup)
4. [Server Management](#server-management)
5. [Account Management](#account-management)
6. [Package Management](#package-management)
7. [Reseller Management](#reseller-management)
8. [Backup System](#backup-system)
9. [Resource Monitoring](#resource-monitoring)
10. [API Integration](#api-integration)
11. [Advanced Features](#advanced-features)
12. [Security](#security)
13. [Troubleshooting](#troubleshooting)
14. [Best Practices](#best-practices)
15. [Related Links](#related-links)

## Overview

The WHM Panel is a comprehensive web hosting management interface that provides complete control over multiple WHM/cPanel servers. It enables hosting providers to manage accounts, packages, resellers, and resources from a centralized dashboard.

### Key Features

- **Multi-Server Management**: Manage unlimited WHM/cPanel servers from one interface
- **Account Lifecycle**: Complete account creation, modification, suspension, and termination
- **Package Templates**: Pre-configured hosting packages with resource limits
- **Reseller Support**: Full reseller account management and delegation
- **Automated Backups**: Scheduled backups with off-site storage
- **Real-time Monitoring**: Server resources, account usage, and performance metrics
- **API Integration**: RESTful API for automation and third-party integrations
- **Audit Logging**: Complete audit trail of all operations

### Technology Stack

- **Framework**: Laravel 9.x
- **Frontend**: Vue.js 3 with Tailwind CSS
- **Database**: MySQL 8.0+ / MariaDB 10.5+
- **API**: WHM API v1
- **Cache**: Redis
- **Queue**: Laravel Horizon

## Architecture

### System Components

```
┌─────────────────────────────────────────────────┐
│              WHM Panel Interface                │
│         (Vue.js Frontend + Laravel API)         │
└───────────────────┬─────────────────────────────┘
                    │
        ┌───────────┼───────────┐
        ▼           ▼           ▼
   ┌────────┐  ┌────────┐  ┌────────┐
   │WHM     │  │WHM     │  │WHM     │
   │Server 1│  │Server 2│  │Server N│
   └────────┘  └────────┘  └────────┘
        │           │           │
        └───────────┼───────────┘
                    │
              ┌─────▼─────┐
              │  Storage  │
              │  Backups  │
              └───────────┘
```

### Database Schema

The WHM Panel uses the following main tables:

- `servers` - WHM server configurations
- `accounts` - Hosting accounts
- `packages` - Hosting packages/plans
- `resellers` - Reseller accounts
- `backups` - Backup records
- `activity_logs` - Audit trail

### Request Flow

1. User initiates action in web interface
2. Frontend sends API request to Laravel backend
3. Backend validates request and permissions
4. WHM API client connects to target server
5. Server executes operation
6. Response logged and returned to user

## Installation and Setup

### Prerequisites

- CentOS/AlmaLinux 7+ with root access
- PHP 8.0+ with required extensions
- MySQL/MariaDB database
- Access to at least one WHM server
- WHM API access token

### Initial Setup

```bash
# Navigate to installation directory
cd /home/whm.soporteclientes.net/public_html

# Clone repository
git clone https://github.com/juliobrasa/whm.git .

# Install PHP dependencies
composer install --no-dev --optimize-autoloader

# Install frontend dependencies
npm install
npm run production

# Configure environment
cp .env.example .env
php artisan key:generate
```

### Database Configuration

Edit `.env` file:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=whm_panel
DB_USERNAME=whm_user
DB_PASSWORD=secure_password
```

Run migrations:

```bash
php artisan migrate --seed
```

### Initial Admin User

Create the first admin user:

```bash
php artisan tinker
```

```php
$user = new \App\Models\User;
$user->name = 'Admin';
$user->email = 'admin@example.com';
$user->password = Hash::make('SecurePassword123!');
$user->role = 'admin';
$user->save();
exit
```

### Web Server Configuration

Apache virtual host example:

```apache
<VirtualHost *:80>
    ServerName whm.soporteclientes.net
    DocumentRoot /home/whm.soporteclientes.net/public_html/public

    <Directory /home/whm.soporteclientes.net/public_html/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/httpd/whm_error.log
    CustomLog /var/log/httpd/whm_access.log combined
</VirtualHost>
```

## Server Management

### Adding a WHM Server

Navigate to **Servers > Add Server** in the admin panel.

Required information:
- Server name (descriptive label)
- Hostname (e.g., server1.example.com)
- IP address
- WHM port (default: 2087)
- API access hash or token
- Optional: SSH credentials for advanced operations

**Example via API:**

```bash
curl -X POST https://whm.soporteclientes.net/api/v1/servers \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Production Server 1",
    "hostname": "server1.example.com",
    "ip_address": "192.168.1.100",
    "port": 2087,
    "username": "root",
    "api_token": "WHM_API_TOKEN_HERE",
    "max_accounts": 500,
    "enabled": true
  }'
```

### Server Configuration

After adding a server, configure:

1. **Resource Limits**
   - Maximum accounts allowed
   - Disk quota limits
   - Bandwidth restrictions

2. **Backup Settings**
   - Backup schedule
   - Retention policy
   - Storage location

3. **Notifications**
   - Resource threshold alerts
   - Server down notifications
   - Quota warnings

### Server Synchronization

Synchronize account data from WHM server:

```bash
# Sync all servers
php artisan whm:sync-all

# Sync specific server
php artisan whm:sync-server 1

# Force full resync
php artisan whm:sync-server 1 --force
```

### Server Health Monitoring

The system automatically monitors:

- Server uptime/downtime
- CPU usage
- Memory usage
- Disk space
- Account count
- Active connections

View server health:

```bash
# Check server status
php artisan whm:server-status

# Detailed health report
php artisan whm:health-check --server=1
```

## Account Management

### Creating Accounts

#### Via Web Interface

1. Navigate to **Accounts > Create New**
2. Fill in required fields:
   - Domain name
   - Username
   - Password
   - Email
   - Package
   - Target server

3. Optional settings:
   - IP address (shared/dedicated)
   - Custom quotas
   - Email limits
   - Database limits

4. Click **Create Account**

#### Via API

```bash
curl -X POST https://whm.soporteclientes.net/api/v1/whm/accounts \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "example.com",
    "username": "exampleuser",
    "password": "SecurePass123!",
    "email": "owner@example.com",
    "package": "basic",
    "server_id": 1,
    "quota": 1024,
    "bandwidth": 10240
  }'
```

#### Via Command Line

```bash
php artisan whm:create-account \
  --domain=example.com \
  --username=exampleuser \
  --email=owner@example.com \
  --package=basic \
  --server=1
```

### Modifying Accounts

Update account settings:

```php
// Update via API
PUT /api/v1/whm/accounts/{id}
{
  "quota": 2048,
  "bandwidth": 20480,
  "max_emails": 100,
  "max_databases": 10
}
```

### Suspending Accounts

Suspend an account for non-payment or policy violations:

```bash
# Suspend via CLI
php artisan whm:suspend-account exampleuser --reason="Non-payment"

# Unsuspend
php artisan whm:unsuspend-account exampleuser
```

**API Example:**

```bash
# Suspend
POST /api/v1/whm/accounts/{id}/suspend
{
  "reason": "Non-payment",
  "notify_user": true
}

# Unsuspend
POST /api/v1/whm/accounts/{id}/unsuspend
```

### Terminating Accounts

Permanently remove an account:

```bash
# WARNING: This is irreversible
php artisan whm:terminate-account exampleuser --keep-dns
```

**Via API:**

```bash
DELETE /api/v1/whm/accounts/{id}
{
  "keep_dns": true,
  "create_backup": true
}
```

### Account Migration

Migrate accounts between servers:

```bash
php artisan whm:migrate-account exampleuser \
  --from-server=1 \
  --to-server=2 \
  --backup-first
```

### Bulk Operations

Perform operations on multiple accounts:

```bash
# Bulk suspend
php artisan whm:bulk-suspend --server=1 --reason="Maintenance"

# Bulk package change
php artisan whm:bulk-package-change --from=basic --to=premium

# Export accounts list
php artisan whm:export-accounts --server=1 --format=csv
```

## Package Management

### Understanding Packages

Packages define resource limits and features for hosting accounts:

- Disk quota (MB)
- Bandwidth limit (MB)
- Email accounts
- Databases
- FTP accounts
- Subdomains
- Addon domains
- Parked domains

### Creating Packages

#### Via Web Interface

1. Navigate to **Packages > Create New**
2. Configure resources:

```yaml
Package: Premium
Quota: 10000 MB (10 GB)
Bandwidth: 100000 MB (100 GB)
Max Email Accounts: Unlimited
Max Databases: 25
Max FTP Accounts: 50
Max Subdomains: Unlimited
Max Addon Domains: 5
Max Parked Domains: 5
CGI Access: Yes
Shell Access: No
```

#### Via API

```bash
curl -X POST https://whm.soporteclientes.net/api/v1/whm/packages \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "name": "premium",
    "quota": 10000,
    "bandwidth": 100000,
    "max_emails": 0,
    "max_databases": 25,
    "max_ftp": 50,
    "max_subdomains": 0,
    "max_addon_domains": 5,
    "max_parked_domains": 5,
    "cgi": true,
    "shell": false
  }'
```

### Package Templates

Pre-configured package templates:

```bash
# Import template
php artisan whm:import-package-template starter.json

# Export package as template
php artisan whm:export-package premium --output=premium-template.json
```

**Template Example (starter.json):**

```json
{
  "name": "starter",
  "display_name": "Starter Plan",
  "quota": 1024,
  "bandwidth": 10240,
  "max_emails": 10,
  "max_databases": 2,
  "max_ftp": 5,
  "max_subdomains": 5,
  "max_addon_domains": 1,
  "max_parked_domains": 1,
  "features": {
    "cgi": false,
    "shell": false,
    "ssl": true,
    "dedicated_ip": false
  }
}
```

### Updating Packages

Modify package limits:

```bash
# Update package
php artisan whm:update-package premium --quota=20000 --bandwidth=200000

# Apply changes to existing accounts
php artisan whm:apply-package-update premium --apply-to-accounts
```

## Reseller Management

### Reseller Accounts

Resellers can create and manage their own accounts with delegated resources.

### Creating Resellers

```bash
php artisan whm:create-reseller \
  --username=reseller1 \
  --domain=reseller1.example.com \
  --email=reseller@example.com \
  --package=reseller-basic \
  --server=1
```

### Reseller Resource Allocation

Define resource pools for resellers:

```json
{
  "reseller": "reseller1",
  "resources": {
    "max_accounts": 50,
    "total_quota": 500000,
    "total_bandwidth": 5000000,
    "allowed_packages": ["basic", "standard"],
    "overselling": true,
    "oversell_limit": 1.5
  }
}
```

### Reseller Permissions

Configure what resellers can do:

- Create/modify/suspend accounts
- Create custom packages (within limits)
- Access WHM functions
- View reports
- Modify DNS zones
- Access backups

### Reseller API Access

Generate API tokens for resellers:

```bash
php artisan whm:generate-reseller-token reseller1 \
  --scopes=accounts.create,accounts.modify,packages.view
```

## Backup System

### Automated Backups

Configure automatic backup schedules:

```bash
# Configure backup schedule
php artisan whm:configure-backup \
  --server=1 \
  --schedule=daily \
  --time="02:00" \
  --retention=30
```

### Backup Configuration

Edit backup settings in admin panel:

```yaml
Backup Schedule: Daily at 2:00 AM
Retention Period: 30 days
Backup Type: Full (accounts + databases)
Compression: gzip
Encryption: AES-256
Storage: Local + S3
Notification: Email on completion
```

### Manual Backup

Create immediate backup:

```bash
# Backup single account
php artisan whm:backup-account exampleuser

# Backup entire server
php artisan whm:backup-server 1

# Backup all servers
php artisan whm:backup-all
```

### Backup Restoration

Restore from backup:

```bash
# List available backups
php artisan whm:list-backups exampleuser

# Restore account
php artisan whm:restore-account exampleuser \
  --backup-id=12345 \
  --restore-type=full
```

### Off-site Backup Storage

Configure S3-compatible storage:

```env
BACKUP_DRIVER=s3
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=whm-backups
```

## Resource Monitoring

### Real-time Monitoring

View live resource usage:

```bash
# Server overview
php artisan whm:monitor-server 1

# Account resource usage
php artisan whm:monitor-account exampleuser

# Resource alerts
php artisan whm:check-alerts
```

### Monitoring Dashboard

Access monitoring dashboard at `/admin/monitoring`

Key metrics displayed:
- Server CPU usage
- Memory utilization
- Disk space
- Network bandwidth
- Active accounts
- Suspended accounts
- Recent activities

### Alert Configuration

Set up resource alerts:

```php
// config/monitoring.php
'alerts' => [
    'disk_usage' => [
        'threshold' => 80, // percentage
        'notify' => ['admin@example.com'],
        'action' => 'email'
    ],
    'cpu_usage' => [
        'threshold' => 90,
        'notify' => ['admin@example.com'],
        'action' => 'email,slack'
    ],
    'bandwidth_usage' => [
        'threshold' => 85,
        'notify' => ['admin@example.com'],
        'action' => 'email'
    ]
]
```

### Historical Data

Generate usage reports:

```bash
# Monthly report
php artisan whm:report --type=monthly --server=1

# Custom date range
php artisan whm:report \
  --from=2024-01-01 \
  --to=2024-01-31 \
  --format=pdf
```

## API Integration

### Authentication

All API requests require authentication:

```bash
# Generate API token
php artisan whm:generate-token --user=admin --expires=365

# Use token in requests
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://whm.soporteclientes.net/api/v1/servers
```

### API Endpoints

Complete API reference available at `/api/documentation`

Common endpoints:

```bash
# Servers
GET    /api/v1/servers
POST   /api/v1/servers
GET    /api/v1/servers/{id}
PUT    /api/v1/servers/{id}
DELETE /api/v1/servers/{id}

# Accounts
GET    /api/v1/whm/accounts
POST   /api/v1/whm/accounts
GET    /api/v1/whm/accounts/{id}
PUT    /api/v1/whm/accounts/{id}
DELETE /api/v1/whm/accounts/{id}
POST   /api/v1/whm/accounts/{id}/suspend
POST   /api/v1/whm/accounts/{id}/unsuspend

# Packages
GET    /api/v1/whm/packages
POST   /api/v1/whm/packages
PUT    /api/v1/whm/packages/{id}
DELETE /api/v1/whm/packages/{id}
```

### Webhooks

Configure webhooks for events:

```php
// config/webhooks.php
'hooks' => [
    'account.created' => 'https://your-app.com/webhook/account-created',
    'account.suspended' => 'https://your-app.com/webhook/account-suspended',
    'account.terminated' => 'https://your-app.com/webhook/account-terminated',
    'server.down' => 'https://your-app.com/webhook/server-down'
]
```

## Advanced Features

### Custom Scripts

Run custom scripts on servers:

```bash
php artisan whm:run-script \
  --server=1 \
  --script=/root/scripts/cleanup.sh \
  --async
```

### DNS Management

Manage DNS zones:

```bash
# Add DNS zone
php artisan whm:add-zone example.com --server=1

# Add DNS record
php artisan whm:add-record example.com \
  --type=A \
  --name=www \
  --value=192.168.1.100
```

### SSL Certificate Management

Install SSL certificates:

```bash
# Install Let's Encrypt
php artisan whm:install-ssl exampleuser \
  --domain=example.com \
  --provider=letsencrypt

# Install custom SSL
php artisan whm:install-ssl exampleuser \
  --cert=/path/to/cert.crt \
  --key=/path/to/private.key
```

### Email Account Management

Manage email accounts:

```bash
# Create email account
php artisan whm:create-email user@example.com \
  --password=SecurePass123 \
  --quota=1024

# List email accounts
php artisan whm:list-emails --domain=example.com
```

## Security

### Access Control

Implement role-based access:

```php
// Define roles
$roles = [
    'super_admin' => ['*'],
    'admin' => ['servers.*', 'accounts.*', 'packages.*'],
    'reseller' => ['accounts.create', 'accounts.modify', 'accounts.view'],
    'user' => ['accounts.view']
];
```

### IP Whitelisting

Restrict access by IP:

```php
// config/security.php
'ip_whitelist' => [
    '192.168.1.0/24',
    '10.0.0.0/8'
]
```

### Two-Factor Authentication

Enable 2FA for admin users:

```bash
php artisan whm:enable-2fa --user=admin
```

### Audit Logging

All operations are logged:

```bash
# View audit logs
php artisan whm:audit-log --user=admin --days=30

# Export logs
php artisan whm:export-audit-log --format=csv --output=/tmp/audit.csv
```

## Troubleshooting

### Common Issues

#### Connection to WHM Server Failed

**Symptoms:** Cannot connect to WHM API

**Solutions:**
```bash
# Test connection
php artisan whm:test-connection --server=1

# Check firewall
sudo firewall-cmd --list-all

# Verify API token
curl -k https://server1.example.com:2087/json-api/version \
  -H "Authorization: whm root:API_TOKEN"
```

#### Account Creation Failed

**Symptoms:** Account creation returns error

**Solutions:**
```bash
# Check server quotas
php artisan whm:check-quota --server=1

# Verify package exists
php artisan whm:list-packages

# Check logs
tail -f storage/logs/laravel.log
```

#### Backup Failure

**Symptoms:** Scheduled backups not running

**Solutions:**
```bash
# Check cron jobs
crontab -l

# Test backup manually
php artisan whm:backup-server 1 --verbose

# Check disk space
df -h
```

#### Performance Issues

**Symptoms:** Slow response times

**Solutions:**
```bash
# Clear cache
php artisan cache:clear
php artisan config:clear

# Optimize database
php artisan optimize

# Check queue workers
php artisan queue:work --timeout=60
```

### Error Codes

| Code | Message | Solution |
|------|---------|----------|
| WHM-001 | Server connection failed | Check network/firewall |
| WHM-002 | Invalid API token | Regenerate token |
| WHM-003 | Quota exceeded | Increase server limits |
| WHM-004 | Account already exists | Use different username |
| WHM-005 | Package not found | Create package first |

### Debug Mode

Enable debug logging:

```env
APP_DEBUG=true
LOG_LEVEL=debug
WHM_DEBUG=true
```

View debug logs:

```bash
tail -f storage/logs/whm-debug.log
```

## Best Practices

### Server Configuration

1. **Load Balancing**: Distribute accounts across multiple servers
2. **Resource Planning**: Don't exceed 80% server capacity
3. **Regular Maintenance**: Schedule maintenance windows
4. **Monitoring**: Enable all monitoring alerts

### Account Management

1. **Username Standards**: Use consistent naming conventions
2. **Password Policy**: Enforce strong passwords
3. **Resource Limits**: Set appropriate quotas
4. **Regular Audits**: Review account usage monthly

### Backup Strategy

1. **Multiple Locations**: Store backups on-site and off-site
2. **Test Restores**: Regularly test backup restoration
3. **Retention Policy**: Keep at least 30 days of backups
4. **Encryption**: Always encrypt backup data

### Security

1. **API Access**: Use token rotation
2. **IP Restrictions**: Limit admin access by IP
3. **Audit Logs**: Review logs weekly
4. **Updates**: Keep system updated

### Performance

1. **Caching**: Enable Redis caching
2. **Queue Jobs**: Use queues for heavy operations
3. **Database**: Optimize queries and indexes
4. **CDN**: Use CDN for static assets

## Related Links

- [Installation Guide](installation.md)
- [API Documentation](../api/endpoints.md)
- [cPanel Integration](cpanel-integration.md)
- [Admin Panel Guide](admin-panel.md)
- [User Management](user-management.md)
- [Configuration Guide](configuration.md)
- [Security Best Practices](security.md)
- [Troubleshooting Guide](troubleshooting.md)
- [WHM API Documentation](https://api.cpanel.net/)

---

*Last updated: October 2024*
*Version: 2.0*
