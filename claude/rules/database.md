# Database & ActiveRecord


## Query Optimization
- Always use eager loading to avoid N+1 queries — add the Bullet gem in development to detect N+1s automatically
- Use `includes` for loading associations you'll use — Rails chooses between a JOIN or separate queries
- Use `preload` to force separate queries (safer for large datasets, avoids cartesian product)
- Use `eager_load` to force a LEFT OUTER JOIN (required when filtering/ordering on the association)
- Use `joins` when filtering by associations but not loading them — does **not** prevent N+1 on access
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
- Use `pick` to fetch a single value from a single record — `User.where(email: email).pick(:id)`
- Use range conditions instead of comparison operators — `where(age: 18..40)` over `where("age >= 18 AND age <= 40")`
- Avoid passing multiple attributes to `where.not` — it generates OR NOT logic, not AND NOT, which is rarely what you want
- Don't memoize `find_by` results with `||=` — `||=` won't re-query if the result is `nil`, masking records that don't exist

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

## Indexing

### Composite Index Column Ordering

For composite indexes, put **equality conditions first**, then range conditions. The database can only range-scan on the last key part after equality matches.

```ruby
# Query: cards for a board, ordered by position
add_index :cards, [:board_id, :position]

# Query: active cards in a column by due date
add_index :cards, [:column_id, :status, :due_at]

# Wrong order — range condition before equality wastes the index
# add_index :cards, [:due_at, :column_id]
```

## Deletes: Hard vs Soft

Prefer **hard deletes** over soft deletes (`deleted_at` columns). Soft deletes add pervasive `where(deleted_at: nil)` conditions to every query, inflate table size, and create risk of accidentally including deleted data.

When audit trail matters, use an event log instead:

```ruby
class Card < ApplicationRecord
  after_destroy_commit :log_deletion

  private

  def log_deletion
    Event.create!(
      action: "card.destroyed",
      recordable_type: "Card",
      recordable_id: id,
      metadata: attributes.except("id"),
      actor: Current.user
    )
  end
end

class Event < ApplicationRecord
  belongs_to :actor, class_name: "User", optional: true
  scope :deletions, -> { where("action LIKE ?", "%.destroyed") }
end
```

If you genuinely need to query deleted records (e.g., restore functionality), reconsider soft deletes — but keep it scoped to models that truly require it, not as a default.

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
