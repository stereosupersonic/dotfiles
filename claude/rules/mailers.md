# ActionMailer Conventions

## Mailer Conventions
- Name mailers with `Mailer` suffix: `UserMailer`, `OrderMailer`
- Provide both HTML and plain-text templates for every email
- Always use `_url` helpers in emails, never `_path` (emails need absolute URLs)
- Format from/to addresses properly: `"Your Name <info@site.com>"`
- Send emails in background jobs, not during request handling
- Inline CSS for HTML emails (e.g., `premailer-rails` or `roadie`)

## Environment Configuration
- Enable delivery errors in development: `config.action_mailer.raise_delivery_errors = true`
- Use a local SMTP server in development (e.g., Mailcatcher, letter_opener)
- Set `default_url_options[:host]` per environment
- Use `:test` delivery method in test environment

```ruby
# config/environments/development.rb
config.action_mailer.raise_delivery_errors = true
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

# config/environments/production.rb
config.action_mailer.default_url_options = { host: "app.example.com", protocol: "https" }

# app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  default from: "App Name <noreply@example.com>"
  layout "mailer"
end

# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  def welcome_email(user)
    @user = user
    mail(to: @user.email, subject: "Welcome to App Name")
  end
end
```
