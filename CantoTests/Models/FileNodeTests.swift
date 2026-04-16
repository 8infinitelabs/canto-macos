import XCTest
@testable import Canto

final class FileNodeTests: XCTestCase {
    func testIsMarkdown() {
        let node = FileNode(id: "README.md", name: "README.md", url: URL(fileURLWithPath: "/README.md"),
                           isDirectory: false, children: nil, fileExtension: "md")
        XCTAssertTrue(node.isMarkdown)
        XCTAssertFalse(node.isImage)
        XCTAssertFalse(node.isCode)
    }

    func testIsClaudeMD() {
        let node = FileNode(id: "CLAUDE.md", name: "CLAUDE.md", url: URL(fileURLWithPath: "/CLAUDE.md"),
                           isDirectory: false, children: nil, fileExtension: "md")
        XCTAssertTrue(node.isClaudeMD)
    }

    func testHasMarkdownChildren() {
        let child = FileNode(id: "docs/spec.md", name: "spec.md", url: URL(fileURLWithPath: "/docs/spec.md"),
                            isDirectory: false, children: nil, fileExtension: "md")
        let parent = FileNode(id: "docs", name: "docs", url: URL(fileURLWithPath: "/docs"),
                             isDirectory: true, children: [child], fileExtension: nil)
        XCTAssertTrue(parent.hasMarkdownChildren)
    }
}
