import XCTest
@testable import Canto

final class GitServiceTests: XCTestCase {
    func testDetectsGitRepo() {
        // The canto project itself is a git repo
        let cantoRoot = URL(fileURLWithPath: "/Users/diego/dev/canto")
        XCTAssertTrue(GitService.isGitRepo(at: cantoRoot))
    }

    func testNonGitRepo() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        XCTAssertFalse(GitService.isGitRepo(at: tempDir))
    }

    func testRecentCommitsFromCanto() {
        let cantoRoot = URL(fileURLWithPath: "/Users/diego/dev/canto")
        let commits = GitService.recentCommits(at: cantoRoot, limit: 3)
        XCTAssertFalse(commits.isEmpty)
        XCTAssertTrue(commits[0].message.contains("feat:"))
    }
}
