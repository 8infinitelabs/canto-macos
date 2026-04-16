import SwiftUI

struct CommandPaletteView: View {
    @Environment(AppState.self) private var appState
    @Binding var isShowing: Bool
    @State private var query = ""
    @State private var selectedIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(CantoColors.textSecondary)
                TextField("Search files and actions...", text: $query)
                    .font(CantoTypography.body)
                    .textFieldStyle(.plain)
                    .onSubmit { executeSelected() }
            }
            .padding(16)

            Divider()

            // Results
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                        Button {
                            executeItem(item)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 14))
                                    .foregroundStyle(CantoColors.accent)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(CantoTypography.sidebar)
                                        .foregroundStyle(CantoColors.textPrimary)
                                    if let subtitle = item.subtitle {
                                        Text(subtitle)
                                            .font(CantoTypography.uiSmall)
                                            .foregroundStyle(CantoColors.textSecondary)
                                    }
                                }
                                Spacer()
                                if let shortcut = item.shortcut {
                                    Text(shortcut)
                                        .font(CantoTypography.codeSmall)
                                        .foregroundStyle(CantoColors.textSecondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(index == selectedIndex ? CantoColors.accent.opacity(0.1) : Color.clear)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 300)
        }
        .frame(width: 500)
        .background(CantoColors.surface)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .onChange(of: query) { _, _ in selectedIndex = 0 }
    }

    private var filteredItems: [PaletteItem] {
        let items = buildItems()
        if query.isEmpty { return items }
        return items.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            ($0.subtitle?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    private func buildItems() -> [PaletteItem] {
        var items: [PaletteItem] = []

        // Actions
        items.append(PaletteItem(id: "toggle-theme", icon: "circle.lefthalf.filled", title: "Toggle Theme", shortcut: nil) {
            appState.settingsManager.update { $0.theme = $0.theme == "dark" ? "light" : "dark" }
        })
        items.append(PaletteItem(id: "save", icon: "square.and.arrow.down", title: "Save File", shortcut: "Cmd+S") {
            appState.saveActiveTab()
        })
        items.append(PaletteItem(id: "close-tab", icon: "xmark", title: "Close Tab", shortcut: "Cmd+W") {
            if let id = appState.activeTabID { appState.closeTab(id) }
        })
        items.append(PaletteItem(id: "open-folder", icon: "folder", title: "Open Folder", shortcut: "Cmd+O") {
            if let url = FolderAccessService.openFolderPanel() { appState.openFolder(url) }
        })

        // Open files
        for node in appState.fileTree where node.isMarkdown {
            items.append(PaletteItem(id: "file-\(node.id)", icon: "doc.richtext", title: node.name, subtitle: node.id) {
                appState.openFile(node)
            })
        }

        return items
    }

    private func executeSelected() {
        let items = filteredItems
        if selectedIndex < items.count {
            executeItem(items[selectedIndex])
        }
    }

    private func executeItem(_ item: PaletteItem) {
        item.action()
        isShowing = false
    }
}

struct PaletteItem: Identifiable {
    let id: String
    let icon: String
    let title: String
    var subtitle: String? = nil
    var shortcut: String? = nil
    let action: () -> Void
}
