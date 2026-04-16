import XCTest
@testable import Canto

final class CantoTests: XCTestCase {
    func testAppStateInitialValues() {
        let state = AppState()
        XCTAssertNil(state.openFolderURL)
        XCTAssertFalse(state.isClaudeProject)
        XCTAssertFalse(state.hasOpenFolder)
    }
}
