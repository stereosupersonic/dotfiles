---
name: controllers
description: Controller actions, routing, REST conventions, filters, and response handling
version: 1.0.0
rails_version: ">= 7.0"
tags:
  - controllers
  - routing
  - actions
  - rest
---

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

### Controller Best Practices
- Keep controllers thin—delegate to services only when complexity warrants it
- Use `params.expect` (Rails 8+) for strong parameters
- Follow REST conventions—model actions as resources
- Use standard CRUD actions when possible (index, show, new, create, edit, update, destroy)
- Handle errors gracefully with proper HTTP status codes
- Use before_actions for authentication, authorization, and common setup
- Limit instance variables—prefer one per action, named after the resource
- Use `respond_to` for multiple formats
- Return early with guard clauses

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

## Model Guidelines

### Keep Models Focused
- Models should handle data persistence, associations, and simple validations
- Extract complex business logic to service objects
- Extract complex queries to query objects
- Use scopes for common, reusable queries
- Avoid fat models with too many responsibilities
- Avoid callbacks
- Validations should also be handled within the database
- Prefer `has_many :through` over `has_and_belongs_to_many` — join models are almost always needed eventually
- Always specify `dependent:` on `has_many` and `has_one` associations
- Use bang persistence methods (`save!`, `create!`, `update!`) unless explicitly handling the return value
- Use `self[:attribute]` over `read_attribute`/`write_attribute`

### Model Macro Ordering

Follow this order for macro-style declarations in models:

1. `include` / `extend`
2. `enum`
3. Associations (`belongs_to`, `has_many`, `has_one`)
4. Validations
5. Scopes
6. Callbacks (use sparingly)
7. Class methods
8. Instance methods

```ruby
class User < ApplicationRecord
  # Concerns (use sparingly)
  include Searchable

  # Enums
  enum role: { viewer: 0, editor: 1, admin: 2 }
  enum status: { inactive: 0, active: 1, suspended: 2 }

  # Associations
  belongs_to :company
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_one :profile, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :role, presence: true

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :recent, -> { order(created_at: :desc) }
  scope :admins, -> { where(role: :admin) }

  # Callbacks (use sparingly)
  before_validation :normalize_email

  # Class methods
  def self.search(query)
    where("name ILIKE ? OR email ILIKE ?", "%#{query}%", "%#{query}%")
  end

  # Instance methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def admin?
    role == "admin"
  end

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
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
10. **Avoid to define helpers methods inside controlles** helper should be located under helpers



## References

- [Rails Guides - Controllers](https://guides.rubyonrails.org/action_controller_overview.html)
- [Rails Guides - Routing](https://guides.rubyonrails.org/routing.html)
- [Rails API - ActionController](https://api.rubyonrails.org/classes/ActionController/Base.html)
