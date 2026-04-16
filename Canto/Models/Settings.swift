import Foundation

struct Settings: Codable {
    var version: Int = 1
    var theme: String = "dark"
    var densityMode: String = "comfortable"
    var fontSize: Int = 16
    var fontFamily: String = "system"
    var sidebarWidth: Double = 260
    var sidebarCollapsed: Bool = false
    var showWordCount: Bool = true
    var sessionIdleTimeout: Int = 300
    var sessionGroupingWindow: Int = 30
    var staleMemoryDays: Int = 14
}
