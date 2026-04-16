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
}
