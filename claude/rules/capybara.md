# Capybara

Style rules for Capybara system/feature specs, based on the [Capybara Style Guide](https://github.com/rubocop/capybara-style-guide).

## Actions

**Prefer specific click methods over generic `click`:**

```ruby
# Good
click_link "Sign in"
click_button "Submit"

# Bad
find("a", text: "Sign in").click
find("input[type=submit]").click
```

**Use specific form helpers over generic `find` + action:**

```ruby
# Good
fill_in "Email", with: "user@example.com"
check "Terms of service"
select "Admin", from: "Role"

# Bad
find("input#email").fill_in("user@example.com")
find("input[type=checkbox]").check
```

## Finders

**Use the most specific finder available:**

```ruby
# Good
find_button "Submit"
find_field "Email"
find_link "Sign in"

# Bad
find("button", text: "Submit")
find("input[name=email]")
find("a", text: "Sign in")
```

## Matchers

**Use specific matchers over `have_selector`:**

```ruby
# Good
expect(page).to have_button("Submit")
expect(page).to have_field("Email")
expect(page).to have_link("Sign in")
expect(page).to have_table("Users")
expect(page).to have_select("Role")
expect(page).to have_text("Welcome")

# Bad
expect(page).to have_selector("button", text: "Submit")
expect(page).to have_selector("input[name=email]")
expect(page).to have_selector("a", text: "Sign in")
```

**Use `have_css` or `have_xpath` instead of `have_selector`:**

```ruby
# Good
expect(page).to have_css("div.notification")
expect(page).to have_xpath("//table/tr")

# Bad
expect(page).to have_selector("div.notification")
expect(page).to have_selector(:xpath, "//table/tr")
```

**Use RSpec predicate matchers over calling predicate methods directly:**

```ruby
# Good
expect(page).to have_button("Submit")
expect(page).to have_text("Welcome")

# Bad
expect(page.has_button?("Submit")).to be true
expect(page.has_text?("Welcome")).to eq(true)
```

## Negation

**Pick one negation style and use it consistently — don't mix both:**

```ruby
# Good — always use have_no_* matchers
expect(page).to have_no_button("Delete")
expect(page).to have_no_text("Error")

# Also fine — always use not_to
expect(page).not_to have_button("Delete")
expect(page).not_to have_text("Error")

# Bad — mixing both styles
expect(page).to have_no_button("Delete")
expect(page).not_to have_text("Error")
```

Prefer `have_no_*` — it avoids Capybara's wait behavior quirks with `not_to`.

## Visibility

**Use symbolic visibility values, not booleans:**

```ruby
# Good
find("input", visible: :hidden)
find("div", visible: :all)
expect(page).to have_css(".tooltip", visible: :visible)

# Bad
find("input", visible: false)
find("div", visible: true)
```

## Scoping

**Avoid redundant nested `within` blocks:**

```ruby
# Good
within "#user-profile" do
  expect(page).to have_text("John Doe")
  click_link "Edit"
end

# Bad
within "#user-profile" do
  within find("#user-profile") do
    expect(page).to have_text("John Doe")
  end
end
```

## Path Expectations

**Don't assert on `current_path` — assert on page content instead:**

```ruby
# Good
expect(page).to have_text("Dashboard")
expect(page).to have_heading("Welcome back")

# Bad
expect(page.current_path).to eq(dashboard_path)
expect(current_path).to eq("/dashboard")
```

## General

- Prefer semantic locators (label text, button text, ARIA labels) over CSS selectors — they're more stable and test accessibility
- Use `within` to scope interactions to a specific region of the page
- Avoid `sleep` — use Capybara's built-in waiting matchers instead
- Set `Capybara.default_max_wait_time` in `spec/support/capybara.rb`, not per-test

```ruby
# Good — Capybara waits automatically
expect(page).to have_text("Saved successfully")

# Bad — arbitrary sleep
sleep 1
expect(page).to have_text("Saved successfully")
```
