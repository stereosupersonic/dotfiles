# CSS

## Philosophy

- **Control CSS growth** — every class is a carrying cost
- Keep CSS modular, scoped, and predictable
- Use a CSS framework (Tailwind, Bootstrap) or methodology (BEM)
- Avoid inline styles unless dynamically generated
- Avoid `!important` and global overrides
- Use CSS variables for theming
- Keep specificity low
- Use meaningful class names
- Organize CSS by component or page
- No inline CSS

## BEM Methodology

When not using a utility framework, use BEM (Block Element Modifier):

```css
/* Block */
.user-card {
  padding: 1rem;
  border: 1px solid #ddd;
}

/* Element */
.user-card__header {
  font-size: 1.5rem;
  font-weight: bold;
}

.user-card__body {
  margin-top: 1rem;
}

/* Modifier */
.user-card--highlighted {
  border-color: #007bff;
}

/* Bad - overly specific, uses !important */
div.container > .user-card > h2 {
  color: red !important;
}
```

## CSS Variables

Use custom properties for theming and repeated values:

```css
:root {
  --color-primary: #007bff;
  --color-text: #333;
  --spacing-md: 1rem;
}

.button {
  background-color: var(--color-primary);
  padding: var(--spacing-md);
}
```

## Specificity Rules

- Prefer class selectors over element or ID selectors
- Never use `!important` — refactor the specificity instead
- Avoid deep nesting — keep selectors flat
- Avoid styling by element tag unless it's a global reset
