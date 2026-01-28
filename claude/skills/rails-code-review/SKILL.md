---
name: rails-code-review
description: Rails code review skill following Konvenit guidelines. Use when the user asks to review Rails code, check for best practices, audit controllers/models/views, or wants feedback on their Rails application code. Triggers on phrases like "review my code", "check this controller", "audit my Rails app", "code review", "best practices check". Enforces service objects, presenters, HAML, double quotes, and Konvenit-specific patterns.
---

# Rails Code Review Skill (Konvenit Guidelines)

Perform thorough code reviews following Konvenit's Rails development standards.

## Core Mindset

- Optimize for **low carrying cost**, not short-term delivery speed
- Prioritize **consistency over cleverness**
- Be explicit, clear, and pragmatic — no premature abstraction
- If trade-off required: **cut scope, not quality**

---

## Code Review Guidelines

### General Principles
- [ ] Code follows Konvenit Guidelines (Ruby, Rails, JavaScript)
- [ ] Code is maintainable — classes are well-structured and properly named
- [ ] If you have trouble understanding concepts, flag it — this indicates structure can be improved
- [ ] Explain where you see structural issues or have a hard time grasping concepts
- [ ] **Avoid requesting changes based on personal preference** — create Rubocop issue instead
- [ ] Check if changes could **unintentionally break production** or have undesirable consequences for users
- [ ] Verify all changes are covered by at least some tests to catch simple runtime exceptions

### Security Review
- [ ] Check for **SQL injection** vulnerabilities:
  - Use `quote` for manual escaping
  - Use parameterized queries: `where("foo LIKE ?", "%#{arg}%")`
  - Never interpolate user input directly into SQL
- [ ] Check for **Cross-Site Scripting (XSS)**:
  - `html_safe` and `raw` are almost never required
  - Use `content_tag` helpers instead
  - If needed, start with empty SafeBuffer: `"".html_safe` and concatenate
- [ ] **No production credentials/keys/certificates in commits** (dev/test data is allowed)

### Migration Review
- [ ] For large data manipulations, consider moving to a **rake task** for more control
- [ ] Check if `NOT NULL` constraints make sense
- [ ] ⚠️ **WARNING**: Adding default values to big tables can run a long time
- [ ] No superfluous/unused columns
- [ ] Check if **indexes** make sense, or if any are missing
- [ ] Check if **unique indexes** make sense
- [ ] Check if **foreign keys** make sense

## Review Process

1. Read the code carefully
2. Check against each rule category below
3. Provide specific, actionable feedback with line references
4. Suggest concrete improvements with code examples
5. Prioritize issues: 🔴 Critical, 🟡 Warning, 🟢 Suggestion

---

## Code Style & Formatting

### Strings & Quotes
- [ ] **Always use double quotes** for strings (single quotes only when specifically needed)
- [ ] Use string interpolation, not concatenation
- [ ] Use `%()` for strings with many quotes
- [ ] Use heredocs for multi-line strings
- [ ] Use `String#strip` for cleaning whitespace

### Indentation & Layout
- [ ] 2 spaces for indentation (no tabs)
- [ ] Line length under 100 characters
- [ ] All files end with a newline
- [ ] Trailing commas in multi-line collections

### Naming Conventions
- [ ] `snake_case` for variables, methods, file names
- [ ] `PascalCase` for class names
- [ ] `SCREAMING_SNAKE_CASE` for constants
- [ ] Descriptive names — avoid abbreviations

### Conditionals
- [ ] Use guard clauses to reduce nesting
- [ ] Use modifier conditionals for simple one-liners
- [ ] Use `unless` sparingly — only for simple negative conditions
- [ ] **Never use `unless` with `else`** — use `if` instead

### Arrays & Hashes
- [ ] Use `%w[]` and `%i[]` for word and symbol arrays
- [ ] Use `Hash#fetch` when handling missing keys matters
- [ ] Use `Hash.new` with block for complex default values

### Rails-Specific
- [ ] Use Rails time helpers instead of Ruby `Time` methods
- [ ] Prefer `present?` and `blank?` over `nil?` and `empty?`
- [ ] Use safe navigation (`&.`) for potentially nil objects
- [ ] Prefer Rails collection methods over raw SQL when possible

---

## Architecture Patterns

### Controllers
- [ ] **Keep controllers thin** — delegate to service objects
- [ ] **Only one instance variable per action**, named after the resource
- [ ] Use strong parameters
- [ ] Use `before_action` for common operations
- [ ] Follow REST conventions
- [ ] Handle errors gracefully with proper HTTP status codes

```ruby
# ❌ Bad: Fat controller with business logic
def create
  @user = User.new(user_params)
  @user.status = "pending"
  @user.activation_token = SecureRandom.hex(20)
  UserMailer.welcome(@user).deliver_later if @user.save
  # ... more logic
end

# ✅ Good: Delegate to service object
def create
  @user = CreateUser.call(params: user_params)
end
```

### Service Objects
- [ ] **Always use service objects** for complex business logic
- [ ] Place in `app/services/`
- [ ] Name with verb + noun format (`CreateUser`, `ProcessPayment`)
- [ ] Single public `call` method
- [ ] Return a result object
- [ ] Inherit from `BaseService`

```ruby
# ✅ Correct service object pattern
class CreateUser < BaseService
  attr_accessor :params

  def call
    # Business logic here
  end
end
```

### Presenter Objects
- [ ] **Use presenters** for complex view-specific logic
- [ ] Place in `app/presenters/`
- [ ] Name with noun + `Presenter` format (`UserPresenter`, `OrderPresenter`)
- [ ] Inherit from `ApplicationPresenter`
- [ ] Use `o.` to access the underlying object

```ruby
# ✅ Correct presenter pattern
class UserPresenter < ApplicationPresenter
  def full_name
    "#{o.first_name} #{o.last_name}".strip
  end

  def formatted_created_at
    o.created_at.strftime("%B %d, %Y")
  end

  def status_badge_class
    o.active? ? "badge-success" : "badge-danger"
  end
end
```

### Models
- [ ] Keep models focused on data and simple validations
- [ ] **No business logic in models** — extract to service objects
- [ ] Use scopes for common queries
- [ ] **Avoid callbacks** (`before_*`, `after_*`) unless absolutely necessary
- [ ] Prefer explicit orchestration over callbacks

```ruby
# ❌ Bad: Callback with side effects
class User < ApplicationRecord
  after_create :send_welcome_email, :create_default_settings
end

# ✅ Good: Explicit orchestration in service
class CreateUser < BaseService
  def call
    user = User.create!(params)
    UserMailer.welcome(user).deliver_later
    DefaultSettings.create_for(user)
    user
  end
end
```

---

## Views & Templates

- [ ] **Prefer HAML over ERB**
- [ ] Extract complex views into presenters
- [ ] No database queries in views
- [ ] Use `data-testid` attributes for test selectors

---

## Authentication & Authorization

- [ ] Use `authentifikator` gem for authentication
- [ ] Use `cancancan` for authorization
- [ ] Define rules in `Authorization::Ability`
- [ ] Use `web_access` block for authentication
- [ ] Use `check_authorization` and `authorize_resource`

```ruby
# ✅ Correct auth pattern
class InvitationsController < ApplicationController
  web_access do
    allow_logged_in :employee
    allow_logged_in :client, if: :team_group_admin?
  end

  check_authorization
  authorize_resource :invitation
end
```

---

## Database & ActiveRecord

- [ ] Meaningful migration names with timestamps
- [ ] **Always add indexes** for foreign keys and frequently queried columns
- [ ] Use `dependent: :destroy` or `dependent: :delete_all` appropriately
- [ ] Validate at **both model and database level**
- [ ] Use database constraints for data integrity
- [ ] Use transactions for multi-step operations

---

## Performance

- [ ] **Use eager loading** (`includes`, `preload`, `joins`) to avoid N+1
- [ ] Add database indexes for frequently queried columns
- [ ] Use counter caches when appropriate
- [ ] Implement pagination for large datasets
- [ ] Cache expensive operations

```ruby
# ❌ Bad: N+1 query
@posts = Post.all
# In view: post.author.name

# ✅ Good: Eager loading
@posts = Post.includes(:author)
```

---

## Background Jobs

- [ ] Use meaningful queue names reflecting priority/purpose
- [ ] **Keep jobs idempotent** — safe to retry
- [ ] Use explicit job classes, not inline jobs
- [ ] Place in `app/jobs/` organized by domain
- [ ] Delegate to service objects

```ruby
# ✅ Correct job pattern
class ProcessPaymentJob < ApplicationJob
  queue_as :payments

  def perform(payment_id)
    payment = Payment.find(payment_id)
    PaymentProcessor.new(payment).call
  end
end
```

---

## API Structure

- [ ] Version APIs from day one (`/api/v1/`)
- [ ] Use Jbuilder for serialization
- [ ] Return consistent error formats
- [ ] Use HTTP status codes correctly (200, 201, 422, 404, 500)
- [ ] Inherit from `Api::V1::BaseController`

```ruby
# ✅ Correct API controller
class Api::V1::BaseController < ApplicationController
  respond_to :json

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

  private

  def not_found
    render json: { error: "Resource not found" }, status: :not_found
  end
end
```

---

## Security

- [ ] Always use strong parameters
- [ ] Sanitize user input
- [ ] Use Rails CSRF protection
- [ ] Use secure headers
- [ ] No hardcoded secrets or credentials
- [ ] No mass assignment vulnerabilities

```ruby
# ❌ Bad: Permit all
params.require(:user).permit!

# ✅ Good: Explicit whitelist
params.require(:user).permit(:name, :email)
```

---

## Testing

- [ ] **Every Ruby code change must be covered by specs** — no exceptions
- [ ] Use RSpec with Arrange-Act-Assert pattern
- [ ] Use FactoryBot, not fixtures
- [ ] Test service objects thoroughly
- [ ] Use system specs for happy path
- [ ] System tests must fail when JavaScript is broken
- [ ] Test DB constraints, not just validations
- [ ] Use `data-testid` attributes for stable selectors
- [ ] Mock external dependencies (RSpec mocks or VCR)
- [ ] Don't over-test controllers — focus on behavior

```ruby
# ❌ Bad: Code change without specs
# PR contains only: app/services/create_user.rb

# ✅ Good: Code change with corresponding specs
# PR contains:
#   app/services/create_user.rb
#   spec/services/create_user_spec.rb
```

---

## JavaScript & CSS

### JavaScript
- [ ] **Minimize JavaScript** — use only when absolutely necessary
- [ ] **Use Hotwire** (Turbo + Stimulus) for interactivity
- [ ] Prefer server-rendered views
- [ ] No complex frontend build systems unless justified
- [ ] Use vanilla JS and web platform APIs where possible
- [ ] Use import maps or ES Modules
- [ ] Ensure JS behavior covered by system tests

### CSS
- [ ] Every CSS class is a carrying cost — don't let it grow unconstrained
- [ ] Avoid inline styles unless dynamically generated
- [ ] Keep CSS modular, scoped, predictable
- [ ] Avoid `!important` and global overrides

---

## Error Handling

- [ ] Use custom exception classes when appropriate
- [ ] Handle errors gracefully in controllers
- [ ] Log errors appropriately (Rollbar)
- [ ] Provide meaningful error messages
- [ ] **Never swallow exceptions or fail silently**

---

also consider the review ruby code See: [../review-ruby-code/skill.md](../review-ruby-code/skill.md)

## Output Format

```markdown
## Code Review: [filename]

### Summary
Brief overview of code quality and main concerns.

### Issues Found

#### 🔴 Critical
- **[Issue]**: Description
  - Line: X
  - Problem: Explanation
  - Fix: Code suggestion

#### 🟡 Warnings
- **[Issue]**: Description
  - Line: X
  - Suggestion: How to improve

#### 🟢 Suggestions
- Minor improvements and style suggestions

### What's Good
- Highlight positive patterns found

### Recommended Changes
Prioritized list of changes to make.
```

---

## Quick Reference: What to Flag

| Pattern | Status | Alternative |
|---------|--------|-------------|
| Code without specs | 🔴 | Add corresponding specs |
| Single quotes for strings | 🔴 | Use double quotes |
| ERB templates | 🟡 | Prefer HAML |
| Business logic in controller | 🔴 | Use service object |
| Business logic in model | 🔴 | Use service object |
| View logic in controller | 🟡 | Use presenter |
| Callbacks with side effects | 🔴 | Explicit orchestration |
| Multiple instance variables | 🟡 | One per action |
| `unless` with `else` | 🔴 | Use `if` |
| N+1 queries | 🔴 | Use `includes` |
| Missing indexes | 🔴 | Add index |
| Fat controller | 🔴 | Extract to service |
| Inline JS/complex frameworks | 🟡 | Use Hotwire |
| Swallowed exceptions | 🔴 | Handle explicitly |
| `permit!` | 🔴 | Explicit whitelist |
| SQL string interpolation | 🔴 | Use parameterized queries |
| `html_safe` / `raw` in views | 🔴 | Use `content_tag` helpers |
| Production credentials in code | 🔴 | Use env vars / credentials |
| Large data changes in migration | 🟡 | Move to rake task |
| Missing foreign keys | 🟡 | Add foreign key constraints |
| Unused columns | 🟡 | Remove or document |
| Personal preference changes | 🟡 | Create Rubocop issue instead |
