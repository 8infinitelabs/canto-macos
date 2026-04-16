import SwiftUI

enum CantoTypography {
    static let displayLarge = Font.system(size: 28, weight: .bold, design: .default)
    static let displayMedium = Font.system(size: 22, weight: .bold, design: .default)
    static let displaySmall = Font.system(size: 18, weight: .semibold, design: .default)

    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)

    static let code = Font.system(size: 14, weight: .regular, design: .monospaced)
    static let codeSmall = Font.system(size: 12, weight: .regular, design: .monospaced)

    static let ui = Font.system(size: 13, weight: .regular, design: .default)
    static let uiSmall = Font.system(size: 11, weight: .regular, design: .default)

    static let sidebar = Font.system(size: 13, weight: .regular, design: .default)
    static let sidebarBold = Font.system(size: 13, weight: .semibold, design: .default)
}
