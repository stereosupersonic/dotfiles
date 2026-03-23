---
name: Backend Migration Standards
description: Create and manage database migrations with reversible changes, proper naming conventions, and zero-downtime deployment strategies. Use this skill when creating database migration files, modifying schema, adding or removing tables/columns, managing indexes, or handling data migrations. Apply when working with migration files (e.g., db/migrate/, migrations/, alembic/, sequelize migrations), schema changes, database versioning, rollback implementations, or when you need to ensure backwards compatibility during deployments. Use for any task involving database structure changes, index creation, constraint modifications, or data transformation scripts.
---
# Database Migration Standards

Apply these rules when creating or modifying database migrations. Migrations are permanent records of schema evolution and must be treated with extreme care.


## Core Principles

**Reversibility is Mandatory**: Every migration MUST have a working rollback method. Test the down migration immediately after writing the up migration. If a change cannot be reversed safely (e.g., dropping a column with data), document why in comments and consider a multi-step approach.

**One Logical Change Per Migration**: Each migration should do exactly one thing - add a table, add a column, create an index, etc. This makes debugging easier, rollbacks safer, and code review clearer. If you need to make multiple related changes, create multiple migrations.

**Never Modify Deployed Migrations**: Once a migration runs in any shared environment (staging, production), it becomes immutable. Create a new migration to fix issues. Modifying deployed migrations breaks version control and causes deployment failures.


## General Rules

* use the same rails version for new create migrations e.g. ActiveRecord::Migration[8.0]

**Naming Convention**: Use timestamps and descriptive names that indicate the change:
- `20241118120000_add_email_to_users.py`
- `20241118120100_create_orders_table.rb`
- `20241118120200_add_index_on_users_email.js`

The name should answer "what does this migration do?" without reading the code.

**File Organization**:
- Schema changes: `migrations/schema/`
- Data migrations: `migrations/data/`
- Keep them separate for rollback safety and clarity

## Column Type Conventions


**Other column type guidelines:**
- Use `datetime` instead of `timestamp` for consistency
- Boolean columns should always have `default:` and `null: false` to avoid the 3-state problem (`true`/`false`/`nil`). If you need three states, use an enum instead
- Use `decimal` for money (with precision and scale), never `float`

## Migration Best Practices
- Use meaningful, descriptive migration names with timestamps
- Always add database indexes for foreign keys
- Add indexes for frequently queried columns
- Use `add_index` with appropriate options (`unique`, `where` for partial indexes)
- Use database constraints for data integrity (not just Rails validations)
- Use `change` method when possible for reversible migrations
- Use `up` and `down` for complex non-reversible migrations
- Add comments for complex database structures
- Name foreign keys explicitly with the `name:` option — don't rely on auto-generated FK names
- When using models in migrations, define a local migration-scoped class to avoid future breakage

```ruby
# Define a local model class in migrations to decouple from app code
class BackfillUserStatus < ActiveRecord::Migration[7.1]
  class MigrationUser < ActiveRecord::Base
    self.table_name = :users
  end

  def up
    MigrationUser.where(status: nil).update_all(status: "active")
  end
end
```

```ruby
class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.text :status, null: false, default: "pending"  # Use text, not string
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.datetime :completed_at  # Use datetime, not timestamp

      t.timestamps
    end

    add_index :orders, :status
    add_index :orders, :completed_at
    add_index :orders, [:user_id, :status]
    add_check_constraint :orders, "total_amount >= 0", name: "orders_total_amount_check"
  end
end
```

## Database Constraints
- Use `null: false` for required fields
- Use `default:` for fields with default values
- Use check constraints for data integrity
- Use unique constraints at database level
- Use foreign key constraints with appropriate `on_delete` behavior

```ruby
# Migration with constraints
class AddConstraintsToUsers < ActiveRecord::Migration[7.1]
  def change
    change_column_null :users, :email, false
    add_index :users, :email, unique: true
    add_check_constraint :users, "LENGTH(email) >= 3", name: "users_email_length_check"
  end
end
```

## Zero-Downtime Deployments

**Backwards Compatibility**: New migrations must work with the currently deployed code version. Deploy order:
1. Deploy migration (schema change)
2. Deploy new code (uses new schema)

**Additive Changes First**: When changing column types or constraints:
1. Add new column/table
2. Deploy code that writes to both
3. Backfill data
4. Deploy code that reads from new location
5. Remove old column/table

**Foreign Key Constraints**: Add in separate migration after data is consistent to avoid validation failures.

## Testing Migrations

**Before Committing**:
1. Run migration up: `rake db:migrate` or equivalent
2. Verify schema changes: Check database structure
3. Run migration down: `rake db:rollback` or equivalent
4. Verify rollback worked: Check schema restored
5. Run migration up again: Ensure it's repeatable

**Test with Production-Like Data**: Use anonymized production data dump to test migrations against realistic data volumes and edge cases.

## Red Flags - Stop and Reconsider

If you're about to:
- Modify an existing migration file that's been deployed
- Drop a column without a multi-step plan
- Create a migration without a down method
- Mix schema and data changes in one migration
- Add a NOT NULL column without a default to a large table
- Create an index without CONCURRENT on a production table

**STOP. Review this document and plan a safer approach.**

## Checklist Before Committing

- [ ] Migration has descriptive timestamp-based name
- [ ] Down/rollback method implemented and tested
- [ ] Ran migration up successfully
- [ ] Ran migration down successfully
- [ ] Ran migration up again (repeatability check)
- [ ] No schema and data changes mixed
- [ ] Large table indexes use concurrent creation
- [ ] NOT NULL columns on existing tables have defaults
- [ ] Changes are backwards compatible with deployed code
- [ ] Considered zero-downtime deployment requirements
