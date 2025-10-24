# cPanel Integration and Billing Guide

Complete guide to the cPanel integration system with comprehensive billing, subscription management, and automated provisioning.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Installation and Setup](#installation-and-setup)
4. [Billing System](#billing-system)
5. [Subscription Management](#subscription-management)
6. [Invoice Generation](#invoice-generation)
7. [Payment Processing](#payment-processing)
8. [Automated Provisioning](#automated-provisioning)
9. [License Management](#license-management)
10. [Client Portal](#client-portal)
11. [Automation and Workflows](#automation-and-workflows)
12. [Integration with WHM Panel](#integration-with-whm-panel)
13. [Reporting and Analytics](#reporting-and-analytics)
14. [Security and Compliance](#security-and-compliance)
15. [Troubleshooting](#troubleshooting)
16. [Best Practices](#best-practices)
17. [Related Links](#related-links)

## Overview

The cPanel Integration System is an enterprise-grade billing and automation platform designed specifically for web hosting providers. It provides complete customer lifecycle management from initial signup through billing, support, and account management.

### Key Features

- **Complete Billing System**: Recurring billing, invoicing, and payment processing
- **Multiple Payment Gateways**: Stripe, PayPal, credit cards, bank transfers
- **Subscription Management**: Flexible billing cycles and plan management
- **Automated Provisioning**: Instant account creation and setup
- **Client Portal**: Self-service customer management
- **License Validation**: Software licensing and activation
- **Tax Management**: Support for multiple tax jurisdictions
- **Multi-currency**: Process payments in different currencies
- **Email Automation**: Automated notifications and reminders
- **Affiliate System**: Built-in referral and commission tracking

### Technology Stack

- **Framework**: Laravel 9.x
- **Frontend**: Vue.js 3 + Tailwind CSS
- **Database**: MySQL 8.0+ / MariaDB 10.5+
- **Payments**: Stripe SDK, PayPal API
- **Queue**: Laravel Horizon + Redis
- **PDF Generation**: DomPDF / Snappy
- **Email**: SMTP, Amazon SES

## Architecture

### System Design

```
┌──────────────────────────────────────────────────┐
│          Client Portal (Vue.js SPA)              │
└────────────────────┬─────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────┐
│         cPanel Billing System (Laravel)          │
│  ┌──────────┬───────────┬──────────┬──────────┐ │
│  │ Billing  │  Invoices │ Payments │ Licenses │ │
│  └──────────┴───────────┴──────────┴──────────┘ │
└────────────────────┬─────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
  ┌─────────┐  ┌─────────┐  ┌──────────┐
  │ Payment │  │   WHM   │  │  Email   │
  │Gateways │  │  Panel  │  │ Service  │
  └─────────┘  └─────────┘  └──────────┘
```

### Database Schema

Main database tables:

- `customers` - Customer information
- `subscriptions` - Active subscriptions
- `plans` - Hosting plans and pricing
- `invoices` - Generated invoices
- `payments` - Payment records
- `licenses` - Software licenses
- `transactions` - Financial transactions
- `affiliates` - Referral program data
- `taxes` - Tax rates and rules

### Integration Points

- **WHM Panel**: Account provisioning
- **Payment Gateways**: Payment processing
- **Email Services**: Transactional emails
- **Support System**: Ticket integration
- **Accounting Software**: QuickBooks, Xero

## Installation and Setup

### Prerequisites

```bash
# System requirements
- PHP 8.0+
- MySQL 8.0+ or MariaDB 10.5+
- Composer 2.0+
- Node.js 14+ and NPM
- Redis server
- SSL certificate
```

### Installation Steps

```bash
# Navigate to installation directory
cd /home/cpanel1.soporteclientes.net

# Clone repository
git clone https://github.com/juliobrasa/cpanel.git .

# Install dependencies
composer install --no-dev --optimize-autoloader
npm install
npm run production

# Configure environment
cp .env.example .env
php artisan key:generate
```

### Database Configuration

Create database and configure `.env`:

```bash
# Create database
mysql -u root -p
CREATE DATABASE cpanel1db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'cpanel_user'@'localhost' IDENTIFIED BY 'secure_password';
GRANT ALL PRIVILEGES ON cpanel1db.* TO 'cpanel_user'@'localhost';
FLUSH PRIVILEGES;
exit
```

Edit `.env`:

```env
APP_NAME="cPanel Billing"
APP_ENV=production
APP_URL=https://cpanel1.soporteclientes.net

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=cpanel1db
DB_USERNAME=cpanel_user
DB_PASSWORD=secure_password

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379
```

### Run Migrations

```bash
php artisan migrate --seed
```

### Payment Gateway Setup

Configure payment gateways in `.env`:

```env
# Stripe
STRIPE_KEY=pk_live_xxxxxxxxxxxxxx
STRIPE_SECRET=sk_live_xxxxxxxxxxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxx

# PayPal
PAYPAL_MODE=live
PAYPAL_CLIENT_ID=xxxxxxxxxxxxx
PAYPAL_CLIENT_SECRET=xxxxxxxxxxxxx
PAYPAL_WEBHOOK_ID=xxxxxxxxxxxxx
```

### Queue Configuration

Setup queue workers:

```bash
# Create supervisor config
sudo nano /etc/supervisord.d/cpanel-worker.ini
```

```ini
[program:cpanel-worker]
process_name=%(program_name)s_%(process_num)02d
command=/usr/bin/php /home/cpanel1.soporteclientes.net/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=apache
numprocs=4
redirect_stderr=true
stdout_logfile=/home/cpanel1.soporteclientes.net/storage/logs/worker.log
stopwaitsecs=3600
```

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start cpanel-worker:*
```

## Billing System

### Understanding Billing Cycles

The system supports multiple billing cycles:

- **Monthly**: Billed every 30 days
- **Quarterly**: Billed every 3 months
- **Semi-annually**: Billed every 6 months
- **Annually**: Billed every 12 months
- **Biennially**: Billed every 24 months
- **Triennially**: Billed every 36 months

### Creating Billing Plans

#### Via Admin Panel

Navigate to **Billing > Plans > Create New**

```yaml
Plan Configuration:
  Name: Professional Hosting
  Slug: pro-hosting
  Description: Professional hosting with enhanced features

Pricing:
  Monthly: $29.99
  Quarterly: $79.99 (11% discount)
  Annually: $299.99 (17% discount)
  Setup Fee: $0.00

Resources:
  Disk Space: 50 GB
  Bandwidth: 500 GB
  Email Accounts: Unlimited
  Databases: 25
  Addon Domains: 10

Features:
  - Free SSL Certificate
  - Daily Backups
  - 24/7 Support
  - Control Panel Access
  - One-Click Installer
```

#### Via API

```bash
curl -X POST https://cpanel1.soporteclientes.net/api/v1/billing/plans \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Professional Hosting",
    "slug": "pro-hosting",
    "description": "Professional hosting package",
    "pricing": {
      "monthly": 29.99,
      "quarterly": 79.99,
      "annually": 299.99,
      "setup_fee": 0
    },
    "resources": {
      "disk_quota": 51200,
      "bandwidth": 512000,
      "max_emails": 0,
      "max_databases": 25,
      "max_addon_domains": 10
    },
    "features": [
      "free_ssl",
      "daily_backups",
      "24x7_support",
      "cpanel_access"
    ],
    "whm_package": "premium",
    "is_active": true
  }'
```

#### Via Command Line

```bash
php artisan billing:create-plan \
  --name="Professional Hosting" \
  --monthly=29.99 \
  --annually=299.99 \
  --disk=51200 \
  --bandwidth=512000
```

### Plan Modifications

Update existing plans:

```bash
# Update pricing
php artisan billing:update-plan pro-hosting \
  --monthly=34.99 \
  --quarterly=94.99

# Apply to existing subscriptions
php artisan billing:migrate-subscriptions pro-hosting \
  --apply-new-pricing \
  --notify-customers
```

### Promotional Pricing

Create limited-time promotions:

```php
// Create promotion
POST /api/v1/billing/promotions
{
  "code": "SUMMER2024",
  "description": "Summer Sale 2024",
  "discount_type": "percentage",
  "discount_value": 25,
  "applies_to": ["pro-hosting", "business-hosting"],
  "max_uses": 100,
  "valid_from": "2024-06-01",
  "valid_until": "2024-08-31",
  "first_payment_only": true
}
```

## Subscription Management

### Creating Subscriptions

#### Customer Self-Service Signup

Customers can sign up through the portal:

1. Select hosting plan
2. Choose billing cycle
3. Enter domain information
4. Create account
5. Enter payment details
6. Complete purchase

#### Manual Subscription Creation

Admin creates subscription for customer:

```bash
php artisan billing:create-subscription \
  --customer=customer@example.com \
  --plan=pro-hosting \
  --cycle=monthly \
  --auto-provision
```

#### API Subscription Creation

```bash
curl -X POST https://cpanel1.soporteclientes.net/api/v1/billing/subscriptions \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "customer_id": 123,
    "plan_id": 5,
    "billing_cycle": "monthly",
    "domain": "example.com",
    "payment_method": "stripe",
    "auto_renew": true,
    "provision_immediately": true
  }'
```

### Subscription Lifecycle

#### Active Subscription

```bash
# View subscription details
php artisan billing:show-subscription 12345

# Update subscription
php artisan billing:update-subscription 12345 \
  --plan=business-hosting \
  --prorate
```

#### Upgrade/Downgrade

```php
// Upgrade subscription
POST /api/v1/billing/subscriptions/{id}/upgrade
{
  "new_plan_id": 10,
  "prorate": true,
  "immediate": true
}

// Downgrade subscription
POST /api/v1/billing/subscriptions/{id}/downgrade
{
  "new_plan_id": 3,
  "effective_date": "2024-12-01"
}
```

#### Suspension

Suspend for non-payment or policy violation:

```bash
# Suspend subscription
php artisan billing:suspend-subscription 12345 \
  --reason="Payment overdue" \
  --notify-customer

# Unsuspend
php artisan billing:unsuspend-subscription 12345
```

#### Cancellation

```bash
# Cancel at end of period
php artisan billing:cancel-subscription 12345 \
  --end-of-period \
  --refund=false

# Immediate cancellation
php artisan billing:cancel-subscription 12345 \
  --immediate \
  --refund=prorated
```

### Renewal Management

Configure automatic renewal:

```php
// config/billing.php
'renewal' => [
    'auto_renew_default' => true,
    'grace_period_days' => 7,
    'reminder_days' => [30, 14, 7, 3, 1],
    'retry_failed_payments' => true,
    'retry_attempts' => 3,
    'retry_interval_hours' => 24
]
```

### Trial Periods

Offer trial subscriptions:

```php
POST /api/v1/billing/subscriptions
{
  "customer_id": 123,
  "plan_id": 5,
  "trial_days": 14,
  "trial_requires_payment_method": true,
  "auto_convert_after_trial": true
}
```

## Invoice Generation

### Automatic Invoice Generation

Invoices are automatically generated based on:

- Subscription renewal dates
- One-time purchases
- Upgrades/downgrades with proration
- Additional services

### Invoice Structure

```json
{
  "invoice_number": "INV-2024-001234",
  "customer_id": 123,
  "issue_date": "2024-10-01",
  "due_date": "2024-10-15",
  "status": "pending",
  "subtotal": 29.99,
  "tax": 5.40,
  "total": 35.39,
  "currency": "USD",
  "line_items": [
    {
      "description": "Professional Hosting - Monthly",
      "quantity": 1,
      "unit_price": 29.99,
      "amount": 29.99,
      "period_start": "2024-11-01",
      "period_end": "2024-11-30"
    }
  ],
  "tax_items": [
    {
      "name": "VAT (18%)",
      "rate": 18.0,
      "amount": 5.40
    }
  ]
}
```

### Manual Invoice Creation

Create ad-hoc invoices:

```bash
php artisan billing:create-invoice \
  --customer=123 \
  --description="Domain Registration - example.com" \
  --amount=12.99 \
  --due-date="+7 days"
```

### Invoice Templates

Customize invoice appearance:

```bash
# Edit invoice template
resources/views/invoices/template.blade.php

# Generate preview
php artisan billing:preview-invoice 12345 --pdf
```

### Invoice Delivery

```php
// config/billing.php
'invoices' => [
    'auto_send' => true,
    'send_methods' => ['email', 'portal'],
    'attach_pdf' => true,
    'cc_admin' => false,
    'reminder_schedule' => [
        'before_due' => [7, 3, 1],
        'after_due' => [1, 3, 7, 14]
    ]
]
```

### Bulk Invoice Generation

Generate invoices for multiple subscriptions:

```bash
# Generate all due invoices
php artisan billing:generate-invoices --due-today

# Preview before generation
php artisan billing:generate-invoices --preview --due-within=7
```

## Payment Processing

### Supported Payment Methods

1. **Credit/Debit Cards** (via Stripe)
2. **PayPal**
3. **Bank Transfer**
4. **Cryptocurrency** (optional)
5. **Check/Money Order**

### Stripe Integration

#### Setup

```bash
# Install Stripe SDK
composer require stripe/stripe-php

# Configure webhooks
php artisan billing:setup-stripe-webhooks
```

#### Process Payment

```php
// Charge card
POST /api/v1/billing/payments
{
  "invoice_id": 12345,
  "payment_method": "stripe",
  "token": "tok_visa",
  "save_card": true
}
```

#### Saved Payment Methods

```bash
# List customer payment methods
GET /api/v1/billing/payment-methods?customer_id=123

# Set default payment method
POST /api/v1/billing/payment-methods/{id}/set-default

# Remove payment method
DELETE /api/v1/billing/payment-methods/{id}
```

### PayPal Integration

#### Configuration

```env
PAYPAL_MODE=live
PAYPAL_CLIENT_ID=your_client_id
PAYPAL_CLIENT_SECRET=your_client_secret
PAYPAL_WEBHOOK_ID=your_webhook_id
```

#### Process PayPal Payment

```php
POST /api/v1/billing/payments/paypal
{
  "invoice_id": 12345,
  "return_url": "https://cpanel1.example.com/payment/success",
  "cancel_url": "https://cpanel1.example.com/payment/cancel"
}
```

### Payment Reconciliation

Match payments to invoices:

```bash
# Auto-reconcile payments
php artisan billing:reconcile-payments

# Manual reconciliation
php artisan billing:match-payment \
  --payment-id=67890 \
  --invoice-id=12345
```

### Refunds

Process refunds:

```bash
# Full refund
php artisan billing:refund-payment 67890 \
  --reason="Customer request"

# Partial refund
php artisan billing:refund-payment 67890 \
  --amount=15.00 \
  --reason="Service credit"
```

### Failed Payment Handling

```php
// config/billing.php
'failed_payments' => [
    'retry_enabled' => true,
    'max_retries' => 3,
    'retry_schedule' => [1, 3, 7], // days
    'suspend_after_retries' => true,
    'grace_period_days' => 7,
    'notify_customer' => true,
    'notify_admin' => true
]
```

## Automated Provisioning

### Provisioning Workflow

```
Order Placed → Payment Verified → Account Created → Email Sent → Account Activated
```

### Instant Provisioning

Configure for immediate account creation:

```php
// config/provisioning.php
'instant_provision' => [
    'enabled' => true,
    'payment_methods' => ['stripe', 'paypal'],
    'require_payment_confirmation' => true,
    'verification_required' => false
]
```

### Provisioning Queue

Monitor provisioning jobs:

```bash
# View provisioning queue
php artisan billing:provisioning-queue

# Retry failed provisioning
php artisan billing:retry-provisioning 12345

# Manual provisioning
php artisan billing:provision-subscription 12345
```

### Account Setup Script

Customize post-provisioning setup:

```php
// app/Services/ProvisioningService.php
public function postProvision($account)
{
    // Install WordPress
    $this->installWordPress($account);

    // Setup email accounts
    $this->createEmailAccounts($account);

    // Install SSL certificate
    $this->installSSL($account);

    // Send welcome email
    $this->sendWelcomeEmail($account);
}
```

### Provisioning Templates

Create templates for different scenarios:

```yaml
# templates/wordpress-hosting.yml
provision_steps:
  - create_cpanel_account
  - install_wordpress
  - create_database
  - setup_ssl
  - configure_email
  - send_welcome_email

wordpress_config:
  version: latest
  theme: default
  plugins:
    - wordfence
    - wp-super-cache
```

## License Management

### License System

Manage software licenses and activations:

```bash
# Generate license
php artisan license:generate \
  --customer=123 \
  --product=whm-panel \
  --expires="+365 days"

# Validate license
php artisan license:validate LICENSE-KEY-HERE
```

### License API

```php
// Validate license
POST /api/v1/installer/validate
{
  "license_key": "XXXX-XXXX-XXXX-XXXX",
  "domain": "example.com",
  "ip_address": "192.168.1.100"
}

// Response
{
  "valid": true,
  "license_type": "professional",
  "expires_at": "2025-10-23",
  "max_activations": 1,
  "current_activations": 1,
  "features": ["whm", "billing", "support"]
}
```

### License Tracking

Monitor license usage:

```bash
# List all licenses
php artisan license:list

# Show license details
php artisan license:show LICENSE-KEY

# Deactivate installation
php artisan license:deactivate LICENSE-KEY \
  --domain=example.com
```

## Client Portal

### Customer Access

Customers access the portal to:

- View services and subscriptions
- Manage billing and payments
- Download invoices
- Update account information
- Submit support tickets
- Access knowledge base

### Portal Configuration

```php
// config/portal.php
'features' => [
    'service_management' => true,
    'billing_history' => true,
    'payment_methods' => true,
    'invoice_download' => true,
    'support_tickets' => true,
    'domain_management' => true,
    'email_accounts' => true,
    'file_manager' => false
]
```

### Custom Branding

Customize portal appearance:

```bash
# Logo and colors
resources/views/portal/layout.blade.php

# Custom CSS
public/css/portal-custom.css
```

### Single Sign-On (SSO)

Integrate SSO for seamless access:

```php
// Enable SSO to cPanel
public function ssoToCPanel(Request $request)
{
    $account = $request->user()->hosting_account;
    $token = $this->whmApi->createUserSession($account->username);

    return redirect()->away(
        "https://{$account->server->hostname}:2083/cpsess{$token}"
    );
}
```

## Automation and Workflows

### Automated Tasks

Schedule routine tasks:

```php
// app/Console/Kernel.php
protected function schedule(Schedule $schedule)
{
    // Generate invoices daily
    $schedule->command('billing:generate-invoices')
             ->dailyAt('00:00');

    // Process renewals
    $schedule->command('billing:process-renewals')
             ->dailyAt('01:00');

    // Send payment reminders
    $schedule->command('billing:send-reminders')
             ->dailyAt('09:00');

    // Suspend overdue accounts
    $schedule->command('billing:suspend-overdue')
             ->dailyAt('02:00');

    // Clean up old data
    $schedule->command('billing:cleanup')
             ->weekly();
}
```

### Custom Workflows

Define custom automation workflows:

```yaml
# workflows/new-customer.yml
workflow: new_customer_onboarding
trigger: subscription.created
steps:
  - send_welcome_email
  - create_support_ticket
  - schedule_followup:
      days: 3
      type: "How are you doing?"
  - add_to_newsletter
  - notify_sales_team
```

### Email Automation

```php
// config/mail-automation.php
'templates' => [
    'welcome' => [
        'trigger' => 'account.created',
        'delay' => 0,
        'subject' => 'Welcome to {company}',
        'template' => 'emails.welcome'
    ],
    'payment_received' => [
        'trigger' => 'payment.received',
        'delay' => 0,
        'subject' => 'Payment Received - Invoice #{invoice_number}'
    ],
    'renewal_reminder' => [
        'trigger' => 'subscription.renewal_due',
        'delay' => '-7 days',
        'subject' => 'Your subscription will renew soon'
    ]
]
```

## Integration with WHM Panel

### Account Synchronization

Keep cPanel accounts in sync with billing:

```bash
# Sync all accounts
php artisan billing:sync-with-whm

# Sync specific customer
php artisan billing:sync-customer 123
```

### Suspension Integration

Automatically suspend accounts for non-payment:

```php
// When payment fails
public function handleFailedPayment($subscription)
{
    // Suspend in billing system
    $subscription->suspend();

    // Suspend WHM account
    $this->whmApi->suspendAccount(
        $subscription->hosting_account->username,
        'Payment overdue'
    );

    // Notify customer
    $this->sendSuspensionNotice($subscription);
}
```

### Resource Limit Enforcement

Sync package limits:

```bash
# Update WHM account limits
php artisan billing:sync-limits 12345
```

## Reporting and Analytics

### Financial Reports

Generate financial reports:

```bash
# Revenue report
php artisan billing:report revenue \
  --from=2024-01-01 \
  --to=2024-12-31 \
  --format=pdf

# Outstanding invoices
php artisan billing:report outstanding

# Payment methods breakdown
php artisan billing:report payment-methods
```

### Customer Analytics

```bash
# Customer lifetime value
php artisan billing:analyze ltv

# Churn rate
php artisan billing:analyze churn --period=monthly

# Growth metrics
php artisan billing:analyze growth
```

### Export Data

```bash
# Export to CSV
php artisan billing:export invoices \
  --from=2024-01-01 \
  --to=2024-12-31 \
  --output=/tmp/invoices.csv

# Export for accounting
php artisan billing:export accounting \
  --format=quickbooks \
  --year=2024
```

## Security and Compliance

### PCI Compliance

The system is designed for PCI compliance:

- No card data stored locally
- All payment processing through PCI-compliant gateways
- SSL/TLS encryption
- Secure token handling

### Data Protection

```php
// config/security.php
'data_protection' => [
    'encrypt_customer_data' => true,
    'mask_payment_methods' => true,
    'secure_invoice_access' => true,
    'audit_logging' => true
]
```

### GDPR Compliance

```bash
# Export customer data
php artisan billing:export-customer-data customer@example.com

# Delete customer data
php artisan billing:delete-customer-data customer@example.com \
  --anonymize
```

### Security Best Practices

1. **Use HTTPS** for all communications
2. **Enable 2FA** for admin accounts
3. **Regular backups** of billing database
4. **Audit logs** for all financial transactions
5. **IP whitelisting** for API access
6. **Rate limiting** on payment endpoints

## Troubleshooting

### Common Issues

#### Payment Not Processing

**Symptoms:** Payment stuck in pending status

**Solutions:**
```bash
# Check payment gateway status
php artisan billing:check-gateway-status stripe

# Review logs
tail -f storage/logs/payments.log

# Retry payment
php artisan billing:retry-payment 12345

# Check webhook configuration
php artisan billing:test-webhooks
```

#### Invoice Not Generated

**Symptoms:** Missing invoice for subscription

**Solutions:**
```bash
# Check subscription status
php artisan billing:show-subscription 12345

# Manually generate invoice
php artisan billing:generate-invoice --subscription=12345

# Check scheduler
php artisan schedule:list
```

#### Provisioning Failed

**Symptoms:** Account not created after payment

**Solutions:**
```bash
# Check provisioning queue
php artisan billing:provisioning-queue

# View error logs
tail -f storage/logs/provisioning.log

# Manual provision
php artisan billing:provision-subscription 12345 --force

# Check WHM connectivity
php artisan whm:test-connection
```

#### Webhook Not Received

**Symptoms:** Payment events not updating

**Solutions:**
```bash
# Verify webhook URL
php artisan billing:show-webhook-url

# Test webhook
php artisan billing:test-webhook stripe

# Check webhook logs
php artisan billing:webhook-logs --provider=stripe

# Re-register webhook
php artisan billing:register-webhooks --force
```

### Debug Mode

Enable detailed logging:

```env
BILLING_DEBUG=true
LOG_LEVEL=debug
LOG_CHANNEL=daily
```

### Error Codes

| Code | Description | Resolution |
|------|-------------|------------|
| BILL-001 | Payment gateway error | Check gateway credentials |
| BILL-002 | Insufficient funds | Retry with different method |
| BILL-003 | Invalid card | Update payment method |
| BILL-004 | Subscription not found | Verify subscription ID |
| BILL-005 | Provisioning failed | Check WHM connection |
| BILL-006 | Invoice generation failed | Check database integrity |

## Best Practices

### Billing Configuration

1. **Clear Terms**: Display pricing and terms clearly
2. **Grace Periods**: Allow reasonable grace periods
3. **Payment Reminders**: Send timely reminders
4. **Multiple Payment Methods**: Offer variety of payment options

### Subscription Management

1. **Proration**: Handle upgrades/downgrades fairly
2. **Trial Periods**: Use trials to reduce churn
3. **Auto-Renewal**: Default to auto-renewal with opt-out
4. **Cancellation Process**: Make it easy but collect feedback

### Financial Management

1. **Regular Reconciliation**: Daily payment reconciliation
2. **Backup Payment Methods**: Encourage backup payment methods
3. **Tax Compliance**: Keep tax rates updated
4. **Audit Trail**: Maintain complete financial audit trail

### Customer Communication

1. **Transactional Emails**: Send clear, timely emails
2. **Invoice Clarity**: Include all details in invoices
3. **Payment Confirmations**: Immediate confirmation emails
4. **Support Access**: Easy access to billing support

### Performance

1. **Queue Jobs**: Use queues for heavy operations
2. **Cache Reports**: Cache frequently accessed reports
3. **Database Indexes**: Optimize billing queries
4. **Archive Old Data**: Archive old invoices/payments

## Related Links

- [Installation Guide](installation.md)
- [WHM Panel Guide](whm-panel.md)
- [Admin Panel Guide](admin-panel.md)
- [User Management](user-management.md)
- [Configuration Guide](configuration.md)
- [API Documentation](../api/endpoints.md)
- [Security Best Practices](security.md)
- [Stripe Documentation](https://stripe.com/docs)
- [PayPal API Reference](https://developer.paypal.com/docs/api/)

---

*Last updated: October 2024*
*Version: 2.0*
