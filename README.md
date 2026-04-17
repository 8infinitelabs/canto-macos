# Canto for macOS

> Native SwiftUI companion for Claude Code users. **Frozen at v1 — maintenance only.**

Canto for macOS is a standalone markdown editor designed around Claude Code's file conventions (`CLAUDE.md`, `.claude/memory/*.md`, plans). It runs as its own window, outside any IDE.

**Status:** This is the reference implementation. Active development has moved to the **VS Code extension** which works inside VS Code, Cursor, Windsurf, and VSCodium.

- **VS Code extension (primary product):** https://github.com/8infinitelabs/canto
- **Landing page:** https://canto.infinitelabs.co
- **Built by:** [Infinite Labs OÜ](https://infinitelabs.co)

## Why this exists

Before the VS Code extension, Canto was planned as a native macOS app. The SwiftUI implementation reached v1 (sidebar, WYSIWYG editor, memory browser, plans browser, config panel) but the decision was made to ship inside the IDE where Claude Code users already work. This repo keeps the macOS source as a reference and for users who want a standalone window.

## Build from source

Requires Xcode 16+, Swift 6, and [xcodegen](https://github.com/yonaskolb/XcodeGen).

```sh
git clone git@github.com:8infinitelabs/canto-macos.git
cd canto-macos
xcodegen generate
open Canto.xcodeproj
```

## Features (v1)

- Sidebar with CLAUDE.md, Memory (typed entries), Plans, Config
- WYSIWYG markdown editor (`NativeMarkdownView`)
- Memory browser with type colors and stale indicators
- Plans browser
- Config panel (MCP servers, permissions, hooks)
- Multi-window support (one per project)
- Markdown-only file filter
- FSEvents-based live reload

## License

MIT © [Infinite Labs OÜ](https://infinitelabs.co)
