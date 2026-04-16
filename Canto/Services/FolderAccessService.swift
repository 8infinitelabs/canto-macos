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
