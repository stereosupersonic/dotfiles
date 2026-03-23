# Object-Oriented Design Principles

## Sandi Metz Rules

Practical constraints from "Practical Object-Oriented Design in Ruby" that encourage better OO design.

- **Classes ≤ 100 lines** — large classes violate SRP and become hard to understand, test, and maintain
- **Methods ≤ 5 lines** — short methods do one thing, have clear names, and are easy to test and reuse
- **Methods ≤ 4 parameters** — too many parameters mean the method is doing too much or needs a class
- **Controllers instantiate ≤ 1 object** — controllers coordinate; multiple instantiations signal a missing service layer
- **Views reference ≤ 1 instance variable** — multiple instance variables couple views tightly to controllers; use presenters

These are guidelines, not laws. Break them when you have a specific reason, but document why.

---

## Law of Demeter

**"Only talk to your immediate friends"** — an object should only call methods on:
1. Itself
2. Objects passed as parameters
3. Objects it creates
4. Its direct component objects (instance variables)

**Violations look like train wrecks:**
```ruby
# Bad - chaining through multiple objects
order.user.shipping_address.city.tax_rate
@post.author.profile.avatar_url
```

**Fix with delegation:**
```ruby
# Hide navigation behind methods
class Order
  delegate :tax_rate, to: :user
end

class User
  delegate :tax_rate, to: :shipping_address
end
```

---

## SOLID Principles

### S — Single Responsibility Principle

A class should have one, and only one, reason to change.

**Violations:** class name contains "And", "Manager", or "Handler"; class has methods operating on different data; hard to give a concise name.

```ruby
# Bad - user model doing everything
class User < ApplicationRecord
  def send_welcome_email = UserMailer.welcome_email(self).deliver_now
  def sync_to_crm = CrmApi.create_contact(email:, name:)
  def generate_activity_report = activities.map { |a| "#{a.created_at}: #{a.description}" }.join("\n")
end

# Good - each class has one job
class User < ApplicationRecord
  validates :email, presence: true
end

class UserNotifier
  def initialize(user) = @user = user
  def send_welcome_email = UserMailer.welcome_email(@user).deliver_now
end

class UserCrmSync
  def initialize(user) = @user = user
  def sync = CrmApi.create_contact(email: @user.email, name: @user.name)
end
```

---

### O — Open/Closed Principle

Software entities should be open for extension but closed for modification.

Add new functionality without changing existing code. Use abstraction and polymorphism.

**Violations:** long `case` statements that grow with new types; modifying existing methods to handle new cases.

```ruby
# Bad - must modify this method to add a new format
def generate(report_type, data)
  case report_type
  when :pdf then generate_pdf(data)
  when :csv then generate_csv(data)
  end
end

# Good - new formats extend without touching existing code
class PdfReportGenerator
  def generate(data) = # PDF logic
end

class CsvReportGenerator
  def generate(data) = # CSV logic
end

class ReportService
  def initialize(generator) = @generator = generator
  def create_report(data) = @generator.generate(data)
end
```

---

### L — Liskov Substitution Principle

Objects of a subclass should be replaceable with objects of the superclass without breaking the application.

**Violations:** subclass raises exceptions the parent doesn't; type-checking with `is_a?` before calling a method; subclass removes functionality.

```ruby
# Bad - Penguin breaks any code written against Bird
class Bird
  def fly = "Flying!"
end

class Penguin < Bird
  def fly = raise "Penguins can't fly!"  # LSP violation
end

# Good - redesign the abstraction
class Bird
  def move = raise NotImplementedError
end

class FlyingBird < Bird
  def move = "Flying!"
end

class Penguin < Bird
  def move = "Swimming!"
end
```

**Key rule:** if you need to check the type before calling a method, LSP is probably violated.

---

### I — Interface Segregation Principle

No class should be forced to depend on methods it does not use. Many specific interfaces are better than one general-purpose one.

**Violations:** classes implementing modules with empty/no-op methods; fat concerns forcing unrelated behavior.

```ruby
# Bad - RobotWorker forced to implement human-specific methods
module Workable
  def work = raise NotImplementedError
  def eat_lunch = raise NotImplementedError
  def take_break = raise NotImplementedError
end

# Good - split into focused modules
module Workable
  def work = raise NotImplementedError
end

module Feedable
  def eat_lunch = raise NotImplementedError
end

class HumanWorker
  include Workable
  include Feedable
end

class RobotWorker
  include Workable  # only what it needs
end
```

**Rails example:** split fat concerns into focused modules. A `Comment` model might `include Publishable` but not `include Schedulable` or `include SocialMediaIntegrated`.

---

### D — Dependency Inversion Principle

High-level modules should not depend on low-level modules. Both should depend on abstractions.

**Violations:** classes instantiating their own dependencies; hard-coded class names; code that's hard to test due to concrete dependencies.

```ruby
# Bad - tightly coupled to Stripe and SMTP
class OrderProcessor
  def process(order)
    StripeGateway.new.charge(order.amount)
    SmtpMailer.new.send_confirmation(order.user.email)
  end
end

# Good - depends on abstractions, injected from outside
class OrderProcessor
  def initialize(payment_gateway:, mailer:)
    @payment_gateway = payment_gateway
    @mailer = mailer
  end

  def process(order)
    @payment_gateway.charge(order.amount)
    @mailer.send_confirmation(order.user.email)
  end
end

# Easy to test
OrderProcessor.new(
  payment_gateway: MockGateway.new,
  mailer: MockMailer.new
)
```

In Rails, service objects with injected dependencies are the primary application of DIP. Controllers wire up the dependencies and pass them to services.
