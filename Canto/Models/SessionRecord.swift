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
