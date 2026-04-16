# Canto v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Canto, a native macOS app that serves as the visual companion to Claude Code — rendering .md files as WYSIWYG documents, with Claude-aware sidebar, memory browser, session workspace, and config panel.

**Architecture:** SwiftUI app using NavigationSplitView for sidebar+content layout. WYSIWYG editor is a Milkdown JS bundle embedded in WKWebView — all other UI is native SwiftUI. State management via @Observable classes. File watching via FSEvents. Data persisted as JSON in Application Support.

**Tech Stack:** Swift 6, SwiftUI, WKWebView, Milkdown (JS), FSEvents, swift-markdown, XCTest

**Spec:** `docs/superpowers/specs/2026-04-16-canto-v1-design.md`

---

## File Structure

```
Canto/
├── Canto.xcodeproj/
├── Canto/
│   ├── CantoApp.swift                    // @main, WindowGroup, app lifecycle
│   ├── Info.plist
│   ├── Canto.entitlements                // App Sandbox + file access
│   ├── Assets.xcassets/                  // App icon, colors, images
│   │
│   ├── Models/
│   │   ├── AppState.swift                // Root @Observable: open folder, tabs, mode
│   │   ├── FileNode.swift                // File tree node (recursive, Identifiable)
│   │   ├── TabItem.swift                 // Open tab: path, content, dirty state, external mod
│   │   ├── SessionRecord.swift           // Session JSON model (Codable)
│   │   ├── SessionEvent.swift            // Individual event in a session (Codable)
│   │   ├── MemoryFile.swift              // Memory with parsed frontmatter (Codable)
│   │   ├── ClaudeMDSection.swift         // Parsed CLAUDE.md section (heading, rules, prose)
│   │   ├── Settings.swift                // User settings (Codable)
│   │   ├── RecentFolder.swift            // Recent folder entry with bookmark (Codable)
│   │   └── ConfigModels.swift            // MCPServer, Skill, Permission (Codable, read-only)
│   │
│   ├── Services/
│   │   ├── FolderAccessService.swift     // NSOpenPanel + Security-Scoped Bookmarks
│   │   ├── FileTreeBuilder.swift         // Scan folder → [FileNode], .gitignore support
│   │   ├── FileWatcherService.swift      // FSEvents wrapper, debounced callbacks
│   │   ├── SessionManager.swift          // State machine (idle/active), event recording
│   │   ├── GitService.swift              // Shell out to git log, parse commits
│   │   ├── SettingsManager.swift         // Load/save settings.json
│   │   ├── RecentFoldersManager.swift    // Load/save recent-folders.json with bookmarks
│   │   ├── ClaudeMDParser.swift          // Parse CLAUDE.md → [ClaudeMDSection]
│   │   ├── MemoryParser.swift            // Parse memory .md frontmatter → MemoryFile
│   │   ├── ConfigReader.swift            // Read Claude Code settings.json → ConfigModels
│   │   └── MarkdownFileService.swift     // Read/write .md files, conflict detection
│   │
│   ├── Views/
│   │   ├── MainWindowView.swift          // NavigationSplitView: sidebar + detail
│   │   ├── WelcomeView.swift             // No folder open: drop zone + recents
│   │   │
│   │   ├── Sidebar/
│   │   │   ├── SidebarView.swift         // Container: Claude section + Files + Session
│   │   │   ├── ClaudeSidebarSection.swift // CLAUDE.md link, memory/, plans/, config
│   │   │   ├── FileTreeView.swift        // Recursive file tree with .md priority
│   │   │   └── SessionSidebarSection.swift // Active session summary + past sessions
│   │   │
│   │   ├── Editor/
│   │   │   ├── TabBarView.swift          // Horizontal tabs with state dots
│   │   │   ├── EditorContainerView.swift // Routes to correct view based on file type
│   │   │   ├── MarkdownWebView.swift     // WKWebView + Milkdown, Swift↔JS bridge
│   │   │   ├── CodePreviewView.swift     // Syntax-highlighted read-only view
│   │   │   └── ImagePreviewView.swift    // Image preview with metadata
│   │   │
│   │   ├── Dashboard/
│   │   │   ├── ClaudeMDDashboardView.swift // Dashboard layout with sections
│   │   │   ├── DashboardSectionView.swift  // Collapsible section (heading + content)
│   │   │   ├── RuleCardView.swift          // Single rule as editable card
│   │   │   └── QuickSetupView.swift        // Template chooser for empty CLAUDE.md
│   │   │
│   │   ├── Memory/
│   │   │   ├── MemoryBrowserView.swift   // Grid + filter bar + search
│   │   │   ├── MemoryCardView.swift      // Single memory card with type color
│   │   │   └── MemoryCreateSheet.swift   // Create new memory form (sheet)
│   │   │
│   │   ├── Session/
│   │   │   ├── SessionTimelineView.swift // Full timeline with events
│   │   │   ├── SessionSummaryCard.swift  // Stats card at top
│   │   │   └── TimelineEventRow.swift    // Single event row (file/commit/memory)
│   │   │
│   │   ├── Config/
│   │   │   ├── ConfigPanelView.swift     // Tabs: MCP, Skills, Permissions
│   │   │   ├── MCPServerRow.swift        // Single MCP server display
│   │   │   └── SkillRow.swift            // Single skill display
│   │   │
│   │   └── Components/
│   │       ├── CommandPaletteView.swift   // Cmd+K overlay
│   │       ├── StatusBarView.swift        // Bottom bar with session info + word count
│   │       ├── BreadcrumbView.swift       // Path breadcrumb above content
│   │       ├── ConflictBannerView.swift   // External modification warning
│   │       └── EmptyStateView.swift       // Reusable empty state with illustration
│   │
│   └── Theme/
│       ├── CantoColors.swift             // Color definitions (dark/light)
│       ├── CantoTypography.swift         // Font definitions
│       └── CantoAnimations.swift         // Shared animation constants
│
├── CantoTests/
│   ├── Models/
│   │   ├── SessionRecordTests.swift
│   │   ├── MemoryFileTests.swift
│   │   ├── ClaudeMDSectionTests.swift
│   │   ├── SettingsTests.swift
│   │   └── FileNodeTests.swift
│   ├── Services/
│   │   ├── ClaudeMDParserTests.swift
│   │   ├── MemoryParserTests.swift
│   │   ├── SessionManagerTests.swift
│   │   ├── FileTreeBuilderTests.swift
│   │   ├── ConfigReaderTests.swift
│   │   └── GitServiceTests.swift
│   └── Fixtures/
│       ├── sample-claude.md
│       ├── sample-memory-user.md
│       ├── sample-memory-feedback.md
│       ├── sample-settings.json
│       └── sample-session.json
│
└── editor-web/                           // Milkdown editor JS bundle
    ├── package.json
    ├── tsconfig.json
    ├── vite.config.ts
    ├── src/
    │   ├── index.ts                      // Milkdown setup + plugins
    │   ├── bridge.ts                     // window.webkit.messageHandlers bridge
    │   ├── slash-menu.ts                 // Slash command configuration
    │   └── styles/
    │       ├── editor.css                // Base editor styles
    │       ├── dark.css                  // Dark theme
    │       └── light.css                 // Light theme
    └── dist/                             // Built output → bundled into Xcode
        ├── editor.html
        ├── editor.js
        └── editor.css
```

---

## Task 1: Xcode Project Setup

**Files:**
- Create: `Canto/Canto.xcodeproj` (via Xcode CLI)
- Create: `Canto/Canto/CantoApp.swift`
- Create: `Canto/Canto/Canto.entitlements`
- Create: `Canto/Canto/Info.plist`

- [ ] **Step 1: Initialize git repo**

```bash
cd /Users/diego/dev/mder
git init
echo ".DS_Store\n*.xcuserdata\nbuild/\nDerivedData/\nnode_modules/\neditor-web/dist/\n.swiftpm/" > .gitignore
```

- [ ] **Step 2: Create Xcode project via command line**

Open Xcode → File → New → Project → macOS → App.
- Product Name: `Canto`
- Team: Diego's Apple Developer team
- Organization Identifier: `com.infinitelabs`
- Interface: SwiftUI
- Language: Swift
- Storage: None
- Save in: `/Users/diego/dev/mder/`

This creates the `Canto/` directory with `.xcodeproj`.

- [ ] **Step 3: Configure entitlements for App Sandbox**

Edit `Canto/Canto/Canto.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.bookmarks.app-scope</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 4: Set deployment target to macOS 14.0**

In Xcode project settings → General → Minimum Deployments → macOS 14.0. This gives us access to @Observable macro and modern SwiftUI APIs.

- [ ] **Step 5: Create CantoApp entry point**

Replace the generated `CantoApp.swift`:

```swift
import SwiftUI

@main
struct CantoApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environment(appState)
        }
        .defaultSize(width: 1200, height: 800)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
    }
}
```

- [ ] **Step 6: Create placeholder AppState and MainWindowView**

Create `Canto/Canto/Models/AppState.swift`:

```swift
import SwiftUI

@Observable
class AppState {
    var openFolderPath: URL?
    var isClaudeProject: Bool = false

    var hasOpenFolder: Bool {
        openFolderPath != nil
    }
}
```

Create `Canto/Canto/Views/MainWindowView.swift`:

```swift
import SwiftUI

struct MainWindowView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.hasOpenFolder {
            Text("Editor will go here")
        } else {
            Text("Welcome to Canto")
        }
    }
}
```

- [ ] **Step 7: Build and run to verify**

Run: `Cmd+R` in Xcode
Expected: App launches, shows "Welcome to Canto" in a window.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: initialize Canto Xcode project with SwiftUI, sandbox entitlements"
```

---

## Task 2: Theme System

**Files:**
- Create: `Canto/Canto/Theme/CantoColors.swift`
- Create: `Canto/Canto/Theme/CantoTypography.swift`
- Create: `Canto/Canto/Theme/CantoAnimations.swift`

- [ ] **Step 1: Create color definitions**

```swift
// CantoColors.swift
import SwiftUI

enum CantoColors {
    // Backgrounds
    static let background = Color("Background") // #0A0A0F dark, #FAFAFA light
    static let surface = Color("Surface")         // #141419 dark, #FFFFFF light

    // Text
    static let textPrimary = Color("TextPrimary")     // #E4E4E7 dark, #18181B light
    static let textSecondary = Color("TextSecondary") // #71717A both

    // Accent
    static let accent = Color(hex: "#8B5CF6")       // Violet

    // Memory types
    static let memoryUser = Color(hex: "#3B82F6")      // Blue
    static let memoryFeedback = Color(hex: "#10B981")  // Green
    static let memoryProject = Color(hex: "#F59E0B")   // Amber
    static let memoryReference = Color(hex: "#EC4899") // Pink

    // Session states
    static let sessionIdle = Color(hex: "#71717A")
    static let sessionActive = Color(hex: "#8B5CF6")
    static let sessionDone = Color(hex: "#10B981")
    static let sessionError = Color(hex: "#EF4444")

    static func forMemoryType(_ type: String) -> Color {
        switch type {
        case "user": return memoryUser
        case "feedback": return memoryFeedback
        case "project": return memoryProject
        case "reference": return memoryReference
        default: return sessionIdle
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
```

- [ ] **Step 2: Add color assets to xcassets**

In `Assets.xcassets`, create color sets for `Background`, `Surface`, `TextPrimary`, `TextSecondary` with dark/light variants matching the hex values from the spec.

- [ ] **Step 3: Create typography definitions**

```swift
// CantoTypography.swift
import SwiftUI

enum CantoTypography {
    static let displayLarge = Font.system(size: 28, weight: .bold, design: .default)
    static let displayMedium = Font.system(size: 22, weight: .bold, design: .default)
    static let displaySmall = Font.system(size: 18, weight: .semibold, design: .default)

    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)

    static let code = Font.system(size: 14, weight: .regular, design: .monospaced)
    static let codeSmall = Font.system(size: 12, weight: .regular, design: .monospaced)

    static let ui = Font.system(size: 13, weight: .regular, design: .default)
    static let uiSmall = Font.system(size: 11, weight: .regular, design: .default)

    static let sidebar = Font.system(size: 13, weight: .regular, design: .default)
    static let sidebarBold = Font.system(size: 13, weight: .semibold, design: .default)
}
```

- [ ] **Step 4: Create animation constants**

```swift
// CantoAnimations.swift
import SwiftUI

enum CantoAnimations {
    static let quick = Animation.easeInOut(duration: 0.15)
    static let standard = Animation.easeInOut(duration: 0.25)
    static let slow = Animation.easeInOut(duration: 0.4)

    static let sidebarAppear = Animation.easeOut(duration: 0.2)
    static let tabSwitch = Animation.easeInOut(duration: 0.15)

    static let pulse = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
}
```

- [ ] **Step 5: Build to verify no compilation errors**

Run: `Cmd+B` in Xcode
Expected: Build succeeds.

- [ ] **Step 6: Commit**

```bash
git add Canto/Canto/Theme/
git commit -m "feat: add Canto theme system (colors, typography, animations)"
```

---

## Task 3: Data Models

**Files:**
- Create: `Canto/Canto/Models/FileNode.swift`
- Create: `Canto/Canto/Models/TabItem.swift`
- Create: `Canto/Canto/Models/Settings.swift`
- Create: `Canto/Canto/Models/RecentFolder.swift`
- Create: `Canto/Canto/Models/SessionRecord.swift`
- Create: `Canto/Canto/Models/SessionEvent.swift`
- Create: `Canto/Canto/Models/MemoryFile.swift`
- Create: `Canto/Canto/Models/ClaudeMDSection.swift`
- Create: `Canto/Canto/Models/ConfigModels.swift`
- Test: `Canto/CantoTests/Models/`

- [ ] **Step 1: Create FileNode model**

```swift
// FileNode.swift
import Foundation

struct FileNode: Identifiable, Hashable {
    let id: String // relative path from project root
    let name: String
    let url: URL
    let isDirectory: Bool
    var children: [FileNode]?
    let fileExtension: String?

    var isMarkdown: Bool { fileExtension == "md" }
    var isImage: Bool { ["png", "jpg", "jpeg", "gif", "svg"].contains(fileExtension ?? "") }
    var isCode: Bool { ["swift", "ts", "js", "py", "rs", "go", "java", "tsx", "jsx"].contains(fileExtension ?? "") }
    var isConfig: Bool { ["json", "yaml", "yml", "toml"].contains(fileExtension ?? "") }
    var isClaudeMD: Bool { name == "CLAUDE.md" }
    var isMemory: Bool { id.contains(".claude/memory/") && isMarkdown }

    var hasMarkdownChildren: Bool {
        guard let children else { return false }
        return children.contains { $0.isMarkdown || $0.hasMarkdownChildren }
    }
}
```

- [ ] **Step 2: Create TabItem model**

```swift
// TabItem.swift
import Foundation

@Observable
class TabItem: Identifiable, Hashable {
    let id: String
    let url: URL
    let name: String
    var content: String
    var isDirty: Bool = false
    var isExternallyModified: Bool = false
    var isBeingModifiedByClaud: Bool = false

    init(url: URL, content: String) {
        self.id = url.path
        self.url = url
        self.name = url.lastPathComponent
        self.content = content
    }

    static func == (lhs: TabItem, rhs: TabItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
```

- [ ] **Step 3: Create Settings model**

```swift
// Settings.swift
import Foundation

struct Settings: Codable {
    var version: Int = 1
    var theme: String = "dark"
    var densityMode: String = "comfortable"
    var fontSize: Int = 16
    var fontFamily: String = "system"
    var sidebarWidth: Double = 260
    var sidebarCollapsed: Bool = false
    var showWordCount: Bool = true
    var sessionIdleTimeout: Int = 300
    var sessionGroupingWindow: Int = 30
    var staleMemoryDays: Int = 14
}
```

- [ ] **Step 4: Create RecentFolder model**

```swift
// RecentFolder.swift
import Foundation

struct RecentFolder: Codable, Identifiable {
    var id: String { path }
    let path: String
    let bookmark: Data
    let lastOpened: Date
    let hasClaude: Bool
    let memoryCount: Int
}

struct RecentFoldersStore: Codable {
    var version: Int = 1
    var folders: [RecentFolder] = []
}
```

- [ ] **Step 5: Create SessionRecord and SessionEvent models**

```swift
// SessionEvent.swift
import Foundation

struct SessionEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let type: EventType
    let path: String?
    let summary: String?
    let commitHash: String?
    let commitMessage: String?
    let filesChanged: Int?
    let insertions: Int?
    let deletions: Int?

    enum EventType: String, Codable {
        case sessionStart = "session_start"
        case fileCreated = "file_created"
        case fileModified = "file_modified"
        case fileDeleted = "file_deleted"
        case commit
        case memoryCreated = "memory_created"
        case memoryUpdated = "memory_updated"
        case planCreated = "plan_created"
    }

    init(type: EventType, path: String? = nil, summary: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.path = path
        self.summary = summary
        self.commitHash = nil
        self.commitMessage = nil
        self.filesChanged = nil
        self.insertions = nil
        self.deletions = nil
    }
}
```

```swift
// SessionRecord.swift
import Foundation

struct SessionRecord: Codable, Identifiable {
    var version: Int = 1
    let id: String
    var name: String
    var nameSource: String // "commit", "file", "user"
    let projectPath: String
    let startedAt: Date
    var endedAt: Date?
    var status: SessionStatus
    var events: [SessionEvent]
    var stats: SessionStats

    enum SessionStatus: String, Codable {
        case active, completed
    }

    struct SessionStats: Codable {
        var filesCreated: Int = 0
        var filesModified: Int = 0
        var filesDeleted: Int = 0
        var memoriesAdded: Int = 0
        var memoriesUpdated: Int = 0
        var commits: Int = 0
        var totalInsertions: Int = 0
        var totalDeletions: Int = 0
    }

    static func create(projectPath: String) -> SessionRecord {
        SessionRecord(
            id: Self.generateID(),
            name: "New session",
            nameSource: "file",
            projectPath: projectPath,
            startedAt: Date(),
            status: .active,
            events: [SessionEvent(type: .sessionStart)],
            stats: SessionStats()
        )
    }

    private static func generateID() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: Date())
    }
}
```

- [ ] **Step 6: Create MemoryFile model**

```swift
// MemoryFile.swift
import Foundation

struct MemoryFile: Identifiable, Hashable {
    let id: String // filename
    let url: URL
    let name: String
    let description: String
    let type: MemoryType
    let content: String
    let modifiedDate: Date

    enum MemoryType: String, CaseIterable {
        case user, feedback, project, reference, unknown
    }

    var isStale: Bool {
        guard type == .project else { return false }
        let daysOld = Calendar.current.dateComponents([.day], from: modifiedDate, to: Date()).day ?? 0
        return daysOld > 14
    }

    static func == (lhs: MemoryFile, rhs: MemoryFile) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
```

- [ ] **Step 7: Create ClaudeMDSection model**

```swift
// ClaudeMDSection.swift
import Foundation

struct ClaudeMDSection: Identifiable {
    let id: String // heading text or "root"
    let heading: String?
    let headingLevel: Int // 0 for root (no heading)
    var rules: [RuleItem] // bullet points
    var prose: String // paragraph content

    struct RuleItem: Identifiable {
        let id: UUID
        var text: String

        init(text: String) {
            self.id = UUID()
            self.text = text
        }
    }
}
```

- [ ] **Step 8: Create ConfigModels**

```swift
// ConfigModels.swift
import Foundation

struct MCPServerConfig: Identifiable, Codable {
    var id: String { name }
    let name: String
    let command: String?
    let args: [String]?
    let url: String?
    let toolCount: Int?
}

struct SkillConfig: Identifiable, Codable {
    var id: String { name }
    let name: String
    let description: String
    let source: String // "built-in", "plugin", "custom"
}

struct PermissionConfig: Identifiable, Codable {
    var id: String { tool + scope }
    let tool: String
    let scope: String // "global", "project"
    let allowed: Bool
}

struct HookConfig: Identifiable, Codable {
    var id: String { event + command }
    let event: String
    let command: String
}
```

- [ ] **Step 9: Write model tests**

Create test fixtures in `CantoTests/Fixtures/`:

`sample-memory-user.md`:
```markdown
---
name: user_role
description: Diego is a solopreneur vibe coder
type: user
---

Senior developer with background in full-stack web.
Based in Barcelona. Runs Infinite Labs.
```

`sample-claude.md`:
```markdown
## Instructions

Use Next.js 16 with App Router. Always use TypeScript.
Deploy to Vercel.

## Rules

- Use pnpm as package manager
- No mocks in integration tests
- Always run ESLint before commit

## Stack

React 19, Tailwind v4, Supabase, Vercel
```

`sample-session.json`: (copy from spec data model section)

Write tests in `CantoTests/Models/`:

```swift
// SessionRecordTests.swift
import XCTest
@testable import Canto

final class SessionRecordTests: XCTestCase {
    func testCreateSession() {
        let session = SessionRecord.create(projectPath: "/test/path")
        XCTAssertEqual(session.status, .active)
        XCTAssertEqual(session.events.count, 1)
        XCTAssertEqual(session.events[0].type, .sessionStart)
        XCTAssertEqual(session.projectPath, "/test/path")
    }

    func testSessionEncodeDecode() throws {
        let session = SessionRecord.create(projectPath: "/test")
        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(SessionRecord.self, from: data)
        XCTAssertEqual(decoded.id, session.id)
        XCTAssertEqual(decoded.projectPath, session.projectPath)
    }
}
```

```swift
// MemoryFileTests.swift
import XCTest
@testable import Canto

final class MemoryFileTests: XCTestCase {
    func testStaleProjectMemory() {
        let old = MemoryFile(
            id: "test", url: URL(fileURLWithPath: "/test"),
            name: "old", description: "", type: .project,
            content: "", modifiedDate: Date().addingTimeInterval(-30 * 86400)
        )
        XCTAssertTrue(old.isStale)
    }

    func testFreshProjectMemoryNotStale() {
        let fresh = MemoryFile(
            id: "test", url: URL(fileURLWithPath: "/test"),
            name: "fresh", description: "", type: .project,
            content: "", modifiedDate: Date()
        )
        XCTAssertFalse(fresh.isStale)
    }

    func testUserMemoryNeverStale() {
        let old = MemoryFile(
            id: "test", url: URL(fileURLWithPath: "/test"),
            name: "old", description: "", type: .user,
            content: "", modifiedDate: Date().addingTimeInterval(-90 * 86400)
        )
        XCTAssertFalse(old.isStale)
    }
}
```

```swift
// FileNodeTests.swift
import XCTest
@testable import Canto

final class FileNodeTests: XCTestCase {
    func testIsMarkdown() {
        let node = FileNode(id: "README.md", name: "README.md", url: URL(fileURLWithPath: "/README.md"),
                           isDirectory: false, children: nil, fileExtension: "md")
        XCTAssertTrue(node.isMarkdown)
        XCTAssertFalse(node.isImage)
        XCTAssertFalse(node.isCode)
    }

    func testIsClaudeMD() {
        let node = FileNode(id: "CLAUDE.md", name: "CLAUDE.md", url: URL(fileURLWithPath: "/CLAUDE.md"),
                           isDirectory: false, children: nil, fileExtension: "md")
        XCTAssertTrue(node.isClaudeMD)
    }

    func testHasMarkdownChildren() {
        let child = FileNode(id: "docs/spec.md", name: "spec.md", url: URL(fileURLWithPath: "/docs/spec.md"),
                            isDirectory: false, children: nil, fileExtension: "md")
        let parent = FileNode(id: "docs", name: "docs", url: URL(fileURLWithPath: "/docs"),
                             isDirectory: true, children: [child], fileExtension: nil)
        XCTAssertTrue(parent.hasMarkdownChildren)
    }
}
```

- [ ] **Step 10: Run tests to verify they pass**

Run: `Cmd+U` in Xcode (or `xcodebuild test -scheme Canto -destination 'platform=macOS'`)
Expected: All tests pass.

- [ ] **Step 11: Commit**

```bash
git add Canto/Canto/Models/ CantoTests/
git commit -m "feat: add all data models with tests (FileNode, Session, Memory, Settings, Config)"
```

---

## Task 4: Settings and Persistence Services

**Files:**
- Create: `Canto/Canto/Services/SettingsManager.swift`
- Create: `Canto/Canto/Services/RecentFoldersManager.swift`
- Test: `Canto/CantoTests/Services/SettingsManagerTests.swift`

- [ ] **Step 1: Create SettingsManager**

```swift
// SettingsManager.swift
import Foundation

@Observable
class SettingsManager {
    private(set) var settings: Settings
    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let cantoDir = appSupport.appendingPathComponent("Canto", isDirectory: true)
        try? FileManager.default.createDirectory(at: cantoDir, withIntermediateDirectories: true)
        self.fileURL = cantoDir.appendingPathComponent("settings.json")

        if let data = try? Data(contentsOf: fileURL),
           let loaded = try? JSONDecoder().decode(Settings.self, from: data) {
            self.settings = loaded
        } else {
            self.settings = Settings()
        }
    }

    func update(_ modify: (inout Settings) -> Void) {
        modify(&settings)
        save()
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(settings) {
            try? data.write(to: fileURL)
        }
    }
}
```

- [ ] **Step 2: Create RecentFoldersManager**

```swift
// RecentFoldersManager.swift
import Foundation
import AppKit

@Observable
class RecentFoldersManager {
    private(set) var folders: [RecentFolder] = []
    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let cantoDir = appSupport.appendingPathComponent("Canto", isDirectory: true)
        try? FileManager.default.createDirectory(at: cantoDir, withIntermediateDirectories: true)
        self.fileURL = cantoDir.appendingPathComponent("recent-folders.json")
        load()
    }

    func addFolder(url: URL) {
        guard let bookmark = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }

        let hasClaude = FileManager.default.fileExists(
            atPath: url.appendingPathComponent(".claude").path
        )
        let memoryPath = url.appendingPathComponent(".claude/memory")
        let memoryCount = (try? FileManager.default.contentsOfDirectory(atPath: memoryPath.path))?.count ?? 0

        let entry = RecentFolder(
            path: url.path,
            bookmark: bookmark,
            lastOpened: Date(),
            hasClaude: hasClaude,
            memoryCount: memoryCount
        )

        folders.removeAll { $0.path == url.path }
        folders.insert(entry, at: 0)
        if folders.count > 10 { folders = Array(folders.prefix(10)) }
        save()
    }

    func resolveBookmark(_ folder: RecentFolder) -> URL? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: folder.bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return nil }

        if isStale {
            // Re-save bookmark
            addFolder(url: url)
        }
        return url
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let store = try? JSONDecoder().decode(RecentFoldersStore.self, from: data)
        else { return }
        self.folders = store.folders
    }

    private func save() {
        let store = RecentFoldersStore(folders: folders)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(store) {
            try? data.write(to: fileURL)
        }
    }
}
```

- [ ] **Step 3: Write tests for SettingsManager**

```swift
// SettingsManagerTests.swift
import XCTest
@testable import Canto

final class SettingsTests: XCTestCase {
    func testDefaultSettings() {
        let settings = Settings()
        XCTAssertEqual(settings.theme, "dark")
        XCTAssertEqual(settings.fontSize, 16)
        XCTAssertEqual(settings.sessionIdleTimeout, 300)
        XCTAssertEqual(settings.version, 1)
    }

    func testSettingsEncodeDecode() throws {
        var settings = Settings()
        settings.theme = "light"
        settings.fontSize = 18
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(Settings.self, from: data)
        XCTAssertEqual(decoded.theme, "light")
        XCTAssertEqual(decoded.fontSize, 18)
    }
}
```

- [ ] **Step 4: Run tests**

Run: `Cmd+U`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add Canto/Canto/Services/SettingsManager.swift Canto/Canto/Services/RecentFoldersManager.swift CantoTests/
git commit -m "feat: add settings and recent folders persistence with security-scoped bookmarks"
```

---

## Task 5: Markdown and Memory Parsing Services

**Files:**
- Create: `Canto/Canto/Services/ClaudeMDParser.swift`
- Create: `Canto/Canto/Services/MemoryParser.swift`
- Test: `Canto/CantoTests/Services/ClaudeMDParserTests.swift`
- Test: `Canto/CantoTests/Services/MemoryParserTests.swift`

- [ ] **Step 1: Write failing tests for ClaudeMDParser**

```swift
// ClaudeMDParserTests.swift
import XCTest
@testable import Canto

final class ClaudeMDParserTests: XCTestCase {
    func testParseWithHeadingsAndRules() {
        let md = """
        ## Instructions

        Use Next.js 16 with App Router. Always use TypeScript.

        ## Rules

        - Use pnpm as package manager
        - No mocks in integration tests
        - Always run ESLint before commit
        """
        let sections = ClaudeMDParser.parse(md)
        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].heading, "Instructions")
        XCTAssertTrue(sections[0].prose.contains("Next.js 16"))
        XCTAssertEqual(sections[0].rules.count, 0)
        XCTAssertEqual(sections[1].heading, "Rules")
        XCTAssertEqual(sections[1].rules.count, 3)
        XCTAssertEqual(sections[1].rules[0].text, "Use pnpm as package manager")
    }

    func testParseWithNoHeadings() {
        let md = "Just some plain text instructions for Claude."
        let sections = ClaudeMDParser.parse(md)
        XCTAssertEqual(sections.count, 1)
        XCTAssertNil(sections[0].heading)
        XCTAssertTrue(sections[0].prose.contains("plain text"))
    }

    func testParseEmptyFile() {
        let sections = ClaudeMDParser.parse("")
        XCTAssertEqual(sections.count, 0)
    }

    func testParseMixedContent() {
        let md = """
        ## Stack

        React 19, Tailwind v4

        - Supabase for database
        - Vercel for deploy
        """
        let sections = ClaudeMDParser.parse(md)
        XCTAssertEqual(sections.count, 1)
        XCTAssertTrue(sections[0].prose.contains("React 19"))
        XCTAssertEqual(sections[0].rules.count, 2)
    }

    func testRoundTrip() {
        let original = """
        ## Rules

        - Rule one
        - Rule two
        """
        let sections = ClaudeMDParser.parse(original)
        let reconstructed = ClaudeMDParser.toMarkdown(sections)
        let reparsed = ClaudeMDParser.parse(reconstructed)
        XCTAssertEqual(reparsed.count, sections.count)
        XCTAssertEqual(reparsed[0].rules.count, sections[0].rules.count)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `Cmd+U`
Expected: FAIL — ClaudeMDParser does not exist.

- [ ] **Step 3: Implement ClaudeMDParser**

```swift
// ClaudeMDParser.swift
import Foundation

enum ClaudeMDParser {
    static func parse(_ markdown: String) -> [ClaudeMDSection] {
        let trimmed = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 10 || !trimmed.isEmpty else { return [] }
        guard !trimmed.isEmpty else { return [] }

        var sections: [ClaudeMDSection] = []
        var currentHeading: String? = nil
        var currentLevel: Int = 0
        var currentProse: [String] = []
        var currentRules: [ClaudeMDSection.RuleItem] = []

        func flushSection() {
            let prose = currentProse.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if currentHeading != nil || !prose.isEmpty || !currentRules.isEmpty {
                sections.append(ClaudeMDSection(
                    id: currentHeading ?? "root",
                    heading: currentHeading,
                    headingLevel: currentLevel,
                    rules: currentRules,
                    prose: prose
                ))
            }
            currentProse = []
            currentRules = []
        }

        for line in markdown.components(separatedBy: .newlines) {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Check for ## heading
            if let match = trimmedLine.range(of: #"^(#{1,6})\s+(.+)$"#, options: .regularExpression) {
                flushSection()
                let hashes = trimmedLine.prefix(while: { $0 == "#" })
                currentLevel = hashes.count
                currentHeading = String(trimmedLine.dropFirst(currentLevel).trimmingCharacters(in: .whitespaces))
            }
            // Check for bullet point (rule)
            else if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") {
                let text = String(trimmedLine.dropFirst(2))
                currentRules.append(ClaudeMDSection.RuleItem(text: text))
            }
            // Regular content
            else {
                currentProse.append(line)
            }
        }

        flushSection()
        return sections
    }

    static func toMarkdown(_ sections: [ClaudeMDSection]) -> String {
        var lines: [String] = []
        for section in sections {
            if let heading = section.heading {
                let hashes = String(repeating: "#", count: max(section.headingLevel, 2))
                lines.append("\(hashes) \(heading)")
                lines.append("")
            }
            if !section.prose.isEmpty {
                lines.append(section.prose)
                lines.append("")
            }
            for rule in section.rules {
                lines.append("- \(rule.text)")
            }
            if !section.rules.isEmpty {
                lines.append("")
            }
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .newlines) + "\n"
    }
}
```

- [ ] **Step 4: Run parser tests**

Run: `Cmd+U`
Expected: All ClaudeMDParser tests pass.

- [ ] **Step 5: Write failing tests for MemoryParser**

```swift
// MemoryParserTests.swift
import XCTest
@testable import Canto

final class MemoryParserTests: XCTestCase {
    func testParseValidMemory() throws {
        let content = """
        ---
        name: user_role
        description: Diego is a solopreneur
        type: user
        ---

        Senior developer based in Barcelona.
        """
        let url = URL(fileURLWithPath: "/test/user_role.md")
        let memory = try MemoryParser.parse(content: content, url: url, modifiedDate: Date())
        XCTAssertEqual(memory.name, "user_role")
        XCTAssertEqual(memory.type, .user)
        XCTAssertTrue(memory.content.contains("Senior developer"))
    }

    func testParseUnknownType() throws {
        let content = """
        ---
        name: test
        description: test
        type: something_new
        ---

        Content.
        """
        let url = URL(fileURLWithPath: "/test/test.md")
        let memory = try MemoryParser.parse(content: content, url: url, modifiedDate: Date())
        XCTAssertEqual(memory.type, .unknown)
    }

    func testParseNoFrontmatter() {
        let content = "Just plain content without frontmatter."
        let url = URL(fileURLWithPath: "/test/plain.md")
        XCTAssertThrowsError(try MemoryParser.parse(content: content, url: url, modifiedDate: Date()))
    }
}
```

- [ ] **Step 6: Implement MemoryParser**

```swift
// MemoryParser.swift
import Foundation

enum MemoryParserError: Error {
    case noFrontmatter
    case invalidFrontmatter
}

enum MemoryParser {
    static func parse(content: String, url: URL, modifiedDate: Date) throws -> MemoryFile {
        let parts = content.components(separatedBy: "---")
        guard parts.count >= 3 else { throw MemoryParserError.noFrontmatter }

        let frontmatter = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let body = parts.dropFirst(2).joined(separator: "---").trimmingCharacters(in: .whitespacesAndNewlines)

        var name = url.deletingPathExtension().lastPathComponent
        var description = ""
        var typeString = "unknown"

        for line in frontmatter.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("name:") {
                name = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("description:") {
                description = String(trimmed.dropFirst(12)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("type:") {
                typeString = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            }
        }

        let type = MemoryFile.MemoryType(rawValue: typeString) ?? .unknown

        return MemoryFile(
            id: url.lastPathComponent,
            url: url,
            name: name,
            description: description,
            type: type,
            content: body,
            modifiedDate: modifiedDate
        )
    }
}
```

- [ ] **Step 7: Run all tests**

Run: `Cmd+U`
Expected: All tests pass.

- [ ] **Step 8: Commit**

```bash
git add Canto/Canto/Services/ClaudeMDParser.swift Canto/Canto/Services/MemoryParser.swift CantoTests/
git commit -m "feat: add CLAUDE.md parser and memory frontmatter parser with tests"
```

---

## Task 6: File System Services (Folder Access, File Tree, File Watcher)

**Files:**
- Create: `Canto/Canto/Services/FolderAccessService.swift`
- Create: `Canto/Canto/Services/FileTreeBuilder.swift`
- Create: `Canto/Canto/Services/FileWatcherService.swift`
- Create: `Canto/Canto/Services/MarkdownFileService.swift`
- Test: `Canto/CantoTests/Services/FileTreeBuilderTests.swift`

- [ ] **Step 1: Create FolderAccessService**

```swift
// FolderAccessService.swift
import Foundation
import AppKit

enum FolderAccessService {
    static func openFolderPanel() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a project folder to open in Canto"
        panel.prompt = "Open"

        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }

    static func requestClaudeConfigAccess() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude")
        panel.message = "Canto needs access to your Claude Code configuration to show memories, plans, and settings."
        panel.prompt = "Grant Access"

        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }

    static func startAccessing(url: URL) -> Bool {
        url.startAccessingSecurityScopedResource()
    }

    static func stopAccessing(url: URL) {
        url.stopAccessingSecurityScopedResource()
    }
}
```

- [ ] **Step 2: Create FileTreeBuilder**

```swift
// FileTreeBuilder.swift
import Foundation

enum FileTreeBuilder {
    static func build(from rootURL: URL, gitignorePatterns: [String] = []) -> [FileNode] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var nodesByPath: [String: FileNode] = [:]
        var rootChildren: [FileNode] = []

        // First pass: collect all items
        var allURLs: [URL] = []
        while let url = enumerator.nextObject() as? URL {
            let relativePath = url.path.replacingOccurrences(of: rootURL.path + "/", with: "")

            // Skip node_modules, .git, build directories
            if shouldSkip(relativePath) {
                if (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                    enumerator.skipDescendants()
                }
                continue
            }
            allURLs.append(url)
        }

        // Build tree
        for url in allURLs.sorted(by: { $0.path < $1.path }) {
            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            let relativePath = url.path.replacingOccurrences(of: rootURL.path + "/", with: "")

            let node = FileNode(
                id: relativePath,
                name: url.lastPathComponent,
                url: url,
                isDirectory: isDir,
                children: isDir ? [] : nil,
                fileExtension: isDir ? nil : url.pathExtension
            )

            let parentPath = (relativePath as NSString).deletingLastPathComponent
            if parentPath.isEmpty {
                rootChildren.append(node)
            } else if var parent = nodesByPath[parentPath] {
                parent.children?.append(node)
                nodesByPath[parentPath] = parent
                // Update in rootChildren or parent's parent
                updateNodeInTree(&rootChildren, path: parentPath, node: parent)
            }

            nodesByPath[relativePath] = node
        }

        return sortNodes(rootChildren)
    }

    private static func shouldSkip(_ path: String) -> Bool {
        let skipDirs = ["node_modules", ".git", "DerivedData", "build", ".build", "__pycache__", ".next"]
        return skipDirs.contains(where: { path.hasPrefix($0) || path.contains("/\($0)") })
    }

    private static func sortNodes(_ nodes: [FileNode]) -> [FileNode] {
        // CLAUDE.md first, then .claude/, then directories with .md, then other dirs, then files
        nodes.sorted { a, b in
            if a.isClaudeMD { return true }
            if b.isClaudeMD { return false }
            if a.name == ".claude" && a.isDirectory { return true }
            if b.name == ".claude" && b.isDirectory { return false }
            if a.isDirectory && b.isDirectory {
                if a.hasMarkdownChildren && !b.hasMarkdownChildren { return true }
                if !a.hasMarkdownChildren && b.hasMarkdownChildren { return false }
                return a.name < b.name
            }
            if a.isDirectory { return true }
            if b.isDirectory { return false }
            if a.isMarkdown && !b.isMarkdown { return true }
            if !a.isMarkdown && b.isMarkdown { return false }
            return a.name < b.name
        }.map { node in
            var sorted = node
            if let children = sorted.children {
                sorted.children = sortNodes(children)
            }
            return sorted
        }
    }

    private static func updateNodeInTree(_ nodes: inout [FileNode], path: String, node: FileNode) {
        for i in nodes.indices {
            if nodes[i].id == path {
                nodes[i] = node
                return
            }
            if let children = nodes[i].children, !children.isEmpty {
                var mutableChildren = children
                updateNodeInTree(&mutableChildren, path: path, node: node)
                nodes[i].children = mutableChildren
            }
        }
    }
}
```

- [ ] **Step 3: Create FileWatcherService**

```swift
// FileWatcherService.swift
import Foundation

@Observable
class FileWatcherService {
    private var stream: FSEventStreamRef?
    private var watchedPath: String?
    var onChange: ((String, FSEventStreamEventFlags) -> Void)?

    func startWatching(path: String) {
        stopWatching()
        watchedPath = path

        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        let paths = [path] as CFArray
        stream = FSEventStreamCreate(
            nil,
            { _, info, numEvents, eventPaths, eventFlags, _ in
                guard let info else { return }
                let watcher = Unmanaged<FileWatcherService>.fromOpaque(info).takeUnretainedValue()
                let paths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as! [String]
                for i in 0..<numEvents {
                    watcher.onChange?(paths[i], eventFlags[i])
                }
            },
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0, // 1 second latency for batching
            UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )

        if let stream {
            FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            FSEventStreamStart(stream)
        }
    }

    func stopWatching() {
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
        stream = nil
        watchedPath = nil
    }

    deinit {
        stopWatching()
    }
}
```

- [ ] **Step 4: Create MarkdownFileService**

```swift
// MarkdownFileService.swift
import Foundation

enum MarkdownFileService {
    static func read(url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    static func write(url: URL, content: String) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    static func createNew(in directory: URL, name: String) throws -> URL {
        let fileName = name.hasSuffix(".md") ? name : "\(name).md"
        let url = directory.appendingPathComponent(fileName)
        try "# \(name.replacingOccurrences(of: ".md", with: ""))\n\n".write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
```

- [ ] **Step 5: Write FileTreeBuilder tests**

```swift
// FileTreeBuilderTests.swift
import XCTest
@testable import Canto

final class FileTreeBuilderTests: XCTestCase {
    var tempDir: URL!

    override func setUp() {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testCLAUDEmdFirstInSort() throws {
        try "# README".write(to: tempDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        try "# Claude".write(to: tempDir.appendingPathComponent("CLAUDE.md"), atomically: true, encoding: .utf8)

        let tree = FileTreeBuilder.build(from: tempDir)
        XCTAssertEqual(tree.first?.name, "CLAUDE.md")
    }

    func testMarkdownFilesDetected() throws {
        try "test".write(to: tempDir.appendingPathComponent("doc.md"), atomically: true, encoding: .utf8)
        try "test".write(to: tempDir.appendingPathComponent("code.ts"), atomically: true, encoding: .utf8)

        let tree = FileTreeBuilder.build(from: tempDir)
        let mdFiles = tree.filter { $0.isMarkdown }
        XCTAssertEqual(mdFiles.count, 1)
    }
}
```

- [ ] **Step 6: Run all tests**

Run: `Cmd+U`
Expected: All tests pass.

- [ ] **Step 7: Commit**

```bash
git add Canto/Canto/Services/ CantoTests/
git commit -m "feat: add folder access, file tree builder, file watcher, and markdown file services"
```

---

## Task 7: Session Manager and Git Service

**Files:**
- Create: `Canto/Canto/Services/SessionManager.swift`
- Create: `Canto/Canto/Services/GitService.swift`
- Test: `Canto/CantoTests/Services/SessionManagerTests.swift`
- Test: `Canto/CantoTests/Services/GitServiceTests.swift`

- [ ] **Step 1: Write failing tests for SessionManager**

```swift
// SessionManagerTests.swift
import XCTest
@testable import Canto

final class SessionManagerTests: XCTestCase {
    func testStartsIdle() {
        let manager = SessionManager(projectPath: "/test", idleTimeout: 5, groupingWindow: 2)
        XCTAssertEqual(manager.state, .idle)
        XCTAssertNil(manager.currentSession)
    }

    func testSingleEventDoesNotStartSession() {
        let manager = SessionManager(projectPath: "/test", idleTimeout: 5, groupingWindow: 2)
        manager.recordFileEvent(path: "file.md", type: .fileModified)
        XCTAssertEqual(manager.state, .idle)
    }

    func testThreeEventsStartSession() {
        let manager = SessionManager(projectPath: "/test", idleTimeout: 5, groupingWindow: 30)
        manager.recordFileEvent(path: "a.md", type: .fileModified)
        manager.recordFileEvent(path: "b.md", type: .fileModified)
        manager.recordFileEvent(path: "c.md", type: .fileCreated)
        XCTAssertEqual(manager.state, .active)
        XCTAssertNotNil(manager.currentSession)
    }

    func testSessionAutoNameFromFile() {
        let manager = SessionManager(projectPath: "/test", idleTimeout: 5, groupingWindow: 30)
        manager.recordFileEvent(path: "auth.md", type: .fileCreated)
        manager.recordFileEvent(path: "auth.ts", type: .fileCreated)
        manager.recordFileEvent(path: "types.ts", type: .fileCreated)
        XCTAssertEqual(manager.currentSession?.name, "auth.md")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: FAIL — SessionManager does not exist.

- [ ] **Step 3: Implement SessionManager**

```swift
// SessionManager.swift
import Foundation

@Observable
class SessionManager {
    enum State: Equatable { case idle, active }

    private(set) var state: State = .idle
    private(set) var currentSession: SessionRecord?
    private(set) var pastSessions: [SessionRecord] = []

    private let projectPath: String
    private let idleTimeout: TimeInterval
    private let groupingWindow: TimeInterval
    private var recentEvents: [(date: Date, path: String)] = []
    private var idleTimer: Timer?
    private let sessionsDirectory: URL

    init(projectPath: String, idleTimeout: TimeInterval = 300, groupingWindow: TimeInterval = 30) {
        self.projectPath = projectPath
        self.idleTimeout = idleTimeout
        self.groupingWindow = groupingWindow

        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.sessionsDirectory = appSupport.appendingPathComponent("Canto/sessions", isDirectory: true)
        try? FileManager.default.createDirectory(at: sessionsDirectory, withIntermediateDirectories: true)

        loadPastSessions()
    }

    func recordFileEvent(path: String, type: SessionEvent.EventType) {
        let now = Date()
        recentEvents.append((date: now, path: path))
        // Clean old events outside grouping window
        recentEvents.removeAll { now.timeIntervalSince($0.date) > groupingWindow }

        if state == .idle {
            if recentEvents.count >= 3 {
                startSession()
            }
        }

        if state == .active, var session = currentSession {
            let event = SessionEvent(type: type, path: path)
            session.events.append(event)
            updateStats(&session, type: type, path: path)
            currentSession = session

            // Update name if still default
            if session.nameSource == "file" && session.name == "New session" {
                if let firstMd = session.events.first(where: {
                    ($0.type == .fileCreated || $0.type == .fileModified) && ($0.path?.hasSuffix(".md") ?? false)
                }) {
                    session.name = URL(fileURLWithPath: firstMd.path ?? "").lastPathComponent
                    session.nameSource = "file"
                    currentSession = session
                }
            }

            resetIdleTimer()
        }
    }

    func recordCommit(hash: String, message: String, filesChanged: Int, insertions: Int, deletions: Int) {
        guard state == .active, var session = currentSession else { return }

        var event = SessionEvent(type: .commit)
        // Create a full commit event — we need to use a different initializer or set properties
        let commitEvent = SessionEvent(
            type: .commit,
            commitHash: hash,
            commitMessage: message,
            filesChanged: filesChanged,
            insertions: insertions,
            deletions: deletions
        )
        session.events.append(commitEvent)
        session.stats.commits += 1
        session.stats.totalInsertions += insertions
        session.stats.totalDeletions += deletions

        // Update name from commit if first commit
        if session.stats.commits == 1 {
            session.name = message
            session.nameSource = "commit"
        }

        currentSession = session
        resetIdleTimer()
    }

    private func startSession() {
        currentSession = SessionRecord.create(projectPath: projectPath)
        state = .active
        resetIdleTimer()
    }

    private func resetIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: idleTimeout, repeats: false) { [weak self] _ in
            self?.endSession()
        }
    }

    private func endSession() {
        guard var session = currentSession else { return }
        session.status = .completed
        session.endedAt = Date()
        saveSession(session)
        pastSessions.insert(session, at: 0)
        currentSession = nil
        state = .idle
        recentEvents.removeAll()
        idleTimer?.invalidate()
    }

    private func updateStats(_ session: inout SessionRecord, type: SessionEvent.EventType, path: String) {
        switch type {
        case .fileCreated: session.stats.filesCreated += 1
        case .fileModified: session.stats.filesModified += 1
        case .fileDeleted: session.stats.filesDeleted += 1
        case .memoryCreated: session.stats.memoriesAdded += 1
        case .memoryUpdated: session.stats.memoriesUpdated += 1
        default: break
        }
    }

    private func saveSession(_ session: SessionRecord) {
        let url = sessionsDirectory.appendingPathComponent("\(session.id).json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(session) {
            try? data.write(to: url)
        }
    }

    private func loadPastSessions() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: sessionsDirectory, includingPropertiesForKeys: nil)
            .filter({ $0.pathExtension == "json" })
            .sorted(by: { $0.lastPathComponent > $1.lastPathComponent })
        else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        pastSessions = files.prefix(20).compactMap { url in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(SessionRecord.self, from: data)
        }
    }
}
```

Note: The `SessionEvent` init needs to be extended to support commit fields. Update `SessionEvent`:

```swift
// Add to SessionEvent.swift
init(type: EventType, path: String? = nil, summary: String? = nil,
     commitHash: String? = nil, commitMessage: String? = nil,
     filesChanged: Int? = nil, insertions: Int? = nil, deletions: Int? = nil) {
    self.id = UUID()
    self.timestamp = Date()
    self.type = type
    self.path = path
    self.summary = summary
    self.commitHash = commitHash
    self.commitMessage = commitMessage
    self.filesChanged = filesChanged
    self.insertions = insertions
    self.deletions = deletions
}
```

- [ ] **Step 4: Create GitService**

```swift
// GitService.swift
import Foundation

struct GitCommit: Identifiable {
    let id: String // hash
    let hash: String
    let message: String
    let date: Date
    let filesChanged: Int
    let insertions: Int
    let deletions: Int
}

enum GitService {
    static func isGitRepo(at path: URL) -> Bool {
        FileManager.default.fileExists(atPath: path.appendingPathComponent(".git").path)
    }

    static func recentCommits(at path: URL, since: Date? = nil, limit: Int = 10) -> [GitCommit] {
        var args = ["log", "--format=%H|%s|%aI", "--shortstat", "-n", "\(limit)"]
        if let since {
            let formatter = ISO8601DateFormatter()
            args.append("--since=\(formatter.string(from: since))")
        }

        guard let output = runGit(args: args, at: path) else { return [] }
        return parseGitLog(output)
    }

    private static func runGit(args: [String], at path: URL) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = args
        process.currentDirectoryURL = path

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    private static func parseGitLog(_ output: String) -> [GitCommit] {
        var commits: [GitCommit] = []
        let lines = output.components(separatedBy: .newlines)
        var i = 0

        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { i += 1; continue }

            let parts = line.components(separatedBy: "|")
            guard parts.count >= 3 else { i += 1; continue }

            let hash = parts[0]
            let message = parts[1]
            let dateStr = parts[2]

            let formatter = ISO8601DateFormatter()
            let date = formatter.date(from: dateStr) ?? Date()

            // Next non-empty line should be the stat line
            var filesChanged = 0, insertions = 0, deletions = 0
            i += 1
            while i < lines.count {
                let statLine = lines[i].trimmingCharacters(in: .whitespaces)
                if statLine.isEmpty { i += 1; continue }
                if statLine.contains("file") {
                    // Parse "3 files changed, 142 insertions(+), 12 deletions(-)"
                    if let fc = statLine.range(of: #"(\d+) file"#, options: .regularExpression) {
                        filesChanged = Int(statLine[fc].components(separatedBy: " ")[0]) ?? 0
                    }
                    if let ins = statLine.range(of: #"(\d+) insertion"#, options: .regularExpression) {
                        insertions = Int(statLine[ins].components(separatedBy: " ")[0]) ?? 0
                    }
                    if let del = statLine.range(of: #"(\d+) deletion"#, options: .regularExpression) {
                        deletions = Int(statLine[del].components(separatedBy: " ")[0]) ?? 0
                    }
                    i += 1
                    break
                }
                i += 1
                break
            }

            commits.append(GitCommit(
                id: hash, hash: hash, message: message, date: date,
                filesChanged: filesChanged, insertions: insertions, deletions: deletions
            ))
        }

        return commits
    }
}
```

- [ ] **Step 5: Run all tests**

Run: `Cmd+U`
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add Canto/Canto/Services/SessionManager.swift Canto/Canto/Services/GitService.swift Canto/Canto/Models/SessionEvent.swift CantoTests/
git commit -m "feat: add session state machine and git service for commit tracking"
```

---

## Task 8: Config Reader Service

**Files:**
- Create: `Canto/Canto/Services/ConfigReader.swift`
- Test: `Canto/CantoTests/Services/ConfigReaderTests.swift`

- [ ] **Step 1: Write failing test**

```swift
// ConfigReaderTests.swift
import XCTest
@testable import Canto

final class ConfigReaderTests: XCTestCase {
    func testParseMCPServers() throws {
        let json = """
        {
          "mcpServers": {
            "supabase": {
              "command": "npx",
              "args": ["-y", "@supabase/mcp-server"]
            },
            "context7": {
              "command": "npx",
              "args": ["@context7/mcp"]
            }
          }
        }
        """
        let servers = ConfigReader.parseMCPServers(from: json)
        XCTAssertEqual(servers.count, 2)
        XCTAssertEqual(servers[0].name, "context7") // sorted alphabetically
    }

    func testParsePermissions() throws {
        let json = """
        {
          "permissions": {
            "allow": ["Bash(npm *)", "Edit"],
            "deny": ["Bash(rm *)"]
          }
        }
        """
        let permissions = ConfigReader.parsePermissions(from: json)
        XCTAssertEqual(permissions.filter { $0.allowed }.count, 2)
        XCTAssertEqual(permissions.filter { !$0.allowed }.count, 1)
    }
}
```

- [ ] **Step 2: Implement ConfigReader**

```swift
// ConfigReader.swift
import Foundation

enum ConfigReader {
    static func readClaudeSettings(globalPath: URL? = nil, projectPath: URL? = nil) -> (
        servers: [MCPServerConfig],
        permissions: [PermissionConfig],
        hooks: [HookConfig]
    ) {
        let globalSettings = globalPath.flatMap { readJSON(at: $0) } ?? [:]
        let projectSettings = projectPath.flatMap { readJSON(at: $0) } ?? [:]

        let mergedJSON: String
        if let data = try? JSONSerialization.data(
            withJSONObject: globalSettings.merging(projectSettings) { _, new in new },
            options: .prettyPrinted
        ), let str = String(data: data, encoding: .utf8) {
            mergedJSON = str
        } else {
            mergedJSON = "{}"
        }

        return (
            servers: parseMCPServers(from: mergedJSON),
            permissions: parsePermissions(from: mergedJSON),
            hooks: parseHooks(from: mergedJSON)
        )
    }

    static func parseMCPServers(from json: String) -> [MCPServerConfig] {
        guard let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let servers = root["mcpServers"] as? [String: Any]
        else { return [] }

        return servers.map { name, config in
            let cfg = config as? [String: Any] ?? [:]
            return MCPServerConfig(
                name: name,
                command: cfg["command"] as? String,
                args: cfg["args"] as? [String],
                url: cfg["url"] as? String,
                toolCount: nil
            )
        }.sorted { $0.name < $1.name }
    }

    static func parsePermissions(from json: String) -> [PermissionConfig] {
        guard let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let permissions = root["permissions"] as? [String: Any]
        else { return [] }

        var result: [PermissionConfig] = []
        if let allow = permissions["allow"] as? [String] {
            result += allow.map { PermissionConfig(tool: $0, scope: "project", allowed: true) }
        }
        if let deny = permissions["deny"] as? [String] {
            result += deny.map { PermissionConfig(tool: $0, scope: "project", allowed: false) }
        }
        return result
    }

    static func parseHooks(from json: String) -> [HookConfig] {
        guard let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = root["hooks"] as? [String: Any]
        else { return [] }

        return hooks.compactMap { event, config in
            if let cmd = config as? String {
                return HookConfig(event: event, command: cmd)
            }
            if let cfg = config as? [String: Any], let cmd = cfg["command"] as? String {
                return HookConfig(event: event, command: cmd)
            }
            return nil
        }
    }

    private static func readJSON(at url: URL) -> [String: Any]? {
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return json
    }
}
```

- [ ] **Step 3: Run tests**

Run: `Cmd+U`
Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add Canto/Canto/Services/ConfigReader.swift CantoTests/
git commit -m "feat: add Claude Code config reader (MCP servers, permissions, hooks)"
```

---

## Task 9: Expand AppState as Root State Manager

**Files:**
- Modify: `Canto/Canto/Models/AppState.swift`

- [ ] **Step 1: Expand AppState to orchestrate all services**

```swift
// AppState.swift
import SwiftUI

@Observable
class AppState {
    // Folder state
    var openFolderURL: URL?
    var fileTree: [FileNode] = []
    var isClaudeProject: Bool = false

    // Tabs
    var tabs: [TabItem] = []
    var activeTabID: String?
    var activeTab: TabItem? { tabs.first { $0.id == activeTabID } }

    // Services
    let settingsManager = SettingsManager()
    let recentFolders = RecentFoldersManager()
    let fileWatcher = FileWatcherService()
    var sessionManager: SessionManager?

    // Claude-specific state
    var memories: [MemoryFile] = []
    var claudeMDSections: [ClaudeMDSection] = []
    var mcpServers: [MCPServerConfig] = []
    var skills: [SkillConfig] = []
    var permissions: [PermissionConfig] = []
    var hooks: [HookConfig] = []

    // Computed
    var hasOpenFolder: Bool { openFolderURL != nil }
    var isSessionActive: Bool { sessionManager?.state == .active }
    var settings: Settings { settingsManager.settings }

    // MARK: - Folder management

    func openFolder(_ url: URL) {
        closeFolderIfNeeded()

        guard FolderAccessService.startAccessing(url: url) else { return }
        openFolderURL = url

        // Build file tree
        fileTree = FileTreeBuilder.build(from: url)

        // Check for Claude project
        isClaudeProject = FileManager.default.fileExists(
            atPath: url.appendingPathComponent(".claude").path
        )

        // Load Claude-specific data if present
        if isClaudeProject {
            loadClaudeData(projectURL: url)
        }

        // Start file watcher
        fileWatcher.onChange = { [weak self] path, flags in
            self?.handleFileChange(path: path, flags: flags)
        }
        fileWatcher.startWatching(path: url.path)

        // Start session manager
        sessionManager = SessionManager(
            projectPath: url.path,
            idleTimeout: TimeInterval(settings.sessionIdleTimeout),
            groupingWindow: TimeInterval(settings.sessionGroupingWindow)
        )

        // Save to recents
        recentFolders.addFolder(url: url)
    }

    func closeFolderIfNeeded() {
        if let url = openFolderURL {
            fileWatcher.stopWatching()
            FolderAccessService.stopAccessing(url: url)
        }
        openFolderURL = nil
        fileTree = []
        tabs = []
        activeTabID = nil
        memories = []
        claudeMDSections = []
        isClaudeProject = false
        sessionManager = nil
    }

    // MARK: - Tab management

    func openFile(_ node: FileNode) {
        // Check if already open
        if let existing = tabs.first(where: { $0.id == node.id }) {
            activeTabID = existing.id
            return
        }

        // Tab limit check (3 for free, unlimited for pro)
        let maxTabs = 3 // TODO: Check pro status
        if tabs.count >= maxTabs {
            // Close oldest non-dirty tab
            if let closable = tabs.first(where: { !$0.isDirty && $0.id != activeTabID }) {
                tabs.removeAll { $0.id == closable.id }
            }
        }

        guard let content = try? MarkdownFileService.read(url: node.url) else { return }
        let tab = TabItem(url: node.url, content: content)
        tabs.append(tab)
        activeTabID = tab.id
    }

    func closeTab(_ id: String) {
        tabs.removeAll { $0.id == id }
        if activeTabID == id {
            activeTabID = tabs.last?.id
        }
    }

    func saveActiveTab() {
        guard let tab = activeTab, tab.isDirty else { return }
        try? MarkdownFileService.write(url: tab.url, content: tab.content)
        tab.isDirty = false
    }

    // MARK: - Claude data loading

    private func loadClaudeData(projectURL: URL) {
        // Parse CLAUDE.md
        let claudeMDPath = projectURL.appendingPathComponent("CLAUDE.md")
        if let content = try? String(contentsOf: claudeMDPath, encoding: .utf8) {
            claudeMDSections = ClaudeMDParser.parse(content)
        }

        // Load memories
        let memoryDir = projectURL.appendingPathComponent(".claude/memory")
        loadMemories(from: memoryDir)

        // Load config
        let projectSettings = projectURL.appendingPathComponent(".claude/settings.json")
        let globalSettings = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")
        let config = ConfigReader.readClaudeSettings(
            globalPath: globalSettings,
            projectPath: projectSettings
        )
        mcpServers = config.servers
        permissions = config.permissions
        hooks = config.hooks
    }

    private func loadMemories(from directory: URL) {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey])
            .filter({ $0.pathExtension == "md" })
        else { return }

        memories = files.compactMap { url in
            guard let content = try? String(contentsOf: url, encoding: .utf8),
                  let attrs = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
                  let modDate = attrs.contentModificationDate
            else { return nil }
            return try? MemoryParser.parse(content: content, url: url, modifiedDate: modDate)
        }
    }

    // MARK: - File watcher handling

    private func handleFileChange(path: String, flags: FSEventStreamEventFlags) {
        guard let folderURL = openFolderURL else { return }

        // Rebuild file tree
        fileTree = FileTreeBuilder.build(from: folderURL)

        let relativePath = path.replacingOccurrences(of: folderURL.path + "/", with: "")
        let url = URL(fileURLWithPath: path)

        // Determine event type
        let isCreated = flags & UInt32(kFSEventStreamEventFlagItemCreated) != 0
        let isRemoved = flags & UInt32(kFSEventStreamEventFlagItemRemoved) != 0
        let isModified = flags & UInt32(kFSEventStreamEventFlagItemModified) != 0

        let eventType: SessionEvent.EventType
        if isCreated {
            if relativePath.contains(".claude/memory/") {
                eventType = .memoryCreated
            } else {
                eventType = .fileCreated
            }
        } else if isRemoved {
            eventType = .fileDeleted
        } else {
            if relativePath.contains(".claude/memory/") {
                eventType = .memoryUpdated
            } else {
                eventType = .fileModified
            }
        }

        // Record in session manager
        sessionManager?.recordFileEvent(path: relativePath, type: eventType)

        // Update open tab if affected
        if let tab = tabs.first(where: { $0.url.path == path }) {
            if isModified && !tab.isDirty {
                // External modification — reload
                if let newContent = try? String(contentsOf: url, encoding: .utf8) {
                    tab.content = newContent
                }
            } else if isModified && tab.isDirty {
                tab.isExternallyModified = true
            } else if isRemoved {
                // File deleted while open
                tab.isExternallyModified = true
            }
        }

        // Reload Claude data if relevant files changed
        if relativePath == "CLAUDE.md" || relativePath.hasPrefix(".claude/") {
            loadClaudeData(projectURL: folderURL)
        }
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `Cmd+B`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Canto/Canto/Models/AppState.swift
git commit -m "feat: expand AppState as root state manager orchestrating all services"
```

---

## Task 10: Milkdown Editor Web Bundle

**Files:**
- Create: `editor-web/package.json`
- Create: `editor-web/tsconfig.json`
- Create: `editor-web/vite.config.ts`
- Create: `editor-web/src/index.ts`
- Create: `editor-web/src/bridge.ts`
- Create: `editor-web/src/slash-menu.ts`
- Create: `editor-web/src/styles/editor.css`
- Create: `editor-web/src/styles/dark.css`
- Create: `editor-web/src/styles/light.css`
- Create: `editor-web/index.html`

- [ ] **Step 1: Initialize npm project**

```bash
cd /Users/diego/dev/mder
mkdir -p editor-web/src/styles
cd editor-web
npm init -y
```

- [ ] **Step 2: Install dependencies**

```bash
npm install @milkdown/core @milkdown/ctx @milkdown/preset-commonmark @milkdown/preset-gfm @milkdown/plugin-slash @milkdown/plugin-listener @milkdown/plugin-history @milkdown/plugin-clipboard @milkdown/plugin-trailing @milkdown/theme-nord @prosemirror/view
npm install -D typescript vite @types/node
```

- [ ] **Step 3: Create package.json scripts and tsconfig**

Update `package.json` scripts:
```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build"
  }
}
```

Create `tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
```

Create `vite.config.ts`:
```typescript
import { defineConfig } from 'vite'

export default defineConfig({
  build: {
    outDir: 'dist',
    rollupOptions: {
      input: 'index.html',
    },
  },
})
```

- [ ] **Step 4: Create the bridge (Swift ↔ JS communication)**

```typescript
// src/bridge.ts

export interface CantoMessage {
  type: 'loadFile' | 'setTheme' | 'focusLine' | 'getContent' | 'toggleCodeView'
  payload?: any
}

export function sendToSwift(type: string, data: any) {
  // WKWebView message handler
  (window as any).webkit?.messageHandlers?.canto?.postMessage({
    type,
    data,
  })
}

export function setupBridge(callbacks: {
  onLoadFile: (content: string) => void
  onSetTheme: (theme: 'dark' | 'light') => void
  onFocusLine: (line: number) => void
  onToggleCodeView: () => void
}) {
  // Swift calls these via evaluateJavaScript
  ;(window as any).cantoReceive = (message: CantoMessage) => {
    switch (message.type) {
      case 'loadFile':
        callbacks.onLoadFile(message.payload)
        break
      case 'setTheme':
        callbacks.onSetTheme(message.payload)
        break
      case 'focusLine':
        callbacks.onFocusLine(message.payload)
        break
      case 'toggleCodeView':
        callbacks.onToggleCodeView()
        break
    }
  }
}
```

- [ ] **Step 5: Create the Milkdown editor setup**

```typescript
// src/index.ts
import { Editor, rootCtx, defaultValueCtx } from '@milkdown/core'
import { commonmark } from '@milkdown/preset-commonmark'
import { gfm } from '@milkdown/preset-gfm'
import { history } from '@milkdown/plugin-history'
import { clipboard } from '@milkdown/plugin-clipboard'
import { trailing } from '@milkdown/plugin-trailing'
import { listener, listenerCtx } from '@milkdown/plugin-listener'
import { slash, slashFactory } from '@milkdown/plugin-slash'
import { setupBridge, sendToSwift } from './bridge'
import { createSlashMenu } from './slash-menu'
import './styles/editor.css'
import './styles/dark.css'

let editor: Editor | null = null
let isCodeView = false
let currentContent = ''

async function createEditor(content: string) {
  const el = document.getElementById('editor')!
  el.innerHTML = ''

  editor = await Editor.make()
    .config((ctx) => {
      ctx.set(rootCtx, el)
      ctx.set(defaultValueCtx, content)
      ctx.set(listenerCtx, {
        markdown: [(getMarkdown) => {
          const md = getMarkdown()
          if (md !== currentContent) {
            currentContent = md
            sendToSwift('contentChanged', md)
          }
        }],
      })
    })
    .use(commonmark)
    .use(gfm)
    .use(history)
    .use(clipboard)
    .use(trailing)
    .use(listener)
    .create()

  currentContent = content
}

function showCodeView(content: string) {
  const el = document.getElementById('editor')!
  el.innerHTML = `<pre class="code-view"><code>${escapeHtml(content)}</code></pre>`
  isCodeView = true
}

function showWysiwygView(content: string) {
  isCodeView = false
  createEditor(content)
}

function escapeHtml(str: string): string {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
}

function updateWordCount(content: string) {
  const words = content.trim().split(/\s+/).filter(Boolean).length
  const readingTime = Math.max(1, Math.ceil(words / 200))
  sendToSwift('wordCount', { words, readingTime })
}

// Set up bridge
setupBridge({
  onLoadFile: (content) => {
    currentContent = content
    if (isCodeView) {
      showCodeView(content)
    } else {
      createEditor(content)
    }
    updateWordCount(content)
  },
  onSetTheme: (theme) => {
    document.body.className = `theme-${theme}`
  },
  onFocusLine: (line) => {
    // Scroll to approximate position based on line number
    const el = document.getElementById('editor')!
    const lineHeight = 24
    el.scrollTop = (line - 1) * lineHeight
  },
  onToggleCodeView: () => {
    if (isCodeView) {
      showWysiwygView(currentContent)
    } else {
      showCodeView(currentContent)
    }
  },
})

// Signal ready
sendToSwift('ready', null)
```

- [ ] **Step 6: Create styles**

```css
/* src/styles/editor.css */
* { box-sizing: border-box; margin: 0; padding: 0; }

body {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Inter', sans-serif;
  font-size: 16px;
  line-height: 1.6;
  padding: 32px 48px;
  max-width: 800px;
  margin: 0 auto;
  -webkit-font-smoothing: antialiased;
}

#editor {
  outline: none;
  min-height: 100vh;
}

#editor h1 { font-size: 28px; font-weight: 700; margin: 24px 0 12px; }
#editor h2 { font-size: 22px; font-weight: 700; margin: 20px 0 10px; }
#editor h3 { font-size: 18px; font-weight: 600; margin: 16px 0 8px; }

#editor p { margin: 8px 0; }

#editor ul, #editor ol { padding-left: 24px; margin: 8px 0; }
#editor li { margin: 4px 0; }

#editor code {
  font-family: 'SF Mono', 'JetBrains Mono', monospace;
  font-size: 14px;
  padding: 2px 6px;
  border-radius: 4px;
}

#editor pre {
  font-family: 'SF Mono', 'JetBrains Mono', monospace;
  font-size: 14px;
  padding: 16px;
  border-radius: 8px;
  overflow-x: auto;
  margin: 12px 0;
}

#editor blockquote {
  border-left: 3px solid #8B5CF6;
  padding-left: 16px;
  margin: 12px 0;
}

#editor table { border-collapse: collapse; width: 100%; margin: 12px 0; }
#editor th, #editor td { border: 1px solid; padding: 8px 12px; text-align: left; }

#editor a { color: #8B5CF6; text-decoration: none; }
#editor a:hover { text-decoration: underline; }

#editor img { max-width: 100%; border-radius: 8px; margin: 12px 0; }

#editor hr { border: none; height: 1px; margin: 24px 0; }

.code-view {
  font-family: 'SF Mono', 'JetBrains Mono', monospace;
  font-size: 14px;
  line-height: 1.5;
  padding: 16px;
  white-space: pre-wrap;
  word-break: break-word;
}

/* Checkbox styling */
#editor input[type="checkbox"] { margin-right: 8px; accent-color: #8B5CF6; }
```

```css
/* src/styles/dark.css */
body.theme-dark, body:not(.theme-light) {
  background: #0A0A0F;
  color: #E4E4E7;
}
body.theme-dark #editor code { background: #1E1E2E; color: #E4E4E7; }
body.theme-dark #editor pre { background: #1E1E2E; }
body.theme-dark #editor th, body.theme-dark #editor td { border-color: #2A2A3A; }
body.theme-dark #editor hr { background: #2A2A3A; }
body.theme-dark .code-view { background: #1E1E2E; color: #E4E4E7; }
```

```css
/* src/styles/light.css */
body.theme-light {
  background: #FAFAFA;
  color: #18181B;
}
body.theme-light #editor code { background: #F0F0F5; color: #18181B; }
body.theme-light #editor pre { background: #F0F0F5; }
body.theme-light #editor th, body.theme-light #editor td { border-color: #E4E4E7; }
body.theme-light #editor hr { background: #E4E4E7; }
body.theme-light .code-view { background: #F0F0F5; color: #18181B; }
```

- [ ] **Step 7: Create index.html**

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Canto Editor</title>
</head>
<body class="theme-dark">
  <div id="editor"></div>
  <script type="module" src="/src/index.ts"></script>
</body>
</html>
```

- [ ] **Step 8: Build the editor bundle**

```bash
cd /Users/diego/dev/mder/editor-web
npm run build
```

Expected: `dist/` directory created with `index.html`, JS and CSS bundles.

- [ ] **Step 9: Commit**

```bash
cd /Users/diego/dev/mder
git add editor-web/
git commit -m "feat: add Milkdown WYSIWYG editor web bundle with Swift bridge"
```

---

## Task 11: WKWebView Swift Wrapper

**Files:**
- Create: `Canto/Canto/Views/Editor/MarkdownWebView.swift`

- [ ] **Step 1: Create the NSViewRepresentable wrapper**

```swift
// MarkdownWebView.swift
import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let content: String
    let theme: String
    let onContentChange: (String) -> Void
    let onWordCount: (Int, Int) -> Void // words, readingTime

    func makeCoordinator() -> Coordinator {
        Coordinator(onContentChange: onContentChange, onWordCount: onWordCount)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "canto")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isInspectable = true // Debug in Safari Web Inspector
        webView.setValue(false, forKey: "drawsBackground") // Transparent background

        context.coordinator.webView = webView

        // Load the editor bundle
        if let editorURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "editor-web") {
            webView.loadFileURL(editorURL, allowingReadAccessTo: editorURL.deletingLastPathComponent())
        }

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.sendToJS(webView: webView, type: "loadFile", payload: content)
        context.coordinator.sendToJS(webView: webView, type: "setTheme", payload: theme)
    }

    class Coordinator: NSObject, WKScriptMessageHandler {
        var webView: WKWebView?
        var isReady = false
        var pendingMessages: [(String, String)] = []
        let onContentChange: (String) -> Void
        let onWordCount: (Int, Int) -> Void

        init(onContentChange: @escaping (String) -> Void, onWordCount: @escaping (Int, Int) -> Void) {
            self.onContentChange = onContentChange
            self.onWordCount = onWordCount
        }

        func userContentController(_ userContentController: WKUserContentController,
                                    didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any],
                  let type = body["type"] as? String
            else { return }

            switch type {
            case "ready":
                isReady = true
                for (type, payload) in pendingMessages {
                    sendToJS(webView: webView!, type: type, payload: payload)
                }
                pendingMessages.removeAll()
            case "contentChanged":
                if let content = body["data"] as? String {
                    DispatchQueue.main.async { self.onContentChange(content) }
                }
            case "wordCount":
                if let data = body["data"] as? [String: Int],
                   let words = data["words"],
                   let readingTime = data["readingTime"] {
                    DispatchQueue.main.async { self.onWordCount(words, readingTime) }
                }
            default:
                break
            }
        }

        func sendToJS(webView: WKWebView, type: String, payload: String) {
            guard isReady else {
                pendingMessages.append((type, payload))
                return
            }
            let escapedPayload = payload
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
                .replacingOccurrences(of: "\n", with: "\\n")
            let js = "window.cantoReceive({ type: '\(type)', payload: '\(escapedPayload)' })"
            webView.evaluateJavaScript(js)
        }
    }
}
```

- [ ] **Step 2: Copy editor-web dist into Xcode project**

In Xcode, add the `editor-web/dist/` directory as a folder reference to the Canto target. This bundles the built editor into the app.

Add a Build Phase script to auto-build the editor:
```bash
cd "${SRCROOT}/../editor-web"
npm run build
```

- [ ] **Step 3: Build and verify WebView loads**

Create a test view that loads MarkdownWebView with sample content. Run the app and verify the editor renders markdown.

- [ ] **Step 4: Commit**

```bash
git add Canto/Canto/Views/Editor/MarkdownWebView.swift
git commit -m "feat: add WKWebView wrapper for Milkdown editor with Swift-JS bridge"
```

---

## Task 12: Welcome Screen and Folder Opening

**Files:**
- Create: `Canto/Canto/Views/WelcomeView.swift`
- Modify: `Canto/Canto/Views/MainWindowView.swift`

- [ ] **Step 1: Create WelcomeView**

```swift
// WelcomeView.swift
import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo
            VStack(spacing: 12) {
                Circle()
                    .fill(CantoColors.accent)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .fill(CantoColors.accent.opacity(0.3))
                            .frame(width: 56, height: 56)
                    )

                Text("Canto")
                    .font(CantoTypography.displayLarge)
                    .foregroundStyle(CantoColors.textPrimary)

                Text("See what you build with Claude.")
                    .font(CantoTypography.body)
                    .foregroundStyle(CantoColors.textSecondary)
            }

            // Drop zone
            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(CantoColors.textSecondary.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .frame(height: 120)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 28))
                                .foregroundStyle(CantoColors.textSecondary)
                            Text("Drop a project folder here")
                                .font(CantoTypography.body)
                                .foregroundStyle(CantoColors.textSecondary)
                        }
                    )
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        handleDrop(providers)
                    }

                Button("Open Folder") {
                    if let url = FolderAccessService.openFolderPanel() {
                        appState.openFolder(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(CantoColors.accent)
                .controlSize(.large)
            }
            .frame(maxWidth: 400)

            // Recent folders
            if !appState.recentFolders.folders.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent")
                        .font(CantoTypography.sidebarBold)
                        .foregroundStyle(CantoColors.textSecondary)

                    ForEach(appState.recentFolders.folders.prefix(5)) { folder in
                        Button {
                            if let url = appState.recentFolders.resolveBookmark(folder) {
                                appState.openFolder(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                    .foregroundStyle(CantoColors.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(folder.path.components(separatedBy: "/").suffix(2).joined(separator: "/"))
                                        .font(CantoTypography.sidebar)
                                        .foregroundStyle(CantoColors.textPrimary)
                                    HStack(spacing: 8) {
                                        if folder.hasClaude {
                                            Text("\(folder.memoryCount) memories")
                                                .font(CantoTypography.uiSmall)
                                                .foregroundStyle(CantoColors.accent)
                                        }
                                        Text(folder.lastOpened, style: .relative)
                                            .font(CantoTypography.uiSmall)
                                            .foregroundStyle(CantoColors.textSecondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(CantoColors.surface.opacity(0.5))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: 400)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CantoColors.background)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil),
                  url.hasDirectoryPath
            else { return }
            DispatchQueue.main.async {
                appState.openFolder(url)
            }
        }
        return true
    }
}
```

- [ ] **Step 2: Update MainWindowView with NavigationSplitView**

```swift
// MainWindowView.swift
import SwiftUI

struct MainWindowView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.hasOpenFolder {
                NavigationSplitView {
                    Text("Sidebar placeholder")
                } detail: {
                    Text("Editor placeholder")
                }
            } else {
                WelcomeView()
            }
        }
        .preferredColorScheme(appState.settings.theme == "dark" ? .dark : .light)
        .onOpenURL { url in
            if url.hasDirectoryPath {
                appState.openFolder(url)
            }
        }
    }
}
```

- [ ] **Step 3: Build and run**

Run: `Cmd+R`
Expected: Welcome screen with Canto branding, drop zone, Open Folder button. Clicking Open Folder shows file picker. Selecting a folder navigates to editor placeholder.

- [ ] **Step 4: Commit**

```bash
git add Canto/Canto/Views/
git commit -m "feat: add welcome screen with folder drop zone, recent folders, and main window routing"
```

---

## Task 13: Sidebar Implementation

**Files:**
- Create: `Canto/Canto/Views/Sidebar/SidebarView.swift`
- Create: `Canto/Canto/Views/Sidebar/ClaudeSidebarSection.swift`
- Create: `Canto/Canto/Views/Sidebar/FileTreeView.swift`
- Create: `Canto/Canto/Views/Sidebar/SessionSidebarSection.swift`
- Modify: `Canto/Canto/Views/MainWindowView.swift`

- [ ] **Step 1: Create SidebarView container**

```swift
// SidebarView.swift
import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        List {
            if appState.isClaudeProject {
                ClaudeSidebarSection()
            }

            FileTreeSection()

            if appState.isSessionActive {
                SessionSidebarSection()
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
    }
}
```

- [ ] **Step 2: Create ClaudeSidebarSection**

```swift
// ClaudeSidebarSection.swift
import SwiftUI

struct ClaudeSidebarSection: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Section("CLAUDE") {
            // CLAUDE.md — always first, highlighted
            if let claudeNode = appState.fileTree.first(where: { $0.isClaudeMD }) {
                Button {
                    appState.openFile(claudeNode)
                } label: {
                    Label {
                        Text("CLAUDE.md")
                            .font(CantoTypography.sidebarBold)
                    } icon: {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(CantoColors.accent)
                    }
                }
                .buttonStyle(.plain)
            }

            // Memory
            DisclosureGroup {
                ForEach(appState.memories) { memory in
                    Button {
                        // Open memory file
                        let node = FileNode(
                            id: memory.url.lastPathComponent,
                            name: memory.name,
                            url: memory.url,
                            isDirectory: false,
                            children: nil,
                            fileExtension: "md"
                        )
                        appState.openFile(node)
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(CantoColors.forMemoryType(memory.type.rawValue))
                                .frame(width: 8, height: 8)
                            Text(memory.name)
                                .font(CantoTypography.sidebar)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            } label: {
                Label {
                    HStack {
                        Text("Memory")
                            .font(CantoTypography.sidebar)
                        Spacer()
                        Text("\(appState.memories.count)")
                            .font(CantoTypography.uiSmall)
                            .foregroundStyle(CantoColors.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(CantoColors.surface)
                            .cornerRadius(4)
                    }
                } icon: {
                    Image(systemName: "brain")
                        .foregroundStyle(CantoColors.accent)
                }
            }

            // Config
            Button {
                // Open config panel
            } label: {
                Label("Config", systemImage: "gearshape")
                    .font(CantoTypography.sidebar)
            }
            .buttonStyle(.plain)
        }
    }
}
```

- [ ] **Step 3: Create FileTreeView**

```swift
// FileTreeView.swift
import SwiftUI

struct FileTreeSection: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Section("FILES") {
            ForEach(filteredNodes, id: \.id) { node in
                FileNodeRow(node: node)
            }
        }
    }

    private var filteredNodes: [FileNode] {
        // Exclude CLAUDE.md and .claude/ (shown in CLAUDE section)
        appState.fileTree.filter { node in
            !node.isClaudeMD && node.name != ".claude"
        }
    }
}

struct FileNodeRow: View {
    @Environment(AppState.self) private var appState
    let node: FileNode

    var body: some View {
        if node.isDirectory {
            DisclosureGroup(isExpanded: .constant(node.hasMarkdownChildren)) {
                if let children = node.children {
                    ForEach(children, id: \.id) { child in
                        FileNodeRow(node: child)
                    }
                }
            } label: {
                Label {
                    Text(node.name)
                        .font(CantoTypography.sidebar)
                        .foregroundStyle(node.hasMarkdownChildren ? CantoColors.textPrimary : CantoColors.textSecondary)
                } icon: {
                    Image(systemName: "folder")
                        .foregroundStyle(node.hasMarkdownChildren ? CantoColors.accent : CantoColors.textSecondary)
                }
            }
        } else {
            Button {
                appState.openFile(node)
            } label: {
                Label {
                    Text(node.name)
                        .font(CantoTypography.sidebar)
                        .foregroundStyle(node.isMarkdown ? CantoColors.textPrimary : CantoColors.textSecondary)
                } icon: {
                    Image(systemName: iconForNode(node))
                        .foregroundStyle(node.isMarkdown ? CantoColors.accent : CantoColors.textSecondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func iconForNode(_ node: FileNode) -> String {
        if node.isMarkdown { return "doc.richtext" }
        if node.isImage { return "photo" }
        if node.isCode { return "chevron.left.forwardslash.chevron.right" }
        if node.isConfig { return "gearshape" }
        return "doc"
    }
}
```

- [ ] **Step 4: Create SessionSidebarSection**

```swift
// SessionSidebarSection.swift
import SwiftUI

struct SessionSidebarSection: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Section("SESSION") {
            if let session = appState.sessionManager?.currentSession {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(CantoColors.sessionActive)
                            .frame(width: 8, height: 8)
                        Text("Active")
                            .font(CantoTypography.sidebarBold)
                            .foregroundStyle(CantoColors.sessionActive)
                        Text("·")
                        Text(session.startedAt, style: .relative)
                            .font(CantoTypography.uiSmall)
                            .foregroundStyle(CantoColors.textSecondary)
                    }
                    Text("\(session.stats.filesCreated + session.stats.filesModified) files · \(session.stats.commits) commits")
                        .font(CantoTypography.uiSmall)
                        .foregroundStyle(CantoColors.textSecondary)
                }

                Button {
                    // Open timeline
                } label: {
                    Label("Open timeline", systemImage: "clock")
                        .font(CantoTypography.sidebar)
                }
                .buttonStyle(.plain)
            }

            // Past sessions
            if let pastSessions = appState.sessionManager?.pastSessions.prefix(3) {
                ForEach(Array(pastSessions), id: \.id) { session in
                    Button {
                        // Open past session timeline
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.name)
                                .font(CantoTypography.sidebar)
                                .lineLimit(1)
                            Text(session.startedAt, style: .date)
                                .font(CantoTypography.uiSmall)
                                .foregroundStyle(CantoColors.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
```

- [ ] **Step 5: Update MainWindowView to use sidebar**

```swift
// MainWindowView.swift — update the NavigationSplitView
NavigationSplitView {
    SidebarView()
} detail: {
    EditorContainerView()
}
.navigationSplitViewStyle(.balanced)
```

- [ ] **Step 6: Build and run, open a project folder with .claude/**

Expected: Sidebar shows CLAUDE.md highlighted, memory files with colored dots, file tree with .md files prominent and other files greyed.

- [ ] **Step 7: Commit**

```bash
git add Canto/Canto/Views/Sidebar/ Canto/Canto/Views/MainWindowView.swift
git commit -m "feat: add Claude-aware sidebar with memory browser, file tree, and session section"
```

---

## Task 14: Editor Container with Tab Bar

**Files:**
- Create: `Canto/Canto/Views/Editor/TabBarView.swift`
- Create: `Canto/Canto/Views/Editor/EditorContainerView.swift`
- Create: `Canto/Canto/Views/Components/BreadcrumbView.swift`
- Create: `Canto/Canto/Views/Components/StatusBarView.swift`

- [ ] **Step 1: Create TabBarView**

```swift
// TabBarView.swift
import SwiftUI

struct TabBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(appState.tabs) { tab in
                    TabButton(tab: tab, isActive: tab.id == appState.activeTabID)
                }
            }
        }
        .frame(height: 36)
        .background(CantoColors.surface)
    }
}

struct TabButton: View {
    @Environment(AppState.self) private var appState
    let tab: TabItem
    let isActive: Bool

    var body: some View {
        Button {
            appState.activeTabID = tab.id
        } label: {
            HStack(spacing: 6) {
                Text(tab.name)
                    .font(CantoTypography.ui)
                    .foregroundStyle(isActive ? CantoColors.textPrimary : CantoColors.textSecondary)
                    .lineLimit(1)

                if tab.isBeingModifiedByClaud {
                    Circle()
                        .fill(CantoColors.accent)
                        .frame(width: 6, height: 6)
                        .modifier(PulseModifier())
                } else if tab.isDirty {
                    Circle()
                        .fill(CantoColors.textSecondary)
                        .frame(width: 6, height: 6)
                }

                Button {
                    appState.closeTab(tab.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(CantoColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isActive ? CantoColors.background : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing && !reduceMotion ? 0.4 : 1.0)
            .onAppear {
                if !reduceMotion {
                    withAnimation(CantoAnimations.pulse) { isPulsing = true }
                }
            }
    }
}
```

- [ ] **Step 2: Create EditorContainerView**

```swift
// EditorContainerView.swift
import SwiftUI

struct EditorContainerView: View {
    @Environment(AppState.self) private var appState
    @State private var wordCount = 0
    @State private var readingTime = 1

    var body: some View {
        VStack(spacing: 0) {
            if !appState.tabs.isEmpty {
                TabBarView()
                Divider()

                if let tab = appState.activeTab {
                    BreadcrumbView(path: tab.url.path, projectRoot: appState.openFolderURL?.path ?? "")

                    // Route to appropriate view
                    Group {
                        if tab.url.lastPathComponent == "CLAUDE.md" {
                            Text("CLAUDE.md Dashboard — Task 15")
                        } else if tab.url.path.contains(".claude/memory/") {
                            Text("Memory view — Task 16")
                        } else if tab.url.pathExtension == "md" {
                            MarkdownWebView(
                                content: tab.content,
                                theme: appState.settings.theme,
                                onContentChange: { newContent in
                                    tab.content = newContent
                                    tab.isDirty = true
                                },
                                onWordCount: { words, time in
                                    wordCount = words
                                    readingTime = time
                                }
                            )
                        } else if FileNode(id: "", name: "", url: tab.url, isDirectory: false, children: nil, fileExtension: tab.url.pathExtension).isImage {
                            ImagePreviewView(url: tab.url)
                        } else {
                            CodePreviewView(url: tab.url)
                        }
                    }
                    .transition(.opacity.animation(CantoAnimations.tabSwitch))

                    // Conflict banner
                    if tab.isExternallyModified {
                        ConflictBannerView(tab: tab)
                    }
                }
            } else {
                EmptyStateView(
                    icon: "doc.richtext",
                    title: "No file open",
                    subtitle: "Select a file from the sidebar to start editing"
                )
            }

            // Status bar
            StatusBarView(wordCount: wordCount, readingTime: readingTime)
        }
    }
}
```

- [ ] **Step 3: Create BreadcrumbView and StatusBarView**

```swift
// BreadcrumbView.swift
import SwiftUI

struct BreadcrumbView: View {
    let path: String
    let projectRoot: String

    var body: some View {
        let relativePath = path.replacingOccurrences(of: projectRoot + "/", with: "")
        let components = relativePath.components(separatedBy: "/")

        HStack(spacing: 4) {
            ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                if index > 0 {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9))
                        .foregroundStyle(CantoColors.textSecondary)
                }
                Text(component)
                    .font(CantoTypography.uiSmall)
                    .foregroundStyle(index == components.count - 1 ? CantoColors.textPrimary : CantoColors.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(CantoColors.surface.opacity(0.5))
    }
}
```

```swift
// StatusBarView.swift
import SwiftUI

struct StatusBarView: View {
    @Environment(AppState.self) private var appState
    let wordCount: Int
    let readingTime: Int

    var body: some View {
        HStack {
            if let session = appState.sessionManager?.currentSession, appState.isSessionActive {
                HStack(spacing: 6) {
                    Circle()
                        .fill(CantoColors.sessionActive)
                        .frame(width: 6, height: 6)
                    Text("Session: \(session.name)")
                        .font(CantoTypography.uiSmall)
                    Text("·")
                    Text("\(session.stats.filesCreated + session.stats.filesModified) files")
                        .font(CantoTypography.uiSmall)
                    Text("·")
                    Text(session.startedAt, style: .relative)
                        .font(CantoTypography.uiSmall)
                }
                .foregroundStyle(CantoColors.textSecondary)
            }

            Spacer()

            if wordCount > 0 && appState.settings.showWordCount {
                Text("\(wordCount) words · \(readingTime) min read")
                    .font(CantoTypography.uiSmall)
                    .foregroundStyle(CantoColors.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(CantoColors.surface)
    }
}
```

- [ ] **Step 4: Create simple helper views**

```swift
// EmptyStateView.swift
import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(CantoColors.textSecondary.opacity(0.5))
            Text(title)
                .font(CantoTypography.body)
                .foregroundStyle(CantoColors.textSecondary)
            Text(subtitle)
                .font(CantoTypography.bodySmall)
                .foregroundStyle(CantoColors.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CantoColors.background)
    }
}
```

```swift
// ConflictBannerView.swift
import SwiftUI

struct ConflictBannerView: View {
    @Environment(AppState.self) private var appState
    let tab: TabItem

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(CantoColors.memoryProject)
            Text("\(tab.name) was modified externally")
                .font(CantoTypography.ui)

            Spacer()

            Button("Accept external") {
                if let content = try? MarkdownFileService.read(url: tab.url) {
                    tab.content = content
                    tab.isDirty = false
                    tab.isExternallyModified = false
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button("Keep mine") {
                tab.isExternallyModified = false
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(CantoColors.memoryProject.opacity(0.1))
    }
}
```

```swift
// ImagePreviewView.swift
import SwiftUI

struct ImagePreviewView: View {
    let url: URL

    var body: some View {
        ScrollView {
            if let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CantoColors.background)
    }
}
```

```swift
// CodePreviewView.swift
import SwiftUI

struct CodePreviewView: View {
    let url: URL
    @State private var content = ""

    var body: some View {
        ScrollView {
            Text(content)
                .font(CantoTypography.code)
                .foregroundStyle(CantoColors.textPrimary)
                .textSelection(.enabled)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(CantoColors.background)
        .onAppear {
            content = (try? String(contentsOf: url, encoding: .utf8)) ?? "Unable to read file"
        }
    }
}
```

- [ ] **Step 5: Build and run, open a project, click files**

Expected: Tab bar shows open files with state dots. Clicking .md files shows WYSIWYG editor. Clicking images shows preview. Clicking code files shows syntax view. Breadcrumb shows current path. Status bar shows session info and word count.

- [ ] **Step 6: Commit**

```bash
git add Canto/Canto/Views/
git commit -m "feat: add editor container with tab bar, breadcrumb, status bar, and file routing"
```

---

## Task 15: CLAUDE.md Dashboard View

**Files:**
- Create: `Canto/Canto/Views/Dashboard/ClaudeMDDashboardView.swift`
- Create: `Canto/Canto/Views/Dashboard/DashboardSectionView.swift`
- Create: `Canto/Canto/Views/Dashboard/RuleCardView.swift`
- Create: `Canto/Canto/Views/Dashboard/QuickSetupView.swift`

- [ ] **Step 1: Create the dashboard components**

Build the views following the spec: collapsible sections from parsed ClaudeMDSections, rule cards from bullet points, Quick Setup when empty, Memory Summary pills, Raw markdown toggle. Use the ClaudeMDParser to parse and ClaudeMDParser.toMarkdown() to save back.

- [ ] **Step 2: Wire up in EditorContainerView**

Replace the CLAUDE.md placeholder with `ClaudeMDDashboardView(sections: appState.claudeMDSections)`.

- [ ] **Step 3: Build, run, open a project with CLAUDE.md**

Expected: CLAUDE.md opens as dashboard, not raw markdown. Sections are collapsible. Rules appear as cards. Raw markdown toggle works.

- [ ] **Step 4: Commit**

```bash
git add Canto/Canto/Views/Dashboard/
git commit -m "feat: add CLAUDE.md dashboard with sections, rule cards, and quick setup"
```

---

## Task 16: Memory Browser View

**Files:**
- Create: `Canto/Canto/Views/Memory/MemoryBrowserView.swift`
- Create: `Canto/Canto/Views/Memory/MemoryCardView.swift`
- Create: `Canto/Canto/Views/Memory/MemoryCreateSheet.swift`

- [ ] **Step 1: Build memory browser components**

Grid of cards with type color tags, search bar with fuzzy filter, type filter tabs, stale indicator for old project memories, [+ New Memory] button that opens create sheet with type dropdown and frontmatter generation.

- [ ] **Step 2: Wire up in sidebar and editor container**

Clicking memory/ folder in sidebar opens MemoryBrowserView in the content area.

- [ ] **Step 3: Build, run, verify memory browser**

Expected: Memory cards display with correct colors. Filter and search work. Create wizard generates valid frontmatter.

- [ ] **Step 4: Commit**

```bash
git add Canto/Canto/Views/Memory/
git commit -m "feat: add memory browser with cards, search, filter, and create wizard"
```

---

## Task 17: Session Timeline View

**Files:**
- Create: `Canto/Canto/Views/Session/SessionTimelineView.swift`
- Create: `Canto/Canto/Views/Session/SessionSummaryCard.swift`
- Create: `Canto/Canto/Views/Session/TimelineEventRow.swift`

- [ ] **Step 1: Build session timeline components**

Summary card at top with stats. Chronological event list with icons per event type. [View] links on files, [View diff] on commits. Compact/Full toggle.

- [ ] **Step 2: Wire up in sidebar**

Clicking "Open timeline" in session sidebar section opens SessionTimelineView.

- [ ] **Step 3: Build, run, trigger a session by opening files rapidly**

Expected: Session starts after 3+ file changes. Timeline populates with events. Summary card updates.

- [ ] **Step 4: Commit**

```bash
git add Canto/Canto/Views/Session/
git commit -m "feat: add session timeline with summary card, event rows, and compact/full toggle"
```

---

## Task 18: Config Panel View

**Files:**
- Create: `Canto/Canto/Views/Config/ConfigPanelView.swift`
- Create: `Canto/Canto/Views/Config/MCPServerRow.swift`
- Create: `Canto/Canto/Views/Config/SkillRow.swift`

- [ ] **Step 1: Build config panel with tabs**

Three tabs: MCP Servers, Skills, Permissions. Each shows read-only cards from the parsed config. MCP servers show name, command, configured status. Skills show name, description, source. Permissions show tool name, scope, allowed/denied.

- [ ] **Step 2: Wire up in sidebar**

Clicking "Config" in CLAUDE sidebar section opens ConfigPanelView.

- [ ] **Step 3: Build, run, verify config panel reads ~/.claude/settings.json**

Expected: MCP servers, skills, and permissions display correctly from Claude Code's config.

- [ ] **Step 4: Commit**

```bash
git add Canto/Canto/Views/Config/
git commit -m "feat: add read-only config panel for MCP servers, skills, and permissions"
```

---

## Task 19: Command Palette

**Files:**
- Create: `Canto/Canto/Views/Components/CommandPaletteView.swift`
- Modify: `Canto/Canto/Views/MainWindowView.swift`

- [ ] **Step 1: Build command palette overlay**

Floating search bar activated by Cmd+K. Lists: recent files, available actions (new memory, new document, toggle theme, toggle code view, open timeline, focus mode). Fuzzy search filtering. Keyboard navigation (arrow keys + Enter).

- [ ] **Step 2: Add keyboard shortcut to MainWindowView**

Use `.onKeyPress` or `.keyboardShortcut` to listen for Cmd+K and show the palette as an overlay.

- [ ] **Step 3: Build, run, press Cmd+K**

Expected: Palette appears centered, lists actions and files, filtering works, Enter executes action.

- [ ] **Step 4: Commit**

```bash
git add Canto/Canto/Views/Components/CommandPaletteView.swift Canto/Canto/Views/MainWindowView.swift
git commit -m "feat: add Cmd+K command palette with fuzzy search and keyboard navigation"
```

---

## Task 20: Keyboard Shortcuts and Focus Mode

**Files:**
- Modify: `Canto/Canto/Views/MainWindowView.swift`
- Modify: `Canto/Canto/Views/Editor/EditorContainerView.swift`

- [ ] **Step 1: Add all keyboard shortcuts**

Wire up all shortcuts from the spec: Cmd+/ (toggle code), Cmd+Shift+Enter (focus mode), Cmd+B/I/Shift+X (formatting via WebView), Ctrl+Tab (switch tabs), Cmd+W (close tab), Cmd+O (open folder), Cmd+N (new file), Cmd+S (save).

- [ ] **Step 2: Implement focus mode**

When activated: sidebar collapses, status bar hides, tab bar hides, content area centers with generous padding (max-width 680px). Esc to exit. Respect `prefers-reduced-motion`.

- [ ] **Step 3: Build, run, test all shortcuts**

Expected: All shortcuts work. Focus mode provides distraction-free writing. Esc exits focus mode.

- [ ] **Step 4: Commit**

```bash
git add Canto/Canto/Views/
git commit -m "feat: add keyboard shortcuts and focus mode for distraction-free writing"
```

---

## Task 21: Git Integration for Sessions

**Files:**
- Modify: `Canto/Canto/Models/AppState.swift`
- Modify: `Canto/Canto/Services/SessionManager.swift`

- [ ] **Step 1: Add git polling timer to AppState**

When a session is active and the project has a `.git` directory, poll `GitService.recentCommits()` every 30 seconds. Feed new commits to `SessionManager.recordCommit()`.

- [ ] **Step 2: Update SessionManager to handle commit naming**

First commit in a session auto-names the session from the commit message.

- [ ] **Step 3: Build, run, make a commit while Canto is open**

Expected: Commit appears in session timeline within 30 seconds.

- [ ] **Step 4: Commit**

```bash
git add Canto/
git commit -m "feat: add git log polling for session commit tracking"
```

---

## Task 22: Accessibility Pass

**Files:**
- Modify: Multiple view files

- [ ] **Step 1: Add accessibility labels to all interactive elements**

Sidebar items, memory cards, tab buttons, command palette items, status bar elements. Use `.accessibilityLabel()` and `.accessibilityHint()`.

- [ ] **Step 2: Add keyboard navigation for sidebar**

Arrow keys to navigate, Enter to open, Tab to move between sidebar/content/status bar.

- [ ] **Step 3: Respect reduced motion**

Wrap all animations in `@Environment(\.accessibilityReduceMotion)` checks. When enabled: no pulse, no fade, instant transitions.

- [ ] **Step 4: Verify VoiceOver works**

Enable VoiceOver (Cmd+F5) and navigate the entire app.

- [ ] **Step 5: Commit**

```bash
git add Canto/
git commit -m "feat: add accessibility support (VoiceOver, keyboard nav, reduced motion)"
```

---

## Task 23: App Icon and Polish

**Files:**
- Modify: `Canto/Canto/Assets.xcassets/`
- Modify: Multiple view files for polish

- [ ] **Step 1: Create app icon**

Design a simple icon: violet circle with a subtle document/page symbol. Create all required sizes for macOS App Store (16, 32, 64, 128, 256, 512, 1024px).

- [ ] **Step 2: Polish transitions and animations**

Review all views. Ensure: 150ms fade on file switches, sidebar flash on new files, smooth crossfade between tabs. Remove any jarring transitions.

- [ ] **Step 3: Empty states**

Verify all empty states render correctly: no folder, no .md files, no .claude/, no memories, no sessions.

- [ ] **Step 4: Dark and light theme verification**

Toggle between themes. Verify all views look correct in both modes. Check color contrast.

- [ ] **Step 5: Commit**

```bash
git add Canto/
git commit -m "feat: add app icon and polish transitions, empty states, and theme consistency"
```

---

## Task 24: App Store Preparation

**Files:**
- Modify: `Canto/Canto/Info.plist`
- Modify: `Canto/Canto/Canto.entitlements`

- [ ] **Step 1: Configure Info.plist for App Store**

Set CFBundleIdentifier (`com.infinitelabs.canto`), version (1.0.0), build number, copyright, category (Productivity), minimum macOS version (14.0).

- [ ] **Step 2: Verify sandbox entitlements**

Confirm entitlements are minimal and correct for App Store review: app-sandbox, user-selected read-write, app-scope bookmarks.

- [ ] **Step 3: Archive and validate**

Product → Archive in Xcode. Validate the archive for App Store submission. Fix any issues.

- [ ] **Step 4: Prepare App Store listing**

Screenshots (5 required), description, keywords, category, pricing (free with IAP for Pro).

- [ ] **Step 5: Submit to App Store Connect**

Upload the archive. Fill in metadata. Submit for review.

- [ ] **Step 6: Commit**

```bash
git add Canto/
git commit -m "chore: prepare Canto v1.0.0 for App Store submission"
```

---

## Summary

| Task | Component | Estimated complexity |
|---|---|---|
| 1 | Xcode project setup | Low |
| 2 | Theme system | Low |
| 3 | Data models + tests | Medium |
| 4 | Settings persistence | Low |
| 5 | Markdown/Memory parsers + tests | Medium |
| 6 | File system services | Medium |
| 7 | Session manager + Git service | High |
| 8 | Config reader | Low |
| 9 | AppState orchestration | High |
| 10 | Milkdown editor bundle | High |
| 11 | WKWebView wrapper | Medium |
| 12 | Welcome screen | Low |
| 13 | Sidebar | Medium |
| 14 | Editor container + tabs | Medium |
| 15 | CLAUDE.md dashboard | Medium |
| 16 | Memory browser | Medium |
| 17 | Session timeline | Medium |
| 18 | Config panel | Low |
| 19 | Command palette | Medium |
| 20 | Keyboard shortcuts + focus mode | Low |
| 21 | Git integration | Low |
| 22 | Accessibility | Medium |
| 23 | App icon + polish | Medium |
| 24 | App Store prep | Medium |

**Critical path:** Tasks 1-3 → 4-6 → 7-9 → 10-11 → 12-14 → 15-18 → 19-24

Tasks within each group can be parallelized. The Milkdown bundle (Task 10) can be built in parallel with the native Swift services (Tasks 4-9).

---

## Review Fixes and Known Issues

The following issues were identified during plan review and MUST be addressed during implementation:

### Critical fixes (apply when implementing the referenced task)

**C1. FileWatcherService (Task 6 Step 3):** The FSEvents callback uses `Unmanaged.passUnretained(self)` which is unsafe — can cause use-after-free on rapid folder switches. Fix: use `DispatchSource.makeFileSystemObjectSource` instead of raw FSEvents, or use `Unmanaged.passRetained` with proper release in `stopWatching()`. Alternatively, use a separate context class with a weak reference to the watcher.

**C2. SessionEvent dual init (Task 3 Step 5 + Task 7 Step 3):** Two init methods with overlapping signatures. Fix: define a single init with ALL parameters, all optional except `type`, with `nil` defaults. Remove the dead `var event = SessionEvent(type: .commit)` line in `recordCommit`.

**C3. Milkdown API (Task 10 Step 5):** The listener plugin setup does NOT match Milkdown v7+ API. Fix: before implementing, fetch current Milkdown docs via Context7 MCP and verify the exact API. Also: create the `slash-menu.ts` file (referenced but never defined), remove unused `@prosemirror/view` import (should be `prosemirror-view` if needed at all).

**C4. WKWebView update loop (Task 11 Step 1):** `updateNSView` sends `loadFile` to JS on every SwiftUI update, creating an infinite loop (user types → JS sends contentChanged → Swift updates content → SwiftUI calls updateNSView → JS receives loadFile → cursor reset). Fix: track `lastSentContent` in the Coordinator. Only send `loadFile` when content changed from Swift side, not from a JS callback. Add a `isLocalChange` flag.

### Important fixes (apply when implementing)

**I1. FileTreeBuilder (Task 6 Step 2):** The recursive `updateNodeInTree` mutates copies of value-type FileNode structs, so children get lost in nested directories. Fix: build a flat `[String: FileNode]` dictionary first, then assemble the tree in a second pass by iterating from deepest to shallowest paths.

**I2. MemoryFile.isStale (Task 3 Step 6):** Hardcodes 14 days, but spec says configurable via `staleMemoryDays`. Fix: compute staleness in the view layer where Settings is accessible, not in the model. Change `isStale` to `func isStale(thresholdDays: Int) -> Bool`.

**I3. No .gitignore support (Task 6 Step 2):** `gitignorePatterns` parameter is accepted but never used. Fix: parse project `.gitignore` and apply patterns during `shouldSkip()`.

**I4. Tab limit silently closes tabs (Task 9):** Bad UX. Fix: show a notification or prevent opening with a message like "Tab limit reached. Close a tab or upgrade to Pro."

**I5. Security bookmark access (Task 4 + Task 9):** `resolveBookmark` in RecentFoldersManager returns a URL without calling `startAccessingSecurityScopedResource()`. Fix: call it before returning and provide user feedback when access fails.

**I6. Missing conflict debouncing (Task 9):** Spec requires 2-second quiet period before showing conflict dialog. Fix: add a debounce timer per file path. Also implement "File deleted while open" banner.

**I7. Missing Diff view in conflict banner (Task 14):** Spec has [Diff] button. Defer to v1.1 — note in UI "Diff view coming soon" or remove the button.

**I8. Plans folder missing from sidebar (Task 13):** Add a "Plans" DisclosureGroup in ClaudeSidebarSection, similar to Memory.

**I9. Sidebar hover tooltip missing (Task 13):** Add `.help()` or custom popover on hover for .md files showing first 3 lines.

### Minor fixes

- **M1.** Fix typo: `isBeingModifiedByClaud` → `isBeingModifiedByClaude` (Task 3 Step 2)
- **M2.** ClaudeMDParser empty guard logic: `guard trimmed.count >= 10 || !trimmed.isEmpty` is always true. Fix: `guard !trimmed.isEmpty else { return [] }`. Move the `< 10 chars → Quick Setup` logic to the dashboard view.
- **M3.** EditorContainerView creates throwaway FileNode for image detection. Extract `FileTypeDetector.detect(url:)` utility.
- **M4.** Missing `light.css` import in `index.ts`. Add `import './styles/light.css'`.
- **M5.** Git log parsing double-break issue in line parsing loop. Review and fix the break/continue logic.
- **M6.** `ClaudeMDSection` uses heading text as `id` — collision risk. Use `UUID().uuidString`.
- **M7.** Density modes not implemented in any view. Add padding conditionals based on `settings.densityMode`.
- **M8.** Reduced motion not checked in WelcomeView logo or sidebar animations.
- **M9.** Word count shows only in status bar. When status bar hidden, show in editor area bottom-right.
- **M10.** Export feature (Pro) has no task. Intentionally deferred — added to backlog.

### Missing spec features (implement during Tasks 10-11 or add new tasks)

- **Floating toolbar** on text selection (Milkdown plugin or custom)
- **Drag & drop block reordering** (Milkdown drag handle plugin)
- **Drag & drop images** to editor (handle in WKWebView drop events → copy to ./assets/)
- **Glass/blur effects** (add NSVisualEffectView to sidebar background)
- **Export** (defer to v1.1)
- **JSON/YAML syntax highlighting** for non-.md config files (use a lightweight syntax highlighter library)

### Updated parallelization

```
Start immediately:     Task 1 (project setup)
After Task 1:          Task 2 (theme) + Task 10 (Milkdown bundle) — in parallel
After Task 2:          Tasks 3-9 (models, services, AppState) — sequential
After Tasks 9 + 10:    Task 11 (WKWebView wrapper)
After Task 11:         Tasks 12-18 (views) — 12-14 sequential, 15-18 parallel
After Task 18:         Tasks 19-20 (palette, shortcuts)
After Task 20:         Tasks 21-24 (git, a11y, polish, App Store)
```

Task 22 (accessibility) should come BEFORE Task 23 (polish) since a11y can affect layout decisions.
