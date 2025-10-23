# API Authentication

## Overview

The soporteclientes.net API uses token-based authentication to secure access to resources. All API requests must include valid authentication credentials unless explicitly noted as public endpoints.

### Authentication Methods

We support multiple authentication methods:

1. **Bearer Token Authentication** (Recommended)
2. **API Key Authentication**
3. **OAuth 2.0** (For third-party integrations)
4. **Session-Based Authentication** (For web applications)

## Bearer Token Authentication

### Overview

Bearer tokens are the primary authentication method for the API. These JWT (JSON Web Token) tokens are included in the `Authorization` header of each request.

### Obtaining a Token

**Endpoint:** `POST /auth/login`

**Request:**

```bash
curl -X POST "https://api.soporteclientes.net/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePassword123!"
  }'
```

**JavaScript:**
```javascript
const axios = require('axios');

async function login(email, password) {
  try {
    const response = await axios.post(
      'https://api.soporteclientes.net/v1/auth/login',
      {
        email: email,
        password: password
      }
    );

    const token = response.data.token;
    console.log('Authentication successful');
    console.log('Token:', token);

    // Store token securely
    localStorage.setItem('api_token', token);

    return response.data;
  } catch (error) {
    console.error('Login failed:', error.response.data);
    throw error;
  }
}

// Usage
login('user@example.com', 'SecurePassword123!');
```

**PHP:**
```php
<?php

function authenticate($email, $password) {
    $url = 'https://api.soporteclientes.net/v1/auth/login';

    $data = [
        'email' => $email,
        'password' => $password
    ];

    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Accept: application/json'
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode === 200) {
        $result = json_decode($response, true);
        $token = $result['token'];

        // Store token securely
        $_SESSION['api_token'] = $token;

        return $result;
    } else {
        throw new Exception('Authentication failed: ' . $response);
    }
}

// Usage
try {
    $auth = authenticate('user@example.com', 'SecurePassword123!');
    echo "Authentication successful\n";
    print_r($auth);
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
```

**Response:**
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaS5zb3BvcnRlY2xpZW50ZXMubmV0IiwiaWF0IjoxNjQyMjQ4MDAwLCJleHAiOjE2NDIyNTE2MDAsInVzZXJfaWQiOjEyM30.abcdefghijklmnopqrstuvwxyz",
  "token_type": "Bearer",
  "expires_in": 3600,
  "user": {
    "id": 123,
    "name": "John Doe",
    "email": "user@example.com",
    "role": "admin",
    "permissions": [
      "users.view",
      "users.create",
      "billing.manage"
    ]
  }
}
```

### Using the Token

Include the token in the `Authorization` header of all subsequent requests:

```bash
curl -X GET "https://api.soporteclientes.net/v1/whm/accounts" \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..." \
  -H "Accept: application/json"
```

**JavaScript:**
```javascript
const axios = require('axios');

const apiClient = axios.create({
  baseURL: 'https://api.soporteclientes.net/v1',
  headers: {
    'Authorization': `Bearer ${localStorage.getItem('api_token')}`,
    'Accept': 'application/json'
  }
});

// Use the client for all API requests
async function getAccounts() {
  const response = await apiClient.get('/whm/accounts');
  return response.data;
}
```

**PHP:**
```php
<?php

class ApiClient {
    private $baseUrl = 'https://api.soporteclientes.net/v1';
    private $token;

    public function __construct($token) {
        $this->token = $token;
    }

    public function get($endpoint) {
        return $this->request('GET', $endpoint);
    }

    public function post($endpoint, $data) {
        return $this->request('POST', $endpoint, $data);
    }

    private function request($method, $endpoint, $data = null) {
        $ch = curl_init($this->baseUrl . $endpoint);

        $headers = [
            'Authorization: Bearer ' . $this->token,
            'Accept: application/json',
            'Content-Type: application/json'
        ];

        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

        if ($data !== null) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        }

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode >= 400) {
            throw new Exception('API request failed: ' . $response);
        }

        return json_decode($response, true);
    }
}

// Usage
$client = new ApiClient($_SESSION['api_token']);
$accounts = $client->get('/whm/accounts');
```

### Token Expiration

Tokens are valid for **1 hour** (3600 seconds) by default. The `expires_in` field in the login response indicates the token lifetime in seconds.

### Token Refresh

Before your token expires, refresh it to maintain uninterrupted access:

**Endpoint:** `POST /auth/refresh`

```bash
curl -X POST "https://api.soporteclientes.net/v1/auth/refresh" \
  -H "Authorization: Bearer YOUR_CURRENT_TOKEN" \
  -H "Accept: application/json"
```

**JavaScript:**
```javascript
async function refreshToken() {
  try {
    const currentToken = localStorage.getItem('api_token');

    const response = await axios.post(
      'https://api.soporteclientes.net/v1/auth/refresh',
      {},
      {
        headers: {
          'Authorization': `Bearer ${currentToken}`,
          'Accept': 'application/json'
        }
      }
    );

    const newToken = response.data.token;
    localStorage.setItem('api_token', newToken);

    return newToken;
  } catch (error) {
    console.error('Token refresh failed:', error.response.data);
    // Redirect to login
    window.location.href = '/login';
  }
}

// Auto-refresh before expiration
function setupTokenRefresh(expiresIn) {
  // Refresh 5 minutes before expiration
  const refreshTime = (expiresIn - 300) * 1000;

  setTimeout(async () => {
    await refreshToken();
    setupTokenRefresh(3600); // Setup next refresh
  }, refreshTime);
}
```

**PHP:**
```php
<?php

function refreshToken($currentToken) {
    $url = 'https://api.soporteclientes.net/v1/auth/refresh';

    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $currentToken,
        'Accept: application/json'
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode === 200) {
        $result = json_decode($response, true);
        $_SESSION['api_token'] = $result['token'];
        return $result['token'];
    } else {
        // Token refresh failed, redirect to login
        session_destroy();
        header('Location: /login');
        exit;
    }
}
```

**Response:**
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.NEW_TOKEN_DATA",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

### Logout

Invalidate your token when logging out:

**Endpoint:** `POST /auth/logout`

```bash
curl -X POST "https://api.soporteclientes.net/v1/auth/logout" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

**Response:**
```json
{
  "message": "Successfully logged out"
}
```

## API Key Authentication

### Overview

API keys are long-lived credentials suitable for server-to-server communication. Unlike bearer tokens, API keys don't expire but can be manually revoked.

### Generating an API Key

1. Log into your dashboard at https://dashboard.soporteclientes.net
2. Navigate to **Settings** > **API Keys**
3. Click **Generate New API Key**
4. Provide a descriptive name (e.g., "Production Server", "Billing Integration")
5. Select permissions/scopes
6. Save the generated key securely (it won't be shown again)

### Using an API Key

Include the API key in the `X-API-Key` header:

```bash
curl -X GET "https://api.soporteclientes.net/v1/whm/accounts" \
  -H "X-API-Key: sk_live_abc123xyz789" \
  -H "Accept: application/json"
```

**JavaScript:**
```javascript
const axios = require('axios');

const apiClient = axios.create({
  baseURL: 'https://api.soporteclientes.net/v1',
  headers: {
    'X-API-Key': process.env.API_KEY,
    'Accept': 'application/json'
  }
});

async function getAccounts() {
  const response = await apiClient.get('/whm/accounts');
  return response.data;
}
```

**PHP:**
```php
<?php

$apiKey = getenv('API_KEY');

function makeRequest($endpoint, $method = 'GET', $data = null) {
    global $apiKey;

    $ch = curl_init('https://api.soporteclientes.net/v1' . $endpoint);

    $headers = [
        'X-API-Key: ' . $apiKey,
        'Accept: application/json',
        'Content-Type: application/json'
    ];

    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

    if ($data !== null) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    }

    $response = curl_exec($ch);
    curl_close($ch);

    return json_decode($response, true);
}

$accounts = makeRequest('/whm/accounts');
```

### API Key Permissions

API keys can be scoped to specific permissions:

- **Read-only**: Can only perform GET requests
- **Full access**: Can perform all operations
- **Custom**: Select specific endpoints/actions

### Revoking an API Key

To revoke an API key:

```bash
curl -X DELETE "https://api.soporteclientes.net/v1/auth/api-keys/{key_id}" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Or revoke through the dashboard.

## OAuth 2.0

### Overview

OAuth 2.0 is used for third-party integrations where you want to access user data without handling their credentials.

### Supported Flows

1. **Authorization Code Flow** (Recommended for web apps)
2. **Client Credentials Flow** (For server-to-server)
3. **Refresh Token Flow**

### Authorization Code Flow

#### Step 1: Register Your Application

Register your OAuth application at https://dashboard.soporteclientes.net/oauth/apps

You'll receive:
- **Client ID**: `client_abc123`
- **Client Secret**: `secret_xyz789`
- **Redirect URI**: `https://yourapp.com/callback`

#### Step 2: Authorization Request

Redirect users to the authorization URL:

```
https://api.soporteclientes.net/v1/oauth/authorize?
  response_type=code&
  client_id=client_abc123&
  redirect_uri=https://yourapp.com/callback&
  scope=read_accounts,write_accounts&
  state=random_state_string
```

**JavaScript:**
```javascript
function initiateOAuth() {
  const params = new URLSearchParams({
    response_type: 'code',
    client_id: 'client_abc123',
    redirect_uri: 'https://yourapp.com/callback',
    scope: 'read_accounts write_accounts',
    state: generateRandomState()
  });

  window.location.href = `https://api.soporteclientes.net/v1/oauth/authorize?${params}`;
}
```

#### Step 3: Handle Callback

After user authorization, they're redirected to your callback URL:

```
https://yourapp.com/callback?code=AUTH_CODE&state=random_state_string
```

#### Step 4: Exchange Code for Token

```bash
curl -X POST "https://api.soporteclientes.net/v1/oauth/token" \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "authorization_code",
    "client_id": "client_abc123",
    "client_secret": "secret_xyz789",
    "code": "AUTH_CODE",
    "redirect_uri": "https://yourapp.com/callback"
  }'
```

**JavaScript:**
```javascript
async function exchangeCodeForToken(code) {
  const response = await axios.post(
    'https://api.soporteclientes.net/v1/oauth/token',
    {
      grant_type: 'authorization_code',
      client_id: 'client_abc123',
      client_secret: 'secret_xyz789',
      code: code,
      redirect_uri: 'https://yourapp.com/callback'
    }
  );

  return response.data;
}
```

**Response:**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "refresh_abc123xyz",
  "scope": "read_accounts write_accounts"
}
```

### Client Credentials Flow

For server-to-server authentication:

```bash
curl -X POST "https://api.soporteclientes.net/v1/oauth/token" \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "client_credentials",
    "client_id": "client_abc123",
    "client_secret": "secret_xyz789",
    "scope": "read_accounts"
  }'
```

### Refresh Token Flow

When your access token expires:

```bash
curl -X POST "https://api.soporteclientes.net/v1/oauth/token" \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "refresh_token",
    "client_id": "client_abc123",
    "client_secret": "secret_xyz789",
    "refresh_token": "refresh_abc123xyz"
  }'
```

**JavaScript:**
```javascript
async function refreshAccessToken(refreshToken) {
  try {
    const response = await axios.post(
      'https://api.soporteclientes.net/v1/oauth/token',
      {
        grant_type: 'refresh_token',
        client_id: 'client_abc123',
        client_secret: 'secret_xyz789',
        refresh_token: refreshToken
      }
    );

    return response.data.access_token;
  } catch (error) {
    console.error('Token refresh failed:', error);
    // Re-authenticate user
  }
}
```

### OAuth Scopes

Available scopes:

| Scope | Description |
|-------|-------------|
| `read_accounts` | Read WHM accounts |
| `write_accounts` | Create/modify WHM accounts |
| `read_billing` | Read billing information |
| `write_billing` | Manage billing |
| `read_users` | Read user data |
| `write_users` | Manage users |
| `admin` | Full administrative access |

## Two-Factor Authentication (2FA)

### Enabling 2FA

When 2FA is enabled on an account, the login process requires an additional step:

**Step 1: Initial Login**

```bash
curl -X POST "https://api.soporteclientes.net/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePassword123!"
  }'
```

**Response (2FA Required):**
```json
{
  "requires_2fa": true,
  "methods": ["totp", "sms"],
  "session_id": "sess_abc123xyz"
}
```

**Step 2: Submit 2FA Code**

```bash
curl -X POST "https://api.soporteclientes.net/v1/auth/2fa/verify" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "sess_abc123xyz",
    "code": "123456",
    "method": "totp"
  }'
```

**JavaScript:**
```javascript
async function loginWith2FA(email, password, twoFACode) {
  try {
    // Step 1: Initial login
    const loginResponse = await axios.post(
      'https://api.soporteclientes.net/v1/auth/login',
      { email, password }
    );

    if (loginResponse.data.requires_2fa) {
      // Step 2: Submit 2FA code
      const verifyResponse = await axios.post(
        'https://api.soporteclientes.net/v1/auth/2fa/verify',
        {
          session_id: loginResponse.data.session_id,
          code: twoFACode,
          method: 'totp'
        }
      );

      return verifyResponse.data;
    }

    return loginResponse.data;
  } catch (error) {
    console.error('Login failed:', error.response.data);
    throw error;
  }
}
```

**Response:**
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "user": {
    "id": 123,
    "name": "John Doe",
    "email": "user@example.com"
  }
}
```

## Security Best Practices

### 1. Token Storage

**Never store tokens in:**
- URL parameters
- Browser localStorage (for sensitive apps)
- Version control systems
- Client-side code
- Logs

**Recommended storage:**
- Server-side session storage
- Secure HTTP-only cookies
- Environment variables
- Secure credential managers

**JavaScript (Secure Cookie):**
```javascript
// Set token in HTTP-only cookie (server-side)
response.cookie('auth_token', token, {
  httpOnly: true,
  secure: true,
  sameSite: 'strict',
  maxAge: 3600000
});
```

### 2. Token Transmission

Always use HTTPS for API requests. HTTP requests will be rejected.

### 3. Token Rotation

Implement regular token rotation:

```javascript
const TOKEN_MAX_AGE = 24 * 60 * 60 * 1000; // 24 hours

async function checkAndRotateToken() {
  const tokenAge = Date.now() - tokenIssuedAt;

  if (tokenAge > TOKEN_MAX_AGE) {
    await refreshToken();
  }
}
```

### 4. API Key Management

**Best practices:**
- Use environment variables for API keys
- Use different keys for different environments
- Implement key rotation
- Monitor key usage
- Revoke unused keys

**Environment Variables:**
```bash
# .env file
API_KEY_PRODUCTION=sk_live_abc123xyz
API_KEY_STAGING=sk_test_def456uvw
API_KEY_DEVELOPMENT=sk_dev_ghi789rst
```

### 5. Implement Request Signing

For critical operations, implement HMAC request signing:

```javascript
const crypto = require('crypto');

function signRequest(apiSecret, method, path, timestamp, body) {
  const payload = `${method}${path}${timestamp}${JSON.stringify(body)}`;
  const signature = crypto
    .createHmac('sha256', apiSecret)
    .update(payload)
    .digest('hex');

  return signature;
}

// Usage
const timestamp = Date.now();
const signature = signRequest(
  process.env.API_SECRET,
  'POST',
  '/whm/accounts',
  timestamp,
  requestBody
);

// Include in headers
headers: {
  'Authorization': `Bearer ${token}`,
  'X-Signature': signature,
  'X-Timestamp': timestamp
}
```

**PHP:**
```php
<?php

function signRequest($apiSecret, $method, $path, $timestamp, $body) {
    $payload = $method . $path . $timestamp . json_encode($body);
    $signature = hash_hmac('sha256', $payload, $apiSecret);
    return $signature;
}

$timestamp = time();
$signature = signRequest(
    getenv('API_SECRET'),
    'POST',
    '/whm/accounts',
    $timestamp,
    $requestBody
);

$headers = [
    'Authorization: Bearer ' . $token,
    'X-Signature: ' . $signature,
    'X-Timestamp: ' . $timestamp
];
```

### 6. IP Whitelisting

Enable IP whitelisting in your dashboard for enhanced security:

1. Navigate to **Settings** > **Security**
2. Enable **IP Whitelisting**
3. Add your server IPs
4. Save changes

Requests from non-whitelisted IPs will be rejected with a 403 error.

### 7. Rate Limiting

Implement client-side rate limiting to avoid hitting limits:

```javascript
const Bottleneck = require('bottleneck');

// Limit to 100 requests per minute
const limiter = new Bottleneck({
  reservoir: 100,
  reservoirRefreshAmount: 100,
  reservoirRefreshInterval: 60 * 1000,
  maxConcurrent: 5
});

const apiRequest = limiter.wrap(async (url) => {
  return await axios.get(url);
});
```

### 8. Secure Error Handling

Don't expose sensitive information in error messages:

```javascript
// ❌ Bad - Exposes token
console.log('Request failed with token:', token, error);

// ✅ Good - No sensitive data
console.log('Request failed:', error.response.status);
```

## Authentication Errors

### Common Error Codes

| Code | Status | Description | Solution |
|------|--------|-------------|----------|
| `AUTHENTICATION_REQUIRED` | 401 | No credentials provided | Include Authorization header |
| `INVALID_TOKEN` | 401 | Token is invalid or malformed | Check token format |
| `EXPIRED_TOKEN` | 401 | Token has expired | Refresh token |
| `INVALID_CREDENTIALS` | 401 | Wrong email/password | Verify credentials |
| `ACCOUNT_LOCKED` | 423 | Account is locked | Contact support |
| `2FA_REQUIRED` | 401 | 2FA code needed | Submit 2FA code |
| `INVALID_2FA_CODE` | 401 | Wrong 2FA code | Retry with correct code |
| `INSUFFICIENT_PERMISSIONS` | 403 | Lack required permissions | Request higher access level |
| `IP_NOT_WHITELISTED` | 403 | IP not in whitelist | Add IP to whitelist |

### Error Response Example

```json
{
  "error": {
    "code": "EXPIRED_TOKEN",
    "message": "Your authentication token has expired. Please refresh your token or login again.",
    "details": {
      "expired_at": "2025-10-23T14:30:00Z"
    },
    "request_id": "req_abc123xyz"
  }
}
```

### Handling Authentication Errors

**JavaScript:**
```javascript
async function handleAuthError(error) {
  if (error.response) {
    switch (error.response.data.error.code) {
      case 'EXPIRED_TOKEN':
        // Try to refresh token
        await refreshToken();
        // Retry original request
        break;

      case 'INVALID_TOKEN':
        // Clear stored token and redirect to login
        localStorage.removeItem('api_token');
        window.location.href = '/login';
        break;

      case 'INSUFFICIENT_PERMISSIONS':
        // Show permission error
        alert('You do not have permission to perform this action');
        break;

      default:
        console.error('Authentication error:', error.response.data);
    }
  }
}
```

## Testing Authentication

### Test Credentials (Sandbox)

For testing in the sandbox environment:

```
Email: test@example.com
Password: TestPassword123!
API Key: sk_test_abc123xyz789
```

### Testing Authentication Flow

```javascript
const assert = require('assert');

async function testAuthenticationFlow() {
  try {
    // Test login
    const loginResponse = await login('test@example.com', 'TestPassword123!');
    assert(loginResponse.token, 'Token should be present');
    console.log('✓ Login successful');

    // Test authenticated request
    const accounts = await getAccounts(loginResponse.token);
    assert(Array.isArray(accounts.data), 'Should return accounts array');
    console.log('✓ Authenticated request successful');

    // Test token refresh
    const refreshedToken = await refreshToken(loginResponse.token);
    assert(refreshedToken, 'Refreshed token should be present');
    console.log('✓ Token refresh successful');

    // Test logout
    await logout(refreshedToken);
    console.log('✓ Logout successful');

    console.log('\nAll authentication tests passed!');
  } catch (error) {
    console.error('Test failed:', error.message);
  }
}

testAuthenticationFlow();
```

## Conclusion

Proper authentication is critical for API security. Remember to:

- Use HTTPS for all requests
- Store credentials securely
- Implement token refresh before expiration
- Handle authentication errors gracefully
- Rotate API keys regularly
- Enable 2FA for sensitive accounts
- Monitor authentication logs
- Use IP whitelisting for production

For more information, see:
- [API Overview](overview.md)
- [API Endpoints Reference](endpoints.md)
- [Security Best Practices](#security-best-practices)

Need help? Contact api-support@soporteclientes.net
