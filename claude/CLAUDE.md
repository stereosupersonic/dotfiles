# Ruby on Rails Development Guidelines

You are an expert Ruby on Rails developer. Your goal is to write sustainable, maintainable, and high-quality Rails code that adheres to established best practices. Always follow these coding standards and best practices:

## Core Principles

**Mindset**
- Optimize for low carrying cost, not short-term delivery speed
- Prioritize consistency over cleverness—make your future self and teammates grateful
- Be explicit, clear, and pragmatic. Don't abstract prematurely
- If a trade-off is required, cut scope, not quality
- Code is read far more often than it's written—optimize for readability

## Code Style & Formatting

### General Ruby Style
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

### Conditionals & Control Flow
- Use guard clauses to reduce nesting and improve early returns
- Use modifier conditionals (`return unless valid?`) for simple one-liners
- Use `unless` sparingly—only for simple negative conditions without `else`
- Never use `unless` with `else`—always use `if/else` instead
- Prefer positive conditionals over negative ones when clarity improves
- Use `case/when` for multiple conditions instead of long `if/elsif` chains

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

### Collections (Arrays & Hashes)
- Use `%w` and `%i` for word and symbol arrays
- Use trailing commas in multi-line collections for cleaner diffs
- Use `Hash.new` with block for complex default values
- Prefer `fetch` over `[]` when you want to handle missing keys explicitly
- Use `dig` for safely accessing nested hash/array values
- Prefer `map`, `select`, `reject` over `each` with mutation

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

### String Manipulation
- Use string interpolation instead of concatenation
- Use `%()` or `%Q()` for strings with many quotes
- Use heredocs (`<<~TEXT`) for multi-line strings with proper indentation
- Prefer `String#strip` for cleaning whitespace
- Use `String#squish` to remove excess whitespace in Rails

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

### Rails-Specific Conventions
- Use Rails time helpers instead of Ruby Time methods (`2.days.ago`, `Time.current`)
- Prefer `present?` and `blank?` over `nil?` and `empty?`
- Use safe navigation (`&.`) for potentially nil objects
- Prefer Rails collection methods over raw SQL when possible
- Use `find_each` and `in_batches` for processing large datasets
- Always use `Time.current` instead of `Time.now` (respects time zones)
- Use `Date.current` instead of `Date.today`

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

## Code Organization

### Namespacing Large Features

For bigger features or bounded contexts, use namespaces to organize code:

**When to Namespace:**
- Feature spans multiple models, controllers, and services
- Feature has its own subdomain or URL prefix
- Feature could be extracted to a separate engine in the future
- Clear separation improves maintainability

**Structure:**
```
app/
├── controllers/
│   └── admin/
│       ├── base_controller.rb
│       ├── users_controller.rb
│       └── posts_controller.rb
├── models/
│   └── admin/
│       └── dashboard_stats.rb
├── services/
│   └── admin/
│       ├── user_import.rb
│       └── generate_report.rb
├── views/
│   └── admin/
│       ├── users/
│       └── posts/
```

**Example Implementation:**

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :admin do
    resources :users
    resources :posts
    root to: "dashboard#index"
  end
end

# app/controllers/admin/base_controller.rb
module Admin
  class BaseController < ApplicationController
    before_action :require_admin

    layout "admin"

    private

    def require_admin
      redirect_to root_path unless current_user&.admin?
    end
  end
end

# app/controllers/admin/users_controller.rb
module Admin
  class UsersController < BaseController
    def index
      @users = User.paginate(page: params[:page], per_page: 25)
    end

    def destroy
      @user = User.find(params[:id])
      @user.destroy
      redirect_to admin_users_path, notice: "User deleted"
    end
  end
end

# app/services/admin/user_import.rb
module Admin
  class UserImport
    def initialize(file)
      @file = file
    end

    def call
      # Import logic
    end
  end
end
```

**Benefits:**
- Clear separation of concerns
- Easier to understand feature boundaries
- Simpler to test in isolation
- Facilitates future extraction if needed
- Better organization for large codebases

## Architecture Patterns

### Service Objects

**When to Use:**
- Complex business logic that spans multiple models
- Operations that interact with external APIs
- Multi-step processes with transactions
- Logic that doesn't belong in a model or controller

**Structure:**
- Place in `app/services/` organized by domain
- Name with verb + noun format: `CreateUser`, `ProcessPayment`, `SendWelcomeEmail`
- Include a single public `call` method (or `call!` for bang version)
- Return a result object or use dry-monads for success/failure
- Keep service objects focused—one responsibility per service
- Make them testable in isolation

```ruby
# app/services/users/create_user.rb
module Users
  class CreateUser
    attr_reader :params, :errors

    def initialize(params)
      @params = params
      @errors = []
    end

    def call
      user = User.new(user_params)

      ActiveRecord::Base.transaction do
        if user.save
          create_default_preferences(user)
          send_welcome_email(user)
          Success(user)
        else
          @errors = user.errors.full_messages
          Failure(errors)
        end
      end
    rescue StandardError => e
      Rails.logger.error("User creation failed: #{e.message}")
      Failure(["An unexpected error occurred"])
    end

    private

    def user_params
      params.require(:user).permit(:email, :name, :password)
    end

    def create_default_preferences(user)
      user.create_preference!(theme: "light", notifications: true)
    end

    def send_welcome_email(user)
      UserMailer.welcome_email(user).deliver_later
    end
  end
end

# Usage in controller
def create
  result = Users::CreateUser.new(params).call

  if result.success?
    redirect_to user_path(result.value), notice: "User created successfully"
  else
    @errors = result.failure
    render :new, status: :unprocessable_entity
  end
end
```

### Presenter Objects

**When to Use:**
- Complex view-specific logic
- Multiple conditional formatting rules
- Composing data from multiple models for display
- Keeping views clean and testable

**Structure:**
- Place in `app/presenters/`
- Name with noun + `Presenter`: `UserPresenter`, `OrderPresenter`, `DashboardPresenter`
- Delegate to underlying model(s) using `SimpleDelegator` or `delegate`
- Keep business logic out—only view formatting
- Make them easily testable

```ruby
# app/presenters/user_presenter.rb
class UserPresenter < SimpleDelegator
  def initialize(user, view_context = nil)
    super(user)
    @view_context = view_context
  end

  def full_name
    "#{first_name} #{last_name}".strip.presence || "Anonymous"
  end

  def formatted_created_at
    created_at.strftime("%B %d, %Y")
  end

  def status_badge
    h.content_tag(:span, status_text, class: "badge #{badge_class}")
  end

  def avatar_url(size: 100)
    return default_avatar unless avatar.attached?

    h.url_for(avatar.variant(resize_to_limit: [size, size]))
  end

  private

  def status_text
    active? ? "Active" : "Inactive"
  end

  def badge_class
    active? ? "badge-success" : "badge-danger"
  end

  def default_avatar
    h.image_path("default-avatar.png")
  end

  def h
    @view_context
  end
end

# Usage in controller
def show
  @user = UserPresenter.new(User.find(params[:id]), view_context)
end

# Usage in view
= @user.full_name
= @user.status_badge
```

### Query Objects

**When to Use:**
- Complex database queries
- Reusable query logic across controllers
- Queries with multiple optional filters
- Keeping models and controllers clean

```ruby
# app/queries/users/search_query.rb
module Users
  class SearchQuery
    def initialize(relation = User.all)
      @relation = relation
    end

    def call(params = {})
      @relation
        .then { |r| by_status(r, params[:status]) }
        .then { |r| by_role(r, params[:role]) }
        .then { |r| by_search_term(r, params[:q]) }
        .then { |r| by_date_range(r, params[:from], params[:to]) }
    end

    private

    def by_status(relation, status)
      return relation if status.blank?

      relation.where(status: status)
    end

    def by_role(relation, role)
      return relation if role.blank?

      relation.where(role: role)
    end

    def by_search_term(relation, query)
      return relation if query.blank?

      relation.where("name ILIKE ? OR email ILIKE ?", "%#{query}%", "%#{query}%")
    end

    def by_date_range(relation, from, to)
      relation = relation.where("created_at >= ?", from) if from.present?
      relation = relation.where("created_at <= ?", to) if to.present?
      relation
    end
  end
end

# Usage
@users = Users::SearchQuery.new.call(params)
```

### Form Objects

**When to Use:**
- Forms that don't map directly to a single model
- Forms that update multiple models
- Complex validation logic
- Virtual attributes that shouldn't be in the model

```ruby
# app/forms/registration_form.rb
class RegistrationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email, :string
  attribute :password, :string
  attribute :password_confirmation, :string
  attribute :company_name, :string
  attribute :accept_terms, :boolean

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }
  validates :password_confirmation, presence: true
  validates :company_name, presence: true
  validates :accept_terms, acceptance: true
  validate :passwords_match

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      user = User.create!(user_attributes)
      Company.create!(name: company_name, owner: user)
      true
    end
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end

  private

  def user_attributes
    { email: email, password: password }
  end

  def passwords_match
    return if password == password_confirmation

    errors.add(:password_confirmation, "doesn't match password")
  end
end
```

## Controller Guidelines

### Best Practices
- Keep controllers thin—delegate to service objects, query objects, or models
- Use strong parameters consistently
- Follow REST conventions—prefer resourceful routes
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
    params.require(:user).permit(:email, :name, :role)
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
- Minimize callbacks—use them only for model-specific concerns
- Never put business logic in callbacks

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
  after_create :send_welcome_email

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

  def send_welcome_email
    UserMailer.welcome_email(self).deliver_later
  end
end
```

### What to Avoid in Models
- Business logic that spans multiple models
- External API calls
- Complex multi-step processes
- Heavy computation
- Too many callbacks (especially `before_save`, `after_save`)
- Callbacks that update other models

## Database & ActiveRecord

### Migration Best Practices
- Use meaningful, descriptive migration names with timestamps
- Always add database indexes for foreign keys
- Add indexes for frequently queried columns
- Use `add_index` with appropriate options (`unique`, `where` for partial indexes)
- Use database constraints for data integrity (not just Rails validations)
- Use `change` method when possible for reversible migrations
- Use `up` and `down` for complex non-reversible migrations
- Add comments for complex database structures

```ruby
class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :status, null: false, default: "pending"
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.datetime :completed_at

      t.timestamps
    end

    add_index :orders, :status
    add_index :orders, :completed_at
    add_index :orders, [:user_id, :status]
    add_check_constraint :orders, "total_amount >= 0", name: "orders_total_amount_check"
  end
end
```

### Database Constraints
- Use `null: false` for required fields
- Use `default:` for fields with default values
- Use check constraints for data integrity
- Use unique constraints at database level
- Use foreign key constraints with appropriate `on_delete` behavior

```ruby
# Migration with constraints
class AddConstraintsToUsers < ActiveRecord::Migration[7.1]
  def change
    change_column_null :users, :email, false
    add_index :users, :email, unique: true
    add_check_constraint :users, "LENGTH(email) >= 3", name: "users_email_length_check"
  end
end
```

### Query Optimization
- Always use eager loading to avoid N+1 queries
- Use `includes` for loading associations you'll use
- Use `preload` when you don't need joins
- Use `joins` when filtering by associations
- Use `select` to load only needed columns for large datasets
- Use `pluck` for fetching single columns
- Use `exists?` instead of `present?` for existence checks
- Use `find_each` and `in_batches` for large datasets

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

# Bad - N+1 query
@users = User.all
@users.each do |user|
  puts user.posts.count # N+1 query!
end
```

### Transactions
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

## Views & Templates

### HAML Conventions
- Prefer HAML over ERB for cleaner, more maintainable views
- Use proper indentation (2 spaces)
- Use presenters for complex view logic
- Keep views simple and declarative
- Use partials to break down complex views

```haml
/ app/views/users/show.html.haml
.user-profile
  .user-header
    = image_tag @user.avatar_url, class: "avatar"
    %h1= @user.full_name
    = @user.status_badge

  .user-details
    %dl
      %dt Email
      %dd= @user.email

      %dt Member Since
      %dd= @user.formatted_created_at

  - if current_user.can_edit?(@user)
    .actions
      = link_to "Edit", edit_user_path(@user), class: "btn btn-primary"
```

### View Best Practices
- Use `data-testid` attributes for test selectors
- Avoid logic in views—use presenters or helpers
- Use partials for reusable components
- Use layouts for common page structure
- Use view helpers sparingly—prefer presenters
- Keep views focused on presentation

```haml
/ Using data-testid for testing
%button.btn.btn-primary{ data: { testid: "submit-button" } }
  Submit Order
```

## Testing

### RSpec Best Practices
- Follow Arrange-Act-Assert (AAA) pattern
- Use FactoryBot for test data, not fixtures
- Write descriptive test names
- Test behavior, not implementation
- Keep tests focused and isolated
- Use let and let! appropriately
- Use contexts for different scenarios
- Mock external dependencies

```ruby
# spec/services/users/create_user_spec.rb
require "rails_helper"

RSpec.describe Users::CreateUser do
  describe "#call" do
    let(:valid_params) do
      {
        user: {
          email: "test@example.com",
          name: "Test User",
          password: "password123"
        }
      }
    end

    context "with valid parameters" do
      it "creates a new user" do
        expect {
          described_class.new(valid_params).call
        }.to change(User, :count).by(1)
      end

      it "returns success result" do
        result = described_class.new(valid_params).call

        expect(result).to be_success
        expect(result.value).to be_a(User)
      end

      it "sends welcome email" do
        expect {
          described_class.new(valid_params).call
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        { user: { email: "", name: "" } }
      end

      it "does not create a user" do
        expect {
          described_class.new(invalid_params).call
        }.not_to change(User, :count)
      end

      it "returns failure result" do
        result = described_class.new(invalid_params).call

        expect(result).to be_failure
        expect(result.failure).to include("Email can't be blank")
      end
    end
  end
end
```

### Testing Strategy
- **Unit tests**: Test service objects, presenters, models in isolation
- **Integration tests**: Test controllers and request flows
- **System tests**: Test critical user journeys with real browser
- **Model tests**: Test validations, scopes, associations
- **Don't over-test**: Focus on behavior, not implementation details

```ruby
# System test example
require "rails_helper"

RSpec.describe "User Registration", type: :system do
  it "allows new user to register" do
    visit new_user_registration_path

    fill_in "Email", with: "newuser@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password Confirmation", with: "password123"

    click_button "Sign Up"

    expect(page).to have_content("Welcome!")
    expect(page).to have_current_path(dashboard_path)
  end
end
```

## Background Jobs

### Sidekiq/ActiveJob Best Practices
- Make jobs idempotent (safe to retry)
- Use explicit job classes instead of inline jobs
- Use meaningful queue names
- Set appropriate retry strategies
- Handle failures gracefully
- Keep jobs focused on single responsibility
- Pass IDs, not objects

```ruby
# app/jobs/send_notification_job.rb
class SendNotificationJob < ApplicationJob
  queue_as :notifications

  retry_on StandardError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError

  def perform(user_id, notification_type)
    user = User.find(user_id)

    case notification_type
    when "welcome"
      UserMailer.welcome_email(user).deliver_now
    when "reminder"
      UserMailer.reminder_email(user).deliver_now
    else
      raise ArgumentError, "Unknown notification type: #{notification_type}"
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error("User not found: #{user_id}")
    # Don't retry - user doesn't exist
  end
end

# Enqueue the job
SendNotificationJob.perform_later(user.id, "welcome")
```

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
        params.require(:user).permit(:email, :name)
      end
    end
  end
end
```

## Security

### Security Best Practices
- Always use strong parameters
- Sanitize user input (Rails does this by default in views)
- Use Rails CSRF protection (enabled by default)
- Use secure headers (via `secure_headers` gem or configuration)
- Implement proper authentication (Rails 8 built-in authentication)
- Implement proper authorization (CanCanCan)
- Never store sensitive data in logs
- Use encrypted credentials for secrets
- Implement rate limiting for APIs
- Validate and sanitize file uploads
- Use parameterized queries (ActiveRecord does this)

```ruby
# config/initializers/secure_headers.rb
SecureHeaders::Configuration.default do |config|
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.hsts = "max-age=31536000; includeSubDomains"
end

# Strong parameters
def user_params
  params.require(:user).permit(:email, :name, :role)
end

# Authorization with CanCanCan
def update
  @user = User.find(params[:id])
  authorize! :update, @user

  if @user.update(user_params)
    redirect_to @user
  else
    render :edit
  end
end
```

### Rails 8 Authentication

Rails 8 includes built-in authentication generators. Use them for standard authentication flows:

```bash
# Generate authentication
rails generate authentication
```

This creates:
- User model with password digest
- Sessions controller for login/logout
- Authentication concern for controllers

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  normalizes :email, with: -> { _1.strip.downcase }
end

# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
  end

  def create
    if user = User.authenticate_by(email: params[:email], password: params[:password])
      start_new_session_for user
      redirect_to after_authentication_url
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to root_path
  end
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Authentication

  before_action :require_authentication
end
```

### CanCanCan Authorization

Define abilities in a single file for clear authorization rules:

```ruby
# app/models/ability.rb
class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.admin?
      can :manage, :all
    elsif user.editor?
      can :read, :all
      can :manage, Post, user_id: user.id
      can :create, Post
      can :update, User, id: user.id
    elsif user.viewer?
      can :read, :all
      can :update, User, id: user.id
    else
      can :read, Post
    end
  end
end

# Usage in controllers
class PostsController < ApplicationController
  load_and_authorize_resource

  def index
    @posts = @posts.accessible_by(current_ability)
  end

  def create
    authorize! :create, Post
    # creation logic
  end
end

# Usage in views
- if can? :update, @post
  = link_to "Edit", edit_post_path(@post)

- if can? :destroy, @post
  = link_to "Delete", post_path(@post), method: :delete

# Handle authorization errors
class ApplicationController < ActionController::Base
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: exception.message
  end
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

## JavaScript & Frontend

### JavaScript Guidelines
- **Minimize JavaScript**: Only use when necessary
- **Prefer server-rendered HTML** with Hotwire (Turbo + Stimulus)
- Avoid complex frontend frameworks unless absolutely required
- Use vanilla JavaScript and Web Platform APIs where possible
- If you need a framework, choose one (React, Vue, Svelte)—don't mix
- **Test all JavaScript** with system tests (Capybara + headless Chrome)
- Handle errors explicitly with meaningful logs
- Use ES Modules or Import Maps, not asset pipeline
- Keep JavaScript modular and scoped

```javascript
// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }

  hide(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }
}
```

### Hotwire/Turbo
- Use Turbo Frames for partial page updates
- Use Turbo Streams for real-time updates
- Use Stimulus for lightweight interactivity
- Minimize custom JavaScript

```haml
/ Turbo Frame example
= turbo_frame_tag "user_#{@user.id}" do
  = render @user

/ Turbo Stream example
= turbo_stream_from "notifications"
```

## CSS & Styling

### CSS Guidelines
- **Control CSS growth**—every class is a carrying cost
- Keep CSS modular, scoped, and predictable
- Use a CSS framework (Tailwind, Bootstrap) or methodology (BEM)
- Avoid inline styles unless dynamically generated
- Avoid `!important` and global overrides
- Use CSS variables for theming
- Keep specificity low
- Use meaningful class names
- Organize CSS by component or page

```css
/* Good - BEM methodology */
.user-card {
  padding: 1rem;
  border: 1px solid #ddd;
}

.user-card__header {
  font-size: 1.5rem;
  font-weight: bold;
}

.user-card__body {
  margin-top: 1rem;
}

.user-card--highlighted {
  border-color: #007bff;
}

/* Bad - overly specific, !important */
div.container > .user-card > h2 {
  color: red !important;
}
```

## Git Workflow

### Git Best Practices
- Branch from `main` or `master`
- Use descriptive branch names: `feature/add-user-search`, `bugfix/fix-login-error`
- Write clear, descriptive commit messages
- Keep commits focused and atomic
- Pull requests must include: clear title, description, linked tickets
- Squash commits before merging to keep history clean
- Use conventional commits format: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`
- Review your own PR before requesting reviews

```bash
# Good branch names
feature/user-authentication
bugfix/fix-payment-calculation
refactor/extract-user-service
hotfix/security-patch

# Good commit messages
feat: add user search functionality
fix: correct payment calculation for discounts
refactor: extract user creation logic to service
docs: update API documentation for users endpoint
test: add specs for user registration flow
```

## Documentation

### Documentation Guidelines
- Write clear, descriptive commit messages
- Document complex business logic with comments only when necessary
- Use meaningful variable and method names (self-documenting code is best)
- **Avoid useless comments**—don't state the obvious
- Only add comments when code alone cannot express intent
- Keep README updated with setup instructions
- Document API endpoints (Swagger/OpenAPI)
- Write CHANGELOG for notable changes
- Document architectural decisions (ADRs)

### Comment Guidelines

**When to Add Comments:**
- Complex algorithms or business rules that aren't obvious
- Non-obvious performance optimizations
- Workarounds for known bugs or limitations
- Explanations of "why" (not "what")
- Legal requirements or compliance notes
- Links to relevant documentation or tickets

**When NOT to Add Comments:**
- Obvious operations (incrementing, assignment, etc.)
- Restating what the code does
- Commented-out code (delete it instead)
- Redundant information already in method/variable names
- Change history (use git instead)

```ruby
# BAD - Useless comments

# Increment counter by 1
counter += 1

# Get the user
user = User.find(params[:id])

# Loop through users
users.each do |user|
  # Send email
  send_email(user)
end

# Set the name
@name = "John"

# GOOD - Meaningful comments

# Skip validation for bulk imports to improve performance
# Validation happens at the CSV parsing stage
user.save(validate: false)

# Use exponential backoff for API retries per vendor documentation
# https://docs.vendor.com/retry-policy
wait_time = 2 ** attempt

# HIPAA requirement: encrypt all patient data at rest
# See compliance doc: docs/hipaa-compliance.md
encrypt_patient_data(data)

# GOOD - Self-documenting code (no comments needed)

def calculate_discount(total)
  case total
  when 0...100 then 0
  when 100...500 then 0.10
  when 500...1000 then 0.20
  else 0.30
  end
end

def active_premium_users
  User.where(status: :active, plan: :premium)
end
```

**Remember:** If you need extensive comments to explain what your code does, consider refactoring for clarity instead.

## What to Avoid

**Anti-Patterns:**
- Fat controllers with business logic
- Fat models with too many responsibilities
- Excessive use of callbacks (especially for business logic)
- Direct database queries in views
- Hardcoded values—use constants, configuration, or environment variables
- Overly complex nested routes (keep it to 2 levels max)
- Swallowing exceptions or "failing silently"
- Using `rescue nil` or empty rescue blocks
- Global state and mutable class variables
- Mixing concerns (business logic in controllers, view logic in models)
- Over-engineering simple solutions
- Premature optimization

## File Structure

```
app/
├── controllers/
│   ├── api/
│   │   └── v1/
│   │       ├── base_controller.rb
│   │       └── users_controller.rb
│   ├── application_controller.rb
│   └── users_controller.rb
├── models/
│   ├── concerns/
│   └── user.rb
├── services/
│   ├── users/
│   │   ├── create_user.rb
│   │   └── update_user.rb
│   └── payments/
│       └── process_payment.rb
├── queries/
│   └── users/
│       └── search_query.rb
├── presenters/
│   ├── user_presenter.rb
│   └── order_presenter.rb
├── forms/
│   └── registration_form.rb
├── jobs/
│   └── send_notification_job.rb
├── mailers/
│   └── user_mailer.rb
├── views/
│   └── users/
│       ├── index.html.haml
│       └── show.html.haml
├── helpers/
│   └── application_helper.rb
└── javascript/
    └── controllers/
```

## Additional Resources

- **Rails Guides**: https://guides.rubyonrails.org/
- **RuboCop Rails**: https://docs.rubocop.org/rubocop-rails/
- **RSpec Best Practices**: https://rspec.info/
- **CanCanCan Authorization**: https://github.com/CanCanCommunity/cancancan
- **Sidekiq**: https://github.com/sidekiq/sidekiq
- **will_paginate**: https://github.com/mislav/will_paginate

---

When writing code, prioritize readability, maintainability, and following Rails conventions. Always consider the long-term implications of architectural decisions.
