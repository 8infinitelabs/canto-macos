import SwiftUI

@main
struct CantoApp: App {
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        // Welcome window (no project yet)
        WindowGroup("Canto", id: "welcome") {
            WindowRootView(folderURL: nil)
        }
        .defaultSize(width: 900, height: 700)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))

        // Project window — one per folder URL
        WindowGroup("Canto — Project", id: "project", for: URL.self) { $folderURL in
            WindowRootView(folderURL: folderURL)
        }
        .defaultSize(width: 1200, height: 800)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open Project…") {
                    if let url = FolderAccessService.openFolderPanel() {
                        openWindow(id: "project", value: url)
                    }
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Open in New Window…") {
                    if let url = FolderAccessService.openFolderPanel() {
                        openWindow(id: "project", value: url)
                    }
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }
        }
    }
}

/// Root view for each window — owns its own AppState.
struct WindowRootView: View {
    let folderURL: URL?
    @State private var appState = AppState()
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        MainWindowView()
            .environment(appState)
            .onAppear {
                if let url = folderURL, !appState.hasOpenFolder {
                    appState.openFolder(url)
                }
            }
    }
}
