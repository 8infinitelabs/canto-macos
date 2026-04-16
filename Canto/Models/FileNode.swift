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
