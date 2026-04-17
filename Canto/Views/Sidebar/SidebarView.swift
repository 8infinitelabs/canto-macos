import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            // Session indicator at the top
            if appState.isClaudeProject {
                HStack {
                    ClaudeActivityIndicator()
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                Divider()
            }

            List {
                if appState.isClaudeProject {
                    ClaudeSidebarSection()
                }

                FileTreeSection()
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 220)
    }
}
