# Webhooks Documentation

## Overview

Webhooks allow you to receive real-time notifications about events in your soporteclientes.net account. Instead of polling the API for changes, webhooks push event data to your server as events occur.

### Benefits of Webhooks

- **Real-time updates** - Receive events as they happen
- **Reduced API calls** - No need to poll for changes
- **Efficient** - Only receive data when events occur
- **Scalable** - Handle high-volume events easily

### How Webhooks Work

1. You configure a webhook endpoint URL in your dashboard
2. When an event occurs in your account, we send an HTTP POST request to your endpoint
3. Your server receives and processes the event
4. Your server responds with a 200 status code to acknowledge receipt

## Setting Up Webhooks

### Creating a Webhook Endpoint

**Via Dashboard:**
1. Navigate to **Settings** > **Webhooks**
2. Click **Create Webhook**
3. Enter your endpoint URL (must be HTTPS)
4. Select events to subscribe to
5. Save webhook

**Via API:**

```bash
curl -X POST "https://api.soporteclientes.net/v1/webhooks" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://yourapp.com/webhooks/soporteclientes",
    "events": ["account.created", "account.suspended", "invoice.paid"],
    "secret": "your_webhook_secret",
    "description": "Production webhook endpoint"
  }'
```

**JavaScript:**
```javascript
const axios = require('axios');

async function createWebhook() {
  try {
    const response = await axios.post(
      'https://api.soporteclientes.net/v1/webhooks',
      {
        url: 'https://yourapp.com/webhooks/soporteclientes',
        events: [
          'account.created',
          'account.suspended',
          'invoice.paid'
        ],
        secret: process.env.WEBHOOK_SECRET,
        description: 'Production webhook endpoint'
      },
      {
        headers: {
          'Authorization': `Bearer ${process.env.API_TOKEN}`,
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('Webhook created:', response.data);
    return response.data;
  } catch (error) {
    console.error('Failed to create webhook:', error.response.data);
  }
}
```

**PHP:**
```php
<?php

function createWebhook($apiToken, $webhookUrl, $events) {
    $url = 'https://api.soporteclientes.net/v1/webhooks';

    $data = [
        'url' => $webhookUrl,
        'events' => $events,
        'secret' => getenv('WEBHOOK_SECRET'),
        'description' => 'Production webhook endpoint'
    ];

    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $apiToken,
        'Content-Type: application/json',
        'Accept: application/json'
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode === 201) {
        return json_decode($response, true);
    } else {
        throw new Exception('Failed to create webhook: ' . $response);
    }
}

// Usage
$webhook = createWebhook(
    getenv('API_TOKEN'),
    'https://yourapp.com/webhooks/soporteclientes',
    ['account.created', 'account.suspended', 'invoice.paid']
);
```

**Response:**
```json
{
  "data": {
    "id": "webhook_abc123",
    "url": "https://yourapp.com/webhooks/soporteclientes",
    "events": ["account.created", "account.suspended", "invoice.paid"],
    "status": "active",
    "secret": "whsec_abc123xyz789",
    "created_at": "2025-10-23T14:30:00Z"
  }
}
```

## Webhook Events

### Available Events

#### Account Events

| Event | Description | Trigger |
|-------|-------------|---------|
| `account.created` | WHM account created | New account provisioned |
| `account.updated` | Account details updated | Account modified |
| `account.suspended` | Account suspended | Account suspension |
| `account.unsuspended` | Account reactivated | Account unsuspension |
| `account.terminated` | Account terminated | Account deletion |
| `account.password_changed` | Password modified | Password update |

#### Billing Events

| Event | Description | Trigger |
|-------|-------------|---------|
| `invoice.created` | New invoice generated | Invoice creation |
| `invoice.paid` | Invoice paid successfully | Payment processed |
| `invoice.overdue` | Invoice overdue | Payment deadline passed |
| `invoice.cancelled` | Invoice cancelled | Invoice cancellation |
| `payment.succeeded` | Payment successful | Successful payment |
| `payment.failed` | Payment failed | Failed payment attempt |
| `subscription.created` | New subscription | Subscription start |
| `subscription.updated` | Subscription modified | Plan change, etc. |
| `subscription.cancelled` | Subscription cancelled | Cancellation |
| `subscription.renewed` | Subscription renewed | Auto-renewal |

#### User Events

| Event | Description | Trigger |
|-------|-------------|---------|
| `user.created` | New user created | User registration |
| `user.updated` | User details updated | Profile modification |
| `user.deleted` | User deleted | Account removal |
| `user.password_reset` | Password reset requested | Reset request |

#### System Events

| Event | Description | Trigger |
|-------|-------------|---------|
| `server.status_changed` | Server status changed | Up/down status change |
| `server.quota_warning` | Server quota warning | 80% quota reached |
| `license.expiring` | License expiring soon | 30 days before expiry |
| `license.expired` | License expired | License expiration |

### Event Payload Structure

All webhook events follow this structure:

```json
{
  "id": "evt_abc123xyz",
  "type": "account.created",
  "created_at": "2025-10-23T14:30:00Z",
  "data": {
    "object": {
      "id": 123,
      "domain": "example.com",
      "username": "user123",
      "status": "active",
      "server_id": 5,
      "package_id": 2,
      "created_at": "2025-10-23T14:30:00Z"
    }
  },
  "previous_attributes": null
}
```

For update events, `previous_attributes` contains the changed fields:

```json
{
  "id": "evt_def456uvw",
  "type": "account.suspended",
  "created_at": "2025-10-23T15:45:00Z",
  "data": {
    "object": {
      "id": 123,
      "domain": "example.com",
      "status": "suspended"
    }
  },
  "previous_attributes": {
    "status": "active"
  }
}
```

## Receiving Webhooks

### Creating a Webhook Endpoint

Your webhook endpoint should:
- Accept POST requests
- Respond quickly (under 5 seconds)
- Return a 200 status code
- Verify the webhook signature
- Process events asynchronously

### Example Implementations

**JavaScript (Express.js):**
```javascript
const express = require('express');
const crypto = require('crypto');
const bodyParser = require('body-parser');

const app = express();

// Important: Use raw body for signature verification
app.use(bodyParser.raw({ type: 'application/json' }));

const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET;

app.post('/webhooks/soporteclientes', async (req, res) => {
  // Get signature from header
  const signature = req.headers['x-webhook-signature'];
  const timestamp = req.headers['x-webhook-timestamp'];

  // Verify signature
  if (!verifyWebhookSignature(req.body, signature, timestamp)) {
    console.error('Invalid webhook signature');
    return res.status(401).send('Invalid signature');
  }

  // Parse the payload
  const event = JSON.parse(req.body.toString());

  // Respond quickly
  res.status(200).send('Webhook received');

  // Process event asynchronously
  processWebhookEvent(event).catch(err => {
    console.error('Error processing webhook:', err);
  });
});

function verifyWebhookSignature(payload, signature, timestamp) {
  // Reject old requests (prevent replay attacks)
  const currentTime = Math.floor(Date.now() / 1000);
  if (Math.abs(currentTime - timestamp) > 300) { // 5 minutes
    return false;
  }

  // Calculate expected signature
  const signedPayload = `${timestamp}.${payload}`;
  const expectedSignature = crypto
    .createHmac('sha256', WEBHOOK_SECRET)
    .update(signedPayload)
    .digest('hex');

  // Compare signatures
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}

async function processWebhookEvent(event) {
  console.log('Processing event:', event.type);

  switch (event.type) {
    case 'account.created':
      await handleAccountCreated(event.data.object);
      break;

    case 'account.suspended':
      await handleAccountSuspended(event.data.object);
      break;

    case 'invoice.paid':
      await handleInvoicePaid(event.data.object);
      break;

    case 'payment.failed':
      await handlePaymentFailed(event.data.object);
      break;

    default:
      console.log('Unhandled event type:', event.type);
  }
}

async function handleAccountCreated(account) {
  console.log('New account created:', account.domain);
  // Send welcome email
  // Update local database
  // Trigger provisioning workflow
}

async function handleInvoicePaid(invoice) {
  console.log('Invoice paid:', invoice.id);
  // Update invoice status
  // Send receipt
  // Provision services
}

app.listen(3000, () => {
  console.log('Webhook server listening on port 3000');
});
```

**PHP:**
```php
<?php

// webhook_handler.php

$webhookSecret = getenv('WEBHOOK_SECRET');

// Get raw POST data
$payload = file_get_contents('php://input');
$signature = $_SERVER['HTTP_X_WEBHOOK_SIGNATURE'] ?? '';
$timestamp = $_SERVER['HTTP_X_WEBHOOK_TIMESTAMP'] ?? '';

// Verify signature
if (!verifyWebhookSignature($payload, $signature, $timestamp, $webhookSecret)) {
    http_response_code(401);
    die('Invalid signature');
}

// Parse event
$event = json_decode($payload, true);

// Respond quickly
http_response_code(200);
echo 'Webhook received';

// Close connection and continue processing
fastcgi_finish_request();

// Process event
processWebhookEvent($event);

function verifyWebhookSignature($payload, $signature, $timestamp, $secret) {
    // Reject old requests (prevent replay attacks)
    $currentTime = time();
    if (abs($currentTime - $timestamp) > 300) { // 5 minutes
        return false;
    }

    // Calculate expected signature
    $signedPayload = $timestamp . '.' . $payload;
    $expectedSignature = hash_hmac('sha256', $signedPayload, $secret);

    // Compare signatures (timing-safe comparison)
    return hash_equals($expectedSignature, $signature);
}

function processWebhookEvent($event) {
    error_log('Processing event: ' . $event['type']);

    switch ($event['type']) {
        case 'account.created':
            handleAccountCreated($event['data']['object']);
            break;

        case 'account.suspended':
            handleAccountSuspended($event['data']['object']);
            break;

        case 'invoice.paid':
            handleInvoicePaid($event['data']['object']);
            break;

        case 'payment.failed':
            handlePaymentFailed($event['data']['object']);
            break;

        default:
            error_log('Unhandled event type: ' . $event['type']);
    }
}

function handleAccountCreated($account) {
    error_log('New account created: ' . $account['domain']);

    // Update database
    $db = getDatabase();
    $stmt = $db->prepare(
        "INSERT INTO accounts (id, domain, username, status) VALUES (?, ?, ?, ?)"
    );
    $stmt->execute([
        $account['id'],
        $account['domain'],
        $account['username'],
        $account['status']
    ]);

    // Send welcome email
    sendWelcomeEmail($account['email'], $account['username']);

    // Log activity
    logActivity('account_created', $account['id']);
}

function handleInvoicePaid($invoice) {
    error_log('Invoice paid: ' . $invoice['id']);

    // Update invoice status
    $db = getDatabase();
    $stmt = $db->prepare("UPDATE invoices SET status = 'paid' WHERE id = ?");
    $stmt->execute([$invoice['id']]);

    // Send receipt
    sendReceipt($invoice['user_email'], $invoice);

    // Provision services if needed
    provisionServices($invoice['subscription_id']);
}

function handleAccountSuspended($account) {
    error_log('Account suspended: ' . $account['domain']);

    // Update local database
    $db = getDatabase();
    $stmt = $db->prepare("UPDATE accounts SET status = 'suspended' WHERE id = ?");
    $stmt->execute([$account['id']]);

    // Notify user
    sendSuspensionNotice($account['email'], $account['domain']);
}

function handlePaymentFailed($payment) {
    error_log('Payment failed: ' . $payment['id']);

    // Notify user
    sendPaymentFailureNotice($payment['user_email'], $payment);

    // Update subscription status
    updateSubscriptionStatus($payment['subscription_id'], 'payment_failed');
}
```

**Python (Flask):**
```python
from flask import Flask, request, jsonify
import hmac
import hashlib
import time
import json
import os

app = Flask(__name__)
WEBHOOK_SECRET = os.getenv('WEBHOOK_SECRET')

@app.route('/webhooks/soporteclientes', methods=['POST'])
def handle_webhook():
    # Get signature from headers
    signature = request.headers.get('X-Webhook-Signature')
    timestamp = request.headers.get('X-Webhook-Timestamp')

    # Get raw payload
    payload = request.get_data()

    # Verify signature
    if not verify_webhook_signature(payload, signature, timestamp):
        return jsonify({'error': 'Invalid signature'}), 401

    # Parse event
    event = json.loads(payload)

    # Respond quickly
    response = jsonify({'status': 'received'})

    # Process event asynchronously (use Celery, RQ, etc. in production)
    process_webhook_event(event)

    return response, 200

def verify_webhook_signature(payload, signature, timestamp):
    # Reject old requests (prevent replay attacks)
    current_time = int(time.time())
    if abs(current_time - int(timestamp)) > 300:  # 5 minutes
        return False

    # Calculate expected signature
    signed_payload = f"{timestamp}.{payload.decode('utf-8')}"
    expected_signature = hmac.new(
        WEBHOOK_SECRET.encode('utf-8'),
        signed_payload.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()

    # Compare signatures (timing-safe comparison)
    return hmac.compare_digest(expected_signature, signature)

def process_webhook_event(event):
    event_type = event['type']
    event_data = event['data']['object']

    handlers = {
        'account.created': handle_account_created,
        'account.suspended': handle_account_suspended,
        'invoice.paid': handle_invoice_paid,
        'payment.failed': handle_payment_failed,
    }

    handler = handlers.get(event_type)
    if handler:
        handler(event_data)
    else:
        print(f"Unhandled event type: {event_type}")

def handle_account_created(account):
    print(f"New account created: {account['domain']}")
    # Update database, send emails, etc.

def handle_account_suspended(account):
    print(f"Account suspended: {account['domain']}")
    # Update database, notify user, etc.

def handle_invoice_paid(invoice):
    print(f"Invoice paid: {invoice['id']}")
    # Update invoice status, send receipt, etc.

def handle_payment_failed(payment):
    print(f"Payment failed: {payment['id']}")
    # Notify user, update subscription, etc.

if __name__ == '__main__':
    app.run(port=3000)
```

## Webhook Security

### Signature Verification

All webhooks include a signature in the `X-Webhook-Signature` header. **Always verify this signature** to ensure the webhook came from soporteclientes.net.

#### Signature Calculation

The signature is calculated as:

```
HMAC-SHA256(timestamp + "." + payload, webhook_secret)
```

Where:
- `timestamp` - Unix timestamp from `X-Webhook-Timestamp` header
- `payload` - Raw request body
- `webhook_secret` - Your webhook secret

#### Verification Steps

1. **Extract** signature and timestamp from headers
2. **Check timestamp** - Reject if older than 5 minutes (prevents replay attacks)
3. **Calculate** expected signature using your webhook secret
4. **Compare** signatures using timing-safe comparison

#### Example Verification

**JavaScript:**
```javascript
const crypto = require('crypto');

function verifyWebhook(payload, signature, timestamp, secret) {
  // Check timestamp
  const currentTime = Math.floor(Date.now() / 1000);
  if (Math.abs(currentTime - timestamp) > 300) {
    throw new Error('Webhook timestamp too old');
  }

  // Calculate signature
  const signedPayload = `${timestamp}.${payload}`;
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(signedPayload)
    .digest('hex');

  // Compare (timing-safe)
  if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSignature))) {
    throw new Error('Invalid webhook signature');
  }

  return true;
}
```

**PHP:**
```php
<?php

function verifyWebhook($payload, $signature, $timestamp, $secret) {
    // Check timestamp
    $currentTime = time();
    if (abs($currentTime - $timestamp) > 300) {
        throw new Exception('Webhook timestamp too old');
    }

    // Calculate signature
    $signedPayload = $timestamp . '.' . $payload;
    $expectedSignature = hash_hmac('sha256', $signedPayload, $secret);

    // Compare (timing-safe)
    if (!hash_equals($expectedSignature, $signature)) {
        throw new Exception('Invalid webhook signature');
    }

    return true;
}
```

### IP Whitelisting

For additional security, you can whitelist our webhook IP addresses:

```
52.89.214.238
34.212.75.30
54.218.53.128
52.32.178.7
```

**Nginx Configuration:**
```nginx
location /webhooks/soporteclientes {
    allow 52.89.214.238;
    allow 34.212.75.30;
    allow 54.218.53.128;
    allow 52.32.178.7;
    deny all;

    proxy_pass http://localhost:3000;
}
```

### HTTPS Required

All webhook endpoints must use HTTPS. HTTP endpoints will be rejected.

## Webhook Delivery

### Delivery Attempts

We attempt to deliver webhooks with the following retry policy:

| Attempt | Delay |
|---------|-------|
| 1 | Immediate |
| 2 | 1 minute |
| 3 | 5 minutes |
| 4 | 30 minutes |
| 5 | 2 hours |
| 6 | 6 hours |

After 6 failed attempts, the webhook is marked as failed and won't be retried automatically.

### Success Criteria

A webhook delivery is considered successful when:
- Response status code is 2xx (200-299)
- Response received within 5 seconds

### Failure Reasons

Webhooks may fail due to:
- Non-2xx response code
- Timeout (>5 seconds)
- Connection error
- DNS resolution failure
- SSL certificate error

### Webhook Logs

View webhook delivery logs in your dashboard:

```
Settings > Webhooks > [Select Webhook] > Delivery Logs
```

Or via API:

```bash
curl "https://api.soporteclientes.net/v1/webhooks/{webhook_id}/deliveries" \
  -H "Authorization: Bearer YOUR_API_TOKEN"
```

**Response:**
```json
{
  "data": [
    {
      "id": "delivery_abc123",
      "event_id": "evt_xyz789",
      "event_type": "account.created",
      "status": "succeeded",
      "response_code": 200,
      "response_time_ms": 245,
      "attempt": 1,
      "created_at": "2025-10-23T14:30:00Z"
    },
    {
      "id": "delivery_def456",
      "event_id": "evt_uvw012",
      "event_type": "invoice.paid",
      "status": "failed",
      "response_code": 500,
      "response_time_ms": 5000,
      "attempt": 3,
      "error": "Connection timeout",
      "created_at": "2025-10-23T13:15:00Z"
    }
  ]
}
```

## Idempotency

### Handling Duplicate Events

Webhooks may be delivered more than once due to network issues or retries. Implement idempotency to handle duplicates:

**JavaScript:**
```javascript
const processedEvents = new Set();

async function processWebhookEvent(event) {
  // Check if already processed
  if (processedEvents.has(event.id)) {
    console.log('Event already processed:', event.id);
    return;
  }

  // Process event
  await handleEvent(event);

  // Mark as processed
  processedEvents.add(event.id);

  // Store in database for persistence
  await db.insert('processed_events', {
    event_id: event.id,
    processed_at: new Date()
  });
}
```

**PHP:**
```php
<?php

function processWebhookEvent($event) {
    $db = getDatabase();

    // Check if already processed
    $stmt = $db->prepare("SELECT id FROM processed_events WHERE event_id = ?");
    $stmt->execute([$event['id']]);

    if ($stmt->fetch()) {
        error_log('Event already processed: ' . $event['id']);
        return;
    }

    // Process event
    handleEvent($event);

    // Mark as processed
    $stmt = $db->prepare(
        "INSERT INTO processed_events (event_id, processed_at) VALUES (?, NOW())"
    );
    $stmt->execute([$event['id']]);
}
```

## Testing Webhooks

### Local Testing with ngrok

Use ngrok to expose your local server for webhook testing:

```bash
# Start your local webhook server
node webhook-server.js

# In another terminal, start ngrok
ngrok http 3000
```

Use the ngrok HTTPS URL as your webhook endpoint:
```
https://abc123.ngrok.io/webhooks/soporteclientes
```

### Testing Events

Trigger test events from your dashboard:

```
Settings > Webhooks > [Select Webhook] > Send Test Event
```

Or via API:

```bash
curl -X POST "https://api.soporteclientes.net/v1/webhooks/{webhook_id}/test" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "account.created"
  }'
```

### Mock Webhook Server

Create a simple webhook receiver for testing:

```javascript
const express = require('express');
const app = express();

app.use(express.raw({ type: 'application/json' }));

app.post('/webhooks/soporteclientes', (req, res) => {
  const event = JSON.parse(req.body.toString());

  console.log('=== Webhook Received ===');
  console.log('Event ID:', event.id);
  console.log('Event Type:', event.type);
  console.log('Payload:', JSON.stringify(event.data, null, 2));
  console.log('========================\n');

  res.status(200).send('OK');
});

app.listen(3000, () => {
  console.log('Mock webhook server listening on port 3000');
});
```

## Best Practices

### 1. Respond Quickly

Always respond with 200 within 5 seconds:

```javascript
app.post('/webhooks', async (req, res) => {
  // Respond immediately
  res.status(200).send('Received');

  // Process asynchronously
  processWebhookAsync(req.body);
});
```

### 2. Process Asynchronously

Use a queue for webhook processing:

```javascript
const Queue = require('bull');
const webhookQueue = new Queue('webhooks');

app.post('/webhooks', async (req, res) => {
  // Add to queue
  await webhookQueue.add(req.body);

  // Respond immediately
  res.status(200).send('Queued');
});

// Process webhooks from queue
webhookQueue.process(async (job) => {
  await processWebhookEvent(job.data);
});
```

### 3. Implement Idempotency

Always check for duplicate events:

```javascript
async function isEventProcessed(eventId) {
  const exists = await db.query(
    'SELECT 1 FROM processed_events WHERE event_id = ?',
    [eventId]
  );
  return exists.length > 0;
}
```

### 4. Log Everything

Maintain comprehensive logs:

```javascript
async function logWebhook(event, status, error = null) {
  await db.insert('webhook_logs', {
    event_id: event.id,
    event_type: event.type,
    status: status,
    error: error,
    created_at: new Date()
  });
}
```

### 5. Monitor Failures

Set up alerts for webhook failures:

```javascript
async function checkWebhookHealth() {
  const recentFailures = await db.query(`
    SELECT COUNT(*) as count
    FROM webhook_logs
    WHERE status = 'failed'
    AND created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)
  `);

  if (recentFailures[0].count > 10) {
    await sendAlert('High webhook failure rate detected');
  }
}
```

### 6. Handle Versioning

Be prepared for event structure changes:

```javascript
function handleWebhookEvent(event) {
  const version = event.api_version || '1.0';

  switch (version) {
    case '1.0':
      return handleV1Event(event);
    case '2.0':
      return handleV2Event(event);
    default:
      console.warn('Unknown webhook version:', version);
  }
}
```

## Managing Webhooks

### List Webhooks

```bash
curl "https://api.soporteclientes.net/v1/webhooks" \
  -H "Authorization: Bearer YOUR_API_TOKEN"
```

### Update Webhook

```bash
curl -X PUT "https://api.soporteclientes.net/v1/webhooks/{webhook_id}" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "events": ["account.created", "account.suspended", "invoice.paid", "invoice.overdue"]
  }'
```

### Disable Webhook

```bash
curl -X POST "https://api.soporteclientes.net/v1/webhooks/{webhook_id}/disable" \
  -H "Authorization: Bearer YOUR_API_TOKEN"
```

### Delete Webhook

```bash
curl -X DELETE "https://api.soporteclientes.net/v1/webhooks/{webhook_id}" \
  -H "Authorization: Bearer YOUR_API_TOKEN"
```

### Retry Failed Webhook

```bash
curl -X POST "https://api.soporteclientes.net/v1/webhooks/deliveries/{delivery_id}/retry" \
  -H "Authorization: Bearer YOUR_API_TOKEN"
```

## Troubleshooting

### Common Issues

#### 1. Invalid Signature Errors

**Problem:** Webhook verification fails

**Solutions:**
- Ensure you're using the raw request body
- Check you're using the correct webhook secret
- Verify timestamp handling
- Use timing-safe comparison

#### 2. Timeout Errors

**Problem:** Webhook delivery times out

**Solutions:**
- Respond immediately before processing
- Use asynchronous processing
- Optimize database queries
- Increase server resources

#### 3. Duplicate Events

**Problem:** Same event processed multiple times

**Solutions:**
- Implement idempotency checks
- Store processed event IDs
- Use unique constraints in database

#### 4. Missing Events

**Problem:** Not receiving webhooks

**Solutions:**
- Check webhook is enabled
- Verify endpoint URL is correct
- Check firewall/IP whitelist settings
- Review webhook logs for errors
- Ensure HTTPS certificate is valid

### Debug Mode

Enable debug mode to log all webhook requests:

```javascript
const DEBUG = process.env.WEBHOOK_DEBUG === 'true';

app.post('/webhooks', (req, res) => {
  if (DEBUG) {
    console.log('Headers:', req.headers);
    console.log('Body:', req.body.toString());
  }

  // ... process webhook
});
```

## Webhook Examples

### Complete Example: Account Provisioning

```javascript
// webhook-handler.js
const express = require('express');
const crypto = require('crypto');
const { sendEmail } = require('./email');
const { updateDatabase } = require('./database');

const app = express();
app.use(express.raw({ type: 'application/json' }));

const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET;

app.post('/webhooks/soporteclientes', async (req, res) => {
  try {
    // Verify signature
    const signature = req.headers['x-webhook-signature'];
    const timestamp = req.headers['x-webhook-timestamp'];

    if (!verifySignature(req.body, signature, timestamp)) {
      return res.status(401).send('Invalid signature');
    }

    const event = JSON.parse(req.body.toString());

    // Respond immediately
    res.status(200).send('OK');

    // Process event
    await handleWebhookEvent(event);

  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).send('Error processing webhook');
  }
});

async function handleWebhookEvent(event) {
  console.log(`Processing ${event.type}:`, event.id);

  switch (event.type) {
    case 'account.created':
      await provisionAccount(event.data.object);
      break;

    case 'account.suspended':
      await suspendAccount(event.data.object);
      break;

    case 'invoice.paid':
      await activateServices(event.data.object);
      break;
  }
}

async function provisionAccount(account) {
  // Update local database
  await updateDatabase('accounts', {
    id: account.id,
    domain: account.domain,
    status: 'active',
    created_at: account.created_at
  });

  // Send welcome email
  await sendEmail(account.email, 'welcome', {
    username: account.username,
    domain: account.domain,
    control_panel_url: `https://cpanel.${account.domain}`
  });

  // Log activity
  console.log(`Account provisioned: ${account.domain}`);
}

app.listen(3000);
```

## Conclusion

Webhooks provide real-time event notifications for your soporteclientes.net integration. Remember to:

- Always verify webhook signatures
- Respond quickly (under 5 seconds)
- Process events asynchronously
- Implement idempotency
- Monitor webhook health
- Use HTTPS endpoints
- Log webhook activity

For more information, see:
- [API Overview](overview.md)
- [Authentication Guide](authentication.md)
- [API Endpoints Reference](endpoints.md)

Need help? Contact api-support@soporteclientes.net
