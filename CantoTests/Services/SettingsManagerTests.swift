import XCTest
@testable import Canto

final class SettingsTests: XCTestCase {
    func testDefaultSettings() {
        let settings = Settings()
        XCTAssertEqual(settings.theme, "dark")
        XCTAssertEqual(settings.fontSize, 16)
        XCTAssertEqual(settings.sessionIdleTimeout, 300)
        XCTAssertEqual(settings.version, 1)
    }

    func testSettingsEncodeDecode() throws {
        var settings = Settings()
        settings.theme = "light"
        settings.fontSize = 18
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(Settings.self, from: data)
        XCTAssertEqual(decoded.theme, "light")
        XCTAssertEqual(decoded.fontSize, 18)
    }
}
