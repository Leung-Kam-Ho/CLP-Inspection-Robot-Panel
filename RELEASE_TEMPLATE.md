# Release Template

Use this template for consistent release notes.

```markdown
## Release vX.Y.Z

One-line summary of the release.

### ✨ What's New

- **Feature Name** — Brief description of the feature and why it matters.
- **Another Feature** — Brief description.

### 🛠️ Under the Hood

- **Improvement Name** — Technical detail aimed at maintainers.
- **Another change** — Brief description.

### 🐛 Fixes

- **Issue description** — What was broken and how it was resolved.
```

## Style Guide

| Element | Convention |
|---|---|
| **Header** | `## Release vX.Y.Z` (level-2 heading) |
| **Summary** | Single sentence on the line below the header |
| **Section headings** | `### ✨ What's New` / `### 🛠️ Under the Hood` / `### 🐛 Fixes` |
| **Items** | `- **Title Case Name** — Description.` (bold, em-dash, space, sentence) |
| **Tone** | Concise, user-facing for "What's New", technical for "Under the Hood" |
| **Emoji** | ✨ features, 🛠️ internals, 🐛 fixes |
| **Trailing punctuation** | Always use a period at the end of each item. |
