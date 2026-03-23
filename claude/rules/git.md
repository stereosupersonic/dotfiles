---
description: "Git and PR conventions"
# no paths: = loads every session
---

# Commits
- Append Jira key or GitHub issue: [MP-XXX]
- Imperative mood: "Fix bug" not "Fixed bug"

# Always branch first
- Never work on main. Remind me if I haven't branched.

## Git Best Practices
- Branch from `main` or `master`
- Use descriptive branch names: `add-user-search`, `fix-login-error`
- Use the github issue number as part of the branch name if it exists
- Write clear, descriptive commit messages
- Keep commits focused and atomic
- Pull requests must include: clear title, description, linked tickets
- Squash commits before merging to keep history clean
- Use conventional commits format: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`
- Review your own PR before requesting reviews

```bash
# Good branch names
16_user-authentication
fix-payment-calculation
extract-user-service
11_security-patch

# Good commit messages
feat: add user search functionality
fix: correct payment calculation for discounts
refactor: extract user creation logic to service
docs: update API documentation for users endpoint
test: add specs for user registration flow
```

## Documentation Guidelines
- Write clear, descriptive commit messages
- Document complex business logic with comments only when necessary
- Use meaningful variable and method names (self-documenting code is best)
- **Avoid useless comments**—don't state the obvious
- Only add comments when code alone cannot express intent
- Keep README updated with setup instructions
- Document API endpoints (Swagger/OpenAPI)
- Write CHANGELOG for notable changes
- Document architectural decisions (ADRs)

## Comment Guidelines

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
