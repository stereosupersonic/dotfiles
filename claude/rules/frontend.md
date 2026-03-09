# Frontend: JavaScript & CSS

## JavaScript Guidelines
- **Minimize JavaScript**: Only use when necessary
- **Prefer server-rendered HTML** with Hotwire (Turbo + Stimulus)
- Avoid complex frontend frameworks unless absolutely required
- Use vanilla JavaScript and Web Platform APIs where possible
- If you need a framework, choose one (React, Vue, Svelte)—don't mix
- **Test all JavaScript** with system tests (Capybara + headless Chrome)
- Handle errors explicitly with meaningful logs
- Use ES Modules or Import Maps, not asset pipeline
- Keep JavaScript modular and scoped

```javascript
// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }

  hide(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }
}
```

## Hotwire/Turbo
- Use Turbo Frames for partial page updates
- Use Turbo Streams for real-time updates
- Use Stimulus for lightweight interactivity
- Minimize custom JavaScript

```haml
/ Turbo Frame example
= turbo_frame_tag "user_#{@user.id}" do
  = render @user

/ Turbo Stream example
= turbo_stream_from "notifications"
```

## CSS Guidelines
- **Control CSS growth**—every class is a carrying cost
- Keep CSS modular, scoped, and predictable
- Use a CSS framework (Tailwind, Bootstrap) or methodology (BEM)
- Avoid inline styles unless dynamically generated
- Avoid `!important` and global overrides
- Use CSS variables for theming
- Keep specificity low
- Use meaningful class names
- Organize CSS by component or page

```css
/* Good - BEM methodology */
.user-card {
  padding: 1rem;
  border: 1px solid #ddd;
}

.user-card__header {
  font-size: 1.5rem;
  font-weight: bold;
}

.user-card__body {
  margin-top: 1rem;
}

.user-card--highlighted {
  border-color: #007bff;
}

/* Bad - overly specific, !important */
div.container > .user-card > h2 {
  color: red !important;
}
```
