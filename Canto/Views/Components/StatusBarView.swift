import SwiftUI

struct StatusBarView: View {
    @Environment(AppState.self) private var appState
    let wordCount: Int
    let readingTime: Int

    var body: some View {
        HStack {
            if let session = appState.sessionManager?.currentSession, appState.isSessionActive {
                HStack(spacing: 6) {
                    Circle()
                        .fill(CantoColors.sessionActive)
                        .frame(width: 6, height: 6)
                    Text("Session: \(session.name)")
                        .font(CantoTypography.uiSmall)
                    Text("\(session.stats.filesCreated + session.stats.filesModified) files")
                        .font(CantoTypography.uiSmall)
                    Text(session.startedAt, style: .relative)
                        .font(CantoTypography.uiSmall)
                }
                .foregroundStyle(CantoColors.textSecondary)
            }

            Spacer()

            if wordCount > 0 && appState.settings.showWordCount {
                Text("\(wordCount) words · \(readingTime) min read")
                    .font(CantoTypography.uiSmall)
                    .foregroundStyle(CantoColors.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(CantoColors.surface)
    }
}
