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

## Semantic HTML

- **Use semantic HTML first**: mark up content with the correct tag for its meaning (`<h1>`, `<nav>`, `<section>`, `<aside>`, `<ol>`, `<button>`, etc.)
- **Then** use `<div>` and `<span>` only to solve layout/styling problems
- If you see a `<div>` in a view, it should mean "this is purely for styling"
- Don't choose HTML tags based on their appearance; choose based on purpose
- Semantic markup = more stable views = more stable tests (anchoring on `<button>`, `<nav>`, `<ul>` is more stable than class selectors)
- No business logic in views — views should not make database queries or perform calculations

## View Best Practices

- Avoid logic in views—use presenters or helpers
- Use partials for reusable components
- Use layouts for common page structure
- Use view helpers sparingly—prefer presenters
- Keep views focused on presentation
- Pass local variables to partials instead of relying on instance variables — makes partials reusable and dependencies explicit

```haml
/ Good - pass locals to partials
= render "shared/user_card", user: @user

/ Bad - partial relies on instance variable
= render "shared/user_card"
/ (and inside the partial: @user — implicit, fragile, not reusable)
```

## Internationalization (I18n)

### Translation Key Conventions

**Use full translation key paths in views:**
```ruby
# Good - explicit full paths, greppable and unambiguous
# In app/views/users/show.html.haml
= t("users.show.title")
= t("users.show.welcome_message")

# Avoid - lazy lookup (dot-prefixed) hides the actual key path
= t(".title")           # Implicit — hard to grep, breaks on partial moves
= t(".welcome_message")
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
= t("users.show.bio_html", content: @user.bio)

# For markdown content (if using a markdown renderer)
= render_markdown(t("users.show.welcome_md"))
```

### use linter

- source: https://github.com/sds/haml-lint
- install: gem 'haml_lint', require: false
- Usage: haml-lint app/views/

### I18n Best Practices
- Translate all user-facing content
- Use YAML anchors for shared translations
- Keep translation files organized by feature/namespace
- Use interpolation for dynamic values: `t("users.show.greeting", name: @user.name)`
- For forms, use `include_blank: t("users.form.select_option")` instead of hardcoded strings
- Test translations exist in your test suite

```ruby
# Form with translated blank option
= f.select :category, @categories, include_blank: t("posts.form.select_category")

# Pluralization
= t("posts.index.items_count", count: @items.size)
# en.yml: items_count:
#   one: "1 item"
#   other: "%{count} items"
```

### Locale File Organization

Organize locale files into subdirectories by concern:

```
config/
└── locales/
    ├── en.yml                  # Shared formats (date, currency, number)
    ├── models/
    │   ├── user.en.yml
    │   └── post.en.yml
    └── views/
        ├── users.en.yml
        └── posts.en.yml
```

Load subdirectories in `config/application.rb`:

```ruby
config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]
```

### Partials Consolidation

- When a partial is used from only one view, consider inlining it — partials add indirection and file count without benefit when not reused
