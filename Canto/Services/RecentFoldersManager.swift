import Foundation
import AppKit

@Observable
class RecentFoldersManager {
    private(set) var folders: [RecentFolder] = []
    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let cantoDir = appSupport.appendingPathComponent("Canto", isDirectory: true)
        try? FileManager.default.createDirectory(at: cantoDir, withIntermediateDirectories: true)
        self.fileURL = cantoDir.appendingPathComponent("recent-folders.json")
        load()
    }

    func addFolder(url: URL) {
        guard let bookmark = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }

        let hasClaude = FileManager.default.fileExists(
            atPath: url.appendingPathComponent(".claude").path
        )
        let memoryPath = url.appendingPathComponent(".claude/memory")
        let memoryCount = (try? FileManager.default.contentsOfDirectory(atPath: memoryPath.path))?.count ?? 0

        let entry = RecentFolder(
            path: url.path,
            bookmark: bookmark,
            lastOpened: Date(),
            hasClaude: hasClaude,
            memoryCount: memoryCount
        )

        folders.removeAll { $0.path == url.path }
        folders.insert(entry, at: 0)
        if folders.count > 10 { folders = Array(folders.prefix(10)) }
        save()
    }

    func resolveBookmark(_ folder: RecentFolder) -> URL? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: folder.bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return nil }

        guard url.startAccessingSecurityScopedResource() else { return nil }

        if isStale {
            addFolder(url: url)
        }
        return url
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let store = try? JSONDecoder().decode(RecentFoldersStore.self, from: data)
        else { return }
        self.folders = store.folders
    }

    private func save() {
        let store = RecentFoldersStore(folders: folders)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(store) {
            try? data.write(to: fileURL)
        }
    }
}
