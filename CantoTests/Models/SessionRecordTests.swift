import XCTest
@testable import Canto

final class SessionRecordTests: XCTestCase {
    func testCreateSession() {
        let session = SessionRecord.create(projectPath: "/test/path")
        XCTAssertEqual(session.status, .active)
        XCTAssertEqual(session.events.count, 1)
        XCTAssertEqual(session.events[0].type, .sessionStart)
        XCTAssertEqual(session.projectPath, "/test/path")
    }

    func testSessionEncodeDecode() throws {
        let session = SessionRecord.create(projectPath: "/test")
        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(SessionRecord.self, from: data)
        XCTAssertEqual(decoded.id, session.id)
        XCTAssertEqual(decoded.projectPath, session.projectPath)
    }
}
