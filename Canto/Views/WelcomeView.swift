import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    private func openProject(url: URL) {
        // If this window is empty (welcome), load here; otherwise open new window
        if appState.hasOpenFolder {
            openWindow(id: "project", value: url)
        } else {
            appState.openFolder(url)
        }
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                AppIconView()
                    .frame(width: 80, height: 80)

                Text("Canto")
                    .font(CantoTypography.displayLarge)
                    .foregroundStyle(CantoColors.textPrimary)

                Text("Claude's markdown companion.")
                    .font(CantoTypography.body)
                    .foregroundStyle(CantoColors.textSecondary)

                Text("One window per project. Edit CLAUDE.md, memories, plans, and outputs visually.")
                    .font(CantoTypography.bodySmall)
                    .foregroundStyle(CantoColors.textSecondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
                    .padding(.top, 4)
            }

            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(CantoColors.textSecondary.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .frame(height: 120)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 28))
                                .foregroundStyle(CantoColors.textSecondary)
                            Text("Drop a project folder here")
                                .font(CantoTypography.body)
                                .foregroundStyle(CantoColors.textSecondary)
                            Text("Works best with a .claude/ directory")
                                .font(CantoTypography.uiSmall)
                                .foregroundStyle(CantoColors.textSecondary.opacity(0.6))
                        }
                    )
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        handleDrop(providers)
                    }

                Button("Open Project") {
                    if let url = FolderAccessService.openFolderPanel() {
                        openProject(url: url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(CantoColors.accent)
                .controlSize(.large)
                .accessibilityHint("Choose a project folder to open")
            }
            .frame(maxWidth: 400)

            if !appState.recentFolders.folders.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent")
                        .font(CantoTypography.sidebarBold)
                        .foregroundStyle(CantoColors.textSecondary)

                    ForEach(appState.recentFolders.folders.prefix(5)) { folder in
                        Button {
                            if let url = appState.recentFolders.resolveBookmark(folder) {
                                openProject(url: url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                    .foregroundStyle(CantoColors.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(folder.path.components(separatedBy: "/").suffix(2).joined(separator: "/"))
                                        .font(CantoTypography.sidebar)
                                        .foregroundStyle(CantoColors.textPrimary)
                                    HStack(spacing: 8) {
                                        if folder.hasClaude {
                                            Text("\(folder.memoryCount) memories")
                                                .font(CantoTypography.uiSmall)
                                                .foregroundStyle(CantoColors.accent)
                                        }
                                        Text(folder.lastOpened, style: .relative)
                                            .font(CantoTypography.uiSmall)
                                            .foregroundStyle(CantoColors.textSecondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(CantoColors.surface.opacity(0.5))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: 400)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CantoColors.background)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil),
                  url.hasDirectoryPath
            else { return }
            DispatchQueue.main.async {
                openProject(url: url)
            }
        }
        return true
    }
}
