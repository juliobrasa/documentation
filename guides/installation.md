# Installation Guide

Complete installation guide for the Hosting Management Platform.

## Table of Contents
1. [System Requirements](#system-requirements)
2. [Pre-installation](#pre-installation)
3. [Automatic Installation](#automatic-installation)
4. [Manual Installation](#manual-installation)
5. [Post-installation](#post-installation)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)

## System Requirements

### Minimum Requirements
- **OS**: CentOS 7/8, RHEL 7/8, AlmaLinux 8
- **RAM**: 1GB (2GB recommended)
- **CPU**: 1 core (2+ recommended)
- **Disk**: 2GB free space
- **Network**: Static IP, Internet connection

### Software Requirements
- PHP 8.0 or higher
- MySQL 5.7+ or MariaDB 10.3+
- Apache 2.4+ or Nginx 1.18+
- Composer 2.0+
- Node.js 14+ and NPM
- Git
- OpenSSL

## Pre-installation

### 1. Update System
```bash
sudo yum update -y
sudo yum upgrade -y
```

### 2. Configure Firewall
```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=8090/tcp
sudo firewall-cmd --reload
```

### 3. Set Hostname
```bash
sudo hostnamectl set-hostname your-server.domain.com
```

### 4. Configure SELinux (Optional)
```bash
sudo setenforce 0
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
```

## Automatic Installation

### Download and Run Installer
```bash
# Download installer
wget https://raw.githubusercontent.com/juliobrasa/installer/master/scripts/install.sh

# Make executable
chmod +x install.sh

# Run installer
sudo ./install.sh
```

The installer will:
1. Check system requirements
2. Install all dependencies
3. Configure databases
4. Setup all three components
5. Configure web server
6. Setup SSL certificates
7. Create services and cron jobs

## Manual Installation

### Step 1: Install Dependencies

```bash
# Install EPEL repository
sudo yum install -y epel-release

# Install Apache
sudo yum install -y httpd mod_ssl

# Install PHP
sudo yum install -y php php-cli php-common php-mysqlnd php-pdo \
    php-xml php-json php-mbstring php-bcmath php-gd php-zip php-curl

# Install MariaDB
sudo yum install -y mariadb-server mariadb

# Install Node.js
curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
sudo yum install -y nodejs

# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Install Git
sudo yum install -y git
```

### Step 2: Configure MariaDB

```bash
# Start MariaDB
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Secure installation
sudo mysql_secure_installation

# Create databases
mysql -u root -p << EOF
CREATE DATABASE whm_panel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE cpanel1db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE admindb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER 'whm_user'@'localhost' IDENTIFIED BY 'secure_password';
CREATE USER 'cpanel_user'@'localhost' IDENTIFIED BY 'secure_password';
CREATE USER 'admin_user'@'localhost' IDENTIFIED BY 'secure_password';

GRANT ALL PRIVILEGES ON whm_panel.* TO 'whm_user'@'localhost';
GRANT ALL PRIVILEGES ON cpanel1db.* TO 'cpanel_user'@'localhost';
GRANT ALL PRIVILEGES ON admindb.* TO 'admin_user'@'localhost';

FLUSH PRIVILEGES;
EOF
```

### Step 3: Install WHM Panel

```bash
# Create directory
sudo mkdir -p /home/whm.soporteclientes.net/public_html
cd /home/whm.soporteclientes.net/public_html

# Clone repository
git clone https://github.com/juliobrasa/whm.git .

# Install dependencies
composer install --no-dev --optimize-autoloader

# Configure environment
cp .env.example .env
php artisan key:generate

# Edit .env file with database credentials
nano .env

# Run migrations
php artisan migrate --seed

# Set permissions
sudo chown -R apache:apache /home/whm.soporteclientes.net
sudo chmod -R 755 /home/whm.soporteclientes.net
sudo chmod -R 775 storage bootstrap/cache
```

### Step 4: Install cPanel System

```bash
# Create directory
sudo mkdir -p /home/cpanel1.soporteclientes.net
cd /home/cpanel1.soporteclientes.net

# Clone repository
git clone https://github.com/juliobrasa/cpanel.git .

# Install dependencies
composer install --no-dev --optimize-autoloader
npm install
npm run production

# Configure and migrate
cp .env.example .env
php artisan key:generate
# Edit .env
php artisan migrate --seed

# Set permissions
sudo chown -R apache:apache /home/cpanel1.soporteclientes.net
sudo chmod -R 755 /home/cpanel1.soporteclientes.net
sudo chmod -R 775 storage bootstrap/cache
```

### Step 5: Install Admin Panel

```bash
# Create directory
sudo mkdir -p /home/admin.soporteclientes.net
cd /home/admin.soporteclientes.net

# Clone repository
git clone https://github.com/juliobrasa/admin-panel.git .

# Install dependencies
composer install --no-dev --optimize-autoloader
npm install
npm run production

# Configure and migrate
cp .env.example .env
php artisan key:generate
# Edit .env
php artisan migrate --seed

# Create admin user
php artisan tinker
>>> $user = new \App\Models\User;
>>> $user->name = 'Admin';
>>> $user->email = 'admin@example.com';
>>> $user->password = Hash::make('password');
>>> $user->save();
>>> exit

# Set permissions
sudo chown -R apache:apache /home/admin.soporteclientes.net
sudo chmod -R 755 /home/admin.soporteclientes.net
sudo chmod -R 775 storage bootstrap/cache
```

### Step 6: Configure Apache

Create virtual hosts:

```bash
# WHM Panel
sudo nano /etc/httpd/conf.d/whm.conf
```

```apache
<VirtualHost *:80>
    ServerName whm.soporteclientes.net
    DocumentRoot /home/whm.soporteclientes.net/public_html/public
    
    <Directory /home/whm.soporteclientes.net/public_html/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog /var/log/httpd/whm_error.log
    CustomLog /var/log/httpd/whm_access.log combined
</VirtualHost>
```

Repeat for cPanel and Admin Panel with appropriate paths.

```bash
# Restart Apache
sudo systemctl restart httpd
sudo systemctl enable httpd
```

### Step 7: Setup SSL

```bash
# Install Certbot
sudo yum install -y certbot python3-certbot-apache

# Get certificates
sudo certbot --apache -d whm.soporteclientes.net
sudo certbot --apache -d cpanel1.soporteclientes.net
sudo certbot --apache -d admin.soporteclientes.net

# Setup auto-renewal
echo "0 0,12 * * * root certbot renew -q" | sudo tee -a /etc/crontab
```

## Post-installation

### 1. Setup Cron Jobs

```bash
# Add Laravel schedulers
crontab -e
```

Add:
```
* * * * * cd /home/whm.soporteclientes.net/public_html && php artisan schedule:run >> /dev/null 2>&1
* * * * * cd /home/cpanel1.soporteclientes.net && php artisan schedule:run >> /dev/null 2>&1
* * * * * cd /home/admin.soporteclientes.net && php artisan schedule:run >> /dev/null 2>&1
```

### 2. Setup Queue Workers

Create systemd service:

```bash
sudo nano /etc/systemd/system/laravel-worker.service
```

```ini
[Unit]
Description=Laravel Queue Worker
After=network.target

[Service]
User=apache
Group=apache
Restart=always
ExecStart=/usr/bin/php /home/admin.soporteclientes.net/artisan queue:work --sleep=3 --tries=3

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable laravel-worker
sudo systemctl start laravel-worker
```

### 3. Configure Backups

```bash
# Create backup script
sudo nano /usr/local/bin/backup.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d)

# Backup databases
mysqldump --all-databases > $BACKUP_DIR/mysql_$DATE.sql

# Backup files
tar -czf $BACKUP_DIR/files_$DATE.tar.gz /home/*/

# Keep only last 30 days
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
```

```bash
chmod +x /usr/local/bin/backup.sh
echo "0 2 * * * root /usr/local/bin/backup.sh" >> /etc/crontab
```

## Verification

### Test Installation

```bash
# Run test script
wget https://raw.githubusercontent.com/juliobrasa/installer/master/tests/test_installation.sh
chmod +x test_installation.sh
./test_installation.sh
```

### Manual Verification

1. **Check Services**
   ```bash
   systemctl status httpd
   systemctl status mariadb
   systemctl status laravel-worker
   ```

2. **Test URLs**
   - WHM Panel: https://whm.soporteclientes.net
   - cPanel: https://cpanel1.soporteclientes.net
   - Admin: https://admin.soporteclientes.net

3. **Check Logs**
   ```bash
   tail -f /var/log/httpd/error_log
   tail -f /home/*/storage/logs/laravel.log
   ```

## Troubleshooting

### Common Issues

#### Permission Errors
```bash
sudo chown -R apache:apache /home/*/
sudo chmod -R 755 /home/*/
sudo chmod -R 775 /home/*/storage
sudo chmod -R 775 /home/*/bootstrap/cache
```

#### Database Connection Failed
- Check credentials in `.env` files
- Verify MySQL is running
- Test connection: `mysql -u user -p database`

#### 500 Internal Server Error
```bash
# Clear Laravel caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Check logs
tail -100 storage/logs/laravel.log
```

#### SSL Certificate Issues
```bash
# Test renewal
sudo certbot renew --dry-run

# Force renewal
sudo certbot renew --force-renewal
```

## Next Steps

1. Change default passwords
2. Configure email settings
3. Setup monitoring
4. Configure backups
5. Review security settings

For more information, see:
- [Configuration Guide](configuration.md)
- [Security Best Practices](security.md)
- [User Management](user-management.md)