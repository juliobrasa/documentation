# Scaling Guide

Comprehensive guide for scaling the Hosting Management Platform to handle increased load and ensure high availability.

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Vertical Scaling](#vertical-scaling)
4. [Horizontal Scaling](#horizontal-scaling)
5. [Database Scaling](#database-scaling)
6. [Cache Scaling](#cache-scaling)
7. [Load Balancing](#load-balancing)
8. [Session Management](#session-management)
9. [File Storage Scaling](#file-storage-scaling)
10. [Queue Worker Scaling](#queue-worker-scaling)
11. [Auto-scaling Strategies](#auto-scaling-strategies)
12. [Performance Optimization](#performance-optimization)
13. [Monitoring and Metrics](#monitoring-and-metrics)
14. [Capacity Planning](#capacity-planning)
15. [Best Practices](#best-practices)
16. [Troubleshooting](#troubleshooting)

## Overview

Scaling is essential for maintaining application performance and reliability as user demand grows. This guide covers both vertical (scaling up) and horizontal (scaling out) strategies for the Hosting Management Platform.

### Scaling Architecture

```
                    ┌─────────────────┐
                    │   DNS / CDN     │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ Load Balancer   │
                    │   (HAProxy)     │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
   ┌────▼────┐         ┌────▼────┐         ┌────▼────┐
   │  Web 1  │         │  Web 2  │         │  Web 3  │
   │ Server  │         │ Server  │         │ Server  │
   └────┬────┘         └────┬────┘         └────┬────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
   ┌────▼────┐         ┌───▼────┐        ┌────▼─────┐
   │ Redis   │         │ MySQL  │        │  NFS/    │
   │ Cluster │         │ Cluster│        │  S3      │
   └─────────┘         └────────┘        └──────────┘
```

### When to Scale

#### Indicators You Need to Scale
- Response times consistently > 500ms
- CPU usage consistently > 70%
- Memory usage consistently > 80%
- Database connections near limit
- Queue backlog growing
- Error rates increasing
- User complaints about performance

## Prerequisites

### Infrastructure Requirements
- Load balancer capable of distributing traffic
- Shared storage solution (NFS, GlusterFS, or S3)
- Session storage (Redis cluster)
- Database replication capability
- Monitoring system in place
- Automated deployment pipeline

### Software Requirements
- HAProxy 2.4+ or Nginx Plus
- Redis 6.0+ with Sentinel or Cluster
- MySQL 8.0+ with replication
- Shared filesystem or S3-compatible storage
- Container orchestration (Docker Swarm or Kubernetes - optional)

### Planning Requirements
- Traffic patterns documented
- Peak load capacity requirements
- Budget constraints identified
- Disaster recovery plan
- Rollback procedures defined

## Vertical Scaling

Vertical scaling involves increasing the resources of existing servers.

### Step 1: Assess Current Resource Usage

```bash
# Check CPU usage
top
htop

# Check memory usage
free -h
vmstat 1 10

# Check disk I/O
iostat -x 1 10

# Check network usage
iftop
nethogs

# Overall system performance
sar -u 1 10     # CPU
sar -r 1 10     # Memory
sar -b 1 10     # I/O
```

### Step 2: Upgrade Server Resources

```bash
# Example: Upgrading a VPS (varies by provider)
# For DigitalOcean:
doctl compute droplet resize <droplet-id> --size s-4vcpu-8gb --wait

# For AWS EC2:
aws ec2 modify-instance-attribute --instance-id i-1234567890abcdef0 --instance-type "{\"Value\": \"m5.xlarge\"}"
aws ec2 stop-instances --instance-ids i-1234567890abcdef0
aws ec2 start-instances --instance-ids i-1234567890abcdef0
```

### Step 3: Optimize PHP Configuration

```bash
# Edit PHP configuration
sudo nano /etc/php.ini
```

```ini
# Increase limits for higher capacity server
memory_limit = 1024M
max_execution_time = 120
max_input_time = 120
upload_max_filesize = 128M
post_max_size = 128M

# OPcache optimization for more memory
opcache.memory_consumption = 512
opcache.interned_strings_buffer = 32
opcache.max_accelerated_files = 20000
```

### Step 4: Optimize PHP-FPM Pools

```bash
# Edit PHP-FPM pool configuration
sudo nano /etc/php-fpm.d/www.conf
```

```ini
# Dynamic process management
pm = dynamic
pm.max_children = 100          # Increase for more concurrent requests
pm.start_servers = 25
pm.min_spare_servers = 15
pm.max_spare_servers = 35
pm.max_requests = 1000
pm.process_idle_timeout = 10s
```

```bash
# Restart PHP-FPM
sudo systemctl restart php-fpm
```

### Step 5: Optimize Database Configuration

```bash
# Edit MySQL configuration
sudo nano /etc/my.cnf.d/server.cnf
```

```ini
[mysqld]
# Buffer pool size (70-80% of available RAM for dedicated DB server)
innodb_buffer_pool_size = 24G
innodb_buffer_pool_instances = 8

# Log files
innodb_log_file_size = 2G
innodb_log_buffer_size = 64M

# Connection pool
max_connections = 1000
thread_cache_size = 100

# Query cache
query_cache_type = 1
query_cache_size = 512M
query_cache_limit = 4M

# InnoDB optimization
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
innodb_io_capacity = 2000
innodb_io_capacity_max = 4000

# Table cache
table_open_cache = 4000
table_definition_cache = 2000
```

```bash
# Restart MySQL
sudo systemctl restart mariadb
```

### Vertical Scaling Limits

Vertical scaling has natural limits:
- Maximum hardware capacity
- Single point of failure
- Downtime required for upgrades
- Cost increases exponentially
- Limited by single server architecture

When vertical scaling is no longer sufficient, horizontal scaling becomes necessary.

## Horizontal Scaling

Horizontal scaling involves adding more servers to distribute the load.

### Step 1: Prepare Application for Horizontal Scaling

#### A. Stateless Application Design

Ensure your application is stateless:

```bash
# Check for local file storage usage
cd /var/www/production/whm
grep -r "Storage::disk('local')" app/

# Replace with cloud storage
# In .env
FILESYSTEM_DISK=s3

# In config/filesystems.php ensure S3 is configured
```

#### B. External Session Storage

Configure Redis for sessions:

```php
// config/session.php
return [
    'driver' => env('SESSION_DRIVER', 'redis'),
    'connection' => env('SESSION_CONNECTION', 'session'),

    // Ensure session lifetime is appropriate
    'lifetime' => 120,
    'expire_on_close' => false,
];
```

```bash
# .env configuration
SESSION_DRIVER=redis
SESSION_CONNECTION=session
REDIS_CLIENT=predis

# Configure session connection in config/database.php
```

```php
// config/database.php
'redis' => [
    'session' => [
        'url' => env('REDIS_URL'),
        'host' => env('REDIS_HOST', '127.0.0.1'),
        'password' => env('REDIS_PASSWORD', null),
        'port' => env('REDIS_PORT', '6379'),
        'database' => env('REDIS_SESSION_DB', '1'),
    ],
],
```

#### C. Shared File Storage

```bash
# Install NFS client
sudo yum install -y nfs-utils

# Mount shared storage
sudo mkdir -p /mnt/shared-storage
sudo mount -t nfs 10.0.1.100:/exports/shared /mnt/shared-storage

# Add to /etc/fstab for persistent mount
echo "10.0.1.100:/exports/shared /mnt/shared-storage nfs defaults 0 0" | sudo tee -a /etc/fstab

# Link application storage to shared storage
ln -s /mnt/shared-storage/whm /var/www/production/whm/storage/app/public
```

### Step 2: Setup Additional Web Servers

#### Clone Existing Server

```bash
# On new server, install dependencies
sudo yum update -y
sudo yum install -y httpd php php-fpm php-mysqlnd php-redis git

# Clone application
cd /var/www/production
sudo git clone git@github.com:juliobrasa/whm.git whm
cd whm

# Install dependencies
sudo -u apache composer install --no-dev --optimize-autoloader

# Copy .env from existing server
scp user@existing-server:/var/www/production/whm/.env .env

# Set permissions
sudo chown -R apache:apache /var/www/production/whm
sudo chmod -R 755 /var/www/production/whm
sudo chmod -R 775 storage bootstrap/cache

# Configure Apache (same as primary server)
sudo cp /path/to/apache-config.conf /etc/httpd/conf.d/whm.conf

# Start services
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl start php-fpm
sudo systemctl enable php-fpm
```

### Step 3: Configure Load Balancer

#### HAProxy Configuration

```bash
# Install HAProxy on load balancer server
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
    maxconn 10000

    # SSL/TLS configuration
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
    log global
    mode http
    option httplog
    option dontlognull
    option forwardfor
    option http-server-close
    timeout connect 10s
    timeout client 30s
    timeout server 30s
    timeout http-request 10s
    timeout http-keep-alive 2s
    timeout queue 30s
    timeout tunnel 3600s
    timeout client-fin 30s
    timeout server-fin 30s

    # Error files
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

# Frontend - HTTP
frontend http_front
    bind *:80
    mode http

    # Redirect HTTP to HTTPS
    redirect scheme https code 301 if !{ ssl_fc }

# Frontend - HTTPS
frontend https_front
    bind *:443 ssl crt /etc/haproxy/certs/ alpn h2,http/1.1
    mode http

    # Security headers
    http-response set-header Strict-Transport-Security "max-age=31536000; includeSubDomains"
    http-response set-header X-Frame-Options "SAMEORIGIN"
    http-response set-header X-Content-Type-Options "nosniff"
    http-response set-header X-XSS-Protection "1; mode=block"

    # ACLs for different applications
    acl whm_domain hdr(host) -i whm.yourdomain.com
    acl cpanel_domain hdr(host) -i cpanel.yourdomain.com
    acl admin_domain hdr(host) -i admin.yourdomain.com

    # Use backends based on domain
    use_backend whm_backend if whm_domain
    use_backend cpanel_backend if cpanel_domain
    use_backend admin_backend if admin_domain

    default_backend whm_backend

# Backend - WHM Panel
backend whm_backend
    mode http
    balance roundrobin
    option httpchk GET /health HTTP/1.1\r\nHost:\ whm.yourdomain.com
    http-check expect status 200

    # Cookie-based session persistence
    cookie SERVERID insert indirect nocache

    # Servers
    server web1 10.0.1.10:80 check cookie web1 maxconn 500
    server web2 10.0.1.11:80 check cookie web2 maxconn 500
    server web3 10.0.1.12:80 check cookie web3 maxconn 500 backup

# Backend - cPanel
backend cpanel_backend
    mode http
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200

    cookie SERVERID insert indirect nocache

    server web1 10.0.1.10:80 check cookie web1 maxconn 500
    server web2 10.0.1.11:80 check cookie web2 maxconn 500
    server web3 10.0.1.12:80 check cookie web3 maxconn 500 backup

# Backend - Admin Panel
backend admin_backend
    mode http
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200

    cookie SERVERID insert indirect nocache

    server web1 10.0.1.10:80 check cookie web1 maxconn 500
    server web2 10.0.1.11:80 check cookie web2 maxconn 500
    server web3 10.0.1.12:80 check cookie web3 maxconn 500 backup

# Statistics page
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats auth admin:YOUR_SECURE_PASSWORD
    stats admin if TRUE
```

```bash
# Enable and start HAProxy
sudo systemctl enable haproxy
sudo systemctl start haproxy

# Check status
sudo systemctl status haproxy

# Test configuration
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

#### Nginx Load Balancer Configuration

Alternatively, use Nginx as load balancer:

```nginx
# /etc/nginx/nginx.conf
upstream whm_servers {
    least_conn;  # or ip_hash for session persistence

    server 10.0.1.10:80 max_fails=3 fail_timeout=30s;
    server 10.0.1.11:80 max_fails=3 fail_timeout=30s;
    server 10.0.1.12:80 max_fails=3 fail_timeout=30s backup;

    keepalive 32;
}

upstream cpanel_servers {
    least_conn;

    server 10.0.1.10:80 max_fails=3 fail_timeout=30s;
    server 10.0.1.11:80 max_fails=3 fail_timeout=30s;
    server 10.0.1.12:80 max_fails=3 fail_timeout=30s backup;

    keepalive 32;
}

server {
    listen 80;
    server_name whm.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name whm.yourdomain.com;

    ssl_certificate /etc/ssl/certs/whm.yourdomain.com.crt;
    ssl_certificate_key /etc/ssl/private/whm.yourdomain.com.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://whm_servers;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Health check
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
        proxy_connect_timeout 5s;
    }

    location /health {
        access_log off;
        proxy_pass http://whm_servers/health;
    }
}
```

## Database Scaling

### Master-Slave Replication

#### Configure Master Server

```bash
# Edit MySQL configuration on master
sudo nano /etc/my.cnf.d/server.cnf
```

```ini
[mysqld]
server-id = 1
log_bin = /var/log/mariadb/mysql-bin.log
binlog_format = ROW
binlog_do_db = whm_panel
binlog_do_db = cpanel1db
binlog_do_db = admindb
max_binlog_size = 100M
expire_logs_days = 7
```

```bash
# Restart MySQL
sudo systemctl restart mariadb

# Create replication user
mysql -u root -p << 'EOF'
CREATE USER 'replicator'@'%' IDENTIFIED BY 'STRONG_PASSWORD';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';
FLUSH PRIVILEGES;
FLUSH TABLES WITH READ LOCK;
SHOW MASTER STATUS;
EOF
```

Note the File and Position from SHOW MASTER STATUS.

```bash
# Create backup for slave
mysqldump -u root -p --all-databases --master-data=2 > /backup/master_backup.sql

# Unlock tables
mysql -u root -p -e "UNLOCK TABLES;"
```

#### Configure Slave Server

```bash
# Copy backup to slave server
scp /backup/master_backup.sql slave-server:/tmp/

# On slave server, edit configuration
sudo nano /etc/my.cnf.d/server.cnf
```

```ini
[mysqld]
server-id = 2
relay_log = /var/log/mariadb/relay-bin
log_bin = /var/log/mariadb/mysql-bin.log
binlog_format = ROW
read_only = 1
```

```bash
# Restart MySQL
sudo systemctl restart mariadb

# Import backup
mysql -u root -p < /tmp/master_backup.sql

# Configure replication
mysql -u root -p << 'EOF'
CHANGE MASTER TO
    MASTER_HOST='10.0.1.100',
    MASTER_USER='replicator',
    MASTER_PASSWORD='STRONG_PASSWORD',
    MASTER_LOG_FILE='mysql-bin.000001',
    MASTER_LOG_POS=12345;

START SLAVE;
SHOW SLAVE STATUS\G
EOF
```

#### Application Configuration for Read/Write Splitting

```php
// config/database.php
'mysql' => [
    'write' => [
        'host' => env('DB_WRITE_HOST', '10.0.1.100'),
    ],
    'read' => [
        [
            'host' => env('DB_READ_HOST_1', '10.0.1.101'),
        ],
        [
            'host' => env('DB_READ_HOST_2', '10.0.1.102'),
        ],
    ],
    'sticky' => true,
    'driver' => 'mysql',
    'database' => env('DB_DATABASE', 'whm_panel'),
    'username' => env('DB_USERNAME', 'whm_user'),
    'password' => env('DB_PASSWORD', ''),
    'charset' => 'utf8mb4',
    'collation' => 'utf8mb4_unicode_ci',
    'prefix' => '',
    'strict' => true,
    'engine' => null,
],
```

### Database Connection Pooling

Use ProxySQL for connection pooling:

```bash
# Install ProxySQL
cat <<EOF | sudo tee /etc/yum.repos.d/proxysql.repo
[proxysql_repo]
name= ProxySQL YUM repository
baseurl=https://repo.proxysql.com/ProxySQL/proxysql-2.4.x/centos/8
gpgcheck=1
gpgkey=https://repo.proxysql.com/ProxySQL/proxysql-2.4.x/repo_pub_key
EOF

sudo yum install -y proxysql

# Configure ProxySQL
sudo systemctl start proxysql
sudo systemctl enable proxysql

# Connect to ProxySQL admin
mysql -u admin -padmin -h 127.0.0.1 -P6032
```

```sql
-- Add backend servers
INSERT INTO mysql_servers(hostgroup_id, hostname, port) VALUES (1, '10.0.1.100', 3306);
INSERT INTO mysql_servers(hostgroup_id, hostname, port) VALUES (2, '10.0.1.101', 3306);
INSERT INTO mysql_servers(hostgroup_id, hostname, port) VALUES (2, '10.0.1.102', 3306);

-- Add users
INSERT INTO mysql_users(username, password, default_hostgroup) VALUES ('whm_user', 'password', 1);

-- Configure routing rules
INSERT INTO mysql_query_rules(active, match_pattern, destination_hostgroup, apply) VALUES (1, '^SELECT.*FOR UPDATE', 1, 1);
INSERT INTO mysql_query_rules(active, match_pattern, destination_hostgroup, apply) VALUES (1, '^SELECT', 2, 1);

-- Load configuration
LOAD MYSQL SERVERS TO RUNTIME;
LOAD MYSQL USERS TO RUNTIME;
LOAD MYSQL QUERY RULES TO RUNTIME;

-- Save configuration
SAVE MYSQL SERVERS TO DISK;
SAVE MYSQL USERS TO DISK;
SAVE MYSQL QUERY RULES TO DISK;
```

Update application to use ProxySQL:

```bash
# .env
DB_HOST=127.0.0.1
DB_PORT=6033
```

## Cache Scaling

### Redis Cluster Configuration

#### Setup Redis Cluster

```bash
# Install Redis on multiple nodes (at least 6 nodes: 3 masters, 3 slaves)
sudo yum install -y redis

# On each node, edit configuration
sudo nano /etc/redis.conf
```

```
# Basic configuration
bind 0.0.0.0
protected-mode yes
port 7000
requirepass YOUR_REDIS_PASSWORD
masterauth YOUR_REDIS_PASSWORD

# Cluster configuration
cluster-enabled yes
cluster-config-file nodes-7000.conf
cluster-node-timeout 5000
cluster-require-full-coverage no

# Persistence
appendonly yes
appendfilename "appendonly.aof"

# Memory
maxmemory 2gb
maxmemory-policy allkeys-lru
```

```bash
# Start Redis on all nodes
sudo systemctl start redis
sudo systemctl enable redis

# Create cluster
redis-cli --cluster create \
    10.0.1.201:7000 10.0.1.202:7000 10.0.1.203:7000 \
    10.0.1.204:7000 10.0.1.205:7000 10.0.1.206:7000 \
    --cluster-replicas 1 \
    -a YOUR_REDIS_PASSWORD
```

#### Application Configuration

```php
// config/database.php
'redis' => [
    'client' => env('REDIS_CLIENT', 'phpredis'),
    'options' => [
        'cluster' => env('REDIS_CLUSTER', 'redis'),
        'prefix' => env('REDIS_PREFIX', Str::slug(env('APP_NAME', 'laravel'), '_').'_database_'),
    ],
    'clusters' => [
        'default' => [
            [
                'host' => env('REDIS_HOST', '10.0.1.201'),
                'password' => env('REDIS_PASSWORD', null),
                'port' => env('REDIS_PORT', '7000'),
                'database' => 0,
            ],
            [
                'host' => '10.0.1.202',
                'password' => env('REDIS_PASSWORD', null),
                'port' => 7000,
                'database' => 0,
            ],
            [
                'host' => '10.0.1.203',
                'password' => env('REDIS_PASSWORD', null),
                'port' => 7000,
                'database' => 0,
            ],
        ],
    ],
],
```

### Redis Sentinel (High Availability)

For smaller deployments, use Redis Sentinel:

```bash
# sentinel.conf
port 26379
sentinel monitor mymaster 10.0.1.201 6379 2
sentinel auth-pass mymaster YOUR_REDIS_PASSWORD
sentinel down-after-milliseconds mymaster 5000
sentinel parallel-syncs mymaster 1
sentinel failover-timeout mymaster 10000
```

## Load Balancing

### DNS-based Load Balancing

```bash
# Configure multiple A records for round-robin DNS
whm.yourdomain.com.  300  IN  A  10.0.1.10
whm.yourdomain.com.  300  IN  A  10.0.1.11
whm.yourdomain.com.  300  IN  A  10.0.1.12
```

Limitations:
- No health checks
- No control over distribution
- DNS caching issues

### Application-level Load Balancing

Use GeoDNS for geographic distribution:

```yaml
# Example with Route53
Type: A
Routing Policy: Geolocation
Geolocation: North America
Value: 10.0.1.10

Type: A
Routing Policy: Geolocation
Geolocation: Europe
Value: 10.0.2.10
```

## Session Management

### Redis-based Sessions

Already configured in horizontal scaling section.

### Database-based Sessions (Alternative)

```bash
# Create sessions table
php artisan session:table
php artisan migrate
```

```bash
# .env
SESSION_DRIVER=database
SESSION_CONNECTION=mysql
```

## File Storage Scaling

### S3-Compatible Storage

```bash
# Install AWS SDK
composer require league/flysystem-aws-s3-v3 "^3.0"
```

```php
// config/filesystems.php
'disks' => [
    's3' => [
        'driver' => 's3',
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION'),
        'bucket' => env('AWS_BUCKET'),
        'url' => env('AWS_URL'),
        'endpoint' => env('AWS_ENDPOINT'),
        'use_path_style_endpoint' => env('AWS_USE_PATH_STYLE_ENDPOINT', false),
    ],
],
```

```bash
# .env
FILESYSTEM_DISK=s3
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=your-bucket
```

### NFS Storage

Already configured in horizontal scaling section.

### GlusterFS (Distributed Filesystem)

```bash
# Install GlusterFS on storage nodes
sudo yum install -y centos-release-gluster
sudo yum install -y glusterfs-server

# Start GlusterFS
sudo systemctl start glusterd
sudo systemctl enable glusterd

# On first node, create cluster
sudo gluster peer probe gluster-node-2
sudo gluster peer probe gluster-node-3

# Create volume
sudo gluster volume create gv0 replica 3 \
    gluster-node-1:/data/glusterfs/gv0 \
    gluster-node-2:/data/glusterfs/gv0 \
    gluster-node-3:/data/glusterfs/gv0 \
    force

# Start volume
sudo gluster volume start gv0

# On web servers, install client and mount
sudo yum install -y glusterfs-client
sudo mkdir -p /mnt/glusterfs
sudo mount -t glusterfs gluster-node-1:/gv0 /mnt/glusterfs
```

## Queue Worker Scaling

### Multiple Worker Processes

```bash
# Create systemd service for multiple workers
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
ExecStart=/usr/bin/php /var/www/production/whm/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600 --queue=high,default,low

[Install]
WantedBy=multi-user.target
```

```bash
# Start multiple workers
for i in {1..10}; do
    sudo systemctl enable laravel-queue@$i
    sudo systemctl start laravel-queue@$i
done
```

### Horizon for Queue Management

```bash
# Install Horizon
cd /var/www/production/whm
composer require laravel/horizon

# Publish configuration
php artisan horizon:install

# Configure in config/horizon.php
```

```php
// config/horizon.php
'environments' => [
    'production' => [
        'supervisor-1' => [
            'connection' => 'redis',
            'queue' => ['high', 'default'],
            'balance' => 'auto',
            'maxProcesses' => 10,
            'maxTime' => 0,
            'maxJobs' => 0,
            'memory' => 512,
            'tries' => 3,
            'timeout' => 300,
        ],
        'supervisor-2' => [
            'connection' => 'redis',
            'queue' => ['low'],
            'balance' => 'auto',
            'maxProcesses' => 5,
            'maxTime' => 0,
            'maxJobs' => 0,
            'memory' => 512,
            'tries' => 2,
            'timeout' => 600,
        ],
    ],
],
```

```bash
# Create Horizon service
sudo nano /etc/systemd/system/horizon.service
```

```ini
[Unit]
Description=Laravel Horizon
After=network.target redis.service

[Service]
Type=simple
User=apache
Group=apache
Restart=always
RestartSec=3
ExecStart=/usr/bin/php /var/www/production/whm/artisan horizon
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

```bash
# Start Horizon
sudo systemctl enable horizon
sudo systemctl start horizon
```

## Auto-scaling Strategies

### AWS Auto Scaling

#### Launch Template

```bash
# Create launch template with AWS CLI
aws ec2 create-launch-template \
    --launch-template-name whm-web-template \
    --launch-template-data '{
        "ImageId": "ami-0abcdef1234567890",
        "InstanceType": "t3.medium",
        "SecurityGroupIds": ["sg-0123456789abcdef0"],
        "UserData": "IyEvYmluL2Jhc2gK..."
    }'
```

#### Auto Scaling Group

```bash
# Create auto scaling group
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name whm-web-asg \
    --launch-template LaunchTemplateName=whm-web-template \
    --min-size 2 \
    --max-size 10 \
    --desired-capacity 3 \
    --target-group-arns arn:aws:elasticloadbalancing:... \
    --health-check-type ELB \
    --health-check-grace-period 300
```

#### Scaling Policies

```bash
# Scale up policy
aws autoscaling put-scaling-policy \
    --auto-scaling-group-name whm-web-asg \
    --policy-name scale-up \
    --scaling-adjustment 2 \
    --adjustment-type ChangeInCapacity \
    --cooldown 300

# CloudWatch alarm to trigger scale up
aws cloudwatch put-metric-alarm \
    --alarm-name high-cpu \
    --alarm-description "Scale up when CPU > 70%" \
    --metric-name CPUUtilization \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --threshold 70 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions arn:aws:autoscaling:...
```

### Kubernetes Auto-scaling

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whm-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: whm
  template:
    metadata:
      labels:
        app: whm
    spec:
      containers:
      - name: whm
        image: hosting-platform/whm:latest
        resources:
          requests:
            cpu: "500m"
            memory: "1Gi"
          limits:
            cpu: "1000m"
            memory: "2Gi"
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: whm-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: whm-deployment
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

## Performance Optimization

### Caching Strategies

```php
// Use Laravel caching effectively
// Cache database queries
$users = Cache::remember('users.all', 3600, function () {
    return User::all();
});

// Cache views
return view('dashboard')->cache(3600);

// Cache routes (already in production deployment)
php artisan route:cache

// Cache configuration
php artisan config:cache
```

### Database Query Optimization

```php
// Use eager loading to prevent N+1 queries
$users = User::with(['posts', 'comments'])->get();

// Use chunk for large datasets
User::chunk(1000, function ($users) {
    foreach ($users as $user) {
        // Process user
    }
});

// Add database indexes
Schema::table('users', function (Blueprint $table) {
    $table->index('email');
    $table->index(['last_name', 'first_name']);
});
```

### CDN Integration

```bash
# Configure CDN in .env
ASSET_URL=https://cdn.yourdomain.com
```

```php
// Use asset() helper for CDN URLs
<link rel="stylesheet" href="{{ asset('css/app.css') }}">
<script src="{{ asset('js/app.js') }}"></script>
```

## Monitoring and Metrics

### Application Performance Monitoring

```bash
# Install New Relic PHP agent
curl -L https://download.newrelic.com/php_agent/release/newrelic-php5-10.10.0.3-linux.tar.gz | tar -C /tmp -zx
cd /tmp/newrelic-php5-*
sudo ./newrelic-install install
sudo systemctl restart php-fpm
```

### Custom Metrics

```php
// Monitor queue size
Schedule::call(function () {
    $queueSize = Redis::llen('queues:default');
    Log::info('Queue size', ['size' => $queueSize]);

    // Alert if queue is growing
    if ($queueSize > 10000) {
        // Send alert
    }
})->everyFiveMinutes();
```

### Prometheus Metrics

```bash
# Install Prometheus PHP client
composer require promphp/prometheus_client_php

# Create metrics endpoint
Route::get('/metrics', function () {
    $registry = app(\Prometheus\CollectorRegistry::class);

    // Register metrics
    $counter = $registry->getOrRegisterCounter('app', 'requests_total', 'Total requests');
    $counter->inc();

    $gauge = $registry->getOrRegisterGauge('app', 'queue_size', 'Queue size');
    $gauge->set(Redis::llen('queues:default'));

    return response(
        (new \Prometheus\RenderTextFormat())->render($registry->getMetricFamilySamples())
    )->header('Content-Type', \Prometheus\RenderTextFormat::MIME_TYPE);
});
```

## Capacity Planning

### Calculate Required Capacity

```bash
# Benchmark single server capacity
ab -n 10000 -c 100 https://whm.yourdomain.com/

# Calculate required servers
# If single server handles 1000 req/s
# And you expect 5000 req/s peak
# You need: 5000 / 1000 = 5 servers
# Add 50% buffer: 5 * 1.5 = 7-8 servers
```

### Load Testing

```bash
# Install k6
sudo yum install -y https://github.com/grafana/k6/releases/download/v0.45.0/k6-0.45.0-amd64.rpm

# Create load test script
cat > loadtest.js << 'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
    stages: [
        { duration: '2m', target: 100 },  // Ramp up
        { duration: '5m', target: 100 },  // Stay at 100 users
        { duration: '2m', target: 200 },  // Spike to 200 users
        { duration: '5m', target: 200 },  // Stay at 200 users
        { duration: '2m', target: 0 },    // Ramp down
    ],
};

export default function () {
    const res = http.get('https://whm.yourdomain.com');
    check(res, {
        'status is 200': (r) => r.status === 200,
        'response time < 500ms': (r) => r.timings.duration < 500,
    });
    sleep(1);
}
EOF

# Run load test
k6 run loadtest.js
```

## Best Practices

### 1. Gradual Scaling

Scale gradually to identify bottlenecks:
- Add one server at a time
- Monitor metrics after each addition
- Identify and resolve bottlenecks before continuing

### 2. Implement Circuit Breakers

```php
use Illuminate\Support\Facades\Cache;

function callExternalAPI() {
    $failures = Cache::get('api_failures', 0);

    // Circuit open (too many failures)
    if ($failures >= 5) {
        $lastFailure = Cache::get('last_api_failure');
        if (now()->diffInMinutes($lastFailure) < 5) {
            throw new \Exception('Circuit breaker open');
        }
        // Reset after 5 minutes
        Cache::forget('api_failures');
    }

    try {
        // Make API call
        $response = Http::timeout(5)->get('https://api.example.com');
        Cache::forget('api_failures');
        return $response;
    } catch (\Exception $e) {
        Cache::increment('api_failures');
        Cache::put('last_api_failure', now());
        throw $e;
    }
}
```

### 3. Implement Rate Limiting

```php
// In routes
Route::middleware('throttle:60,1')->group(function () {
    Route::get('/api/users', [UserController::class, 'index']);
});

// Custom rate limiting
use Illuminate\Cache\RateLimiter;

app(RateLimiter::class)->for('api', function (Request $request) {
    return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
});
```

### 4. Health Checks

```php
// routes/web.php
Route::get('/health', function () {
    $checks = [
        'database' => checkDatabase(),
        'redis' => checkRedis(),
        'disk' => checkDiskSpace(),
        'queue' => checkQueue(),
    ];

    $healthy = !in_array(false, $checks, true);

    return response()->json([
        'status' => $healthy ? 'healthy' : 'unhealthy',
        'checks' => $checks,
        'timestamp' => now(),
    ], $healthy ? 200 : 503);
});

function checkDatabase() {
    try {
        DB::connection()->getPdo();
        return true;
    } catch (\Exception $e) {
        return false;
    }
}

function checkRedis() {
    try {
        Redis::ping();
        return true;
    } catch (\Exception $e) {
        return false;
    }
}

function checkDiskSpace() {
    $free = disk_free_space('/');
    $total = disk_total_space('/');
    return ($free / $total) > 0.1; // 10% free
}

function checkQueue() {
    $size = Redis::llen('queues:default');
    return $size < 10000; // Less than 10k queued jobs
}
```

## Troubleshooting

### Common Scaling Issues

#### 1. Session Loss After Load Balancer

**Problem**: Users logged out randomly
**Cause**: Session stored locally, not shared

**Solution**: Use Redis sessions (configured in horizontal scaling section)

#### 2. File Upload Issues

**Problem**: Uploads work on some requests, fail on others
**Cause**: Files stored locally, not on shared storage

**Solution**: Use S3 or NFS for file storage

#### 3. Cache Inconsistency

**Problem**: Stale data on some servers
**Cause**: Local file cache

**Solution**: Use Redis for caching

```bash
# .env
CACHE_DRIVER=redis
```

#### 4. Database Connection Limit

**Problem**: "Too many connections" error
**Cause**: Each web server opening too many connections

**Solution**: Use connection pooling with ProxySQL (configured earlier)

#### 5. Uneven Load Distribution

**Problem**: Some servers overloaded while others idle
**Cause**: Poor load balancing algorithm

**Solution**: Switch to least connections algorithm

```
# HAProxy
balance leastconn
```

---

**Next Steps:**
- [Production Deployment Guide](production.md)
- [Docker Deployment Guide](docker.md)
- [Backup and Recovery Guide](backup.md)
