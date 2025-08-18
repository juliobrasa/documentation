# System Architecture Overview

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         Users                               │
└─────────────┬───────────────────────────────┬───────────────┘
              │                               │
              ▼                               ▼
    ┌─────────────────┐             ┌─────────────────┐
    │   Web Browser   │             │   Mobile App    │
    └────────┬────────┘             └────────┬────────┘
             │                                │
             ▼                                ▼
    ┌────────────────────────────────────────────────┐
    │           Load Balancer / Nginx                 │
    └────────┬───────────┬──────────────┬────────────┘
             │           │              │
             ▼           ▼              ▼
    ┌──────────┐  ┌──────────┐  ┌──────────┐
    │   WHM    │  │  cPanel  │  │  Admin   │
    │  Panel   │  │  System  │  │  Panel   │
    └────┬─────┘  └────┬─────┘  └────┬─────┘
         │             │              │
         └─────────────┼──────────────┘
                       │
                       ▼
    ┌────────────────────────────────────────┐
    │           Shared Services              │
    │  - Authentication (JWT/Sanctum)        │
    │  - API Gateway                         │
    │  - Queue System (Redis)               │
    │  - Cache Layer (Redis)                │
    └────────────────┬───────────────────────┘
                     │
         ┌───────────┼───────────┐
         ▼           ▼           ▼
    ┌─────────┐ ┌─────────┐ ┌─────────┐
    │  MySQL  │ │  Redis  │ │  Files  │
    │   DBs   │ │  Cache  │ │ Storage │
    └─────────┘ └─────────┘ └─────────┘
```

## Components

### 1. Frontend Layer
- **Web Interface**: React/Vue.js based SPAs
- **Mobile Support**: Responsive design
- **API Clients**: RESTful API consumption

### 2. Application Layer

#### WHM Panel
- **Framework**: Laravel 9.x
- **Purpose**: WHM server management
- **Key Features**:
  - Multi-server management
  - Account CRUD operations
  - Package management
  - Reseller management
  - Backup automation

#### cPanel System
- **Framework**: Laravel 9.x
- **Purpose**: Billing and automation
- **Key Features**:
  - Billing management
  - Subscription handling
  - Invoice generation
  - Payment processing
  - Auto-installer

#### Admin Panel
- **Framework**: Laravel 9.x
- **Purpose**: Central administration
- **Key Features**:
  - User management
  - System monitoring
  - API management
  - Audit logging
  - Report generation

### 3. Service Layer

#### Authentication Service
- **Type**: JWT + Laravel Sanctum
- **Features**:
  - Token-based auth
  - 2FA support
  - Session management
  - Role-based access

#### API Gateway
- **Protocol**: RESTful
- **Format**: JSON
- **Versioning**: URL-based (v1, v2)
- **Rate Limiting**: Per-user/IP

#### Queue System
- **Driver**: Redis/Database
- **Workers**: Supervisor managed
- **Jobs**: Email, backups, reports

#### Cache Layer
- **Driver**: Redis/Memcached
- **TTL**: Configurable
- **Strategies**: Tag-based invalidation

### 4. Data Layer

#### Databases
- **WHM Database**: `whm_panel`
  - Accounts, servers, packages
  - Resellers, backups
  - Activity logs

- **cPanel Database**: `cpanel1db`
  - Billing tables
  - Subscriptions
  - Installer data

- **Admin Database**: `admindb`
  - Users, roles
  - System settings
  - Audit logs

#### File Storage
- **Local**: Application files
- **S3-compatible**: Backups, uploads
- **CDN**: Static assets

## Design Patterns

### 1. Repository Pattern
```php
interface AccountRepository {
    public function find($id);
    public function create(array $data);
    public function update($id, array $data);
    public function delete($id);
}
```

### 2. Service Layer Pattern
```php
class AccountService {
    public function __construct(
        private AccountRepository $repository,
        private WHMApiClient $whmClient
    ) {}
    
    public function createAccount($data) {
        // Business logic
        $account = $this->repository->create($data);
        $this->whmClient->createAccount($account);
        return $account;
    }
}
```

### 3. Observer Pattern
- Event-driven architecture
- Laravel events and listeners
- Webhook notifications

### 4. Factory Pattern
- Dynamic service creation
- Payment gateway factories
- Notification channel factories

## Security Architecture

### Authentication Flow
```
User → Login → Validate → Generate Token → Store Session → Return Token
         ↓
    Failed → Log Attempt → Block if threshold → Notify Admin
```

### Authorization
- Role-Based Access Control (RBAC)
- Permission middleware
- API token scopes
- Resource policies

### Data Protection
- Encryption at rest (AES-256)
- TLS 1.3 for transport
- Password hashing (bcrypt)
- SQL injection prevention
- XSS protection

## Scalability

### Horizontal Scaling
- Load balancing with Nginx
- Multiple application servers
- Read replicas for databases
- Redis clustering

### Vertical Scaling
- Resource optimization
- Query optimization
- Caching strategies
- CDN implementation

### Microservices Ready
- Service separation
- API-first design
- Message queue communication
- Independent deployments

## Performance Optimization

### Caching Strategy
1. **Page Cache**: Full page caching
2. **Query Cache**: Database query results
3. **Object Cache**: Computed objects
4. **CDN**: Static assets

### Database Optimization
- Indexed columns
- Query optimization
- Connection pooling
- Read/write splitting

### Code Optimization
- Lazy loading
- Eager loading relationships
- Compiled routes/config
- OpCache enabled

## Monitoring & Logging

### Application Monitoring
- Laravel Telescope
- Custom metrics
- Performance tracking
- Error tracking

### Infrastructure Monitoring
- Server metrics
- Database performance
- Queue monitoring
- Cache hit rates

### Logging
- Centralized logging
- Log aggregation
- Real-time alerts
- Audit trails

## Deployment Architecture

### Development
```
Local → Git → CI/CD → Staging → Testing → Production
```

### Production Setup
- Blue-green deployment
- Zero-downtime updates
- Rollback capability
- Automated backups

### Container Support
- Docker images
- Kubernetes ready
- Helm charts
- Auto-scaling

## Integration Points

### External Services
- WHM/cPanel API
- Payment gateways
- Email services
- SMS providers
- Monitoring services

### Webhooks
- Incoming webhooks
- Outgoing notifications
- Event subscriptions
- Retry mechanisms

## Disaster Recovery

### Backup Strategy
- Daily automated backups
- Off-site storage
- Point-in-time recovery
- Tested restore procedures

### High Availability
- Multiple data centers
- Database replication
- Failover mechanisms
- Health checks

## Technology Stack

### Backend
- **Language**: PHP 8.0+
- **Framework**: Laravel 9.x
- **API**: RESTful, GraphQL ready
- **Queue**: Redis/Horizon

### Frontend
- **Framework**: Vue.js/React
- **CSS**: Tailwind CSS
- **Build**: Webpack/Vite
- **State**: Vuex/Redux

### Infrastructure
- **OS**: CentOS/AlmaLinux
- **Web Server**: Apache/Nginx
- **Database**: MySQL/MariaDB
- **Cache**: Redis/Memcached
- **Search**: Elasticsearch (optional)

### DevOps
- **CI/CD**: GitHub Actions
- **Monitoring**: Prometheus/Grafana
- **Logging**: ELK Stack
- **Containers**: Docker/Kubernetes