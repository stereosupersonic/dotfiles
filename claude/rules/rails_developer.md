---
name: rails-developer
description: General Rules for working om a rails code base
version: 1.0.0
rails_version: ">= 8.0"
---

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

### 3. Convention Over Configuration

Follow Rails conventions unless compelling reason:

- **Naming**: Models singular, Controllers plural
- **Routes**: RESTful design
- **Structure**: Standard Rails directories
- **Patterns**: Rails way first

### 4. Security by Design

**Always:**
- ✅ Strong parameters in controllers
- ✅ Authorization on all actions (Pundit)
- ✅ Encrypt sensitive data (Lockbox)
- ✅ HTTPS in production
- ✅ Rate limiting on APIs

### 5. Incremental Progress

Each commit should:
- ✅ Compile successfully
- ✅ Pass all tests
- ✅ Be deployable
- ✅ Represent complete feature slice

## 📋 Quality Checklist

Before any commit, specialists ensure:

```bash
# All must pass:
bundle exec rspec                    # Tests
bundle exec rubocop                  # Linting
bundle exec brakeman --no-pager      # Security
bundle exec bundle-audit check       # Vulnerabilities
```
