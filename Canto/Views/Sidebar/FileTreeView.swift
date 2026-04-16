import SwiftUI

struct FileTreeSection: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Section("FILES") {
            ForEach(filteredNodes, id: \.id) { node in
                FileNodeRow(node: node)
            }
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
            DisclosureGroup(isExpanded: .constant(node.hasMarkdownChildren)) {
                if let children = node.children {
                    ForEach(children, id: \.id) { child in
                        FileNodeRow(node: child)
                    }
                }
            } label: {
                Label {
                    Text(node.name)
                        .font(CantoTypography.sidebar)
                        .foregroundStyle(node.hasMarkdownChildren ? CantoColors.textPrimary : CantoColors.textSecondary)
                } icon: {
                    Image(systemName: "folder")
                        .foregroundStyle(node.hasMarkdownChildren ? CantoColors.accent : CantoColors.textSecondary)
                }
            }
        } else {
            Button {
                appState.openFile(node)
            } label: {
                Label {
                    Text(node.name)
                        .font(CantoTypography.sidebar)
                        .foregroundStyle(node.isMarkdown ? CantoColors.textPrimary : CantoColors.textSecondary)
                } icon: {
                    Image(systemName: iconForNode(node))
                        .foregroundStyle(node.isMarkdown ? CantoColors.accent : CantoColors.textSecondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func iconForNode(_ node: FileNode) -> String {
        if node.isMarkdown { return "doc.richtext" }
        if node.isImage { return "photo" }
        if node.isCode { return "chevron.left.forwardslash.chevron.right" }
        if node.isConfig { return "gearshape" }
        return "doc"
    }
}
