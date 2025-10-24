# Quick Start Guide

Get up and running with the Hosting Management Platform in minutes.

## Prerequisites

Before you begin, ensure you have:
- A fresh CentOS/RHEL/AlmaLinux server
- Root or sudo access
- Internet connection
- Valid domain names pointing to your server

## 5-Minute Installation

### Step 1: Download Installer

```bash
wget https://raw.githubusercontent.com/juliobrasa/installer/master/scripts/install.sh
chmod +x install.sh
```

### Step 2: Run Installation

```bash
sudo ./install.sh
```

The installer will prompt you for:
- Domain names for each component
- Database passwords
- Admin email and password
- SSL certificate preferences

### Step 3: Access Your Panels

Once installation completes, access your panels:

- **WHM Panel**: `https://whm.yourdomain.com`
- **cPanel System**: `https://cpanel.yourdomain.com`
- **Admin Panel**: `https://admin.yourdomain.com`

Default admin credentials (change immediately):
- Email: `admin@example.com`
- Password: `admin123` (set during installation)

## First Steps

### 1. Secure Your Installation

```bash
# Change default admin password
cd /home/admin.soporteclientes.net
php artisan user:change-password admin@example.com
```

### 2. Add Your First WHM Server

1. Log into Admin Panel
2. Navigate to **Servers → Add Server**
3. Enter WHM server details:
   - Hostname: `server1.yourdomain.com`
   - IP Address: `192.168.1.100`
   - WHM Username: `root`
   - WHM API Token: (from WHM)
   - Port: `2087`
4. Click **Test Connection**
5. Click **Save**

### 3. Create Your First Package

1. Go to **Packages → Create Package**
2. Fill in package details:
   - Name: `Basic Hosting`
   - Disk Quota: `5000 MB`
   - Bandwidth: `50000 MB`
   - Max Email Accounts: `10`
   - Max Databases: `5`
   - Max Domains: `1`
3. Click **Create**

### 4. Create a Hosting Account

1. Navigate to **Accounts → Create Account**
2. Enter account information:
   - Domain: `example.com`
   - Username: `example`
   - Password: (generate secure password)
   - Email: `user@example.com`
   - Package: `Basic Hosting`
   - Server: `server1`
3. Click **Create Account**

### 5. Setup Billing (Optional)

1. Go to **Billing → Plans**
2. Create a billing plan:
   - Name: `Basic Plan`
   - Monthly Price: `$9.99`
   - Yearly Price: `$99.99`
   - Link to Package: `Basic Hosting`
3. Configure payment gateway:
   - Navigate to **Settings → Payment Gateways**
   - Enable Stripe/PayPal
   - Enter API credentials

## Common Tasks

### Create Reseller Account

```bash
cd /home/whm.soporteclientes.net/public_html
php artisan whm:create-reseller username --package=reseller_package
```

### Generate Invoice

```bash
cd /home/cpanel1.soporteclientes.net
php artisan billing:generate-invoices
```

### Backup Accounts

```bash
cd /home/whm.soporteclientes.net/public_html
php artisan backup:accounts --server=all
```

### View System Status

```bash
cd /home/admin.soporteclientes.net
php artisan system:health
```

## API Quick Start

### Get API Token

```bash
curl -X POST https://api.soporteclientes.net/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "your_password"
  }'
```

### Create Account via API

```bash
curl -X POST https://api.soporteclientes.net/v1/whm/accounts \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "newsite.com",
    "username": "newuser",
    "password": "SecurePass123!",
    "email": "user@newsite.com",
    "package": "basic",
    "server_id": 1
  }'
```

### List All Accounts

```bash
curl -X GET https://api.soporteclientes.net/v1/whm/accounts \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Configuration

### Environment Files

Each component has its own `.env` file:

- WHM Panel: `/home/whm.soporteclientes.net/public_html/.env`
- cPanel System: `/home/cpanel1.soporteclientes.net/.env`
- Admin Panel: `/home/admin.soporteclientes.net/.env`

### Key Settings

```bash
# Database
DB_DATABASE=your_database
DB_USERNAME=your_user
DB_PASSWORD=your_password

# Mail
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your_email@gmail.com
MAIL_PASSWORD=your_password

# Queue
QUEUE_CONNECTION=redis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379
```

## Monitoring

### Check Service Status

```bash
# Apache
sudo systemctl status httpd

# Database
sudo systemctl status mariadb

# Queue Workers
sudo systemctl status laravel-worker

# Check all
systemctl status httpd mariadb laravel-worker
```

### View Logs

```bash
# Apache logs
tail -f /var/log/httpd/error_log

# Application logs
tail -f /home/whm.soporteclientes.net/public_html/storage/logs/laravel.log
tail -f /home/cpanel1.soporteclientes.net/storage/logs/laravel.log
tail -f /home/admin.soporteclientes.net/storage/logs/laravel.log
```

## Troubleshooting

### Cannot Access Panels

1. Check firewall:
```bash
sudo firewall-cmd --list-all
```

2. Verify Apache is running:
```bash
sudo systemctl status httpd
```

3. Check DNS records:
```bash
dig whm.yourdomain.com
```

### Database Connection Error

1. Test MySQL connection:
```bash
mysql -u username -p database_name
```

2. Check `.env` credentials
3. Restart services:
```bash
sudo systemctl restart mariadb httpd
```

### Permission Issues

```bash
cd /home
sudo chown -R apache:apache whm.soporteclientes.net cpanel1.soporteclientes.net admin.soporteclientes.net
sudo chmod -R 755 */
sudo chmod -R 775 */storage */bootstrap/cache
```

### Clear Cache

```bash
cd /home/admin.soporteclientes.net
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
```

## Next Steps

Now that you're up and running:

1. [Complete Installation Guide](installation.md) - Full installation details
2. [Configuration Guide](configuration.md) - Advanced configuration
3. [Security Best Practices](security.md) - Secure your installation
4. [User Management](user-management.md) - Manage users and roles
5. [API Documentation](../api/overview.md) - Integrate with the API

## Getting Help

- Check logs for error messages
- Review [Troubleshooting Guide](troubleshooting.md)
- Contact support team
- Review GitHub issues

## Quick Reference

### Important Directories

- WHM: `/home/whm.soporteclientes.net/public_html`
- cPanel: `/home/cpanel1.soporteclientes.net`
- Admin: `/home/admin.soporteclientes.net`
- Backups: `/backup`
- Logs: `/var/log/httpd` and `*/storage/logs`

### Important Commands

```bash
# Restart services
sudo systemctl restart httpd mariadb

# Run migrations
php artisan migrate

# Clear cache
php artisan cache:clear

# Queue worker
php artisan queue:work

# Run scheduler
php artisan schedule:run

# Create user
php artisan make:user

# Backup
php artisan backup:run
```

---

*For detailed information, refer to the complete documentation.*
