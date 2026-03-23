---
name: rails-best-practices
description: Ruby on Rails Development Guidelines. Apply when writing or reviewing Rails code to ensure it follows project conventions. References the authoritative rule files in ~/.claude/rules/ — do not duplicate those rules here.
---

# Ruby on Rails Development Guidelines

Apply all rules from `~/.claude/rules/` when writing or reviewing Rails code.

## Rules Reference

| Rule File | Covers |
|-----------|--------|
| `ruby.md` | Style, naming, conditionals, collections, strings |
| `architecture.md` | Service objects, presenters, finders, form objects, namespacing |
| `controllers.md` | Thin controllers, strong params, REST, one instance variable per action |
| `models.md` | ActiveRecord, enums, validations, callbacks, associations |
| `database.md` | Query optimization, N+1 prevention, transactions |
| `migrations.md` | Zero-downtime, constraints, rollback safety |
| `views.md` | HAML, I18n, partials, semantic HTML |
| `testing.md` | TDD philosophy, test types, real objects over mocks |
| `rspec.md` | RSpec syntax, subject/let, matchers, FactoryBot |
| `capybara.md` | Capybara system spec style, finders, matchers, actions, scoping |
| `api.md` | Versioning, Jbuilder serialization, error formats |
| `jobs.md` | Idempotency, queue naming, retry strategies |
| `security.md` | Rails 8 auth, CanCanCan, CSRF, mass assignment |
| `mailers.md` | Naming, HTML+text templates, background delivery |
| `performance.md` | filter_map, flat_map, match?, Struct over OpenStruct |
| `backend.md` | Error handling, custom exceptions, caching |
| `frontend.md` | Hotwire/Turbo/Stimulus, minimal JS, CSS discipline |
| `hotwire.md` | Turbo Frames, Turbo Streams, morphing, Stimulus controller catalog |
| `caching.md` | HTTP caching, Russian doll, Solid Cache, counter caches |
| `delegated-types.md` | Delegated types vs STI, Contactable pattern |
| `webhooks.md` | SSRF protection, delivery lifecycle, signature verification |
| `activestorage.md` | Attachment removal, direct uploads, custom keys |
| `git.md` | Commit messages, branch naming, PR hygiene |

## Core Principles

- Optimize for **low carrying cost**, not short-term delivery speed
- **Simple is better than complex** — don't abstract prematurely
- **Explicit is better than implicit** — name things clearly
- Errors should never pass silently
- In the face of ambiguity, refuse the temptation to guess

## Architecture at a Glance

```
Request
 ↓
Controller  (thin — no business logic)
 ↓
Service Object  (business logic)
 ↓
Query Object  (complex queries)
 ↓
ActiveRecord
 ↓
Background Job  (async work)
```

**Where things live:**
- Business logic → `app/services/` (verb+noun: `CreateUser`, `ProcessPayment`)
- Complex queries → `app/queries/`
- View formatting → `app/presenters/` (extend `ApplicationPresenter`)
- Multi-model forms → `app/forms/`
- Search/filter → `app/filters/`

## Non-Negotiables

- Double quotes for all strings
- HAML over ERB
- Service objects for anything beyond simple CRUD
- RSpec + FactoryBot for all tests — no fixtures
- TDD: write failing test first, then make it pass
- Migrations must be reversible and zero-downtime safe
- All user-facing strings through I18n
- `Time.current` not `Time.now`
- Eager load associations — never load in a loop
