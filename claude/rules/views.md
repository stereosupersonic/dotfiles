# Views, Templates & I18n

## HAML Conventions
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

## View Best Practices
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

## Internationalization (I18n)

### Translation Key Conventions

**Use relative translation keys in views:**
```ruby
# Good - relative keys (Rails resolves based on view path)
# In app/views/users/show.html.haml
= t(".title")           # Looks up "users.show.title"
= t(".welcome_message") # Looks up "users.show.welcome_message"

# Avoid - absolute keys are verbose and repetitive
= t("users.show.title")
= t("users.show.welcome_message")
```

**Use `_html` or `_md` suffix for rich content:**
```yaml
# config/locales/en.yml
en:
  users:
    show:
      title: "User Profile"
      bio_html: "<strong>About:</strong> %{content}"
      welcome_md: "Welcome to **your dashboard**!"
```

```ruby
# In view - automatically marks as html_safe
= t(".bio_html", content: @user.bio)

# For markdown content (if using a markdown renderer)
= render_markdown(t(".welcome_md"))
```

### I18n Best Practices
- Translate all user-facing content
- Use YAML anchors for shared translations
- Keep translation files organized by feature/namespace
- Use interpolation for dynamic values: `t(".greeting", name: @user.name)`
- For forms, use `include_blank: t(".select_option")` instead of hardcoded strings
- Test translations exist in your test suite

```ruby
# Form with translated blank option
= f.select :category, @categories, include_blank: t(".select_category")

# Pluralization
= t(".items_count", count: @items.size)
# en.yml: items_count:
#   one: "1 item"
#   other: "%{count} items"
```
