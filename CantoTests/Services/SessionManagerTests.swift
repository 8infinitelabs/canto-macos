import XCTest
@testable import Canto

final class SessionManagerTests: XCTestCase {
    func testStartsIdle() {
        let manager = SessionManager(projectPath: "/test", idleTimeout: 5, groupingWindow: 2)
        XCTAssertEqual(manager.state, .idle)
        XCTAssertNil(manager.currentSession)
    }

    func testSingleEventDoesNotStartSession() {
        let manager = SessionManager(projectPath: "/test", idleTimeout: 5, groupingWindow: 2)
        manager.recordFileEvent(path: "file.md", type: .fileModified)
        XCTAssertEqual(manager.state, .idle)
    }

    func testThreeEventsStartSession() {
        let manager = SessionManager(projectPath: "/test", idleTimeout: 5, groupingWindow: 30)
        manager.recordFileEvent(path: "a.md", type: .fileModified)
        manager.recordFileEvent(path: "b.md", type: .fileModified)
        manager.recordFileEvent(path: "c.md", type: .fileCreated)
        XCTAssertEqual(manager.state, .active)
        XCTAssertNotNil(manager.currentSession)
    }

    func testSessionAutoNameFromFile() {
        let manager = SessionManager(projectPath: "/test", idleTimeout: 5, groupingWindow: 30)
        manager.recordFileEvent(path: "auth.md", type: .fileCreated)
        manager.recordFileEvent(path: "auth.ts", type: .fileCreated)
        manager.recordFileEvent(path: "types.ts", type: .fileCreated)
        XCTAssertEqual(manager.currentSession?.name, "auth.md")
    }
}
