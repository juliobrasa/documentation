# System Architecture Overview

## Current Infrastructure (Updated December 2025)

The platform has migrated to a **Proxmox-based virtualization architecture** with multiple specialized VMs running on a private network.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                        │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │
           ┌───────────────────────┼───────────────────────┐
           │                       │                       │
           ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  cpanel1        │    │  soltia1        │    │  Proxmox Host   │
│ 184.174.36.104  │    │ cph02.soltia.net│    │  (Hypervisor)   │
│ AlmaLinux 8.10  │    │ CloudLinux 8.10 │    │                 │
│ OpenLiteSpeed   │    │ cPanel/WHM      │    │                 │
└─────────────────┘    └─────────────────┘    └────────┬────────┘
                                                       │
                    ┌──────────────────────────────────┼──────────────────────────────────┐
                    │                         Private Network 10.0.0.x                     │
                    │                                                                      │
    ┌───────────────┼───────────────┬───────────────┬───────────────┬───────────────┐     │
    │               │               │               │               │               │     │
    ▼               ▼               ▼               ▼               ▼               ▼     │
┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐        │
│cuentas │    │gestion │    │  dev   │    │ admin  │    │  ips   │    │ kavia  │        │
│  .100  │    │  piso  │    │ostelio │    │  .103  │    │  .104  │    │  .105  │        │
│        │    │  .101  │    │  .102  │    │        │    │        │    │        │        │
└───┬────┘    └───┬────┘    └───┬────┘    └───┬────┘    └───┬────┘    └───┬────┘        │
    │             │             │             │             │             │             │
    └─────────────┴─────────────┴─────────────┴─────────────┴─────────────┘             │
                                        │                                               │
                                        ▼                                               │
                         ┌─────────────────────────────┐                               │
                         │     Shared Services         │                               │
                         │  - MariaDB 11.8 (per VM)    │                               │
                         │  - Nginx + PHP-FPM 8.4      │                               │
                         │  - Redis (cpanel1)          │                               │
                         │  - Docker (admin)           │                               │
                         └─────────────────────────────┘                               │
                                                                                        │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

## Proxmox Virtual Machines

### VM Network: 10.0.0.x

| VM Name | IP | Hostname | Application | Stack |
|---------|-----|----------|-------------|-------|
| cuentas | 10.0.0.100 | cuentas-kaviahoteles | Cuentas App | Debian 13 + Nginx + PHP 8.4 + MariaDB 11.8 |
| gestionpiso | 10.0.0.101 | clientes-gestiondepiso | Alquiler App | Debian 13 + Nginx + PHP 8.4 + MariaDB 11.8 |
| devostelio | 10.0.0.102 | dev-ostelio | Dev Environment | Debian 13 + Nginx + PHP 8.4 + MariaDB 11.8 |
| admin | 10.0.0.103 | admin-soporteclientes | SOLTIA Admin Panel | Debian 13 + Nginx + PHP 8.4 + MariaDB 11.8 + Docker |
| ips | 10.0.0.104 | ips-soporteclientes | IPS App | Debian 13 + Nginx + PHP 8.4 + MariaDB 11.8 |
| kavia | 10.0.0.105 | kavia-ostelio | Kavia App | Debian 13 + Nginx + PHP 8.4 + MariaDB 11.8 |
| ansible | 10.0.0.106 | - | Ansible Automation | TBD |
| manageremail | 10.0.0.107 | - | Email Management | TBD |
| whm | 10.0.0.108 | - | WHM Panel | TBD |

### External Servers

| Server | IP/Hostname | OS | Purpose | Stack |
|--------|-------------|-----|---------|-------|
| cpanel1 | 184.174.36.104 | AlmaLinux 8.10 | cPanel Hosting | OpenLiteSpeed + MariaDB + Redis |
| soltia1 | cph02.soltia.net:64227 | CloudLinux 8.10 | cPanel/WHM Hosting | cPanel Stack |

## Standard VM Stack (Proxmox VMs)

Each VM in the Proxmox cluster runs:

```
┌────────────────────────────────┐
│         Debian 13              │
├────────────────────────────────┤
│    Nginx (Web Server)          │
├────────────────────────────────┤
│    PHP-FPM 8.4                 │
├────────────────────────────────┤
│    MariaDB 11.8                │
├────────────────────────────────┤
│    Laravel Application         │
└────────────────────────────────┘
```

### Software Versions
- **OS**: Debian 13 (Trixie)
- **Web Server**: Nginx 1.27+
- **PHP**: 8.4.x with FPM
- **Database**: MariaDB 11.8.x
- **Framework**: Laravel 10.x/11.x

## Application Components

### 1. SOLTIA Admin Panel (admin - 10.0.0.103)

Central administration hub with AI agent system:

- **Location**: `/var/www/admin`
- **Purpose**: Central administration, monitoring, AI-powered automation
- **Special Features**:
  - 25 AI Agents (SOLTIA Architecture)
  - RAG System with Qdrant + Elasticsearch
  - XNetBackup CDP System
  - Docker containers for AI services

#### Docker Stack (admin VM):
```yaml
services:
  - redis: Cache and queues
  - elasticsearch: Search and RAG
  - qdrant: Vector database for embeddings
  - postgresql: RAG metadata storage
```

### 2. Cuentas App (cuentas - 10.0.0.100)

- **Location**: `/var/www/cuentas`
- **Purpose**: Account management for Kavia Hotels
- **Domain**: cuentas.kaviahoteles.com

### 3. Alquiler App (gestionpiso - 10.0.0.101)

- **Location**: `/var/www/alquiler`
- **Purpose**: Property rental management
- **Domain**: clientes.gestiondepiso.com

### 4. IPS App (ips - 10.0.0.104)

- **Location**: `/var/www/ips`
- **Purpose**: IPS management system
- **Domain**: ips.soporteclientes.net

### 5. Kavia App (kavia - 10.0.0.105)

- **Location**: `/var/www/kavia`
- **Purpose**: Kavia platform
- **Domain**: kavia.ostelio.com

### 6. Dev Ostelio (devostelio - 10.0.0.102)

- **Location**: `/var/www/dev`
- **Purpose**: Development environment
- **Domain**: dev.ostelio.com

## SOLTIA AI Agent Architecture

The admin server (10.0.0.103) hosts the SOLTIA system with 25 specialized AI agents organized in departments:

```
┌─────────────────────────────────────────────────────────────────┐
│                      SOLTIA IA ORCHESTRATOR                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │ EXECUTIVES  │  │INFRASTRUCTURE│  │  SECURITY   │             │
│  │  (3 agents) │  │  (4 agents)  │  │  (3 agents) │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   DEVOPS    │  │   SUPPORT   │  │ COMMERCIAL  │             │
│  │  (5 agents) │  │  (4 agents)  │  │  (3 agents) │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                  │
│  ┌─────────────┐                                                │
│  │    DATA     │                                                │
│  │  (3 agents) │                                                │
│  └─────────────┘                                                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Agent Departments:
1. **Executives** (3 agents): Strategic decisions and orchestration
2. **Infrastructure** (4 agents): Server, network, storage management
3. **Security** (3 agents): Threat detection, compliance, auditing
4. **DevOps** (5 agents): CI/CD, deployments, automation
5. **Support** (4 agents): Ticket handling, user assistance
6. **Commercial** (3 agents): Billing, sales, customer relations
7. **Data** (3 agents): Analytics, reporting, data processing

## Service Layer

### Authentication
- **Type**: Laravel Sanctum + JWT
- **Features**:
  - Token-based authentication
  - 2FA support
  - Session management
  - Role-based access control (RBAC)

### API Gateway
- **Protocol**: RESTful
- **Format**: JSON
- **Versioning**: URL-based (v1, v2)
- **Rate Limiting**: Per-user/IP

### Queue System
- **Driver**: Redis (on cpanel1) / Database (on VMs)
- **Workers**: Supervisor managed
- **Jobs**: Email, backups, reports, AI processing

### Cache Layer
- **Driver**: Redis/File
- **Strategies**: Tag-based invalidation

## Database Architecture

Each VM has its own MariaDB 11.8 instance:

| VM | Database | Purpose |
|----|----------|--------|
| admin | admindb | Admin panel, SOLTIA, users |
| cuentas | cuentasdb | Accounts management |
| gestionpiso | alquilerdb | Rental properties |
| ips | ipsdb | IPS data |
| kavia | kaviadb | Kavia platform |

### RAG System Databases (admin):
- **PostgreSQL**: Metadata and relations
- **Qdrant**: Vector embeddings (OpenAI)
- **Elasticsearch**: Full-text search and indexing

## Security Architecture

### Network Security
- VMs isolated on private 10.0.0.x network
- Proxmox firewall
- Per-VM iptables rules
- SSH key-based authentication

### Application Security
- HTTPS everywhere (Let's Encrypt/Custom SSL)
- CSRF protection
- SQL injection prevention
- XSS protection
- Input validation

### Data Protection
- Encryption at rest (AES-256)
- TLS 1.3 for transport
- Password hashing (bcrypt/argon2)
- Automated backups (XNetBackup CDP)

## Backup & Recovery

### XNetBackup CDP System
- Continuous Data Protection
- Automated snapshots
- Point-in-time recovery
- Off-site replication

### Backup Locations
- Local snapshots on Proxmox
- Remote backup server
- Database dumps (daily)
- File backups (incremental)

## Monitoring & Logging

### Infrastructure Monitoring
- Proxmox metrics
- VM resource tracking
- Network monitoring
- Disk usage alerts

### Application Monitoring
- Laravel Telescope (development)
- Custom health endpoints
- Error tracking
- Performance metrics

### Logging
- Centralized logging
- Laravel logs per application
- Nginx access/error logs
- System logs (journald)

## Deployment Flow

```
Developer → Git Push → CI/CD Pipeline → Build → Test → Deploy
                                                          │
                    ┌─────────────────────────────────────┤
                    │                                     │
                    ▼                                     ▼
            ┌──────────────┐                    ┌──────────────┐
            │   Staging    │                    │  Production  │
            │   (dev VM)   │                    │   (VMs)      │
            └──────────────┘                    └──────────────┘
```

### Deployment Methods
- Git-based deployments
- Ansible automation (10.0.0.106)
- Laravel Envoy scripts
- Zero-downtime deployments

## Technology Stack Summary

### Backend
- **Language**: PHP 8.4
- **Framework**: Laravel 10.x/11.x
- **API**: RESTful
- **Queue**: Redis/Database

### Frontend
- **Framework**: Vue.js 3 / Blade
- **CSS**: Tailwind CSS
- **Build**: Vite

### Infrastructure
- **Virtualization**: Proxmox VE
- **OS**: Debian 13 (VMs), AlmaLinux 8 (cpanel1), CloudLinux 8 (soltia1)
- **Web Server**: Nginx (VMs), OpenLiteSpeed (cpanel1)
- **Database**: MariaDB 11.8
- **Cache**: Redis
- **Search**: Elasticsearch
- **Vector DB**: Qdrant

### AI/ML
- **Embeddings**: OpenAI API
- **Vector Store**: Qdrant
- **RAG**: Custom implementation
- **Agents**: SOLTIA (25 agents)

### DevOps
- **CI/CD**: GitHub Actions
- **Automation**: Ansible
- **Containers**: Docker (admin VM)
- **Backup**: XNetBackup CDP
