# Caching Strategies

## Philosophy

1. **HTTP caching first** — `fresh_when` prevents rendering entirely
2. **Russian Doll by default** — nest fragments, use `touch: true`
3. **Measure before caching** — not every fragment benefits
4. **Counter caches for counts** — denormalize what you read frequently
5. **Solid Cache for retention** — database-backed, months of retention vs hours

---

## HTTP Caching

Check staleness before rendering. If the client already has a fresh copy, skip rendering entirely.

```ruby
class ProjectsController < ApplicationController
  def show
    @project = Project.find(params[:id])
    fresh_when @project
  end

  def index
    @projects = current_account.projects.recent
    fresh_when @projects
  end
end

# stale? for conditional rendering
def show
  @project = Project.find(params[:id])

  if stale?(@project)
    respond_to do |format|
      format.html
      format.json { render json: @project }
    end
  end
end
```

---

## Russian Doll Caching

Nest cached fragments so that when one item changes, only that fragment re-renders.

```erb
<%# app/views/projects/show.html.erb %>
<% cache @project do %>
  <h1><%= @project.name %></h1>

  <% @project.todolists.each do |todolist| %>
    <% cache todolist do %>
      <h2><%= todolist.name %></h2>

      <% todolist.todos.each do |todo| %>
        <% cache todo do %>
          <%= render todo %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
```

### Touch for Cache Invalidation

When a child changes, touch the parent so its `updated_at` changes and its cache key expires:

```ruby
class Todo < ApplicationRecord
  belongs_to :todolist, touch: true
end

class Todolist < ApplicationRecord
  belongs_to :project, touch: true
  has_many :todos, dependent: :destroy
end
```

When a todo updates:
1. Todo's cache key changes (its `updated_at` changed)
2. Todolist touched → its cache expires
3. Project touched → outer cache expires
4. Only the changed todo fragment re-renders from scratch

---

## Fragment Caching Best Practices

### Cache Key Design

```erb
<%# Include all dependencies in cache key %>
<% cache [current_user, @project] do %>
  <%= render @project %>
<% end %>

<%# Rails automatically uses cache_key_with_version — prefer this %>
<% cache @project do %>
  <%= render @project %>
<% end %>
```

### Collection Caching

```erb
<%# One multi-get instead of N cache lookups %>
<%= render partial: "todos/todo", collection: @todos, cached: true %>
```

### Conditional Caching

```erb
<%# Skip caching for users who see extra info (would have low hit rate) %>
<% cache_if !current_user.admin?, @project do %>
  <%= render @project %>
<% end %>
```

---

## When to Cache

**Cache when:**
- Hit rate > 80%
- Render time is significant (> 10ms)
- Content changes infrequently relative to reads

**Skip caching when:**
- Content is highly personalized (low hit rate)
- Fragment renders quickly (< 5ms)
- Content changes frequently

High-personalization fragments often perform *worse* when cached due to cache lookup overhead.

---

## Solid Cache (Database-Backed)

Use Solid Cache instead of Redis/Memcached. Database-backed caching retains keys for months, yielding much higher hit rates than memory-limited stores.

```ruby
# config/environments/production.rb
config.cache_store = :solid_cache_store

# config/cache.yml
production:
  database: cache
  max_age: <%= 60.days.to_i %>
  max_size: <%= 256.megabytes %>
```

| Aspect | Redis | Solid Cache |
|--------|-------|-------------|
| Read/write speed | 0.8ms | 1.2ms |
| Retention | Hours (memory limited) | Months (disk is cheap) |
| Infrastructure | Additional service | Just PostgreSQL/SQLite |
| Debugging | Separate tooling | ActiveRecord, standard SQL |

The 0.4ms difference is insignificant. The massive retention advantage outweighs it.

---

## Counter Caches

Avoid N+1 counts by storing counts in a column.

```ruby
class Todo < ApplicationRecord
  belongs_to :todolist, counter_cache: true
end

class Todolist < ApplicationRecord
  has_many :todos
  # todos_count column updated automatically
end
```

```ruby
# Migration
add_column :todolists, :todos_count, :integer, default: 0, null: false

# Reset after data migration
Todolist.find_each { |t| Todolist.reset_counters(t.id, :todos) }
```

```erb
<%# In views — no query needed %>
<%= todolist.todos_count %> todos
```

Counter caches for `has_many` associations are strongly preferred when the count is displayed in lists.

---

## Low-Level Caching

For cross-request caching of expensive computations:

```ruby
class User < ApplicationRecord
  def expensive_calculation
    Rails.cache.fetch("user/#{id}/expensive", expires_in: 1.hour) do
      # Complex calculation
    end
  end
end
```

Rails automatically caches identical queries within a single request — no manual intervention needed for that case.
