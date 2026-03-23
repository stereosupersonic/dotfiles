# Active Storage

## Attachment Removal via Checkbox

Allow users to remove attachments through a form:

```ruby
# app/models/account.rb
class Account < ApplicationRecord
  attribute :remove_logo, :boolean
  has_one_attached :logo

  before_save :unassign_logo, if: :remove_logo

  private

  def unassign_logo
    self.logo = nil
  end
end

# app/controllers/accounts_controller.rb
def account_params
  params.expect(account: [:logo, :remove_logo])
end
```

```haml
- if form.object.logo.attached?
  = image_tag form.object.logo
  = form.check_box :remove_logo, label: "Remove logo"

= form.label :logo
= form.file_field :logo
```

---

## Custom Storage Keys

Use custom keys for predictable, human-readable URLs:

```ruby
user.avatar.attach(
  io: File.open("/path/to/file"),
  filename: "avatar.png",
  key: "users/#{user.id}/avatar.png"
)
# => https://cdn.example.com/users/42/avatar.png
```

---

## has_many_attached: Keeping Existing Attachments

By default, attaching new files to `has_many_attached` replaces all existing attachments. Use hidden fields with `signed_id` to preserve them:

```haml
- @message.images.each do |image|
  = form.hidden_field :images, multiple: true, value: image.signed_id

= form.file_field :images, multiple: true
```

This lets JavaScript selectively remove individual existing attachments while adding new ones.

---

## Preserving Attachments on Validation Failure

Use direct uploads so files are sent to storage before form submission. They persist even if validation fails:

```haml
- if @user.avatar.attached?
  = form.hidden_field :avatar, value: @user.avatar.signed_id
= form.file_field :avatar, direct_upload: true
```

---

## Displaying Different Blob Types

```erb
<% @record.blobs.each do |blob| %>
  <% if blob.previewable? %>
    <%# PDFs, videos - generate preview image %>
    <%= image_tag blob.preview(resize_to_limit: [100, 100]).processed.url %>
  <% elsif blob.variable? %>
    <%# Images - create variant %>
    <%= image_tag blob.variant(resize_to_fill: [120, 120]) %>
  <% else %>
    <%# Other files - show content type %>
    <span>File: <%= blob.filename %> (<%= blob.content_type %>)</span>
  <% end %>
<% end %>
```

---

## Virtual Columns for Derived Data

Use PostgreSQL virtual columns to derive values stored in the database:

```ruby
class AddEncryptionKeyToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :encryption_key, :virtual,
      type: :string,
      as: "LEFT(device_token, 12)",
      stored: true
  end
end

# user.device_token   => "wTIsM5YiSmGS2r4fMJa7EZGea8xs3YzJ"
# user.encryption_key => "wTIsM5YiSmGS"  (auto-computed, stored)
```
