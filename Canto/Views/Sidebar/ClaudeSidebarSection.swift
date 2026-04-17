import SwiftUI

struct ClaudeSidebarSection: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Section("CLAUDE") {
            // CLAUDE.md — may not be in fileTree (filtered), open from disk
            Button {
                if let folderURL = appState.openFolderURL {
                    let claudeMDURL = folderURL.appendingPathComponent("CLAUDE.md")
                    let node = FileNode(
                        id: "CLAUDE.md",
                        name: "CLAUDE.md",
                        url: claudeMDURL,
                        isDirectory: false,
                        children: nil,
                        fileExtension: "md"
                    )
                    appState.openFile(node)
                }
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

            // Memory — click label opens browser, expand shows list
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
                Button {
                    appState.activeView = .memoryBrowser
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
                .buttonStyle(.plain)
            }

            // Plans
            DisclosureGroup {
                ForEach(planFiles, id: \.id) { node in
                    Button {
                        appState.openFile(node)
                    } label: {
                        Text(node.name)
                            .font(CantoTypography.sidebar)
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                }
            } label: {
                Label {
                    HStack {
                        Text("Plans")
                            .font(CantoTypography.sidebar)
                        Spacer()
                        Text("\(planFiles.count)")
                            .font(CantoTypography.uiSmall)
                            .foregroundStyle(CantoColors.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(CantoColors.surface)
                            .cornerRadius(4)
                    }
                } icon: {
                    Image(systemName: "list.bullet.clipboard")
                        .foregroundStyle(CantoColors.accent)
                }
            }

            Button {
                appState.activeView = .configPanel
            } label: {
                Label("Config", systemImage: "gearshape")
                    .font(CantoTypography.sidebar)
            }
            .buttonStyle(.plain)
        }
    }

    private var planFiles: [FileNode] {
        func findPlans(in nodes: [FileNode]) -> [FileNode] {
            var result: [FileNode] = []
            for node in nodes {
                if node.isDirectory, let children = node.children {
                    if node.name == "plans" {
                        result += children.filter { $0.isMarkdown }
                    } else {
                        result += findPlans(in: children)
                    }
                }
            }
            return result
        }
        return findPlans(in: appState.fileTree)
    }
}
