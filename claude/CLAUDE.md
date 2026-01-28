# Ruby on Rails Development Guidelines
You are an expert Ruby on Rails developer. Your goal is to write sustainable, maintainable, and high-quality Rails code that adheres to established best practices. Always follow these coding standards and best practices:

## Mindset

- Optimize for low carrying cost, not short-term delivery speed.
- Prioritize consistency over cleverness—make your future self and teammates grateful.
- Be explicit, clear, and pragmatic. Don’t abstract prematurely.
- If a trade-off is required, cut scope, not quality.

## Code Style & Formatting

- **Always use double quotes** for strings unless single quotes are specifically needed
- Use 2 spaces for indentation (no tabs)
- Keep line length under 100 characters
- Use snake_case for variables, methods, and file names
- Use PascalCase for class names
- Use SCREAMING_SNAKE_CASE for constants
- Use descriptive names - avoid abbreviations
- Use parallel assignment when it improves readability
- Follow Ruby/Rails conventions (Rubocop Rails Omakase with customizations)
- Prefer HAML for templates over ERB
- Use *unless* sparingly - only for simple negative conditions
- Avoid *unless* with else - use if instead
- Use modifier conditionals for simple one-liners
- Use guard clauses to reduce nesting
- All files should end with a newline

### Arrays & Hashes

- Use %w and %i for word and symbol arrays
- Use trailing commas in multi-line collections
- Use Hash.new with block for complex default values
- Prefer fetch over [] when you want to handle missing keys

### String Manipulation

- Use string interpolation instead of concatenation
- Use %() for strings with many quotes
- Use heredocs for multi-line strings
- Prefer String#strip for cleaning whitespace

### Rails-Specific Rules

- Use Rails time helpers instead of Ruby Time methods
- Prefer present? and blank? over nil? and empty?
- Use safe navigation for potentially nil objects
- Prefer Rails collection methods over raw SQL when possible

## Code Organization

- Use namespaces to organize related functionality
- Keep related files in appropriate directories
- Use concerns for shared functionality (sparingly)
- Extract complex views into presenters

## Architecture Patterns

- Keep business logic out of Active Record models. Use service classes with clear responsibilities.
- Favor small, single-purpose methods.
- Don’t use before_* or after_* callbacks unless absolutely necessary—prefer explicit orchestration.
- Only use one instance variable per controller action, named after the resource.
- Avoid custom JS frameworks unless absolutely required. Embrace server-rendered views and Turbo.


### Service Objects

- **Always use service objects** for complex business logic
- Place service objects in `app/services/`
- Name them with verb + noun format (e.g., `CreateUser`, `ProcessPayment`)
- Include a single public `call` method
- Return a result object

```ruby

class CreateUser < BaseService
  attr_accessor :params

  def call
    # Business logic here
  end


end
```

### Presenter Objects

- **Use presenter objects** for complex view-specific logic
- Place presenters in `app/presenters/`
- Name them with noun + `Presenter` format (e.g., `UserPresenter`, `OrderPresenter`)
- Delegate to the underlying model when appropriate
- Keep view formatting and display logic separate from business logic

```ruby
class UserPresenter < ApplicationPresenter

  def full_name
    "#{o.first_name} #{o.last_name}".strip
  end

  def formatted_created_at
    o.created_at.strftime("%B %d, %Y")
  end

  def status_badge_class
    o.active? ? "badge-success" : "badge-danger"
  end

end
```

### Controller Guidelines

- Keep controllers thin - delegate to service objects
- Use strong parameters
- Handle errors gracefully with proper HTTP status codes
- Use before_actions for common operations
- Follow REST conventions for controllers

### Model Guidelines

- Keep models focused on data and simple validations
- Extract complex business logic to service objects
- Use scopes for common queries
- Avoid callbacks for complex operations

## Database & ActiveRecord

- Use meaningful migration names with timestamps
- Always add database indexes for foreign keys and frequently queried columns
- Use `dependent: :destroy` or `dependent: :delete_all` appropriately
- Validate presence and format at both model and database level
- Use database constraints for data integrity, not just validation
- Use database transactions for multi-step operations

## Testing

- Write comprehensive tests using RSpec
- Follow the Arrange-Act-Assert pattern
- Use factories (FactoryBot) instead of fixtures
- Test service objects thoroughly
- Use system specs for the happy path
- Ensure system tests fail when JavaScript is broken
- Write tests for DB constraints, not just validations
- Avoid over-testing controllers. Focus on behavior, not implementation
- use data-testid attributes in views to stabilize test selectors
- Mock external dependencies via rspec or use vcr gem

## Error Handling

- Use custom exception classes when appropriate
- Handle errors gracefully in controllers
- Log errors appropriately
- Provide meaningful error messages to users
- Use Rails' built-in error handling where possible

## Security

- Always use strong parameters in controllers
- Sanitize user input
- Use Rails' built-in CSRF protection
- Use secure headers

## Performance

- Use eager loading (`includes`, `preload`, `joins`) to avoid N+1 queries
- Add database indexes for frequently queried columns
- Use counter caches when appropriate
- Implement pagination for large datasets
- Cache expensive operations appropriately


## Example Structure

```
app/
├── controllers/
├── models/
├── services/
│   ├── users/
│   │   ├── create_user.rb
│   │   └── update_user.rb
├── presenters/
│   ├── user_presenter.rb
│   └── order_presenter.rb
├── views/
├── helpers/
```

## Common Patterns to Follow

1. **Service Object Pattern**: Extract complex business logic
3. **Presenter Pattern**: For view-specific logic

## Background Jobs & Async Processing

- Use meaningful queue names that reflect priority and purpose
- Keep jobs idempotent - they should be safe to retry
- Use explicit job classes instead of inline jobs
- Place jobs in app/jobs/ directory organized by domain

```ruby
class ProcessPaymentJob < ApplicationJob
  queue_as :payments

  def perform(payment_id)
    payment = Payment.find(payment_id)
    PaymentProcessor.new(payment).call
  end
end
```

# API Structure Rules

- Version APIs from day one using URL versioning (/api/v1/)
- Use consistent serialization (Jbuilder)
- Return consistent error formats across all endpoints
- Use HTTP status codes correctly (200, 201, 422, 404, 500)

```ruby
class Api::V1::BaseController < ApplicationController
  respond_to :json

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

  private

  def not_found
    render json: { error: "Resource not found" }, status: :not_found
  end
end
```

## What to Avoid

- Fat controllers with business logic
- Fat models with too many responsibilities
- Excessive use of callbacks
- Direct database queries in views
- Hardcoded values (use constants or configuration)
- Overly complex nested routes
- Don't swallow exceptions or "fail silently."

## Documentation

- Write clear commit messages
- Document complex business logic
- Use meaningful variable and method names
- Add comments for non-obvious code

## JavaScript

- Minimize JavaScript: Use it only when absolutely necessary. Prefer server-rendered HTML.
- Use Hotwire (Turbo + Stimulus) for interactivity instead of custom frameworks.
- Do not rely on complex frontend build systems (like Webpack or Vite) unless justified.
- Use vanilla JavaScript and the web platform APIs where possible.
- If a framework is needed, choose one (e.g. React or Vue)—don’t mix.
- Ensure all JavaScript behavior is covered by system tests (use real browser testing via Capybara + headless Chrome).
- Handle JavaScript errors explicitly and ensure logs are meaningful.
- Organize JavaScript using import maps or ES Modules, not asset pipelines.

## CSS

- Never let CSS grow without constraint—every CSS class is a carrying cost.
- Avoid inline styles unless dynamically generated.
- Keep CSS modular, scoped, and predictable. Avoid !important and global overrides.

## Git Conventions

- Branch from `master`.
- PRs must include clear title, purpose, and linked tickets.

When writing code, prioritize readability, maintainability, and following Rails conventions. Always consider the long-term implications of architectural decisions.
