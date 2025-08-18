# API Endpoints Reference

Base URL: `https://api.soporteclientes.net/v1`

## Authentication

### POST /auth/login
Login to the system

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password"
}
```

**Response:**
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "user@example.com"
  }
}
```

### POST /auth/logout
Logout and invalidate token

### POST /auth/refresh
Refresh authentication token

## WHM Management

### Accounts

#### GET /whm/accounts
List all WHM accounts

**Parameters:**
- `page` (int): Page number
- `per_page` (int): Items per page
- `search` (string): Search term
- `status` (string): active|suspended|terminated

#### POST /whm/accounts
Create new WHM account

**Request:**
```json
{
  "domain": "example.com",
  "username": "user123",
  "password": "SecurePass123!",
  "email": "user@example.com",
  "package": "basic",
  "server_id": 1
}
```

#### GET /whm/accounts/{id}
Get account details

#### PUT /whm/accounts/{id}
Update account

#### DELETE /whm/accounts/{id}
Terminate account

#### POST /whm/accounts/{id}/suspend
Suspend account

#### POST /whm/accounts/{id}/unsuspend
Unsuspend account

### Packages

#### GET /whm/packages
List all packages

#### POST /whm/packages
Create package

**Request:**
```json
{
  "name": "Premium",
  "disk_quota": 10000,
  "bandwidth": 100000,
  "max_emails": 100,
  "max_databases": 10,
  "max_domains": 5
}
```

#### PUT /whm/packages/{id}
Update package

#### DELETE /whm/packages/{id}
Delete package

### Servers

#### GET /whm/servers
List all servers

#### POST /whm/servers
Add new server

**Request:**
```json
{
  "name": "Server 1",
  "hostname": "server1.example.com",
  "ip_address": "192.168.1.100",
  "username": "root",
  "api_token": "token_here",
  "port": 2087
}
```

#### GET /whm/servers/{id}/status
Get server status

#### POST /whm/servers/{id}/sync
Sync server data

## Billing System

### Plans

#### GET /billing/plans
List all billing plans

#### POST /billing/plans
Create billing plan

**Request:**
```json
{
  "name": "Professional",
  "price_monthly": 29.99,
  "price_yearly": 299.99,
  "features": {
    "storage": "50GB",
    "bandwidth": "500GB",
    "emails": "unlimited"
  }
}
```

### Subscriptions

#### GET /billing/subscriptions
List subscriptions

#### POST /billing/subscriptions
Create subscription

**Request:**
```json
{
  "user_id": 1,
  "plan_id": 2,
  "billing_cycle": "monthly",
  "payment_method": "stripe"
}
```

#### GET /billing/subscriptions/{id}
Get subscription details

#### POST /billing/subscriptions/{id}/cancel
Cancel subscription

#### POST /billing/subscriptions/{id}/resume
Resume subscription

### Invoices

#### GET /billing/invoices
List invoices

**Parameters:**
- `status`: pending|paid|overdue|cancelled
- `from_date`: YYYY-MM-DD
- `to_date`: YYYY-MM-DD

#### GET /billing/invoices/{id}
Get invoice details

#### POST /billing/invoices/{id}/pay
Process payment

**Request:**
```json
{
  "payment_method": "stripe",
  "token": "tok_visa"
}
```

#### GET /billing/invoices/{id}/download
Download invoice PDF

### Payments

#### GET /billing/payment-methods
List payment methods

#### POST /billing/payment-methods
Add payment method

**Request:**
```json
{
  "type": "card",
  "token": "tok_visa",
  "is_default": true
}
```

#### DELETE /billing/payment-methods/{id}
Remove payment method

## Admin Functions

### Users

#### GET /admin/users
List all users

#### POST /admin/users
Create user

**Request:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "SecurePass123!",
  "role": "admin",
  "permissions": ["users.view", "users.create"]
}
```

#### PUT /admin/users/{id}
Update user

#### DELETE /admin/users/{id}
Delete user

#### POST /admin/users/{id}/reset-password
Send password reset email

### System

#### GET /admin/system/health
System health check

**Response:**
```json
{
  "status": "healthy",
  "services": {
    "database": "up",
    "redis": "up",
    "queue": "up"
  },
  "metrics": {
    "cpu_usage": 45.2,
    "memory_usage": 67.8,
    "disk_usage": 23.4
  }
}
```

#### GET /admin/system/stats
System statistics

#### GET /admin/audit-logs
View audit logs

**Parameters:**
- `user_id`: Filter by user
- `action`: Filter by action type
- `from_date`: Start date
- `to_date`: End date

### Reports

#### GET /admin/reports/usage
Usage report

#### GET /admin/reports/revenue
Revenue report

#### GET /admin/reports/growth
Growth metrics

## Installer API

### Licenses

#### POST /installer/validate
Validate license

**Request:**
```json
{
  "license_key": "XXXX-XXXX-XXXX-XXXX",
  "domain": "example.com",
  "ip_address": "192.168.1.100"
}
```

#### POST /installer/activate
Activate installation

#### GET /installer/check-updates
Check for updates

## Webhooks

### POST /webhooks/payment
Payment webhook endpoint

### POST /webhooks/account
Account status webhook

## Rate Limiting

All API endpoints are rate limited:
- **Default**: 60 requests per minute
- **Authenticated**: 100 requests per minute
- **Admin**: 200 requests per minute

Rate limit headers:
- `X-RateLimit-Limit`: Maximum requests
- `X-RateLimit-Remaining`: Remaining requests
- `X-RateLimit-Reset`: Reset timestamp

## Error Responses

Standard error format:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": {
      "email": ["The email field is required."]
    }
  }
}
```

Common error codes:
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `422` - Validation Error
- `429` - Too Many Requests
- `500` - Internal Server Error

## Pagination

Paginated responses include:
```json
{
  "data": [...],
  "meta": {
    "current_page": 1,
    "from": 1,
    "last_page": 10,
    "per_page": 15,
    "to": 15,
    "total": 150
  },
  "links": {
    "first": "https://api.example.com/endpoint?page=1",
    "last": "https://api.example.com/endpoint?page=10",
    "prev": null,
    "next": "https://api.example.com/endpoint?page=2"
  }
}
```

## Filtering & Sorting

Most list endpoints support:
- `filter[field]`: Filter by field value
- `sort`: Sort field (prefix with `-` for descending)
- `include`: Include related resources
- `fields`: Specify fields to return

Example:
```
GET /api/accounts?filter[status]=active&sort=-created_at&include=server&fields=id,domain,status
```