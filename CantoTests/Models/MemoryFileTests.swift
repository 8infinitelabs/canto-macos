import XCTest
@testable import Canto

final class MemoryFileTests: XCTestCase {
    func testStaleProjectMemory() {
        let old = MemoryFile(
            id: "test", url: URL(fileURLWithPath: "/test"),
            name: "old", description: "", type: .project,
            content: "", modifiedDate: Date().addingTimeInterval(-30 * 86400)
        )
        XCTAssertTrue(old.isStale)
    }

    func testFreshProjectMemoryNotStale() {
        let fresh = MemoryFile(
            id: "test", url: URL(fileURLWithPath: "/test"),
            name: "fresh", description: "", type: .project,
            content: "", modifiedDate: Date()
        )
        XCTAssertFalse(fresh.isStale)
    }

    func testUserMemoryNeverStale() {
        let old = MemoryFile(
            id: "test", url: URL(fileURLWithPath: "/test"),
            name: "old", description: "", type: .user,
            content: "", modifiedDate: Date().addingTimeInterval(-90 * 86400)
        )
        XCTAssertFalse(old.isStale)
    }
}
