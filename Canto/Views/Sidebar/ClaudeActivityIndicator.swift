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
                    .fill(isActive ? CantoColors.sessionActive : CantoColors.sessionIdle.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .opacity(isActive && isPulsing && !reduceMotion ? 0.4 : 1.0)
                    .onAppear {
                        if !reduceMotion {
                            withAnimation(CantoAnimations.pulse) { isPulsing = true }
                        }
                    }

                Text(label)
                    .font(CantoTypography.uiSmall)
                    .foregroundStyle(isActive ? CantoColors.sessionActive : CantoColors.textSecondary)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(CantoColors.surface.opacity(0.4))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }

    private var isActive: Bool {
        appState.isSessionActive
    }

    private var label: String {
        if let session = appState.sessionManager?.currentSession {
            return "Claude: \(session.name)"
        }
        return "Claude — no active session"
    }

    private var tooltip: String {
        guard let session = appState.sessionManager?.currentSession else {
            return "No active Claude session. Canto starts tracking when Claude edits 3+ files."
        }
        let files = session.stats.filesCreated + session.stats.filesModified
        return "Session: \(session.name) · \(files) files · \(session.stats.commits) commits. Click to view timeline."
    }
}
