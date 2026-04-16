import SwiftUI

struct MainWindowView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.hasOpenFolder {
            Text("Editor will go here")
        } else {
            Text("Welcome to Canto")
        }
    }
}
