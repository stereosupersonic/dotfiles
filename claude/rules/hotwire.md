# Hotwire: Turbo & Stimulus

## Philosophy

- Prefer server-rendered HTML with Hotwire over client-side JavaScript
- Use Turbo Frames for partial page updates
- Use Turbo Streams for precise DOM mutations (append, replace, remove)
- Use Turbo 8 morphing (`broadcast_refresh`) for complex nested structures
- Use Stimulus for lightweight interactivity only — one controller, one responsibility
- Test with system specs (Capybara), not JavaScript unit tests

---

## Turbo Frames

### Lazy-Loading with Skeleton UI

```erb
<%= turbo_frame_tag :table, src: "/table", lazy: true do %>
  <div class="animate-pulse">
    <div class="bg-neutral-50 rounded-xl h-16"></div>
    <div class="bg-neutral-50 rounded-xl h-96 mt-4"></div>
  </div>
<% end %>
```

### Infinite Scroll

```erb
<%= turbo_frame_tag "accounts_#{@accounts.current_page}" do %>
  <%= render @accounts %>

  <% unless @accounts.last_page? %>
    <%= turbo_frame_tag "accounts_#{@accounts.next_page}",
                        src: path_to_next_page(@accounts),
                        loading: "lazy" do %>
      <span>Loading...</span>
    <% end %>
  <% end %>
<% end %>
```

### Search with URL Updates

```slim
= form_for posts_path, method: :get, html: { data: { turbo_frame: 'posts', turbo_action: 'advance' } } do
  = search_field_tag :q, params[:q], placeholder: 'Search...'

= turbo_frame_tag 'posts' do
  = render partial: 'posts/post', collection: @posts
  = pagy_nav(@pagy)
```

The `turbo_action: 'advance'` updates the browser URL with search params automatically.

### Turbo Frame Request Variants

Detect Turbo Frame requests and serve appropriate templates:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :turbo_frame_request_variant

  private

  def turbo_frame_request_variant
    request.variant = :turbo_frame if turbo_frame_request?
  end
end

# app/views/index.html+turbo_frame.erb — serves only the frame content
```

---

## Turbo Streams

### Basic Stream Actions in Views

```erb
<%= turbo_stream_action_tag "append", target: "messages", template: %(#{render @message}) %>
<%= turbo_stream_action_tag "replace", target: "pager", template: %(#{render "pager", pagy: @pagy}) %>
```

### Like Button Toggle

```ruby
# Controller
class LikesController < ApplicationController
  before_action :set_todo

  def create
    @like = @todo.likes.where(user: current_user).first_or_create
  end

  def destroy
    @like = @todo.likes.find_by(user: current_user)
    @like.destroy
    render :create
  end
end
```

```erb
<%# likes/create.turbo_stream.erb %>
<%= turbo_stream.replace(dom_id(@todo, :like), partial: "likes/like", locals: { todo: @todo, like: @like }) %>
<%= turbo_stream.update(dom_id(@todo, :likes_count), @todo.likes.count) %>
```

---

## Turbo 8 Morphing

Turbo 8 introduces `broadcast_refresh` — broadcast a refresh signal and let morphing handle the DOM diff instead of crafting specific stream actions.

### Layout Setup

```erb
<%# app/views/layouts/application.html.erb %>
<head>
  <%= turbo_refreshes_with method: :morph, scroll: :preserve %>
</head>
```

### Model Broadcasting with Touch Chain

```ruby
class Board < ApplicationRecord
  has_many :columns, dependent: :destroy
  after_update_commit -> { broadcast_refresh }
end

class Column < ApplicationRecord
  belongs_to :board, touch: true  # touches board → triggers broadcast_refresh
  has_many :cards, dependent: :destroy
end

class Card < ApplicationRecord
  belongs_to :column, touch: true  # touches column → touches board → broadcast
end
```

### Subscription in View

```erb
<%= turbo_stream_from @board %>

<div id="<%= dom_id(@board) %>">
  <%= render @board.columns %>
</div>
```

### When to Use Morphing vs Traditional Streams

| Use morphing (`broadcast_refresh`) | Use traditional streams |
|------------------------------------|------------------------|
| Complex nested structures | Simple append to a list |
| Multiple elements change together | Single-element precise updates |
| Dashboard-style pages | Notifications |
| New to a feature (simpler code) | Ordered lists where position matters |

### Conditional Broadcasting

```ruby
class Card < ApplicationRecord
  after_update_commit :broadcast_changes

  private

  def broadcast_changes
    return unless saved_change_to_position? || saved_change_to_column_id?
    board.broadcast_refresh
  end
end
```

### Debounced Broadcasting

```ruby
class Board < ApplicationRecord
  after_update_commit :broadcast_refresh_later

  private

  def broadcast_refresh_later
    BroadcastRefreshJob.set(wait: 100.milliseconds).perform_later(self)
  end
end
```

### View Rules for Morphing

```erb
<%# GOOD: stable IDs let morphing match elements %>
<div id="<%= dom_id(card) %>"><%= card.title %></div>

<%# BAD: random IDs break morphing %>
<div id="card-<%= SecureRandom.hex %>"><%= card.title %></div>

<%# Prevent morphing specific elements (video, audio, flash) %>
<div data-turbo-permanent id="flash-messages">
  <%= render "shared/flash" %>
</div>
```

---

## Stimulus Controllers

### Design Principles

- Configure behavior through `data` attributes (static values/classes)
- Controllers communicate via dispatched events, not direct references
- Keep internal logic in private methods
- One controller, one responsibility

### Controller Communication Pattern

```javascript
// Parent listens for child events
// parent_controller.js
handleChildEvent(event) {
  const { text } = event.detail
}

// child_controller.js
doSomething() {
  this.dispatch("done", { detail: { text: "completed" } })
}
```

```erb
<div data-controller="parent"
     data-action="child:done->parent#handleChildEvent">
  <button data-controller="child"
          data-action="click->child#doSomething">Go</button>
</div>
```

---

## Stimulus Controller Catalog

Copy-paste-ready controllers for common UI patterns.

### Clipboard

```javascript
// app/javascript/controllers/clipboard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]
  static values = { content: String }
  static classes = ["copied"]

  copy(event) {
    event.preventDefault()
    const text = this.hasContentValue ? this.contentValue : this.sourceTarget.value

    navigator.clipboard.writeText(text).then(() => {
      this.element.classList.add(this.copiedClass)
      this.dispatch("copied", { detail: { text } })
      setTimeout(() => this.element.classList.remove(this.copiedClass), 2000)
    })
  }
}
```

```erb
<div data-controller="clipboard" data-clipboard-copied-class="bg-green-100">
  <input data-clipboard-target="source" value="Copy this text" readonly>
  <button data-action="clipboard#copy">Copy</button>
</div>
```

### Element Removal (flash messages, dismissible alerts)

```javascript
// app/javascript/controllers/element_removal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  remove() {
    this.element.remove()
  }
}
```

```erb
<%# Auto-dismiss on animation end %>
<div data-controller="element-removal"
     data-action="animationend->element-removal#remove"
     class="flash">
  <%= notice %>
</div>

<%# Manual dismiss %>
<div data-controller="element-removal" class="alert">
  <p>Alert content</p>
  <button data-action="element-removal#remove">Dismiss</button>
</div>
```

### Toggle (accordions, tabs, show/hide)

```javascript
// app/javascript/controllers/toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]
  static classes = ["active", "hidden"]
  static values = { exclusive: Boolean }

  toggle(event) {
    const item = event.currentTarget

    if (this.exclusiveValue) {
      this.itemTargets.forEach(target => {
        target.classList.remove(this.activeClass)
        target.classList.add(this.hiddenClass)
      })
    }

    item.classList.toggle(this.activeClass)
    item.classList.toggle(this.hiddenClass)
    this.dispatch("toggled", { detail: { item } })
  }

  show(event) {
    const item = this.#findItem(event)
    item?.classList.remove(this.hiddenClass)
    item?.classList.add(this.activeClass)
  }

  hide(event) {
    const item = this.#findItem(event)
    item?.classList.add(this.hiddenClass)
    item?.classList.remove(this.activeClass)
  }

  #findItem(event) {
    const id = event.params?.id
    return id ? this.itemTargets.find(t => t.id === id) : event.currentTarget
  }
}
```

### Autoresize Textarea

```javascript
// app/javascript/controllers/autoresize_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { minRows: { type: Number, default: 2 } }

  connect() {
    this.resize()
  }

  resize() {
    this.element.style.height = "auto"
    const minHeight = this.minRowsValue * parseInt(getComputedStyle(this.element).lineHeight)
    this.element.style.height = Math.max(this.element.scrollHeight, minHeight) + "px"
  }

  reset() {
    this.element.style.height = "auto"
  }
}
```

```erb
<%= form.text_area :body,
  data: {
    controller: "autoresize",
    autoresize_min_rows_value: 3,
    action: "input->autoresize#resize"
  } %>
```

### Hotkey (keyboard shortcuts)

```javascript
// app/javascript/controllers/hotkey_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { key: String, ctrl: Boolean, meta: Boolean, shift: Boolean }

  connect() {
    this.boundHandler = this.#handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandler)
  }

  #handleKeydown(event) {
    if (this.#matchesKey(event)) {
      event.preventDefault()
      this.element.click()
    }
  }

  #matchesKey(event) {
    return event.key.toLowerCase() === this.keyValue.toLowerCase() &&
      (!this.ctrlValue || event.ctrlKey) &&
      (!this.metaValue || event.metaKey) &&
      (!this.shiftValue || event.shiftKey)
  }
}
```

```erb
<button data-controller="hotkey"
        data-hotkey-key-value="k"
        data-hotkey-meta-value="true"
        data-action="click->search#open">
  Search (⌘K)
</button>
```

### Dialog (Native HTML Modal)

```javascript
// app/javascript/controllers/dialog_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]
  static values = { closeOnOutsideClick: { type: Boolean, default: true } }

  connect() {
    if (this.closeOnOutsideClickValue) {
      this.dialogTarget.addEventListener("click", this.#handleBackdropClick.bind(this))
    }
  }

  open() {
    this.dialogTarget.showModal()
    document.body.style.overflow = "hidden"
    this.dispatch("opened")
  }

  close() {
    this.dialogTarget.close()
    document.body.style.overflow = ""
    this.dispatch("closed")
  }

  #handleBackdropClick(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
```

```erb
<div data-controller="dialog">
  <button data-action="dialog#open">Open</button>

  <dialog data-dialog-target="dialog">
    <h2>Modal Title</h2>
    <button data-action="dialog#close">Close</button>
  </dialog>
</div>
```

```css
dialog::backdrop { background: rgba(0, 0, 0, 0.5); }
dialog { border: none; border-radius: 0.5rem; padding: 0; }
```

### Form (loading states & Turbo integration)

```javascript
// app/javascript/controllers/form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit", "error"]
  static classes = ["loading", "error"]
  static values = { resetOnSuccess: Boolean }

  connect() {
    this.element.addEventListener("turbo:submit-start", this.#onSubmitStart.bind(this))
    this.element.addEventListener("turbo:submit-end", this.#onSubmitEnd.bind(this))
  }

  #onSubmitStart() {
    this.submitTarget.disabled = true
    this.element.classList.add(this.loadingClass)
    this.element.classList.remove(this.errorClass)
    this.errorTargets.forEach(el => el.textContent = "")
  }

  #onSubmitEnd(event) {
    this.submitTarget.disabled = false
    this.element.classList.remove(this.loadingClass)

    if (event.detail.success) {
      this.dispatch("success")
      if (this.resetOnSuccessValue) this.element.reset()
    } else {
      this.element.classList.add(this.errorClass)
      this.dispatch("error")
    }
  }
}
```

### Local Save (Draft Persistence)

```javascript
// app/javascript/controllers/local_save_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field"]
  static values = { key: String, debounce: { type: Number, default: 1000 } }

  connect() {
    this.#restore()
  }

  save() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const data = {}
      this.fieldTargets.forEach(field => { data[field.name] = field.value })
      localStorage.setItem(this.keyValue, JSON.stringify(data))
      this.dispatch("saved")
    }, this.debounceValue)
  }

  clear() {
    localStorage.removeItem(this.keyValue)
    this.dispatch("cleared")
  }

  #restore() {
    const saved = localStorage.getItem(this.keyValue)
    if (!saved) return
    const data = JSON.parse(saved)
    this.fieldTargets.forEach(field => { if (data[field.name]) field.value = data[field.name] })
    this.dispatch("restored")
  }
}
```

```erb
<%= form_with model: @post,
  data: {
    controller: "local-save",
    local_save_key_value: "post_draft_#{current_user.id}",
    action: "turbo:submit-end->local-save#clear"
  } do |f| %>
  <%= f.text_field :title, data: { local_save_target: "field", action: "input->local-save#save" } %>
  <%= f.text_area :body, data: { local_save_target: "field", action: "input->local-save#save" } %>
  <%= f.submit %>
<% end %>
```

### Auto-Click (trigger on connect)

```javascript
// app/javascript/controllers/auto_click_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.click()
  }
}
```

### Fetch on Visible (lazy-load on scroll)

```javascript
// app/javascript/controllers/fetch_on_visible_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.observer = new IntersectionObserver(
      entries => entries.forEach(entry => this.#handleIntersection(entry)),
      { threshold: 0.1 }
    )
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
  }

  #handleIntersection(entry) {
    if (entry.isIntersecting) {
      this.observer.disconnect()
      this.#fetch()
    }
  }

  async #fetch() {
    try {
      const response = await fetch(this.urlValue, { headers: { "Accept": "text/html" } })
      this.element.outerHTML = await response.text()
    } catch (error) {
      console.error("Fetch on visible failed:", error)
    }
  }
}
```

```erb
<div data-controller="fetch-on-visible"
     data-fetch-on-visible-url-value="<%= post_comments_path(@post) %>">
  <span>Loading comments...</span>
</div>
```

### Local Time (display in user's timezone)

```javascript
// app/javascript/controllers/local_time_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { datetime: String, format: { type: String, default: "relative" } }

  connect() {
    this.#render()
    if (this.formatValue === "relative") {
      this.interval = setInterval(() => this.#render(), 60000)
    }
  }

  disconnect() {
    if (this.interval) clearInterval(this.interval)
  }

  #render() {
    const date = new Date(this.datetimeValue)
    switch (this.formatValue) {
      case "relative": this.element.textContent = this.#relativeTime(date); break
      case "date": this.element.textContent = date.toLocaleDateString(); break
      case "time": this.element.textContent = date.toLocaleTimeString(); break
      case "datetime": this.element.textContent = date.toLocaleString(); break
    }
  }

  #relativeTime(date) {
    const seconds = Math.floor((new Date() - date) / 1000)
    const minutes = Math.floor(seconds / 60)
    const hours = Math.floor(minutes / 60)
    const days = Math.floor(hours / 24)
    if (seconds < 60) return "just now"
    if (minutes < 60) return `${minutes}m ago`
    if (hours < 24) return `${hours}h ago`
    if (days < 7) return `${days}d ago`
    return date.toLocaleDateString()
  }
}
```

```erb
<time data-controller="local-time"
      data-local-time-datetime-value="<%= message.created_at.iso8601 %>"
      data-local-time-format-value="relative"
      datetime="<%= message.created_at.iso8601 %>">
  <%= message.created_at %>
</time>
```

---

## ViewComponent

Use ViewComponent for reusable UI components with slots:

```ruby
# app/components/ui/card.rb
class UI::Card < ApplicationComponent
  renders_one :title
  renders_one :body

  def initialize(title: nil)
    @title_text = title
  end
end
```

```erb
<%# app/components/ui/card.html.erb %>
<div class="rounded-2xl p-6 bg-white border shadow">
  <% if title? %>
    <%= title %>
  <% else %>
    <h2><%= @title_text %></h2>
  <% end %>
  <%= body %>
</div>

<%# Usage %>
<%= render UI::Card.new(title: "Hello!") do |c| %>
  <% c.body { "This is a card!" } %>
<% end %>
```
