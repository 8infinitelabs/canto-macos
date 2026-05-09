import SwiftUI

enum ActiveView: Equatable {
    case editor
    case memoryBrowser
    case plansBrowser
    case sessionTimeline
    case configPanel
    case dashboard
}

@Observable
@MainActor
class AppState {
    // Folder state
    var openFolderURL: URL?
    var fileTree: [FileNode] = []
    var isClaudeProject: Bool = false

    // View routing
    var activeView: ActiveView = .editor

    // Tabs
    var tabs: [TabItem] = []
    var activeTabID: String?
    var activeTab: TabItem? { tabs.first { $0.id == activeTabID } }

    // Services
    let settingsManager = SettingsManager()
    let recentFolders = RecentFoldersManager()
    let fileWatcher = FileWatcherService()
    var sessionManager: SessionManager?
    private var gitPollTimer: Timer?
    private var lastKnownCommitHash: String?
    private var fileTreeRebuildTask: Task<Void, Never>?

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
        _ = FolderAccessService.startAccessing(url: url)

        // Show the project UI immediately — heavy work runs in background
        openFolderURL = url
        recentFolders.addFolder(url: url)

        fileWatcher.onChange = { [weak self] path, flags in
            self?.handleFileChange(path: path, flags: flags)
        }
        fileWatcher.startWatching(path: url.path)

        sessionManager = SessionManager(
            projectPath: url.path,
            idleTimeout: TimeInterval(settings.sessionIdleTimeout),
            groupingWindow: TimeInterval(settings.sessionGroupingWindow)
        )

        // Scan file tree + Claude data on a background thread
        Task.detached(priority: .userInitiated) { [weak self] in
            let tree = FileTreeBuilder.build(from: url, mode: .markdownOnly)
            let isClaude = FileManager.default.fileExists(
                atPath: url.appendingPathComponent(".claude").path
            )
            // Load all Claude data off the main actor
            var sections: [ClaudeMDSection] = []
            var memories: [MemoryFile] = []
            var servers: [MCPServerConfig] = []
            var perms: [PermissionConfig] = []
            var hooks: [HookConfig] = []
            if isClaude {
                let claudeMDPath = url.appendingPathComponent("CLAUDE.md")
                if let content = try? String(contentsOf: claudeMDPath, encoding: .utf8) {
                    sections = ClaudeMDParser.parse(content)
                }
                memories = Self.loadMemoriesSync(from: url.appendingPathComponent(".claude/memory"))
                let projectSettings = url.appendingPathComponent(".claude/settings.json")
                let globalSettings = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent(".claude/settings.json")
                let config = ConfigReader.readClaudeSettings(
                    globalPath: globalSettings,
                    projectPath: projectSettings
                )
                servers = config.servers
                perms = config.permissions
                hooks = config.hooks
            }
            await MainActor.run { [weak self] in
                guard let self, self.openFolderURL == url else { return }
                self.fileTree = tree
                self.isClaudeProject = isClaude
                self.claudeMDSections = sections
                self.memories = memories
                self.mcpServers = servers
                self.permissions = perms
                self.hooks = hooks
            }
        }

        // Git check in background
        Task.detached(priority: .background) { [weak self] in
            guard GitService.isGitRepo(at: url) else { return }
            let commits = GitService.recentCommits(at: url, limit: 1)
            await MainActor.run { [weak self] in
                guard let self, self.openFolderURL == url else { return }
                self.lastKnownCommitHash = commits.first?.hash
                self.startGitPolling(url: url)
            }
        }
    }

    func closeFolderIfNeeded() {
        gitPollTimer?.invalidate()
        gitPollTimer = nil
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
        print("[Canto] openFile: \(node.name) at \(node.url.path)")
        activeView = node.isClaudeMD ? .dashboard : .editor
        if let existing = tabs.first(where: { $0.id == node.id }) {
            activeTabID = existing.id
            print("[Canto] tab already open, switching")
            return
        }

        let maxTabs = 3 // TODO: Check pro status
        if tabs.count >= maxTabs {
            if let closable = tabs.first(where: { !$0.isDirty && $0.id != activeTabID }) {
                tabs.removeAll { $0.id == closable.id }
            }
        }

        guard let content = try? MarkdownFileService.read(url: node.url) else {
            print("[Canto] ERROR: failed to read file \(node.url.path)")
            return
        }
        print("[Canto] file read OK, \(content.count) chars")
        let tab = TabItem(url: node.url, content: content)
        tabs.append(tab)
        activeTabID = tab.id
        print("[Canto] tab created, activeTabID=\(tab.id)")
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
        let claudeMDPath = projectURL.appendingPathComponent("CLAUDE.md")
        if let content = try? String(contentsOf: claudeMDPath, encoding: .utf8) {
            claudeMDSections = ClaudeMDParser.parse(content)
        }

        let memoryDir = projectURL.appendingPathComponent(".claude/memory")
        loadMemories(from: memoryDir)

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

    func createNewFile(name: String = "untitled", in directory: URL? = nil) {
        guard let rootURL = openFolderURL else { return }
        let targetDir = directory ?? rootURL
        do {
            let fileURL = try MarkdownFileService.createNew(in: targetDir, name: name)
            fileTree = FileTreeBuilder.build(from: rootURL, mode: .markdownOnly)
            let node = FileNode(
                id: fileURL.lastPathComponent,
                name: fileURL.lastPathComponent,
                url: fileURL,
                isDirectory: false,
                children: nil,
                fileExtension: "md"
            )
            openFile(node)
        } catch {
            print("[Canto] Failed to create file: \(error)")
        }
    }

    func reloadMemories() {
        guard let folderURL = openFolderURL else { return }
        loadMemories(from: folderURL.appendingPathComponent(".claude/memory"))
    }

    func reloadPlans() {
        guard let folderURL = openFolderURL else { return }
        fileTree = FileTreeBuilder.build(from: folderURL, mode: .markdownOnly)
    }

    private func loadMemories(from directory: URL) {
        memories = Self.loadMemoriesSync(from: directory)
    }

    private nonisolated static func loadMemoriesSync(from directory: URL) -> [MemoryFile] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey])
            .filter({ $0.pathExtension == "md" })
        else { return [] }

        return files.compactMap { url in
            guard let content = try? String(contentsOf: url, encoding: .utf8),
                  let attrs = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
                  let modDate = attrs.contentModificationDate
            else { return nil }
            return try? MemoryParser.parse(content: content, url: url, modifiedDate: modDate)
        }
    }

    // MARK: - Git polling

    private func startGitPolling(url: URL) {
        gitPollTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkForNewCommits(at: url)
        }
    }

    private func checkForNewCommits(at url: URL) {
        let commits = GitService.recentCommits(at: url, limit: 5)
        for commit in commits {
            if commit.hash == lastKnownCommitHash { break }
            sessionManager?.recordCommit(
                hash: commit.hash,
                message: commit.message,
                filesChanged: commit.filesChanged,
                insertions: commit.insertions,
                deletions: commit.deletions
            )
        }
        lastKnownCommitHash = commits.first?.hash
    }

    // MARK: - File watcher handling

    private func handleFileChange(path: String, flags: FSEventStreamEventFlags) {
        guard let folderURL = openFolderURL else { return }

        // Debounce file tree rebuild — coalesce rapid FS events into one rebuild
        fileTreeRebuildTask?.cancel()
        fileTreeRebuildTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled, self.openFolderURL == folderURL else { return }
            self.fileTree = FileTreeBuilder.build(from: folderURL, mode: .markdownOnly)
        }

        let relativePath = path.replacingOccurrences(of: folderURL.path + "/", with: "")
        let url = URL(fileURLWithPath: path)

        let isCreated = flags & UInt32(kFSEventStreamEventFlagItemCreated) != 0
        let isRemoved = flags & UInt32(kFSEventStreamEventFlagItemRemoved) != 0
        let isModified = flags & UInt32(kFSEventStreamEventFlagItemModified) != 0

        let eventType: SessionEvent.EventType
        if isCreated {
            eventType = relativePath.contains(".claude/memory/") ? .memoryCreated : .fileCreated
        } else if isRemoved {
            eventType = .fileDeleted
        } else {
            eventType = relativePath.contains(".claude/memory/") ? .memoryUpdated : .fileModified
        }

        sessionManager?.recordFileEvent(path: relativePath, type: eventType)

        if let tab = tabs.first(where: { $0.url.path == path }) {
            if isModified && !tab.isDirty {
                if let newContent = try? String(contentsOf: url, encoding: .utf8) {
                    tab.content = newContent
                }
            } else if isModified && tab.isDirty {
                tab.isExternallyModified = true
            } else if isRemoved {
                tab.isExternallyModified = true
            }
        }

        if relativePath == "CLAUDE.md" || relativePath.hasPrefix(".claude/") {
            loadClaudeData(projectURL: folderURL)
        }
    }
}
