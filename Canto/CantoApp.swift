import SwiftUI

@main
struct CantoApp: App {
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup("Canto", id: "main", for: URL.self) { $incomingURL in
            WindowRootView(openURL: incomingURL)
        }
        .defaultSize(width: 1200, height: 800)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open Project…") {
                    if let url = FolderAccessService.openFolderPanel() {
                        openWindow(id: "main", value: url)
                    }
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Open in New Window…") {
                    if let url = FolderAccessService.openFolderPanel() {
                        openWindow(id: "main", value: url)
                    }
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }

            CommandGroup(after: .saveItem) {
                Button("Save") {
                    NotificationCenter.default.post(name: .cantoSaveFile, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
            }

            CommandGroup(after: .textEditing) {
                Button("New File") {
                    NotificationCenter.default.post(name: .cantoNewFile, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Close Tab") {
                    NotificationCenter.default.post(name: .cantoCloseTab, object: nil)
                }
                .keyboardShortcut("w", modifiers: .command)

                Button("Find…") {
                    NotificationCenter.default.post(name: .cantoFindInFile, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }
    }
}

struct WindowRootView: View {
    let openURL: URL?
    @State private var appState = AppState()

    var body: some View {
        MainWindowView()
            .environment(appState)
            .onAppear {
                guard let url = openURL, !appState.hasOpenFolder else { return }
                if url.hasDirectoryPath {
                    appState.openFolder(url)
                } else if ["md", "markdown"].contains(url.pathExtension.lowercased()) {
                    appState.openFolder(url.deletingLastPathComponent())
                    let node = FileNode(
                        id: url.lastPathComponent,
                        name: url.lastPathComponent,
                        url: url,
                        isDirectory: false,
                        children: nil,
                        fileExtension: "md"
                    )
                    appState.openFile(node)
                }
            }
    }
}
