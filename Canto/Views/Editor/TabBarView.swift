import SwiftUI

struct TabBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(appState.tabs) { tab in
                    TabButton(tab: tab, isActive: tab.id == appState.activeTabID)
                }
            }
        }
        .frame(height: 36)
        .background(CantoColors.surface)
    }
}

struct TabButton: View {
    @Environment(AppState.self) private var appState
    let tab: TabItem
    let isActive: Bool

    var body: some View {
        Button {
            appState.activeTabID = tab.id
        } label: {
            HStack(spacing: 6) {
                Text(tab.name)
                    .font(CantoTypography.ui)
                    .foregroundStyle(isActive ? CantoColors.textPrimary : CantoColors.textSecondary)
                    .lineLimit(1)

                if tab.isBeingModifiedByClaude {
                    Circle()
                        .fill(CantoColors.accent)
                        .frame(width: 6, height: 6)
                        .modifier(PulseModifier())
                } else if tab.isDirty {
                    Circle()
                        .fill(CantoColors.textSecondary)
                        .frame(width: 6, height: 6)
                }

                Button {
                    appState.closeTab(tab.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(CantoColors.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close \(tab.name)")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isActive ? CantoColors.background : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing && !reduceMotion ? 0.4 : 1.0)
            .onAppear {
                if !reduceMotion {
                    withAnimation(CantoAnimations.pulse) { isPulsing = true }
                }
            }
    }
}
