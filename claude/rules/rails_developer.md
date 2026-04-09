## 📚 Core Rails Principles

All specialists follow these NON-NEGOTIABLE principles:

### 1. Test-First Development (TDD)

**Every feature MUST follow Red-Green-Refactor:**

```ruby
# 1. RED - Write failing test FIRST
RSpec.describe User do
  it "validates email presence" do
    user = User.new(email: nil)
    expect(user).not_to be_valid
  end
end

# 2. Run test - MUST fail
# 3. GREEN - Write minimal code to pass
# 4. REFACTOR - Improve while tests pass
```

**Rules:**
- ✅ Tests written BEFORE implementation
- ✅ Never commit failing tests
- ✅ Never skip/disable tests to pass builds
- ✅ Red-Green-Refactor cycle strictly enforced

### 2. YAGNI Principle

**You Aren't Gonna Need It - Don't create abstractions until needed.**

- YAGNI. The best code is no code. Don't add features we don't need right now.
- When it doesn't conflict with YAGNI, architect for extensibility and flexibility.

### 3. Convention Over Configuration

Follow Rails conventions unless compelling reason:

- **Naming**: Models singular, Controllers plural
- **Routes**: RESTful design
- **Structure**: Standard Rails directories
- **Patterns**: Rails way first

### 4. Security by Design

**Always:**
- ✅ Strong parameters in controllers
- ✅ Authorization on all actions (CanCanCan)
- ✅ Encrypt sensitive data (Lockbox)
- ✅ HTTPS in production
- ✅ Rate limiting on APIs

### 5. Incremental Progress

Each commit should:
- ✅ Compile successfully
- ✅ Pass all tests
- ✅ Be deployable
- ✅ Represent complete feature slice

## Developer Workflow Scripts

Every project must have three executable scripts in `bin/`:

**`bin/setup`** — Idempotent bootstrapping. A new developer runs this once to get the app running:

```ruby
#!/usr/bin/env ruby
require "optparse"

def setup
  log "Installing gems"
  system! "bundle check || bundle install"

  log "Setting up database"
  system! "bin/rails db:reset || bin/rails db:migrate"
  system!({ "RAILS_ENV" => "test" }, "bin/rails db:reset")

  log "Done. Run bin/dev to start the app."
end

def system!(*args)
  system(*args) || abort("\n== Command #{args} failed ==")
end

def log(message)
  puts "\n== #{message} =="
end

setup
```

**`bin/dev`** — Starts all dev processes via Overmind/Foreman using `Procfile.dev`:

```bash
#!/usr/bin/env bash
exec overmind start -f Procfile.dev "$@"
```

**`bin/ci`** — Mirrors CI locally. Run before pushing:

```bash
#!/usr/bin/env bash
set -e
bundle exec rspec
bundle exec rubocop
bundle exec brakeman --no-pager
bundle exec bundle-audit check
```

These three scripts are the project's living documentation for how to get it running. A new developer runs `bin/setup` then `bin/dev` — that's the whole setup story.

---

## Runtime Configuration (12-Factor)

Use environment variables for all runtime configuration. Use `dotenv` for dev/test:

```ruby
# Gemfile
gem "dotenv-rails", groups: [:development, :test]
```

```bash
# .env.development — not committed, used in development
DATABASE_URL=postgres://localhost/myapp_development
REDIS_URL=redis://localhost:6379/0

# .env.test — not committed, used in tests
DATABASE_URL=postgres://localhost/myapp_test
```

Never use `config/environments/` YAML files for things that differ per deployment. ENV is the only mechanism that works consistently across local, CI, staging, and production without code changes.

Commit `.env.development.sample` and `.env.test.sample` as documentation of required variables.

---

## Gemfile Documentation

Add a brief comment to every non-obvious gem explaining why it's included:

```ruby
# Password hashing
gem "bcrypt"

# Paginate ActiveRecord collections
gem "pagy"

# Authorization
gem "cancancan"

# Detect N+1 queries in development
gem "bullet", group: :development
```

Skip comments for gems whose purpose is obvious from the name. The Gemfile is read by every developer who joins — comments answer "why is this here?" which `bundle info` cannot.

---

## 📋 Quality Checklist

Before any commit, specialists ensure:

```bash
# All must pass:
bundle exec rspec                    # Tests
bundle exec rubocop                  # Linting
bundle exec brakeman --no-pager      # Security
bundle exec bundle-audit check       # Vulnerabilities
```
