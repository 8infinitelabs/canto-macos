# Canto — Claude's markdown companion

> Edit `CLAUDE.md`, memories, plans, and all your markdown — visually, right inside your IDE.

Canto is a VS Code extension that gives Claude Code users a dedicated, visual editor for the markdown files that power their Claude projects: `CLAUDE.md`, `.claude/memory/*.md`, plans, and docs.

## Features

### WYSIWYG markdown editor

Edit `.md` files directly in the rendered view — no more mental tax of switching between raw markdown and a preview.

- Bold, italic, headings, lists, tables, code blocks — all with real-time visual feedback
- Keyboard shortcuts (`⌘B`, `⌘I`, `⌘K` for links)
- Slash commands for quick inserts
- Three modes: **WYSIWYG**, **Instant Rendering**, **Split View** — pick via the mode toggle in the toolbar
- Theme-aware — follows your VS Code dark/light theme

### Claude Code sidebar

Dedicated view in the activity bar with:

- **CLAUDE.md** — one click to open the project instructions
- **Memory** — all your memories, categorized; `+ New Memory` creates one with the right frontmatter
- **Plans** — all your plans from `docs/superpowers/plans/` or `.claude/plans/`; `+ New Plan` scaffolds a fresh one
- **Config** — quick access to Claude Code settings

### Documents view

A second tree view showing all markdown in the workspace, ordered sensibly: root files first, then folders with counts.

## Install

### From the VS Code Marketplace

```
ext install infinitelabs.canto
```

Or search for **Canto** in the Extensions panel.

### From source

```sh
git clone https://github.com/8infinitelabs/canto.git
cd canto/canto-vscode
npm install
npm run compile
npm run package
code --install-extension canto-0.1.0.vsix
```

## Compatibility

Works in:

- **VS Code** 1.85.0+
- **Cursor**
- **Windsurf**
- **VSCodium**

Any editor built on the VS Code Extension API.

## Usage

1. Open a folder with a `.claude/` directory (or any folder with markdown)
2. Click the **Canto** icon in the activity bar
3. Click any file in the sidebar to open it in the WYSIWYG editor
4. Right-click a `.md` file in Explorer → **Canto: Open WYSIWYG Editor**

## Keyboard shortcuts

Inherited from Vditor:

- `⌘B` — Bold
- `⌘I` — Italic
- `⌘K` — Link
- `⌘Shift+K` — Inline code
- `⌘1`–`⌘6` — Headings
- `⌘E` — Code block

## Why "Canto"?

A canto is a section of a long poem. Fits the Anthropic family (Opus, Sonnet, Haiku) and works in English, Spanish, Italian, Portuguese.

## Development

```sh
npm install
npm run watch       # recompile on change
# Press F5 in VS Code to launch Extension Development Host
```

## License

MIT © [Infinite Labs OÜ](https://github.com/8infinitelabs)

## Links

- [GitHub](https://github.com/8infinitelabs/canto)
- [Report an issue](https://github.com/8infinitelabs/canto/issues)
