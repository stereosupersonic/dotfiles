# Delegated Types

Rails' `delegated_type` provides polymorphism without Single Table Inheritance's downsides.

## When to Use Delegated Types vs STI

| Problem with STI | Delegated Types Solution |
|-----------------|--------------------------|
| Sparse columns (many NULLs) | Each type has its own table |
| Growing monster table | Normalized, type-specific storage |
| Type-specific validations awkward | Natural per-type models |
| Hard to add type-specific columns | Just add to the specific table |

**Use delegated types when:**
- Types share some attributes but have type-specific data
- Types have different validation rules
- You want clean separation of concerns
- You're modeling real-world entities that share an interface

**Use STI when:**
- Types are very similar (only 1-2 different columns)
- Simplicity trumps normalization

---

## Basic Setup

### The Shared Module (Delegatee Interface)

```ruby
# app/models/contactable.rb
module Contactable
  extend ActiveSupport::Concern

  TYPES = %w[ User Person Service ]

  included do
    has_one :contact, as: :contactable, inverse_of: :contactable, touch: true
    belongs_to :account, default: -> { contact&.account }
  end

  # Interface contract — override in each type
  def display_name
    raise NotImplementedError
  end
end
```

### The Parent Model (Delegator)

```ruby
# app/models/contact.rb
class Contact < ApplicationRecord
  belongs_to :account
  has_many :accesses, dependent: :destroy

  delegated_type :contactable,
                 types: Contactable::TYPES,
                 inverse_of: :contact,
                 dependent: :destroy

  scope :accessible_to, ->(user) {
    joins(:accesses).where(accesses: { user: user })
  }
end
```

### Type-Specific Models

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include Contactable

  has_secure_password

  def display_name
    name.presence || email
  end
end

# app/models/person.rb
class Person < ApplicationRecord
  include Contactable

  validates :name, presence: true

  def display_name
    name
  end
end

# app/models/service.rb
class Service < ApplicationRecord
  include Contactable

  validates :name, :api_key, presence: true
  encrypts :api_key

  def display_name
    "#{name} (Service)"
  end
end
```

---

## Database Schema

```ruby
class CreateContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :contacts do |t|
      t.references :account, null: false, foreign_key: true
      t.string :contactable_type, null: false
      t.bigint :contactable_id, null: false
      t.timestamps

      t.index [:contactable_type, :contactable_id], unique: true
    end

    create_table :users do |t|
      t.string :name
      t.string :email, null: false
      t.string :password_digest
      t.timestamps
    end

    create_table :people do |t|
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.timestamps
    end

    create_table :services do |t|
      t.string :name, null: false
      t.string :api_key
      t.timestamps
    end
  end
end
```

---

## Usage Patterns

### Creating Records

```ruby
user = User.create!(name: "David", email: "david@hey.com", password: "secret")
contact = Contact.create!(account: account, contactable: user)
```

### Querying

```ruby
# All contacts (regardless of type)
account.contacts.accessible_to(current_user)

# Rails auto-generates type-specific scopes
Contact.users   # WHERE contactable_type = 'User'
Contact.people  # WHERE contactable_type = 'Person'
```

### Type Checking and Access

```ruby
contact.user?    # true if contactable_type == "User"
contact.person?  # true if contactable_type == "Person"

contact.contactable  # Returns the User/Person/Service
contact.user         # Returns User or nil
contact.person       # Returns Person or nil

# Polymorphic behavior — works for all types
contact.contactable.display_name

# Type-specific behavior when needed
case contact.contactable
when User
  contact.contactable.sessions.destroy_all
when Service
  contact.contactable.revoke_api_key!
end
```

---

## Advanced: The Recording Pattern

For applications with many content types sharing significant behavior (audit trails, access control, lifecycle management, activity feeds), the Recording pattern extends delegated types into a full architectural pattern.

**Core idea:** A `Recording` model is a lightweight pointer (creator, timestamps, parent, bucket/container) while the specific content (`Recordable`) holds the actual data and is immutable — edits create new rows rather than updating in place. This enables zero-cost copying and version history.

**Use this pattern when:**
- 5+ content types share significant behavior
- You need unified activity feeds or audit trails
- Access control spans content types
- You expect to add new content types over time
- Version history is important

**Skip it when:**
- Content types are truly independent
- You have only 2–3 simple models
- Shared behavior is minimal

See the [Basecamp Recording pattern](https://dev.37signals.com/active-record-nice-and-blended/) for the full implementation reference.
