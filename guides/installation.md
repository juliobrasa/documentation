# Installation Guide

Complete installation guide for the Hosting Management Platform on Proxmox VMs.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Proxmox VM Setup](#proxmox-vm-setup)
3. [Base System Installation](#base-system-installation)
4. [Application Installation](#application-installation)
5. [Docker Setup (Admin VM)](#docker-setup-admin-vm)
6. [Post-installation](#post-installation)
7. [Verification](#verification)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements
- **Proxmox VE**: 8.x (hypervisor configured)
- **VM OS**: Debian 13 (Trixie)
- **RAM**: 2GB per VM (4GB for admin)
- **Disk**: 20GB per VM (40GB for admin)
- **Network**: 10.0.0.x private network configured

### Software Requirements
- PHP 8.4 or higher
- MariaDB 11.8+
- Nginx 1.27+
- Composer 2.7+
- Git
- Docker (admin VM only)

## Proxmox VM Setup

### 1. Create VM Template

```bash
# Download Debian 13 cloud image
wget https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2

# Create VM template
qm create 9000 --memory 2048 --cores 2 --name debian13-template \
    --net0 virtio,bridge=vmbr0

# Import disk
qm importdisk 9000 debian-13-generic-amd64.qcow2 local-lvm

# Configure VM
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0

# Convert to template
qm template 9000
```

### 2. Clone VMs from Template

```bash
# Clone for each application
qm clone 9000 100 --name cuentas --full
qm clone 9000 101 --name gestionpiso --full
qm clone 9000 102 --name devostelio --full
qm clone 9000 103 --name admin --full
qm clone 9000 104 --name ips --full
qm clone 9000 105 --name kavia --full

# Set IP addresses
qm set 100 --ipconfig0 ip=10.0.0.100/24,gw=10.0.0.1
qm set 101 --ipconfig0 ip=10.0.0.101/24,gw=10.0.0.1
qm set 102 --ipconfig0 ip=10.0.0.102/24,gw=10.0.0.1
qm set 103 --ipconfig0 ip=10.0.0.103/24,gw=10.0.0.1
qm set 104 --ipconfig0 ip=10.0.0.104/24,gw=10.0.0.1
qm set 105 --ipconfig0 ip=10.0.0.105/24,gw=10.0.0.1

# Resize disk for admin VM
qm resize 103 scsi0 +20G

# Start VMs
for i in 100 101 102 103 104 105; do qm start $i; done
```

## Base System Installation

Run these commands on each VM.

### 1. Update System

```bash
apt update && apt upgrade -y
```

### 2. Set Hostname

```bash
# Example for admin VM
hostnamectl set-hostname admin-soporteclientes
```

### 3. Install Base Packages

```bash
apt install -y \
    nginx \
    php8.4-fpm php8.4-cli php8.4-common php8.4-mysql \
    php8.4-xml php8.4-mbstring php8.4-curl php8.4-zip \
    php8.4-gd php8.4-bcmath php8.4-intl php8.4-soap \
    php8.4-opcache php8.4-redis \
    mariadb-server mariadb-client \
    git curl wget unzip supervisor certbot \
    python3-certbot-nginx
```

### 4. Install Composer

```bash
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer
```

### 5. Configure MariaDB

```bash
# Start and enable MariaDB
systemctl enable mariadb
systemctl start mariadb

# Secure installation
mysql_secure_installation

# Create database and user
mysql -u root -p << 'EOF'
CREATE DATABASE appdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'appuser'@'localhost' IDENTIFIED BY 'secure_password';
GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'localhost';
FLUSH PRIVILEGES;
EOF
```

### 6. Configure PHP-FPM

```bash
# Edit PHP configuration
cat > /etc/php/8.4/fpm/conf.d/99-custom.ini << 'EOF'
memory_limit = 256M
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 300
max_input_time = 300
date.timezone = UTC
opcache.enable = 1
opcache.memory_consumption = 128
EOF

# Restart PHP-FPM
systemctl restart php8.4-fpm
```

## Application Installation

### 1. Create Application Directory

```bash
# Create directory structure
mkdir -p /var/www/app
chown -R www-data:www-data /var/www/app
```

### 2. Clone Repository

```bash
cd /var/www/app

# Clone the appropriate repository
git clone https://github.com/juliobrasa/[repo-name].git .

# Install PHP dependencies
composer install --no-dev --optimize-autoloader
```

### 3. Configure Environment

```bash
# Copy environment file
cp .env.example .env

# Generate application key
php artisan key:generate

# Edit environment variables
nano .env
```

Example `.env` configuration:
```env
APP_NAME="Application"
APP_ENV=production
APP_DEBUG=false
APP_URL=https://app.domain.com

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=appdb
DB_USERNAME=appuser
DB_PASSWORD=secure_password

CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_CONNECTION=database
```

### 4. Run Migrations

```bash
php artisan migrate --seed
```

### 5. Set Permissions

```bash
chown -R www-data:www-data /var/www/app
chmod -R 755 /var/www/app
chmod -R 775 /var/www/app/storage
chmod -R 775 /var/www/app/bootstrap/cache
```

### 6. Configure Nginx

```bash
cat > /etc/nginx/sites-available/app << 'EOF'
server {
    listen 80;
    server_name app.domain.com;
    root /var/www/app/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

# Enable site
ln -s /etc/nginx/sites-available/app /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

# Test and reload
nginx -t
systemctl reload nginx
```

### 7. Setup SSL

```bash
certbot --nginx -d app.domain.com
```

### 8. Configure Supervisor for Queue Worker

```bash
cat > /etc/supervisor/conf.d/laravel-worker.conf << 'EOF'
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/app/artisan queue:work --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/app/storage/logs/worker.log
stopwaitsecs=3600
EOF

supervisorctl reread
supervisorctl update
supervisorctl start laravel-worker:*
```

### 9. Setup Cron

```bash
crontab -e
```

Add:
```
* * * * * cd /var/www/app && php artisan schedule:run >> /dev/null 2>&1
```

## Docker Setup (Admin VM)

For the admin VM (10.0.0.103) with SOLTIA system.

### 1. Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh

# Add user to docker group
usermod -aG docker www-data

# Enable Docker
systemctl enable docker
systemctl start docker

# Install Docker Compose
apt install -y docker-compose-plugin
```

### 2. Create Docker Compose Configuration

```bash
mkdir -p /opt/docker
cat > /opt/docker/docker-compose.yml << 'EOF'
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    container_name: redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes

  elasticsearch:
    image: elasticsearch:8.11.0
    container_name: elasticsearch
    restart: unless-stopped
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
    ports:
      - "9200:9200"
    volumes:
      - es_data:/usr/share/elasticsearch/data
    ulimits:
      memlock:
        soft: -1
        hard: -1

  qdrant:
    image: qdrant/qdrant:latest
    container_name: qdrant
    restart: unless-stopped
    ports:
      - "6333:6333"
    volumes:
      - qdrant_data:/qdrant/storage

  postgresql:
    image: postgres:16-alpine
    container_name: postgresql
    restart: unless-stopped
    environment:
      POSTGRES_DB: rag_db
      POSTGRES_USER: rag_user
      POSTGRES_PASSWORD: ${PG_PASSWORD:-secure_password}
    ports:
      - "5432:5432"
    volumes:
      - pg_data:/var/lib/postgresql/data

volumes:
  redis_data:
  es_data:
  qdrant_data:
  pg_data:
EOF
```

### 3. Start Docker Services

```bash
cd /opt/docker
docker compose up -d
```

### 4. Verify Services

```bash
# Check all containers are running
docker ps

# Test connections
curl -s http://localhost:9200 | head -5
curl -s http://localhost:6333/health
redis-cli ping
```

## Post-installation

### 1. Setup Firewall

```bash
apt install -y ufw

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH, HTTP, HTTPS
ufw allow ssh
ufw allow http
ufw allow https

# Enable firewall
ufw enable
```

### 2. Configure Backups

```bash
# Create backup script
cat > /usr/local/bin/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)
APP_DIR="/var/www/app"

mkdir -p $BACKUP_DIR

# Backup database
mysqldump -u appuser -p'secure_password' appdb | gzip > $BACKUP_DIR/db_$DATE.sql.gz

# Backup files
tar -czf $BACKUP_DIR/files_$DATE.tar.gz $APP_DIR/storage

# Keep only last 7 days
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete
EOF

chmod +x /usr/local/bin/backup.sh

# Add to cron
echo "0 2 * * * /usr/local/bin/backup.sh" >> /var/spool/cron/crontabs/root
```

### 3. Optimize Laravel

```bash
cd /var/www/app

# Cache configuration
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Optimize autoloader
composer dump-autoload --optimize
```

## Verification

### 1. Check Services

```bash
# Web server
systemctl status nginx

# PHP-FPM
systemctl status php8.4-fpm

# Database
systemctl status mariadb

# Queue workers
supervisorctl status

# Docker (admin VM)
docker ps
```

### 2. Test Application

```bash
# Laravel health check
php artisan about

# Check routes
php artisan route:list | head -20

# Test HTTP response
curl -I https://app.domain.com
```

### 3. Check Logs

```bash
# Nginx logs
tail -f /var/log/nginx/error.log

# Laravel logs
tail -f /var/www/app/storage/logs/laravel.log

# PHP-FPM logs
journalctl -u php8.4-fpm -f
```

## Troubleshooting

### Permission Errors

```bash
chown -R www-data:www-data /var/www/app
chmod -R 755 /var/www/app
chmod -R 775 /var/www/app/storage /var/www/app/bootstrap/cache
```

### 500 Internal Server Error

```bash
# Check Laravel logs
tail -100 /var/www/app/storage/logs/laravel.log

# Clear all caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
```

### Database Connection Failed

```bash
# Test connection
mysql -u appuser -p appdb

# Check credentials in .env
grep DB_ /var/www/app/.env

# Verify MariaDB is running
systemctl status mariadb
```

### Nginx Configuration Issues

```bash
# Test configuration
nginx -t

# Check error log
tail -50 /var/log/nginx/error.log
```

### Docker Issues (Admin VM)

```bash
# Check container logs
docker logs elasticsearch
docker logs qdrant
docker logs redis

# Restart services
cd /opt/docker
docker compose restart
```

### SSL Certificate Issues

```bash
# Test renewal
certbot renew --dry-run

# Force renewal
certbot renew --force-renewal
```

## VM-Specific Installation

### Admin VM (10.0.0.103)

```bash
# Additional packages
apt install -y php8.4-pgsql

# Environment additions
echo "
REDIS_HOST=127.0.0.1
ELASTICSEARCH_HOST=127.0.0.1
QDRANT_HOST=127.0.0.1
OPENAI_API_KEY=your_key_here
" >> /var/www/admin/.env
```

### Application VMs (100-105)

Follow the standard installation procedure above, adjusting:
- Hostname
- Database name
- Domain name
- Git repository

## Next Steps

After installation:

1. Change default passwords
2. Configure email settings
3. Setup monitoring
4. Test backup and restore
5. Review security settings
6. Configure SOLTIA agents (admin VM)

For more information, see:
- [System Requirements](requirements.md)
- [Proxmox Infrastructure](../architecture/infrastructure-proxmox.md)
- [Security Best Practices](security.md)
