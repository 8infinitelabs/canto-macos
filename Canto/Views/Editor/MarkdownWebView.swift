import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let content: String
    let theme: String
    let onContentChange: (String) -> Void
    let onWordCount: (Int, Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onContentChange: onContentChange, onWordCount: onWordCount)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "canto")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isInspectable = true
        webView.setValue(false, forKey: "drawsBackground")

        context.coordinator.webView = webView

        if let editorURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "editor-web") {
            webView.loadFileURL(editorURL, allowingReadAccessTo: editorURL.deletingLastPathComponent())
        }

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Only send loadFile if content changed from Swift side (not from JS callback)
        if content != context.coordinator.lastSentContent {
            context.coordinator.lastSentContent = content
            context.coordinator.sendToJS(webView: webView, type: "loadFile", payload: content)
        }
        if theme != context.coordinator.lastSentTheme {
            context.coordinator.lastSentTheme = theme
            context.coordinator.sendToJS(webView: webView, type: "setTheme", payload: theme)
        }
    }

    class Coordinator: NSObject, WKScriptMessageHandler {
        var webView: WKWebView?
        var isReady = false
        var pendingMessages: [(String, String)] = []
        var lastSentContent: String = ""
        var lastSentTheme: String = ""
        private var isLocalChange = false
        let onContentChange: (String) -> Void
        let onWordCount: (Int, Int) -> Void

        init(onContentChange: @escaping (String) -> Void, onWordCount: @escaping (Int, Int) -> Void) {
            self.onContentChange = onContentChange
            self.onWordCount = onWordCount
        }

        func userContentController(_ userContentController: WKUserContentController,
                                    didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any],
                  let type = body["type"] as? String
            else { return }

            switch type {
            case "ready":
                isReady = true
                for (type, payload) in pendingMessages {
                    sendToJS(webView: webView!, type: type, payload: payload)
                }
                pendingMessages.removeAll()
            case "contentChanged":
                if let content = body["data"] as? String {
                    // Mark as local change so updateNSView doesn't re-send
                    lastSentContent = content
                    DispatchQueue.main.async { self.onContentChange(content) }
                }
            case "wordCount":
                if let data = body["data"] as? [String: Int],
                   let words = data["words"],
                   let readingTime = data["readingTime"] {
                    DispatchQueue.main.async { self.onWordCount(words, readingTime) }
                }
            default:
                break
            }
        }

        func sendToJS(webView: WKWebView, type: String, payload: String) {
            guard isReady else {
                pendingMessages.append((type, payload))
                return
            }
            let escapedPayload = payload
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
                .replacingOccurrences(of: "\n", with: "\\n")
            let js = "window.cantoReceive({ type: '\(type)', payload: '\(escapedPayload)' })"
            webView.evaluateJavaScript(js)
        }
    }
}
