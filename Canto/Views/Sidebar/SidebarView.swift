import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        List {
            if appState.isClaudeProject {
                ClaudeSidebarSection()
            }

            FileTreeSection()

            if appState.isSessionActive {
                SessionSidebarSection()
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
    }
}
