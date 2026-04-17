import Foundation

enum FileTreeBuilder {
    enum Mode {
        case all
        case markdownOnly
    }

    static func build(from rootURL: URL, mode: Mode = .all, gitignorePatterns: [String] = []) -> [FileNode] {
        let tree = buildAll(from: rootURL, gitignorePatterns: gitignorePatterns)
        switch mode {
        case .all: return tree
        case .markdownOnly: return pruneToMarkdown(tree)
        }
    }

    /// Keep .md files, CLAUDE.md, and directories that contain .md descendants.
    /// Drop everything else.
    static func pruneToMarkdown(_ nodes: [FileNode]) -> [FileNode] {
        var result: [FileNode] = []
        for node in nodes {
            if node.isDirectory {
                if let children = node.children {
                    let pruned = pruneToMarkdown(children)
                    if !pruned.isEmpty {
                        var keep = node
                        keep.children = pruned
                        result.append(keep)
                    }
                }
            } else if node.isMarkdown {
                result.append(node)
            }
        }
        return result
    }

    private static func buildAll(from rootURL: URL, gitignorePatterns: [String] = []) -> [FileNode] {
        let fm = FileManager.default
        let standardRoot = rootURL.standardizedFileURL
        let rootPath = standardRoot.path
        guard let enumerator = fm.enumerator(
            at: standardRoot,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var nodesByPath: [String: FileNode] = [:]
        var rootChildren: [FileNode] = []

        var allURLs: [URL] = []
        while let url = enumerator.nextObject() as? URL {
            let stdURL = url.standardizedFileURL
            let relativePath = String(stdURL.path.dropFirst(rootPath.count + 1))

            if shouldSkip(relativePath) {
                if (try? stdURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                    enumerator.skipDescendants()
                }
                continue
            }
            allURLs.append(stdURL)
        }

        for url in allURLs.sorted(by: { $0.path < $1.path }) {
            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            let relativePath = String(url.path.dropFirst(rootPath.count + 1))

            let node = FileNode(
                id: relativePath,
                name: url.lastPathComponent,
                url: url,
                isDirectory: isDir,
                children: isDir ? [] : nil,
                fileExtension: isDir ? nil : url.pathExtension
            )

            let parentPath = (relativePath as NSString).deletingLastPathComponent
            if parentPath.isEmpty {
                rootChildren.append(node)
            } else if var parent = nodesByPath[parentPath] {
                parent.children?.append(node)
                nodesByPath[parentPath] = parent
                updateNodeInTree(&rootChildren, path: parentPath, node: parent)
            }

            nodesByPath[relativePath] = node
        }

        return sortNodes(rootChildren)
    }

    private static func shouldSkip(_ path: String) -> Bool {
        let skipDirs = ["node_modules", ".git", "DerivedData", "build", ".build", "__pycache__", ".next"]
        return skipDirs.contains(where: { path.hasPrefix($0) || path.contains("/\($0)") })
    }

    private static func sortNodes(_ nodes: [FileNode]) -> [FileNode] {
        nodes.sorted { a, b in
            if a.isClaudeMD { return true }
            if b.isClaudeMD { return false }
            if a.name == ".claude" && a.isDirectory { return true }
            if b.name == ".claude" && b.isDirectory { return false }
            if a.isDirectory && b.isDirectory {
                if a.hasMarkdownChildren && !b.hasMarkdownChildren { return true }
                if !a.hasMarkdownChildren && b.hasMarkdownChildren { return false }
                return a.name < b.name
            }
            if a.isDirectory { return true }
            if b.isDirectory { return false }
            if a.isMarkdown && !b.isMarkdown { return true }
            if !a.isMarkdown && b.isMarkdown { return false }
            return a.name < b.name
        }.map { node in
            var sorted = node
            if let children = sorted.children {
                sorted.children = sortNodes(children)
            }
            return sorted
        }
    }

    private static func updateNodeInTree(_ nodes: inout [FileNode], path: String, node: FileNode) {
        for i in nodes.indices {
            if nodes[i].id == path {
                nodes[i] = node
                return
            }
            if let children = nodes[i].children, !children.isEmpty {
                var mutableChildren = children
                updateNodeInTree(&mutableChildren, path: path, node: node)
                nodes[i].children = mutableChildren
            }
        }
    }
}
