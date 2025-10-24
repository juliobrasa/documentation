# API Overview

## Introduction

Welcome to the soporteclientes.net API documentation. This RESTful API provides comprehensive access to our customer support and hosting management platform. The API enables developers to integrate billing systems, manage WHM/cPanel accounts, handle customer subscriptions, and automate various administrative tasks.

### Base URL

All API requests should be made to:

```
https://api.soporteclientes.net/v1
```

### API Version

Current API version: **v1**

The API version is included in the base URL. When breaking changes are introduced, a new version will be released, allowing you to migrate at your own pace.

## Getting Started

### Prerequisites

Before you begin using the API, ensure you have:

1. **An active account** with soporteclientes.net
2. **API credentials** (obtainable from your dashboard)
3. **Valid license key** for production environments
4. **Whitelist your IP address** (for enhanced security)

### Quick Start Example

Here's a simple example to get you started with the API:

**cURL:**
```bash
curl -X GET "https://api.soporteclientes.net/v1/admin/system/health" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Accept: application/json"
```

**JavaScript (Node.js):**
```javascript
const axios = require('axios');

const apiClient = axios.create({
  baseURL: 'https://api.soporteclientes.net/v1',
  headers: {
    'Authorization': 'Bearer YOUR_API_TOKEN',
    'Accept': 'application/json'
  }
});

async function getSystemHealth() {
  try {
    const response = await apiClient.get('/admin/system/health');
    console.log(response.data);
  } catch (error) {
    console.error('Error:', error.response.data);
  }
}

getSystemHealth();
```

**PHP:**
```php
<?php

$apiToken = 'YOUR_API_TOKEN';
$baseUrl = 'https://api.soporteclientes.net/v1';

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/admin/system/health');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $apiToken,
    'Accept: application/json'
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($httpCode === 200) {
    $data = json_decode($response, true);
    print_r($data);
} else {
    echo "Error: HTTP $httpCode\n";
    echo $response;
}
```

## Core Concepts

### RESTful Architecture

Our API follows REST principles:

- **Resources** are accessed via standard HTTPS requests
- **HTTP methods** define actions (GET, POST, PUT, DELETE)
- **JSON format** for request/response bodies
- **Stateless authentication** using bearer tokens
- **Standard HTTP status codes** for responses

### Resource-Based URLs

URLs represent resources in a hierarchical structure:

```
/whm/accounts          # Collection of accounts
/whm/accounts/{id}     # Specific account
/whm/accounts/{id}/suspend  # Action on account
```

### HTTP Methods

| Method | Purpose | Idempotent |
|--------|---------|------------|
| GET | Retrieve resource(s) | Yes |
| POST | Create new resource | No |
| PUT | Update entire resource | Yes |
| PATCH | Partial update | No |
| DELETE | Remove resource | Yes |

## Request Format

### Headers

All requests must include these headers:

```
Authorization: Bearer YOUR_API_TOKEN
Accept: application/json
Content-Type: application/json
```

Optional headers:

```
X-Request-ID: unique-request-identifier
X-Client-Version: 1.0.0
```

### Request Body

For POST, PUT, and PATCH requests, send data as JSON:

**Example - Create WHM Account:**
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

### Query Parameters

Use query parameters for filtering, sorting, and pagination:

```
GET /whm/accounts?page=2&per_page=25&status=active&sort=-created_at
```

Common parameters:

- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 15, max: 100)
- `search` - Search term
- `sort` - Sort field (prefix with `-` for descending)
- `filter[field]` - Filter by field value

## Response Format

### Success Response

Successful requests return a 2xx status code with JSON data:

**Single Resource:**
```json
{
  "data": {
    "id": 123,
    "domain": "example.com",
    "status": "active",
    "created_at": "2025-01-15T10:30:00Z"
  }
}
```

**Collection:**
```json
{
  "data": [
    {
      "id": 123,
      "domain": "example.com",
      "status": "active"
    },
    {
      "id": 124,
      "domain": "example2.com",
      "status": "active"
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
    "first": "https://api.soporteclientes.net/v1/whm/accounts?page=1",
    "last": "https://api.soporteclientes.net/v1/whm/accounts?page=10",
    "prev": null,
    "next": "https://api.soporteclientes.net/v1/whm/accounts?page=2"
  }
}
```

### Error Response

Failed requests return appropriate HTTP status codes with error details:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": {
      "email": ["The email field is required."],
      "password": ["The password must be at least 8 characters."]
    },
    "request_id": "req_abc123xyz"
  }
}
```

## HTTP Status Codes

### Success Codes (2xx)

| Code | Meaning | Usage |
|------|---------|-------|
| 200 | OK | Request succeeded |
| 201 | Created | Resource created successfully |
| 202 | Accepted | Request accepted for processing |
| 204 | No Content | Success with no response body |

### Client Error Codes (4xx)

| Code | Meaning | Usage |
|------|---------|-------|
| 400 | Bad Request | Invalid request format |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource doesn't exist |
| 422 | Unprocessable Entity | Validation failed |
| 429 | Too Many Requests | Rate limit exceeded |

### Server Error Codes (5xx)

| Code | Meaning | Usage |
|------|---------|-------|
| 500 | Internal Server Error | Server-side error |
| 502 | Bad Gateway | Upstream server error |
| 503 | Service Unavailable | Temporary unavailability |
| 504 | Gateway Timeout | Upstream timeout |

## Rate Limiting

To ensure fair usage and system stability, all API requests are rate-limited.

### Rate Limits by User Type

| User Type | Requests per Minute | Burst Allowance |
|-----------|-------------------|-----------------|
| Public | 60 | 10 |
| Authenticated | 100 | 20 |
| Admin | 200 | 40 |
| Enterprise | 500 | 100 |

### Rate Limit Headers

Every response includes rate limit information:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642248000
```

### Handling Rate Limits

When rate limit is exceeded, you'll receive a 429 response:

```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests. Please retry after 60 seconds.",
    "retry_after": 60
  }
}
```

**Best Practice - Exponential Backoff:**

```javascript
async function apiRequestWithRetry(url, options, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch(url, options);

      if (response.status === 429) {
        const retryAfter = response.headers.get('Retry-After') || Math.pow(2, i);
        await sleep(retryAfter * 1000);
        continue;
      }

      return response;
    } catch (error) {
      if (i === maxRetries - 1) throw error;
    }
  }
}
```

## Pagination

Collections are paginated to improve performance and usability.

### Pagination Parameters

- `page` - Page number (starting from 1)
- `per_page` - Items per page (default: 15, max: 100)

### Example Request

```bash
curl "https://api.soporteclientes.net/v1/whm/accounts?page=2&per_page=25" \
  -H "Authorization: Bearer YOUR_API_TOKEN"
```

### Pagination Response

```json
{
  "data": [...],
  "meta": {
    "current_page": 2,
    "from": 26,
    "last_page": 10,
    "per_page": 25,
    "to": 50,
    "total": 237
  },
  "links": {
    "first": "https://api.soporteclientes.net/v1/whm/accounts?page=1",
    "last": "https://api.soporteclientes.net/v1/whm/accounts?page=10",
    "prev": "https://api.soporteclientes.net/v1/whm/accounts?page=1",
    "next": "https://api.soporteclientes.net/v1/whm/accounts?page=3"
  }
}
```

### Iterating Through Pages

**JavaScript:**
```javascript
async function fetchAllAccounts() {
  let allAccounts = [];
  let currentPage = 1;
  let hasMore = true;

  while (hasMore) {
    const response = await apiClient.get('/whm/accounts', {
      params: { page: currentPage, per_page: 100 }
    });

    allAccounts = allAccounts.concat(response.data.data);

    hasMore = response.data.meta.current_page < response.data.meta.last_page;
    currentPage++;
  }

  return allAccounts;
}
```

**PHP:**
```php
<?php

function fetchAllAccounts($apiToken) {
    $allAccounts = [];
    $currentPage = 1;
    $hasMore = true;

    while ($hasMore) {
        $url = "https://api.soporteclientes.net/v1/whm/accounts?page={$currentPage}&per_page=100";

        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            "Authorization: Bearer {$apiToken}",
            "Accept: application/json"
        ]);

        $response = json_decode(curl_exec($ch), true);
        curl_close($ch);

        $allAccounts = array_merge($allAccounts, $response['data']);

        $hasMore = $response['meta']['current_page'] < $response['meta']['last_page'];
        $currentPage++;
    }

    return $allAccounts;
}
```

## Filtering and Sorting

### Filtering

Use the `filter` parameter to narrow down results:

```
GET /whm/accounts?filter[status]=active&filter[server_id]=5
```

**Complex Filtering:**
```
GET /billing/invoices?filter[status]=pending&filter[amount][gte]=100&filter[created_at][between]=2025-01-01,2025-01-31
```

Supported operators:
- `eq` - Equals (default)
- `ne` - Not equals
- `gt` - Greater than
- `gte` - Greater than or equal
- `lt` - Less than
- `lte` - Less than or equal
- `like` - Contains (case-insensitive)
- `in` - In array
- `between` - Between two values

### Sorting

Use the `sort` parameter to order results:

```
GET /whm/accounts?sort=-created_at
```

Multiple sort fields:
```
GET /whm/accounts?sort=-status,created_at
```

Prefix with `-` for descending order.

## Field Selection

Request only specific fields to reduce payload size:

```
GET /whm/accounts?fields=id,domain,status,created_at
```

**Response:**
```json
{
  "data": [
    {
      "id": 123,
      "domain": "example.com",
      "status": "active",
      "created_at": "2025-01-15T10:30:00Z"
    }
  ]
}
```

## Including Related Resources

Use the `include` parameter to embed related resources:

```
GET /whm/accounts?include=server,package
```

**Response:**
```json
{
  "data": {
    "id": 123,
    "domain": "example.com",
    "server": {
      "id": 5,
      "name": "Server 1",
      "hostname": "server1.example.com"
    },
    "package": {
      "id": 2,
      "name": "Professional",
      "disk_quota": 10000
    }
  }
}
```

## Error Handling

### Error Response Structure

All errors follow a consistent format:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {},
    "request_id": "req_abc123xyz",
    "timestamp": "2025-10-23T14:30:00Z"
  }
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| VALIDATION_ERROR | 422 | Request validation failed |
| AUTHENTICATION_REQUIRED | 401 | No authentication provided |
| INVALID_TOKEN | 401 | Invalid or expired token |
| INSUFFICIENT_PERMISSIONS | 403 | User lacks required permissions |
| RESOURCE_NOT_FOUND | 404 | Requested resource doesn't exist |
| RATE_LIMIT_EXCEEDED | 429 | Too many requests |
| SERVER_ERROR | 500 | Internal server error |
| SERVICE_UNAVAILABLE | 503 | Service temporarily unavailable |

### Error Handling Best Practices

**JavaScript:**
```javascript
async function handleApiRequest(url, options) {
  try {
    const response = await fetch(url, options);
    const data = await response.json();

    if (!response.ok) {
      throw new ApiError(data.error);
    }

    return data;
  } catch (error) {
    if (error instanceof ApiError) {
      switch (error.code) {
        case 'RATE_LIMIT_EXCEEDED':
          console.log('Rate limit exceeded. Waiting...');
          await sleep(error.retry_after * 1000);
          return handleApiRequest(url, options);

        case 'AUTHENTICATION_REQUIRED':
          console.log('Refreshing token...');
          await refreshToken();
          return handleApiRequest(url, options);

        default:
          console.error('API Error:', error.message);
          throw error;
      }
    }
    throw error;
  }
}
```

**PHP:**
```php
<?php

class ApiClient {
    private $token;
    private $baseUrl = 'https://api.soporteclientes.net/v1';

    public function request($method, $endpoint, $data = null) {
        $ch = curl_init($this->baseUrl . $endpoint);

        $headers = [
            'Authorization: Bearer ' . $this->token,
            'Accept: application/json',
            'Content-Type: application/json'
        ];

        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

        if ($data) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        }

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        $result = json_decode($response, true);

        if ($httpCode >= 400) {
            $this->handleError($httpCode, $result['error']);
        }

        return $result;
    }

    private function handleError($httpCode, $error) {
        switch ($error['code']) {
            case 'RATE_LIMIT_EXCEEDED':
                sleep($error['retry_after']);
                // Retry request
                break;

            case 'INVALID_TOKEN':
                $this->refreshToken();
                // Retry request
                break;

            default:
                throw new Exception($error['message'], $httpCode);
        }
    }
}
```

## Security Best Practices

### 1. Secure Token Storage

Never expose API tokens in client-side code or version control:

```javascript
// ❌ Bad - Exposed in frontend code
const API_TOKEN = 'sk_live_abc123xyz';

// ✅ Good - Use environment variables
const API_TOKEN = process.env.API_TOKEN;
```

### 2. Use HTTPS Only

Always use HTTPS for API requests. HTTP requests will be rejected.

### 3. Validate SSL Certificates

Ensure SSL certificate validation is enabled:

```php
<?php
// ✅ Good - SSL verification enabled (default)
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);

// ❌ Bad - SSL verification disabled
// curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
```

### 4. IP Whitelisting

For enhanced security, whitelist your server IPs in the dashboard.

### 5. Rotate Tokens Regularly

Implement token rotation for long-lived applications:

```javascript
const TOKEN_ROTATION_DAYS = 90;

async function checkTokenExpiration() {
  const tokenAge = Date.now() - tokenCreatedAt;
  const maxAge = TOKEN_ROTATION_DAYS * 24 * 60 * 60 * 1000;

  if (tokenAge > maxAge) {
    await rotateApiToken();
  }
}
```

### 6. Implement Request Signing

For critical operations, implement request signing:

```javascript
const crypto = require('crypto');

function signRequest(method, path, body, secret) {
  const timestamp = Date.now();
  const payload = `${method}${path}${timestamp}${JSON.stringify(body)}`;
  const signature = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');

  return {
    timestamp,
    signature
  };
}
```

## SDKs and Libraries

### Official SDKs

- **PHP SDK**: `composer require soporteclientes/php-sdk`
- **JavaScript SDK**: `npm install @soporteclientes/js-sdk`
- **Python SDK**: `pip install soporteclientes-sdk`

### Community Libraries

Check our [GitHub organization](https://github.com/soporteclientes) for community-contributed libraries.

## Webhooks

For real-time event notifications, see our [Webhooks documentation](webhooks.md).

## Support

### Resources

- **API Reference**: [endpoints.md](endpoints.md)
- **Authentication Guide**: [authentication.md](authentication.md)
- **Webhooks Guide**: [webhooks.md](webhooks.md)
- **Changelog**: https://api.soporteclientes.net/changelog
- **Status Page**: https://status.soporteclientes.net

### Contact

- **Email**: api-support@soporteclientes.net
- **Discord**: https://discord.gg/soporteclientes
- **GitHub Issues**: https://github.com/soporteclientes/api-issues

### SLA

- **Uptime**: 99.9% guaranteed
- **Support Response Time**:
  - Critical: < 1 hour
  - High: < 4 hours
  - Normal: < 24 hours

## Changelog

Stay updated with API changes:

- Subscribe to our [changelog](https://api.soporteclientes.net/changelog)
- Join our developer newsletter
- Follow [@soporteclientes_dev](https://twitter.com/soporteclientes_dev) on Twitter

### Breaking Changes Policy

We commit to:
- **6 months notice** for breaking changes
- **Maintain old versions** for at least 12 months after deprecation
- **Provide migration guides** for all breaking changes

## Testing

### Sandbox Environment

Use our sandbox environment for testing:

```
https://api-sandbox.soporteclientes.net/v1
```

Sandbox features:
- Isolated test data
- No actual charges or account modifications
- Full API functionality
- Reset data daily at 00:00 UTC

### Test Credentials

Use these test credentials in sandbox:

```
API Token: sk_test_abc123xyz
License Key: TEST-1234-5678-9012
```

### Mock Data

The sandbox provides realistic mock data for all resources. Create, update, and delete operations work normally but don't affect production systems.

## Conclusion

You're now ready to integrate with the soporteclientes.net API. For detailed endpoint documentation, see our [API Endpoints Reference](endpoints.md).

Remember to:
- Keep your API tokens secure
- Implement proper error handling
- Respect rate limits
- Test in sandbox before production
- Monitor the changelog for updates

Happy coding!
