# Backend: Jobs, API, Errors & Performance

## Error Handling

### Error Handling Strategy
- Use custom exception classes for domain-specific errors
- Handle errors at appropriate levels
- Log errors with context
- Provide meaningful error messages to users
- Use Rails rescue_from in controllers
- Use error monitoring (Sentry, Honeybadger, Rollbar)
- Don't swallow exceptions

```ruby
# app/errors/payment_error.rb
module Errors
  class PaymentError < StandardError; end
  class InsufficientFundsError < PaymentError; end
  class InvalidCardError < PaymentError; end
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  rescue_from Errors::PaymentError, with: :handle_payment_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

  private

  def handle_payment_error(exception)
    Rails.logger.error("Payment error: #{exception.message}")
    redirect_to checkout_path, alert: "Payment failed: #{exception.message}"
  end

  def handle_not_found
    redirect_to root_path, alert: "Resource not found"
  end
end

# Usage in service
def process_payment
  raise Errors::InsufficientFundsError, "Account balance too low" if balance < amount
  raise Errors::InvalidCardError, "Card has expired" if card.expired?

  # process payment
end
```

## Rake Tasks

Use Rake tasks for operational automation: one-time backfills, data migrations, periodic reports, admin scripts. They are preferred over one-off scripts because they are discoverable (`rake -T`), testable, namespaced, and runnable across all environments.

```ruby
# lib/tasks/users.rake
namespace :users do
  desc "Backfill missing display names from email address"
  task backfill_display_names: :environment do
    scope = User.where(display_name: nil)
    count = scope.count

    scope.find_each do |user|
      user.update_columns(display_name: user.email.split("@").first)
    end

    puts "Done. Backfilled #{count} users."
  end
end
```

Keep tasks thin — delegate to service objects or model methods for the actual logic. Tasks orchestrate; they don't implement.

Avoid Rake tasks for:
- Work that should be a background job (use Solid Queue instead)
- Scheduled recurring work (use `config/recurring.yml` instead)
- Anything requiring interactive input (use a console or admin UI instead)

---

## Performance

### Optimization Strategies
- Use eager loading to avoid N+1 queries (`includes`, `preload`, `joins`)
- Add database indexes for foreign keys and frequently queried columns
- Use counter caches for associations
- Implement pagination for large datasets (will_paginate gem)
- Cache expensive operations (fragment caching, Russian doll caching)
- Use background jobs for slow operations
- Monitor performance with tools (Bullet, Rack Mini Profiler, Scout)
- Use CDN for assets
- Optimize images
- Use database connection pooling

```ruby
# Counter cache
class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
end

# Add counter cache column
class AddCommentsCountToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :comments_count, :integer, default: 0, null: false
  end
end

# Fragment caching in views
- cache @user do
  .user-profile
    = render @user

# Russian doll caching
- cache @post do
  .post
    = @post.title
    - cache @post.comments do
      = render @post.comments
```
