import SwiftUI

struct MainWindowView: View {
    @Environment(AppState.self) private var appState
    @State private var showCommandPalette = false
    @State private var isFocusMode = false

    var body: some View {
        ZStack {
            Group {
                if appState.hasOpenFolder {
                    if isFocusMode {
                        // Focus mode: just the editor, centered
                        VStack(spacing: 0) {
                            if let tab = appState.activeTab {
                                MarkdownWebView(
                                    content: tab.content,
                                    theme: appState.settings.theme,
                                    onContentChange: { newContent in
                                        tab.content = newContent
                                        tab.isDirty = true
                                    },
                                    onWordCount: { _, _ in }
                                )
                                .frame(maxWidth: 680)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(CantoColors.background)
                    } else {
                        NavigationSplitView {
                            SidebarView()
                        } detail: {
                            EditorContainerView()
                        }
                        .navigationSplitViewStyle(.balanced)
                    }
                } else {
                    WelcomeView()
                }
            }

            // Command palette overlay
            if showCommandPalette {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { showCommandPalette = false }

                VStack {
                    CommandPaletteView(isShowing: $showCommandPalette)
                        .padding(.top, 80)
                    Spacer()
                }
            }
        }
        .preferredColorScheme(appState.settings.theme == "dark" ? .dark : .light)
        .onOpenURL { url in
            if url.hasDirectoryPath {
                appState.openFolder(url)
            }
        }
    }
}
