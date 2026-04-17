import SwiftUI

struct FileTreeSection: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Section {
            if filteredNodes.isEmpty {
                Text("No markdown files in this project")
                    .font(CantoTypography.uiSmall)
                    .foregroundStyle(CantoColors.textSecondary)
                    .italic()
                    .padding(.vertical, 4)
            } else {
                ForEach(filteredNodes, id: \.id) { node in
                    FileNodeRow(node: node)
                }
                Text("Only markdown is editable in Canto.")
                    .font(CantoTypography.uiSmall)
                    .foregroundStyle(CantoColors.textSecondary.opacity(0.6))
                    .italic()
                    .padding(.top, 8)
            }
        } header: {
            Text("DOCUMENTS")
        }
    }

    private var filteredNodes: [FileNode] {
        appState.fileTree.filter { node in
            !node.isClaudeMD && node.name != ".claude"
        }
    }
}

struct FileNodeRow: View {
    @Environment(AppState.self) private var appState
    let node: FileNode

    var body: some View {
        if node.isDirectory {
            DisclosureGroup {
                if let children = node.children {
                    ForEach(children, id: \.id) { child in
                        FileNodeRow(node: child)
                    }
                }
            } label: {
                Label {
                    Text(node.name)
                        .font(CantoTypography.sidebar)
                        .foregroundStyle(CantoColors.textPrimary)
                } icon: {
                    Image(systemName: "folder")
                        .foregroundStyle(CantoColors.accent)
                }
            }
        } else {
            Button {
                appState.openFile(node)
            } label: {
                Label {
                    Text(node.name)
                        .font(CantoTypography.sidebar)
                        .foregroundStyle(CantoColors.textPrimary)
                } icon: {
                    Image(systemName: "doc.richtext")
                        .foregroundStyle(CantoColors.accent)
                }
            }
            .buttonStyle(.plain)
        }
    }
}
