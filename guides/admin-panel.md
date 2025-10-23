# Admin Panel Guide

Complete guide to the centralized administration and monitoring panel for the Hosting Management Platform.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Installation and Setup](#installation-and-setup)
4. [Dashboard](#dashboard)
5. [User Management](#user-management)
6. [System Configuration](#system-configuration)
7. [API Management](#api-management)
8. [Audit Logging](#audit-logging)
9. [Health Monitoring](#health-monitoring)
10. [Report Generation](#report-generation)
11. [Database Management](#database-management)
12. [Email Configuration](#email-configuration)
13. [Backup and Recovery](#backup-and-recovery)
14. [Security Settings](#security-settings)
15. [Performance Optimization](#performance-optimization)
16. [Troubleshooting](#troubleshooting)
17. [Best Practices](#best-practices)
18. [Related Links](#related-links)

## Overview

The Admin Panel serves as the central command center for the entire Hosting Management Platform. It provides administrators with comprehensive tools for system management, monitoring, configuration, and analytics.

### Key Features

- **Unified Dashboard**: Single pane of glass for all system metrics
- **User & Role Management**: Complete access control system
- **System Configuration**: Centralized configuration management
- **API Management**: API key generation and monitoring
- **Audit Logging**: Complete audit trail of all actions
- **Real-time Monitoring**: Live system health and performance metrics
- **Report Generation**: Comprehensive reporting and analytics
- **Multi-component Control**: Manage WHM Panel and cPanel System
- **Email Management**: Configure and monitor email delivery
- **Backup Management**: Automated backup scheduling and recovery

### Technology Stack

- **Framework**: Laravel 9.x
- **Frontend**: Vue.js 3 + Tailwind CSS + Chart.js
- **Database**: MySQL 8.0+ / MariaDB 10.5+
- **Cache**: Redis
- **Queue**: Laravel Horizon
- **Monitoring**: Laravel Telescope
- **Real-time**: Laravel Echo + Pusher/Socket.io

## Architecture

### System Design

```
┌──────────────────────────────────────────────────┐
│         Admin Panel Interface (Vue.js)           │
│  ┌──────────┬──────────┬──────────┬──────────┐  │
│  │Dashboard │  Users   │  Config  │   Logs   │  │
│  └──────────┴──────────┴──────────┴──────────┘  │
└────────────────────┬─────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────┐
│         Admin API (Laravel Backend)              │
│  ┌──────────┬──────────┬──────────┬──────────┐  │
│  │   Auth   │  Audit   │  Health  │ Reports  │  │
│  └──────────┴──────────┴──────────┴──────────┘  │
└────────────────────┬─────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
   ┌─────────┐  ┌─────────┐  ┌─────────┐
   │   WHM   │  │ cPanel  │  │  MySQL  │
   │  Panel  │  │ System  │  │  Redis  │
   └─────────┘  └─────────┘  └─────────┘
```

### Database Schema

Primary tables in `admindb`:

- `users` - System users
- `roles` - User roles
- `permissions` - Granular permissions
- `role_permission` - Role-permission mapping
- `audit_logs` - Complete audit trail
- `api_tokens` - API access tokens
- `settings` - System configuration
- `health_metrics` - System health data
- `scheduled_tasks` - Cron job management
- `notifications` - System notifications

### Security Model

- **Role-Based Access Control (RBAC)**
- **Permission-based authorization**
- **Multi-factor authentication (MFA)**
- **IP whitelisting**
- **Session management**
- **API token scoping**

## Installation and Setup

### Prerequisites

```bash
# Required software
- PHP 8.0+ with extensions
- MySQL 8.0+ or MariaDB 10.5+
- Redis server
- Composer 2.0+
- Node.js 14+ and NPM
- Supervisor (for queue workers)
```

### Installation Steps

```bash
# Create installation directory
sudo mkdir -p /home/admin.soporteclientes.net

# Navigate to directory
cd /home/admin.soporteclientes.net

# Clone repository
git clone https://github.com/juliobrasa/admin-panel.git .

# Install PHP dependencies
composer install --no-dev --optimize-autoloader

# Install frontend dependencies
npm install
npm run production

# Setup environment
cp .env.example .env
php artisan key:generate
```

### Database Setup

Create database:

```bash
mysql -u root -p
```

```sql
CREATE DATABASE admindb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'admin_user'@'localhost' IDENTIFIED BY 'secure_password';
GRANT ALL PRIVILEGES ON admindb.* TO 'admin_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

Configure `.env`:

```env
APP_NAME="Admin Panel"
APP_ENV=production
APP_DEBUG=false
APP_URL=https://admin.soporteclientes.net

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=admindb
DB_USERNAME=admin_user
DB_PASSWORD=secure_password

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
```

### Run Migrations

```bash
php artisan migrate --seed
```

### Create Super Admin

```bash
php artisan admin:create-super-admin
```

Interactive prompts:
```
Name: System Administrator
Email: admin@example.com
Password: [enter secure password]
Confirm Password: [confirm password]
```

Or via tinker:

```bash
php artisan tinker
```

```php
$admin = new \App\Models\User;
$admin->name = 'System Administrator';
$admin->email = 'admin@example.com';
$admin->password = Hash::make('SecurePassword123!');
$admin->email_verified_at = now();
$admin->save();

$superAdminRole = \App\Models\Role::where('name', 'super-admin')->first();
$admin->roles()->attach($superAdminRole);

exit
```

### Web Server Configuration

Apache VirtualHost example:

```apache
<VirtualHost *:443>
    ServerName admin.soporteclientes.net
    DocumentRoot /home/admin.soporteclientes.net/public

    <Directory /home/admin.soporteclientes.net/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/admin.soporteclientes.net/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/admin.soporteclientes.net/privkey.pem

    ErrorLog /var/log/httpd/admin_error.log
    CustomLog /var/log/httpd/admin_access.log combined
</VirtualHost>
```

### Queue Workers Setup

Configure Supervisor:

```bash
sudo nano /etc/supervisord.d/admin-worker.ini
```

```ini
[program:admin-worker]
process_name=%(program_name)s_%(process_num)02d
command=/usr/bin/php /home/admin.soporteclientes.net/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=apache
numprocs=2
redirect_stderr=true
stdout_logfile=/home/admin.soporteclientes.net/storage/logs/worker.log
stopwaitsecs=3600

[program:admin-horizon]
process_name=%(program_name)s
command=/usr/bin/php /home/admin.soporteclientes.net/artisan horizon
autostart=true
autorestart=true
user=apache
redirect_stderr=true
stdout_logfile=/home/admin.soporteclientes.net/storage/logs/horizon.log
stopwaitsecs=3600
```

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start admin-worker:*
sudo supervisorctl start admin-horizon:*
```

## Dashboard

### Overview Dashboard

The main dashboard provides:

- **System Status**: Overall health indicator
- **Quick Stats**: Key metrics at a glance
- **Recent Activity**: Latest system events
- **Resource Usage**: CPU, memory, disk charts
- **Active Users**: Currently logged in users
- **Alerts**: System warnings and notifications

### Widgets

Customize dashboard widgets:

```bash
# Available widgets
php artisan admin:list-widgets

# Enable widget
php artisan admin:enable-widget revenue-chart

# Configure widget
php artisan admin:configure-widget system-health \
  --refresh-interval=30 \
  --show-details=true
```

### Real-time Updates

Dashboard auto-refreshes using Laravel Echo:

```javascript
// resources/js/dashboard.js
Echo.private('admin.dashboard')
    .listen('MetricsUpdated', (e) => {
        updateDashboard(e.metrics);
    })
    .listen('AlertCreated', (e) => {
        showAlert(e.alert);
    });
```

### Custom Metrics

Add custom metrics to dashboard:

```php
// app/Metrics/CustomMetric.php
class ActiveSubscriptionsMetric extends Metric
{
    public function calculate()
    {
        return [
            'value' => Subscription::active()->count(),
            'change' => $this->calculateChange(),
            'trend' => $this->getTrend()
        ];
    }
}
```

Register in dashboard:

```php
// config/dashboard.php
'metrics' => [
    'active_subscriptions' => \App\Metrics\ActiveSubscriptionsMetric::class,
    'monthly_revenue' => \App\Metrics\MonthlyRevenueMetric::class,
    'server_uptime' => \App\Metrics\ServerUptimeMetric::class,
]
```

## User Management

### User Administration

Admin panel provides complete user management:

- Create/edit/delete users
- Assign roles and permissions
- Set user status (active/inactive/suspended)
- Password reset
- Session management
- Activity tracking

### Creating Users

#### Via Web Interface

Navigate to **Users > Create New User**

```yaml
User Information:
  Name: John Doe
  Email: john@example.com
  Password: [auto-generate or manual]
  Status: Active

Role Assignment:
  Primary Role: Administrator
  Additional Roles: [optional]

Permissions:
  Custom Permissions: [optional overrides]

Notifications:
  Send Welcome Email: Yes
  Require Password Change: No
```

#### Via Command Line

```bash
php artisan admin:create-user \
  --name="John Doe" \
  --email=john@example.com \
  --role=administrator \
  --send-email
```

#### Via API

```bash
curl -X POST https://admin.soporteclientes.net/api/v1/admin/users \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "SecurePassword123!",
    "role": "administrator",
    "permissions": ["users.view", "users.create"],
    "send_welcome_email": true
  }'
```

### Role Management

Define custom roles:

```bash
# Create role
php artisan admin:create-role \
  --name="Support Manager" \
  --slug=support-manager \
  --description="Manages support tickets and knowledge base"

# Assign permissions
php artisan admin:assign-permissions support-manager \
  --permissions=tickets.view,tickets.create,tickets.update,kb.manage
```

**Predefined Roles:**

- **Super Admin**: Full system access
- **Administrator**: System management without destructive operations
- **Manager**: Department-level management
- **Support**: Customer support access
- **Billing**: Financial and billing access
- **Technical**: Server and infrastructure access
- **Viewer**: Read-only access

### Permission System

Granular permissions:

```php
// Define permissions
$permissions = [
    'users.view',
    'users.create',
    'users.update',
    'users.delete',
    'roles.manage',
    'settings.view',
    'settings.update',
    'logs.view',
    'reports.generate',
    'api.manage',
    'servers.view',
    'servers.manage',
    'billing.view',
    'billing.manage',
];
```

Check permissions in code:

```php
// Check single permission
if ($user->can('users.create')) {
    // Allow action
}

// Check multiple permissions
if ($user->hasAllPermissions(['users.view', 'users.update'])) {
    // Allow action
}

// Check any permission
if ($user->hasAnyPermission(['billing.view', 'billing.manage'])) {
    // Allow action
}
```

### Two-Factor Authentication

Enable 2FA for users:

```bash
# Enable for user
php artisan admin:enable-2fa john@example.com

# Force 2FA for role
php artisan admin:require-2fa --role=administrator

# Disable 2FA
php artisan admin:disable-2fa john@example.com
```

Configure 2FA settings:

```php
// config/auth.php
'two_factor' => [
    'enabled' => true,
    'method' => 'totp', // totp, sms, email
    'required_roles' => ['super-admin', 'administrator'],
    'remember_device_days' => 30,
    'backup_codes' => 8
]
```

## System Configuration

### Configuration Interface

Centralized configuration management:

```bash
# View all settings
php artisan admin:config-list

# Get specific setting
php artisan admin:config-get mail.from.address

# Set configuration
php artisan admin:config-set mail.from.address support@example.com

# Reset to default
php artisan admin:config-reset mail.from.address
```

### Configuration Categories

#### General Settings

```yaml
Site Configuration:
  Site Name: Hosting Management Platform
  Site URL: https://admin.soporteclientes.net
  Admin Email: admin@example.com
  Timezone: America/New_York
  Date Format: Y-m-d H:i:s
  Language: en
```

#### Email Settings

```yaml
Mail Configuration:
  Driver: smtp
  Host: smtp.gmail.com
  Port: 587
  Encryption: tls
  Username: noreply@example.com
  Password: [encrypted]
  From Address: noreply@example.com
  From Name: Hosting Platform
```

#### Security Settings

```yaml
Security Configuration:
  Session Lifetime: 120 minutes
  Password Min Length: 12
  Password Require Special: Yes
  Max Login Attempts: 5
  Lockout Duration: 15 minutes
  Force HTTPS: Yes
  IP Whitelist: [enabled/disabled]
```

#### Integration Settings

```yaml
WHM Panel Integration:
  Enabled: Yes
  API Endpoint: https://whm.soporteclientes.net/api
  API Token: [encrypted]
  Sync Interval: 5 minutes

cPanel System Integration:
  Enabled: Yes
  API Endpoint: https://cpanel1.soporteclientes.net/api
  API Token: [encrypted]
  Sync Interval: 5 minutes
```

### Environment Variables

Manage environment variables:

```bash
# List all env variables
php artisan admin:env-list

# Set environment variable
php artisan admin:env-set APP_DEBUG false

# View .env file
php artisan admin:env-show
```

### Configuration Backup

Backup configuration:

```bash
# Export configuration
php artisan admin:export-config --output=/backup/config.json

# Import configuration
php artisan admin:import-config /backup/config.json

# Version control
php artisan admin:config-snapshot "Before major update"
```

## API Management

### API Token Management

Generate and manage API tokens:

```bash
# Generate token
php artisan admin:generate-token \
  --user=admin@example.com \
  --name="Integration Token" \
  --scopes=users.view,servers.manage \
  --expires=365

# List tokens
php artisan admin:list-tokens

# Revoke token
php artisan admin:revoke-token TOKEN_ID

# Rotate token
php artisan admin:rotate-token TOKEN_ID
```

### Token Scopes

Define API access scopes:

```php
// Available scopes
$scopes = [
    'users.*',          // All user operations
    'users.view',       // View users only
    'servers.*',        // All server operations
    'billing.*',        // All billing operations
    'reports.generate', // Generate reports
    'logs.view',        // View logs
];
```

### API Rate Limiting

Configure rate limits:

```php
// config/api.php
'rate_limits' => [
    'default' => [
        'requests' => 60,
        'per_minutes' => 1
    ],
    'authenticated' => [
        'requests' => 100,
        'per_minutes' => 1
    ],
    'admin' => [
        'requests' => 200,
        'per_minutes' => 1
    ]
]
```

### API Monitoring

Monitor API usage:

```bash
# View API statistics
php artisan admin:api-stats

# Monitor specific token
php artisan admin:api-usage --token=TOKEN_ID

# Export API logs
php artisan admin:export-api-logs \
  --from=2024-01-01 \
  --to=2024-12-31 \
  --format=csv
```

## Audit Logging

### Automatic Audit Logging

All administrative actions are automatically logged:

```php
// Logged events
- User login/logout
- User creation/modification/deletion
- Role/permission changes
- Configuration changes
- API token generation/revocation
- System settings updates
- Database operations
```

### Viewing Audit Logs

```bash
# View recent logs
php artisan admin:audit-logs --limit=100

# Filter by user
php artisan admin:audit-logs --user=admin@example.com

# Filter by action
php artisan admin:audit-logs --action=user.deleted

# Filter by date range
php artisan admin:audit-logs \
  --from=2024-10-01 \
  --to=2024-10-31
```

### Audit Log Format

```json
{
  "id": 12345,
  "user_id": 1,
  "user_email": "admin@example.com",
  "action": "user.created",
  "description": "Created user: john@example.com",
  "ip_address": "192.168.1.100",
  "user_agent": "Mozilla/5.0...",
  "old_values": null,
  "new_values": {
    "name": "John Doe",
    "email": "john@example.com",
    "role": "administrator"
  },
  "created_at": "2024-10-23 10:30:45"
}
```

### Log Retention

Configure log retention:

```php
// config/audit.php
'retention' => [
    'days' => 365,
    'archive_old_logs' => true,
    'archive_path' => storage_path('logs/archive'),
    'compress_archives' => true
]
```

### Export Audit Logs

```bash
# Export to CSV
php artisan admin:export-audit-logs \
  --format=csv \
  --output=/tmp/audit-logs.csv

# Export to JSON
php artisan admin:export-audit-logs \
  --format=json \
  --from=2024-01-01
```

## Health Monitoring

### System Health Checks

Automated health monitoring:

```bash
# Run health check
php artisan admin:health-check

# Detailed health report
php artisan admin:health-check --detailed

# Specific component check
php artisan admin:health-check --component=database
```

### Health Check Components

```yaml
Health Checks:
  - Database Connection
  - Redis Connection
  - Disk Space
  - Memory Usage
  - CPU Load
  - Queue Workers
  - Scheduled Tasks
  - Email Service
  - WHM Panel Connectivity
  - cPanel System Connectivity
  - SSL Certificates
  - API Endpoints
```

### Monitoring Dashboard

Access monitoring at `/admin/monitoring`

**Metrics Displayed:**

```yaml
System Resources:
  - CPU Usage: [graph]
  - Memory Usage: [graph]
  - Disk Usage: [graph]
  - Network Traffic: [graph]

Services:
  - Web Server: [status]
  - Database: [status]
  - Redis Cache: [status]
  - Queue Workers: [status]

Components:
  - WHM Panel: [status]
  - cPanel System: [status]
  - Email Service: [status]
```

### Alerts Configuration

Setup automated alerts:

```php
// config/monitoring.php
'alerts' => [
    'disk_space' => [
        'enabled' => true,
        'threshold' => 85, // percentage
        'notify' => ['admin@example.com'],
        'channels' => ['email', 'slack']
    ],
    'cpu_usage' => [
        'enabled' => true,
        'threshold' => 90,
        'duration' => 5, // minutes
        'notify' => ['admin@example.com'],
        'channels' => ['email', 'slack']
    ],
    'memory_usage' => [
        'enabled' => true,
        'threshold' => 85,
        'notify' => ['admin@example.com'],
        'channels' => ['email']
    ],
    'service_down' => [
        'enabled' => true,
        'check_interval' => 60, // seconds
        'notify' => ['admin@example.com', 'ops@example.com'],
        'channels' => ['email', 'slack', 'sms']
    ]
]
```

### Custom Health Checks

Create custom health checks:

```php
// app/HealthChecks/CustomCheck.php
namespace App\HealthChecks;

use Spatie\Health\Checks\Check;
use Spatie\Health\Checks\Result;

class LicenseServerCheck extends Check
{
    public function run(): Result
    {
        $isReachable = $this->checkLicenseServer();

        return $isReachable
            ? Result::make()->ok()
            : Result::make()->failed('License server unreachable');
    }

    protected function checkLicenseServer(): bool
    {
        // Implementation
        return true;
    }
}
```

## Report Generation

### Available Reports

```bash
# List available reports
php artisan admin:list-reports

# Generate report
php artisan admin:generate-report revenue --month=10 --year=2024

# Schedule report
php artisan admin:schedule-report revenue \
  --frequency=monthly \
  --recipients=admin@example.com,finance@example.com
```

### Report Types

#### System Reports

```yaml
System Performance:
  - CPU Usage Over Time
  - Memory Usage Trends
  - Disk I/O Statistics
  - Network Traffic Analysis

Application Reports:
  - User Activity Log
  - API Usage Statistics
  - Error Rate Analysis
  - Response Time Metrics
```

#### Business Reports

```yaml
Financial Reports:
  - Revenue by Month
  - Revenue by Product
  - Outstanding Invoices
  - Payment Methods Breakdown
  - Refund Analysis

Customer Reports:
  - New Customers
  - Churn Rate
  - Customer Lifetime Value
  - Subscription Growth
  - Active Subscriptions

Server Reports:
  - Resource Utilization
  - Account Distribution
  - Package Popularity
  - Bandwidth Usage
```

### Custom Reports

Create custom reports:

```bash
# Generate report builder
php artisan admin:make-report CustomerGrowthReport
```

```php
// app/Reports/CustomerGrowthReport.php
namespace App\Reports;

class CustomerGrowthReport extends Report
{
    public function generate($startDate, $endDate)
    {
        $data = Customer::whereBetween('created_at', [$startDate, $endDate])
            ->selectRaw('DATE(created_at) as date, COUNT(*) as count')
            ->groupBy('date')
            ->get();

        return $this->formatReport([
            'title' => 'Customer Growth Report',
            'period' => "{$startDate} to {$endDate}",
            'data' => $data,
            'chart' => $this->generateChart($data)
        ]);
    }
}
```

### Export Formats

Reports can be exported in multiple formats:

```bash
# Export as PDF
php artisan admin:export-report revenue --format=pdf

# Export as Excel
php artisan admin:export-report revenue --format=xlsx

# Export as CSV
php artisan admin:export-report revenue --format=csv

# Email report
php artisan admin:email-report revenue \
  --to=admin@example.com \
  --format=pdf
```

## Database Management

### Database Operations

```bash
# Backup database
php artisan admin:db-backup

# Restore database
php artisan admin:db-restore /path/to/backup.sql

# Optimize database
php artisan admin:db-optimize

# Check database integrity
php artisan admin:db-check
```

### Query Monitor

Monitor database queries:

```bash
# Enable query logging
php artisan admin:enable-query-log

# View slow queries
php artisan admin:slow-queries --threshold=1000

# Analyze query performance
php artisan admin:analyze-queries
```

### Database Maintenance

```bash
# Vacuum deleted records
php artisan admin:db-vacuum

# Update statistics
php artisan admin:db-analyze

# Rebuild indexes
php artisan admin:db-reindex

# Check table sizes
php artisan admin:db-table-sizes
```

## Email Configuration

### Email Settings

Configure email delivery:

```yaml
SMTP Configuration:
  Driver: smtp
  Host: smtp.example.com
  Port: 587
  Encryption: tls
  Username: noreply@example.com
  Password: [secure]

Email Preferences:
  From Name: Hosting Platform
  From Address: noreply@example.com
  Reply-To: support@example.com
  Footer: Include company footer
```

### Email Templates

Manage email templates:

```bash
# List templates
php artisan admin:email-templates

# Edit template
php artisan admin:edit-template welcome

# Test template
php artisan admin:test-email welcome \
  --recipient=test@example.com
```

### Email Queue

Monitor email queue:

```bash
# View queue
php artisan admin:email-queue

# Retry failed emails
php artisan admin:retry-emails

# Clear email queue
php artisan admin:clear-email-queue --failed-only
```

## Backup and Recovery

### Automated Backups

Configure automated backups:

```php
// config/backup.php
'backup' => [
    'schedule' => 'daily',
    'time' => '02:00',
    'databases' => ['admindb', 'whm_panel', 'cpanel1db'],
    'files' => [
        '/home/admin.soporteclientes.net',
        '/home/whm.soporteclientes.net',
        '/home/cpanel1.soporteclientes.net'
    ],
    'compression' => 'gzip',
    'encryption' => true,
    'retention_days' => 30
]
```

### Backup Operations

```bash
# Manual backup
php artisan admin:backup

# Backup specific component
php artisan admin:backup --only=database

# Backup with encryption
php artisan admin:backup --encrypt --password=SecurePass

# List backups
php artisan admin:list-backups

# Delete old backups
php artisan admin:cleanup-backups --older-than=30
```

### Recovery

```bash
# Restore from backup
php artisan admin:restore /path/to/backup.tar.gz

# Restore specific database
php artisan admin:restore-database admindb \
  --backup=/path/to/backup.sql

# Test restore (dry-run)
php artisan admin:restore /path/to/backup.tar.gz --dry-run
```

## Security Settings

### Security Hardening

```bash
# Run security audit
php artisan admin:security-audit

# Enable security features
php artisan admin:enable-security-features

# Check for vulnerabilities
php artisan admin:check-vulnerabilities
```

### Access Control

```yaml
IP Whitelisting:
  Enabled: Yes
  Allowed IPs:
    - 192.168.1.0/24
    - 10.0.0.0/8

Session Security:
  Secure Cookies: Yes
  HTTP Only: Yes
  Same Site: Strict
  Lifetime: 120 minutes

Password Policy:
  Min Length: 12
  Require Uppercase: Yes
  Require Lowercase: Yes
  Require Numbers: Yes
  Require Special: Yes
  Password History: 5
  Max Age: 90 days
```

### Security Logs

```bash
# View security events
php artisan admin:security-logs

# Export security logs
php artisan admin:export-security-logs \
  --from=2024-10-01 \
  --format=csv
```

## Performance Optimization

### Caching

```bash
# Clear all caches
php artisan admin:clear-cache

# Optimize for production
php artisan optimize

# Cache configuration
php artisan config:cache

# Cache routes
php artisan route:cache

# Cache views
php artisan view:cache
```

### Performance Monitoring

```bash
# Check performance
php artisan admin:performance-check

# Analyze slow requests
php artisan admin:slow-requests

# Memory profiling
php artisan admin:memory-profile
```

## Troubleshooting

### Common Issues

#### Cannot Login to Admin Panel

**Symptoms:** Login fails with credentials

**Solutions:**
```bash
# Reset admin password
php artisan admin:reset-password admin@example.com

# Check user status
php artisan admin:user-info admin@example.com

# Clear sessions
php artisan session:clear

# Check logs
tail -f storage/logs/laravel.log
```

#### Dashboard Not Loading

**Symptoms:** Dashboard shows errors or blank page

**Solutions:**
```bash
# Clear cache
php artisan cache:clear
php artisan view:clear

# Check permissions
sudo chown -R apache:apache storage/
sudo chmod -R 775 storage/

# Rebuild assets
npm run production

# Check JavaScript console for errors
```

#### Queue Workers Not Processing

**Symptoms:** Background jobs not running

**Solutions:**
```bash
# Check supervisor status
sudo supervisorctl status

# Restart workers
sudo supervisorctl restart admin-worker:*

# Check queue
php artisan queue:work --once

# View failed jobs
php artisan queue:failed
```

### Debug Mode

Enable debugging:

```env
APP_DEBUG=true
APP_ENV=local
LOG_LEVEL=debug
```

### Log Files

Check relevant logs:

```bash
# Application logs
tail -f storage/logs/laravel.log

# Worker logs
tail -f storage/logs/worker.log

# Apache logs
tail -f /var/log/httpd/admin_error.log
```

## Best Practices

### Administration

1. **Regular Backups**: Daily automated backups
2. **Security Updates**: Keep system updated
3. **Audit Reviews**: Weekly audit log reviews
4. **Health Monitoring**: Configure all alerts
5. **Documentation**: Document all changes

### Access Management

1. **Least Privilege**: Grant minimum required permissions
2. **Regular Audits**: Review user access quarterly
3. **2FA Enforcement**: Require 2FA for admin roles
4. **Session Management**: Reasonable session timeouts
5. **API Security**: Rotate API tokens regularly

### Performance

1. **Cache Usage**: Enable all appropriate caches
2. **Queue Jobs**: Background processing for heavy tasks
3. **Database Optimization**: Regular index optimization
4. **Asset Optimization**: Minify and compress assets
5. **CDN Usage**: Use CDN for static assets

### Monitoring

1. **Alert Configuration**: Set appropriate thresholds
2. **Regular Checks**: Daily health check reviews
3. **Performance Metrics**: Monitor trends
4. **Capacity Planning**: Proactive resource planning
5. **Incident Response**: Documented procedures

## Related Links

- [Installation Guide](installation.md)
- [WHM Panel Guide](whm-panel.md)
- [cPanel Integration Guide](cpanel-integration.md)
- [User Management Guide](user-management.md)
- [Configuration Guide](configuration.md)
- [API Documentation](../api/endpoints.md)
- [Security Best Practices](security.md)
- [Troubleshooting Guide](troubleshooting.md)

---

*Last updated: October 2024*
*Version: 2.0*
