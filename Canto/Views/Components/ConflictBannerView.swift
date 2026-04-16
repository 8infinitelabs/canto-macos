import SwiftUI

struct ConflictBannerView: View {
    @Environment(AppState.self) private var appState
    let tab: TabItem

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(CantoColors.memoryProject)
            Text("\(tab.name) was modified externally")
                .font(CantoTypography.ui)

            Spacer()

            Button("Accept external") {
                if let content = try? MarkdownFileService.read(url: tab.url) {
                    tab.content = content
                    tab.isDirty = false
                    tab.isExternallyModified = false
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button("Keep mine") {
                tab.isExternallyModified = false
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(CantoColors.memoryProject.opacity(0.1))
    }
}
