import Foundation

enum MemoryParserError: Error {
    case noFrontmatter
    case invalidFrontmatter
}

enum MemoryParser {
    static func parse(content: String, url: URL, modifiedDate: Date) throws -> MemoryFile {
        let parts = content.components(separatedBy: "---")
        guard parts.count >= 3 else { throw MemoryParserError.noFrontmatter }

        let frontmatter = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let body = parts.dropFirst(2).joined(separator: "---").trimmingCharacters(in: .whitespacesAndNewlines)

        var name = url.deletingPathExtension().lastPathComponent
        var description = ""
        var typeString = "unknown"

        for line in frontmatter.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("name:") {
                name = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("description:") {
                description = String(trimmed.dropFirst(12)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("type:") {
                typeString = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            }
        }

        let type = MemoryFile.MemoryType(rawValue: typeString) ?? .unknown

        return MemoryFile(
            id: url.lastPathComponent,
            url: url,
            name: name,
            description: description,
            type: type,
            content: body,
            modifiedDate: modifiedDate
        )
    }
}
