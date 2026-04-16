import SwiftUI

@Observable
class AppState {
    var openFolderPath: URL?
    var isClaudeProject: Bool = false

    var hasOpenFolder: Bool {
        openFolderPath != nil
    }
}
