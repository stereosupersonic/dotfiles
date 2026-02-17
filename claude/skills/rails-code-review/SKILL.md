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
- [ ] comments should explain **why**, not **what** — if code is unclear, suggest refactoring instead.
- [ ] avoid useless comments at all costs — they add to carrying cost without value
- [ ] Suggest concrete improvements with code example

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
- [ ] Check for **thread safety issues**:
  - No class-level instance variables (`@var` at class level)
  - No unsynchronized shared mutable state
  - Service objects don't rely on class-level state

### Migration Review
- [ ] For large data manipulations, consider moving to a **rake task** for more control
- [ ] Check if `NOT NULL` constraints make sense
- [ ] ⚠️ **WARNING**: Adding default values to big tables can run a long time
- [ ] No superfluous/unused columns
- [ ] Check if **indexes** make sense, or if any are missing
- [ ] Check if **unique indexes** make sense
- [ ] Check if **foreign keys** make sense

### Gemfile & Dependencies
- [ ] New gems are necessary and well-maintained
- [ ] Gem versions are pinned appropriately (`~>` for patch updates)
- [ ] No duplicate or overlapping gems
- [ ] Security vulnerabilities checked (`bundle audit`)
- [ ] License compatibility verified for commercial projects
- [ ] Gemfile organized by purpose (authentication, testing, assets, etc.)

### Configuration & Environment
- [ ] Sensitive config uses Rails credentials or ENV vars
- [ ] No environment-specific code outside `config/environments/`
- [ ] Feature flags properly implemented (if used)
- [ ] Database configuration uses sensible pool sizes
- [ ] Timezone handling is explicit (`Time.zone`, not `Time.now`)
- [ ] No hardcoded URLs or domain names

### Internationalization
- [ ] User-facing strings use I18n keys, not hardcoded text
- [ ] I18n keys are namespaced logically (`en.controllers.users.create.success`)
- [ ] Pluralization rules defined where needed
- [ ] Date/time formatting uses I18n helpers

### Logging & Observability
- [ ] Appropriate log levels used (debug, info, warn, error)
- [ ] No sensitive data logged (passwords, tokens, PII)
- [ ] Key business events logged for analytics
- [ ] Performance-critical operations instrumented
- [ ] Structured logging used for searchability

### Data Privacy & Compliance
- [ ] PII (Personally Identifiable Information) handling documented
- [ ] Data retention policies implemented where needed
- [ ] User data export capability (if required by law)
- [ ] User data deletion capability (if required by law)
- [ ] Audit trails for sensitive operations

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
- [ ] **Establish a convention**: services either raise on failure OR return result objects — pick one and enforce it consistently across the project

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

### Form Objects
- [ ] Place in `app/forms/` (if used)
- [ ] Name with noun + `Form` format (`UserRegistrationForm`)
- [ ] Include `ActiveModel::Model` or inherit from `BaseForm`
- [ ] Handle validation logic for complex forms
- [ ] Return a result indicating success/failure

```ruby
# ✅ Form object pattern
class UserRegistrationForm
  include ActiveModel::Model

  attr_accessor :email, :password, :terms_accepted

  validates :email, :password, presence: true
  validates :terms_accepted, acceptance: true

  def save
    return false unless valid?
    # Create user and related records
  end
end
```

### Query Objects
- [ ] Place in `app/queries/` (if used)
- [ ] Name descriptively (`ActiveUsersQuery`, `RecentOrdersQuery`)
- [ ] Return an `ActiveRecord::Relation` for chaining
- [ ] Single public method (`.call` or `.all`)
- [ ] Properly scoped and indexed

```ruby
# ✅ Query object pattern
class ActiveUsersQuery
  def self.call(scope = User.all)
    scope
      .where(active: true)
      .where("last_login_at > ?", 30.days.ago)
      .order(last_login_at: :desc)
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

### Concerns & Modules
- [ ] Concerns should be **small and focused** on a single behavior
- [ ] Avoid "junk drawer" concerns that collect unrelated methods
- [ ] Prefer composition (service objects) over deep concern hierarchies
- [ ] Concerns should not depend on specific model implementation details
- [ ] Name concerns after the behavior they provide (`Archivable`, `Searchable`)

```ruby
# ❌ Bad: Junk drawer concern
module UserHelpers
  extend ActiveSupport::Concern

  def full_name; end
  def send_notification; end
  def calculate_discount; end
  def export_to_csv; end
end

# ✅ Good: Focused concern
module Archivable
  extend ActiveSupport::Concern

  included do
    scope :archived, -> { where.not(archived_at: nil) }
    scope :active, -> { where(archived_at: nil) }
  end

  def archive!
    update!(archived_at: Time.zone.now)
  end

  def archived?
    archived_at.present?
  end
end
```

---

## Routing

- [ ] **RESTful routes preferred** over custom routes
- [ ] Avoid deeply nested routes (max 1 level of nesting)
- [ ] No unused/dead routes
- [ ] Use `resources` over individual `get`/`post` definitions
- [ ] Route constraints for parameter validation where applicable
- [ ] API routes namespaced properly (`namespace :api do namespace :v1 do`)
- [ ] Use `only:` or `except:` to limit generated routes to what's actually used
- [ ] Member and collection routes should be rare — prefer new controllers instead

```ruby
# ❌ Bad: Deeply nested and custom routes
resources :companies do
  resources :departments do
    resources :employees do
      member do
        post :activate
        post :deactivate
        get :export
      end
    end
  end
end

# ✅ Good: Shallow nesting, separate controllers for actions
resources :companies, only: %i[index show] do
  resources :departments, only: %i[index show], shallow: true
end

resources :departments do
  resources :employees, only: %i[index create], shallow: true
end

# Separate controller for activation
resources :employee_activations, only: %i[create destroy]
```

---

## Views & Templates

- [ ] **Prefer HAML over ERB**
- [ ] Extract complex views into presenters
- [ ] No database queries in views
- [ ] Use `data-testid` attributes for test selectors

### Accessibility (A11y)
- [ ] Semantic HTML tags used (`<nav>`, `<main>`, `<article>`)
- [ ] Form labels properly associated with inputs
- [ ] ARIA attributes used appropriately
- [ ] Color contrast meets WCAG standards
- [ ] Keyboard navigation works correctly
- [ ] Alt text for images

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

### Enums
- [ ] **Always use explicit hash syntax** for enums to avoid reordering bugs
- [ ] Be aware of auto-generated scopes and bang methods
- [ ] Use `_prefix` or `_suffix` options when enum names could clash

```ruby
# ❌ Bad: Array syntax — reordering will break existing data
enum status: [:draft, :published, :archived]

# ✅ Good: Explicit hash — values are stable
enum status: { draft: 0, published: 1, archived: 2 }

# ✅ Good: With prefix to avoid method name clashes
enum status: { active: 0, inactive: 1 }, _prefix: true
# Generates: status_active?, status_inactive?
```

### Model Validations & DB Constraints
- [ ] `presence:` ↔ `NOT NULL` constraint in DB
- [ ] `uniqueness:` ↔ unique index in DB (note: `validates_uniqueness_of` alone is **not race-condition safe** — always back with a unique index)
- [ ] Length constraints in both model and DB layers
- [ ] Numeric constraints (`numericality:`) matched by DB check constraints where critical

```ruby
# ✅ Good: Both layers
# Migration
add_column :users, :email, :string, null: false
add_index :users, :email, unique: true

# Model
class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
end
```

---

## ActiveRecord Query Safety

- [ ] **Use `find_each` / `in_batches`** for bulk processing instead of `.each` on large sets
- [ ] Avoid `.all` without pagination on large tables
- [ ] Be aware of `pluck` vs `select` trade-offs (`pluck` loads into memory immediately)
- [ ] Check for missing `limit` on unbounded queries
- [ ] Avoid `update_all` / `delete_all` without adequate `where` clauses
- [ ] Use `exists?` instead of `present?` or `any?` for existence checks (avoids loading records)

```ruby
# ❌ Bad: Loads all records into memory
User.all.each { |u| u.update(synced: true) }

# ✅ Good: Processes in batches
User.where(synced: false).find_each(batch_size: 500) do |user|
  user.update(synced: true)
end

# ❌ Bad: Loads records just to check existence
if User.where(email: email).present?

# ✅ Good: SQL-level existence check
if User.where(email: email).exists?

# ❌ Bad: Unbounded delete
User.where(role: "guest").delete_all  # Could delete millions

# ✅ Good: Scoped and controlled
User.where(role: "guest").where("created_at < ?", 1.year.ago).in_batches.delete_all
```

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

### Caching
- [ ] Use fragment caching for expensive view partials
- [ ] Use Russian doll caching for nested associations
- [ ] Cache keys include version/timestamp for automatic expiration
- [ ] Avoid caching user-specific content in shared caches
- [ ] Use `Rails.cache.fetch` with explicit `expires_in` for data caching
- [ ] Low-level caching for expensive computations or API calls

```ruby
# ✅ Good: Fragment caching with touch
# Model
class Comment < ApplicationRecord
  belongs_to :post, touch: true
end

# View (HAML)
- cache @post do
  = render @post.comments

# ✅ Good: Low-level caching
def expensive_stats
  Rails.cache.fetch("user_stats:#{id}", expires_in: 1.hour) do
    calculate_stats
  end
end
```

---

## Background Jobs

- [ ] Use meaningful queue names reflecting priority/purpose
- [ ] **Keep jobs idempotent** — safe to retry
- [ ] Use explicit job classes, not inline jobs
- [ ] Place in `app/jobs/` organized by domain
- [ ] Delegate to service objects
- [ ] **Accept primitive arguments only** (IDs, strings) — not full objects (objects can change between enqueue and execution)
- [ ] Set proper retry counts and dead-set handling
- [ ] Avoid long-running jobs blocking queues
- [ ] Consider unique job constraints if duplicate prevention matters

```ruby
# ❌ Bad: Passing full object — can be stale when executed
class ProcessPaymentJob < ApplicationJob
  def perform(payment)
    payment.process!
  end
end

# ✅ Correct job pattern
class ProcessPaymentJob < ApplicationJob
  queue_as :payments
  sidekiq_options retry: 3

  def perform(payment_id)
    payment = Payment.find(payment_id)
    PaymentProcessor.new(payment).call
  rescue ActiveRecord::RecordNotFound
    # Record deleted between enqueue and execution — safe to skip
    Rails.logger.warn("Payment #{payment_id} not found, skipping")
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

### Serialization
- [ ] Jbuilder templates cached where appropriate
- [ ] Only expose necessary attributes (no over-fetching)
- [ ] Use partial templates for reusable JSON structures
- [ ] Consistent date/time formatting across API
- [ ] Enum values serialized as human-readable strings, not integers

### Serialization Safety
- [ ] **Never use `Marshal.load`** on untrusted data (security risk — allows arbitrary code execution)
- [ ] Use `YAML.safe_load` instead of `YAML.load` (prevents object deserialization attacks)
- [ ] JSON parsing should handle malformed input gracefully with rescue

```ruby
# ❌ CRITICAL: Remote code execution risk
data = Marshal.load(params[:data])

# ❌ CRITICAL: Arbitrary object instantiation
config = YAML.load(user_input)

# ✅ Good: Safe deserialization
config = YAML.safe_load(user_input, permitted_classes: [Date, Time])

# ✅ Good: Safe JSON parsing
begin
  data = JSON.parse(raw_body)
rescue JSON::ParserError => e
  render json: { error: "Invalid JSON" }, status: :bad_request
end
```

---

## Mailers & Notifications

- [ ] Mailers inherit from `ApplicationMailer`
- [ ] Email templates exist for both HTML and plain text
- [ ] Subject lines use I18n keys
- [ ] Mailers tested with email previews (`test/mailers/previews/`)
- [ ] Background jobs used for email delivery (`deliver_later`)
- [ ] Unsubscribe links included where required

```ruby
# ✅ Correct mailer pattern
class UserMailer < ApplicationMailer
  def welcome(user)
    @user = user
    mail(
      to: @user.email,
      subject: I18n.t("mailers.user_mailer.welcome.subject")
    )
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
- [ ] Mock external dependencies (RSpec mocks, VCR, or `webmock`)
- [ ] Don't over-test controllers — focus on behavior
- [ ] Consider `shoulda-matchers` for concise association/validation specs

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

## Asset Pipeline & Importmaps

- [ ] Assets organized logically (images, stylesheets, JavaScript)
- [ ] Production asset precompilation verified
- [ ] Images optimized for web (compressed, appropriate format)
- [ ] Use lazy loading for below-the-fold images
- [ ] No unused assets checked in
- [ ] Importmap pins are version-locked

---

## Error Handling

- [ ] Use custom exception classes when appropriate
- [ ] Handle errors gracefully in controllers
- [ ] Log errors appropriately (Rollbar)
- [ ] Provide meaningful error messages
- [ ] **Never swallow exceptions or fail silently**

---

## Deployment & Zero-Downtime Migrations

Migrations must be **backward-compatible** with the currently running code. This is critical for zero-downtime deployments.

- [ ] **Never rename columns directly** — add new column, migrate data, update code, remove old column in separate deploys
- [ ] **Never remove columns** that running code still references — remove code references first, deploy, then remove column
- [ ] Use `strong_migrations` gem to automatically catch unsafe migration patterns
- [ ] Adding an index on a large table should use `algorithm: :concurrently` (Postgres)
- [ ] Data migrations belong in rake tasks, not in schema migrations
- [ ] Test migrations against a production-sized dataset to estimate runtime

```ruby
# ❌ Bad: Renaming a column in one step — breaks running code during deploy
class RenameUserNameToFullName < ActiveRecord::Migration[7.1]
  def change
    rename_column :users, :name, :full_name
  end
end

# ✅ Good: Multi-step safe rename
# Step 1 (Deploy 1): Add new column
class AddFullNameToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :full_name, :string
  end
end

# Step 2: Backfill data (rake task, not migration)
# Step 3 (Deploy 2): Update code to use full_name, write to both columns
# Step 4 (Deploy 3): Remove old column
class RemoveNameFromUsers < ActiveRecord::Migration[7.1]
  def change
    safety_assured { remove_column :users, :name }
  end
end
```

---

## PR & Code Hygiene

- [ ] **PRs should be small and focused** — one concern per PR
- [ ] Commit messages are meaningful and explain *why*, not just *what*
- [ ] No unrelated changes bundled into a PR
- [ ] Draft PRs used for early feedback on architecture decisions
- [ ] PR description explains context, links to ticket/issue
- [ ] Reviewer checklist completed before requesting review
- [ ] No TODO/FIXME without a linked issue or ticket
- [ ] Dead code removed — don't leave commented-out code in the codebase

---

## Websockets / ActionCable

If ActionCable is used:
- [ ] Channel authorization properly implemented
- [ ] Stream names follow a consistent naming convention
- [ ] Connection authentication verified (`connect` method)
- [ ] Broadcasts scoped to appropriate audience
- [ ] No sensitive data broadcast to unauthorized subscribers
- [ ] Disconnection and cleanup handled properly

```ruby
# ✅ Correct ActionCable pattern
class ChatChannel < ApplicationCable::Channel
  def subscribed
    chat = Chat.find(params[:id])
    reject unless current_user.can_access?(chat)
    stream_for chat
  end

  def unsubscribed
    stop_all_streams
  end
end
```

---

## Rails Version Compatibility

- [ ] No deprecated Rails methods used
- [ ] Check for breaking changes in target Rails version
- [ ] Gems compatible with current/target Rails version
- [ ] No monkey patches that could break on upgrade

---

## Common Code Smells to Flag

- [ ] **God objects**: Classes with too many responsibilities (>200 lines)
- [ ] **Long methods**: Methods over 10-15 lines
- [ ] **Long parameter lists**: More than 3-4 parameters
- [ ] **Feature envy**: Method using another object's data more than its own
- [ ] **Primitive obsession**: Using primitives instead of small objects
- [ ] **Data clumps**: Same group of variables appearing together repeatedly
- [ ] **Shotgun surgery**: Single change requires edits across many files

---

## Thread Safety & Concurrency

Rails applications run in multi-threaded environments (Puma, Sidekiq). Thread-unsafe code can cause race conditions, data corruption, and intermittent bugs.

### Class-Level Instance Variables (Most Common Issue)
- [ ] **Never use class-level instance variables** (`@variable` at class level)
- [ ] Use class variables (`@@variable`) or class instance variables carefully
- [ ] Prefer `thread_mattr_accessor` or `class_attribute` for thread-safe class-level state
- [ ] Use `RequestStore` or `Current` attributes for request-scoped data

```ruby
# ❌ CRITICAL: Not thread-safe - will cause race conditions
class UserService
  @current_user = nil  # Class instance variable - DANGEROUS

  def self.process(user)
    @current_user = user  # Race condition! Multiple threads will overwrite this
    # ... logic using @current_user
  end
end

# ❌ CRITICAL: Not thread-safe - shared mutable state
class CacheManager
  @@cache = {}  # Class variable - shared across threads, not thread-safe

  def self.store(key, value)
    @@cache[key] = value  # Race condition!
  end
end

# ✅ Good: Use Rails thread-safe alternatives
class UserService
  thread_mattr_accessor :current_user  # Thread-safe storage

  def self.process(user)
    self.current_user = user
    # ... logic
  ensure
    self.current_user = nil  # Clean up
  end
end

# ✅ Good: Use RequestStore for request-scoped data
class UserService
  def self.process(user)
    RequestStore.store[:current_user] = user
    # ... logic
  end
end

# ✅ Good: Use Rails Current attributes
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :request_id
end

class UserService
  def self.process(user)
    Current.user = user
    # ... logic
  end
end

# ✅ Good: Pass as parameter (best approach)
class UserService
  def self.process(user)
    new(user).call
  end

  def initialize(user)
    @user = user  # Instance variable - safe
  end

  def call
    # ... logic using @user
  end
end
```

### Common Thread Safety Issues

#### 1. Memoization Without Synchronization
```ruby
# ❌ Bad: Race condition in memoization
def config
  @config ||= load_config  # Multiple threads can call load_config
end

# ✅ Good: Thread-safe memoization
def config
  @config ||= Concurrent::LazyRegister.new { load_config }
end

# ✅ Good: Use Rails.cache for shared data
def config
  Rails.cache.fetch("app_config", expires_in: 1.hour) do
    load_config
  end
end
```

#### 2. Shared Mutable Collections
```ruby
# ❌ Bad: Shared array modified by multiple threads
class EventTracker
  @@events = []  # Not thread-safe

  def self.track(event)
    @@events << event  # Race condition!
  end
end

# ✅ Good: Use thread-safe data structures
require "concurrent"

class EventTracker
  @events = Concurrent::Array.new

  def self.track(event)
    @events << event  # Thread-safe
  end
end

# ✅ Better: Use proper logging/event system
class EventTracker
  def self.track(event)
    Rails.logger.info("Event: #{event}")
    # or use proper event tracking service
  end
end
```

#### 3. Lazy Initialization in Class Methods
```ruby
# ❌ Bad: Not thread-safe initialization
class ApiClient
  def self.instance
    @instance ||= new  # Race condition!
  end
end

# ✅ Good: Use Rails' thread-safe class_attribute
class ApiClient
  class_attribute :_instance

  def self.instance
    self._instance ||= new
  end
end

# ✅ Better: Use proper singleton pattern
class ApiClient
  include Singleton

  def call
    # ... API logic
  end
end
```

#### 4. Global State Modification
```ruby
# ❌ Bad: Modifying global/class state
class FeatureFlag
  @@enabled_features = Set.new

  def self.enable(feature)
    @@enabled_features << feature  # Not thread-safe
  end

  def self.enabled?(feature)
    @@enabled_features.include?(feature)
  end
end

# ✅ Good: Use database or Rails.cache
class FeatureFlag
  def self.enable(feature)
    Rails.cache.write("feature:#{feature}", true)
  end

  def self.enabled?(feature)
    Rails.cache.read("feature:#{feature}") || false
  end
end
```

### Thread Safety Checklist
- [ ] No class-level instance variables (`@var` at class level)
- [ ] No unsynchronized class variables (`@@var`)
- [ ] No shared mutable state between requests
- [ ] Memoization uses thread-safe approaches
- [ ] Class methods don't rely on shared state
- [ ] Use `thread_mattr_accessor` or `class_attribute` for class-level storage
- [ ] Use `Current` attributes or `RequestStore` for request-scoped data
- [ ] Background jobs don't share state across instances
- [ ] Service objects receive dependencies as parameters
- [ ] Singleton patterns use proper synchronization

### When Thread Safety Matters Most
- Background job processors (Sidekiq runs multi-threaded)
- Service objects called from multiple threads
- Class-level caching or memoization
- API clients and external service wrappers
- Any code that modifies class-level state
- Concern modules included in multiple classes

### Safe Patterns Summary
```ruby
# ✅ SAFE: Instance variables in instance methods
class UserService
  def initialize(user)
    @user = user  # Safe - each instance has its own
  end
end

# ✅ SAFE: Local variables
def process
  user = User.find(params[:id])  # Safe - method scope
end

# ✅ SAFE: Constants
class Config
  API_ENDPOINT = "https://api.example.com"  # Safe - immutable
end

# ✅ SAFE: Database/cache for shared state
def config
  Rails.cache.fetch("config") { load_config }
end

# ✅ SAFE: Thread-local storage
Thread.current[:user] = user

# ✅ SAFE: RequestStore (request-scoped)
RequestStore.store[:user] = user

# ✅ SAFE: Current attributes (request-scoped)
Current.user = user
```

---

also consider the review ruby code See: [../review-ruby-code/skill.md](../review-ruby-code/skill.md)

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
| `Time.now` | 🟡 | Use `Time.zone.now` |
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
| Hardcoded strings in views | 🟡 | Use I18n keys |
| God objects (>200 lines) | 🔴 | Split responsibilities |
| Methods >15 lines | 🟡 | Extract smaller methods |
| Logging sensitive data | 🔴 | Filter or exclude PII |
| Missing email plain text template | 🟡 | Add text version |
| Enums as integers in API | 🟡 | Serialize as strings |
| No audit trail for sensitive ops | 🟡 | Add logging/tracking |
| Deprecated Rails methods | 🔴 | Update to current API |
| Primitive obsession | 🟡 | Use value objects |
| Hardcoded URLs/domains | 🟡 | Use config/ENV vars |
| Environment-specific code outside config | 🔴 | Move to `config/environments/` |
| Insecure gem versions | 🔴 | Update and run `bundle audit` |
| Class-level instance variables (`@var` at class level) | 🔴 | Use `thread_mattr_accessor`, `Current`, or pass as parameter |
| Unsynchronized class variables (`@@var`) | 🔴 | Use thread-safe alternatives or database |
| Shared mutable state | 🔴 | Use `RequestStore`, `Current`, or Rails.cache |
| Unsafe memoization in class methods | 🔴 | Use thread-safe memoization or cache |
| Global state modification | 🔴 | Use database or proper state management |
| Enum with array syntax | 🔴 | Use explicit hash syntax |
| `.each` on large dataset | 🟡 | Use `find_each` / `in_batches` |
| `.present?` for existence check | 🟡 | Use `.exists?` |
| `Marshal.load` on untrusted data | 🔴 | Never — remote code execution risk |
| `YAML.load` on user input | 🔴 | Use `YAML.safe_load` |
| Column rename in single migration | 🔴 | Multi-step safe rename |
| Full objects passed to jobs | 🟡 | Pass IDs (primitives) only |
| Junk drawer concerns | 🟡 | Split into focused concerns |
| Deeply nested routes (>1 level) | 🟡 | Flatten with `shallow:` or new controllers |
| TODOs/FIXMEs without linked issue | 🟡 | Link to ticket or remove |
| Commented-out dead code | 🟡 | Remove — use version control |
| Unbounded `delete_all` / `update_all` | 🔴 | Add proper `where` scope |
| Missing `strong_migrations` gem | 🟢 | Add for migration safety checks |