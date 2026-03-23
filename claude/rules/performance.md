# Ruby Performance

Practical performance rules derived from rubocop-performance. These apply to all Ruby code unless noted otherwise.

## Collections

**Use `flat_map` over `map + flatten`:**
```ruby
# Good
users.flat_map(&:addresses)

# Bad
users.map(&:addresses).flatten(1)
```

**Use `filter_map` over `select + map` or `map + compact` (Ruby 2.7+):**
```ruby
# Good
users.filter_map { |u| u.email if u.active? }

# Bad
users.select(&:active?).map(&:email)
users.map { |u| u.email if u.active? }.compact
```

**Use `sort_by` over sort with a block:**
```ruby
# Good
users.sort_by(&:last_name)
users.sort_by { |u| [u.last_name, u.first_name] }

# Bad
users.sort { |a, b| a.last_name <=> b.last_name }
```

**Use `reverse_each` over `reverse.each`:**
```ruby
# Good
items.reverse_each { |item| process(item) }

# Bad — creates a reversed copy just to iterate
items.reverse.each { |item| process(item) }
```

**Use `sum` over `reduce(:+)` or `inject(:+)`:**
```ruby
# Good
orders.sum(&:total)
[1, 2, 3].sum

# Bad
orders.map(&:total).reduce(:+)
[1, 2, 3].inject(:+)
```

**Avoid collection literals inside loops — extract to a constant:**
```ruby
# Good
ADMIN_ROLES = %i[admin superadmin].freeze

users.each do |user|
  next unless ADMIN_ROLES.include?(user.role)
end

# Bad — allocates a new array on every iteration
users.each do |user|
  next unless [:admin, :superadmin].include?(user.role)
end
```

## Strings

**Use `delete_prefix`/`delete_suffix` over `gsub` with anchored regex (Ruby 2.5+):**
```ruby
# Good
path.delete_prefix("/api")
filename.delete_suffix(".tmp")

# Bad
path.gsub(/\A\/api/, "")
filename.gsub(/\.tmp\z/, "")
```

**Combine multiple prefix/suffix checks into one call:**
```ruby
# Good
str.start_with?("http", "https")

# Bad
str.start_with?("http") || str.start_with?("https")
```

**Use `include?` over `match?` for plain substring checks:**
```ruby
# Good
title.include?("Error")

# Bad — allocates a regex matcher unnecessarily
title.match?(/Error/)
```

## Regex

**Use `match?` over `match` or `=~` in boolean contexts (Ruby 2.4+):**
```ruby
# Good — no MatchData object allocated
return unless email.match?(/\A[^@]+@[^@]+\z/)

# Bad
return unless email.match(/\A[^@]+@[^@]+\z/)
return unless email =~ /\A[^@]+@[^@]+\z/
```

**Extract repeated regexes to constants:**
```ruby
# Good — compiled once
EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\z/

def valid_email?(str)
  str.match?(EMAIL_REGEX)
end

# Bad — recompiled on every call
def valid_email?(str)
  str.match?(/\A[^@\s]+@[^@\s]+\z/)
end
```

## Blocks & Methods

**Use `yield` over explicit `block.call`:**
```ruby
# Good
def with_logging
  Rails.logger.info "start"
  yield
  Rails.logger.info "done"
end

# Bad — unnecessary block object allocation
def with_logging(&block)
  Rails.logger.info "start"
  block.call
  Rails.logger.info "done"
end
```

## Data Structures

**Use `Struct` over `OpenStruct`:**

`OpenStruct` invalidates Ruby's method dispatch cache globally on every instantiation. Use `Struct` instead:

```ruby
# Good
Point = Struct.new(:x, :y)
point = Point.new(1, 2)

# Bad — degrades performance across the whole process
point = OpenStruct.new(x: 1, y: 2)
```

## Calling the Stack

**Use `caller(n..n).first` over `caller[n]`:**
```ruby
# Good — fetches only what you need
location = caller(1..1).first

# Bad — builds the full call stack array
location = caller[1]
```
