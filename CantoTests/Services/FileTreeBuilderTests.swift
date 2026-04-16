import XCTest
@testable import Canto

final class FileTreeBuilderTests: XCTestCase {
    var tempDir: URL!

    override func setUp() {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testCLAUDEmdFirstInSort() throws {
        try "# README".write(to: tempDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        try "# Claude".write(to: tempDir.appendingPathComponent("CLAUDE.md"), atomically: true, encoding: .utf8)

        let tree = FileTreeBuilder.build(from: tempDir)
        XCTAssertEqual(tree.first?.name, "CLAUDE.md")
    }

    func testMarkdownFilesDetected() throws {
        try "test".write(to: tempDir.appendingPathComponent("doc.md"), atomically: true, encoding: .utf8)
        try "test".write(to: tempDir.appendingPathComponent("code.ts"), atomically: true, encoding: .utf8)

        let tree = FileTreeBuilder.build(from: tempDir)
        let mdFiles = tree.filter { $0.isMarkdown }
        XCTAssertEqual(mdFiles.count, 1)
    }
}
