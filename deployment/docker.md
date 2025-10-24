# Docker Deployment Guide

Complete guide for deploying the Hosting Management Platform using Docker containers.

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Docker Architecture](#docker-architecture)
4. [Installation](#installation)
5. [Container Configuration](#container-configuration)
6. [Docker Compose Setup](#docker-compose-setup)
7. [Network Configuration](#network-configuration)
8. [Volume Management](#volume-management)
9. [Environment Variables](#environment-variables)
10. [Building Custom Images](#building-custom-images)
11. [Orchestration](#orchestration)
12. [Security Best Practices](#security-best-practices)
13. [Monitoring and Logging](#monitoring-and-logging)
14. [Troubleshooting](#troubleshooting)
15. [Production Deployment](#production-deployment)

## Overview

This guide provides comprehensive instructions for containerizing and deploying the Hosting Management Platform using Docker. Docker provides consistent environments, easy scaling, and simplified deployment workflows.

### Benefits of Docker Deployment
- **Consistency**: Same environment across development, staging, and production
- **Isolation**: Each service runs in its own container
- **Portability**: Deploy anywhere Docker is supported
- **Scalability**: Easy horizontal scaling with container orchestration
- **Resource Efficiency**: Better resource utilization than traditional VMs
- **Rapid Deployment**: Quick startup and deployment times

## Prerequisites

### System Requirements

#### Minimum Requirements
- **OS**: CentOS 8, RHEL 8, Ubuntu 20.04 LTS, or Debian 11
- **CPU**: 4 cores (8+ recommended)
- **RAM**: 8GB (16GB+ recommended)
- **Disk**: 100GB SSD (fast I/O recommended)
- **Docker**: 20.10 or higher
- **Docker Compose**: 2.0 or higher

#### For Production
- **CPU**: 8+ cores
- **RAM**: 32GB+
- **Disk**: 500GB+ SSD with RAID
- **Network**: 1Gbps+ connection
- **Backup Storage**: Separate backup location

### Software Prerequisites
- Docker Engine 20.10+
- Docker Compose v2.0+
- Git
- OpenSSL
- curl/wget

### Knowledge Prerequisites
- Basic Docker concepts (containers, images, volumes, networks)
- Docker Compose syntax
- Linux system administration
- Basic networking concepts

## Docker Architecture

### Container Layout

```
┌─────────────────────────────────────────────────┐
│              Load Balancer (Traefik)            │
│                  Port 80/443                    │
└────────────┬──────────────┬─────────────────────┘
             │              │
    ┌────────▼─────┐  ┌────▼──────┐  ┌──────────┐
    │   WHM Panel  │  │  cPanel   │  │  Admin   │
    │  Container   │  │ Container │  │Container │
    │   (PHP-FPM)  │  │ (PHP-FPM) │  │(PHP-FPM) │
    └────────┬─────┘  └────┬──────┘  └────┬─────┘
             │              │              │
             └──────────────┼──────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
    ┌────▼─────┐    ┌──────▼────┐    ┌───────▼────┐
    │  MySQL   │    │   Redis   │    │  PHP-FPM   │
    │Container │    │ Container │    │  Workers   │
    └──────────┘    └───────────┘    └────────────┘
```

### Network Architecture
- **Frontend Network**: Handles external traffic to web containers
- **Backend Network**: Internal communication between application and services
- **Database Network**: Isolated network for database access

## Installation

### Step 1: Install Docker Engine

#### CentOS/RHEL 8

```bash
# Remove old versions
sudo yum remove docker docker-client docker-client-latest \
    docker-common docker-latest docker-latest-logrotate \
    docker-logrotate docker-engine

# Add Docker repository
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verify installation
sudo docker --version
sudo docker compose version
```

#### Ubuntu 20.04/22.04

```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verify installation
sudo docker --version
sudo docker compose version
```

### Step 2: Configure Docker

```bash
# Add current user to docker group
sudo usermod -aG docker $USER

# Configure Docker daemon
sudo mkdir -p /etc/docker
sudo nano /etc/docker/daemon.json
```

Add configuration:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true,
  "userland-proxy": false,
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
```

```bash
# Restart Docker
sudo systemctl restart docker

# Verify configuration
sudo docker info
```

### Step 3: Install Docker Compose (Standalone - Optional)

```bash
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

## Container Configuration

### Dockerfile for WHM Panel

```dockerfile
# /var/www/hosting-platform/whm/Dockerfile
FROM php:8.2-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    bash \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    oniguruma-dev \
    libzip-dev \
    icu-dev \
    postgresql-dev \
    mysql-client \
    nginx \
    supervisor

# Install PHP extensions
RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    mysqli \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    xml \
    zip \
    intl \
    opcache

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create application directory
WORKDIR /var/www/html

# Copy application files
COPY . .

# Install dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Copy PHP configuration
COPY docker/php/php.ini /usr/local/etc/php/php.ini
COPY docker/php/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

# Copy Supervisor configuration
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose port
EXPOSE 9000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD php artisan health:check || exit 1

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
```

### PHP Configuration (php.ini)

```ini
# docker/php/php.ini
[PHP]
engine = On
short_open_tag = Off
precision = 14
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func =
serialize_precision = -1
disable_functions = exec,passthru,shell_exec,system,proc_open,popen
disable_classes =
zend.enable_gc = On
expose_php = Off
max_execution_time = 60
max_input_time = 60
memory_limit = 512M
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = Off
display_startup_errors = Off
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
variables_order = "GPCS"
request_order = "GP"
register_argc_argv = Off
auto_globals_jit = On
post_max_size = 64M
auto_prepend_file =
auto_append_file =
default_mimetype = "text/html"
default_charset = "UTF-8"
doc_root =
user_dir =
enable_dl = Off
file_uploads = On
upload_max_filesize = 64M
max_file_uploads = 20
allow_url_fopen = On
allow_url_include = Off
default_socket_timeout = 60

[Date]
date.timezone = UTC

[Session]
session.save_handler = redis
session.save_path = "tcp://redis:6379?auth=YOUR_REDIS_PASSWORD"
session.use_strict_mode = 1
session.use_cookies = 1
session.use_only_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.cookie_domain =
session.cookie_httponly = 1
session.cookie_secure = 1
session.cookie_samesite = Strict
session.serialize_handler = php
session.gc_probability = 1
session.gc_divisor = 1000
session.gc_maxlifetime = 1440

[opcache]
opcache.enable = 1
opcache.enable_cli = 0
opcache.memory_consumption = 256
opcache.interned_strings_buffer = 16
opcache.max_accelerated_files = 10000
opcache.revalidate_freq = 2
opcache.fast_shutdown = 1
opcache.validate_timestamps = 0
```

### PHP-FPM Configuration

```ini
# docker/php/php-fpm.conf
[www]
user = www-data
group = www-data
listen = 9000
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 500
pm.status_path = /fpm-status
ping.path = /fpm-ping
access.log = /proc/self/fd/2
slowlog = /proc/self/fd/2
request_slowlog_timeout = 10s
catch_workers_output = yes
clear_env = no
```

### Supervisor Configuration

```ini
# docker/supervisor/supervisord.conf
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:php-fpm]
command=/usr/local/sbin/php-fpm -F
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
autorestart=true
startretries=3

[program:queue-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=4
redirect_stderr=true
stdout_logfile=/var/www/html/storage/logs/worker.log
stopwaitsecs=3600

[program:schedule]
command=/bin/sh -c "while [ true ]; do (php /var/www/html/artisan schedule:run --verbose --no-interaction &); sleep 60; done"
autostart=true
autorestart=true
stdout_logfile=/var/www/html/storage/logs/scheduler.log
stderr_logfile=/var/www/html/storage/logs/scheduler.log
```

## Docker Compose Setup

### Complete docker-compose.yml

```yaml
# docker-compose.yml
version: '3.8'

services:
  # Traefik Load Balancer
  traefik:
    image: traefik:v2.10
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - frontend
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik/traefik.yml:/traefik.yml:ro
      - ./traefik/acme.json:/acme.json
      - ./traefik/config.yml:/config.yml:ro
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.entrypoints=http"
      - "traefik.http.routers.traefik.rule=Host(`traefik.yourdomain.com`)"
      - "traefik.http.middlewares.traefik-auth.basicauth.users=admin:$$apr1$$..."
      - "traefik.http.middlewares.traefik-https-redirect.redirectscheme.scheme=https"
      - "traefik.http.routers.traefik.middlewares=traefik-https-redirect"
      - "traefik.http.routers.traefik-secure.entrypoints=https"
      - "traefik.http.routers.traefik-secure.rule=Host(`traefik.yourdomain.com`)"
      - "traefik.http.routers.traefik-secure.middlewares=traefik-auth"
      - "traefik.http.routers.traefik-secure.tls=true"
      - "traefik.http.routers.traefik-secure.tls.certresolver=cloudflare"
      - "traefik.http.routers.traefik-secure.service=api@internal"
    environment:
      - CF_API_EMAIL=${CLOUDFLARE_EMAIL}
      - CF_DNS_API_TOKEN=${CLOUDFLARE_API_TOKEN}

  # MySQL Database
  mysql:
    image: mysql:8.0
    container_name: mysql
    restart: unless-stopped
    networks:
      - backend
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./mysql/my.cnf:/etc/mysql/conf.d/custom.cnf:ro
      - ./mysql/init:/docker-entrypoint-initdb.d:ro
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
    command: --default-authentication-plugin=mysql_native_password
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: redis
    restart: unless-stopped
    networks:
      - backend
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
      - ./redis/redis.conf:/usr/local/etc/redis/redis.conf:ro
    command: redis-server /usr/local/etc/redis/redis.conf
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  # WHM Panel Application
  whm:
    build:
      context: ./whm
      dockerfile: Dockerfile
    container_name: whm
    restart: unless-stopped
    networks:
      - frontend
      - backend
    volumes:
      - ./whm:/var/www/html
      - whm_storage:/var/www/html/storage
    environment:
      - APP_NAME=WHM Panel
      - APP_ENV=production
      - APP_DEBUG=false
      - APP_URL=https://whm.yourdomain.com
      - DB_CONNECTION=mysql
      - DB_HOST=mysql
      - DB_PORT=3306
      - DB_DATABASE=${WHM_DB_NAME}
      - DB_USERNAME=${WHM_DB_USER}
      - DB_PASSWORD=${WHM_DB_PASSWORD}
      - CACHE_DRIVER=redis
      - SESSION_DRIVER=redis
      - QUEUE_CONNECTION=redis
      - REDIS_HOST=redis
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - REDIS_PORT=6379
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.whm.entrypoints=http"
      - "traefik.http.routers.whm.rule=Host(`whm.yourdomain.com`)"
      - "traefik.http.middlewares.whm-https-redirect.redirectscheme.scheme=https"
      - "traefik.http.routers.whm.middlewares=whm-https-redirect"
      - "traefik.http.routers.whm-secure.entrypoints=https"
      - "traefik.http.routers.whm-secure.rule=Host(`whm.yourdomain.com`)"
      - "traefik.http.routers.whm-secure.tls=true"
      - "traefik.http.routers.whm-secure.tls.certresolver=cloudflare"
      - "traefik.http.routers.whm-secure.service=whm"
      - "traefik.http.services.whm.loadbalancer.server.port=9000"
      - "traefik.docker.network=frontend"

  # cPanel Application
  cpanel:
    build:
      context: ./cpanel
      dockerfile: Dockerfile
    container_name: cpanel
    restart: unless-stopped
    networks:
      - frontend
      - backend
    volumes:
      - ./cpanel:/var/www/html
      - cpanel_storage:/var/www/html/storage
    environment:
      - APP_NAME=cPanel
      - APP_ENV=production
      - APP_DEBUG=false
      - APP_URL=https://cpanel.yourdomain.com
      - DB_CONNECTION=mysql
      - DB_HOST=mysql
      - DB_PORT=3306
      - DB_DATABASE=${CPANEL_DB_NAME}
      - DB_USERNAME=${CPANEL_DB_USER}
      - DB_PASSWORD=${CPANEL_DB_PASSWORD}
      - CACHE_DRIVER=redis
      - SESSION_DRIVER=redis
      - QUEUE_CONNECTION=redis
      - REDIS_HOST=redis
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - REDIS_PORT=6379
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.cpanel.entrypoints=http"
      - "traefik.http.routers.cpanel.rule=Host(`cpanel.yourdomain.com`)"
      - "traefik.http.middlewares.cpanel-https-redirect.redirectscheme.scheme=https"
      - "traefik.http.routers.cpanel.middlewares=cpanel-https-redirect"
      - "traefik.http.routers.cpanel-secure.entrypoints=https"
      - "traefik.http.routers.cpanel-secure.rule=Host(`cpanel.yourdomain.com`)"
      - "traefik.http.routers.cpanel-secure.tls=true"
      - "traefik.http.routers.cpanel-secure.tls.certresolver=cloudflare"
      - "traefik.http.routers.cpanel-secure.service=cpanel"
      - "traefik.http.services.cpanel.loadbalancer.server.port=9000"
      - "traefik.docker.network=frontend"

  # Admin Panel Application
  admin:
    build:
      context: ./admin
      dockerfile: Dockerfile
    container_name: admin
    restart: unless-stopped
    networks:
      - frontend
      - backend
    volumes:
      - ./admin:/var/www/html
      - admin_storage:/var/www/html/storage
    environment:
      - APP_NAME=Admin Panel
      - APP_ENV=production
      - APP_DEBUG=false
      - APP_URL=https://admin.yourdomain.com
      - DB_CONNECTION=mysql
      - DB_HOST=mysql
      - DB_PORT=3306
      - DB_DATABASE=${ADMIN_DB_NAME}
      - DB_USERNAME=${ADMIN_DB_USER}
      - DB_PASSWORD=${ADMIN_DB_PASSWORD}
      - CACHE_DRIVER=redis
      - SESSION_DRIVER=redis
      - QUEUE_CONNECTION=redis
      - REDIS_HOST=redis
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - REDIS_PORT=6379
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.admin.entrypoints=http"
      - "traefik.http.routers.admin.rule=Host(`admin.yourdomain.com`)"
      - "traefik.http.middlewares.admin-https-redirect.redirectscheme.scheme=https"
      - "traefik.http.routers.admin.middlewares=admin-https-redirect"
      - "traefik.http.routers.admin-secure.entrypoints=https"
      - "traefik.http.routers.admin-secure.rule=Host(`admin.yourdomain.com`)"
      - "traefik.http.routers.admin-secure.tls=true"
      - "traefik.http.routers.admin-secure.tls.certresolver=cloudflare"
      - "traefik.http.routers.admin-secure.service=admin"
      - "traefik.http.services.admin.loadbalancer.server.port=9000"
      - "traefik.docker.network=frontend"

  # Nginx Web Server
  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: unless-stopped
    networks:
      - frontend
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./whm:/var/www/whm:ro
      - ./cpanel:/var/www/cpanel:ro
      - ./admin:/var/www/admin:ro
    depends_on:
      - whm
      - cpanel
      - admin
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=frontend"

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true

volumes:
  mysql_data:
    driver: local
  redis_data:
    driver: local
  whm_storage:
    driver: local
  cpanel_storage:
    driver: local
  admin_storage:
    driver: local
```

### Environment Variables (.env)

```bash
# .env
# MySQL Configuration
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_DATABASE=hosting_platform
MYSQL_USER=hosting_user
MYSQL_PASSWORD=your_secure_mysql_password

# WHM Database
WHM_DB_NAME=whm_panel
WHM_DB_USER=whm_user
WHM_DB_PASSWORD=your_secure_whm_password

# cPanel Database
CPANEL_DB_NAME=cpanel1db
CPANEL_DB_USER=cpanel_user
CPANEL_DB_PASSWORD=your_secure_cpanel_password

# Admin Database
ADMIN_DB_NAME=admindb
ADMIN_DB_USER=admin_user
ADMIN_DB_PASSWORD=your_secure_admin_password

# Redis Configuration
REDIS_PASSWORD=your_secure_redis_password

# Cloudflare Configuration (for SSL)
CLOUDFLARE_EMAIL=your@email.com
CLOUDFLARE_API_TOKEN=your_cloudflare_api_token

# Application Keys (generate with: openssl rand -base64 32)
WHM_APP_KEY=base64:your_generated_key_here
CPANEL_APP_KEY=base64:your_generated_key_here
ADMIN_APP_KEY=base64:your_generated_key_here
```

## Network Configuration

### Traefik Configuration

```yaml
# traefik/traefik.yml
api:
  dashboard: true
  debug: false

entryPoints:
  http:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: https
          scheme: https
  https:
    address: ":443"

serversTransport:
  insecureSkipVerify: true

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
  file:
    filename: /config.yml

certificatesResolvers:
  cloudflare:
    acme:
      email: your@email.com
      storage: acme.json
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "1.0.0.1:53"

log:
  level: INFO
  filePath: /var/log/traefik/traefik.log

accessLog:
  filePath: /var/log/traefik/access.log
```

### Nginx Configuration

```nginx
# nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 64M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript
               application/json application/javascript application/xml+rss
               application/rss+xml font/truetype font/opentype
               application/vnd.ms-fontobject image/svg+xml;

    # Include virtual host configurations
    include /etc/nginx/conf.d/*.conf;
}
```

```nginx
# nginx/conf.d/whm.conf
server {
    listen 80;
    server_name whm.yourdomain.com;
    root /var/www/whm/public;
    index index.php index.html;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass whm:9000;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

## Volume Management

### Creating Named Volumes

```bash
# Create volumes manually
docker volume create mysql_data
docker volume create redis_data
docker volume create whm_storage
docker volume create cpanel_storage
docker volume create admin_storage

# Inspect volume
docker volume inspect mysql_data

# List all volumes
docker volume ls

# Remove unused volumes
docker volume prune
```

### Backup Volumes

```bash
# Create backup script
nano /usr/local/bin/docker-backup.sh
```

```bash
#!/bin/bash
set -e

BACKUP_DIR="/backup/docker"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup MySQL
docker exec mysql sh -c 'exec mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD"' | gzip > "$BACKUP_DIR/mysql_$DATE.sql.gz"

# Backup volumes
for volume in mysql_data redis_data whm_storage cpanel_storage admin_storage; do
    docker run --rm \
        -v $volume:/data \
        -v $BACKUP_DIR:/backup \
        alpine tar -czf /backup/${volume}_$DATE.tar.gz -C /data .
done

# Cleanup old backups (keep last 7 days)
find "$BACKUP_DIR" -name "*.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
```

```bash
# Make executable
chmod +x /usr/local/bin/docker-backup.sh

# Add to crontab
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/docker-backup.sh") | crontab -
```

### Restore Volumes

```bash
# Restore MySQL
gunzip < /backup/docker/mysql_20231023.sql.gz | docker exec -i mysql mysql -uroot -p"$MYSQL_ROOT_PASSWORD"

# Restore volume
docker run --rm \
    -v mysql_data:/data \
    -v /backup/docker:/backup \
    alpine sh -c "cd /data && tar -xzf /backup/mysql_data_20231023.tar.gz"
```

## Environment Variables

### Laravel Environment Configuration

Each application needs its own `.env` file:

```bash
# whm/.env
APP_NAME="WHM Panel"
APP_ENV=production
APP_KEY=base64:your_generated_key
APP_DEBUG=false
APP_URL=https://whm.yourdomain.com

LOG_CHANNEL=stack
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=whm_panel
DB_USERNAME=whm_user
DB_PASSWORD=your_secure_password

BROADCAST_DRIVER=log
CACHE_DRIVER=redis
FILESYSTEM_DISK=local
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
SESSION_LIFETIME=120

REDIS_HOST=redis
REDIS_PASSWORD=your_redis_password
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS="noreply@yourdomain.com"
MAIL_FROM_NAME="${APP_NAME}"

SESSION_SECURE_COOKIE=true
SESSION_SAME_SITE=strict
```

## Building Custom Images

### Multi-stage Build for Production

```dockerfile
# Production optimized Dockerfile
FROM php:8.2-fpm-alpine AS base

RUN apk add --no-cache \
    bash \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    mysql-client \
    supervisor

RUN docker-php-ext-install \
    pdo_mysql \
    mysqli \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    xml \
    zip \
    opcache

RUN pecl install redis && docker-php-ext-enable redis

FROM base AS dependencies

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

FROM base AS production

WORKDIR /var/www/html
COPY --from=dependencies /app/vendor ./vendor
COPY . .
RUN composer dump-autoload --optimize --classmap-authoritative

RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 storage bootstrap/cache

COPY docker/php/php.ini /usr/local/etc/php/
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/

EXPOSE 9000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
```

### Building Images

```bash
# Build all images
docker compose build

# Build specific service
docker compose build whm

# Build with no cache
docker compose build --no-cache

# Build and tag custom image
docker build -t hosting-platform/whm:1.0.0 ./whm

# Push to registry
docker tag hosting-platform/whm:1.0.0 registry.yourdomain.com/whm:1.0.0
docker push registry.yourdomain.com/whm:1.0.0
```

## Orchestration

### Starting Services

```bash
# Start all services
docker compose up -d

# Start specific service
docker compose up -d whm

# View logs
docker compose logs -f

# View specific service logs
docker compose logs -f whm

# Check service status
docker compose ps

# Stop all services
docker compose stop

# Stop and remove containers
docker compose down

# Stop and remove containers with volumes
docker compose down -v
```

### Scaling Services

```bash
# Scale WHM service to 3 instances
docker compose up -d --scale whm=3

# Verify scaling
docker compose ps
```

### Health Checks

```bash
# Check container health
docker compose ps

# Inspect container health
docker inspect --format='{{json .State.Health}}' whm | jq

# View health check logs
docker inspect whm | jq '.[0].State.Health.Log'
```

## Security Best Practices

### 1. Use Secrets Management

```yaml
# docker-compose.yml with secrets
version: '3.8'

services:
  whm:
    secrets:
      - db_password
      - redis_password
    environment:
      - DB_PASSWORD_FILE=/run/secrets/db_password
      - REDIS_PASSWORD_FILE=/run/secrets/redis_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
  redis_password:
    file: ./secrets/redis_password.txt
```

### 2. Run as Non-root User

```dockerfile
# Create non-root user in Dockerfile
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

USER appuser
```

### 3. Security Scanning

```bash
# Scan images for vulnerabilities
docker scan hosting-platform/whm:latest

# Use Trivy for comprehensive scanning
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy image hosting-platform/whm:latest
```

### 4. Network Isolation

```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # No external access
```

### 5. Resource Limits

```yaml
services:
  whm:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

## Monitoring and Logging

### Container Monitoring with cAdvisor

```yaml
# Add to docker-compose.yml
services:
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    restart: unless-stopped
    ports:
      - "8081:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    networks:
      - frontend
```

### Centralized Logging with ELK Stack

```yaml
# Add Elasticsearch, Logstash, Kibana
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.10.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    networks:
      - backend

  logstash:
    image: docker.elastic.co/logstash/logstash:8.10.0
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline
    depends_on:
      - elasticsearch
    networks:
      - backend

  kibana:
    image: docker.elastic.co/kibana/kibana:8.10.0
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch
    networks:
      - frontend
      - backend
```

### Logging Configuration

```yaml
# Configure logging driver
services:
  whm:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
        labels: "service=whm"
```

## Troubleshooting

### Common Issues

#### 1. Container Won't Start

```bash
# Check container logs
docker compose logs whm

# Inspect container
docker inspect whm

# Check events
docker events --since 1h

# Start container in foreground
docker compose up whm
```

#### 2. Database Connection Issues

```bash
# Test MySQL connection
docker exec -it mysql mysql -uroot -p

# Check MySQL logs
docker compose logs mysql

# Verify network connectivity
docker exec whm ping mysql

# Check environment variables
docker exec whm env | grep DB_
```

#### 3. Permission Issues

```bash
# Fix storage permissions
docker exec whm chown -R www-data:www-data /var/www/html/storage
docker exec whm chmod -R 775 /var/www/html/storage

# Check file ownership
docker exec whm ls -la /var/www/html/storage
```

#### 4. Out of Memory

```bash
# Check container memory usage
docker stats

# Increase container memory limit
docker update --memory="4g" whm

# Or in docker-compose.yml
services:
  whm:
    mem_limit: 4g
```

#### 5. Network Issues

```bash
# List networks
docker network ls

# Inspect network
docker network inspect frontend

# Test connectivity between containers
docker exec whm ping redis
docker exec whm nc -zv mysql 3306
```

## Production Deployment

### Deployment Checklist

- [ ] All images built and tested
- [ ] Environment variables configured
- [ ] Secrets management configured
- [ ] SSL certificates obtained
- [ ] Database backups configured
- [ ] Monitoring configured
- [ ] Log aggregation setup
- [ ] Health checks implemented
- [ ] Resource limits set
- [ ] Security scanning completed

### Deployment Script

```bash
#!/bin/bash
set -e

echo "Starting deployment..."

# Pull latest changes
git pull origin main

# Build images
echo "Building images..."
docker compose build --no-cache

# Run database migrations
echo "Running migrations..."
docker compose run --rm whm php artisan migrate --force

# Start services
echo "Starting services..."
docker compose up -d

# Wait for services to be healthy
echo "Waiting for services..."
sleep 30

# Verify deployment
echo "Verifying deployment..."
docker compose ps

# Clear caches
echo "Clearing caches..."
docker exec whm php artisan cache:clear
docker exec whm php artisan config:cache
docker exec whm php artisan route:cache
docker exec whm php artisan view:cache

echo "Deployment complete!"
```

### Zero-downtime Deployment

```bash
# Using blue-green deployment
docker-compose -f docker-compose.blue.yml up -d
# Test blue environment
# Switch traffic to blue
# Take down green environment
docker-compose -f docker-compose.green.yml down
```

---

**Next Steps:**
- [Production Deployment Guide](production.md)
- [Scaling Guide](scaling.md)
- [Backup and Recovery Guide](backup.md)
