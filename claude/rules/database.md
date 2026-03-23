# Database & ActiveRecord


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
