# Rails Models (ActiveRecord)

## Quick Reference

| Pattern | Example |
|---------|---------|
| **Model Generation** | `rails g model User name:string email:string` |
| **Migration** | `rails g migration AddAgeToUsers age:integer` |
| **Validation** | `validates :email, presence: true, uniqueness: true` |
| **Association** | `has_many :posts, dependent: :destroy` |
| **Callback** | `before_save :normalize_email` |
| **Scope** | `scope :active, -> { where(active: true) }` |
| **Query** | `User.where(active: true).order(created_at: :desc)` |

## Model Organization Order

Declare model internals in this order for consistency:

```ruby
class Cloud < ApplicationRecord
  # 1. Gems/DSL extensions
  include Turbo::Broadcastable
  has_paper_trail

  # 2. Associations
  belongs_to :participant
  has_many :cards, dependent: :destroy
  has_one_attached :image

  # 3. Enums
  enum :state, { uploaded: "uploaded", analyzing: "analyzing", generated: "generated", failed: "failed" }

  # 4. Normalizations (Rails 7.1+)
  normalizes :email, with: ->(e) { e.strip.downcase }

  # 5. Validations
  validates :title, presence: true, length: { maximum: 100 }

  # 6. Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :pending, -> { where(state: %i[uploaded analyzing]) }

  # 7. Callbacks
  before_create :generate_slug
  after_commit :broadcast_update, on: :update

  # 8. Delegated methods
  delegate :email, to: :participant, prefix: true

  # 9. Public instance methods
  def ready?
    generated? && cards.any?
  end

  # 10. Private methods
  private

  def generate_slug
    self.slug ||= title.parameterize
  end
end
```

## Model Definition

```ruby
class User < ApplicationRecord
  # Constants
  ROLES = %w[admin user guest].freeze

  # Associations
  has_many :posts, dependent: :destroy
  has_many :comments
  belongs_to :organization, optional: true

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true, length: { minimum: 2 }
  validates :role, inclusion: { in: ROLES }

  # Callbacks (database lifecycle only — never queue jobs or send emails here)
  before_save :normalize_email

  # Scopes
  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }

  # Class methods
  def self.search(query)
    where("name ILIKE ?", "%#{query}%")
  end

  # Instance methods
  def full_name
    "#{first_name} #{last_name}"
  end

  private

  def normalize_email
    self.email = email.downcase.strip
  end
end
```

## Migrations

### Creating Tables

```ruby
class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.boolean :active, default: true
      t.integer :role, default: 0
      t.references :organization, foreign_key: true

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
```

### Modifying Tables

```ruby
class AddFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :bio, :text
    add_column :users, :avatar_url, :string
    add_reference :users, :manager, foreign_key: { to_table: :users }

    change_column_null :users, :email, false
    change_column_default :users, :active, from: nil, to: true
  end
end
```

## Validations

**Validations vs Database Constraints:**
- Database constraints guarantee data integrity — they are the only true guarantee
- Rails validations provide user experience (friendly error messages via `.errors`)
- `validates_uniqueness_of` does **not** guarantee uniqueness — always back it with a database unique index
- `update_column`/`update_columns` bypasses validations — design your system knowing this
- Don't test simple single-line validations (presence, format, inclusion) — they're config, not logic. Only test complex or custom validators.

**ActiveModel for non-DB resources:**
- Use `ActiveModel` for resources not backed by a database table
- ActiveModel supports validations, making it work seamlessly with Rails form helpers and error display

```ruby
class User < ApplicationRecord
  # Presence
  validates :email, presence: true

  # Uniqueness — ALWAYS back with a DB unique index
  validates :email, uniqueness: { case_sensitive: false }
  validates :username, uniqueness: { scope: :organization_id }

  # Format
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, format: { with: /\A\d{10}\z/ }

  # Length
  validates :name, length: { minimum: 2, maximum: 50 }
  validates :bio, length: { maximum: 500 }

  # Numericality
  validates :age, numericality: { greater_than: 0, less_than: 150 }

  # Inclusion/Exclusion
  validates :role, inclusion: { in: ROLES }
  validates :username, exclusion: { in: %w[admin root] }

  # One attribute per validation — don't group unrelated attributes
  # Bad:  validates :email, :password, presence: true
  # Good: separate lines per attribute (as shown above)

  # Custom validation
  validate :email_domain_allowed

  private

  def email_domain_allowed
    return if email.blank?
    domain = email.split('@').last
    unless %w[example.com company.com].include?(domain)
      errors.add(:email, "must be from an allowed domain")
    end
  end
end
```

## Associations

```ruby
# One-to-Many
class Author < ApplicationRecord
  has_many :books, dependent: :destroy
  has_many :published_books, -> { where(published: true) }, class_name: 'Book'
end

class Book < ApplicationRecord
  belongs_to :author
end

# Many-to-Many (has_and_belongs_to_many)
class Student < ApplicationRecord
  has_and_belongs_to_many :courses
end

class Course < ApplicationRecord
  has_and_belongs_to_many :students
end

# Many-to-Many (has_many :through)
class Student < ApplicationRecord
  has_many :enrollments
  has_many :courses, through: :enrollments
end

class Enrollment < ApplicationRecord
  belongs_to :student
  belongs_to :course
end

class Course < ApplicationRecord
  has_many :enrollments
  has_many :students, through: :enrollments
end

# One-to-One
class User < ApplicationRecord
  has_one :profile, dependent: :destroy
end

class Profile < ApplicationRecord
  belongs_to :user
end

# Polymorphic
class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
end

class Post < ApplicationRecord
  has_many :comments, as: :commentable
end

class Photo < ApplicationRecord
  has_many :comments, as: :commentable
end
```


## Scopes and Queries

When a scope lambda becomes too complex to read, convert it to a class method returning a relation:

```ruby
# Scope is fine for simple cases
scope :published, -> { where(published: true) }
scope :recent, -> { order(created_at: :desc) }

# Complex logic → class method
def self.created_between(start_date, end_date)
  where(created_at: start_date..end_date)
    .joins(:author)
    .where(authors: { active: true })
end
```

### Scope Naming Conventions

Follow consistent naming patterns for scopes:

| Pattern | Purpose | Example |
|---------|---------|---------|
| `with_*` | Eager load associations | `with_creator`, `with_attachments` |
| `preloaded` | Full eager load for view rendering | `preloaded` (all associations) |
| `chronologically` | Oldest first ordering | `chronologically` |
| `reverse_chronologically` | Newest first ordering | `reverse_chronologically` |
| `latest` | Single most recent record | `latest` |
| `page_before` / `page_after` | Cursor-based pagination | `page_before(cursor)` |
| `indexed_by_*` | Hash lookup by key | `indexed_by_room` |
| `excluding` | Filter out records | `excluding(user)` |

```ruby
class Message < ApplicationRecord
  scope :with_creator, -> { includes(:creator) }
  scope :preloaded, -> { includes(:creator, :mentions) }
  scope :chronologically, -> { order(created_at: :asc) }
  scope :reverse_chronologically, -> { order(created_at: :desc) }
  scope :latest, -> { order(created_at: :desc).limit(1) }
  scope :page_before, ->(cursor) { where("id < ?", cursor.id).order(id: :desc).limit(50) }
  scope :page_after, ->(cursor) { where("id > ?", cursor.id).order(id: :asc).limit(50) }
end
```

```ruby
class Post < ApplicationRecord
  # Scopes
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_author, ->(author_id) { where(author_id: author_id) }
  scope :created_between, ->(start_date, end_date) {
    where(created_at: start_date..end_date)
  }

  # Chaining scopes
  # Post.published.recent.limit(10)
end

# Query methods
Post.where(published: true)
Post.where("views > ?", 100)
Post.where(author_id: [1, 2, 3])
Post.where.not(category: 'draft')

# Ordering
Post.order(created_at: :desc)
Post.order(views: :desc, created_at: :asc)

# Limiting
Post.limit(10)
Post.offset(20).limit(10)

# Joins
Post.joins(:author)
Post.joins(:author, :comments)
Post.left_joins(:comments)

# Includes (eager loading)
Post.includes(:author, :comments)
Post.includes(author: :profile)

# Selecting specific fields
Post.select(:id, :title, :created_at)
Post.pluck(:title)
Post.pluck(:id, :title)

# Aggregations
Post.count
Post.average(:views)
Post.maximum(:views)
Post.minimum(:views)
Post.sum(:views)

# Group
Post.group(:category).count
Post.group(:author_id).average(:views)
```

### Query Methods Worth Knowing

```ruby
# Find records with/without associations (Rails 6.1+)
Invoice.where.missing(:payments)    # invoices with no payment
Invoice.where.associated(:payments) # invoices with at least one payment

# Sort by enum value in custom order
Proposal.in_order_of(:status, %w[accepted in_review rejected]).order(:name)

# Combine relations with OR
inactive = Account.where("last_activity_at < ?", 14.days.ago)
low_usage = Account.where("actions_last_month < ?", 10)
at_risk = inactive.or(low_usage)

# Lambda defaults on associations — auto-set on create
class Card < ApplicationRecord
  belongs_to :creator, class_name: "User", default: -> { Current.user }
  belongs_to :account, default: -> { board.account }
end
```

## Enums

Always use hash syntax with explicit integer values — never array syntax. Array-based enums break if you reorder or insert values.

```ruby
# Good - explicit values, safe to reorder
class Post < ApplicationRecord
  enum status: {
    draft: 0,
    published: 1,
    archived: 2
  }

# Bad - array syntax, insertion breaks existing data
# enum status: [:draft, :published, :archived]

  # Or with prefix/suffix
  enum visibility: {
    public: 0,
    private: 1
  }, _prefix: :visibility

  # Usage:
  # post.draft!
  # post.published?
  # Post.published
  # post.visibility_public!
end
```


### PostgreSQL-Level Enums

For PostgreSQL, define enums at the database level for type safety and self-documenting schemas:

```ruby
# Migration
class AddCloudStateEnum < ActiveRecord::Migration[8.0]
  def up
    create_enum :cloud_state, %w[uploaded analyzing analyzed generating generated failed]
    add_column :clouds, :state, :cloud_state, default: "uploaded", null: false
    add_index :clouds, :state
  end

  def down
    remove_column :clouds, :state
    drop_enum :cloud_state
  end
end

# Model
class Cloud < ApplicationRecord
  enum :state, {
    uploaded: "uploaded",
    analyzing: "analyzing",
    generated: "generated",
    failed: "failed"
  }, validate: true
end
```

Invalid states are rejected at the database level. Use string values in the hash to match the PostgreSQL enum names.

## Association Tips

Use `:inverse_of` for bidirectional associations when Rails can't infer them automatically (e.g., custom foreign keys, scoped associations, or polymorphic):

```ruby
class User < ApplicationRecord
  has_many :authored_posts, class_name: "Post", foreign_key: :author_id, inverse_of: :author
end

class Post < ApplicationRecord
  belongs_to :author, class_name: "User", inverse_of: :authored_posts
end
```

This ensures both sides of the association share the same in-memory object, avoiding stale data and unnecessary queries.

### `before_destroy` with `dependent: :destroy`

When using `before_destroy` to validate whether a record can be deleted, and the model also has `dependent: :destroy`, use `prepend: true` so the callback runs before Rails destroys dependents:

```ruby
has_many :line_items, dependent: :destroy

before_destroy :ensure_not_shipped, prepend: true

private

def ensure_not_shipped
  if shipped?
    errors.add(:base, "Cannot delete a shipped order")
    throw(:abort)
  end
end
```

### Rich Error Objects with Symbol Codes

Use symbol error codes instead of strings for better i18n and test assertions:

```ruby
class Admin < ApplicationRecord
  EMAIL_DOMAIN = "@company.com"

  validate :email_domain_valid

  private

  def email_domain_valid
    return if email.blank?
    return if email.end_with?(EMAIL_DOMAIN)

    errors.add(
      :email,
      :invalid_email_domain,       # Symbol code (used for i18n lookup)
      expected: EMAIL_DOMAIN,      # Extra params available in error details
      actual: email.split("@").last
    )
  end
end

# In tests — assert on codes, not strings
admin.errors.details[:email]
# => [{ error: :invalid_email_domain, expected: "@company.com", actual: "gmail.com" }]
```

### State as Records

Model optional state as a separate associated record rather than a boolean column. Captures who changed it, when, and optionally why — and reverting is as simple as destroying the record.

```ruby
class Card < ApplicationRecord
  has_one :closure

  def close(by:, reason: nil)
    create_closure!(closed_by: by, reason: reason)
  end

  def reopen
    closure&.destroy!
  end

  def closed?
    closure.present?
  end
end

class Closure < ApplicationRecord
  belongs_to :card, touch: true
  belongs_to :closed_by, class_name: "User"
end
```

```ruby
# Migration
create_table :closures do |t|
  t.references :card, null: false, foreign_key: true
  t.references :closed_by, null: false, foreign_key: { to_table: :users }
  t.text :reason
  t.timestamps
end
```

**When to use:** Whenever you need an audit trail, a timestamp, or a "by whom" for a boolean — prefer a state record over a boolean + nullable timestamp + nullable foreign key column.

### Custom Validators

Extract repeated validation logic into custom validator classes. Place in `app/validators/`:

```ruby
# app/validators/email_domain_validator.rb
class EmailDomainValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    domain = value.split("@").last
    unless options[:in].include?(domain)
      record.errors.add(attribute, options[:message] || "is not from an allowed domain")
    end
  end
end

# Usage in model
validates :email, email_domain: { in: %w[example.com company.com] }
```

### Callbacks — Database Lifecycle Only

Callbacks are hooks for **database lifecycle events**, not business logic triggers:
- Not Acceptable: `normalizes`, data normalization. use the rails 8 normalize method
```ruby
class User < ActiveRecord::Base
  normalizes :name, with: -> name { name.strip.titlecase }
end
```

- Use `after_commit` (not `after_save`) for any side effects — `after_commit` runs after the transaction completes, avoiding lock cascades and partial rollback surprises
- Never: sending emails, queueing jobs, making API calls — these run inside a DB transaction and can cause lock cascades
- If you find yourself writing `after_create :send_welcome_email` — move it to a service object

If callbacks can't be avoided, declare them in execution order for readability:
`before_validation` → `after_validation` → `before_save` → `around_save` → `before_create`/`before_update` → `after_create`/`after_update` → `after_save` → `after_commit`

## Advanced Queries

### Arel for Complex Queries

Use Arel when ActiveRecord's query interface isn't expressive enough:

```ruby
users = User.arel_table
posts = Post.arel_table

User.where(
  users[:created_at].gt(1.month.ago)
    .and(users[:role].eq("editor"))
    .or(users[:admin].eq(true))
)
```

Prefer ActiveRecord scopes and `where` for straightforward queries — only reach for Arel when you need complex `OR` conditions, subqueries, or operations that can't be expressed cleanly otherwise.

### Bulk Operations

Use bulk methods for performance when operating on large datasets:

```ruby
# Bulk insert (Rails 6+)
User.insert_all([
  { name: "Alice", email: "alice@example.com" },
  { name: "Bob", email: "bob@example.com" },
])

# Bulk upsert
User.upsert_all(records, unique_by: :email)

# Bulk update
User.where(active: false).update_all(archived: true)

# Bulk delete
User.where("last_login_at < ?", 2.years.ago).delete_all
```

Note: `insert_all`, `update_all`, and `delete_all` skip validations and callbacks — use intentionally.

## Migration Safety

- Always test rollbacks before deploying: `rails db:migrate && rails db:rollback`
- For data migrations that aren't reversible, use explicit `up` and `down` methods
- Consider the impact on existing data — add `NOT NULL` constraints in two steps if the column has existing `nil` values

```ruby
# Two-step NOT NULL addition for existing data
class MakeEmailRequired < ActiveRecord::Migration[7.1]
  def up
    User.where(email: nil).update_all(email: "unknown@placeholder.com")
    change_column_null :users, :email, false
  end

  def down
    change_column_null :users, :email, true
  end
end
```

## What to Avoid in Models
- Business logic that spans multiple models
- External API calls
- Complex multi-step processes
- Heavy computation
- Callbacks (especially `before_save`, `after_save`)
- Callbacks that update other models

## Best Practices

1. **Fat models, skinny controllers** - Business logic belongs in models
2. **Use scopes** for common queries
3. **Validate at database level** with constraints when possible
4. **Use indexes** for frequently queried columns
5. **Eager load associations** to avoid N+1 queries
7. **Keep callbacks simple** - avoid complex logic
8. **Use transactions** for multi-step operations
9. **Avoid callbacks for cross-cutting concerns** - use service objects instead

## Common Pitfalls

- **N+1 queries**: Use `includes`, `preload`, or `eager_load`
- **Callback hell**: Keep callbacks simple, use service objects for complex logic
- **Mass assignment vulnerabilities**: Use strong parameters in controllers
- **Missing indexes**: Add indexes for foreign keys and frequently queried columns
- **Ignoring database constraints**: Add NOT NULL, unique constraints in migrations

## References

- [Rails Guides - Active Record](https://guides.rubyonrails.org/active_record_basics.html)
- [Rails Guides - Validations](https://guides.rubyonrails.org/active_record_validations.html)
- [Rails Guides - Associations](https://guides.rubyonrails.org/association_basics.html)
- [Rails Guides - Migrations](https://guides.rubyonrails.org/active_record_migrations.html)
- [Rails Guides - Queries](https://guides.rubyonrails.org/active_record_querying.html)
