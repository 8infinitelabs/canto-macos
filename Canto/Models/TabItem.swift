import Foundation

@Observable
class TabItem: Identifiable, Hashable {
    let id: String
    let url: URL
    let name: String
    var content: String
    var isDirty: Bool = false
    var isExternallyModified: Bool = false
    var isBeingModifiedByClaude: Bool = false

    init(url: URL, content: String) {
        self.id = url.path
        self.url = url
        self.name = url.lastPathComponent
        self.content = content
    }

    static func == (lhs: TabItem, rhs: TabItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
