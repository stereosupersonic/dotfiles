# Rails Controllers & Models

## Controller Guidelines

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

### What to Avoid in Models
- Business logic that spans multiple models
- External API calls
- Complex multi-step processes
- Heavy computation
- Callbacks (especially `before_save`, `after_save`)
- Callbacks that update other models
