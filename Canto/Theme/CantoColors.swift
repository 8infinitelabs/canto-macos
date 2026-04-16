import SwiftUI

enum CantoColors {
    // Backgrounds
    static let background = Color("Background") // #0A0A0F dark, #FAFAFA light
    static let surface = Color("Surface")         // #141419 dark, #FFFFFF light

    // Text
    static let textPrimary = Color("TextPrimary")     // #E4E4E7 dark, #18181B light
    static let textSecondary = Color("TextSecondary") // #71717A both

    // Accent
    static let accent = Color(hex: "#8B5CF6")       // Violet

    // Memory types
    static let memoryUser = Color(hex: "#3B82F6")      // Blue
    static let memoryFeedback = Color(hex: "#10B981")  // Green
    static let memoryProject = Color(hex: "#F59E0B")   // Amber
    static let memoryReference = Color(hex: "#EC4899") // Pink

    // Session states
    static let sessionIdle = Color(hex: "#71717A")
    static let sessionActive = Color(hex: "#8B5CF6")
    static let sessionDone = Color(hex: "#10B981")
    static let sessionError = Color(hex: "#EF4444")

    static func forMemoryType(_ type: String) -> Color {
        switch type {
        case "user": return memoryUser
        case "feedback": return memoryFeedback
        case "project": return memoryProject
        case "reference": return memoryReference
        default: return sessionIdle
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
