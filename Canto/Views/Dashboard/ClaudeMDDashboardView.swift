import SwiftUI

struct ClaudeMDDashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var showRawMarkdown = false

    var body: some View {
        ScrollView {
            if appState.claudeMDSections.isEmpty {
                QuickSetupView()
            } else if showRawMarkdown {
                if let tab = appState.activeTab {
                    MarkdownWebView(
                        content: tab.content,
                        theme: appState.settings.theme,
                        onContentChange: { newContent in
                            tab.content = newContent
                            tab.isDirty = true
                        },
                        onWordCount: { _, _ in }
                    )
                }
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CLAUDE.md")
                                .font(CantoTypography.displayMedium)
                                .foregroundStyle(CantoColors.textPrimary)
                            Text("Project instructions for Claude Code")
                                .font(CantoTypography.bodySmall)
                                .foregroundStyle(CantoColors.textSecondary)
                        }
                        Spacer()
                        Button {
                            showRawMarkdown.toggle()
                        } label: {
                            Label("Raw Markdown", systemImage: "chevron.left.forwardslash.chevron.right")
                                .font(CantoTypography.ui)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    // Memory summary
                    if !appState.memories.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(MemoryFile.MemoryType.allCases.filter { $0 != .unknown }, id: \.rawValue) { type in
                                let count = appState.memories.filter { $0.type == type }.count
                                if count > 0 {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(CantoColors.forMemoryType(type.rawValue))
                                            .frame(width: 8, height: 8)
                                        Text("\(count) \(type.rawValue)")
                                            .font(CantoTypography.uiSmall)
                                            .foregroundStyle(CantoColors.textSecondary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(CantoColors.surface)
                                    .cornerRadius(6)
                                }
                            }
                        }
                    }

                    // Sections
                    ForEach(appState.claudeMDSections) { section in
                        DashboardSectionView(section: section)
                    }
                }
                .padding(32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CantoColors.background)
    }
}
