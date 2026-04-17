# Canto

> **Claude's markdown companion.**
>
> Edit `CLAUDE.md`, memories, plans, and all your markdown — visually, right inside your IDE.

Canto is a visual companion for [Claude Code](https://claude.com/claude-code) users. Claude writes and consumes a lot of markdown — project instructions, memories, plans, outputs. Canto gives you a WYSIWYG editor and a dedicated sidebar to manage all of that in one place.

**Website:** [canto.basicstech.org](https://canto.basicstech.org)
**Built by:** [BasicsTech](https://basicstech.org) · [hello@basicstech.org](mailto:hello@basicstech.org)

---

## Products

| | Status |
|---|---|
| [**VS Code extension**](./canto-vscode) — runs inside VS Code / Cursor / Windsurf / VSCodium | **Active** · v0.1 |
| [**macOS app**](./Canto) — standalone SwiftUI companion window | Frozen at v1 |

The **VS Code extension is the primary product**. The macOS app is kept as a reference and for users who want a standalone window, but is not actively developed.

---

## Install (VS Code extension)

From the Marketplace:

```sh
code --install-extension basicstech.canto
```

Or search **Canto** in the Extensions panel inside VS Code / Cursor / Windsurf.

---

## What Canto gives you

**Visual CLAUDE.md editing** — no more staring at raw markdown. Edit headings, rules, and sections visually.

**Memory browser** — all your `.claude/memory/*.md` files with type colors (user/feedback/project/reference), stale indicators, and one-click create-new with the right frontmatter.

**Plans browser** — see plans from `docs/superpowers/plans/` or `.claude/plans/`, create new ones with the scaffold ready.

**Config panel** — quick read-only view of your MCP servers, permissions, and hooks.

**Documents tree** — the rest of the markdown in your workspace, organized: root files first, then folders with counts.

---

## Why "Canto"?

A canto is a section of a long poem. Fits the Anthropic family (Opus, Sonnet, Haiku) and works in English, Spanish, Italian, and Portuguese.

---

## Roadmap

- [x] VS Code extension v0.1 — WYSIWYG editor (Vditor), Claude sidebar, commands
- [ ] v0.2 — drag-drop images, paste-image → assets, search across markdown
- [ ] v0.3 — Claude Code session indicator (activity badge)
- [ ] v0.4 — Claude Code hook integration (auto-refresh when Claude writes)
- [ ] v0.5 — split-view with live preview from another pane
- [ ] v1.0 — stable marketplace release, docs site

---

## Development

```sh
# VS Code extension
cd canto-vscode
npm install
npm run watch
# Press F5 in VS Code to open Extension Development Host

# macOS app (frozen, for reference)
cd Canto
xcodegen generate
open Canto.xcodeproj
```

### Publishing the extension

See [`PUBLISHING.md`](./PUBLISHING.md) for the full step-by-step.

---

## Support

- **Issues:** [github.com/basicstech/canto/issues](https://github.com/basicstech/canto/issues)
- **Email:** [canto@basicstech.org](mailto:canto@basicstech.org)

## License

MIT © [BasicsTech](https://basicstech.org)

## Credits

- WYSIWYG editor: [Vditor](https://github.com/Vanessa219/vditor)
- Design inspiration: Linear, VS Code
