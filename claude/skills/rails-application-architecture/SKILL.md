---
name: rails-application-architecture
description: This document defines the core architectural decisions for the Rails application.
The goal is to ensure **consistency, maintainability, and scalability** as the system evolves.
---

# Rails Architecture Decisions

Status: accepted
Date: 2026-03-06

This document defines the core architectural decisions for the Rails application.
The goal is to ensure **consistency, maintainability, and scalability** as the system evolves.

---

## Tech stack

* ruby on rails: 8.1
* ruby: 3.4
* database: postgres
* caching: redis
* background: sidekiq
* web server: puma
* Views: HAML
* Frontend: Hotwire (Turbo + Stimulus)
* css: boostrap 5
* authorisation: cancancan
* authentication:  build in rails 8 (bcrypt)
* pagination: will_paginate
* dockerization: docker and docker compose
* deployment: kamal
* error monitoring: rollbar
* performance monitoring: new relic
* logging: lograge
* search: postgres full text search (potential future migration to elasticsearch or meilisearch)
* file storage: active storage with s3 compatible object storage
* email delivery: smtp
* Tests: RSpec + FactoryBot + Capybara
* Test data generation: Faker
* Caching: Redis
* annotation:  annotaterb gem
* code coverage: simplecov
* Environment variable management: dotenv-rails
* Debugging with step-through: pry-nav
* CI: GitHub Actions:
* * test suite
* * code quality checks (rubocop, brakeman, annotate)
* * code coverage reporting
* * deployment to production
* * Frequent Dependency Updates


# 1. Application Architecture

## Decision

The application will be implemented as a **modular Rails monolith**.

## Rationale

A modular monolith provides:

* simpler development and deployment
* lower operational complexity than microservices
* strong maintainability for small to medium teams
* clear domain boundaries within a single codebase

The codebase will be organized by responsibility and domain.

```
app/
  controllers/
  models/
  presenters/
  services/
  queries/
  abilities/
  jobs/
  components/
```

---

# 2. Authentication Strategy

## Decision

Authentication will be implemented using **native Rails authentication mechanisms**.

Implementation:

* `has_secure_password`
* session-based authentication
* custom `SessionsController`

## Rationale

Advantages:

* minimal dependencies
* full control over the authentication flow
* lower complexity than large authentication frameworks

---

# 3. Authorization Strategy

## Decision

Authorization will be implemented using **CanCanCan**.

Roles:

* guest
* user
* admin

Implementation:

```
app/abilities/ability.rb
```

Example rule:

```ruby
can :update, Post, user_id: user.id
```

---

# 4. Database

## Decision

Primary database: **PostgreSQL**

ORM:

* ActiveRecord

## Rationale

PostgreSQL provides:

* strong reliability
* excellent Rails integration
* JSONB support
* good performance and scalability

---

# 5. Query Architecture

## Decision

Complex queries will be implemented using **Query Objects**.

Location:

```
app/queries/
```

Example:

```
Orders::RecentQuery.call
```

## Rationale

Benefits:

* keeps models small
* improves testability
* isolates performance optimizations

---

# 6. Business Logic

## Decision

Business logic will be implemented using **Service Objects**.

Location:

```
app/services/
```

Example:

```
Orders::CreateOrder.call(user:, params:)
```

## Rationale

Advantages:

* keeps controllers thin
* isolates business workflows
* improves reusability and testing

---

# 7. Background Jobs

## Decision

Asynchronous processing will use **Sidekiq**.

Typical background tasks:

* email delivery
* webhooks
* imports
* report generation

Queue structure:

* default
* mailers
* critical

---

# 8. Caching Strategy

## Decision

Caching will be implemented using **Redis**.

Rails cache store:

```
redis_cache_store
```

Caching layers:

* fragment caching
* query caching
* API response caching

---

# 9. Pagination

## Decision

Pagination will use **will_paginate**.

Default page size:

```
per_page = 20
```

Controller example:

```ruby
@posts = Post.paginate(page: params[:page], per_page: 20)
```

---

# 10. Logging

## Decision

Logging will use **structured logs** via Lograge.

Benefits:

* cleaner logs
* easier analysis
* compatible with log aggregation systems

---

# 11. Error Monitoring

## Decision

Application errors will be tracked using **Rollbar**.

Captured events:

* application exceptions
* background job failures
* performance-related errors

---

# 12. Performance Monitoring

## Decision

Performance monitoring will be handled by **New Relic**.

Monitored metrics:

* request duration
* database queries
* background job performance

---

# 13. Deployment Strategy

## Decision

Application deployment will use **Kamal**.

Deployment model:

* Docker containers
* rolling deployments
* zero-downtime releases

---

# 14. Hosting Infrastructure

## Decision

The application will run on **cloud-based virtual machines**.

Potential providers:

* AWS
* Hetzner
* DigitalOcean

---

# 15. Frontend Architecture

## Decision

Frontend will use **Hotwire**.

Principles:

* server-rendered HTML
* minimal JavaScript
* Turbo + Stimulus

---

# 16. API Architecture

## Decision

The application will expose a **REST API**.

Example endpoints:

```
GET /orders
POST /orders
PUT /orders/:id
```

---

# 17. Serialization

## Decision

JSON serialization will use **Jbuilder**.

Advantages:

* ships with Rails — no extra dependency
* template-based — colocated with views
* easy partial reuse for consistent API responses

---

# 18. Security Strategy

## Decision

Security measures include:

* CSRF protection
* rate limiting
* automated security scans

Tools:

* Rack::Attack
* Brakeman

---

# 19. Rate Limiting

## Decision

API requests will be rate limited.

Example limit:

```
100 requests per minute per IP
```

Implementation via Rack::Attack.

---

# 20. File Storage

## Decision

File uploads will use **ActiveStorage**.

Storage backend:

* S3-compatible object storage

---

# 21. Email Delivery

## Decision

Email delivery will use SMTP

---

# 22. Search Strategy

## Decision

Search functionality will initially use **PostgreSQL Full-Text Search**.

If requirements grow, migration to a dedicated search engine may occur:

* Elasticsearch
* Meilisearch

---

# 23. Multitenancy Strategy

## Decision

Multitenancy will be implemented using a **tenant_id column**.

Advantages:

* simple implementation
* compatible with standard Rails queries
* easy to maintain

---

# 24. Testing Strategy

## Decision

Testing stack:

* RSpec
* FactoryBot
* Capybara

Test types:

* unit tests
* request tests
* system tests

---

# 25. Observability

## Decision

System observability will be based on three signals:

1. Logs
2. Metrics
3. Errors

Tools used:

* Lograge
* Sentry
* New Relic

---

# Architectural Principles

The system follows these principles:

* controllers remain thin
* business logic lives in services
* complex queries belong in query objects
* asynchronous tasks run in background jobs
* clear domain separation

Example request flow:

```
Request
 ↓
Controller
 ↓
Authorization
 ↓
Service Object
 ↓
Query Object
 ↓
ActiveRecord
 ↓
Background Job
```
