# Testing

## Testing Philosophy
- **Prefer real objects over mocks/stubs** - Use actual model instances and database records
- Only mock external dependencies (APIs, email services, third-party integrations)
- Test behavioral outcomes (status codes, data changes, rendered content)
- Don't mock internal classes or methods—this couples tests to implementation

```ruby
# Good - real objects
it "creates a user" do
  user = create(:user)
  post = create(:post, user: user)

  expect(post.author).to eq(user)
end

# Avoid - excessive mocking of internal code
it "creates a user" do
  user = instance_double(User, id: 1)
  allow(User).to receive(:find).and_return(user)
  # ...this couples the test to implementation details
end

# Good - mock external services
it "sends notification to Slack" do
  slack_client = instance_double(SlackClient)
  allow(SlackClient).to receive(:new).and_return(slack_client)
  expect(slack_client).to receive(:post_message)

  NotificationService.new.notify("Hello")
end
```

## RSpec Best Practices
- Follow Arrange-Act-Assert (AAA) pattern
- Use FactoryBot for test data, not fixtures
- Write descriptive test names
- Test behavior, not implementation
- Keep tests focused and isolated
- Use let and let! appropriately
- Use contexts for different scenarios
- Only mock external dependencies

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

## Time-Dependent Tests

Use `freeze_time` or `travel_to` for tests that depend on the current time. Never rely on `Time.current` producing a stable value during test execution.

```ruby
# Good - frozen time
it "expires after 30 days" do
  freeze_time do
    subscription = create(:subscription)
    travel 31.days
    expect(subscription).to be_expired
  end
end

# Good - specific time
it "shows morning greeting before noon" do
  travel_to Time.zone.local(2024, 6, 15, 9, 0) do
    expect(helper.greeting).to eq("Good morning")
  end
end

# Bad - don't use travel_to with Time.now/Time.current just to freeze
travel_to(Time.current) { ... } # Use freeze_time instead
```

## Testing Strategy
- **Unit tests**: Test service objects, presenters, models in isolation
- **Integration tests**: Test controllers and request flows
- **System tests**: Test the user journeys with real browser. Happy path.
- **Model tests**: Test validations, scopes, associations
- **Don't over-test**: Focus on behavior, not implementation details

## System Test Selectors

Use Rails DOM helpers instead of string interpolation for cleaner, more maintainable tests:

```ruby
# Good - use Rails helpers
find(css_id(@user))                    # => "#user_123"
find(css_id(@user, :edit))             # => "#edit_user_123"
click_on css_id(@post, :delete)        # => "#delete_post_456"
within(css_id(@comment)) { ... }

# Avoid - string interpolation
find("#user_#{@user.id}")              # Harder to read, error-prone
find("#edit_user_#{@user.id}")

# For class-based selectors
find(css_class("active"))              # => ".active"
find(css_class("user", "premium"))     # => ".user.premium"
```

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

  it "shows user profile after creation" do
    user = create(:user)
    visit user_path(user)

    within(css_id(user)) do
      expect(page).to have_content(user.name)
    end
  end
end
```
