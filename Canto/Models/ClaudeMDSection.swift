import Foundation

struct ClaudeMDSection: Identifiable {
    let id: String // UUID to avoid collision
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
