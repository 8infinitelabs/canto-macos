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

    func isStale(thresholdDays: Int = 14) -> Bool {
        guard type == .project else { return false }
        let daysOld = Calendar.current.dateComponents([.day], from: modifiedDate, to: Date()).day ?? 0
        return daysOld > thresholdDays
    }

    static func == (lhs: MemoryFile, rhs: MemoryFile) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
