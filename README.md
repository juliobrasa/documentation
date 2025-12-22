# Hosting Management Platform - Documentation

Documentation for the Hosting Management Platform running on Proxmox virtualization infrastructure.

**Last Updated:** December 2025

## Infrastructure Overview

The platform runs on a **Proxmox VE** hypervisor with multiple specialized VMs:

```
┌─────────────────────────────────────────────────────────────┐
│                    Proxmox VE Host                           │
├─────────────────────────────────────────────────────────────┤
│  10.0.0.100  │  10.0.0.101  │  10.0.0.102  │  10.0.0.103   │
│   cuentas    │  gestionpiso │  devostelio  │    admin      │
├──────────────┼──────────────┼──────────────┼───────────────┤
│  10.0.0.104  │  10.0.0.105  │  10.0.0.106  │  10.0.0.107   │
│     ips      │    kavia     │   ansible    │ manageremail  │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

| Component | Version |
|-----------|---------|  
| OS | Debian 13 (Trixie) |
| Web Server | Nginx 1.27+ |
| PHP | 8.4 with FPM |
| Database | MariaDB 11.8 |
| Framework | Laravel 10.x/11.x |

## Documentation Index

### Getting Started
- [Installation Guide](guides/installation.md)
- [System Requirements](guides/requirements.md)
- [Quick Start](guides/quickstart.md)

### Architecture
- [System Architecture](architecture/overview.md)
- [Proxmox Infrastructure](architecture/infrastructure-proxmox.md)
- [Database Design](architecture/database.md)
- [API Architecture](architecture/api.md)
- [Security Model](architecture/security.md)

### Components

#### Virtual Machines

| VM | IP | Application | Purpose |
|----|-----|-------------|---------|
| cuentas | 10.0.0.100 | Cuentas App | Kavia Hotels accounts |
| gestionpiso | 10.0.0.101 | Alquiler App | Property rental |
| devostelio | 10.0.0.102 | Dev Environment | Development/staging |
| admin | 10.0.0.103 | SOLTIA Admin | AI-powered administration |
| ips | 10.0.0.104 | IPS App | IPS management |
| kavia | 10.0.0.105 | Kavia App | Kavia platform |
| ansible | 10.0.0.106 | Automation | Ansible controller |
| manageremail | 10.0.0.107 | Email | Email management |

#### External Servers

| Server | IP | OS | Purpose |
|--------|-----|-----|--------- |
| cpanel1 | 184.174.36.104 | AlmaLinux 8.10 | cPanel hosting |
| soltia1 | cph02.soltia.net | CloudLinux 8.10 | cPanel/WHM |

### SOLTIA AI System

The admin VM (10.0.0.103) runs the SOLTIA enterprise IA system with **25 specialized agents**:

| Department | Agents | Function |
|------------|--------|----------|
| Executives | 3 | Strategic decisions |
| Infrastructure | 4 | Server management |
| Security | 3 | Threat detection |
| DevOps | 5 | CI/CD, automation |
| Support | 4 | User assistance |
| Commercial | 3 | Billing, sales |
| Data | 3 | Analytics |

**Tech Stack (Docker):**
- Redis: Cache and queues
- Elasticsearch: Search and RAG
- Qdrant: Vector embeddings
- PostgreSQL: RAG metadata

### API Documentation
- [API Overview](api/overview.md)
- [Authentication](api/authentication.md)
- [Endpoints Reference](api/endpoints.md)
- [Webhooks](api/webhooks.md)

### Deployment
- [Production Deployment](deployment/production.md)
- [Docker Setup](deployment/docker.md)
- [Scaling Guide](deployment/scaling.md)
- [Backup & Recovery](deployment/backup.md)

### Administration
- [User Management](guides/user-management.md)
- [System Configuration](guides/configuration.md)
- [Monitoring](guides/monitoring.md)
- [Troubleshooting](guides/troubleshooting.md)

### Security
- [Security Best Practices](guides/security.md)
- [SSL Configuration](guides/ssl.md)
- [Firewall Setup](guides/firewall.md)

## Quick Installation

### Prerequisites
- Proxmox VE 8.x with VMs configured
- Debian 13 on each VM
- Network 10.0.0.x configured

### Install on a VM

```bash
# Update system
apt update && apt upgrade -y

# Install stack
apt install -y nginx php8.4-fpm php8.4-cli php8.4-common \
    php8.4-mysql php8.4-xml php8.4-mbstring php8.4-curl \
    php8.4-zip php8.4-gd php8.4-bcmath mariadb-server git

# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Clone and setup application
cd /var/www
git clone https://github.com/juliobrasa/[app].git app
cd app
composer install --no-dev
cp .env.example .env
php artisan key:generate
php artisan migrate --seed

# Set permissions
chown -R www-data:www-data /var/www/app
chmod -R 775 storage bootstrap/cache
```

## Documentation Deployment

### Deploy to Server

```bash
# Download deployment script
wget https://raw.githubusercontent.com/juliobrasa/documentation/main/desplegar-documentacion.sh
chmod +x desplegar-documentacion.sh

# Deploy to staging
sudo ./desplegar-documentacion.sh

# Deploy to production
sudo ./desplegar-documentacion.sh -e production -b main
```

### Rollback

```bash
# List backups
sudo ./rollback-documentacion.sh -l

# Restore latest
sudo ./rollback-documentacion.sh
```

## Repository Structure

```
documentation/
├── README.md                           # This file
├── DEPLOYMENT.md                       # Deployment instructions
├── architecture/
│   ├── overview.md                     # System architecture
│   ├── infrastructure-proxmox.md       # Proxmox VMs details
│   ├── database.md                     # Database design
│   ├── api.md                          # API architecture
│   └── security.md                     # Security model
├── guides/
│   ├── installation.md                 # Installation guide
│   ├── requirements.md                 # System requirements
│   ├── quickstart.md                   # Quick start
│   ├── configuration.md                # Configuration
│   ├── user-management.md              # User management
│   ├── monitoring.md                   # Monitoring
│   ├── troubleshooting.md              # Troubleshooting
│   ├── security.md                     # Security practices
│   ├── ssl.md                          # SSL configuration
│   └── firewall.md                     # Firewall setup
├── api/
│   ├── overview.md                     # API overview
│   ├── authentication.md               # Authentication
│   ├── endpoints.md                    # Endpoints reference
│   └── webhooks.md                     # Webhooks
└── deployment/
    ├── production.md                   # Production deployment
    ├── docker.md                       # Docker setup
    ├── scaling.md                      # Scaling guide
    └── backup.md                       # Backup & recovery
```

## GitHub Repositories

| Repository | Description |
|------------|-------------|
| [documentation](https://github.com/juliobrasa/documentation) | This documentation |
| [whm](https://github.com/juliobrasa/whm) | WHM Panel |
| [cpanel](https://github.com/juliobrasa/cpanel) | cPanel System |
| [admin-panel](https://github.com/juliobrasa/admin-panel) | Admin Panel |
| [api](https://github.com/juliobrasa/api) | API System |
| [database](https://github.com/juliobrasa/database) | Database schemas |
| [installer](https://github.com/juliobrasa/installer) | Installation scripts |

## Live Systems

| System | URL |
|--------|-----|
| Admin Panel | https://admin.soporteclientes.net |
| Cuentas | https://cuentas.kaviahoteles.com |
| Alquiler | https://clientes.gestiondepiso.com |
| IPS | https://ips.soporteclientes.net |
| Kavia | https://kavia.ostelio.com |

## Support

For technical support, contact the development team.

## License

Proprietary software - All rights reserved.

---

*Documentation maintained by the SOLTIA development team*
