import XCTest
@testable import Canto

final class ClaudeMDParserTests: XCTestCase {
    func testParseWithHeadingsAndRules() {
        let md = """
        ## Instructions

        Use Next.js 16 with App Router. Always use TypeScript.

        ## Rules

        - Use pnpm as package manager
        - No mocks in integration tests
        - Always run ESLint before commit
        """
        let sections = ClaudeMDParser.parse(md)
        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].heading, "Instructions")
        XCTAssertTrue(sections[0].prose.contains("Next.js 16"))
        XCTAssertEqual(sections[0].rules.count, 0)
        XCTAssertEqual(sections[1].heading, "Rules")
        XCTAssertEqual(sections[1].rules.count, 3)
        XCTAssertEqual(sections[1].rules[0].text, "Use pnpm as package manager")
    }

    func testParseWithNoHeadings() {
        let md = "Just some plain text instructions for Claude."
        let sections = ClaudeMDParser.parse(md)
        XCTAssertEqual(sections.count, 1)
        XCTAssertNil(sections[0].heading)
        XCTAssertTrue(sections[0].prose.contains("plain text"))
    }

    func testParseEmptyFile() {
        let sections = ClaudeMDParser.parse("")
        XCTAssertEqual(sections.count, 0)
    }

    func testParseMixedContent() {
        let md = """
        ## Stack

        React 19, Tailwind v4

        - Supabase for database
        - Vercel for deploy
        """
        let sections = ClaudeMDParser.parse(md)
        XCTAssertEqual(sections.count, 1)
        XCTAssertTrue(sections[0].prose.contains("React 19"))
        XCTAssertEqual(sections[0].rules.count, 2)
    }

    func testRoundTrip() {
        let original = """
        ## Rules

        - Rule one
        - Rule two
        """
        let sections = ClaudeMDParser.parse(original)
        let reconstructed = ClaudeMDParser.toMarkdown(sections)
        let reparsed = ClaudeMDParser.parse(reconstructed)
        XCTAssertEqual(reparsed.count, sections.count)
        XCTAssertEqual(reparsed[0].rules.count, sections[0].rules.count)
    }
}
