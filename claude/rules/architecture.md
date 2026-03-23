# Architecture Patterns

## Code Organization

### Namespacing Large Features

For bigger features or bounded contexts, use namespaces to organize code:

**When to Namespace:**
- Feature spans multiple models, controllers, presenters and services
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
│   ├── post.rb
│   └── admin/
│       └── dashboard_stats.rb
├── presenters/
│   ├── base_presenter.rb
│   ├── post_presenter.rb
│   └── admin/
│       ├── user_presenter.rb
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
  resources :posts
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

### File Structure

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

## Service Objects

**When to Use:**

The Golden Rule: A Service Object = Business Use Case

- Complex business logic that spans multiple models
- Operations that interact with external APIs
- Multi-step processes with transactions
- Logic that doesn't belong in a model or controller
- Return Rich Result Objects, not Booleans or Active Records
- Service objects should be stateless. no instance state, no persistent internal data, all inputs passed as parameters
- One Responsibility Per Service. Each service should do one thing.
- Don't create services for: simple CRUD, trivial model logic or single-line operations

**Structure:**
- Create a base_service.rb object
- Place in `app/services/` organized by domain
- Name with verb + noun format: `CreateUser`, `ProcessPayment`, `SendWelcomeEmail`
- Include a single public `call` method
- Provide `self.call` class method via BaseService for convenience
- Return a result object or use dry-monads for success/failure
- Keep service objects focused—one responsibility per service
- Make them testable in isolation
- it uses  ActiveModel::Model for validation and adding values via attr_accessor

```ruby
# app/services/base_service.rb
class BaseService

  include ActiveModel::Model
  def self.call(...)
    new(...).call
  end

  def call
    raise NotImplementedError, "#{self.class}#call must be implemented"
  end
end

# app/services/users/create_user.rb
module Users
  class CreateUser < BaseService
    attr_accessor :params, :errors

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
      # Note: In Rails 8+, prefer params.expect in the controller
      # and pass clean params to the service
      params.expect(user: [:email, :name, :password])
    end

    def create_default_preferences(user)
      user.create_preference!(theme: "light", notifications: true)
    end

    def send_welcome_email(user)
      UserMailer.welcome_email(user).deliver_later
    end
  end
end
```

## Presenter Objects

**When to Use:**
- Complex view-specific logic
- Multiple conditional formatting rules
- Composing data from multiple models for display
- Keeping views clean and testable
- Presenters should never contain business logic.
- Good: formatting, display rules, string composition, HTML helpers
- Prefer instantiate in the view over the controller

**Structure:**
- Place in `app/presenters/`
- Name with noun + `Presenter`: `UserPresenter`, `OrderPresenter`, `DashboardPresenter`
- Delegate to underlying model(s) using `SimpleDelegator` or `delegate`
- Keep business logic out—only view formatting
- Make them easily testable

```ruby
# app/presenter/application_presenter.rb
require "delegate"

class ApplicationPresenter < SimpleDelegator
  alias object __getobj__
  alias h helpers
  alias o object

  def initialize(object, view = nil)
    super(object)
    @view = view
  end

  def helpers
    ApplicationController.helpers
  end

  def url_helpers
    Rails.application.routes.url_helpers
  end

  def t(key, **options)
    I18n.t(key, **options)
  end
end

# app/presenters/user_presenter.rb
class UserPresenter < ApplicationPresenter
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

end

# Usage in controller
def show
  @user = User.find(params[:id])
end

# Usage in view
- user_presenter = UserPresenter.new(@user)
= user_presenter.full_name
= user_presenter.status_badge
```

## Finder Objects

Finders are Plain Old Ruby Objects (PORO) that are used for searching. It is a design pattern that lets us extract query logic from Controllers and Models into reusable classes.

Problems to solve: Fat models, fat controllers, separation of concerns.

Located in `app/finders/`.

**When to Use:**
- Complex database queries
- Reusable query logic across controllers
- Queries with multiple optional filters
- Keeping models and controllers clean

```ruby
class UserEventsFinder
  include ActiveModel::Model

  FILTERS = %i[user_id event start_date end_date shop_id source done_by_id]
  attr_accessor :per_page, :page
  attr_accessor(*FILTERS)

  def call
    UserEvent
      .order("done_at DESC")
      .merge(start_date_filter)
      .merge(end_date_filter)
      .merge(event_filter)
      .merge(user_id_filter)
      .merge(shop_filter)
      .merge(source_filter)
      .merge(done_by_id_filter)
      .paginate(page: page, per_page: per_page)
  end

  private

  def shop_filter
    if shop_id.present?
      UserEvent.where(shop_id: shop_id)
    else
      UserEvent.all
    end
  end

  def source_filter
    if source.present?
      UserEvent.where(source: source)
    else
      UserEvent.all
    end
  end

  def start_date_filter
    if start_date.present?
      UserEvent.where("done_at >= ?", start_date.to_datetime.beginning_of_day)
    else
      UserEvent.all
    end
  end

  def end_date_filter
    if end_date.present?
      UserEvent.where("done_at <= ?", end_date.to_datetime.end_of_day)
    else
      UserEvent.all
    end
  end

  def event_filter
    event.present? ? UserEvent.where(name: event) : UserEvent.all
  end

  def user_id_filter
    user_id.present? ? UserEvent.where(user_id: user_id) : UserEvent.all
  end

  def done_by_id_filter
    done_by_id.present? ? UserEvent.where(done_by_id: done_by_id) : UserEvent.all
  end
end

# usage:
@user_events = UserEventsFinder.new(search_params).call
```

## Form Objects

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

## Helpers

* use helpers rarley better are Presenter Objects
* NEVER put them inside of controllers
