# Security Architecture

Comprehensive security architecture and best practices for the Hosting Management Platform.

## Security Overview

The platform implements defense-in-depth security with multiple layers of protection:

```
┌─────────────────────────────────────────────────┐
│              External Security Layer             │
│  - Firewall, DDoS Protection, WAF               │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────┐
│           Transport Security Layer               │
│  - TLS 1.3, SSL Certificates, HSTS              │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────┐
│        Authentication & Authorization            │
│  - JWT, 2FA, RBAC, API Tokens                   │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────┐
│           Application Security Layer             │
│  - Input Validation, CSRF, XSS Protection       │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────┐
│              Data Security Layer                 │
│  - Encryption at Rest, Secure Storage           │
└─────────────────────────────────────────────────┘
```

## Authentication Architecture

### Multi-Factor Authentication Flow

```
User Login
    │
    ▼
┌──────────────────────┐
│ Username + Password  │
└─────────┬────────────┘
          │
          ▼
    ┌─────────┐
    │Validate │ ──No──> Fail (Log attempt)
    │Password │
    └────┬────┘
         │Yes
         ▼
    ┌─────────────┐
    │2FA Enabled? │──No──> Generate Token
    └─────┬───────┘
          │Yes
          ▼
    ┌──────────────┐
    │Request 2FA   │
    │Code/Token    │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │Validate 2FA  │──No──> Fail
    └──────┬───────┘
           │Yes
           ▼
    ┌──────────────────┐
    │ Generate Session │
    │  & JWT Token     │
    └──────────────────┘
```

### Password Security

#### Password Requirements

```php
- Minimum length: 12 characters
- Must contain:
  - Uppercase letters (A-Z)
  - Lowercase letters (a-z)
  - Numbers (0-9)
  - Special characters (!@#$%^&*)
- Cannot contain:
  - Username
  - Common words
  - Previously used passwords (last 5)
```

#### Password Hashing

```php
// Using bcrypt with cost factor 12
$hashedPassword = Hash::make($password, [
    'rounds' => 12,
]);

// Verify password
if (Hash::check($plainPassword, $hashedPassword)) {
    // Password matches
}
```

#### Password Policy

```php
- Maximum age: 90 days
- Grace period: 7 days
- Lockout after failed attempts: 5
- Lockout duration: 30 minutes
- Password history: 5 passwords
```

### JWT Token Security

#### Token Structure

```json
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "sub": "user_id",
    "email": "user@example.com",
    "roles": ["admin"],
    "iat": 1635724800,
    "exp": 1635728400,
    "jti": "unique_token_id"
  }
}
```

#### Token Configuration

```php
// Access Token
- Lifetime: 15 minutes
- Refresh: Yes
- Storage: Memory only (client-side)
- Blacklist: On logout

// Refresh Token
- Lifetime: 30 days
- Rotation: Yes (single use)
- Storage: Secure HTTP-only cookie
- Blacklist: On password change
```

#### Token Blacklisting

```php
// Blacklist on logout
Cache::put(
    'token_blacklist_' . $tokenId,
    true,
    $tokenExpiration
);

// Check if blacklisted
if (Cache::has('token_blacklist_' . $tokenId)) {
    throw new TokenBlacklistedException();
}
```

### Two-Factor Authentication (2FA)

#### Supported Methods

1. **TOTP (Time-based One-Time Password)**
   - Google Authenticator
   - Authy
   - Microsoft Authenticator

2. **SMS**
   - Backup method
   - Rate limited

3. **Recovery Codes**
   - 10 one-time use codes
   - Regenerate after use

#### Implementation

```php
use PragmaRX\Google2FA\Google2FA;

// Generate secret
$google2fa = new Google2FA();
$secretKey = $google2fa->generateSecretKey();

// Verify code
$valid = $google2fa->verifyKey($secretKey, $code);
```

## Authorization Architecture

### Role-Based Access Control (RBAC)

```
┌─────────┐
│  Users  │
└────┬────┘
     │ has many
     ▼
┌─────────┐
│  Roles  │
└────┬────┘
     │ has many
     ▼
┌──────────────┐
│ Permissions  │
└──────────────┘
```

#### Default Roles

```php
Super Admin
├── Full system access
└── Cannot be deleted

Admin
├── User management
├── System configuration
├── View audit logs
└── Manage servers

Reseller
├── Create accounts
├── Manage own accounts
├── View own billing
└── Limited server access

User
├── View own account
├── Manage own services
└── View own billing

API User
├── Programmatic access
└── Scoped permissions
```

#### Permission System

```php
// Define permissions
'accounts.view'
'accounts.create'
'accounts.update'
'accounts.delete'
'accounts.suspend'

'servers.view'
'servers.create'
'servers.manage'

'billing.view'
'billing.manage'

'admin.users.manage'
'admin.system.configure'
```

#### Check Permissions

```php
// In controller
if (!auth()->user()->can('accounts.create')) {
    abort(403, 'Unauthorized action.');
}

// In blade
@can('accounts.create')
    <button>Create Account</button>
@endcan

// Via middleware
Route::post('/accounts', [AccountController::class, 'store'])
    ->middleware('permission:accounts.create');
```

### API Authorization

#### Scoped API Tokens

```php
$token = $user->createToken('Mobile App', [
    'accounts:read',
    'billing:read'
]);

// Verify scope
if ($request->user()->tokenCan('accounts:read')) {
    // Allowed
}
```

## Data Protection

### Encryption at Rest

#### Database Encryption

```php
// Encrypted model attributes
class User extends Model
{
    protected $casts = [
        'api_token' => 'encrypted',
        'two_factor_secret' => 'encrypted',
        'recovery_codes' => 'encrypted:array',
    ];
}
```

#### File Encryption

```php
// Encrypt files
Storage::put('secrets.txt', encrypt($data));

// Decrypt files
$data = decrypt(Storage::get('secrets.txt'));
```

#### Encryption Configuration

```php
- Algorithm: AES-256-CBC
- Key derivation: PBKDF2
- Key rotation: Quarterly
- Key storage: Environment variables
```

### Encryption in Transit

#### TLS Configuration

```apache
SSLEngine on
SSLProtocol -all +TLSv1.3 +TLSv1.2
SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256
SSLHonorCipherOrder on
```

#### HSTS (HTTP Strict Transport Security)

```php
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
```

### Sensitive Data Handling

#### PII Protection

```php
// Never log sensitive data
Log::info('User logged in', [
    'user_id' => $user->id,
    // Do NOT log: password, token, credit card, etc.
]);

// Mask sensitive data in responses
{
    "card_number": "****-****-****-1234",
    "email": "j***@example.com"
}
```

#### Data Sanitization

```php
// Before display
$clean = htmlspecialchars($userInput, ENT_QUOTES, 'UTF-8');

// Before storage
$clean = strip_tags($userInput);

// SQL injection prevention (automatic with Eloquent)
User::where('email', $email)->first();
```

## Application Security

### CSRF Protection

```php
// Automatic in Laravel
<form method="POST">
    @csrf
    <!-- form fields -->
</form>

// API exemption (use token auth instead)
protected $except = [
    'api/*'
];
```

### XSS Prevention

```php
// Blade automatic escaping
{{ $userInput }}

// Unescaped (use with caution)
{!! $trustedHtml !!}

// Content Security Policy
Header set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';"
```

### SQL Injection Prevention

```php
// ✅ Good - Using Eloquent
User::where('email', $email)->first();

// ✅ Good - Using query builder with bindings
DB::table('users')->where('email', $email)->first();

// ❌ Bad - Raw queries without bindings
DB::select("SELECT * FROM users WHERE email = '$email'");

// ✅ Good - Raw queries with bindings
DB::select("SELECT * FROM users WHERE email = ?", [$email]);
```

### Input Validation

```php
// Request validation
public function rules()
{
    return [
        'email' => 'required|email|max:255',
        'domain' => 'required|regex:/^[a-z0-9.-]+$/i',
        'username' => 'required|alpha_num|min:3|max:16',
        'password' => 'required|min:12|confirmed',
    ];
}

// Custom validation
Validator::extend('safe_domain', function ($attribute, $value, $parameters, $validator) {
    return !preg_match('/[<>"\']/', $value);
});
```

### File Upload Security

```php
// Validate uploads
'avatar' => 'required|image|max:2048|mimes:jpeg,png,jpg',

// Secure storage
$path = $request->file('avatar')->store('avatars', 'private');

// Scan for malware (optional)
if (AntiVirus::scan($path)->isInfected()) {
    Storage::delete($path);
    throw new VirusDetectedException();
}
```

### Command Injection Prevention

```php
// ❌ Bad
exec("ping " . $userInput);

// ✅ Good - Use escapeshellarg
exec("ping " . escapeshellarg($userInput));

// ✅ Better - Validate input first
if (!filter_var($ip, FILTER_VALIDATE_IP)) {
    throw new InvalidArgumentException();
}
exec("ping " . escapeshellarg($ip));
```

## Network Security

### Firewall Configuration

```bash
# Default deny all
firewall-cmd --set-default-zone=drop

# Allow specific services
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=ssh

# Allow specific ports
firewall-cmd --permanent --add-port=2087/tcp

# Rate limiting (using firewalld rich rules)
firewall-cmd --permanent --add-rich-rule='rule service name=ssh limit value=3/m accept'

# Reload
firewall-cmd --reload
```

### DDoS Protection

```nginx
# Nginx rate limiting
limit_req_zone $binary_remote_addr zone=one:10m rate=10r/s;
limit_conn_zone $binary_remote_addr zone=addr:10m;

server {
    limit_req zone=one burst=20 nodelay;
    limit_conn addr 10;
}
```

### IP Whitelisting

```php
// Restrict admin access
Route::middleware(['admin', 'ip.whitelist'])->group(function () {
    // Admin routes
});

// IP whitelist middleware
if (!in_array($request->ip(), config('security.admin_ips'))) {
    abort(403, 'Access denied from your IP address.');
}
```

## Security Monitoring

### Audit Logging

```php
// Log security events
AuditLog::create([
    'user_id' => auth()->id(),
    'action' => 'login',
    'ip_address' => request()->ip(),
    'user_agent' => request()->userAgent(),
    'status' => 'success',
]);

// Events to log
- Login attempts (success & failure)
- Password changes
- Permission changes
- Account creation/deletion
- Configuration changes
- API access
- Failed authorization attempts
```

### Failed Login Protection

```php
// Track failed attempts
$key = 'login_attempts_' . $request->ip();
$attempts = Cache::get($key, 0);

if ($attempts >= 5) {
    $lockoutTime = 30; // minutes
    throw new TooManyAttemptsException($lockoutTime);
}

// Increment on failure
Cache::put($key, $attempts + 1, now()->addMinutes(30));

// Clear on success
Cache::forget($key);
```

### Intrusion Detection

```php
// Detect suspicious patterns
- Multiple failed logins
- Access from unusual locations
- Rapid API requests
- Unusual user behavior
- Permission escalation attempts

// Response actions
- Lock account
- Require password reset
- Require 2FA
- Notify admin
- Block IP
```

## Security Headers

### Recommended Headers

```php
// In middleware or web server config
'X-Frame-Options' => 'SAMEORIGIN',
'X-Content-Type-Options' => 'nosniff',
'X-XSS-Protection' => '1; mode=block',
'Referrer-Policy' => 'strict-origin-when-cross-origin',
'Permissions-Policy' => 'geolocation=(), microphone=(), camera=()',
'Content-Security-Policy' => "default-src 'self'",
```

## Compliance

### GDPR Compliance

```php
// Data rights
- Right to access
- Right to rectification
- Right to erasure
- Right to data portability
- Right to object

// Implementation
Route::get('/api/v1/user/data', [UserDataController::class, 'export']);
Route::delete('/api/v1/user', [UserDataController::class, 'destroy']);
```

### PCI DSS (if handling payments)

```php
// Requirements
- Never store CVV
- Encrypt card data
- Use tokenization
- Regular security audits
- Access logging
- Network segmentation

// Implementation
- Use Stripe/PayPal (recommended)
- Store tokens only, not actual card numbers
- Log all payment transactions
```

## Security Best Practices

### Development

1. **Keep dependencies updated**
   ```bash
   composer audit
   npm audit
   ```

2. **Use environment variables for secrets**
   ```php
   // ✅ Good
   'api_key' => env('API_KEY')

   // ❌ Bad
   'api_key' => 'hardcoded_key'
   ```

3. **Disable debug mode in production**
   ```php
   APP_DEBUG=false
   ```

4. **Use prepared statements**
5. **Validate all input**
6. **Sanitize all output**
7. **Use HTTPS everywhere**
8. **Implement rate limiting**

### Deployment

1. **Secure server access**
   - SSH key authentication only
   - Disable root login
   - Non-standard SSH port

2. **File permissions**
   ```bash
   chmod 755 /home/*/
   chmod 775 /home/*/storage
   chmod 600 .env
   ```

3. **Regular backups**
4. **Security updates**
5. **Monitoring & alerting**

## Incident Response

### Security Incident Plan

1. **Detection**
   - Monitor logs
   - Automated alerts
   - User reports

2. **Assessment**
   - Determine scope
   - Identify vulnerability
   - Assess damage

3. **Containment**
   - Isolate affected systems
   - Block malicious IPs
   - Revoke compromised tokens

4. **Eradication**
   - Patch vulnerability
   - Remove malware
   - Reset credentials

5. **Recovery**
   - Restore from backups
   - Verify system integrity
   - Resume operations

6. **Post-Incident**
   - Document incident
   - Update procedures
   - Implement preventive measures

## Security Checklist

### Pre-Launch Security Audit

- [ ] SSL/TLS properly configured
- [ ] Firewall rules in place
- [ ] All ports secured
- [ ] Debug mode disabled
- [ ] Error display disabled
- [ ] File permissions correct
- [ ] Database credentials secure
- [ ] API rate limiting enabled
- [ ] CSRF protection enabled
- [ ] XSS protection enabled
- [ ] SQL injection prevention verified
- [ ] Input validation implemented
- [ ] Audit logging enabled
- [ ] Backup system tested
- [ ] Security headers configured
- [ ] 2FA available
- [ ] Password policy enforced
- [ ] Dependencies updated
- [ ] Security scan completed
- [ ] Penetration test performed

---

*For implementation details, see [Security Best Practices](../guides/security.md)*
