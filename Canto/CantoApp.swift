import SwiftUI

@main
struct CantoApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environment(appState)
        }
        .defaultSize(width: 1200, height: 800)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    appState.saveActiveTab()
                }
                .keyboardShortcut("s", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("Open Folder...") {
                    if let url = FolderAccessService.openFolderPanel() {
                        appState.openFolder(url)
                    }
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandGroup(replacing: .toolbar) {
                Button("Close Tab") {
                    if let id = appState.activeTabID {
                        appState.closeTab(id)
                    }
                }
                .keyboardShortcut("w", modifiers: .command)
            }
        }
    }
}
