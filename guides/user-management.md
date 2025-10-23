# User Management Guide

Comprehensive guide to user administration, role management, permissions, and access control in the Hosting Management Platform.

## Table of Contents

1. [Overview](#overview)
2. [User Types](#user-types)
3. [User Lifecycle](#user-lifecycle)
4. [Role-Based Access Control](#role-based-access-control)
5. [Permission System](#permission-system)
6. [User Creation and Onboarding](#user-creation-and-onboarding)
7. [User Authentication](#user-authentication)
8. [Multi-Factor Authentication](#multi-factor-authentication)
9. [Session Management](#session-management)
10. [User Groups and Teams](#user-groups-and-teams)
11. [Customer Management](#customer-management)
12. [Reseller Management](#reseller-management)
13. [User Activity Tracking](#user-activity-tracking)
14. [Account Security](#account-security)
15. [Bulk User Operations](#bulk-user-operations)
16. [User Import and Export](#user-import-and-export)
17. [Troubleshooting](#troubleshooting)
18. [Best Practices](#best-practices)
19. [Related Links](#related-links)

## Overview

The User Management system provides comprehensive tools for managing all types of users across the Hosting Management Platform, including administrators, staff, resellers, and customers. It implements a robust role-based access control (RBAC) system with granular permissions.

### Key Features

- **Multi-Level User Hierarchy**: Support for admins, staff, resellers, and customers
- **Role-Based Access Control**: Flexible role and permission system
- **Granular Permissions**: Fine-grained access control
- **Multi-Factor Authentication**: Enhanced security with 2FA/MFA
- **Session Management**: Concurrent session control
- **User Groups**: Organize users into teams and departments
- **Activity Tracking**: Complete audit trail of user actions
- **Bulk Operations**: Efficient management of multiple users
- **Self-Service Portal**: Customer account management
- **API Access Management**: Token-based API authentication

### User Management Architecture

```
┌────────────────────────────────────────────────┐
│           User Management System               │
├────────────────────────────────────────────────┤
│  ┌──────────┬──────────┬──────────┬─────────┐ │
│  │  Admins  │  Staff   │Resellers │Customers│ │
│  └────┬─────┴────┬─────┴────┬─────┴────┬────┘ │
│       │          │          │          │      │
│       └──────────┼──────────┼──────────┘      │
│                  │          │                  │
│         ┌────────▼──────────▼────────┐        │
│         │   RBAC Engine              │        │
│         │  - Roles                   │        │
│         │  - Permissions             │        │
│         │  - Policies                │        │
│         └────────────────────────────┘        │
└────────────────────────────────────────────────┘
```

## User Types

### System Administrators

**Characteristics:**
- Full system access
- Manage all components
- Configure system settings
- Access all customer data
- Manage staff and roles

**Default Permissions:**
```php
$superAdminPermissions = ['*']; // All permissions
```

### Staff Users

**Characteristics:**
- Department-specific access
- Limited administrative functions
- Customer support capabilities
- Report generation
- No system configuration access

**Common Roles:**
- Support Agent
- Billing Specialist
- Technical Support
- Manager
- Sales Representative

### Resellers

**Characteristics:**
- White-label capabilities
- Manage own customers
- Limited server access
- Custom pricing
- Own branding

**Capabilities:**
- Create/manage customer accounts
- View own statistics
- Manage own packages
- Access customer support
- Generate invoices

### Customers

**Characteristics:**
- Self-service portal access
- Manage own services
- View billing information
- Submit support tickets
- Access knowledge base

**Capabilities:**
- Service management
- Invoice payments
- Domain management
- Email account management
- File management

## User Lifecycle

### User States

```
New → Active → Suspended → Terminated
              ↓
          Inactive
```

**State Definitions:**

- **New**: Just created, pending activation
- **Active**: Full access granted
- **Inactive**: Temporarily disabled (by user or admin)
- **Suspended**: Restricted access (policy violation, non-payment)
- **Terminated**: Permanently disabled, scheduled for deletion

### Lifecycle Management

```bash
# Activate user
php artisan user:activate user@example.com

# Suspend user
php artisan user:suspend user@example.com \
  --reason="Policy violation" \
  --notify

# Terminate user
php artisan user:terminate user@example.com \
  --delete-data-after=30

# Reactivate suspended user
php artisan user:reactivate user@example.com
```

## Role-Based Access Control

### Understanding RBAC

The system implements a hierarchical RBAC model:

```
Super Admin
    ├── Administrator
    │   ├── Manager
    │   │   ├── Staff
    │   │   └── Support
    │   └── Billing Admin
    ├── Reseller
    │   └── Sub-Reseller
    └── Customer
```

### Predefined Roles

#### Super Administrator

```yaml
Role: super-admin
Description: Complete system access
Permissions: *
Cannot Be Modified: Yes
User Limit: Recommended 1-2
```

#### Administrator

```yaml
Role: administrator
Description: System administration without destructive operations
Permissions:
  - users.* (except super-admin management)
  - servers.*
  - settings.view
  - settings.update
  - reports.*
  - logs.view
Restrictions:
  - Cannot modify super-admin users
  - Cannot delete system
  - Cannot change critical security settings
```

#### Manager

```yaml
Role: manager
Description: Department or team management
Permissions:
  - users.view
  - users.create
  - users.update
  - customers.*
  - reports.view
  - reports.generate
  - tickets.*
Access Level: Department-specific
```

#### Support Agent

```yaml
Role: support
Description: Customer support access
Permissions:
  - customers.view
  - tickets.*
  - kb.view
  - kb.create
  - services.view
Access Level: Read-mostly with ticket management
```

#### Billing Specialist

```yaml
Role: billing
Description: Financial and billing operations
Permissions:
  - invoices.*
  - payments.*
  - subscriptions.*
  - reports.financial
  - customers.view
Access Level: Billing-specific operations
```

#### Reseller

```yaml
Role: reseller
Description: White-label hosting reseller
Permissions:
  - customers.create (own)
  - customers.manage (own)
  - packages.view
  - services.create (own customers)
  - invoices.view (own)
  - reports.view (own)
Restrictions:
  - Limited to own customer base
  - Cannot access other resellers
  - Resource quotas apply
```

### Creating Custom Roles

#### Via Admin Panel

Navigate to **Users > Roles > Create New**

```yaml
Create Role:
  Name: Technical Support
  Slug: tech-support
  Description: Technical support with server access

Permissions:
  Users:
    - users.view
    - customers.view

  Servers:
    - servers.view
    - servers.manage
    - accounts.view
    - accounts.suspend
    - accounts.unsuspend

  Support:
    - tickets.view
    - tickets.update
    - tickets.close

  Reports:
    - reports.view
    - reports.technical
```

#### Via Command Line

```bash
php artisan role:create \
  --name="Technical Support" \
  --slug=tech-support \
  --description="Technical support with server access" \
  --permissions=users.view,servers.*,tickets.*
```

#### Via API

```bash
curl -X POST https://admin.soporteclientes.net/api/v1/admin/roles \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Technical Support",
    "slug": "tech-support",
    "description": "Technical support with server access",
    "permissions": [
      "users.view",
      "customers.view",
      "servers.view",
      "servers.manage",
      "tickets.*"
    ]
  }'
```

### Role Hierarchy

Implement role hierarchy:

```php
// config/rbac.php
'role_hierarchy' => [
    'super-admin' => [],
    'administrator' => ['super-admin'],
    'manager' => ['administrator'],
    'staff' => ['manager'],
    'support' => ['manager'],
    'billing' => ['administrator'],
    'reseller' => [],
    'customer' => []
]
```

### Role Assignment

Assign roles to users:

```bash
# Assign single role
php artisan user:assign-role user@example.com administrator

# Assign multiple roles
php artisan user:assign-role user@example.com manager,billing

# Remove role
php artisan user:remove-role user@example.com manager

# View user roles
php artisan user:show-roles user@example.com
```

## Permission System

### Permission Structure

Permissions follow the format: `resource.action`

**Examples:**
```
users.view          # View users
users.create        # Create users
users.update        # Update users
users.delete        # Delete users
users.*            # All user operations

servers.manage      # Manage servers
billing.view        # View billing
reports.generate    # Generate reports
```

### Permission Categories

#### User Management Permissions

```php
'users' => [
    'users.view',
    'users.create',
    'users.update',
    'users.delete',
    'users.suspend',
    'users.activate',
    'users.impersonate'
]
```

#### Server Management Permissions

```php
'servers' => [
    'servers.view',
    'servers.create',
    'servers.update',
    'servers.delete',
    'servers.manage',
    'accounts.view',
    'accounts.create',
    'accounts.modify',
    'accounts.suspend',
    'accounts.terminate'
]
```

#### Billing Permissions

```php
'billing' => [
    'billing.view',
    'billing.manage',
    'invoices.view',
    'invoices.create',
    'invoices.update',
    'invoices.delete',
    'payments.view',
    'payments.process',
    'payments.refund',
    'subscriptions.view',
    'subscriptions.manage'
]
```

#### System Permissions

```php
'system' => [
    'settings.view',
    'settings.update',
    'logs.view',
    'logs.export',
    'reports.view',
    'reports.generate',
    'api.manage',
    'backups.view',
    'backups.create',
    'backups.restore'
]
```

### Direct Permission Assignment

Assign permissions directly to users:

```bash
# Grant permission
php artisan user:grant-permission user@example.com reports.generate

# Revoke permission
php artisan user:revoke-permission user@example.com reports.generate

# List user permissions
php artisan user:permissions user@example.com
```

### Permission Checking

In code:

```php
// Check single permission
if ($user->can('users.create')) {
    // Allow action
}

// Check multiple permissions (all required)
if ($user->hasAllPermissions(['users.view', 'users.update'])) {
    // Allow action
}

// Check multiple permissions (any required)
if ($user->hasAnyPermission(['billing.view', 'billing.manage'])) {
    // Allow action
}

// Check wildcard permission
if ($user->can('servers.*')) {
    // Allow all server operations
}
```

In Blade templates:

```blade
@can('users.create')
    <button>Create User</button>
@endcan

@canany(['billing.view', 'billing.manage'])
    <a href="/billing">Billing</a>
@endcanany
```

In routes:

```php
Route::middleware(['can:users.create'])->group(function () {
    Route::post('/users', [UserController::class, 'store']);
});
```

### Permission Policies

Define complex permission logic:

```php
// app/Policies/UserPolicy.php
class UserPolicy
{
    public function update(User $currentUser, User $targetUser)
    {
        // Super admin can update anyone
        if ($currentUser->hasRole('super-admin')) {
            return true;
        }

        // Admins can update non-super-admins
        if ($currentUser->hasRole('administrator')) {
            return !$targetUser->hasRole('super-admin');
        }

        // Users can update themselves
        return $currentUser->id === $targetUser->id;
    }

    public function delete(User $currentUser, User $targetUser)
    {
        // Cannot delete yourself
        if ($currentUser->id === $targetUser->id) {
            return false;
        }

        // Cannot delete super admin
        if ($targetUser->hasRole('super-admin')) {
            return false;
        }

        return $currentUser->hasPermission('users.delete');
    }
}
```

## User Creation and Onboarding

### Creating Users

#### Manual User Creation

**Via Admin Panel:**

1. Navigate to **Users > Create New User**
2. Fill in user details:

```yaml
User Information:
  First Name: John
  Last Name: Doe
  Email: john.doe@example.com
  Username: johndoe (optional)
  Phone: +1-555-0100

Account Settings:
  Password: [Auto-generate or Manual]
  Require Password Change: Yes
  Account Status: Active
  Email Verified: Yes

Role Assignment:
  Primary Role: Support
  Additional Roles: [optional]

Permissions:
  Custom Permissions: [optional overrides]

Notifications:
  Welcome Email: Yes
  Setup Instructions: Yes
  Account Details: Yes
```

3. Click **Create User**

#### Via Command Line

```bash
php artisan user:create \
  --name="John Doe" \
  --email=john.doe@example.com \
  --role=support \
  --send-welcome-email \
  --require-password-change
```

#### Via API

```bash
curl -X POST https://admin.soporteclientes.net/api/v1/admin/users \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john.doe@example.com",
    "password": "TempPassword123!",
    "role": "support",
    "permissions": [],
    "require_password_change": true,
    "send_welcome_email": true,
    "metadata": {
      "department": "Technical Support",
      "manager": "manager@example.com"
    }
  }'
```

### User Onboarding Workflow

Automated onboarding process:

```yaml
Onboarding Steps:
  1. Account Creation:
     - User record created
     - Password generated/set
     - Role assigned
     - Permissions configured

  2. Email Notifications:
     - Welcome email sent
     - Account credentials provided
     - Setup instructions included
     - Support contact information

  3. First Login:
     - Password change required (if enabled)
     - 2FA setup (if required)
     - Profile completion
     - Terms acceptance

  4. Training & Documentation:
     - Tutorial walkthrough
     - Video guides
     - Documentation links
     - Support resources

  5. Follow-up:
     - Day 3: Check-in email
     - Day 7: Feedback request
     - Day 30: Usage review
```

Configure onboarding:

```php
// config/onboarding.php
'onboarding' => [
    'welcome_email' => true,
    'require_password_change' => true,
    'require_2fa_setup' => ['administrator', 'billing'],
    'require_profile_completion' => true,
    'show_tutorial' => true,
    'follow_up_schedule' => [3, 7, 30], // days
    'assign_mentor' => true
]
```

### Bulk User Creation

Import multiple users:

```bash
# From CSV file
php artisan user:import users.csv \
  --role=support \
  --send-emails

# From JSON file
php artisan user:import users.json --format=json
```

**CSV Format:**

```csv
name,email,role,department
John Doe,john@example.com,support,Technical
Jane Smith,jane@example.com,billing,Finance
Bob Wilson,bob@example.com,manager,Operations
```

**JSON Format:**

```json
[
  {
    "name": "John Doe",
    "email": "john@example.com",
    "role": "support",
    "permissions": ["tickets.view", "tickets.update"],
    "metadata": {
      "department": "Technical Support"
    }
  }
]
```

## User Authentication

### Authentication Methods

Supported authentication methods:

1. **Email/Password**: Standard authentication
2. **Username/Password**: Alternative login
3. **API Tokens**: Programmatic access
4. **OAuth**: Third-party authentication
5. **SAML SSO**: Enterprise single sign-on
6. **LDAP/Active Directory**: Directory integration

### Password Requirements

Configure password policy:

```php
// config/auth.php
'password_requirements' => [
    'min_length' => 12,
    'require_uppercase' => true,
    'require_lowercase' => true,
    'require_numbers' => true,
    'require_special_chars' => true,
    'prevent_common_passwords' => true,
    'password_history' => 5,
    'max_age_days' => 90,
    'expiry_warning_days' => 14
]
```

### Password Management

```bash
# Force password reset
php artisan user:force-password-reset user@example.com

# Send password reset link
php artisan user:send-password-reset user@example.com

# Check password strength
php artisan user:check-password-strength user@example.com

# Expire passwords
php artisan user:expire-old-passwords --days=90
```

### Single Sign-On (SSO)

#### SAML Configuration

```php
// config/saml2.php
'saml2_settings' => [
    'sp' => [
        'entityId' => 'https://admin.soporteclientes.net',
        'assertionConsumerService' => [
            'url' => 'https://admin.soporteclientes.net/saml2/acs',
        ],
    ],
    'idp' => [
        'entityId' => 'https://idp.example.com',
        'singleSignOnService' => [
            'url' => 'https://idp.example.com/sso',
        ],
        'x509cert' => 'CERTIFICATE_HERE',
    ],
]
```

#### OAuth Integration

Configure OAuth providers:

```env
# Google OAuth
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret
GOOGLE_REDIRECT_URI=https://admin.soporteclientes.net/auth/google/callback

# GitHub OAuth
GITHUB_CLIENT_ID=your_client_id
GITHUB_CLIENT_SECRET=your_client_secret
```

## Multi-Factor Authentication

### MFA Setup

Enable MFA for users:

```bash
# Enable for specific user
php artisan user:enable-mfa user@example.com

# Require MFA for role
php artisan role:require-mfa administrator

# Force MFA for all users
php artisan user:force-mfa-all
```

### MFA Methods

#### TOTP (Time-Based One-Time Password)

Using authenticator apps like Google Authenticator, Authy:

```php
// Generate QR code for setup
public function setupTOTP(User $user)
{
    $secret = Google2FA::generateSecretKey();
    $user->two_factor_secret = encrypt($secret);
    $user->save();

    $qrCodeUrl = Google2FA::getQRCodeUrl(
        config('app.name'),
        $user->email,
        $secret
    );

    return response()->json([
        'secret' => $secret,
        'qr_code' => $qrCodeUrl
    ]);
}
```

#### SMS-Based MFA

Send verification codes via SMS:

```php
// config/auth.php
'mfa' => [
    'methods' => ['totp', 'sms', 'email'],
    'default' => 'totp',
    'sms' => [
        'driver' => 'twilio',
        'from' => '+15555551234',
        'code_length' => 6,
        'expiry_minutes' => 5
    ]
]
```

#### Email-Based MFA

Send verification codes via email:

```bash
# Configure email MFA
php artisan mfa:configure-email \
  --code-length=6 \
  --expiry=10
```

### Backup Codes

Generate backup codes:

```bash
# Generate backup codes for user
php artisan mfa:generate-backup-codes user@example.com

# Regenerate backup codes
php artisan mfa:regenerate-backup-codes user@example.com \
  --count=8
```

### MFA Recovery

Reset MFA when user loses access:

```bash
# Disable MFA temporarily
php artisan mfa:disable user@example.com \
  --reason="Lost device" \
  --notify-user

# Generate emergency access code
php artisan mfa:emergency-access user@example.com \
  --expires=24h
```

## Session Management

### Session Configuration

```php
// config/session.php
'session' => [
    'lifetime' => 120, // minutes
    'expire_on_close' => false,
    'secure' => true,
    'http_only' => true,
    'same_site' => 'lax',
    'max_concurrent_sessions' => 3,
    'destroy_on_password_change' => true
]
```

### Concurrent Sessions

Manage multiple sessions:

```bash
# List user sessions
php artisan session:list user@example.com

# Terminate specific session
php artisan session:terminate SESSION_ID

# Terminate all user sessions
php artisan session:terminate-all user@example.com

# Terminate all sessions except current
php artisan session:terminate-others user@example.com
```

### Session Security

```bash
# Force logout all users
php artisan session:flush-all

# Force logout specific role
php artisan session:flush-role administrator

# Session activity report
php artisan session:activity-report \
  --days=30 \
  --output=sessions.pdf
```

## User Groups and Teams

### Creating Groups

Organize users into groups:

```bash
# Create group
php artisan group:create \
  --name="Technical Support Team" \
  --description="Level 2 technical support" \
  --manager=manager@example.com

# Add users to group
php artisan group:add-user tech-support user1@example.com
php artisan group:add-user tech-support user2@example.com

# Remove user from group
php artisan group:remove-user tech-support user1@example.com
```

### Group Permissions

Assign permissions to groups:

```bash
# Grant permission to group
php artisan group:grant-permission tech-support tickets.escalate

# View group permissions
php artisan group:permissions tech-support
```

### Team Collaboration

Enable team features:

```yaml
Team Features:
  - Shared ticket queue
  - Team calendar
  - Internal messaging
  - Knowledge sharing
  - Performance metrics
  - Team reports
```

## Customer Management

### Customer Accounts

Customers have access to:

```yaml
Customer Portal Features:
  - Service management
  - Billing and payments
  - Support tickets
  - Domain management
  - Email accounts
  - File manager (optional)
  - Statistics and analytics
```

### Customer Creation

```bash
# Create customer account
php artisan customer:create \
  --name="Acme Corporation" \
  --email=admin@acme.com \
  --plan=professional \
  --billing-cycle=annual

# Create with hosting account
php artisan customer:create-with-hosting \
  --name="Acme Corporation" \
  --email=admin@acme.com \
  --domain=acme.com \
  --plan=professional \
  --server=1
```

### Customer Portal Access

Configure portal access:

```php
// config/portal.php
'customer_portal' => [
    'enabled' => true,
    'features' => [
        'services' => true,
        'billing' => true,
        'support' => true,
        'domains' => true,
        'emails' => true,
        'files' => false,
        'statistics' => true
    ],
    'custom_branding' => true,
    'white_label' => true
]
```

## Reseller Management

### Reseller Accounts

Create reseller accounts:

```bash
php artisan reseller:create \
  --name="Hosting Reseller Inc" \
  --email=admin@reseller.com \
  --package=reseller-pro \
  --max-accounts=100 \
  --disk-quota=500000 \
  --bandwidth=5000000
```

### Reseller Resources

Configure resource allocation:

```yaml
Reseller Resources:
  Maximum Accounts: 100
  Total Disk Quota: 500 GB
  Total Bandwidth: 5000 GB
  Allowed Packages:
    - Basic
    - Standard
    - Professional
  Overselling: Enabled (150%)
  White Label: Enabled
  Custom Pricing: Enabled
```

### Reseller Permissions

```php
$resellerPermissions = [
    'customers.create',     // Own customers only
    'customers.manage',     // Own customers only
    'customers.delete',     // Own customers only
    'packages.view',        // View available packages
    'services.create',      // For own customers
    'services.manage',      // For own customers
    'invoices.view',        // Own invoices only
    'reports.view',         // Own statistics only
    'support.submit',       // Submit tickets
];
```

### Reseller Quotas

Monitor reseller usage:

```bash
# Check reseller quotas
php artisan reseller:check-quota reseller@example.com

# View reseller usage
php artisan reseller:usage reseller@example.com

# Adjust reseller quotas
php artisan reseller:update-quota reseller@example.com \
  --max-accounts=150 \
  --disk=750000
```

## User Activity Tracking

### Activity Logging

All user actions are logged:

```php
// Automatically logged events
$loggedEvents = [
    'user.login',
    'user.logout',
    'user.failed_login',
    'user.password_changed',
    'user.email_changed',
    'user.2fa_enabled',
    'user.2fa_disabled',
    'user.created',
    'user.updated',
    'user.deleted',
    'permission.granted',
    'permission.revoked',
    'role.assigned',
    'role.removed',
];
```

### View User Activity

```bash
# View user activity
php artisan user:activity user@example.com

# Filter by action
php artisan user:activity user@example.com --action=login

# Date range
php artisan user:activity user@example.com \
  --from=2024-10-01 \
  --to=2024-10-31

# Export activity
php artisan user:export-activity user@example.com \
  --format=csv \
  --output=/tmp/activity.csv
```

### Login History

Track login attempts:

```bash
# View login history
php artisan user:login-history user@example.com

# Failed login attempts
php artisan user:failed-logins user@example.com

# Suspicious activity
php artisan user:suspicious-activity
```

### Activity Reports

Generate activity reports:

```bash
# User activity report
php artisan report:user-activity \
  --from=2024-10-01 \
  --to=2024-10-31 \
  --format=pdf

# Team activity report
php artisan report:team-activity tech-support \
  --period=monthly
```

## Account Security

### Security Features

Implement security measures:

```yaml
Account Security:
  Password Policy: Enforced
  MFA Requirement: Role-based
  Session Timeout: 120 minutes
  Concurrent Sessions: Limited to 3
  IP Whitelisting: Available
  Login Notifications: Enabled
  Suspicious Activity Detection: Enabled
  Account Lockout: After 5 failed attempts
  Lockout Duration: 15 minutes
```

### IP Whitelisting

Configure IP restrictions:

```bash
# Enable IP whitelist for user
php artisan user:enable-ip-whitelist user@example.com

# Add allowed IP
php artisan user:add-allowed-ip user@example.com 192.168.1.100

# Add IP range
php artisan user:add-allowed-ip user@example.com 192.168.1.0/24

# Remove IP
php artisan user:remove-allowed-ip user@example.com 192.168.1.100

# List allowed IPs
php artisan user:list-allowed-ips user@example.com
```

### Account Lockout

Manage account lockouts:

```bash
# Lock account
php artisan user:lock user@example.com \
  --reason="Security policy violation"

# Unlock account
php artisan user:unlock user@example.com

# Check lockout status
php artisan user:lockout-status user@example.com
```

### Security Alerts

Configure security notifications:

```php
// config/security.php
'alerts' => [
    'new_login_location' => true,
    'new_device' => true,
    'password_changed' => true,
    'email_changed' => true,
    'mfa_disabled' => true,
    'failed_login_threshold' => 3,
    'suspicious_activity' => true,
    'permission_changed' => true
]
```

## Bulk User Operations

### Bulk Updates

Update multiple users:

```bash
# Bulk role assignment
php artisan user:bulk-assign-role \
  --users=users.csv \
  --role=support

# Bulk permission grant
php artisan user:bulk-grant-permission \
  --users=users.csv \
  --permission=tickets.view

# Bulk status change
php artisan user:bulk-update-status \
  --users=users.csv \
  --status=active
```

### Bulk Password Reset

Force password reset for multiple users:

```bash
# Reset passwords for role
php artisan user:bulk-password-reset --role=support

# Reset passwords from list
php artisan user:bulk-password-reset --users=users.csv

# Reset all expired passwords
php artisan user:reset-expired-passwords
```

### Bulk Deactivation

Deactivate inactive users:

```bash
# Deactivate users inactive for 90 days
php artisan user:deactivate-inactive --days=90

# Deactivate users without MFA
php artisan user:deactivate-without-mfa --role=administrator

# Preview before deactivation
php artisan user:deactivate-inactive --days=90 --dry-run
```

## User Import and Export

### Export Users

```bash
# Export all users
php artisan user:export --output=users.csv

# Export specific role
php artisan user:export --role=support --output=support-users.csv

# Export with custom fields
php artisan user:export \
  --fields=name,email,role,created_at \
  --output=users.csv

# Export to JSON
php artisan user:export --format=json --output=users.json
```

### Import Users

```bash
# Import from CSV
php artisan user:import users.csv

# Import with role
php artisan user:import users.csv --default-role=customer

# Import with validation
php artisan user:import users.csv --validate-only

# Import and send welcome emails
php artisan user:import users.csv --send-emails
```

### Sync with External System

Synchronize users with LDAP/AD:

```bash
# Sync from LDAP
php artisan user:sync-ldap

# Sync specific OU
php artisan user:sync-ldap --ou="OU=Employees,DC=company,DC=com"

# Dry run
php artisan user:sync-ldap --dry-run
```

## Troubleshooting

### Common Issues

#### User Cannot Login

**Symptoms:** Login fails with valid credentials

**Solutions:**
```bash
# Check account status
php artisan user:status user@example.com

# Check lockout status
php artisan user:lockout-status user@example.com

# Unlock if locked
php artisan user:unlock user@example.com

# Reset password
php artisan user:send-password-reset user@example.com

# Check MFA status
php artisan mfa:status user@example.com
```

#### Permission Denied Errors

**Symptoms:** User cannot access features

**Solutions:**
```bash
# Check user permissions
php artisan user:permissions user@example.com

# Check role permissions
php artisan role:permissions ROLE_NAME

# Grant missing permission
php artisan user:grant-permission user@example.com PERMISSION

# Verify permission cache
php artisan permission:cache-reset
```

#### MFA Issues

**Symptoms:** MFA not working

**Solutions:**
```bash
# Check MFA status
php artisan mfa:status user@example.com

# Reset MFA
php artisan mfa:reset user@example.com

# Generate emergency code
php artisan mfa:emergency-access user@example.com

# Disable MFA temporarily
php artisan mfa:disable user@example.com --temporary
```

### Debug Mode

Enable user management debugging:

```env
USER_MANAGEMENT_DEBUG=true
LOG_AUTHENTICATION=true
LOG_AUTHORIZATION=true
```

## Best Practices

### User Management

1. **Principle of Least Privilege**: Grant minimum required permissions
2. **Regular Audits**: Review user access quarterly
3. **Offboarding Process**: Prompt deactivation of departed users
4. **Strong Passwords**: Enforce strong password policy
5. **MFA Enforcement**: Require MFA for privileged accounts

### Role Management

1. **Role Clarity**: Clear role definitions and documentation
2. **Regular Review**: Audit role permissions regularly
3. **Role Hierarchy**: Maintain logical role structure
4. **Minimal Roles**: Avoid role proliferation
5. **Permission Groups**: Group related permissions

### Security

1. **2FA/MFA**: Enable for all administrative accounts
2. **Session Management**: Reasonable timeout periods
3. **IP Restrictions**: Implement for sensitive roles
4. **Activity Monitoring**: Review logs regularly
5. **Password Rotation**: Enforce password changes

### Compliance

1. **Audit Trails**: Maintain complete activity logs
2. **Data Protection**: Encrypt sensitive user data
3. **Access Reviews**: Regular access certification
4. **Separation of Duties**: Prevent conflicts of interest
5. **Compliance Reporting**: Generate compliance reports

## Related Links

- [Admin Panel Guide](admin-panel.md)
- [Configuration Guide](configuration.md)
- [Security Best Practices](security.md)
- [API Documentation](../api/endpoints.md)
- [Installation Guide](installation.md)
- [Troubleshooting Guide](troubleshooting.md)

---

*Last updated: October 2024*
*Version: 2.0*
