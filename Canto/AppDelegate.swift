import AppKit

extension Notification.Name {
    static let cantoOpenFile = Notification.Name("CantoOpenFile")
    static let cantoSaveFile = Notification.Name("CantoSaveFile")
    static let cantoFindInFile = Notification.Name("CantoFindInFile")
    static let cantoNewFile = Notification.Name("CantoNewFile")
    static let cantoCloseTab = Notification.Name("CantoCloseTab")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        PendingFileOpener.shared = url
        NotificationCenter.default.post(name: .cantoOpenFile, object: url)
    }
}

@MainActor
enum PendingFileOpener {
    static var shared: URL?
}
