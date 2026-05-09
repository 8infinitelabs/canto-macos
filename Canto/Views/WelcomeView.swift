import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                AppIconView()
                    .frame(width: 80, height: 80)

                Text("Canto")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(CantoColors.textPrimary)

                Text("Your Claude Code companion for Mac")
                    .font(CantoTypography.body)
                    .foregroundStyle(CantoColors.textSecondary)

                Text("Edit CLAUDE.md, manage memories, browse plans,\nand track coding sessions — all in a native Mac app.")
                    .font(CantoTypography.bodySmall)
                    .foregroundStyle(CantoColors.textSecondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
                    .padding(.top, 4)
            }

            VStack(spacing: 12) {
                Button {
                    if let url = FolderAccessService.openFolderPanel() {
                        appState.openFolder(url)
                    }
                } label: {
                    Label("Open Project...", systemImage: "folder")
                        .frame(width: 200)
                }
                .buttonStyle(.borderedProminent)
                .tint(CantoColors.accent)
                .controlSize(.large)
                .keyboardShortcut("o", modifiers: .command)
                .accessibilityHint("Choose a Claude Code project folder")

                // Drop zone
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(CantoColors.textSecondary.opacity(0.25), style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .frame(width: 320, height: 80)
                    .overlay(
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 18))
                                .foregroundStyle(CantoColors.textSecondary)
                            Text("Drop a project folder here")
                                .font(CantoTypography.bodySmall)
                                .foregroundStyle(CantoColors.textSecondary)
                        }
                    )
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        handleDrop(providers)
                    }
            }

            if !appState.recentFolders.folders.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent")
                        .font(CantoTypography.sidebarBold)
                        .foregroundStyle(CantoColors.textSecondary)

                    ForEach(appState.recentFolders.folders.prefix(5)) { folder in
                        Button {
                            if let url = appState.recentFolders.resolveBookmark(folder) {
                                appState.openFolder(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                    .foregroundStyle(CantoColors.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(folder.path.components(separatedBy: "/").suffix(2).joined(separator: "/"))
                                        .font(CantoTypography.sidebar)
                                        .foregroundStyle(CantoColors.textPrimary)
                                    Text(folder.lastOpened, style: .relative)
                                        .font(CantoTypography.uiSmall)
                                        .foregroundStyle(CantoColors.textSecondary)
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
                .frame(width: 320)
            }

            Spacer()

            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(CantoTypography.uiSmall)
                .foregroundStyle(CantoColors.textSecondary.opacity(0.4))
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
                appState.openFolder(url)
            }
        }
        return true
    }
}
