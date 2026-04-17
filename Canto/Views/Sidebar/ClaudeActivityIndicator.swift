import SwiftUI

struct ClaudeActivityIndicator: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    var body: some View {
        Button {
            appState.activeView = .sessionTimeline
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(isActive ? CantoColors.sessionActive : CantoColors.sessionIdle)
                    .frame(width: 8, height: 8)
                    .opacity(isActive && isPulsing && !reduceMotion ? 0.4 : 1.0)
                    .onAppear {
                        if !reduceMotion {
                            withAnimation(CantoAnimations.pulse) { isPulsing = true }
                        }
                    }

                VStack(alignment: .leading, spacing: 0) {
                    Text(isActive ? "Claude active" : "Idle")
                        .font(CantoTypography.uiSmall)
                        .foregroundStyle(isActive ? CantoColors.sessionActive : CantoColors.textSecondary)
                    if let session = appState.sessionManager?.currentSession {
                        Text(session.name)
                            .font(CantoTypography.uiSmall)
                            .foregroundStyle(CantoColors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(CantoColors.surface.opacity(0.5))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }

    private var isActive: Bool {
        appState.isSessionActive
    }

    private var tooltip: String {
        guard let session = appState.sessionManager?.currentSession else {
            return "No active Claude session"
        }
        let files = session.stats.filesCreated + session.stats.filesModified
        return "Session: \(session.name) · \(files) files · \(session.stats.commits) commits"
    }
}
