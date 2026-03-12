# Database & ActiveRecord

## Column Type Conventions

**Other column type guidelines:**
- Use `text` instead of `string`/`varchar` in Postgres — there is no performance difference, and arbitrary length limits cause bugs
- Use `datetime` instead of `timestamp` for consistency
- Boolean columns should always have `default:` and `null: false` to avoid the 3-state problem (`true`/`false`/`nil`). If you need three states, use an enum instead
- Use `decimal` for money (with precision and scale), never `float`

## Migration Best Practices
- Use meaningful, descriptive migration names with timestamps
- Always add database indexes for foreign keys
- Add indexes for frequently queried columns
- Use `add_index` with appropriate options (`unique`, `where` for partial indexes)
- Use database constraints for data integrity (not just Rails validations)
- Use `change` method when possible for reversible migrations
- Use `up` and `down` for complex non-reversible migrations
- Add comments for complex database structures
- Name foreign keys explicitly with the `name:` option — don't rely on auto-generated FK names
- When using models in migrations, define a local migration-scoped class to avoid future breakage

```ruby
# Define a local model class in migrations to decouple from app code
class BackfillUserStatus < ActiveRecord::Migration[7.1]
  class MigrationUser < ActiveRecord::Base
    self.table_name = :users
  end

  def up
    MigrationUser.where(status: nil).update_all(status: "active")
  end
end
```

```ruby
class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.text :status, null: false, default: "pending"  # Use text, not string
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.datetime :completed_at  # Use datetime, not timestamp

      t.timestamps
    end

    add_index :orders, :status
    add_index :orders, :completed_at
    add_index :orders, [:user_id, :status]
    add_check_constraint :orders, "total_amount >= 0", name: "orders_total_amount_check"
  end
end
```

## Database Constraints
- Use `null: false` for required fields
- Use `default:` for fields with default values
- Use check constraints for data integrity
- Use unique constraints at database level
- Use foreign key constraints with appropriate `on_delete` behavior

```ruby
# Migration with constraints
class AddConstraintsToUsers < ActiveRecord::Migration[7.1]
  def change
    change_column_null :users, :email, false
    add_index :users, :email, unique: true
    add_check_constraint :users, "LENGTH(email) >= 3", name: "users_email_length_check"
  end
end
```

## Query Optimization
- Always use eager loading to avoid N+1 queries — add the Bullet gem in development to detect N+1s automatically
- Use `includes` for loading associations you'll use
- Use `preload` when you don't need joins
- Use `joins` when filtering by associations
- Use `select` to load only needed columns for large datasets
- Use `pluck` for fetching single columns
- Use `exists?` instead of `present?` for existence checks
- Use `find_each` and `in_batches` for large datasets
- Never use string interpolation in queries — always use parameterized conditions
- Prefer named placeholders over `?` for readability
- Don't order by `id` — use `created_at` instead (IDs aren't guaranteed sequential with UUIDs or partitioning)
- Use `where.missing(:association)` for finding records without associated records (Rails 6.1+)
- Prefer `ids` over `pluck(:id)` — `User.ids` not `User.pluck(:id)`
- Prefer `size` over `count` for potentially-loaded collections — `size` checks if the collection is already loaded before hitting the DB
- Prefer `where.not(id: id)` over `where("id != ?", id)`
- Prefer `find` for primary key lookup (raises `RecordNotFound`), `find_by` for attribute lookup (returns `nil`)
- Use heredocs with `squish` for raw SQL in `find_by_sql`

```ruby
# Good - eager loading
@users = User.includes(:posts, :comments).where(active: true)

# Good - specific columns
User.select(:id, :email, :name).where(active: true)

# Good - existence check
User.where(email: email).exists?

# Good - batch processing
User.find_each(batch_size: 1000) do |user|
  user.send_notification
end

# Good - named placeholders
User.where("created_at > :start AND created_at < :end", start: 1.week.ago, end: Time.current)

# Good - missing associations
Post.where.missing(:comments)

# Bad - N+1 query
@users = User.all
@users.each do |user|
  puts user.posts.count # N+1 query!
end

# Bad - string interpolation in queries
User.where("email = '#{email}'") # SQL injection risk

# Bad - ordering by id
User.order(:id)

# Good - ordering by timestamp
User.order(:created_at)
```

## Transactions
- Use transactions for multi-step operations
- Keep transactions short and focused
- Don't perform external API calls inside transactions
- Use `transaction` blocks for data consistency
- Rescue and handle exceptions appropriately

```ruby
ActiveRecord::Base.transaction do
  user = User.create!(user_params)
  user.create_profile!(profile_params)
  user.create_settings!(default_settings)
end
```
