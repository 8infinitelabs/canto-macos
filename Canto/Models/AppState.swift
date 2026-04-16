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

        fileTree = FileTreeBuilder.build(from: url)

        isClaudeProject = FileManager.default.fileExists(
            atPath: url.appendingPathComponent(".claude").path
        )

        if isClaudeProject {
            loadClaudeData(projectURL: url)
        }

        fileWatcher.onChange = { [weak self] path, flags in
            self?.handleFileChange(path: path, flags: flags)
        }
        fileWatcher.startWatching(path: url.path)

        sessionManager = SessionManager(
            projectPath: url.path,
            idleTimeout: TimeInterval(settings.sessionIdleTimeout),
            groupingWindow: TimeInterval(settings.sessionGroupingWindow)
        )

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
        if let existing = tabs.first(where: { $0.id == node.id }) {
            activeTabID = existing.id
            return
        }

        let maxTabs = 3 // TODO: Check pro status
        if tabs.count >= maxTabs {
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

        fileTree = FileTreeBuilder.build(from: folderURL)

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
