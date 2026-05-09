import SwiftUI
import AppKit

/// Hidden helper to disable native window tabbing on the host NSWindow.
/// Prevents duplicate empty Canto windows from merging into a tab bar.
private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async {
            if let window = v.window {
                window.tabbingMode = .disallowed
                window.titlebarAppearsTransparent = false
            }
        }
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct MainWindowView: View {
    @Environment(AppState.self) private var appState
    @State private var showCommandPalette = false
    @State private var isFocusMode = false

    var body: some View {
        ZStack {
            Group {
                if appState.hasOpenFolder {
                    if isFocusMode {
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
        .navigationTitle(appState.openFolderURL?.lastPathComponent ?? "Canto")
        .navigationSubtitle(appState.activeTab?.name ?? "")
        .background(WindowConfigurator())
        .onReceive(NotificationCenter.default.publisher(for: .cantoNewFile)) { _ in
            guard appState.hasOpenFolder else { return }
            appState.createNewFile()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cantoCloseTab)) { _ in
            guard let id = appState.activeTabID else { return }
            appState.closeTab(id)
        }
    }
}
