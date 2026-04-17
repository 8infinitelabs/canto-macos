import SwiftUI

struct EditorContainerView: View {
    @Environment(AppState.self) private var appState
    @State private var wordCount = 0
    @State private var readingTime = 1

    var body: some View {
        VStack(spacing: 0) {
            // Route based on activeView first
            switch appState.activeView {
            case .memoryBrowser:
                MemoryBrowserView()
            case .configPanel:
                ConfigPanelView()
            case .sessionTimeline:
                if let session = appState.sessionManager?.currentSession {
                    SessionTimelineView(session: session)
                } else {
                    EmptyStateView(icon: "clock", title: "No active session", subtitle: "Session starts automatically when Claude edits files")
                }
            case .dashboard:
                // CLAUDE.md dashboard
                VStack(spacing: 0) {
                    if let tab = appState.activeTab {
                        BreadcrumbView(path: tab.url.path, projectRoot: appState.openFolderURL?.path ?? "")
                    }
                    ClaudeMDDashboardView()
                }
            case .editor:
                editorContent
            }

            StatusBarView(wordCount: wordCount, readingTime: readingTime)
        }
    }

    @ViewBuilder
    private var editorContent: some View {
        if !appState.tabs.isEmpty {
            TabBarView()
            Divider()

            if let tab = appState.activeTab {
                BreadcrumbView(path: tab.url.path, projectRoot: appState.openFolderURL?.path ?? "")

                Group {
                    if tab.url.pathExtension == "md" {
                        NativeMarkdownView(tab: tab)
                    } else if isImage(tab.url) {
                        ImagePreviewView(url: tab.url)
                    } else {
                        CodePreviewView(url: tab.url)
                    }
                }
                .transition(.opacity.animation(CantoAnimations.tabSwitch))

                if tab.isExternallyModified {
                    ConflictBannerView(tab: tab)
                }
            }
        } else {
            EmptyStateView(
                icon: "doc.richtext",
                title: "No file open",
                subtitle: "Select a markdown file from the sidebar to start editing"
            )
        }
    }

    private func isImage(_ url: URL) -> Bool {
        ["png", "jpg", "jpeg", "gif", "svg"].contains(url.pathExtension.lowercased())
    }
}
