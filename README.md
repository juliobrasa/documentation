# Hosting Management Platform - Documentation

Documentación completa del sistema de gestión de hosting.

## 📚 Índice de Contenidos

### 🚀 Getting Started
- [Installation Guide](guides/installation.md)
- [Quick Start](guides/quickstart.md)
- [System Requirements](guides/requirements.md)

### 🏗️ Architecture
- [System Architecture](architecture/overview.md)
- [Database Design](architecture/database.md)
- [API Architecture](architecture/api.md)
- [Security Model](architecture/security.md)

### 💻 Components
- [WHM Panel](guides/whm-panel.md)
- [cPanel Integration](guides/cpanel-integration.md)
- [Admin Panel](guides/admin-panel.md)

### 🔌 API Documentation
- [API Overview](api/overview.md)
- [Authentication](api/authentication.md)
- [Endpoints Reference](api/endpoints.md)
- [Webhooks](api/webhooks.md)

### 🚢 Deployment
- [Production Deployment](deployment/production.md)
- [Docker Setup](deployment/docker.md)
- [Scaling Guide](deployment/scaling.md)
- [Backup & Recovery](deployment/backup.md)

### 🔧 Administration
- [User Management](guides/user-management.md)
- [System Configuration](guides/configuration.md)
- [Monitoring](guides/monitoring.md)
- [Troubleshooting](guides/troubleshooting.md)

### 🔐 Security
- [Security Best Practices](guides/security.md)
- [SSL Configuration](guides/ssl.md)
- [Firewall Setup](guides/firewall.md)

## 🏛️ System Overview

The Hosting Management Platform is a comprehensive solution for managing web hosting services, consisting of three main components:

### WHM Panel
Complete WHM server management interface with:
- Multi-server management
- Account creation and management
- Package management
- Reseller management
- Backup automation
- Resource monitoring

### cPanel Integration System
Enterprise-grade billing and automation system:
- Complete billing system
- Subscription management
- Invoice generation
- Payment processing
- Automated installer
- License management

### Admin Panel
Central administration and monitoring:
- User management
- System configuration
- API management
- Audit logging
- Health monitoring
- Report generation

## 🔗 Quick Links

- **GitHub Repositories**
  - [WHM Panel](https://github.com/juliobrasa/whm)
  - [cPanel System](https://github.com/juliobrasa/cpanel)
  - [Admin Panel](https://github.com/juliobrasa/admin-panel)
  - [API System](https://github.com/juliobrasa/api)
  - [Database](https://github.com/juliobrasa/database)
  - [Installer](https://github.com/juliobrasa/installer)

- **Live Systems**
  - WHM Panel: https://whm.soporteclientes.net
  - cPanel: https://cpanel1.soporteclientes.net
  - Admin: https://admin.soporteclientes.net

## 📋 Prerequisites

- CentOS/RHEL/AlmaLinux 7+
- PHP 8.0+
- MySQL/MariaDB 5.7+
- Apache/Nginx
- Composer
- Node.js & NPM
- Redis (optional)

## 🚀 Quick Installation

```bash
wget https://raw.githubusercontent.com/juliobrasa/installer/master/scripts/install.sh
chmod +x install.sh
sudo ./install.sh
```

## 📦 Deploying Documentation

### Automated Deployment Script

Deploy this documentation to production or staging servers using the provided script:

```bash
# Download deployment script
wget https://raw.githubusercontent.com/juliobrasa/documentation/main/desplegar-documentacion.sh
chmod +x desplegar-documentacion.sh

# Deploy to staging
sudo ./desplegar-documentacion.sh

# Deploy to production
sudo ./desplegar-documentacion.sh -e production -b main
```

**Features:**
- ✅ Automatic Git clone/pull
- ✅ Automatic backups before deployment
- ✅ Web server configuration (Apache/Nginx)
- ✅ Firewall setup
- ✅ Permission management
- ✅ Deployment verification

**Available Options:**
```bash
-e, --environment    production | staging (default: staging)
-b, --branch         Git branch to deploy (default: main)
-d, --directory      Installation directory (default: /var/www/docs)
-w, --web-server     apache | nginx | none (default: apache)
-p, --port           Web server port (default: 8080)
-h, --help           Show help
```

**Examples:**
```bash
# Staging deployment with develop branch
sudo ./desplegar-documentacion.sh -e staging -b develop -p 8081

# Production with Nginx
sudo ./desplegar-documentacion.sh -e production -w nginx -p 8090

# Just clone/update without web server
sudo ./desplegar-documentacion.sh -w none -d /opt/docs
```

### Rollback Script

If you need to rollback to a previous version:

```bash
# List available backups
sudo ./rollback-documentacion.sh -l

# Restore latest backup
sudo ./rollback-documentacion.sh

# Restore specific backup
sudo ./rollback-documentacion.sh -b /var/backups/docs/docs_backup_20251023_120000.tar.gz

# Rollback to specific Git commit
sudo ./rollback-documentacion.sh -c abc1234
```

For detailed deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md)

## 📖 Documentation Structure

```
documentation/
├── guides/              # User and admin guides
├── api/                # API documentation
├── architecture/       # System architecture docs
└── deployment/         # Deployment guides
```

## 🤝 Contributing

Please read our contributing guidelines before submitting pull requests.

## 📝 License

Proprietary software - All rights reserved

## 📞 Support

For technical support, please contact the development team.

---

*Last updated: August 2025*