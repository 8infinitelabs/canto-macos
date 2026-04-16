import SwiftUI

struct EditorContainerView: View {
    @Environment(AppState.self) private var appState
    @State private var wordCount = 0
    @State private var readingTime = 1

    var body: some View {
        VStack(spacing: 0) {
            if !appState.tabs.isEmpty {
                TabBarView()
                Divider()

                if let tab = appState.activeTab {
                    BreadcrumbView(path: tab.url.path, projectRoot: appState.openFolderURL?.path ?? "")

                    Group {
                        if tab.url.pathExtension == "md" {
                            MarkdownWebView(
                                content: tab.content,
                                theme: appState.settings.theme,
                                onContentChange: { newContent in
                                    tab.content = newContent
                                    tab.isDirty = true
                                },
                                onWordCount: { words, time in
                                    wordCount = words
                                    readingTime = time
                                }
                            )
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
                    subtitle: "Select a file from the sidebar to start editing"
                )
            }

            StatusBarView(wordCount: wordCount, readingTime: readingTime)
        }
    }

    private func isImage(_ url: URL) -> Bool {
        ["png", "jpg", "jpeg", "gif", "svg"].contains(url.pathExtension.lowercased())
    }
}
