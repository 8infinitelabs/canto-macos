import Foundation

enum MarkdownFileService {
    static func read(url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    static func write(url: URL, content: String) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    static func createNew(in directory: URL, name: String) throws -> URL {
        let fileName = name.hasSuffix(".md") ? name : "\(name).md"
        let url = directory.appendingPathComponent(fileName)
        try "# \(name.replacingOccurrences(of: ".md", with: ""))\n\n".write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
