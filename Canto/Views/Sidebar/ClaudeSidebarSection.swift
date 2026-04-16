import SwiftUI

struct ClaudeSidebarSection: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Section("CLAUDE") {
            if let claudeNode = appState.fileTree.first(where: { $0.isClaudeMD }) {
                Button {
                    appState.openFile(claudeNode)
                } label: {
                    Label {
                        Text("CLAUDE.md")
                            .font(CantoTypography.sidebarBold)
                    } icon: {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(CantoColors.accent)
                    }
                }
                .buttonStyle(.plain)
            }

            DisclosureGroup {
                ForEach(appState.memories) { memory in
                    Button {
                        let node = FileNode(
                            id: memory.url.lastPathComponent,
                            name: memory.name,
                            url: memory.url,
                            isDirectory: false,
                            children: nil,
                            fileExtension: "md"
                        )
                        appState.openFile(node)
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(CantoColors.forMemoryType(memory.type.rawValue))
                                .frame(width: 8, height: 8)
                            Text(memory.name)
                                .font(CantoTypography.sidebar)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            } label: {
                Label {
                    HStack {
                        Text("Memory")
                            .font(CantoTypography.sidebar)
                        Spacer()
                        Text("\(appState.memories.count)")
                            .font(CantoTypography.uiSmall)
                            .foregroundStyle(CantoColors.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(CantoColors.surface)
                            .cornerRadius(4)
                    }
                } icon: {
                    Image(systemName: "brain")
                        .foregroundStyle(CantoColors.accent)
                }
            }

            Button {
                // Open config panel
            } label: {
                Label("Config", systemImage: "gearshape")
                    .font(CantoTypography.sidebar)
            }
            .buttonStyle(.plain)
        }
    }
}
