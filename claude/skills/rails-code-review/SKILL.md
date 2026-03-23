---
name: rails-code-review
description: Rails code review skill following Konvenit guidelines. Use when the user asks to review Rails code, check for best practices, audit controllers/models/views, or wants feedback on their Rails application code. Triggers on phrases like "review my code", "check this controller", "audit my Rails app", "code review", "best practices check". Enforces service objects, presenters, HAML, double quotes, and Konvenit-specific patterns.
---

# Rails Code Review Skill (Konvenit Guidelines)

Perform thorough code reviews following Konvenit's Rails development standards.

## Rules Reference

All coding standards are defined in `~/.claude/rules/`. Read and apply these during every review:

- `rails_developer.md` — General rules for a Rails developer
- `ruby.md` — Ruby style, formatting, naming, control flow, collections, strings
- `architecture.md` — Service objects, presenters, finders, form objects, namespacing, file structure
- `documentation.md` — How to document and write comments
- `migrations.md` — Rails database migrations,
- `database.md` — ActiveRecord, queries, transactions, constraints
- `views.md` — HAML, templates, I18n
- `testing.md` — RSpec, testing philosophy, system tests
- `backend.md` —  error handling, performance
- `api.md` — API development
- `jobs.md` — Background jobs
- `controllers.md` — Rails Controllers. the C of MVC
- `models.md` — Rails models. the M of MVC
- `security.md` — Authentication, authorization, security best practices
- `frontend.md` — JavaScript, CSS, Hotwire/Turbo/Stimulus
- `git.md` — Git workflow, documentation, comment guidelines

---

## Review Process

1. Read the code carefully
2. Check against each rule category and the checklists below
3. Provide specific, actionable feedback with line references
4. Suggest concrete improvements with code examples
5. Prioritize issues: 🔴 Critical, 🟡 Warning, 🟢 Suggestion

### General Principles
- [ ] Code follows Konvenit Guidelines (see rules files above)
- [ ] Code is maintainable — classes are well-structured and properly named
- [ ] If you have trouble understanding concepts, flag it — this indicates structure can be improved
- [ ] **Avoid requesting changes based on personal preference** — create Rubocop issue instead
- [ ] Check if changes could **unintentionally break production** or have undesirable consequences for users
- [ ] Verify all changes are covered by at least some tests to catch simple runtime exceptions
- [ ] Comments should explain **why**, not **what** — if code is unclear, suggest refactoring instead
- [ ] Avoid useless comments at all costs — they add to carrying cost without value
- [ ] Suggest concrete improvements with code examples
- [ ] No spelling or grammar errors in code or comments

---

## SOLID Principles

Check code against all five SOLID principles during review.

### Single Responsibility Principle (SRP)
- [ ] Each class has **one, and only one, reason to change**
- [ ] Class name clearly describes its single purpose
- [ ] No class names containing "And", "Manager", or "Handler" (smell for multiple responsibilities)
- [ ] Methods within a class operate on the same data/concern

```ruby
# Bad: Multiple responsibilities in one class
class User < ApplicationRecord
  validates :email, presence: true

  def send_welcome_email       # Notification concern
    UserMailer.welcome_email(self).deliver_now
  end

  def generate_activity_report  # Reporting concern
    activities.map { |a| "#{a.created_at}: #{a.description}" }.join("\n")
  end

  def sync_to_crm               # External integration concern
    CrmApi.create_contact(email: email, name: name)
  end
end

# Good: Each class has one responsibility
class User < ApplicationRecord
  validates :email, presence: true
end

class UserNotifier
  def initialize(user)
    @user = user
  end

  def send_welcome_email
    UserMailer.welcome_email(@user).deliver_now
  end
end

class UserCrmSync
  def initialize(user)
    @user = user
  end

  def sync
    CrmApi.create_contact(email: @user.email, name: @user.name)
  end
end
```

### Open/Closed Principle (OCP)
- [ ] Code is **open for extension, closed for modification**
- [ ] No long `case`/`if-elsif` chains that grow with new types
- [ ] Use polymorphism or strategy pattern where behavior varies by type

```ruby
# Bad: Must modify existing code for each new format
class ReportGenerator
  def generate(report_type, data)
    case report_type
    when :pdf then generate_pdf(data)
    when :csv then generate_csv(data)
    end
  end
end

# Good: New formats added without modifying existing code
class ReportService
  def initialize(generator)
    @generator = generator
  end

  def create_report(data)
    @generator.generate(data)
  end
end

class PdfReportGenerator
  def generate(data)
    # PDF logic
  end
end
```

### Liskov Substitution Principle (LSP)
- [ ] Subclasses are **substitutable** for their parent class without breaking behavior
- [ ] No type checking (`is_a?`, `kind_of?`) before calling methods
- [ ] Subclasses don't remove or restrict parent functionality
- [ ] Subclasses don't throw exceptions the parent doesn't throw

### Interface Segregation Principle (ISP)
- [ ] No class is forced to implement methods it doesn't use
- [ ] Concerns/modules are **small and focused** on a single behavior
- [ ] No empty or no-op method implementations to satisfy an interface

### Dependency Inversion Principle (DIP)
- [ ] High-level modules **don't depend on low-level modules** — both depend on abstractions
- [ ] No direct instantiation of hard-coded dependencies
- [ ] Dependencies are injected, making code testable and swappable

```ruby
# Bad: Tightly coupled
class OrderProcessor
  def process(order)
    payment = StripePaymentGateway.new
    payment.charge(order.amount)
  end
end

# Good: Dependencies injected
class OrderProcessor
  def initialize(payment_gateway:)
    @payment_gateway = payment_gateway
  end

  def process(order)
    @payment_gateway.charge(order.amount)
  end
end
```

---

## Law of Demeter

**"Only talk to your immediate friends"** — an object should only call methods on itself, its parameters, objects it creates, or its direct instance variables.

- [ ] No **train wrecks** (chained method calls through multiple objects)
- [ ] Use `delegate` or wrapper methods to hide navigation

```ruby
# Bad: Train wreck — reaching through objects
order.user.shipping_address.city.tax_rate
@post.author.profile.avatar_url

# Good: Delegation hides the chain
class Order
  delegate :tax_rate, to: :user
end

# Good: Rails delegate with prefix
class Post < ApplicationRecord
  delegate :avatar_url, to: :author, prefix: true
  # Generates: post.author_avatar_url
end
```

---

## Konvenit-Specific Patterns

### Authentication & Authorization
- [ ] Use `authentifikator` gem for authentication
- [ ] Use `cancancan` for authorization
- [ ] Define rules in `Authorization::Ability`
- [ ] Use `web_access` block for authentication
- [ ] Use `check_authorization` and `authorize_resource`
- [ ] **Authorization checks on ALL actions** that modify data
- [ ] **Server-side authorization always** — never rely on client-side hiding alone
- [ ] Scope queries to current user where appropriate

```ruby
# Correct auth pattern
class InvitationsController < ApplicationController
  web_access do
    allow_logged_in :employee
    allow_logged_in :client, if: :team_group_admin?
  end

  check_authorization
  authorize_resource :invitation
end
```

```ruby
# Bad: Authorization only in view — server is unprotected
<% if current_user.admin? %>
  <%= link_to "Delete", post_path(@post), method: :delete %>
<% end %>

# Good: Server-side authorization
def destroy
  @post = Post.find(params[:id])
  authorize! :destroy, @post
  @post.destroy
  redirect_to posts_path
end
```

### Enums
- [ ] **Always use explicit hash syntax** for enums to avoid reordering bugs
- [ ] Use `_prefix` or `_suffix` options when enum names could clash

```ruby
# Bad: Array syntax — reordering will break existing data
enum status: [:draft, :published, :archived]

# Good: Explicit hash — values are stable
enum status: { draft: 0, published: 1, archived: 2 }

# Good: With prefix to avoid method name clashes
enum status: { active: 0, inactive: 1 }, _prefix: true
```

### Callback Rules

**Acceptable callbacks** (data normalization within the same record):
```ruby
# OK: Normalizing data before validation
before_validation :normalize_email

# OK: Setting calculated fields on the same record
before_save :generate_slug
```

**Unacceptable callbacks** (side effects, external calls, other models):
```ruby
# Bad: Email sending, API calls, updating other models in callbacks
after_create :send_welcome_email
after_save :sync_to_crm
after_create :update_post_stats

# Good: Explicit orchestration in service
class CreateUser < BaseService
  def call
    user = User.create!(params)
    UserMailer.welcome(user).deliver_later
    DefaultSettings.create_for(user)
    user
  end
end
```

**If you must use callbacks for side effects, prefer `after_commit`** (transaction-aware).

### Concerns & Modules
- [ ] Concerns should be **small and focused** on a single behavior
- [ ] Avoid "junk drawer" concerns that collect unrelated methods
- [ ] Prefer composition (service objects) over deep concern hierarchies
- [ ] Name concerns after the behavior they provide (`Archivable`, `Searchable`)

---

## Security Review Checklist

In addition to the rules in `security.md`, check for these patterns:

### SQL Injection Detection
```ruby
# Bad — string interpolation in SQL
User.where("email = '#{params[:email]}'")
User.find_by_sql("SELECT * FROM users WHERE id = #{params[:id]}")
ActiveRecord::Base.connection.execute("DELETE FROM posts WHERE id = #{params[:id]}")

# Good
User.where("email = ?", params[:email])
User.where(email: params[:email])
User.where("email = :email", email: params[:email])
```

### XSS Detection
```ruby
# Bad
<%= params[:message].html_safe %>
<%= raw @comment.body %>
<script>var msg = "<%= @message %>";</script>

# Good
<%= @user.bio %>                                          # Rails auto-escapes
<%= sanitize @comment.body, tags: %w(strong em a) %>      # Controlled allowlist
<script>var msg = <%= @message.to_json %>;</script>        # JSON-escaped
```

### Mass Assignment Detection
```ruby
# Bad
params.require(:user).permit!
User.create(params[:user])
params[:product].each { |k, v| product.send("#{k}=", v) }

# Good: Conditional permissions for role-based access
def user_params
  if current_user.admin?
    params.expect(user: [:name, :email, :role, :status])
  else
    params.expect(user: [:name, :email])
  end
end
```

### Serialization Safety
- [ ] **Never use `Marshal.load`** on untrusted data (remote code execution risk)
- [ ] Use `YAML.safe_load` instead of `YAML.load`
- [ ] JSON parsing should handle malformed input gracefully

### Thread Safety
- [ ] No class-level instance variables (`@var` at class level)
- [ ] No unsynchronized class variables (`@@var`)
- [ ] No shared mutable state between requests
- [ ] Memoization uses thread-safe approaches
- [ ] Use `Current` attributes or `RequestStore` for request-scoped data
- [ ] Service objects receive dependencies as parameters (safest approach)

```ruby
# Bad: Not thread-safe
class UserService
  @current_user = nil

  def self.process(user)
    @current_user = user  # Race condition!
  end
end

# Good: Pass as parameter
class UserService
  def initialize(user)
    @user = user  # Instance variable — safe
  end

  def call
    # logic using @user
  end
end

# Good: Use Current attributes for request-scoped data
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :request_id
end
```

### CSRF & Session
- [ ] `protect_from_forgery` enabled
- [ ] State-changing actions use POST/PUT/DELETE, never GET
- [ ] Session reset on login (prevent session fixation)
- [ ] Secure cookie settings in production

### File Upload Security
- [ ] Validate file types by actual content, not just client-provided content type
- [ ] Limit file sizes
- [ ] Store uploads outside web root

---

## Deployment & Zero-Downtime Migrations

Migrations must be **backward-compatible** with the currently running code.

- [ ] **Never rename columns directly** — add new, migrate data, update code, remove old (separate deploys)
- [ ] **Never remove columns** that running code still references
- [ ] Use `strong_migrations` gem to catch unsafe migration patterns
- [ ] Adding indexes on large tables should use `algorithm: :concurrently` (Postgres)
- [ ] Data migrations belong in rake tasks, not schema migrations

```ruby
# Bad: Renaming a column in one step — breaks running code during deploy
rename_column :users, :name, :full_name

# Good: Multi-step safe rename
# Deploy 1: Add new column
add_column :users, :full_name, :string
# Backfill data (rake task)
# Deploy 2: Update code to use full_name, write to both
# Deploy 3: Remove old column
safety_assured { remove_column :users, :name }
```

---

## Accessibility (A11y)

- [ ] Semantic HTML tags used (`<nav>`, `<main>`, `<article>`)
- [ ] Form labels properly associated with inputs
- [ ] ARIA attributes used appropriately
- [ ] Color contrast meets WCAG standards
- [ ] Keyboard navigation works correctly
- [ ] Alt text for images

---

## Gemfile & Dependencies

- [ ] New gems are necessary and well-maintained
- [ ] Gem versions are pinned appropriately (`~>` for patch updates)
- [ ] No duplicate or overlapping gems
- [ ] Security vulnerabilities checked (`bundle audit`)
- [ ] License compatibility verified for commercial projects

---

## Configuration & Environment

- [ ] Sensitive config uses Rails credentials or ENV vars
- [ ] No environment-specific code outside `config/environments/`
- [ ] No hardcoded URLs or domain names

---

## Logging & Observability

- [ ] Appropriate log levels used (debug, info, warn, error)
- [ ] No sensitive data logged (passwords, tokens, PII)
- [ ] Key business events logged for analytics
- [ ] Structured logging used for searchability

---

## Data Privacy & Compliance

- [ ] PII handling documented
- [ ] Data retention policies implemented where needed
- [ ] Audit trails for sensitive operations

---

## Common Code Smells to Flag

- [ ] **God objects**: Classes with too many responsibilities (>200 lines)
- [ ] **Long methods**: Methods over 10-15 lines
- [ ] **Long parameter lists**: More than 3-4 parameters — introduce parameter object
- [ ] **Feature envy**: Method using another object's data more than its own
- [ ] **Primitive obsession**: Using primitives instead of small objects
- [ ] **Data clumps**: Same group of variables appearing together repeatedly
- [ ] **Shotgun surgery**: Single change requires edits across many files
- [ ] **Train wrecks**: Chained method calls violating Law of Demeter

---

## PR & Code Hygiene

- [ ] **PRs should be small and focused** — one concern per PR
- [ ] Commit messages are meaningful and explain *why*, not just *what*
- [ ] No unrelated changes bundled into a PR
- [ ] PR description explains context, links to ticket/issue
- [ ] No TODO/FIXME without a linked issue or ticket
- [ ] Dead code removed — don't leave commented-out code

---

## Websockets / ActionCable

If ActionCable is used:
- [ ] Channel authorization properly implemented
- [ ] Stream names follow a consistent naming convention
- [ ] Connection authentication verified
- [ ] No sensitive data broadcast to unauthorized subscribers

---

Also consider the review ruby code skill. See: [../review-ruby-code/skill.md](../review-ruby-code/skill.md)

## Output Format

```markdown
## Code Review: [filename]

### Summary
Brief overview of code quality and main concerns.

### Metrics Summary
- Total issues: X
- Critical: X | Warnings: X | Suggestions: X
- Files reviewed: X
- Test coverage: X% (if available)

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

### Dependencies Changed (if applicable)
- Added: [list]
- Updated: [list]
- Removed: [list]
- Security concerns: [list]

### Recommended Changes
Prioritized list of changes to make.

### Next Steps
1. [Prioritized action items]
2. ...
```

---

## Quick Reference: What to Flag

| Pattern | Status | Alternative |
|---------|--------|-------------|
| Code without specs | 🔴 | Add corresponding specs |
| Single quotes for strings | 🔴 | Use double quotes |
| `Time.now` | 🟡 | Use `Time.current` |
| ERB templates | 🟡 | Prefer HAML |
| Business logic in controller | 🔴 | Use service object |
| Business logic in model | 🔴 | Use service object |
| View logic in controller | 🟡 | Use presenter |
| Callbacks with side effects | 🔴 | Explicit orchestration |
| Multiple instance variables | 🟡 | One per action |
| `unless` with `else` | 🔴 | Use `if` |
| N+1 queries | 🔴 | Use `includes` / `preload` / `eager_load` |
| Missing indexes | 🔴 | Add index |
| Fat controller | 🔴 | Extract to service |
| Inline JS/complex frameworks | 🟡 | Use Hotwire |
| Swallowed exceptions | 🔴 | Handle explicitly |
| `permit!` | 🔴 | Explicit whitelist |
| SQL string interpolation | 🔴 | Use parameterized queries |
| `html_safe` / `raw` in views | 🔴 | Use `content_tag` / `sanitize` |
| Production credentials in code | 🔴 | Use env vars / credentials |
| Large data changes in migration | 🟡 | Move to rake task |
| Missing foreign keys | 🟡 | Add foreign key constraints |
| Unused columns | 🟡 | Remove or document |
| Personal preference changes | 🟡 | Create Rubocop issue instead |
| Hardcoded strings in views | 🟡 | Use I18n keys |
| God objects (>200 lines) | 🔴 | Split responsibilities |
| Methods >15 lines | 🟡 | Extract smaller methods |
| Logging sensitive data | 🔴 | Filter or exclude PII |
| Missing email plain text template | 🟡 | Add text version |
| Enums as integers in API | 🟡 | Serialize as strings |
| Enum with array syntax | 🔴 | Use explicit hash syntax |
| Deprecated Rails methods | 🔴 | Update to current API |
| Class-level instance variables | 🔴 | Use `Current`, `RequestStore`, or pass as parameter |
| Shared mutable state | 🔴 | Use thread-safe alternatives |
| `Marshal.load` on untrusted data | 🔴 | Never — remote code execution risk |
| `YAML.load` on user input | 🔴 | Use `YAML.safe_load` |
| Column rename in single migration | 🔴 | Multi-step safe rename |
| Full objects passed to jobs | 🟡 | Pass IDs (primitives) only |
| Junk drawer concerns | 🟡 | Split into focused concerns |
| Deeply nested routes (>1 level) | 🟡 | Flatten with `shallow:` or new controllers |
| TODOs/FIXMEs without linked issue | 🟡 | Link to ticket or remove |
| Commented-out dead code | 🟡 | Remove — use version control |
| Unbounded `delete_all` / `update_all` | 🔴 | Add proper `where` scope |
| State-changing action via GET | 🔴 | Use POST/PUT/DELETE |
| Client-side-only authorization | 🔴 | Add server-side checks |
| `>4` method parameters | 🟡 | Introduce parameter object |
| Train wreck (chained dots) | 🟡 | Use `delegate` (Law of Demeter) |
| `has_and_belongs_to_many` | 🟡 | Use `has_many :through` |
| Missing `dependent:` on associations | 🟡 | Always specify |
| Don't order by `id` | 🟡 | Use `created_at` |
| Nullable boolean columns | 🟡 | Add `default:` + `null: false` |
| `travel_to(Time.current)` | 🟡 | Use `freeze_time` |
| Instance variables in partials | 🟡 | Pass locals instead |
