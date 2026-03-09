# Database & ActiveRecord

## Column Type Conventions

**Prefer `text` over `string` for text fields:**
- PostgreSQL treats `text` and `string` (varchar) identically for performance
- `string` has an arbitrary 255 character limit that causes silent truncation
- `text` avoids limit-related bugs and migration headaches

```ruby
# Good - use text for flexibility
create_table :users do |t|
  t.text :name                    # No arbitrary length limit
  t.text :bio                     # Obviously text
  t.text :email                   # Even short fields benefit
end

# Avoid - arbitrary 255 char limit
create_table :users do |t|
  t.string :name                  # May truncate unexpectedly
end
```

**Other column type guidelines:**
- Use `datetime` instead of `timestamp` for consistency
- Boolean columns should be nullable unless business logic requires a default
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
- Always use eager loading to avoid N+1 queries
- Use `includes` for loading associations you'll use
- Use `preload` when you don't need joins
- Use `joins` when filtering by associations
- Use `select` to load only needed columns for large datasets
- Use `pluck` for fetching single columns
- Use `exists?` instead of `present?` for existence checks
- Use `find_each` and `in_batches` for large datasets

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

# Bad - N+1 query
@users = User.all
@users.each do |user|
  puts user.posts.count # N+1 query!
end
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
