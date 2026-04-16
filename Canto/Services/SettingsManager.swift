import Foundation

@Observable
class SettingsManager {
    private(set) var settings: Settings
    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let cantoDir = appSupport.appendingPathComponent("Canto", isDirectory: true)
        try? FileManager.default.createDirectory(at: cantoDir, withIntermediateDirectories: true)
        self.fileURL = cantoDir.appendingPathComponent("settings.json")

        if let data = try? Data(contentsOf: fileURL),
           let loaded = try? JSONDecoder().decode(Settings.self, from: data) {
            self.settings = loaded
        } else {
            self.settings = Settings()
        }
    }

    func update(_ modify: (inout Settings) -> Void) {
        modify(&settings)
        save()
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(settings) {
            try? data.write(to: fileURL)
        }
    }
}
