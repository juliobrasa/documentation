# API Architecture

Comprehensive API architecture documentation for the Hosting Management Platform.

## Overview

The platform provides a RESTful API that enables programmatic access to all system functionalities. The API follows REST principles and uses JSON for data exchange.

## API Structure

```
┌─────────────────────────────────────────────────┐
│              API Gateway / Load Balancer         │
│           (Rate Limiting, SSL, Auth)            │
└────────────────────┬────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
   ┌─────────┐  ┌─────────┐  ┌─────────┐
   │   WHM   │  │ cPanel  │  │  Admin  │
   │   API   │  │   API   │  │   API   │
   └────┬────┘  └────┬────┘  └────┬────┘
        │            │            │
        └────────────┼────────────┘
                     │
        ┌────────────┴────────────┐
        │   Shared API Services   │
        │  - Authentication       │
        │  - Validation           │
        │  - Response Formatting  │
        │  - Error Handling       │
        └─────────────────────────┘
```

## API Design Principles

### 1. RESTful Architecture

- **Resource-Based URLs**: `/api/v1/resources/{id}`
- **HTTP Methods**: GET, POST, PUT, PATCH, DELETE
- **Stateless**: Each request contains all necessary information
- **Cacheable**: Responses include cache headers

### 2. Versioning

**URL-Based Versioning:**
```
https://api.soporteclientes.net/v1/accounts
https://api.soporteclientes.net/v2/accounts
```

**Benefits:**
- Clear version identification
- Easy migration path
- Backward compatibility

### 3. JSON Format

All requests and responses use JSON:

```json
{
  "data": {},
  "meta": {},
  "links": {}
}
```

## Authentication & Authorization

### JWT Token-Based Authentication

```
┌──────────┐                ┌─────────────┐
│  Client  │   POST /login  │  API Server │
│          │───────────────>│             │
│          │                │  Validate   │
│          │<───────────────│   Return    │
│          │   JWT Token    │   Token     │
│          │                │             │
│          │  API Request   │             │
│          │  + Token       │             │
│          │───────────────>│  Verify     │
│          │                │  Token      │
│          │<───────────────│  Process    │
│          │  Response      │  Request    │
└──────────┘                └─────────────┘
```

### Token Structure

```json
{
  "sub": "user_id",
  "email": "user@example.com",
  "roles": ["admin"],
  "scopes": ["accounts:read", "accounts:write"],
  "iat": 1234567890,
  "exp": 1234571490
}
```

### Token Types

1. **Access Token**: Short-lived (15 minutes)
2. **Refresh Token**: Long-lived (30 days)
3. **API Token**: Long-lived, scoped tokens

### Authorization Scopes

```
accounts:read
accounts:write
accounts:delete
servers:read
servers:write
billing:read
billing:write
admin:all
```

## Request/Response Format

### Successful Response

```json
{
  "success": true,
  "data": {
    "id": 1,
    "domain": "example.com",
    "status": "active"
  },
  "meta": {
    "timestamp": "2025-10-23T12:00:00Z",
    "request_id": "req_abc123"
  }
}
```

### Error Response

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": {
      "email": [
        "The email field is required.",
        "The email must be a valid email address."
      ]
    }
  },
  "meta": {
    "timestamp": "2025-10-23T12:00:00Z",
    "request_id": "req_abc123"
  }
}
```

### Collection Response

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "domain": "example.com"
    },
    {
      "id": 2,
      "domain": "example2.com"
    }
  ],
  "meta": {
    "current_page": 1,
    "from": 1,
    "last_page": 10,
    "per_page": 15,
    "to": 15,
    "total": 150
  },
  "links": {
    "first": "https://api.example.com/accounts?page=1",
    "last": "https://api.example.com/accounts?page=10",
    "prev": null,
    "next": "https://api.example.com/accounts?page=2"
  }
}
```

## API Endpoints Structure

### Resource Endpoints

```
/api/v1/
├── auth/
│   ├── login              POST
│   ├── logout             POST
│   ├── refresh            POST
│   └── me                 GET
│
├── whm/
│   ├── accounts/
│   │   ├── /              GET, POST
│   │   ├── /{id}          GET, PUT, DELETE
│   │   ├── /{id}/suspend  POST
│   │   └── /{id}/unsuspend POST
│   │
│   ├── packages/
│   │   ├── /              GET, POST
│   │   └── /{id}          GET, PUT, DELETE
│   │
│   └── servers/
│       ├── /              GET, POST
│       ├── /{id}          GET, PUT, DELETE
│       ├── /{id}/status   GET
│       └── /{id}/sync     POST
│
├── billing/
│   ├── plans/             GET, POST
│   ├── subscriptions/     GET, POST
│   ├── invoices/          GET
│   ├── payments/          GET, POST
│   └── payment-methods/   GET, POST, DELETE
│
└── admin/
    ├── users/             GET, POST, PUT, DELETE
    ├── roles/             GET, POST, PUT, DELETE
    ├── system/
    │   ├── health         GET
    │   └── stats          GET
    └── audit-logs/        GET
```

## Middleware Stack

### Request Processing Flow

```
Request
  │
  ▼
┌──────────────────────┐
│ CORS Middleware      │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Rate Limiter         │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Authentication       │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Authorization        │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Validation           │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Controller           │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Response Formatter   │
└──────┬───────────────┘
       │
       ▼
    Response
```

### Middleware Components

#### 1. CORS Middleware
```php
'Access-Control-Allow-Origin' => '*'
'Access-Control-Allow-Methods' => 'GET, POST, PUT, DELETE, OPTIONS'
'Access-Control-Allow-Headers' => 'Authorization, Content-Type'
```

#### 2. Rate Limiting
```php
// Per user
RateLimiter::for('api', function (Request $request) {
    return Limit::perMinute(100)->by($request->user()?->id);
});

// Per IP
RateLimiter::for('guest', function (Request $request) {
    return Limit::perMinute(60)->by($request->ip());
});
```

#### 3. Authentication
- Validates JWT token
- Loads user context
- Checks token expiration

#### 4. Authorization
- Verifies user permissions
- Checks API scopes
- Enforces role-based access

## Pagination

### Default Pagination

```
GET /api/v1/accounts?page=2&per_page=25
```

### Cursor Pagination (for large datasets)

```
GET /api/v1/accounts?cursor=eyJpZCI6MTAwfQ
```

### Parameters
- `page`: Page number (default: 1)
- `per_page`: Items per page (default: 15, max: 100)
- `cursor`: Cursor for cursor-based pagination

## Filtering & Sorting

### Filtering

```
GET /api/v1/accounts?filter[status]=active&filter[server_id]=1
```

### Sorting

```
GET /api/v1/accounts?sort=-created_at,domain
```

Prefix with `-` for descending order.

### Searching

```
GET /api/v1/accounts?search=example.com
```

### Including Relationships

```
GET /api/v1/accounts?include=server,package
```

### Field Selection

```
GET /api/v1/accounts?fields=id,domain,status
```

## Rate Limiting

### Default Limits

| User Type | Requests per Minute | Burst |
|-----------|---------------------|-------|
| Guest     | 60                  | 10    |
| Authenticated | 100             | 20    |
| Admin     | 200                 | 40    |
| API Token | Custom              | Custom|

### Headers

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1635724800
```

### Rate Limit Exceeded Response

```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests. Please try again in 30 seconds.",
    "retry_after": 30
  }
}
```

## Error Handling

### HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200  | OK - Request successful |
| 201  | Created - Resource created |
| 204  | No Content - Successful, no response body |
| 400  | Bad Request - Invalid request |
| 401  | Unauthorized - Authentication required |
| 403  | Forbidden - Insufficient permissions |
| 404  | Not Found - Resource not found |
| 422  | Unprocessable Entity - Validation error |
| 429  | Too Many Requests - Rate limit exceeded |
| 500  | Internal Server Error - Server error |
| 503  | Service Unavailable - Maintenance mode |

### Error Codes

```
VALIDATION_ERROR
AUTHENTICATION_FAILED
AUTHORIZATION_FAILED
RESOURCE_NOT_FOUND
RATE_LIMIT_EXCEEDED
SERVER_ERROR
SERVICE_UNAVAILABLE
INSUFFICIENT_CREDITS
INVALID_API_KEY
```

## Webhooks

### Webhook Events

```
account.created
account.suspended
account.deleted
subscription.created
subscription.cancelled
invoice.paid
payment.success
payment.failed
```

### Webhook Payload

```json
{
  "event": "account.created",
  "timestamp": "2025-10-23T12:00:00Z",
  "data": {
    "id": 123,
    "domain": "example.com",
    "status": "active"
  },
  "signature": "sha256=abc123..."
}
```

### Signature Verification

```php
$payload = file_get_contents('php://input');
$signature = $_SERVER['HTTP_X_WEBHOOK_SIGNATURE'];
$expected = hash_hmac('sha256', $payload, $secret);

if (!hash_equals($expected, $signature)) {
    // Invalid signature
}
```

## Caching Strategy

### Cache Headers

```http
Cache-Control: public, max-age=300
ETag: "abc123"
Last-Modified: Wed, 23 Oct 2025 12:00:00 GMT
```

### Conditional Requests

```http
If-None-Match: "abc123"
If-Modified-Since: Wed, 23 Oct 2025 12:00:00 GMT
```

### Cache Invalidation

- Automatic on resource updates
- Manual via cache tags
- Time-based expiration

## API Versioning Strategy

### Version Lifecycle

1. **Current (v1)**: Active, maintained
2. **Deprecated**: 6-month warning period
3. **Retired**: No longer available

### Deprecation Process

1. Announce 6 months before
2. Add deprecation headers
3. Update documentation
4. Provide migration guide

### Deprecation Header

```http
Deprecated: true
Sunset: Wed, 23 Apr 2026 12:00:00 GMT
Link: <https://api.example.com/v2/docs>; rel="successor-version"
```

## SDK Support

### Official SDKs

- **PHP SDK**: `composer require hosting-platform/sdk`
- **JavaScript SDK**: `npm install @hosting-platform/sdk`
- **Python SDK**: `pip install hosting-platform-sdk`

### Example Usage (PHP)

```php
use HostingPlatform\SDK\Client;

$client = new Client('your-api-token');

// Create account
$account = $client->accounts()->create([
    'domain' => 'example.com',
    'username' => 'user123',
    'package' => 'basic',
    'server_id' => 1
]);

// List accounts
$accounts = $client->accounts()->list([
    'filter' => ['status' => 'active'],
    'per_page' => 50
]);
```

## API Testing

### Test Endpoints

```
https://api-staging.soporteclientes.net/v1
```

### Test Credentials

Provided per developer account.

### Postman Collection

Available at: `/docs/postman/collection.json`

## Performance Optimization

### Response Compression

```http
Accept-Encoding: gzip, deflate
Content-Encoding: gzip
```

### Batch Requests

```json
{
  "requests": [
    {
      "method": "GET",
      "url": "/api/v1/accounts/1"
    },
    {
      "method": "GET",
      "url": "/api/v1/servers/1"
    }
  ]
}
```

### Async Operations

For long-running operations:

```json
{
  "job_id": "job_abc123",
  "status": "pending",
  "status_url": "/api/v1/jobs/job_abc123"
}
```

## Security Best Practices

1. **Always use HTTPS**
2. **Validate JWT tokens**
3. **Implement rate limiting**
4. **Use API scopes**
5. **Log all API access**
6. **Monitor for abuse**
7. **Rotate API keys regularly**
8. **Use webhook signatures**

## Monitoring & Analytics

### Metrics Tracked

- Request count
- Response times
- Error rates
- Rate limit hits
- Popular endpoints
- User agents

### Health Check Endpoint

```
GET /api/v1/health

Response:
{
  "status": "healthy",
  "version": "1.0.0",
  "uptime": 123456,
  "services": {
    "database": "up",
    "redis": "up",
    "queue": "up"
  }
}
```

---

*For complete API reference, see [API Endpoints](../api/endpoints.md)*
