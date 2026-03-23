# Security

## Security Best Practices
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

# Strong parameters (Rails 8+)
def user_params
  params.expect(user: [:email, :name, :role])
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

## Rails 8 Authentication

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

## XSS Prevention

Rails auto-escapes view output by default — the main risk is explicitly bypassing that protection.

**Never do this with user-generated content:**
```ruby
<%= @user.bio.html_safe %>   # user can inject <script> tags
<%= raw @comment.body %>     # same risk
content_tag :div, params[:content].html_safe
```

**Embedding user data in JavaScript requires explicit escaping:**
```ruby
# Bad - not escaped in JS context
<script>var msg = "<%= @message %>";</script>

# Good - to_json handles escaping
<script>var msg = <%= @message.to_json %>;</script>
```

**When you need to allow limited HTML (e.g. rich text):**
```ruby
<%= sanitize @post.body, tags: %w[strong em a], attributes: %w[href] %>
```

---

## Session Management

**Secure cookie settings:**
```ruby
# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store,
  key: "_app_session",
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax
```

**Always reset the session on login** to prevent session fixation:
```ruby
def create
  if user = User.authenticate_by(...)
    reset_session           # must come before writing to session
    session[:user_id] = user.id
    redirect_to root_path
  end
end
```

---

## CanCanCan Authorization

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
