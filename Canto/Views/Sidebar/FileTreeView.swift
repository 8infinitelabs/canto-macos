import SwiftUI

struct FileTreeSection: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        // Two sub-sections for clarity: root-level docs first, then folders
        if rootFiles.isEmpty && folderNodes.isEmpty {
            Section("DOCUMENTS") {
                Text("No markdown files in this project")
                    .font(CantoTypography.uiSmall)
                    .foregroundStyle(CantoColors.textSecondary)
                    .italic()
                    .padding(.vertical, 4)
            }
        } else {
            if !rootFiles.isEmpty {
                Section("DOCUMENTS") {
                    ForEach(rootFiles, id: \.id) { node in
                        FileNodeRow(node: node, indent: 0)
                    }
                }
            }

            if !folderNodes.isEmpty {
                Section("FOLDERS") {
                    ForEach(folderNodes, id: \.id) { node in
                        FolderRow(node: node)
                    }
                }
            }
        }
    }

    /// Markdown files at the root of the project (excluding CLAUDE.md which is in its own section).
    private var rootFiles: [FileNode] {
        appState.fileTree
            .filter { !$0.isDirectory && $0.isMarkdown && !$0.isClaudeMD }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Folders that contain markdown (excluding .claude which is handled separately).
    private var folderNodes: [FileNode] {
        appState.fileTree
            .filter { $0.isDirectory && $0.name != ".claude" }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

/// File tree with "New File" button.
struct FileTreeWithToolbar: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("FILES")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CantoColors.textSecondary)

                Spacer()

                Button {
                    appState.createNewFile()
                } label: {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 13))
                        .foregroundStyle(CantoColors.textSecondary)
                }
                .buttonStyle(.plain)
                .help("New markdown file (⌘N)")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(CantoColors.surface.opacity(0.4))

            FileTreeSection()
        }
    }
}

/// Top-level folder with expandable contents.
struct FolderRow: View {
    @Environment(AppState.self) private var appState
    let node: FileNode
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if let children = node.children {
                ForEach(sortedChildren(children), id: \.id) { child in
                    FileNodeRow(node: child, indent: 1)
                }
            }
        } label: {
            Label {
                HStack {
                    Text(node.name)
                        .font(CantoTypography.sidebar)
                        .foregroundStyle(CantoColors.textPrimary)
                    Spacer()
                    Text("\(countMarkdown(node))")
                        .font(CantoTypography.uiSmall)
                        .foregroundStyle(CantoColors.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(CantoColors.surface)
                        .cornerRadius(4)
                }
            } icon: {
                Image(systemName: "folder.fill")
                    .foregroundStyle(CantoColors.accent.opacity(0.8))
            }
        }
    }

    private func sortedChildren(_ children: [FileNode]) -> [FileNode] {
        children.sorted { a, b in
            if a.isDirectory != b.isDirectory {
                return !a.isDirectory // files first
            }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    private func countMarkdown(_ node: FileNode) -> Int {
        guard let children = node.children else { return 0 }
        var count = 0
        for child in children {
            if child.isDirectory {
                count += countMarkdown(child)
            } else if child.isMarkdown {
                count += 1
            }
        }
        return count
    }
}

/// Individual file or folder row, used inside folder expansions.
struct FileNodeRow: View {
    @Environment(AppState.self) private var appState
    let node: FileNode
    let indent: Int
    @State private var isExpanded = false

    var body: some View {
        if node.isDirectory {
            DisclosureGroup(isExpanded: $isExpanded) {
                if let children = node.children {
                    ForEach(children.sorted(by: { $0.name < $1.name }), id: \.id) { child in
                        FileNodeRow(node: child, indent: indent + 1)
                    }
                }
            } label: {
                Label {
                    Text(node.name)
                        .font(CantoTypography.sidebar)
                        .foregroundStyle(CantoColors.textPrimary)
                } icon: {
                    Image(systemName: "folder")
                        .foregroundStyle(CantoColors.accent.opacity(0.7))
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
                    Image(systemName: "doc.text")
                        .foregroundStyle(CantoColors.accent)
                }
            }
            .buttonStyle(.plain)
        }
    }
}
