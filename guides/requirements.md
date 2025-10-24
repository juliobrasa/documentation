# System Requirements

Complete system requirements for the Hosting Management Platform.

## Overview

This document outlines all hardware, software, and network requirements for deploying the Hosting Management Platform.

## Hardware Requirements

### Minimum Requirements (Testing/Development)

**Single Server Setup:**
- **CPU**: 2 cores @ 2.0 GHz
- **RAM**: 2 GB
- **Storage**: 20 GB SSD
- **Network**: 100 Mbps

**Suitable for:**
- Development environments
- Testing installations
- Up to 10 hosting accounts
- Single administrator

### Recommended Requirements (Production)

**Single Server Setup:**
- **CPU**: 4 cores @ 2.5 GHz or higher
- **RAM**: 8 GB (16 GB preferred)
- **Storage**: 100 GB SSD
- **Network**: 1 Gbps
- **Backup Storage**: 200 GB minimum

**Suitable for:**
- Small to medium production
- Up to 100 hosting accounts
- Multiple administrators
- Basic reseller hosting

### High-Performance Requirements (Enterprise)

**Multi-Server Setup:**

**Application Server:**
- **CPU**: 8+ cores @ 3.0 GHz
- **RAM**: 16-32 GB
- **Storage**: 200 GB NVMe SSD
- **Network**: 1-10 Gbps

**Database Server:**
- **CPU**: 8+ cores @ 3.0 GHz
- **RAM**: 32-64 GB
- **Storage**: 500 GB NVMe SSD with RAID 10
- **Network**: 10 Gbps

**WHM Servers (Multiple):**
- Per WHM specifications
- Additional resources as needed

**Load Balancer:**
- **CPU**: 4 cores
- **RAM**: 8 GB
- **Network**: 10 Gbps

**Suitable for:**
- Large production environments
- 500+ hosting accounts
- High availability requirements
- Multiple resellers
- Heavy API usage

## Software Requirements

### Operating System

**Supported:**
- CentOS 7.x / 8.x (x86_64)
- RHEL 7.x / 8.x (x86_64)
- AlmaLinux 8.x (x86_64)
- Rocky Linux 8.x (x86_64)

**Not Supported:**
- Ubuntu/Debian (may work but not tested)
- Windows Server
- macOS
- 32-bit systems

**Recommended:** AlmaLinux 8.x (CentOS replacement)

### Web Server

**Apache HTTP Server:**
- Version: 2.4.6 or higher
- Required modules:
  - mod_rewrite
  - mod_ssl
  - mod_headers
  - mod_expires
  - mod_deflate

**OR Nginx:**
- Version: 1.18 or higher
- With PHP-FPM support

**Note:** Apache is recommended for easier cPanel integration.

### PHP

**Version:** 8.0 or higher (8.1 recommended)

**Required Extensions:**
- php-cli
- php-common
- php-mysqlnd (MySQL Native Driver)
- php-pdo
- php-xml
- php-json
- php-mbstring
- php-bcmath
- php-gd
- php-zip
- php-curl
- php-intl
- php-soap
- php-tokenizer
- php-opcache

**PHP Configuration:**
```ini
memory_limit = 256M
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 300
max_input_time = 300
date.timezone = UTC
```

### Database

**MySQL:**
- Version: 5.7 or higher (8.0 recommended)

**OR MariaDB:**
- Version: 10.3 or higher (10.6 recommended)

**Configuration Requirements:**
- InnoDB engine enabled
- UTF8MB4 charset support
- Query cache (optional but recommended)
- Binary logging for replication (production)

**Minimum Settings:**
```ini
max_connections = 200
innodb_buffer_pool_size = 512M (adjust based on RAM)
innodb_log_file_size = 128M
max_allowed_packet = 64M
```

### Additional Software

**Required:**
- **Composer**: 2.0 or higher
- **Node.js**: 14.x or higher (16.x LTS recommended)
- **NPM**: 6.x or higher
- **Git**: 2.x or higher
- **OpenSSL**: 1.0.2 or higher

**Optional but Recommended:**
- **Redis**: 5.0 or higher (for caching and queues)
- **Memcached**: 1.5 or higher (alternative cache)
- **Supervisor**: Process manager for queue workers
- **Certbot**: For Let's Encrypt SSL certificates
- **Elasticsearch**: 7.x (for advanced search)

## Network Requirements

### Ports

**Inbound (Must be open):**
- `80/TCP` - HTTP
- `443/TCP` - HTTPS
- `22/TCP` - SSH (restrict to admin IPs)

**Optional Inbound:**
- `2087/TCP` - WHM API access
- `2083/TCP` - cPanel access (if direct)
- `3306/TCP` - MySQL (only if remote access needed)
- `6379/TCP` - Redis (only if remote access needed)

**Outbound:**
- `80/TCP` - HTTP (for updates, APIs)
- `443/TCP` - HTTPS (for updates, APIs)
- `25/TCP` or `587/TCP` - SMTP (for email)
- `2087/TCP` - WHM API (to managed servers)

### Domain Names

**Required:**
- At least 3 subdomains or separate domains:
  - WHM Panel: `whm.yourdomain.com`
  - cPanel System: `cpanel.yourdomain.com`
  - Admin Panel: `admin.yourdomain.com`

**Optional:**
- API endpoint: `api.yourdomain.com`

**DNS Requirements:**
- Valid A records pointing to server IP
- Ability to modify DNS records
- TTL set appropriately (300-3600 seconds)

### Bandwidth

**Minimum:**
- 1 TB/month for up to 50 accounts

**Recommended:**
- 5 TB/month for production
- Unmetered for enterprise

### IP Addresses

**Minimum:**
- 1 public IPv4 address

**Recommended:**
- 1 public IPv4 for main services
- Additional IPs for SSL (if not using SNI)
- IPv6 support recommended

## SSL/TLS Requirements

- **TLS 1.2** minimum (TLS 1.3 recommended)
- Valid SSL certificates for all domains
- **Let's Encrypt** supported (free)
- Wildcard certificates supported
- Self-signed certificates (development only)

## Browser Compatibility

### Supported Browsers

**Desktop:**
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

**Mobile:**
- Chrome for Android
- Safari for iOS 14+

**Not Supported:**
- Internet Explorer (any version)
- Opera Mini

## Security Requirements

### Firewall

- Firewalld or iptables configured
- Only necessary ports open
- Rate limiting configured
- DDoS protection recommended

### SELinux

- Can run with SELinux enforcing
- Permissive mode acceptable
- Disabled mode not recommended

### SSH

- Key-based authentication recommended
- Password authentication disabled (production)
- Root login disabled (production)
- Non-standard port recommended

## WHM/cPanel Server Requirements

If managing WHM/cPanel servers:

### WHM Server Requirements
- WHM 11.92 or higher
- API token access enabled
- JSON API available
- Allow IP address of management server

### cPanel Version
- cPanel 11.92 or higher
- WHMCS integration compatible

## Performance Considerations

### For 50 Accounts
- 4 GB RAM minimum
- 4 CPU cores
- 50 GB storage

### For 100 Accounts
- 8 GB RAM minimum
- 4-6 CPU cores
- 100 GB storage

### For 500 Accounts
- 16 GB RAM minimum
- 8+ CPU cores
- 200 GB+ storage
- Consider multi-server setup

### For 1000+ Accounts
- Multi-server setup required
- Load balancer needed
- Database replication
- 32+ GB RAM
- 16+ CPU cores distributed

## Backup Requirements

### Storage
- 2x production data size minimum
- Off-site backup location
- 30-day retention recommended

### Backup System
- Automated daily backups
- Point-in-time recovery capability
- Tested restore procedures
- Backup monitoring

## Development Environment

For local development:

**Minimum:**
- Any modern OS (Linux, macOS, Windows)
- 4 GB RAM
- Docker Desktop (optional but recommended)
- Code editor (VSCode, PHPStorm)

**Recommended Tools:**
- Vagrant or Docker for local environment
- Git for version control
- Postman for API testing
- MySQL Workbench or similar

## Third-Party Services

### Optional Integrations

**Payment Gateways:**
- Stripe account
- PayPal Business account

**Email Services:**
- SMTP server or service (Gmail, SendGrid, Mailgun)
- Minimum 1000 emails/month

**Monitoring:**
- Uptime monitoring service
- Application performance monitoring (optional)

**CDN (Optional):**
- Cloudflare or similar
- For static asset delivery

## Licensing Requirements

### Software Licenses

**Open Source (Free):**
- Linux OS
- Apache/Nginx
- PHP
- MySQL/MariaDB
- Laravel framework

**Commercial (If applicable):**
- cPanel/WHM licenses for managed servers
- SSL certificates (if not using Let's Encrypt)
- Premium monitoring tools (optional)

## Compliance Requirements

### Data Protection
- GDPR compliance (if handling EU data)
- Data encryption at rest
- Secure data transmission (TLS)
- Backup encryption

### Industry Standards
- PCI DSS (if processing payments)
- SOC 2 (for enterprise customers)
- ISO 27001 (for enterprise)

## Scalability Considerations

### Vertical Scaling
- Plan for RAM upgrades
- CPU upgrades possible
- Storage expansion capability

### Horizontal Scaling
- Multiple application servers
- Database read replicas
- Distributed caching
- Load balancer capacity

## Testing Requirements

### Recommended Test Environment
- Separate from production
- Similar specs to production
- Isolated network
- Backup/restore testing

## Summary Checklist

Before installation, verify:

- [ ] Server meets minimum hardware requirements
- [ ] Operating system is supported version
- [ ] All required ports are open
- [ ] Domain names are configured
- [ ] SSL certificates are ready
- [ ] Backup storage is available
- [ ] Database server is ready
- [ ] PHP version and extensions are correct
- [ ] Network connectivity is stable
- [ ] Security measures are in place

---

*For installation instructions, see [Installation Guide](installation.md)*
