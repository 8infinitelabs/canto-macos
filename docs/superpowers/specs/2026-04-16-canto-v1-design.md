# Canto v1 — Design Specification

> **Canto — see what you build with Claude.**

## 1. Product Vision

### What it is

Canto is a native desktop app that lives beside the terminal while you work with Claude Code. It renders your .md files as beautiful visual documents — not raw code. It understands Claude Code's structure (.claude/, memories, plans, sessions) and presents it intuitively.

### What it is NOT

- Not an IDE. Not a VS Code replacement.
- Not Obsidian. Not a PKM tool.
- Does not compete with code editors — it coexists alongside them.

### Two modes

- **Session mode** — Claude Code is active. Canto tracks in real-time which files are created/modified, shows session timeline, plans in progress, memories updating.
- **Editor mode** — Standalone. Open any folder, see your .md files rendered WYSIWYG. Works perfectly without Claude Code.

### Target user

The vibe coder. Someone who discovered they can CREATE with Claude — whether they're a developer, entrepreneur, designer, or someone who never coded before. People who work with .md daily because Claude works with .md. People who need to see and edit these files visually because they're creators building products, not developers reading code.

### Platforms

- **v1:** macOS (native, SwiftUI)
- **v2:** Windows (Kotlin Compose Multiplatform)
- **Future:** iOS, Android

### Distribution

- macOS App Store
- Microsoft Store (Windows, v2)

### Business model

Freemium with one-time Pro purchase (~$9.99-14.99):

| Feature | Free | Pro |
|---|---|---|
| Open local folders | Yes | Yes |
| WYSIWYG rendering | Yes | Yes |
| Sidebar Claude-aware | Yes | Yes |
| File watcher | Yes | Yes |
| Session workspace | Yes | Yes |
| Light + Dark theme | Yes | Yes |
| Cloud drives (GDrive, Dropbox, iCloud) | — | Yes |
| All themes | — | Yes |
| Export PDF/HTML/DOCX | — | Yes |
| Multiple tabs (up to 3 free, unlimited Pro) | 3 tabs | Unlimited |
| MCP integration | — | Yes |

### Name and branding

- **Name:** Canto
- **Tagline:** "See what you build with Claude."
- **Why Canto:** Follows Anthropic's poetic naming tradition (Opus, Sonnet, Haiku). A canto is a section of a long poem. Works in English, Spanish, Italian, Portuguese. Feels "part of the family" without infringing trademarks.

---

## 2. Technical Architecture

### Stack per platform

```
macOS (v1)                         Windows (v2)
+------------------------+        +------------------------+
|  SwiftUI               |        |  Kotlin Compose MP     |
|  +-- Sidebar           |        |  +-- Sidebar           |
|  +-- Memory browser    |        |  +-- Memory browser    |
|  +-- Session timeline  |        |  +-- Session timeline  |
|  +-- CLAUDE.md dash    |        |  +-- CLAUDE.md dash    |
|  +-- WKWebView         |        |  +-- WebView           |
|      +-- Milkdown (JS) |        |      +-- Milkdown (JS) |
+------------------------+        +------------------------+
         ^                                 ^
         +------- Shared -----------------+
                  +-- Milkdown editor (JS bundle)
                  +-- CSS themes
                  +-- Markdown parser config
```

**Principle:** Everything Claude-specific is native (feels Mac/Windows real). Only the WYSIWYG text editor uses a WebView with Milkdown. The JS editor bundle is shared across platforms — write once.

### Components

| Component | Tech | Native/Web |
|---|---|---|
| App shell + navigation | SwiftUI / Compose | Native |
| Sidebar Claude-aware | SwiftUI / Compose | Native |
| CLAUDE.md dashboard | SwiftUI / Compose | Native |
| Memory browser | SwiftUI / Compose | Native |
| Session timeline | SwiftUI / Compose | Native |
| Config panel | SwiftUI / Compose | Native |
| WYSIWYG editor | Milkdown in WKWebView | Web (embedded) |
| File watcher | FSEvents / Win32 API | Native |
| Markdown parsing | swift-markdown / commonmark | Native |

### Swift <-> WebView communication

```
Swift (host)                    WebView (Milkdown)
     |                               |
     |-- loadFile(content) --------->|  // open .md in editor
     |                               |
     |<-- onContentChange(md) ------|  // user edits, returns md
     |                               |
     |-- setTheme(dark/light) ------>|  // sync theme with system
     |                               |
     |-- focusLine(42) ------------>|  // scroll to specific line
     |                               |
```

Minimal interface: 4-5 messages between Swift and JS. The editor is autonomous — receives markdown, returns markdown. The host doesn't need to know about the internal DOM.

### Local persistence

```
~/Library/Application Support/Canto/
+-- settings.json          // user preferences
+-- recent-folders.json    // recent folders
+-- sessions/              // session history
|   +-- 2026-04-16-auth-system.json
+-- themes/                // custom themes
```

Sessions are stored as JSON: start/end timestamp, files touched, associated commits, project folder. No file duplication — metadata only.

### App Store sandboxing strategy

macOS App Store apps are sandboxed. Canto requires access to arbitrary user folders. Strategy:

- **Project folders:** User grants access via `NSOpenPanel` (standard open dialog). Access persisted across launches using **Security-Scoped Bookmarks**.
- **~/.claude/ directory:** Prompted separately during onboarding ("Canto needs access to your Claude Code configuration to show memories, plans, and settings"). Also persisted via Security-Scoped Bookmark.
- **~/Library/Application Support/Canto/:** App's own container — no special permission needed.
- **Recent folders:** Bookmarks stored in `recent-folders.json` so the app can re-open them without re-prompting.

### Data model

**Session record** (`sessions/*.json`):

```json
{
  "version": 1,
  "id": "2026-04-16-auth-system",
  "name": "Auth system",
  "nameSource": "commit",
  "projectPath": "/Users/diego/dev/mi-proyecto",
  "startedAt": "2026-04-16T14:32:00Z",
  "endedAt": "2026-04-16T15:19:00Z",
  "status": "completed",
  "events": [
    {
      "timestamp": "2026-04-16T14:33:00Z",
      "type": "file_modified",
      "path": "CLAUDE.md",
      "summary": "+3 lines (new rule added)"
    },
    {
      "timestamp": "2026-04-16T14:50:00Z",
      "type": "commit",
      "hash": "abc123",
      "message": "Add auth middleware",
      "filesChanged": 4,
      "insertions": 142,
      "deletions": 12
    }
  ],
  "stats": {
    "filesCreated": 2,
    "filesModified": 3,
    "filesDeleted": 0,
    "memoriesAdded": 1,
    "memoriesUpdated": 1,
    "commits": 2,
    "totalInsertions": 231,
    "totalDeletions": 12
  }
}
```

Event types: `session_start`, `file_created`, `file_modified`, `file_deleted`, `commit`, `memory_created`, `memory_updated`, `plan_created`.

**Settings** (`settings.json`):

```json
{
  "version": 1,
  "theme": "dark",
  "densityMode": "comfortable",
  "fontSize": 16,
  "fontFamily": "system",
  "sidebarWidth": 260,
  "sidebarCollapsed": false,
  "showWordCount": true,
  "sessionIdleTimeout": 300,
  "sessionGroupingWindow": 30,
  "staleMemoryDays": 14
}
```

**Recent folders** (`recent-folders.json`):

```json
{
  "version": 1,
  "folders": [
    {
      "path": "/Users/diego/dev/regulia",
      "bookmark": "<base64 security-scoped bookmark>",
      "lastOpened": "2026-04-16T10:00:00Z",
      "hasClaude": true,
      "memoryCount": 3
    }
  ]
}
```

**Memory file format** (expected structure in `.claude/memory/*.md`):

```markdown
---
name: memory name
description: one-line description
type: user | feedback | project | reference
---

Content here. For feedback/project types, structured as:
Rule or fact statement.

**Why:** reason behind it
**How to apply:** when/where this applies
```

Canto reads the frontmatter `type` field to classify memories. If `type` is missing or unrecognized, the memory displays with a grey "unknown" tag and renders as a standard .md card.

---

## 3. Visual Identity and UX

### Aesthetic north star

| Reference | What we take |
|---|---|
| **Linear** | Dark premium mode, clean typography, information density without clutter, purposeful micro-animations |
| **Raycast** | Perceived speed, instant transitions, blur/glass effects, power tool feeling |
| **Apple Notes** | WYSIWYG simplicity, anyone could use it, "doesn't look like a code editor" |

### Design principles

1. **Dark-first, light impeccable** — dark mode is the default. Light mode equally polished, not an afterthought.

2. **Content first, minimal chrome** — sidebar can collapse. Borders disappear. The .md fills the screen. Canto disappears so your document shines.

3. **Motion with purpose** — nothing moves without reason. When Claude modifies a file, a subtle flash appears in the sidebar. When opening a .md, content enters with a 150ms fade. No bounces, no gratuitous spinners.

4. **Typography as hero** — 90% of the app is text. Typography must be perfect:
   - Titles (H1-H3): SF Pro Display (system) or Inter Display
   - Body: SF Pro Text / Inter — 16px, line-height 1.6
   - Inline code: SF Mono / JetBrains Mono
   - Code blocks: SF Mono, subtly differentiated background
   - UI (sidebar, tabs): SF Pro Text, 13px

5. **Color as language** — minimal color, maximum meaning:
   - Background: #0A0A0F (dark) / #FAFAFA (light)
   - Surface: #141419 (dark) / #FFFFFF (light)
   - Text primary: #E4E4E7 (dark) / #18181B (light)
   - Text secondary: #71717A
   - Accent: #8B5CF6 (violet — Canto identity, thread to Anthropic)
   - Memory user: #3B82F6 (blue)
   - Memory feedback: #10B981 (green)
   - Memory project: #F59E0B (amber)
   - Memory reference: #EC4899 (pink)
   - Session idle: #71717A (grey)
   - Session active: #8B5CF6 (violet, pulsing)
   - Session done: #10B981 (green)
   - Session error: #EF4444 (red)

6. **Glass and native blur** — Use `NSVisualEffectView` / `.ultraThinMaterial` for sidebar blur and frosted glass modals. Adopt Liquid Glass APIs when macOS Tahoe ships and APIs stabilize. Canto feels built FOR macOS, not ported.

7. **Density modes** — Comfortable (default, generous padding) and Compact (less padding, more visible info).

### Key UX details

- Hover on sidebar item: tooltip with .md preview (first 3 lines rendered)
- Drag & drop images to editor: copies to `./assets/` directory (created if needed), filename preserved with dedup suffix if collision (e.g., `image-1.png`), auto-generates markdown `![](./assets/image.png)`
- Cmd+K: command palette (Raycast-style) for search, actions, navigation
- Transitions between files: smooth crossfade, not a hard cut
- Cursor blinks in violet when in editor (subtle branding)
- Empty state: minimal illustration with "Open a folder or drop it here"
- Tabs show state: dot = unsaved, violet pulsing dot = Claude is modifying it

---

## 4. App Layout

### Three zones

```
+-------------+----------------------------------------------+
| Sidebar     | Tabs: README.md x | spec.md x |              |
|             |----------------------------------------------|
| CLAUDE.md   |                                              |
|             |                                              |
| CLAUDE      |           Content Area                       |
|  Memory (4) |                                              |
|  Plans (1)  |  - WYSIWYG when .md                         |
|  Config     |  - Dashboard when CLAUDE.md                  |
|             |  - Cards when memory/                        |
| FILES       |  - Timeline when Session                     |
|  docs/      |  - Config panel when Config                  |
|  src/ (grey)|                                              |
|             |                                              |
| SESSION     |----------------------------------------------|
| Active 23m  | Status bar: Session "Auth" - 4 files - 23min |
+-------------+----------------------------------------------+
```

| Zone | Content | Behavior |
|---|---|---|
| **Left sidebar** | Claude-aware file tree + active session summary | .md files prominent, src/ and others greyed and collapsed. SESSION section at bottom when Claude Code is active. |
| **Central area** | Content, adapted to file type | Changes based on what you open. |
| **Bottom status bar** | Session state in one line | Only visible in session mode. |

### Sidebar order of priority

1. CLAUDE.md — always first, highlighted with violet badge
2. .claude/ section — memory/ (with count badge), plans/, config
3. FILES section — folders with .md expanded, others collapsed and greyed
4. SESSION section — only in session mode, with quick stats

### Central area adapts to context

| You open... | You see... |
|---|---|
| Any .md | WYSIWYG visual-first editor |
| CLAUDE.md | Interactive dashboard with collapsible sections and editable rule cards |
| memory/*.md | Visual card: type (color tag), name, rendered content |
| memory/ (folder) | Grid of cards, filterable by type |
| Session (in sidebar) | Timeline: files touched, when, commits, visual progress |
| Config | Claude Code configuration panel (MCP, Skills, Permissions) |
| Image | Preview |
| Code (.ts, .py...) | Syntax highlight, read-only |
| Other files | Icon + metadata (size, date), no opening |

---

## 5. Feature Specifications

### Feature 1: WYSIWYG Editor (visual-first, code-optional)

**Behavior:** Open a .md -> see the rendered document. Click -> edit inline.

**Supported elements in v1:**

| Element | Display | Editing |
|---|---|---|
| Headers (H1-H6) | Real visual size, no `#` | Click to edit text, level via Cmd+1-6 |
| Bold/Italic/Strike | Rendered, no `**` or `*` | Select + Cmd+B / Cmd+I / Cmd+Shift+X |
| Links | Clickable text in violet | Click -> popover to edit URL and text |
| Images | Rendered inline, real size | Click -> popover for resize/alt text/change |
| Lists (ul/ol) | Real bullets/numbers | Enter = new item, Tab = indent |
| Checkboxes | Real clickable checkbox | Click = toggle |
| Inline code | Pill with subtle background, monospace | Backtick to enter/exit |
| Code blocks | Syntax highlight, differentiated background | Click -> raw editing with language selector |
| Blockquotes | Violet side bar, visual indent | `>` at start or toolbar |
| Tables | Real visual table, no pipes | Click cell to edit. Toolbar for add row/col |
| Dividers | Subtle line | — |
| Frontmatter YAML | Collapsed by default, visual tag | Click to expand and edit raw |
| Callout blocks | Styled boxes with icon (NOTE, WARNING, TIP) | Stored as `> [!NOTE]` (GFM compatible) |

**Code toggle:** Cmd+/ or subtle button in corner -> shows raw markdown. Not split view, but toggle between views. Scroll position is maintained.

**Floating toolbar:** Appears when selecting text.

```
                    +------------------------------+
 Select text -->    | B  I  S  Link Code  H  "  Check |
                    +------------------------------+
```

No permanent toolbar. Content rules.

**Slash commands:** Type `/` on an empty line:

```
/heading    H1-H6
/list       Bullet list
/check      Checklist
/table      Insert table
/image      Add image
/code       Code block
/quote      Blockquote
/divider    Horizontal rule
/callout    Highlighted block
```

No markdown knowledge needed. Type `/`, choose, create.

**Drag & drop block reordering:** Drag entire blocks (paragraphs, lists, tables) to reorganize. Subtle handle on left on hover.

**Word count + reading time:** Subtle in bottom-right corner: `428 words - 2 min read`

**Focus mode:** Cmd+Shift+Enter. Sidebar disappears. Status bar disappears. Just the document, centered, generous padding. Esc to exit.

**Word count position:** Displayed in the editor area bottom-right when status bar is hidden, or integrated into the right side of the status bar when visible. Never overlaps.

### Feature 2: Sidebar Claude-aware

**Three sections with intelligent behavior:**

1. **CLAUDE section** — CLAUDE.md always first and highlighted. Memory with count badge and color-coded icons by type. Plans with count. Config subsection.

2. **FILES section** — Standard file tree. .md files always expanded. Non-.md folders collapsed and greyed. Detects and respects .gitignore.

3. **SESSION section** — Only appears when Claude Code session is detected. Shows: status (active/idle), duration, file count, link to open timeline.

**Smart behaviors:**
- Auto-detects `.claude/` directory when opening a folder
- File watcher: new files appear with subtle animation
- Badges update in real-time
- Hover preview: tooltip with first 3 rendered lines of .md files
- Breadcrumb above content area: `project > docs > spec.md`

### Feature 3: File Watcher

**Implementation:** FSEvents (macOS native). Recursive watch on opened folder.

**Events tracked:**

| Event | Canto reaction |
|---|---|
| .md created | Appears in sidebar with animation, status bar notification |
| .md modified | If open in tab, refresh content. "Modified" badge in sidebar |
| .md deleted | Disappears from sidebar, closes tab if open |
| Non-.md created | Appears in sidebar (FILES section, grey) |
| CLAUDE.md modified | Auto-refresh dashboard |
| memory/*.md created/modified | Update memory browser + count badge |

**Edit conflict handling:** If user is editing a .md in Canto and Claude Code modifies it simultaneously:

```
+----------------------------------------+
|  Warning: spec.md modified externally  |
|                                        |
|  [Accept external]  [Keep mine]  [Diff]|
+----------------------------------------+
```

Never auto-overwrite. User decides.

**Conflict debouncing:** If multiple rapid external modifications occur (e.g., Claude Code editing a file 5 times in 10 seconds), Canto waits for a 2-second quiet period before showing the conflict dialog. Only one dialog per file at a time.

**File deleted externally while open:** Tab shows a "This file was deleted" banner with options: [Save as new] [Close tab].

### Feature 4: CLAUDE.md Dashboard

When opening CLAUDE.md, you don't see markdown. You see a dashboard.

**Parsing strategy:** CLAUDE.md is freeform markdown. Canto uses the following heuristic to structure it:

- Each `## heading` becomes a collapsible dashboard section.
- Within a section, each top-level bullet point (`- ` or `* `) is treated as a "rule card."
- Paragraphs (non-bullet content) are treated as "instructions" rendered as prose.
- If no `##` headings exist, the entire file is rendered as a single "Instructions" section.
- If the file is empty or < 10 characters, the Quick Setup guide is shown instead.
- The dashboard always has a "Raw markdown" toggle to show/edit the underlying text directly. Any edits in dashboard mode produce valid markdown when saved.

**Sections:**

1. **Quick Setup** (only if CLAUDE.md is empty/minimal) — Guide to configure. Predefined templates by project type (Next.js, Python, Swift...).

2. **Instructions** — Paragraph content rendered with [Edit] button. Click to edit inline.

3. **Rules** — Bullet points displayed as cards. Each card has edit (pencil) and delete (x) actions. [+ Add Rule] creates a new bullet. Drag to reorder bullets.

4. **Memory Summary** — Color pills with count by type (blue user, green feedback, amber project, pink reference). Click opens Memory Browser.

5. **Recent Sessions** — Quick preview of last 2-3 sessions without leaving the dashboard.

6. **Raw markdown toggle** — Always available at the bottom.

### Feature 5: Memory Browser

**Folder view** — When clicking memory/ in sidebar:

**Layout:** Grid of cards, each card showing:
- Type tag with color (blue/green/amber/pink)
- Memory name
- Content preview (first 2-3 lines)
- Why/How to apply structure highlighted
- Updated timestamp
- [Edit] and [Delete] actions

**Features:**
- **Search** — Fuzzy search over name + content
- **Filter by type** — Tabs: All, user, feedback, project, reference (with counts)
- **Stale indicator** — Project memories older than 2 weeks show "stale?" badge
- **Create wizard** — [+ New Memory] opens visual form with type dropdown, name, content. Auto-generates correct frontmatter.
- **Click card** — Opens the .md in WYSIWYG in the central area

### Feature 6: Session Workspace

**Session lifecycle state machine:**

```
                    ┌─────────┐
                    │  IDLE   │ ← No activity detected
                    └────┬────┘
                         │ Trigger: 3+ file changes within 30s window
                         ▼
                    ┌─────────┐
                    │ ACTIVE  │ ← Session in progress
                    └────┬────┘
                         │ Trigger: No file changes for 5 min (configurable)
                         ▼
                    ┌─────────┐
                    │  IDLE   │ ← Session auto-saved, new session on next burst
                    └─────────┘
```

- **Start trigger:** 3 or more file system events within a 30-second window. A single file save does not start a session (could be manual edit).
- **Grouping window:** File events within 30 seconds of each other are grouped into a single timeline entry (e.g., "3 files modified" instead of 3 separate entries). Configurable via `sessionGroupingWindow` in settings.
- **Idle timeout:** 5 minutes (300s) of no file activity transitions from ACTIVE to IDLE. Session is auto-saved. Configurable via `sessionIdleTimeout` in settings.
- **Git integration:** Git log polled every 30s during ACTIVE state. Commits are matched to the active session by timestamp. Canto does not distinguish between Claude Code commits and manual commits — all are shown in the timeline.
- **No .git directory:** Session workspace still works (file events only), but commit entries and diff features are unavailable. Sidebar shows "No git" indicator.
- **Session naming:** Auto-inferred from first commit message in the session. If no commits, uses the first .md file created/modified. User can always rename with click.

**Summary card** at top:
- Status (Active/Completed), duration, file count, commit count
- Files created / modified / deleted
- Memories added/updated
- Total lines added/removed

**Timeline view:**
- Chronological list of events
- Event types: session start, file modified, file created, plan created, commit, memory updated
- Plans shown inline with checklist progress
- [View change] on CLAUDE.md and memory modifications shows mini-diff
- [View diff] and [View files] on commits
- Compact/Full toggle

**Session naming:** Auto-inferred from first plan or commit message. User can rename with click.

**Session history:**
- Auto-saved as JSON in ~/Library/Application Support/Canto/sessions/
- Sidebar shows last 5 sessions below active one
- Click opens historical timeline

### Feature 7: Claude Code Config Panel (read-only in v1)

**MCP Servers viewer:**
- Lists configured MCP servers from Claude Code's settings.json
- Shows configuration status: configured (green icon), not configured (grey). Note: v1 is read-only and cannot determine live connection status — only whether a server is configured.
- Displays tool count per server
- [Info] expands to show available tools list

**Skills browser:**
- Lists installed skills (built-in + plugins + custom)
- Shows name, description, source
- [Info] expands to show full skill description

**Permissions viewer:**
- Lists allowed/denied tool permissions
- Shows scope (global/project)
- Lists configured hooks with their triggers

**All read-only in v1.** Visual configuration (add MCP servers, edit permissions, create skills) planned for v1.x.

---

## 6. Onboarding

### First launch

```
         +------------------------------------+
         |              Canto                 |
         |  See what you build with Claude.   |
         |                                    |
         |  +----------------------------+   |
         |  | Drop a project folder here |   |
         |  | or [Open Folder]           |   |
         |  +----------------------------+   |
         |                                    |
         |  Recent                            |
         |  ~/dev/regulia     3 mem - 2h ago  |
         |  ~/dev/contestia   7 mem - yday    |
         +------------------------------------+
```

- Recent folders show Claude context: memory count, last activity
- If Claude Code is running in a directory, show it with "Live" badge
- Logo pulses once gently on first load, then stabilizes

---

## 7. Non-.md File Handling

| File type | Behavior |
|---|---|
| .md | Full WYSIWYG editor |
| Images (.png, .jpg, .svg, .gif) | Inline preview |
| .json / .yaml / .toml | Syntax highlight (read-only) |
| .txt | Plain text rendered |
| .csv | v1.x — visual table (moved from v1 to reduce scope) |
| .pdf | v1.x — basic preview via PDFKit (moved from v1 to reduce scope) |
| Code (.ts, .py, .swift...) | Syntax highlight (read-only) |
| Other | Icon + metadata (size, date), no opening |

Images referenced in .md (`![](./img.png)`) render inline in the WYSIWYG editor.

---

## 8. Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| Cmd+K | Command palette |
| Cmd+/ | Toggle code view |
| Cmd+Shift+Enter | Focus mode |
| Cmd+1-6 | Set heading level |
| Cmd+B | Bold |
| Cmd+I | Italic |
| Cmd+Shift+X | Strikethrough |
| Cmd+L | Insert link |
| Ctrl+Tab | Switch between open tabs |
| Cmd+W | Close current tab |
| Cmd+O | Open folder |
| Cmd+N | New .md file |
| Cmd+S | Save |
| Cmd+E | Export (Pro) |
| Esc | Exit focus mode / close modal |

---

## 9. Export (Pro feature)

| Format | Details |
|---|---|
| PDF | Styled, respecting current Canto theme |
| HTML | Standalone single file |
| DOCX | For Word/Google Docs users |
| Copy as formatted text | For pasting into Slack/Notion/Email |

---

## 10. Error and Empty States

Every state must feel intentional and beautiful — never a broken screen.

| State | What the user sees |
|---|---|
| **No folder open** | Welcome screen with drop zone, [Open Folder], and recent folders |
| **Folder has no .md files** | Sidebar shows file tree normally. Central area: "No markdown files found. Create one?" with [+ New .md] button |
| **Folder has no .claude/** | App works in pure Editor mode. Sidebar omits CLAUDE section entirely. No error — just a cleaner sidebar. Subtle banner: "No Claude Code project detected. [Learn more]" |
| **Memory folder empty** | Memory browser shows: "No memories yet. Memories are created by Claude Code as you work together." with illustration |
| **No sessions exist** | Session section in sidebar hidden. Dashboard "Recent Sessions" shows: "Sessions appear here as you work with Claude Code." |
| **File watcher loses permission** | Banner at top: "Canto lost access to this folder. [Re-grant access]" (triggers NSOpenPanel) |
| **WebView fails to load** | Fallback to raw markdown in a native text view with monospace font. Banner: "Editor failed to load. Showing raw markdown." |
| **Corrupt/unparseable .md** | Show raw content in monospace with banner: "This file could not be parsed as Markdown. Showing raw content." |
| **Memory with unknown type** | Displayed with grey "unknown" tag. Still fully functional as a card. |

---

## 11. Accessibility

| Area | v1 minimum bar |
|---|---|
| **VoiceOver** | All interactive elements have accessibility labels. Sidebar items announce file name + type. Memory cards announce type + name + preview. |
| **Keyboard navigation** | Full keyboard navigation for sidebar (arrow keys), tabs (Ctrl+Tab), command palette (Cmd+K). Tab key moves focus between sidebar, content area, and status bar. |
| **WebView editor** | Milkdown/Tiptap have built-in a11y (ARIA roles, keyboard shortcuts). Verify and supplement where needed. |
| **Color contrast** | All text/background combinations meet WCAG 2.1 AA minimum (4.5:1 for body text, 3:1 for large text). Verify both dark and light themes. |
| **Reduced motion** | Respect `prefers-reduced-motion`. When enabled: no fade transitions, no pulsing dots, no sidebar animations. Instant state changes instead. |
| **Font scaling** | Respect macOS system font size preferences. Editor font size also configurable independently in settings. |

---

## 12. Backlog (post-v1)

### v1.x planned

- MCP server visual configuration wizard (add/edit/remove servers)
- Skills editor (create/edit custom skills visually)
- Permissions and hooks editor
- Plan viewer as interactive checklists
- Cloud drives integration (Google Drive, iCloud, Dropbox)
- Non-.md preview improvements (code editing, CSV visual table, PDF preview via PDFKit)

### v2+ exploration

- Visual personality of the app based on session state (colors, micro-animations, "Canto breathes when Claude breathes")
- Multi-session support: multiple terminals with simultaneous Claude Code sessions, each with independent tracking in Canto
- Windows native app (Kotlin Compose Multiplatform)
- iOS/Android companion apps (view + light edit)
- MCP server mode (Claude Code sends commands to Canto)

---

## 13. Technical Decisions and Rationale

| Decision | Rationale |
|---|---|
| Native app (SwiftUI), not Electron | Performance, feel, App Store distribution. Target users are vibe coders who appreciate quality. |
| WebView only for WYSIWYG editor | Building a WYSIWYG markdown editor from scratch would take 6+ months. Milkdown/Tiptap are mature. Typora validated this approach. |
| Claude-first positioning | The differentiator. Without Claude integration, Canto is just another Typora. With it, it's a new category. |
| Freemium with one-time Pro | Developers and creators hate subscriptions for editing tools. Typora proved $14.99 perpetual works. Free tier is the marketing. |
| App Store only (no web direct) | Single channel simplifies everything: payments, updates, discovery. Apple Small Business Program reduces commission to 15% first year. |
| File watcher over MCP for v1 | FSEvents is native, reliable, zero-dependency. Covers 80% of session tracking without needing MCP protocol integration. MCP comes in v1.x. |
| Violet (#8B5CF6) as accent | Not blue (VS Code), not purple (Obsidian), not orange (Claude). Halfway between Anthropic purple and its own identity. Canto has its own brand but feels "in the family". |

---

*Canto v1 Design Specification — Infinite Labs OU, April 2026*
