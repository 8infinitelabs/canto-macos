import SwiftUI

struct QuickSetupView: View {
    @Environment(AppState.self) private var appState

    private let templates = [
        ("Web Project", "## Stack\n\n- Framework: \n- Styling: \n- Database: \n\n## Rules\n\n- \n"),
        ("iOS App", "## Stack\n\nSwift, SwiftUI, macOS 14+\n\n## Rules\n\n- Use @Observable macro\n- Follow Apple HIG\n"),
        ("Python Project", "## Stack\n\nPython 3.12, uv\n\n## Rules\n\n- Use type hints\n- Run ruff before commit\n"),
        ("Empty", "## Instructions\n\n\n## Rules\n\n- \n"),
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(CantoColors.accent)

            Text("Set up CLAUDE.md")
                .font(CantoTypography.displayMedium)
                .foregroundStyle(CantoColors.textPrimary)

            Text("Choose a template to get started with project instructions for Claude.")
                .font(CantoTypography.body)
                .foregroundStyle(CantoColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            HStack(spacing: 12) {
                ForEach(templates, id: \.0) { name, content in
                    Button {
                        applyTemplate(content)
                    } label: {
                        VStack(spacing: 8) {
                            Text(name)
                                .font(CantoTypography.sidebarBold)
                                .foregroundStyle(CantoColors.textPrimary)
                        }
                        .frame(width: 120, height: 60)
                        .background(CantoColors.surface)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CantoColors.background)
    }

    private func applyTemplate(_ content: String) {
        guard let folderURL = appState.openFolderURL else { return }
        let claudeMDURL = folderURL.appendingPathComponent("CLAUDE.md")
        try? content.write(to: claudeMDURL, atomically: true, encoding: .utf8)
        appState.claudeMDSections = ClaudeMDParser.parse(content)
        if let tab = appState.activeTab {
            tab.content = content
            tab.isDirty = false
        }
    }
}
