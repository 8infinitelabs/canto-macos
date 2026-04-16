import SwiftUI

struct SessionSidebarSection: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Section("SESSION") {
            if let session = appState.sessionManager?.currentSession {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(CantoColors.sessionActive)
                            .frame(width: 8, height: 8)
                        Text("Active")
                            .font(CantoTypography.sidebarBold)
                            .foregroundStyle(CantoColors.sessionActive)
                        Text(session.startedAt, style: .relative)
                            .font(CantoTypography.uiSmall)
                            .foregroundStyle(CantoColors.textSecondary)
                    }
                    Text("\(session.stats.filesCreated + session.stats.filesModified) files · \(session.stats.commits) commits")
                        .font(CantoTypography.uiSmall)
                        .foregroundStyle(CantoColors.textSecondary)
                }

                Button {
                    // Open timeline
                } label: {
                    Label("Open timeline", systemImage: "clock")
                        .font(CantoTypography.sidebar)
                }
                .buttonStyle(.plain)
            }

            if let pastSessions = appState.sessionManager?.pastSessions.prefix(3) {
                ForEach(Array(pastSessions), id: \.id) { session in
                    Button {
                        // Open past session timeline
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.name)
                                .font(CantoTypography.sidebar)
                                .lineLimit(1)
                            Text(session.startedAt, style: .date)
                                .font(CantoTypography.uiSmall)
                                .foregroundStyle(CantoColors.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
