# RSpec Conventions

RSpec-specific syntax and formatting rules. For testing philosophy, which spec types to write, and TDD workflow see `testing.md`.

## Structure & Naming

- Use `.method_name` for class methods and `#method_name` for instance methods in `describe` blocks
- Context descriptions start with `when`, `with`, or `without` and form readable sentences
- `it` descriptions use present tense, third person — "returns X", not "should return X"
- Keep `it` descriptions under 60 characters
- Every `context` should have a corresponding negative/opposite context
- Never end an `it` description with a conditional — wrap the condition in a `context` instead
- Don't generate tests with iterators — each scenario needs its own explicit block

```ruby
# Good
RSpec.describe Article do
  describe ".published" do         # class method
    context "when published" do
      it "returns the article" do ... end
    end

    context "when not published" do
      it "returns nothing" do ... end
    end
  end

  describe "#title" do             # instance method
    it "returns the formatted title" do ... end
  end
end

# Bad
it "should return the user"        # 'should' phrasing
it "returns user if admin is true" # conditional in description
```

## Declaration Order

Within an example group, order declarations consistently:

1. `subject`
2. `let!` / `let`
3. `before` / `after`
4. nested `describe` / `context` / `it` blocks

```ruby
RSpec.describe Order do
  subject(:order) { build(:order, user: user) }

  let(:user) { create(:user) }
  let(:product) { create(:product) }

  before { order.add_item(product) }

  it "has one item" do
    expect(order.items.size).to eq(1)
  end
end
```

## subject

- Always use a named subject: `subject(:user) { ... }` — anonymous subjects make tests hard to read
- Use anonymous subject only when using `is_expected`
- Don't stub methods on the subject — provide the needed state through initialization or factory traits

```ruby
# Good
subject(:user) { create(:user, :admin) }

it "can manage all resources" do
  expect(user).to be_admin
end

# Good - anonymous subject with is_expected
subject { build(:user, active: true) }
it { is_expected.to be_active }
```

## let & let!

- Use `let` for lazy-evaluated shared data across examples
- Use `let!` when the value must exist regardless of whether the example references it (e.g., database records that need to be present for queries)
- Replace instance variables in `before` blocks with `let`
- Don't overuse `let` to the point of making tests hard to follow — inline data is fine for single-use values

```ruby
# Good - let for shared setup
let(:user) { create(:user) }
let(:post) { create(:post, author: user) }

# Good - let! for records that must exist for the query under test
let!(:published_post) { create(:post, published: true) }
let!(:draft_post) { create(:post, published: false) }

it "returns only published posts" do
  expect(Post.published).to contain_exactly(published_post)
end
```

## Hooks

- Omit `:each`/`:example` scope in `before`/`after` — it's the default
- Use `:context` instead of `:all` to avoid ambiguity
- Avoid `before(:context)` / `after(:context)` — shared state leaks between examples

```ruby
# Good
before { sign_in(user) }

# Bad
before(:each) { sign_in(user) }  # :each is redundant
```

## Expectations & Matchers

- Always use `expect` syntax — never `should`
- Use predicate matchers over calling the method directly

```ruby
# Good
expect(user).to be_admin
expect(response).to be_successful
expect(list).to be_empty

# Bad
expect(user.admin?).to be true
expect(response.successful?).to eq(true)
```

- Use built-in matchers over manual checks

```ruby
# Good
expect(title).to include("Welcome")
expect(user.errors[:email]).to include("is invalid")
expect { action }.to change(User, :count).by(1)
expect { action }.to raise_error(ActiveRecord::RecordNotFound)

# Bad
expect(title.include?("Welcome")).to be true
```

- Avoid bare `be` matcher — use `be_truthy`, `be_nil`, or a specific matcher
- Use `aggregate_failures` when multiple expectations logically belong together

```ruby
it "returns user data", :aggregate_failures do
  expect(response).to have_http_status(:ok)
  expect(json[:email]).to eq(user.email)
  expect(json[:name]).to eq(user.full_name)
end
```

## Doubles & Mocking

- Prefer verifying doubles (`instance_double`, `class_double`) over plain `double` — they validate the interface exists
- Never use `allow_any_instance_of` or `expect_any_instance_of` — it's a sign the code needs refactoring
- Never disable `verify_partial_doubles`
- Use `stub_const` instead of defining constants directly in example groups — constants leak into global namespace

```ruby
# Good
let(:mailer) { instance_double(UserMailer) }
before { allow(UserMailer).to receive(:new).and_return(mailer) }

# Bad
let(:mailer) { double("mailer") }  # no interface verification
```

## Shared Examples

Use shared examples to eliminate duplication across contexts. Prefer `it_behaves_like` for behavior and `include_examples` for helper matchers:

```ruby
RSpec.shared_examples "a published resource" do
  it "is visible to the public" do
    expect(subject).to be_publicly_visible
  end
end

RSpec.describe Article do
  subject { create(:article, :published) }
  it_behaves_like "a published resource"
end
```

## FactoryBot

- Every model must have a factory
- Factories should produce valid objects by default — verify this with one spec per factory
- Use traits for variations, not multiple factories
- Use `build` over `create` when the record doesn't need to be persisted

```ruby
# Good - trait for variations
factory :user do
  name { Faker::Name.name }
  email { Faker::Internet.email }

  trait :admin do
    role { :admin }
  end

  trait :inactive do
    active { false }
  end
end

# Usage
create(:user, :admin)
build(:user, :inactive)
```

## Formatting

- No empty line after `describe`/`context`/`feature` opening
- One empty line between consecutive `describe`/`context` blocks
- One empty line after `let`/`subject`/`before`/`after` blocks
- One empty line around `it`/`specify` blocks

```ruby
RSpec.describe User do
  describe "#full_name" do
    let(:user) { build(:user, first_name: "John", last_name: "Doe") }

    it "joins first and last name" do
      expect(user.full_name).to eq("John Doe")
    end

    it "strips extra whitespace" do
      user.last_name = ""
      expect(user.full_name).to eq("John")
    end
  end

  describe "#admin?" do
    context "when role is admin" do
      subject(:user) { build(:user, :admin) }

      it { is_expected.to be_admin }
    end

    context "when role is not admin" do
      subject(:user) { build(:user) }

      it { is_expected.not_to be_admin }
    end
  end
end
```
