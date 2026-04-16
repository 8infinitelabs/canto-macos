import XCTest
@testable import Canto

final class MemoryParserTests: XCTestCase {
    func testParseValidMemory() throws {
        let content = """
        ---
        name: user_role
        description: Diego is a solopreneur
        type: user
        ---

        Senior developer based in Barcelona.
        """
        let url = URL(fileURLWithPath: "/test/user_role.md")
        let memory = try MemoryParser.parse(content: content, url: url, modifiedDate: Date())
        XCTAssertEqual(memory.name, "user_role")
        XCTAssertEqual(memory.type, .user)
        XCTAssertTrue(memory.content.contains("Senior developer"))
    }

    func testParseUnknownType() throws {
        let content = """
        ---
        name: test
        description: test
        type: something_new
        ---

        Content.
        """
        let url = URL(fileURLWithPath: "/test/test.md")
        let memory = try MemoryParser.parse(content: content, url: url, modifiedDate: Date())
        XCTAssertEqual(memory.type, .unknown)
    }

    func testParseNoFrontmatter() {
        let content = "Just plain content without frontmatter."
        let url = URL(fileURLWithPath: "/test/plain.md")
        XCTAssertThrowsError(try MemoryParser.parse(content: content, url: url, modifiedDate: Date()))
    }
}
