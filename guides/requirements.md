# System Requirements

Complete system requirements for the Hosting Management Platform.

## Overview

This document outlines all hardware, software, and network requirements for deploying the Hosting Management Platform on the Proxmox virtualization infrastructure.

## Infrastructure Requirements

### Proxmox Host (Hypervisor)

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 4 cores @ 2.5 GHz | 8+ cores @ 3.0 GHz |
| RAM | 16 GB | 32+ GB |
| Storage | 200 GB SSD | 500+ GB NVMe |
| Network | 1 Gbps | 10 Gbps |
| OS | Proxmox VE 7.x | Proxmox VE 8.x |

### Standard Virtual Machine (per application)

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| vCPU | 1 core | 2 cores |
| RAM | 1 GB | 2 GB |
| Disk | 10 GB | 20 GB |
| Network | virtio | virtio |

### Admin VM (SOLTIA + Docker Stack)

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| vCPU | 2 cores | 4 cores |
| RAM | 4 GB | 8 GB |
| Disk | 40 GB | 80 GB |
| Network | virtio | virtio |

## Software Requirements

### Operating System

| OS | Version | Status |
|----|---------|--------|
| **Debian** | **13 (Trixie)** | **Primary - Production** |
| Debian | 12 (Bookworm) | Supported |
| Ubuntu | 24.04 LTS | Supported |
| AlmaLinux | 8.x / 9.x | Supported (external servers) |
| CloudLinux | 8.x | Supported (cPanel servers) |

**Note:** CentOS is deprecated. AlmaLinux or Rocky Linux are recommended for RHEL compatibility.

### Web Server

| Software | Version | Status | Notes |
|----------|---------|--------|-------|
| **Nginx** | **1.27+** | **Primary** | Production VMs |
| OpenLiteSpeed | 1.7+ | Supported | cpanel1 server |
| Apache | 2.4+ | Legacy | Older installations |

### PHP

| Version | Status | Notes |
|---------|--------|-------|
| **PHP 8.4** | **Primary** | Current production |
| PHP 8.3 | Supported | Fallback option |
| PHP 8.2 | Supported | Minimum required |
| PHP 8.1 | Deprecated | Not recommended |
| PHP 8.0 | Deprecated | End of life |

#### Required PHP Extensions

```bash
# Core extensions (all VMs)
php8.4-fpm          # FastCGI Process Manager
php8.4-cli          # Command Line Interface
php8.4-common       # Common files
php8.4-mysql        # MySQL/MariaDB driver
php8.4-xml          # XML support
php8.4-dom          # DOM support
php8.4-mbstring     # Multibyte strings
php8.4-curl         # cURL library
php8.4-zip          # ZIP archives
php8.4-gd           # Graphics
php8.4-bcmath       # Arbitrary precision
php8.4-intl         # Internationalization
php8.4-soap         # SOAP support
php8.4-opcache      # Opcode cache

# Additional for admin VM
php8.4-redis        # Redis driver
php8.4-pgsql        # PostgreSQL driver (RAG system)
```

#### PHP Configuration

```ini
; /etc/php/8.4/fpm/php.ini
memory_limit = 256M
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 300
max_input_time = 300
date.timezone = UTC
opcache.enable = 1
opcache.memory_consumption = 128
```

### Database

| Software | Version | Status |
|----------|---------|--------|
| **MariaDB** | **11.8.x** | **Primary** |
| MariaDB | 10.11.x | Supported |
| MySQL | 8.0+ | Supported |
| PostgreSQL | 16.x | RAG system only (admin VM) |

#### MariaDB Configuration

```ini
; /etc/mysql/mariadb.conf.d/50-server.cnf
[mysqld]
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
max_connections = 200
query_cache_size = 64M
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
```

### Additional Software

| Service | Version | Purpose | Required |
|---------|---------|---------|----------|
| **Composer** | 2.7+ | PHP dependencies | Yes |
| **Git** | 2.x | Version control | Yes |
| **Supervisor** | 4.x | Process manager | Yes |
| Node.js | 20 LTS | Build tools | Optional |
| Redis | 7.x | Cache, queues | Recommended |
| Certbot | Latest | SSL certificates | Recommended |

### Docker Requirements (Admin VM Only)

| Service | Image | Purpose |
|---------|-------|--------|
| Redis | redis:7-alpine | Cache and queues |
| Elasticsearch | elasticsearch:8.11+ | Search and RAG |
| Qdrant | qdrant/qdrant:latest | Vector database |
| PostgreSQL | postgres:16-alpine | RAG metadata |

#### Docker Resource Allocation

| Container | CPU | RAM | Disk |
|-----------|-----|-----|------|
| Redis | 0.5 | 512 MB | 1 GB |
| Elasticsearch | 1 | 2 GB | 10 GB |
| Qdrant | 0.5 | 1 GB | 5 GB |
| PostgreSQL | 0.5 | 512 MB | 5 GB |

## Network Requirements

### VM Network Configuration

| Setting | Value |
|---------|-------|
| Network | 10.0.0.0/24 (private) |
| Gateway | 10.0.0.1 |
| DNS | 10.0.0.1, 8.8.8.8, 1.1.1.1 |

### Port Requirements

**Inbound (Must be open):**

| Port | Protocol | Service |
|------|----------|--------|
| 22 | TCP | SSH |
| 80 | TCP | HTTP |
| 443 | TCP | HTTPS |

**Internal (VM-to-VM):**

| Port | Protocol | Service |
|------|----------|--------|
| 3306 | TCP | MariaDB |
| 6379 | TCP | Redis |
| 9200 | TCP | Elasticsearch |
| 6333 | TCP | Qdrant |
| 5432 | TCP | PostgreSQL |

### Domain Names

Each application requires a valid domain:

| Application | Domain Example |
|-------------|----------------|
| Admin Panel | admin.soporteclientes.net |
| Cuentas | cuentas.kaviahoteles.com |
| Alquiler | clientes.gestiondepiso.com |
| IPS | ips.soporteclientes.net |
| Kavia | kavia.ostelio.com |

### SSL/TLS Requirements

- **TLS 1.2** minimum (TLS 1.3 recommended)
- Valid SSL certificates for all domains
- **Let's Encrypt** supported and recommended
- HSTS headers enabled

## Laravel Requirements

### Framework Versions

| Version | PHP Required | Status |
|---------|--------------|--------|
| Laravel 11.x | PHP 8.2+ | Recommended |
| Laravel 10.x | PHP 8.1+ | Supported |

### Required PHP Extensions for Laravel

- BCMath, Ctype, cURL, DOM, Fileinfo
- JSON, Mbstring, OpenSSL, PCRE
- PDO, Tokenizer, XML

## Browser Compatibility

### Supported Browsers

**Desktop:**
- Chrome 100+
- Firefox 100+
- Safari 16+
- Edge 100+

**Mobile:**
- Chrome for Android
- Safari for iOS 16+

**Not Supported:**
- Internet Explorer (any version)

## Security Requirements

### Firewall

- iptables/nftables configured per VM
- Proxmox firewall at hypervisor level
- Rate limiting configured
- DDoS protection recommended

### SSH

- Key-based authentication required
- Password authentication disabled (production)
- Root login disabled
- Non-standard port recommended (optional)

## Backup Requirements

### Storage

- Local snapshots: 2x production data size
- Off-site backup location required
- 30-day retention recommended

### Backup System

- XNetBackup CDP (Continuous Data Protection)
- Proxmox VM snapshots
- Daily database dumps
- Tested restore procedures

## Performance Recommendations

### PHP-FPM Pool

```ini
; /etc/php/8.4/fpm/pool.d/www.conf
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500
```

### Nginx Configuration

```nginx
worker_processes auto;
worker_connections 1024;
keepalive_timeout 65;

gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
```

## Compatibility Matrix

| Component | Debian 13 | Debian 12 | Ubuntu 24.04 | AlmaLinux 8 |
|-----------|-----------|-----------|--------------|-------------|
| PHP 8.4 | Native | Ondrej PPA | Ondrej PPA | Remi |
| MariaDB 11.8 | Native | MariaDB repo | MariaDB repo | MariaDB repo |
| Nginx 1.27 | Native | Nginx repo | Nginx repo | Nginx repo |
| Redis 7 | Native | Redis repo | Native | Remi |

## Pre-Installation Checklist

Before installation, verify:

- [ ] Proxmox host meets hardware requirements
- [ ] VMs are created with correct resources
- [ ] Network bridge is configured (10.0.0.x)
- [ ] Debian 13 installed on VMs
- [ ] Domain names are configured in DNS
- [ ] SSL certificates are ready or Let's Encrypt configured
- [ ] Backup storage is available
- [ ] SSH keys are distributed

## Summary by VM Type

### Standard Application VM

```yaml
os: Debian 13
cpu: 2 cores
ram: 2 GB
disk: 20 GB
stack:
  - nginx 1.27+
  - php-fpm 8.4
  - mariadb 11.8
  - supervisor
  - composer
```

### Admin VM (SOLTIA)

```yaml
os: Debian 13
cpu: 4 cores
ram: 4-8 GB
disk: 40-80 GB
stack:
  - nginx 1.27+
  - php-fpm 8.4
  - mariadb 11.8
  - docker
  - redis
  - elasticsearch
  - qdrant
  - postgresql
```

---

*For installation instructions, see [Installation Guide](installation.md)*
*For infrastructure details, see [Proxmox Infrastructure](../architecture/infrastructure-proxmox.md)*
