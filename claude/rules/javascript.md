# JavaScript

## Philosophy

- **Minimize JavaScript**: Only use when necessary
- **Prefer server-rendered HTML** with Hotwire (Turbo + Stimulus)
- Avoid complex frontend frameworks unless absolutely required
- Use vanilla JavaScript and Web Platform APIs where possible
- If you need a framework, choose one (React, Vue, Svelte) — don't mix
- **Test all JavaScript** with system tests (Capybara + headless Chrome)
- Handle errors explicitly with meaningful logs
- Use ES Modules or Import Maps, not the asset pipeline
- Keep JavaScript modular and scoped
- No inline JavaScript

## Variables

- Always use `const`; use `let` only when reassignment is needed; never use `var`
- Declare one variable per `const`/`let` statement
- Group `const` declarations before `let` declarations

```javascript
// Good
const count = 5
const name = 'Alice'
let index = 0

// Bad
var x = 1
let a = 1, b = 2
```

## Strings

- Use single quotes `''` for strings
- Use template literals for interpolation and multi-line strings — never concatenation
- Never use `eval()`

```javascript
// Good
const greeting = `Hello, ${name}!`

// Bad
const greeting = 'Hello, ' + name + '!'
```

## Functions

- Use arrow functions for anonymous callbacks
- Use default parameters instead of mutating arguments; place defaults last
- Use rest syntax (`...args`) instead of the `arguments` object
- Never mutate or reassign parameters

```javascript
// Good
const double = (n) => n * 2
const add = (a, b = 0) => a + b
const sum = (...numbers) => numbers.reduce((a, b) => a + b, 0)

// Bad
function(list) { arguments[0] = list || [] }
```

## Objects & Arrays

- Use literal syntax: `{}` not `new Object()`, `[]` not `new Array()`
- Use shorthand for methods and property values
- Use object spread over `Object.assign` for shallow copies
- Use spread syntax to copy arrays: `[...items]`
- Use destructuring when accessing multiple properties

```javascript
// Good
const copy = { ...original, extra: true }
const [first, ...rest] = items
const { name, email } = user

// Bad
const copy = Object.assign({}, original, { extra: true })
```

## Modules

- Always use `import`/`export` — never CommonJS `require`
- No wildcard imports (`import * as Foo`)
- Import from a path only once
- Place all imports before other statements

```javascript
// Good
import { Controller } from '@hotwired/stimulus'
import { formatDate } from '../utils/date'
```

## Classes

- Always use `class` syntax — never manipulate `prototype` directly
- Use `extends` for inheritance
- Avoid empty constructors

## Naming

- Use camelCase for variables, functions, and instances
- Use PascalCase for classes and constructors
- No single-letter names — be descriptive
- No leading or trailing underscores

## Iterators & Control Flow

- Prefer `map`/`filter`/`reduce`/`find` over `for` loops
- Use `===` and `!==` — never `==` or `!=`
- Use braces for all multi-line blocks

```javascript
// Good
const doubled = numbers.map((n) => n * 2)
const active = users.filter((u) => u.active)

// Bad
for (let i = 0; i < numbers.length; i++) { ... }
if (x == null) { ... }
```

## Formatting

- 2-space indentation
- 100-character line limit
- Semicolons at end of statements
- Trailing commas in multi-line structures
- Spaces inside object braces: `{ key: value }`, not inside array brackets

## Hotwire / Stimulus

- Use Turbo Frames for partial page updates
- Use Turbo Streams for real-time updates
- Use Stimulus for lightweight interactivity
- Minimize custom JavaScript beyond Stimulus controllers

```javascript
// app/javascript/controllers/dropdown_controller.js
import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['menu']

  toggle() {
    this.menuTarget.classList.toggle('hidden')
  }

  hide(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add('hidden')
    }
  }
}
```
