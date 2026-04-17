# Canto — Claude's markdown companion

> Edit `CLAUDE.md`, memories, plans, and all your markdown — visually, right inside your IDE.

Canto is a VS Code extension that gives [Claude Code](https://claude.com/claude-code) users a dedicated, visual editor for the markdown files that power their Claude projects: `CLAUDE.md`, `.claude/memory/*.md`, plans, and docs.

**Website:** [canto.basicstech.org](https://canto.basicstech.org)
**Source:** [github.com/basicstech/canto](https://github.com/basicstech/canto)

## Features

### WYSIWYG markdown editor

Edit `.md` files directly in the rendered view — no more switching between raw markdown and a preview.

- Bold, italic, headings, lists, tables, code blocks — all with real-time visual feedback
- Keyboard shortcuts (`⌘B`, `⌘I`, `⌘K` for links)
- Slash commands for quick inserts
- Three modes: **WYSIWYG**, **Instant Rendering**, **Split View**
- Theme-aware — follows your VS Code dark/light theme

### Claude Code sidebar

Dedicated view in the activity bar:

- **CLAUDE.md** — one click to open project instructions
- **Memory** — all your memories, categorized; `+ New Memory` creates one with the right frontmatter
- **Plans** — all your plans from `docs/superpowers/plans/` or `.claude/plans/`
- **Config** — quick access to Claude Code settings

### Documents view

A second tree view showing all markdown in the workspace: root files first, then folders with counts.

## Install

```
ext install basicstech.canto
```

Or search for **Canto** in the Extensions panel.

### Compatibility

Works in **VS Code** 1.85+, **Cursor**, **Windsurf**, **VSCodium** — any editor built on the VS Code Extension API.

## Usage

1. Open a folder with a `.claude/` directory (or any folder with markdown)
2. Click the **Canto** icon in the activity bar
3. Click any file in the sidebar to open it in the WYSIWYG editor
4. Right-click a `.md` file in Explorer → **Canto: Open WYSIWYG Editor**

## Keyboard shortcuts

- `⌘B` — Bold
- `⌘I` — Italic
- `⌘K` — Link
- `⌘Shift+K` — Inline code
- `⌘1`–`⌘6` — Headings
- `⌘E` — Code block

## Why "Canto"?

A canto is a section of a long poem. Fits the Anthropic family (Opus, Sonnet, Haiku) and works in English, Spanish, Italian, Portuguese.

## Support

- **Issues / feature requests:** [github.com/basicstech/canto/issues](https://github.com/basicstech/canto/issues)
- **Email:** [canto@basicstech.org](mailto:canto@basicstech.org)

## License

MIT © [BasicsTech](https://basicstech.org)
