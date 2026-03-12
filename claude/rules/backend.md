# Backend: Jobs, API, Errors & Performance


## API Development

### API Structure
- Version APIs from day one (`/api/v1/`)
- Use consistent JSON structure
- Return appropriate HTTP status codes
- Use serializers for consistent output (Jbuilder or ActiveModel::Serializers)
- Handle errors consistently
- Document API endpoints

```ruby
# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ApplicationController
      respond_to :json

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request

      private

      def not_found(exception)
        render json: {
          error: "Resource not found",
          message: exception.message
        }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: {
          error: "Validation failed",
          details: exception.record.errors.full_messages
        }, status: :unprocessable_entity
      end

      def bad_request(exception)
        render json: {
          error: "Bad request",
          message: exception.message
        }, status: :bad_request
      end
    end
  end
end

# app/controllers/api/v1/users_controller.rb
module Api
  module V1
    class UsersController < BaseController
      def index
        @users = User.active.paginate(page: params[:page], per_page: 25)
        render json: @users
      end

      def show
        @user = User.find(params[:id])
        render json: @user
      end

      def create
        result = Users::CreateUser.new(user_params).call

        if result.success?
          render json: result.value, status: :created
        else
          render json: { errors: result.failure }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.expect(user: [:email, :name])
      end
    end
  end
end
```

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

### What to Avoid in Models
- Business logic that spans multiple models
- External API calls
- Complex multi-step processes
- Heavy computation
- Callbacks (especially `before_save`, `after_save`)
- Callbacks that update other models
