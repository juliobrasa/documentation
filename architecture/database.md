# Database Design

Complete database architecture and schema documentation for the Hosting Management Platform.

## Overview

The system uses three separate MySQL/MariaDB databases to maintain separation of concerns and allow independent scaling:

1. **whm_panel** - WHM management data
2. **cpanel1db** - Billing and subscription data
3. **admindb** - Administration and system data

## Database Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Application Layer                  │
└────────┬───────────────┬────────────────┬───────────┘
         │               │                │
         ▼               ▼                ▼
    ┌─────────┐    ┌──────────┐    ┌──────────┐
    │   WHM   │    │  cPanel  │    │  Admin   │
    │Database │    │ Database │    │ Database │
    └─────────┘    └──────────┘    └──────────┘
```

## WHM Panel Database (whm_panel)

### Tables Overview

#### servers
Stores WHM server information.

```sql
CREATE TABLE servers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    hostname VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    port INT DEFAULT 2087,
    username VARCHAR(255) NOT NULL,
    api_token TEXT NOT NULL,
    type ENUM('whm', 'cpanel', 'dedicated') DEFAULT 'whm',
    status ENUM('active', 'inactive', 'maintenance') DEFAULT 'active',
    max_accounts INT DEFAULT 100,
    current_accounts INT DEFAULT 0,
    nameserver1 VARCHAR(255),
    nameserver2 VARCHAR(255),
    nameserver3 VARCHAR(255),
    nameserver4 VARCHAR(255),
    last_sync_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_status (status),
    INDEX idx_hostname (hostname)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### packages
Hosting package definitions.

```sql
CREATE TABLE packages (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    disk_quota INT NOT NULL COMMENT 'MB',
    bandwidth INT NOT NULL COMMENT 'MB',
    max_emails INT DEFAULT 0 COMMENT '0 = unlimited',
    max_databases INT DEFAULT 0,
    max_ftp_accounts INT DEFAULT 0,
    max_domains INT DEFAULT 1,
    max_subdomains INT DEFAULT 0,
    max_parked_domains INT DEFAULT 0,
    cgi_access BOOLEAN DEFAULT TRUE,
    shell_access BOOLEAN DEFAULT FALSE,
    max_email_per_hour INT DEFAULT 100,
    max_defer_fail_percentage INT DEFAULT 100,
    is_reseller BOOLEAN DEFAULT FALSE,
    language VARCHAR(10) DEFAULT 'en',
    cpmod VARCHAR(50) DEFAULT 'paper_lantern',
    feature_list VARCHAR(255),
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### accounts
Hosting account information.

```sql
CREATE TABLE accounts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    server_id BIGINT UNSIGNED NOT NULL,
    package_id BIGINT UNSIGNED NOT NULL,
    domain VARCHAR(255) NOT NULL,
    username VARCHAR(16) NOT NULL,
    email VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255),
    owner VARCHAR(255) COMMENT 'Reseller owner',
    plan VARCHAR(255),
    disk_used BIGINT DEFAULT 0 COMMENT 'Bytes',
    disk_limit BIGINT COMMENT 'Bytes',
    bandwidth_used BIGINT DEFAULT 0 COMMENT 'Bytes',
    bandwidth_limit BIGINT COMMENT 'Bytes',
    suspended BOOLEAN DEFAULT FALSE,
    suspended_reason TEXT,
    suspended_at TIMESTAMP NULL,
    ip_address VARCHAR(45),
    startdate TIMESTAMP NULL,
    partition VARCHAR(255),
    unix_startdate BIGINT,
    disklimit INT,
    diskused INT,
    maxaddons INT,
    maxftp INT,
    maxlst INT,
    maxparked INT,
    maxpop INT,
    maxsql INT,
    maxsub INT,
    status ENUM('active', 'suspended', 'terminated') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE,
    FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE RESTRICT,
    UNIQUE KEY unique_username_server (username, server_id),
    INDEX idx_domain (domain),
    INDEX idx_username (username),
    INDEX idx_status (status),
    INDEX idx_suspended (suspended),
    INDEX idx_server_id (server_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### resellers
Reseller account information.

```sql
CREATE TABLE resellers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    server_id BIGINT UNSIGNED NOT NULL,
    username VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    package_id BIGINT UNSIGNED,
    max_accounts INT DEFAULT 10,
    current_accounts INT DEFAULT 0,
    disk_limit BIGINT COMMENT 'MB',
    disk_used BIGINT DEFAULT 0 COMMENT 'MB',
    bandwidth_limit BIGINT COMMENT 'MB',
    bandwidth_used BIGINT DEFAULT 0 COMMENT 'MB',
    acl_list TEXT COMMENT 'JSON array of permissions',
    nameservers TEXT COMMENT 'JSON array',
    status ENUM('active', 'suspended', 'terminated') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE,
    FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE SET NULL,
    UNIQUE KEY unique_username_server (username, server_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### backups
Backup tracking and management.

```sql
CREATE TABLE backups (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id BIGINT UNSIGNED,
    server_id BIGINT UNSIGNED NOT NULL,
    backup_type ENUM('full', 'incremental', 'database', 'files') DEFAULT 'full',
    file_path TEXT,
    file_size BIGINT COMMENT 'Bytes',
    status ENUM('pending', 'in_progress', 'completed', 'failed') DEFAULT 'pending',
    started_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    error_message TEXT,
    checksum VARCHAR(255),
    storage_location VARCHAR(255) COMMENT 'local, s3, ftp, etc',
    retention_days INT DEFAULT 30,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
    FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE,
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### activity_logs
Activity tracking for WHM operations.

```sql
CREATE TABLE activity_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED,
    account_id BIGINT UNSIGNED,
    server_id BIGINT UNSIGNED,
    action VARCHAR(255) NOT NULL,
    description TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_account_id (account_id),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## cPanel Database (cpanel1db)

### Tables Overview

#### billing_plans
Billing plan definitions.

```sql
CREATE TABLE billing_plans (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    package_id BIGINT UNSIGNED,
    price_monthly DECIMAL(10, 2) NOT NULL,
    price_quarterly DECIMAL(10, 2),
    price_semiannually DECIMAL(10, 2),
    price_yearly DECIMAL(10, 2),
    price_biennially DECIMAL(10, 2),
    price_triennially DECIMAL(10, 2),
    setup_fee DECIMAL(10, 2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'USD',
    billing_cycle ENUM('monthly', 'quarterly', 'semiannually', 'yearly', 'biennially', 'triennially'),
    features JSON,
    trial_days INT DEFAULT 0,
    is_featured BOOLEAN DEFAULT FALSE,
    is_visible BOOLEAN DEFAULT TRUE,
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### subscriptions
Customer subscriptions.

```sql
CREATE TABLE subscriptions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    plan_id BIGINT UNSIGNED NOT NULL,
    account_id BIGINT UNSIGNED,
    status ENUM('active', 'suspended', 'cancelled', 'expired', 'trial') DEFAULT 'active',
    billing_cycle ENUM('monthly', 'quarterly', 'semiannually', 'yearly', 'biennially', 'triennially'),
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    next_billing_date DATE,
    last_billing_date DATE,
    trial_ends_at TIMESTAMP NULL,
    started_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    cancellation_reason TEXT,
    ends_at TIMESTAMP NULL,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (plan_id) REFERENCES billing_plans(id) ON DELETE RESTRICT,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_next_billing_date (next_billing_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### invoices
Invoice tracking.

```sql
CREATE TABLE invoices (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    subscription_id BIGINT UNSIGNED,
    invoice_number VARCHAR(255) UNIQUE NOT NULL,
    status ENUM('pending', 'paid', 'overdue', 'cancelled', 'refunded') DEFAULT 'pending',
    subtotal DECIMAL(10, 2) NOT NULL,
    tax DECIMAL(10, 2) DEFAULT 0,
    total DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    due_date DATE,
    paid_at TIMESTAMP NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_invoice_number (invoice_number),
    INDEX idx_status (status),
    INDEX idx_due_date (due_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### invoice_items
Individual invoice line items.

```sql
CREATE TABLE invoice_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    invoice_id BIGINT UNSIGNED NOT NULL,
    description TEXT NOT NULL,
    quantity INT DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
    INDEX idx_invoice_id (invoice_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### payments
Payment transaction records.

```sql
CREATE TABLE payments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    invoice_id BIGINT UNSIGNED,
    transaction_id VARCHAR(255) UNIQUE,
    payment_method ENUM('stripe', 'paypal', 'bank_transfer', 'credit', 'manual') NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'pending',
    gateway_response JSON,
    notes TEXT,
    processed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_transaction_id (transaction_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### payment_methods
Stored payment methods.

```sql
CREATE TABLE payment_methods (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    type ENUM('card', 'paypal', 'bank') NOT NULL,
    provider VARCHAR(50),
    token TEXT,
    last_four VARCHAR(4),
    card_brand VARCHAR(50),
    exp_month INT,
    exp_year INT,
    is_default BOOLEAN DEFAULT FALSE,
    status ENUM('active', 'expired', 'invalid') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_is_default (is_default)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### licenses
Software license management.

```sql
CREATE TABLE licenses (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    license_key VARCHAR(255) UNIQUE NOT NULL,
    user_id BIGINT UNSIGNED,
    product VARCHAR(255) NOT NULL,
    domain VARCHAR(255),
    ip_address VARCHAR(45),
    status ENUM('active', 'suspended', 'expired', 'cancelled') DEFAULT 'active',
    max_activations INT DEFAULT 1,
    current_activations INT DEFAULT 0,
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    last_checked_at TIMESTAMP NULL,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_license_key (license_key),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## Admin Database (admindb)

### Tables Overview

#### users
System users and administrators.

```sql
CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    email_verified_at TIMESTAMP NULL,
    password VARCHAR(255) NOT NULL,
    remember_token VARCHAR(100),
    two_factor_secret TEXT,
    two_factor_recovery_codes TEXT,
    avatar VARCHAR(255),
    phone VARCHAR(20),
    timezone VARCHAR(50) DEFAULT 'UTC',
    language VARCHAR(10) DEFAULT 'en',
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    last_login_at TIMESTAMP NULL,
    last_login_ip VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_email (email),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### roles
User roles.

```sql
CREATE TABLE roles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### permissions
System permissions.

```sql
CREATE TABLE permissions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255),
    description TEXT,
    group_name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_group_name (group_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### role_user
Role assignments to users.

```sql
CREATE TABLE role_user (
    user_id BIGINT UNSIGNED NOT NULL,
    role_id BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### permission_role
Permission assignments to roles.

```sql
CREATE TABLE permission_role (
    permission_id BIGINT UNSIGNED NOT NULL,
    role_id BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (permission_id, role_id),
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### audit_logs
System audit trail.

```sql
CREATE TABLE audit_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED,
    event VARCHAR(255) NOT NULL,
    auditable_type VARCHAR(255),
    auditable_id BIGINT UNSIGNED,
    old_values JSON,
    new_values JSON,
    url TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    tags VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_event (event),
    INDEX idx_auditable (auditable_type, auditable_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### settings
System configuration settings.

```sql
CREATE TABLE settings (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    key VARCHAR(255) UNIQUE NOT NULL,
    value TEXT,
    type VARCHAR(50) DEFAULT 'string',
    group_name VARCHAR(255),
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_key (key),
    INDEX idx_group_name (group_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### api_tokens
API authentication tokens.

```sql
CREATE TABLE api_tokens (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(255) NOT NULL,
    token VARCHAR(64) UNIQUE NOT NULL,
    abilities TEXT,
    last_used_at TIMESTAMP NULL,
    expires_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_token (token),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## Database Relationships

### Cross-Database Relationships

While the databases are separate, they maintain logical relationships through IDs:

- `accounts.id` → `subscriptions.account_id`
- `users.id` → `subscriptions.user_id`
- `packages.id` → `billing_plans.package_id`

These are managed at the application level, not through foreign keys.

## Indexes and Performance

### Key Indexes

1. **Primary Keys**: All tables have auto-incrementing IDs
2. **Foreign Keys**: Properly indexed for relationship queries
3. **Status Fields**: Indexed for filtering
4. **Timestamps**: Indexed for date-range queries
5. **Unique Keys**: On unique identifiers (email, username, license_key)

### Query Optimization

- Use composite indexes for common query patterns
- Partition large tables by date if needed
- Regular ANALYZE TABLE operations
- Monitor slow query log

## Backup Strategy

### Daily Backups
```bash
mysqldump --single-transaction whm_panel > whm_panel_backup.sql
mysqldump --single-transaction cpanel1db > cpanel1db_backup.sql
mysqldump --single-transaction admindb > admindb_backup.sql
```

### Point-in-Time Recovery
- Enable binary logging
- Maintain binary logs for 7 days
- Test restore procedures monthly

## Migration Management

All migrations are managed through Laravel:

```bash
# Run migrations
php artisan migrate

# Rollback last migration
php artisan migrate:rollback

# Fresh install with seed data
php artisan migrate:fresh --seed
```

## Data Retention

### Default Retention Policies

- Activity Logs: 90 days
- Audit Logs: 1 year
- Deleted Accounts: 30 days (soft delete)
- Payment Records: 7 years (compliance)
- Backup Files: 30 days

---

*For database configuration, see [Configuration Guide](../guides/configuration.md)*
