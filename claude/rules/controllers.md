# Rails Controllers

## Quick Reference

| Pattern | Example |
|---------|---------|
| **Generate** | `rails g controller Posts index show` |
| **Route** | `resources :posts` |
| **Action** | `def show; @post = Post.find(params[:id]); end` |
| **Render** | `render :edit` |
| **Redirect** | `redirect_to posts_path` |
| **Filter** | `before_action :authenticate_user!` |
| **Strong Params** | `params.require(:post).permit(:title, :body)` |

## Controller Guidelines

### Routing

- Use `member` and `collection` blocks for multiple custom routes on a resource
- Use `shallow: true` for nested resources deeper than 1 level
- Avoid wildcard/match routes — use explicit verb-based routes
- Keep routes RESTful — model actions as resources (see CRUD Resource Modeling below)

```ruby
# Good - shallow nesting prevents deep URLs
resources :forums do
  resources :topics, shallow: true do
    resources :posts, shallow: true
  end
end
# Produces: /forums/:forum_id/topics (index, create)
#           /topics/:id (show, edit, update, destroy)

# Good - member/collection blocks
resources :users do
  member do
    get :profile
    get :activity
  end
  collection do
    get :search
  end
end

# Bad - match/wildcard routes
match "/api/*path", to: "api#handle", via: :all
```

### Direct Routes for External URLs

```ruby
# config/routes.rb
direct(:partner_website) { "https://www.example.com" }

# Usage
partner_website_url  # => "https://www.example.com"
```

### Authenticated Route Constraints

Serve different roots based on authentication state:

```ruby
# config/initializers/routing_helpers.rb
class AuthenticatedConstraint
  def matches?(request)
    cookies = ActionDispatch::Cookies::CookieJar.build(request, request.cookies)
    if (session_token = cookies.signed[:session_token])
      Session.exists?(id: session_token)
    end
  rescue
    false
  end
end

# config/routes.rb
constraints(AuthenticatedConstraint.new) do
  root to: "dashboard#index", as: :authenticated_root
end

root to: "pages#home"
```

### Rate Limiting (Rails 8+)

```ruby
class SessionsController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :create
end

class ApiController < ApplicationController
  rate_limit to: 5, within: 1.minute, by: :ip,
    with: -> { render json: { error: "Too many requests" }, status: :too_many_requests }
end
```

### Strong Parameters

Use the Rails 8+ `params.expect` syntax for cleaner, more explicit parameter handling:

```ruby
# Rails 8+ preferred - explicit and clear
def user_params
  params.expect(user: [:email, :name, :password])
end

# For nested attributes
def order_params
  params.expect(order: [:status, :total, items: [[:name, :quantity, :price]]])
end

# Legacy syntax - still works but prefer expect
def user_params
  params.require(:user).permit(:email, :name, :password)
end
```

### CRUD Resource Modeling

Model endpoints as CRUD operations on resources (REST). When an action doesn't map cleanly to a standard CRUD verb, introduce a new resource rather than adding custom actions.

```ruby
# Bad - custom actions
resources :cards do
  post :close
  post :reopen
  post :archive
end

# Good - new resources for state changes
resources :cards do
  resource :closure, only: [:create, :destroy]  # close/reopen
  resource :archival, only: [:create, :destroy] # archive/unarchive
end

# Good - nested resource for related action
resources :orders do
  resource :cancellation, only: [:create]
end
```

### Vanilla Rails Approach

For simple operations, direct Active Record calls in controllers are fine. Don't over-abstract with services when plain Rails suffices.

```ruby
# Fine for simple CRUD - no service needed
class CommentsController < ApplicationController
  def create
    @comment = @post.comments.create!(comment_params)
    redirect_to @post
  end

  def destroy
    @comment = @post.comments.find(params[:id])
    @comment.destroy
    redirect_to @post
  end
end

# Use services for complex multi-step operations
class RegistrationsController < ApplicationController
  def create
    result = Users::CreateUser.new(user_params).call
    # ...
  end
end
```

### Parameter Conversion

Controllers are responsible for converting HTTP strings into proper types before handing off to business logic:
- For ActiveRecord, strings are often fine (AR handles conversions) — don't add unnecessary `.to_i`
- For custom types (e.g. dollars → cents), convert in the controller before passing to services
- Only create a conversion abstraction when you have 3+ duplications

```ruby
# Convert custom types in the controller
widget_params[:price_cents] = Price.new(widget_params[:price_cents]).cents
```

### Controller Best Practices
- Keep controllers thin—delegate to services only when complexity warrants it
- Use `params.expect` (Rails 8+) for strong parameters
- Follow REST conventions—model actions as resources
- Use standard CRUD actions when possible (index, show, new, create, edit, update, destroy)
- Handle errors gracefully with proper HTTP status codes — always use symbolic status codes (`:not_found`, `:forbidden`, `:unprocessable_entity`) over numeric (`404`, `403`, `422`)
- Use before_actions for authentication, authorization, and common setup
- **Expose exactly ONE instance variable per action**, named after the resource (`@widget`, `@widgets`). Exceptions: reference data (dropdown lists), global context (`current_user`), persisted UI state (active tab). Multiple instance variables that collectively represent a resource = a domain modeling problem, not a view problem.
- Use `respond_to` for multiple formats
- Return early with guard clauses
- `before_action` filters should only reference actions defined in the same controller (lexically scoped) — don't filter on inherited actions not visible in the current file

```ruby
class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: %i[show edit update destroy]
  before_action :authorize_user, only: %i[edit update destroy]

  def index
    @users = Users::SearchQuery.new.call(search_params)
                                .paginate(page: params[:page], per_page: 25)
  end

  def show
    @user = UserPresenter.new(@user, view_context)
  end

  def create
    result = Users::CreateUser.new(user_params).call

    if result.success?
      redirect_to user_path(result.value), notice: "User created successfully"
    else
      @user = User.new(user_params)
      flash.now[:alert] = result.failure.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      redirect_to user_path(@user), notice: "User updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to users_path, alert: "User not found"
  end

  def authorize_user
    redirect_to root_path, alert: "Not authorized" unless current_user.can_edit?(@user)
  end

  def user_params
    params.expect(user: [:email, :name, :role])
  end

  def search_params
    params.permit(:q, :status, :role, :page)
  end
end
```

## Multi-Format Error Handling

When controllers serve both HTML and JSON, handle errors for both formats:

```ruby
rescue_from ActiveRecord::RecordNotFound do |exception|
  respond_to do |format|
    format.html { redirect_to root_path, alert: "Record not found" }
    format.json { render json: { error: "Not found" }, status: :not_found }
  end
end
```

## API Controllers

For API-only endpoints, inherit from `ActionController::API` instead of `ActionController::Base` for a leaner stack:

- Use `ActionController::API` base class
- Implement proper HTTP status codes
- Version APIs from day one (`/api/v1/`)
- Use serializers (Jbuilder, ActiveModel::Serializers) for consistent JSON output
- Handle CORS appropriately (e.g., `rack-cors` gem)
- Skip CSRF protection (token auth or JWT instead)

```ruby
module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_token

      private

      def authenticate_token
        # Token-based auth logic
      end
    end
  end
end

```

## Best Practices

1. **Keep controllers thin** - Move business logic to models or service objects
2. **Use before_action** for common setup code
3. **Always use strong parameters** for security
4. **Return proper HTTP status codes**
5. **Use concerns** for shared controller behavior
6. **Follow REST conventions** when possible
7. **Handle errors gracefully** with rescue_from
8. **Use flash messages** for user feedback
9. **Set instance variables** only for view rendering
10. **Avoid complex queries** in controllers - use scopes or query objects
11. **Avoid defining helper methods inside controllers** - helpers should be located under helpers

## MCP-Enhanced Capabilities

When Rails MCP Server is available, leverage:
- **Routing Documentation**: Access comprehensive routing guides and DSL reference
- **Controller Patterns**: Reference ActionController methods and modules
- **Security Guidelines**: Query official security best practices
- **API Design**: Access REST and API design patterns from Rails guides
- **Middleware Information**: Understand the request/response cycle

Use MCP tools to:
- Verify routing DSL syntax and options
- Check available controller filters and callbacks
- Reference proper HTTP status codes and when to use them
- Find security best practices for the current Rails version
- Understand request/response format handling

## References

- [Rails Guides - Controllers](https://guides.rubyonrails.org/action_controller_overview.html)
- [Rails Guides - Routing](https://guides.rubyonrails.org/routing.html)
- [Rails API - ActionController](https://api.rubyonrails.org/classes/ActionController/Base.html)
