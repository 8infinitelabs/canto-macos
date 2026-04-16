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
