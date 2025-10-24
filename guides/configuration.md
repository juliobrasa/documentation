# Configuration Guide

Comprehensive configuration guide for the Hosting Management Platform, covering all components and their settings.

## Table of Contents

1. [Overview](#overview)
2. [Environment Configuration](#environment-configuration)
3. [Database Configuration](#database-configuration)
4. [Web Server Configuration](#web-server-configuration)
5. [Cache and Session Configuration](#cache-and-session-configuration)
6. [Email Configuration](#email-configuration)
7. [Queue Configuration](#queue-configuration)
8. [WHM Panel Configuration](#whm-panel-configuration)
9. [Billing System Configuration](#billing-system-configuration)
10. [Security Configuration](#security-configuration)
11. [API Configuration](#api-configuration)
12. [Backup Configuration](#backup-configuration)
13. [Monitoring Configuration](#monitoring-configuration)
14. [Performance Optimization](#performance-optimization)
15. [Multi-Server Configuration](#multi-server-configuration)
16. [Advanced Configuration](#advanced-configuration)
17. [Troubleshooting](#troubleshooting)
18. [Best Practices](#best-practices)
19. [Related Links](#related-links)

## Overview

The Hosting Management Platform uses a centralized configuration system based on Laravel's environment variables and configuration files. This guide covers all configurable aspects of the system.

### Configuration Architecture

```
┌────────────────────────────────────────────────┐
│         Environment Variables (.env)           │
│         - Database credentials                 │
│         - API keys                             │
│         - Service endpoints                    │
└────────────────────┬───────────────────────────┘
                     │
┌────────────────────▼───────────────────────────┐
│         Configuration Files (config/)          │
│         - app.php (Application)                │
│         - database.php (Database)              │
│         - mail.php (Email)                     │
│         - services.php (External services)     │
└────────────────────┬───────────────────────────┘
                     │
┌────────────────────▼───────────────────────────┐
│         Runtime Configuration                  │
│         - Admin panel settings                 │
│         - Database-stored config               │
└────────────────────────────────────────────────┘
```

### Configuration Layers

1. **Environment Variables**: Sensitive data, environment-specific settings
2. **Configuration Files**: Application structure and defaults
3. **Database Settings**: Runtime configurable options
4. **Admin Panel**: User-friendly configuration interface

## Environment Configuration

### Basic Application Settings

Edit `.env` file:

```env
# Application
APP_NAME="Hosting Management Platform"
APP_ENV=production
APP_KEY=base64:GENERATED_KEY_HERE
APP_DEBUG=false
APP_URL=https://admin.soporteclientes.net

# Timezone
APP_TIMEZONE=UTC
APP_LOCALE=en
APP_FALLBACK_LOCALE=en

# Logging
LOG_CHANNEL=daily
LOG_LEVEL=info
LOG_DAYS=14
```

### Environment Types

Configure for different environments:

#### Production

```env
APP_ENV=production
APP_DEBUG=false
LOG_LEVEL=warning
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
```

#### Staging

```env
APP_ENV=staging
APP_DEBUG=false
LOG_LEVEL=info
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
```

#### Development

```env
APP_ENV=local
APP_DEBUG=true
LOG_LEVEL=debug
CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_CONNECTION=sync
```

### Debugging Configuration

```env
# Debug settings
APP_DEBUG=true
DEBUGBAR_ENABLED=true
TELESCOPE_ENABLED=true
LOG_QUERY=true
LOG_SLOW_QUERIES=true
QUERY_THRESHOLD=1000

# Error reporting
LOG_DEPRECATIONS=true
LOG_CHANNEL=stack
LOG_STACK=['daily', 'slack']
```

## Database Configuration

### Primary Database

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=admindb
DB_USERNAME=admin_user
DB_PASSWORD=secure_password
DB_CHARSET=utf8mb4
DB_COLLATION=utf8mb4_unicode_ci
```

### Multiple Database Connections

Configure in `config/database.php`:

```php
'connections' => [
    'admin' => [
        'driver' => 'mysql',
        'host' => env('DB_ADMIN_HOST', '127.0.0.1'),
        'database' => env('DB_ADMIN_DATABASE', 'admindb'),
        'username' => env('DB_ADMIN_USERNAME', 'admin_user'),
        'password' => env('DB_ADMIN_PASSWORD', ''),
    ],

    'whm' => [
        'driver' => 'mysql',
        'host' => env('DB_WHM_HOST', '127.0.0.1'),
        'database' => env('DB_WHM_DATABASE', 'whm_panel'),
        'username' => env('DB_WHM_USERNAME', 'whm_user'),
        'password' => env('DB_WHM_PASSWORD', ''),
    ],

    'billing' => [
        'driver' => 'mysql',
        'host' => env('DB_BILLING_HOST', '127.0.0.1'),
        'database' => env('DB_BILLING_DATABASE', 'cpanel1db'),
        'username' => env('DB_BILLING_USERNAME', 'cpanel_user'),
        'password' => env('DB_BILLING_PASSWORD', ''),
    ],
]
```

Add to `.env`:

```env
# Admin Database
DB_ADMIN_HOST=127.0.0.1
DB_ADMIN_DATABASE=admindb
DB_ADMIN_USERNAME=admin_user
DB_ADMIN_PASSWORD=secure_password

# WHM Database
DB_WHM_HOST=127.0.0.1
DB_WHM_DATABASE=whm_panel
DB_WHM_USERNAME=whm_user
DB_WHM_PASSWORD=secure_password

# Billing Database
DB_BILLING_HOST=127.0.0.1
DB_BILLING_DATABASE=cpanel1db
DB_BILLING_USERNAME=cpanel_user
DB_BILLING_PASSWORD=secure_password
```

### Database Optimization

```php
// config/database.php
'mysql' => [
    'driver' => 'mysql',
    'strict' => true,
    'engine' => 'InnoDB',
    'options' => extension_loaded('pdo_mysql') ? array_filter([
        PDO::MYSQL_ATTR_SSL_CA => env('MYSQL_ATTR_SSL_CA'),
        PDO::ATTR_PERSISTENT => true,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]) : [],
    'pool' => [
        'min_connections' => 5,
        'max_connections' => 20,
    ],
]
```

### Read/Write Splitting

Configure read replicas:

```php
// config/database.php
'mysql' => [
    'read' => [
        'host' => [
            '192.168.1.11', // Read replica 1
            '192.168.1.12', // Read replica 2
        ],
    ],
    'write' => [
        'host' => [
            '192.168.1.10', // Master
        ],
    ],
    'sticky' => true,
]
```

## Web Server Configuration

### Apache Configuration

#### Virtual Host Example

```apache
<VirtualHost *:443>
    ServerName admin.soporteclientes.net
    ServerAdmin admin@soporteclientes.net
    DocumentRoot /home/admin.soporteclientes.net/public

    <Directory /home/admin.soporteclientes.net/public>
        Options -Indexes +FollowSymLinks -MultiViews
        AllowOverride All
        Require all granted

        # Security headers
        Header always set X-Frame-Options "SAMEORIGIN"
        Header always set X-Content-Type-Options "nosniff"
        Header always set X-XSS-Protection "1; mode=block"
        Header always set Referrer-Policy "strict-origin-when-cross-origin"
        Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
    </Directory>

    # SSL Configuration
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/admin.soporteclientes.net/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/admin.soporteclientes.net/privkey.pem
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256
    SSLHonorCipherOrder on

    # Logging
    ErrorLog /var/log/httpd/admin_error.log
    CustomLog /var/log/httpd/admin_access.log combined

    # Compression
    <IfModule mod_deflate.c>
        AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript
    </IfModule>

    # Caching
    <IfModule mod_expires.c>
        ExpiresActive On
        ExpiresByType image/jpg "access plus 1 year"
        ExpiresByType image/jpeg "access plus 1 year"
        ExpiresByType image/gif "access plus 1 year"
        ExpiresByType image/png "access plus 1 year"
        ExpiresByType text/css "access plus 1 month"
        ExpiresByType application/javascript "access plus 1 month"
    </IfModule>
</VirtualHost>

# HTTP to HTTPS redirect
<VirtualHost *:80>
    ServerName admin.soporteclientes.net
    Redirect permanent / https://admin.soporteclientes.net/
</VirtualHost>
```

### Nginx Configuration

#### Server Block Example

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name admin.soporteclientes.net;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name admin.soporteclientes.net;
    root /home/admin.soporteclientes.net/public;

    index index.php index.html;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/admin.soporteclientes.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/admin.soporteclientes.net/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Logging
    access_log /var/log/nginx/admin_access.log;
    error_log /var/log/nginx/admin_error.log;

    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript;

    # Rate Limiting
    limit_req_zone $binary_remote_addr zone=admin:10m rate=10r/s;
    limit_req zone=admin burst=20 nodelay;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|ttf|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### PHP Configuration

Optimize `php.ini`:

```ini
[PHP]
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 100M
upload_max_filesize = 100M

[OpCache]
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=10000
opcache.revalidate_freq=2
opcache.validate_timestamps=0

[Session]
session.gc_maxlifetime = 7200
session.cookie_secure = 1
session.cookie_httponly = 1
session.cookie_samesite = "Lax"
```

## Cache and Session Configuration

### Redis Configuration

Install and configure Redis:

```bash
# Install Redis
sudo yum install redis -y

# Start Redis
sudo systemctl start redis
sudo systemctl enable redis

# Configure Redis
sudo nano /etc/redis.conf
```

Redis configuration:

```conf
bind 127.0.0.1
port 6379
requirepass your_redis_password
maxmemory 256mb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
```

Application configuration:

```env
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=your_redis_password
REDIS_PORT=6379
REDIS_DB=0

CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
```

### Cache Configuration

```php
// config/cache.php
'stores' => [
    'redis' => [
        'driver' => 'redis',
        'connection' => 'cache',
        'lock_connection' => 'default',
    ],

    'file' => [
        'driver' => 'file',
        'path' => storage_path('framework/cache/data'),
    ],
],

'prefix' => env('CACHE_PREFIX', 'hosting_'),
```

### Cache Strategies

```php
// config/cache.php
'cache_strategies' => [
    'users' => [
        'ttl' => 3600, // 1 hour
        'tags' => ['users'],
    ],
    'servers' => [
        'ttl' => 300, // 5 minutes
        'tags' => ['servers'],
    ],
    'settings' => [
        'ttl' => 86400, // 24 hours
        'tags' => ['settings'],
    ],
]
```

### Session Configuration

```php
// config/session.php
'driver' => env('SESSION_DRIVER', 'redis'),
'lifetime' => 120,
'expire_on_close' => false,
'encrypt' => true,
'files' => storage_path('framework/sessions'),
'connection' => 'session',
'table' => 'sessions',
'store' => null,
'lottery' => [2, 100],
'cookie' => env('SESSION_COOKIE', 'hosting_session'),
'path' => '/',
'domain' => env('SESSION_DOMAIN', null),
'secure' => env('SESSION_SECURE_COOKIE', true),
'http_only' => true,
'same_site' => 'lax',
```

## Email Configuration

### SMTP Configuration

```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=noreply@example.com
MAIL_PASSWORD=your_app_password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@example.com
MAIL_FROM_NAME="${APP_NAME}"
```

### Multiple Mail Drivers

Configure in `config/mail.php`:

```php
'mailers' => [
    'smtp' => [
        'transport' => 'smtp',
        'host' => env('MAIL_HOST', 'smtp.gmail.com'),
        'port' => env('MAIL_PORT', 587),
        'encryption' => env('MAIL_ENCRYPTION', 'tls'),
        'username' => env('MAIL_USERNAME'),
        'password' => env('MAIL_PASSWORD'),
    ],

    'ses' => [
        'transport' => 'ses',
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'mailgun' => [
        'transport' => 'mailgun',
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
    ],

    'sendgrid' => [
        'transport' => 'sendgrid',
        'api_key' => env('SENDGRID_API_KEY'),
    ],
]
```

### Email Templates Configuration

```php
// config/mail.php
'templates' => [
    'welcome' => [
        'subject' => 'Welcome to {company}',
        'from' => 'noreply@example.com',
        'template' => 'emails.welcome',
    ],
    'password_reset' => [
        'subject' => 'Reset Your Password',
        'from' => 'security@example.com',
        'template' => 'emails.password-reset',
    ],
    'invoice' => [
        'subject' => 'Invoice #{invoice_number}',
        'from' => 'billing@example.com',
        'template' => 'emails.invoice',
        'attach_pdf' => true,
    ],
]
```

### Email Queue Configuration

```php
// config/mail.php
'queue' => [
    'enabled' => true,
    'connection' => 'redis',
    'queue' => 'emails',
    'retry_after' => 90,
    'max_tries' => 3,
]
```

## Queue Configuration

### Queue Setup

```env
QUEUE_CONNECTION=redis
REDIS_QUEUE=default
QUEUE_FAILED_DRIVER=database
```

### Queue Workers Configuration

```php
// config/queue.php
'connections' => [
    'redis' => [
        'driver' => 'redis',
        'connection' => 'default',
        'queue' => env('REDIS_QUEUE', 'default'),
        'retry_after' => 90,
        'block_for' => null,
        'after_commit' => false,
    ],
]
```

### Horizon Configuration

```php
// config/horizon.php
'environments' => [
    'production' => [
        'supervisor-1' => [
            'connection' => 'redis',
            'queue' => ['default', 'emails', 'backups'],
            'balance' => 'auto',
            'processes' => 10,
            'tries' => 3,
            'timeout' => 300,
        ],
    ],
],

'waits' => [
    'redis:default' => 60,
    'redis:emails' => 30,
],

'trim' => [
    'recent' => 60,
    'pending' => 60,
    'completed' => 60,
    'failed' => 10080,
]
```

### Supervisor Configuration

```ini
[program:horizon]
process_name=%(program_name)s
command=/usr/bin/php /home/admin.soporteclientes.net/artisan horizon
autostart=true
autorestart=true
user=apache
redirect_stderr=true
stdout_logfile=/home/admin.soporteclientes.net/storage/logs/horizon.log
stopwaitsecs=3600

[program:queue-worker]
process_name=%(program_name)s_%(process_num)02d
command=/usr/bin/php /home/admin.soporteclientes.net/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=apache
numprocs=4
redirect_stderr=true
stdout_logfile=/home/admin.soporteclientes.net/storage/logs/worker.log
stopwaitsecs=3600
```

## WHM Panel Configuration

### WHM API Settings

```env
# WHM Panel Configuration
WHM_PANEL_URL=https://whm.soporteclientes.net
WHM_API_TIMEOUT=30
WHM_API_RETRIES=3
WHM_SYNC_INTERVAL=300

# Default WHM Server
DEFAULT_WHM_SERVER=1
```

### WHM Server Configuration

```php
// config/whm.php
'servers' => [
    'default' => [
        'hostname' => env('WHM_DEFAULT_HOSTNAME'),
        'port' => env('WHM_DEFAULT_PORT', 2087),
        'username' => env('WHM_DEFAULT_USERNAME', 'root'),
        'api_token' => env('WHM_DEFAULT_API_TOKEN'),
        'verify_ssl' => env('WHM_VERIFY_SSL', true),
    ],
],

'api' => [
    'timeout' => 30,
    'retries' => 3,
    'retry_delay' => 1000, // milliseconds
],

'sync' => [
    'enabled' => true,
    'interval' => 300, // seconds
    'batch_size' => 100,
],

'limits' => [
    'max_accounts_per_server' => 500,
    'disk_usage_warning' => 80, // percentage
    'bandwidth_warning' => 80,
]
```

### Package Defaults

```php
// config/whm.php
'default_package' => [
    'quota' => 1024, // MB
    'bandwidth' => 10240, // MB
    'max_emails' => 10,
    'max_databases' => 2,
    'max_ftp' => 5,
    'max_subdomains' => 5,
    'max_addon_domains' => 1,
    'cgi' => false,
    'shell' => false,
]
```

## Billing System Configuration

### Payment Gateway Configuration

#### Stripe

```env
STRIPE_KEY=pk_live_xxxxxxxxxxxxx
STRIPE_SECRET=sk_live_xxxxxxxxxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxx
```

```php
// config/services.php
'stripe' => [
    'key' => env('STRIPE_KEY'),
    'secret' => env('STRIPE_SECRET'),
    'webhook_secret' => env('STRIPE_WEBHOOK_SECRET'),
    'currency' => env('STRIPE_CURRENCY', 'usd'),
    'payment_methods' => ['card', 'sepa_debit', 'ideal'],
]
```

#### PayPal

```env
PAYPAL_MODE=live
PAYPAL_CLIENT_ID=xxxxxxxxxxxxx
PAYPAL_CLIENT_SECRET=xxxxxxxxxxxxx
PAYPAL_WEBHOOK_ID=xxxxxxxxxxxxx
```

```php
// config/services.php
'paypal' => [
    'mode' => env('PAYPAL_MODE', 'sandbox'),
    'client_id' => env('PAYPAL_CLIENT_ID'),
    'client_secret' => env('PAYPAL_CLIENT_SECRET'),
    'webhook_id' => env('PAYPAL_WEBHOOK_ID'),
]
```

### Billing Configuration

```php
// config/billing.php
'billing' => [
    'currency' => 'USD',
    'currency_symbol' => '$',
    'tax_enabled' => true,
    'tax_rate' => 18.0,
    'invoice_prefix' => 'INV-',
    'invoice_number_length' => 6,

    'cycles' => [
        'monthly' => 30,
        'quarterly' => 90,
        'semiannually' => 180,
        'annually' => 365,
        'biennially' => 730,
        'triennially' => 1095,
    ],

    'auto_renew' => true,
    'grace_period_days' => 7,
    'suspension_days' => 14,
    'termination_days' => 30,

    'late_fee' => [
        'enabled' => true,
        'percentage' => 5.0,
        'max_amount' => 50.00,
    ],
]
```

### Invoice Configuration

```php
// config/billing.php
'invoices' => [
    'auto_generate' => true,
    'generate_days_before' => 7,
    'due_days' => 14,
    'send_reminders' => true,
    'reminder_days' => [7, 3, 1, -1, -3, -7],
    'attach_pdf' => true,
    'logo_path' => public_path('images/logo.png'),
    'footer_text' => 'Thank you for your business',
]
```

## Security Configuration

### Authentication Settings

```php
// config/auth.php
'guards' => [
    'web' => [
        'driver' => 'session',
        'provider' => 'users',
    ],
    'api' => [
        'driver' => 'sanctum',
        'provider' => 'users',
    ],
],

'passwords' => [
    'users' => [
        'provider' => 'users',
        'table' => 'password_resets',
        'expire' => 60,
        'throttle' => 60,
    ],
],

'password_requirements' => [
    'min_length' => 12,
    'require_uppercase' => true,
    'require_lowercase' => true,
    'require_numbers' => true,
    'require_special_chars' => true,
    'prevent_common' => true,
    'password_history' => 5,
    'max_age_days' => 90,
]
```

### Security Headers

```php
// config/security.php
'headers' => [
    'X-Frame-Options' => 'SAMEORIGIN',
    'X-Content-Type-Options' => 'nosniff',
    'X-XSS-Protection' => '1; mode=block',
    'Referrer-Policy' => 'strict-origin-when-cross-origin',
    'Permissions-Policy' => 'geolocation=(), microphone=(), camera=()',
    'Strict-Transport-Security' => 'max-age=31536000; includeSubDomains',
]
```

### CORS Configuration

```php
// config/cors.php
'paths' => ['api/*'],
'allowed_methods' => ['*'],
'allowed_origins' => ['https://admin.soporteclientes.net'],
'allowed_origins_patterns' => [],
'allowed_headers' => ['*'],
'exposed_headers' => [],
'max_age' => 0,
'supports_credentials' => true,
```

### Rate Limiting

```php
// config/api.php
'rate_limits' => [
    'api' => [
        'requests' => 60,
        'per_minutes' => 1,
    ],
    'auth' => [
        'requests' => 5,
        'per_minutes' => 1,
    ],
    'admin' => [
        'requests' => 200,
        'per_minutes' => 1,
    ],
]
```

## API Configuration

### API Settings

```php
// config/api.php
'version' => 'v1',
'prefix' => 'api',
'middleware' => ['api', 'throttle:api'],

'authentication' => [
    'driver' => 'sanctum',
    'token_expiry' => 365, // days
    'personal_access_tokens' => true,
],

'pagination' => [
    'default_per_page' => 15,
    'max_per_page' => 100,
],

'response' => [
    'format' => 'json',
    'pretty_print' => env('API_PRETTY_PRINT', false),
    'include_meta' => true,
]
```

### API Documentation

```php
// config/l5-swagger.php
'documentations' => [
    'default' => [
        'api' => [
            'title' => 'Hosting Management Platform API',
            'version' => '2.0',
        ],
        'routes' => [
            'api' => 'api/documentation',
        ],
        'paths' => [
            'docs' => storage_path('api-docs'),
            'annotations' => [
                app_path('Http/Controllers/Api'),
            ],
        ],
    ],
]
```

## Backup Configuration

### Backup Settings

```php
// config/backup.php
'backup' => [
    'name' => env('APP_NAME', 'hosting-platform'),

    'source' => [
        'files' => [
            'include' => [
                base_path(),
            ],
            'exclude' => [
                base_path('vendor'),
                base_path('node_modules'),
                base_path('storage/framework'),
            ],
        ],

        'databases' => [
            'admindb',
            'whm_panel',
            'cpanel1db',
        ],
    ],

    'destination' => [
        'disks' => [
            'local',
            's3',
        ],
    ],

    'notifications' => [
        'mail' => [
            'to' => 'admin@example.com',
        ],
        'slack' => [
            'webhook_url' => env('BACKUP_SLACK_WEBHOOK'),
        ],
    ],
],

'cleanup' => [
    'strategy' => 'default',
    'defaultStrategy' => [
        'keepAllBackupsForDays' => 7,
        'keepDailyBackupsForDays' => 30,
        'keepWeeklyBackupsForWeeks' => 12,
        'keepMonthlyBackupsForMonths' => 12,
        'keepYearlyBackupsForYears' => 5,
        'deleteOldestBackupsWhenUsingMoreMegabytesThan' => 50000,
    ],
]
```

### S3 Backup Configuration

```env
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=hosting-backups
AWS_USE_PATH_STYLE_ENDPOINT=false
```

## Monitoring Configuration

### Logging Configuration

```php
// config/logging.php
'channels' => [
    'stack' => [
        'driver' => 'stack',
        'channels' => ['daily', 'slack'],
        'ignore_exceptions' => false,
    ],

    'daily' => [
        'driver' => 'daily',
        'path' => storage_path('logs/laravel.log'),
        'level' => env('LOG_LEVEL', 'debug'),
        'days' => 14,
    ],

    'slack' => [
        'driver' => 'slack',
        'url' => env('LOG_SLACK_WEBHOOK_URL'),
        'username' => 'Laravel Log',
        'emoji' => ':boom:',
        'level' => 'critical',
    ],
]
```

### Health Monitoring

```php
// config/health.php
'checks' => [
    'database' => [
        'enabled' => true,
        'timeout' => 5,
    ],
    'redis' => [
        'enabled' => true,
        'timeout' => 5,
    ],
    'disk_space' => [
        'enabled' => true,
        'threshold' => 80, // percentage
    ],
    'queue' => [
        'enabled' => true,
        'max_wait_time' => 300, // seconds
    ],
]
```

### Metrics Collection

```php
// config/metrics.php
'collectors' => [
    'system' => [
        'cpu' => true,
        'memory' => true,
        'disk' => true,
        'network' => true,
    ],
    'application' => [
        'requests' => true,
        'errors' => true,
        'slow_queries' => true,
        'queue_jobs' => true,
    ],
],

'retention' => [
    'raw' => 7, // days
    'hourly' => 30,
    'daily' => 365,
]
```

## Performance Optimization

### OpCache Configuration

```ini
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=10000
opcache.revalidate_freq=2
opcache.validate_timestamps=0
opcache.save_comments=1
opcache.fast_shutdown=1
```

### Laravel Optimization

```bash
# Production optimization commands
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache
php artisan optimize
```

### Asset Optimization

```javascript
// webpack.mix.js
mix.js('resources/js/app.js', 'public/js')
   .vue()
   .sass('resources/sass/app.scss', 'public/css')
   .version()
   .sourceMaps(false)
   .options({
       processCssUrls: false,
       terser: {
           terserOptions: {
               compress: {
                   drop_console: true,
               }
           }
       }
   });
```

## Multi-Server Configuration

### Load Balancer Configuration

Nginx load balancer example:

```nginx
upstream admin_backend {
    least_conn;
    server 192.168.1.10:443 weight=3;
    server 192.168.1.11:443 weight=2;
    server 192.168.1.12:443 weight=2;
    server 192.168.1.13:443 backup;
}

server {
    listen 443 ssl http2;
    server_name admin.soporteclientes.net;

    location / {
        proxy_pass https://admin_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Session Sharing

Configure for multi-server setup:

```env
SESSION_DRIVER=redis
REDIS_HOST=redis-cluster.example.com
CACHE_DRIVER=redis
```

### Database Replication

```php
// config/database.php
'mysql' => [
    'read' => [
        'host' => [
            'db-slave-1.example.com',
            'db-slave-2.example.com',
        ],
    ],
    'write' => [
        'host' => ['db-master.example.com'],
    ],
    'sticky' => true,
]
```

## Advanced Configuration

### Custom Configuration Files

Create custom configuration:

```bash
php artisan vendor:publish --tag=config
```

Example custom configuration:

```php
// config/hosting.php
return [
    'features' => [
        'auto_provisioning' => true,
        'instant_activation' => true,
        'trial_period_days' => 14,
        'affiliate_program' => true,
    ],

    'limits' => [
        'max_domains_per_customer' => 10,
        'max_email_accounts' => 100,
        'max_databases' => 25,
    ],

    'notifications' => [
        'welcome_email' => true,
        'renewal_reminders' => true,
        'payment_confirmations' => true,
        'server_alerts' => true,
    ],
];
```

### Environment-Specific Configuration

```php
// config/app.php
'debug' => env('APP_DEBUG', false),
'env_specific' => [
    'production' => [
        'cache_enabled' => true,
        'log_level' => 'warning',
    ],
    'staging' => [
        'cache_enabled' => true,
        'log_level' => 'info',
    ],
    'local' => [
        'cache_enabled' => false,
        'log_level' => 'debug',
    ],
]
```

## Troubleshooting

### Configuration Cache Issues

```bash
# Clear all caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Rebuild caches
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

### Environment Variable Not Loading

```bash
# Verify .env file exists
ls -la .env

# Check file permissions
chmod 644 .env

# Restart web server
sudo systemctl restart httpd
# or
sudo systemctl restart nginx

# Clear config cache
php artisan config:clear
```

### Database Connection Issues

```bash
# Test database connection
php artisan db:show

# Check credentials
mysql -u username -p database_name

# Verify .env database settings
grep DB_ .env
```

## Best Practices

### Configuration Management

1. **Version Control**: Never commit `.env` to version control
2. **Secrets Management**: Use encrypted storage for sensitive data
3. **Documentation**: Document all custom configuration
4. **Validation**: Validate configuration on deployment
5. **Backup**: Keep configuration backups

### Security

1. **SSL/TLS**: Always use HTTPS in production
2. **Strong Passwords**: Generate strong database passwords
3. **API Keys**: Rotate API keys regularly
4. **Permissions**: Set proper file permissions (644 for files, 755 for directories)
5. **Firewall**: Configure firewall rules

### Performance

1. **Caching**: Enable all appropriate caching
2. **OpCache**: Use PHP OpCache
3. **CDN**: Use CDN for static assets
4. **Database**: Optimize database queries
5. **Queue**: Use queues for heavy operations

### Monitoring

1. **Logging**: Configure comprehensive logging
2. **Alerts**: Set up monitoring alerts
3. **Metrics**: Collect performance metrics
4. **Health Checks**: Regular health monitoring
5. **Backups**: Automated daily backups

## Related Links

- [Installation Guide](installation.md)
- [Admin Panel Guide](admin-panel.md)
- [User Management Guide](user-management.md)
- [WHM Panel Guide](whm-panel.md)
- [cPanel Integration Guide](cpanel-integration.md)
- [Security Best Practices](security.md)
- [API Documentation](../api/endpoints.md)
- [Troubleshooting Guide](troubleshooting.md)

---

*Last updated: October 2024*
*Version: 2.0*
