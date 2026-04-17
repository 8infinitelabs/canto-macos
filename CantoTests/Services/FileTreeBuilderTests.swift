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

    func testMarkdownOnlyModeFiltersNonMarkdown() throws {
        try "md".write(to: tempDir.appendingPathComponent("doc.md"), atomically: true, encoding: .utf8)
        try "ts".write(to: tempDir.appendingPathComponent("code.ts"), atomically: true, encoding: .utf8)
        try "json".write(to: tempDir.appendingPathComponent("config.json"), atomically: true, encoding: .utf8)

        let tree = FileTreeBuilder.build(from: tempDir, mode: .markdownOnly)
        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(tree[0].name, "doc.md")
    }

    func testMarkdownOnlyModeKeepsDirectoriesWithMarkdownChildren() throws {
        let docsDir = tempDir.appendingPathComponent("docs")
        try FileManager.default.createDirectory(at: docsDir, withIntermediateDirectories: true)
        try "md".write(to: docsDir.appendingPathComponent("spec.md"), atomically: true, encoding: .utf8)
        try "code".write(to: docsDir.appendingPathComponent("helper.ts"), atomically: true, encoding: .utf8)

        let tree = FileTreeBuilder.build(from: tempDir, mode: .markdownOnly)
        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(tree[0].name, "docs")
        XCTAssertEqual(tree[0].children?.count, 1)
        XCTAssertEqual(tree[0].children?.first?.name, "spec.md")
    }

    func testMarkdownOnlyModeDropsEmptyDirectories() throws {
        let srcDir = tempDir.appendingPathComponent("src")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        try "code".write(to: srcDir.appendingPathComponent("main.ts"), atomically: true, encoding: .utf8)

        let tree = FileTreeBuilder.build(from: tempDir, mode: .markdownOnly)
        XCTAssertTrue(tree.isEmpty)
    }
}
