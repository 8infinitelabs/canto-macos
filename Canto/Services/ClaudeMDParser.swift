import Foundation

enum ClaudeMDParser {
    static func parse(_ markdown: String) -> [ClaudeMDSection] {
        let trimmed = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var sections: [ClaudeMDSection] = []
        var currentHeading: String? = nil
        var currentLevel: Int = 0
        var currentProse: [String] = []
        var currentRules: [ClaudeMDSection.RuleItem] = []

        func flushSection() {
            let prose = currentProse.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if currentHeading != nil || !prose.isEmpty || !currentRules.isEmpty {
                sections.append(ClaudeMDSection(
                    id: currentHeading ?? "root",
                    heading: currentHeading,
                    headingLevel: currentLevel,
                    rules: currentRules,
                    prose: prose
                ))
            }
            currentProse = []
            currentRules = []
        }

        for line in markdown.components(separatedBy: .newlines) {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if trimmedLine.range(of: #"^(#{1,6})\s+(.+)$"#, options: .regularExpression) != nil {
                flushSection()
                let hashes = trimmedLine.prefix(while: { $0 == "#" })
                currentLevel = hashes.count
                currentHeading = String(trimmedLine.dropFirst(currentLevel).trimmingCharacters(in: .whitespaces))
            } else if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") {
                let text = String(trimmedLine.dropFirst(2))
                currentRules.append(ClaudeMDSection.RuleItem(text: text))
            } else {
                currentProse.append(line)
            }
        }

        flushSection()
        return sections
    }

    static func toMarkdown(_ sections: [ClaudeMDSection]) -> String {
        var lines: [String] = []
        for section in sections {
            if let heading = section.heading {
                let hashes = String(repeating: "#", count: max(section.headingLevel, 2))
                lines.append("\(hashes) \(heading)")
                lines.append("")
            }
            if !section.prose.isEmpty {
                lines.append(section.prose)
                lines.append("")
            }
            for rule in section.rules {
                lines.append("- \(rule.text)")
            }
            if !section.rules.isEmpty {
                lines.append("")
            }
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .newlines) + "\n"
    }
}
