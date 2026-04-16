import SwiftUI

struct MainWindowView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.hasOpenFolder {
                NavigationSplitView {
                    Text("Sidebar placeholder")
                } detail: {
                    Text("Editor placeholder")
                }
            } else {
                WelcomeView()
            }
        }
        .preferredColorScheme(appState.settings.theme == "dark" ? .dark : .light)
        .onOpenURL { url in
            if url.hasDirectoryPath {
                appState.openFolder(url)
            }
        }
    }
}
