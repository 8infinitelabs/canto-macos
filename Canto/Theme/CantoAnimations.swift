import SwiftUI

enum CantoAnimations {
    static let quick = Animation.easeInOut(duration: 0.15)
    static let standard = Animation.easeInOut(duration: 0.25)
    static let slow = Animation.easeInOut(duration: 0.4)

    static let sidebarAppear = Animation.easeOut(duration: 0.2)
    static let tabSwitch = Animation.easeInOut(duration: 0.15)

    static let pulse = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
}
