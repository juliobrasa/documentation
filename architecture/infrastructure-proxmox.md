# Proxmox Infrastructure Documentation

## Overview

The hosting platform runs on a Proxmox VE hypervisor with multiple virtual machines, each dedicated to specific applications. This architecture provides isolation, scalability, and easy management.

## Proxmox Host

### Hypervisor Details
- **Platform**: Proxmox VE 8.x
- **Network**: Bridge to private 10.0.0.x subnet
- **Storage**: Local + Network storage
- **Backup**: Integrated VM snapshots + XNetBackup CDP

## Virtual Machines

### Network Layout

```
Internet
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│                   Proxmox VE Host                        │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │           vmbr0 (Bridge to 10.0.0.x)            │    │
│  └───────────────────────┬─────────────────────────┘    │
│                          │                               │
│    ┌─────────┬───────────┼───────────┬─────────┐        │
│    │         │           │           │         │        │
│    ▼         ▼           ▼           ▼         ▼        │
│ ┌─────┐  ┌─────┐     ┌─────┐    ┌─────┐   ┌─────┐      │
│ │.100 │  │.101 │     │.102 │    │.103 │   │.104 │      │
│ └─────┘  └─────┘     └─────┘    └─────┘   └─────┘      │
│                                                          │
│    ┌─────────┬───────────┬───────────┐                  │
│    │         │           │           │                  │
│    ▼         ▼           ▼           ▼                  │
│ ┌─────┐  ┌─────┐     ┌─────┐    ┌─────┐                │
│ │.105 │  │.106 │     │.107 │    │.108 │                │
│ └─────┘  └─────┘     └─────┘    └─────┘                │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### VM Inventory

| VMID | Name | IP | vCPU | RAM | Disk | Purpose |
|------|------|-----|------|-----|------|---------|
| 100 | cuentas | 10.0.0.100 | 2 | 2GB | 20GB | Cuentas Kavia App |
| 101 | gestionpiso | 10.0.0.101 | 2 | 2GB | 20GB | Alquiler App |
| 102 | devostelio | 10.0.0.102 | 2 | 2GB | 20GB | Dev Environment |
| 103 | admin | 10.0.0.103 | 4 | 4GB | 40GB | SOLTIA Admin + Docker |
| 104 | ips | 10.0.0.104 | 2 | 2GB | 20GB | IPS App |
| 105 | kavia | 10.0.0.105 | 2 | 2GB | 20GB | Kavia App |
| 106 | ansible | 10.0.0.106 | 2 | 2GB | 20GB | Ansible Automation |
| 107 | manageremail | 10.0.0.107 | 2 | 2GB | 20GB | Email Management |
| 108 | whm | 10.0.0.108 | 2 | 2GB | 20GB | WHM Panel |

## Standard VM Configuration

### Base Operating System
- **Distribution**: Debian 13 (Trixie)
- **Kernel**: Latest stable
- **Updates**: Automatic security updates enabled

### Software Stack

```bash
# Standard packages on each VM
nginx                    # Web server
php8.4-fpm              # PHP FastCGI Process Manager
php8.4-cli              # PHP CLI
php8.4-common           # PHP common files
php8.4-mysql            # MySQL/MariaDB driver
php8.4-xml              # XML support
php8.4-mbstring         # Multibyte string support
php8.4-curl             # cURL support
php8.4-zip              # ZIP support
php8.4-gd               # Graphics support
php8.4-bcmath           # BCMath support
php8.4-intl             # Internationalization
mariadb-server-11.8     # Database server
composer                # PHP dependency manager
git                     # Version control
supervisor              # Process manager
```

### Directory Structure

```
/var/www/
└── [app_name]/
    ├── app/
    ├── bootstrap/
    ├── config/
    ├── database/
    ├── public/
    ├── resources/
    ├── routes/
    ├── storage/
    ├── tests/
    ├── vendor/
    ├── .env
    ├── artisan
    └── composer.json
```

## VM Detailed Configuration

### cuentas (10.0.0.100)

**Purpose**: Account management for Kavia Hotels

```yaml
hostname: cuentas-kaviahoteles
application: /var/www/cuentas
domain: cuentas.kaviahoteles.com
database: cuentasdb
php_memory: 256M
nginx_workers: 2
```

**Nginx Config**:
```nginx
server {
    listen 80;
    server_name cuentas.kaviahoteles.com;
    root /var/www/cuentas/public;

    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

### gestionpiso (10.0.0.101)

**Purpose**: Property rental management system

```yaml
hostname: clientes-gestiondepiso
application: /var/www/alquiler
domain: clientes.gestiondepiso.com
database: alquilerdb
php_memory: 256M
nginx_workers: 2
```

### devostelio (10.0.0.102)

**Purpose**: Development and staging environment

```yaml
hostname: dev-ostelio
application: /var/www/dev
domain: dev.ostelio.com
database: devdb
php_memory: 512M
nginx_workers: 2
xdebug: enabled
```

### admin (10.0.0.103)

**Purpose**: Central administration with SOLTIA AI system

```yaml
hostname: admin-soporteclientes
application: /var/www/admin
domain: admin.soporteclientes.net
database: admindb
php_memory: 512M
nginx_workers: 4
docker: enabled
```

**Docker Services**:
```yaml
version: '3.8'
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  elasticsearch:
    image: elasticsearch:8.11.0
    ports:
      - "9200:9200"
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    volumes:
      - es_data:/usr/share/elasticsearch/data

  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
    volumes:
      - qdrant_data:/qdrant/storage

  postgresql:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=rag_db
      - POSTGRES_USER=rag_user
      - POSTGRES_PASSWORD=${PG_PASSWORD}
    volumes:
      - pg_data:/var/lib/postgresql/data

volumes:
  redis_data:
  es_data:
  qdrant_data:
  pg_data:
```

### ips (10.0.0.104)

**Purpose**: IPS management application

```yaml
hostname: ips-soporteclientes
application: /var/www/ips
domain: ips.soporteclientes.net
database: ipsdb
php_memory: 256M
nginx_workers: 2
```

### kavia (10.0.0.105)

**Purpose**: Kavia platform application

```yaml
hostname: kavia-ostelio
application: /var/www/kavia
domain: kavia.ostelio.com
database: kaviadb
php_memory: 256M
nginx_workers: 2
```

### ansible (10.0.0.106)

**Purpose**: Ansible automation controller

```yaml
hostname: ansible-controller
software:
  - ansible
  - ansible-lint
  - python3
  - sshpass
inventory: /etc/ansible/hosts
playbooks: /opt/ansible/playbooks
```

### manageremail (10.0.0.107)

**Purpose**: Email management and routing

```yaml
hostname: email-manager
software:
  - postfix
  - dovecot
  - roundcube
```

### whm (10.0.0.108)

**Purpose**: WHM panel for hosting management

```yaml
hostname: whm-panel
application: /var/www/whm
domain: whm.soporteclientes.net
```

## Network Configuration

### IP Addressing
- **Network**: 10.0.0.0/24
- **Gateway**: 10.0.0.1
- **DNS**: 10.0.0.1 (Proxmox), 8.8.8.8, 1.1.1.1

### Firewall Rules

Each VM has basic iptables rules:

```bash
# Allow SSH
-A INPUT -p tcp --dport 22 -j ACCEPT

# Allow HTTP/HTTPS
-A INPUT -p tcp --dport 80 -j ACCEPT
-A INPUT -p tcp --dport 443 -j ACCEPT

# Allow established connections
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Drop all other incoming
-A INPUT -j DROP
```

### Inter-VM Communication

VMs can communicate freely on the 10.0.0.x network:

```
admin (10.0.0.103) <---> All VMs (database sync, API calls)
ansible (10.0.0.106) ---> All VMs (SSH for automation)
```

## Storage Configuration

### VM Disks
- **Format**: qcow2
- **Location**: /var/lib/vz/images/
- **Snapshots**: Enabled

### Backup Storage
- **Local backups**: /var/lib/vz/dump/
- **Remote backups**: Via XNetBackup CDP
- **Retention**: 7 daily, 4 weekly, 12 monthly

## Monitoring

### Proxmox Metrics
- CPU usage per VM
- Memory usage per VM
- Disk I/O
- Network I/O

### VM Health Checks

```bash
# Health check script (runs every 5 minutes)
#!/bin/bash
for vm in cuentas gestionpiso devostelio admin ips kavia; do
    curl -s http://10.0.0.$((100 + i))/health || alert "$vm is down"
done
```

## Backup & Recovery

### Proxmox Backups
```bash
# Full VM backup (weekly)
vzdump $VMID --storage backup --mode snapshot --compress zstd

# Incremental (daily)
vzdump $VMID --storage backup --mode snapshot --compress zstd --incremental
```

### Application Backups
- Database dumps: Daily at 2:00 AM
- File backups: Incremental, every 6 hours
- Log rotation: Weekly

### Recovery Procedures

1. **VM Failure**:
   ```bash
   # Restore from backup
   qmrestore /var/lib/vz/dump/vzdump-qemu-$VMID-*.zst $VMID
   ```

2. **Application Failure**:
   ```bash
   # Restore application files
   cd /var/www/app
   git checkout HEAD~1
   php artisan migrate:rollback
   ```

3. **Database Failure**:
   ```bash
   # Restore database
   mysql -u root -p database < /backup/database_YYYYMMDD.sql
   ```

## Maintenance

### Regular Tasks

| Task | Frequency | VM |
|------|-----------|-----|
| Security updates | Weekly | All |
| Log rotation | Weekly | All |
| Database optimization | Monthly | All |
| Full backups | Weekly | All |
| SSL renewal | Auto (Let's Encrypt) | All |

### Update Procedure

```bash
# On each VM
apt update && apt upgrade -y

# Restart services
systemctl restart nginx php8.4-fpm

# Clear Laravel cache
cd /var/www/app
php artisan cache:clear
php artisan config:clear
```

## Scaling

### Horizontal Scaling
- Clone VMs for load balancing
- Add new VMs to the cluster
- Configure load balancer (HAProxy/Nginx)

### Vertical Scaling
- Increase vCPU allocation
- Increase RAM allocation
- Expand disk space (online resize)

```bash
# Resize disk
qm resize $VMID virtio0 +10G

# Inside VM
growpart /dev/vda 1
resize2fs /dev/vda1
```

## Troubleshooting

### Common Issues

1. **VM Won't Start**
   - Check Proxmox resources
   - Verify disk space
   - Check VM logs: `journalctl -u qemu-guest-agent`

2. **Network Issues**
   - Verify bridge configuration
   - Check IP assignment
   - Test connectivity: `ping 10.0.0.1`

3. **Application Errors**
   - Check Laravel logs: `tail -f /var/www/app/storage/logs/laravel.log`
   - Check Nginx logs: `tail -f /var/log/nginx/error.log`
   - Check PHP-FPM: `journalctl -u php8.4-fpm`

### Useful Commands

```bash
# VM status
qm status $VMID

# VM console
qm terminal $VMID

# List all VMs
qm list

# Start/Stop VM
qm start $VMID
qm stop $VMID

# Live migration
qm migrate $VMID target-host --online
```
