# Documentation Standards

## Ruby Method Documentation

Document public methods when the name alone doesn't convey intent, parameters, or return values. Skip docs for obvious one-liners.

```ruby
# Good — explains non-obvious return and parameters
# Returns the user's display name, falling back to email if name is blank.
# Raises ArgumentError if user has neither name nor email.
def display_name(user)
  user.name.presence || user.email || raise(ArgumentError, "User has no name or email")
end

# No doc needed — self-explanatory
def full_name
  "#{first_name} #{last_name}".strip
end
```

Common tags: `@param`, `@return`, `@raise`, `@example`, `@deprecated`, `@see`

## README

Every project needs a README that covers:
- What the project does (one paragraph)
- Prerequisites and setup (`bundle install`, env vars, DB setup)
- How to run tests
- How to deploy

Keep it up to date — a wrong README is worse than no README.

## Architectural Decision Records (ADRs)

Record significant architectural decisions in `docs/decisions/`. Use this format:

```
# ADR-001: Use service objects for business logic

## Status
Accepted

## Context
Fat models were accumulating business logic, making testing difficult.

## Decision
Extract multi-step business operations into service objects under app/services/.

## Consequences
Controllers stay thin. Services are easily unit tested. Slight indirection for simple operations.
```

## API Documentation

Document API endpoints with OpenAPI/Swagger when building public or cross-team APIs. Keep docs colocated with the code (e.g., `docs/api/`).

## CHANGELOG

Maintain a CHANGELOG for user-facing changes. Use [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
## [Unreleased]
### Added
- User search by email

### Fixed
- Payment total rounding error
```
