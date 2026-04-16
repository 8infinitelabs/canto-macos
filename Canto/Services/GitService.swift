import Foundation

struct GitCommit: Identifiable {
    let id: String
    let hash: String
    let message: String
    let date: Date
    let filesChanged: Int
    let insertions: Int
    let deletions: Int
}

enum GitService {
    static func isGitRepo(at path: URL) -> Bool {
        FileManager.default.fileExists(atPath: path.appendingPathComponent(".git").path)
    }

    static func recentCommits(at path: URL, since: Date? = nil, limit: Int = 10) -> [GitCommit] {
        var args = ["log", "--format=%H|%s|%aI", "--shortstat", "-n", "\(limit)"]
        if let since {
            let formatter = ISO8601DateFormatter()
            args.append("--since=\(formatter.string(from: since))")
        }

        guard let output = runGit(args: args, at: path) else { return [] }
        return parseGitLog(output)
    }

    private static func runGit(args: [String], at path: URL) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = args
        process.currentDirectoryURL = path

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    private static func parseGitLog(_ output: String) -> [GitCommit] {
        var commits: [GitCommit] = []
        let lines = output.components(separatedBy: .newlines)
        var i = 0

        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { i += 1; continue }

            let parts = line.components(separatedBy: "|")
            guard parts.count >= 3 else { i += 1; continue }

            let hash = parts[0]
            let message = parts[1]
            let dateStr = parts[2]

            let formatter = ISO8601DateFormatter()
            let date = formatter.date(from: dateStr) ?? Date()

            var filesChanged = 0, insertions = 0, deletions = 0
            i += 1
            while i < lines.count {
                let statLine = lines[i].trimmingCharacters(in: .whitespaces)
                if statLine.isEmpty { i += 1; continue }
                if statLine.contains("file") {
                    if let fc = statLine.range(of: #"(\d+) file"#, options: .regularExpression) {
                        filesChanged = Int(statLine[fc].components(separatedBy: " ")[0]) ?? 0
                    }
                    if let ins = statLine.range(of: #"(\d+) insertion"#, options: .regularExpression) {
                        insertions = Int(statLine[ins].components(separatedBy: " ")[0]) ?? 0
                    }
                    if let del = statLine.range(of: #"(\d+) deletion"#, options: .regularExpression) {
                        deletions = Int(statLine[del].components(separatedBy: " ")[0]) ?? 0
                    }
                    i += 1
                    break
                }
                i += 1
                break
            }

            commits.append(GitCommit(
                id: hash, hash: hash, message: message, date: date,
                filesChanged: filesChanged, insertions: insertions, deletions: deletions
            ))
        }

        return commits
    }
}
