# Ruby Style & Formatting

## General Style

- **Always use double quotes** for strings unless single quotes are specifically needed
- Use 2 spaces for indentation (no tabs)
- Keep line length under 100 characters (120 max for exceptional cases)
- Use snake_case for variables, methods, and file names
- Use PascalCase for class names
- Use SCREAMING_SNAKE_CASE for constants
- Use descriptive names—avoid abbreviations (prefer `user_registration` over `usr_reg`)
- Use parallel assignment sparingly and only when it improves readability
- Follow Ruby/Rails conventions (Rubocop Rails Omakase with customizations)
- All files must end with a newline

## Method Behavior

- Don't mutate method arguments
- Omit `return` where not needed — the last expression is the return value
- Omit `self` where not needed (required only for attribute writers)
- Use `public_send` over `send` to respect visibility modifiers
- Prefer keyword arguments over an options hash

```ruby
# Good
def create(name:, role:)
  # ...
end

# Bad
def create(options = {})
  name = options[:name]
  role = options[:role]
end
```

## Method Naming

**Bang methods (`!`):** Only use `!` when a non-bang counterpart exists. Don't use `!` merely to indicate destructive actions—many Ruby/Rails methods are destructive without `!`.

```ruby
# Good - bang has non-bang counterpart
user.save    # Returns true/false
user.save!   # Raises exception

# Good - no bang needed for naturally destructive methods
user.destroy      # Not destroy!
array.clear       # Not clear!
hash.delete(:key) # Not delete!

# Bad - bang without counterpart
def process_payment!  # Don't do this unless process_payment exists
  # ...
end
```

**Naming:**
- Predicate methods end with `?` — never prefix with `is_` or `get_`

## Method Ordering

Order methods in classes for readability:

1. **Class methods** (`self.` methods)
2. **Public instance methods** (`initialize` first)
3. **Private methods** (in invocation order)

**Invocation order:** Arrange private methods vertically based on when they're called. This helps readers follow the code flow.

```ruby
class OrderProcessor
  def self.for(user)
    new(user)
  end

  def initialize(user)
    @user = user
  end

  def process
    validate_order
    charge_payment
    send_confirmation
  end

  private

  # Ordered by invocation in process method
  def validate_order
    check_inventory
    check_address
  end

  def check_inventory
    # called by validate_order
  end

  def check_address
    # called by validate_order
  end

  def charge_payment
    # called second in process
  end

  def send_confirmation
    # called last in process
  end
end
```

## Conditionals & Control Flow
- Use guard clauses to reduce nesting and improve early returns
- Use modifier conditionals (`return unless valid?`) for simple one-liners
- Use `unless` sparingly—only for simple negative conditions without `else`
- Never use `unless` with `else`—always use `if/else` instead
- Prefer positive conditionals over negative ones when clarity improves
- Use `case/when` for multiple conditions instead of long `if/elsif` chains
- Use `&&`/`||` instead of `and`/`or`; use `!` instead of `not`
- Use `||=` to initialize variables, but not for booleans (use `if @var.nil?` instead)

```ruby
# Good - guard clause
def process_order(order)
  return unless order.valid?
  return if order.processed?

  # main logic here
end

# Bad - nested conditionals
def process_order(order)
  if order.valid?
    if !order.processed?
      # main logic here
    end
  end
end
```

## Blocks
- Use `{...}` for single-line blocks, `do..end` for multi-line blocks
- Prefix unused block parameters with `_`

```ruby
# Good
[1, 2, 3].map { |n| n * 2 }

hash.each do |key, value|
  # multi-line
end

[1, 2, 3].each_with_index.map { |_n, i| i }
```

## Collections (Arrays & Hashes)
- Use `%w` and `%i` for word and symbol arrays
- Use trailing commas in multi-line collections for cleaner diffs
- Use `Hash.new` with block for complex default values
- Prefer `fetch` over `[]` when you want to handle missing keys explicitly
- Use `dig` for safely accessing nested hash/array values
- Prefer `map`, `select`, `reject` over `each` with mutation
- Use `first`/`last` over `[0]`/`[-1]`
- Use `key?`/`value?` over `has_key?`/`has_value?`
- Use `find` over `detect`, `map` over `collect`

```ruby
# Good
STATUSES = %w[pending approved rejected].freeze
ALLOWED_ROLES = %i[admin editor viewer].freeze

config = {
  timeout: 30,
  retries: 3,
}

user.dig(:address, :city) # Safe nested access
```

## String Manipulation
- Use string interpolation instead of concatenation
- Use `%()` or `%Q()` for strings with many quotes
- Use heredocs (`<<~TEXT`) for multi-line strings with proper indentation
- Prefer `String#strip` for cleaning whitespace
- Use `String#squish` to remove excess whitespace in Rails
- Don't call `to_s` on interpolated objects — it's implicit
- Prefer `tr`/`delete` over `gsub` when no regex is needed

```ruby
# Good
message = "Hello, #{user.name}!"
sql = <<~SQL
  SELECT users.*
  FROM users
  WHERE active = true
SQL

# Bad
message = "Hello, " + user.name + "!"
```

## Rails-Specific Conventions
- Use Rails time helpers instead of Ruby Time methods (`2.days.ago`, `Time.current`)
- Prefer `present?` and `blank?` over `nil?` and `empty?`
- Use safe navigation (`&.`) for potentially nil objects
- Prefer Rails collection methods over raw SQL when possible
- Use `find_each` and `in_batches` for processing large datasets
- Always use `Time.current` instead of `Time.now` (respects time zones)
- Use `Date.current` instead of `Date.today`
- Prefer Ruby stdlib over ActiveSupport aliases: `start_with?` not `starts_with?`, `end_with?` not `ends_with?`
- Prefer Ruby comparison operators over `Array#inquiry` and `String#inquiry`
- Use `Time.zone.parse` instead of `Time.parse` (respects application time zone)

```ruby
# Good
User.where(active: true).find_each do |user|
  user.send_notification
end

expires_at = 30.days.from_now
last_login = user.last_login_at&.to_date

# Bad
User.where(active: true).each do |user|
  user.send_notification
end
```
