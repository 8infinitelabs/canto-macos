import SwiftUI

struct NativeMarkdownView: View {
    let tab: TabItem
    @State private var editBuffer: String = ""
    @State private var showFind = false
    @State private var findText = ""
    @State private var matchCount = 0
    @State private var autoSaveTask: Task<Void, Never>?
    @FocusState private var editorFocused: Bool
    @State private var previewContent: String = ""
    @State private var previewDebounceTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            // Format toolbar
            FormatToolbar { action in
                performFormatAction(action)
            }

            // Find bar
            if showFind {
                FindBar(
                    findText: $findText,
                    matchCount: matchCount,
                    onDismiss: { showFind = false }
                )
                .onChange(of: findText) { _, query in
                    matchCount = countMatches(query: query, in: editBuffer)
                }
            }

            HSplitView {
                // Left: Editor
                VStack(spacing: 0) {
                    HStack {
                        Text("Edit")
                            .font(CantoTypography.uiSmall)
                            .foregroundStyle(CantoColors.textSecondary)
                            .padding(.leading, 16)
                        Spacer()
                        if tab.isDirty {
                            Circle()
                                .fill(CantoColors.textSecondary)
                                .frame(width: 6, height: 6)
                                .padding(.trailing, 4)
                        }
                    }
                    .frame(height: 28)
                    .background(CantoColors.surface.opacity(0.6))

                    MarkdownEditorView(text: $editBuffer)
                        .focused($editorFocused)
                        .onChange(of: editBuffer) { _, newValue in
                            tab.content = newValue
                            tab.isDirty = true
                            scheduleAutoSave()
                            schedulePreviewUpdate()
                        }
                }
                .frame(minWidth: 300)
                .background(CantoColors.background)

                // Right: Live preview (debounced)
                VStack(spacing: 0) {
                    HStack {
                        Text("Preview")
                            .font(CantoTypography.uiSmall)
                            .foregroundStyle(CantoColors.textSecondary)
                            .padding(.leading, 16)
                        Spacer()
                    }
                    .frame(height: 28)
                    .background(CantoColors.surface.opacity(0.6))

                    ScrollView {
                        MarkdownRenderer(content: previewContent)
                            .frame(maxWidth: 680, alignment: .leading)
                            .padding(24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(CantoColors.background)
                }
                .frame(minWidth: 300)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button { performFormatAction(.bold) } label: {
                    Image(systemName: "bold")
                }
                .keyboardShortcut("b", modifiers: .command)
                .help("Bold (⌘B)")

                Button { performFormatAction(.italic) } label: {
                    Image(systemName: "italic")
                }
                .keyboardShortcut("i", modifiers: .command)
                .help("Italic (⌘I)")

                Button { performFormatAction(.code) } label: {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                }
                .help("Inline code")
            }
        }
        .onAppear {
            editBuffer = tab.content
            previewContent = tab.content
        }
        .onReceive(NotificationCenter.default.publisher(for: .cantoSaveFile)) { _ in
            try? MarkdownFileService.write(url: tab.url, content: tab.content)
            tab.isDirty = false
            autoSaveTask?.cancel()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cantoFindInFile)) { _ in
            showFind.toggle()
        }
    }

    // MARK: - Format actions

    private func performFormatAction(_ action: FormatAction) {
        let syntax = action.markdownSyntax
        let sel = NSApp.keyWindow?.firstResponder
        if let textView = findFirstResponderTextView(sel) {
            let range = textView.selectedRange()
            if range.length > 0 {
                // Wrap selection
                if let textStorage = textView.textStorage {
                    let selected = textStorage.attributedSubstring(from: range).string
                    let replacement = syntax.prefix + selected + syntax.suffix
                    textView.insertText(replacement, replacementRange: range)
                }
            } else {
                // Insert at cursor with placeholder
                textView.insertText(syntax.prefix + syntax.placeholder + syntax.suffix, replacementRange: range)
                // Select the placeholder
                let insertPoint = textView.selectedRange().location
                let placeholderRange = NSRange(
                    location: insertPoint - syntax.suffix.count - syntax.placeholder.count,
                    length: syntax.placeholder.count
                )
                textView.setSelectedRange(placeholderRange)
            }
            editBuffer = textView.string
            tab.content = editBuffer
            tab.isDirty = true
        }
    }

    private func findFirstResponderTextView(_ responder: NSResponder?) -> NSTextView? {
        if let tv = responder as? NSTextView { return tv }
        return responder?.nextResponder.flatMap { findFirstResponderTextView($0) }
    }

    private func countMatches(query: String, in text: String) -> Int {
        guard !query.isEmpty else { return 0 }
        var count = 0
        var range = text.startIndex..<text.endIndex
        while let r = text.range(of: query, options: .caseInsensitive, range: range) {
            count += 1
            range = r.upperBound..<text.endIndex
        }
        return count
    }

    private func schedulePreviewUpdate() {
        previewDebounceTask?.cancel()
        previewDebounceTask = Task {
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                previewContent = tab.content
            }
        }
    }

    private func scheduleAutoSave() {
        autoSaveTask?.cancel()
        autoSaveTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            try? MarkdownFileService.write(url: tab.url, content: tab.content)
            await MainActor.run {
                tab.isDirty = false
            }
        }
    }
}

// MARK: - Format action types

enum FormatAction: CaseIterable {
    case bold, italic, code, heading, bullet, number, quote, link, image

    var label: String {
        switch self {
        case .bold: "B"
        case .italic: "I"
        case .code: "</>"
        case .heading: "H"
        case .bullet: "•"
        case .number: "1."
        case .quote: "\""
        case .link: "🔗"
        case .image: "🖼"
        }
    }

    var systemImage: String {
        switch self {
        case .bold: "bold"
        case .italic: "italic"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .heading: "textformat.size"
        case .bullet: "list.bullet"
        case .number: "list.number"
        case .quote: "text.quote"
        case .link: "link"
        case .image: "photo"
        }
    }

    var markdownSyntax: (prefix: String, suffix: String, placeholder: String) {
        switch self {
        case .bold: ("**", "**", "bold")
        case .italic: ("_", "_", "italic")
        case .code: ("`", "`", "code")
        case .heading: ("\n## ", "", "Heading")
        case .bullet: ("\n- ", "", "item")
        case .number: ("\n1. ", "", "item")
        case .quote: ("\n> ", "", "quote")
        case .link: ("[", "](url)", "link text")
        case .image: ("![", "](url)", "alt text")
        }
    }
}

// MARK: - Format toolbar

struct FormatToolbar: View {
    let onAction: (FormatAction) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(FormatAction.allCases, id: \.self) { action in
                Button {
                    onAction(action)
                } label: {
                    Image(systemName: action.systemImage)
                        .font(.system(size: 12))
                        .frame(width: 28, height: 24)
                }
                .buttonStyle(.plain)
                .help(action.label)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .frame(height: 30)
        .background(CantoColors.surface)
    }
}

// MARK: - Find bar

struct FindBar: View {
    @Binding var findText: String
    let matchCount: Int
    let onDismiss: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(CantoColors.textSecondary)

            TextField("Find...", text: $findText)
                .textFieldStyle(.plain)
                .font(CantoTypography.ui)
                .focused($focused)
                .frame(width: 200)

            if !findText.isEmpty {
                Text("\(matchCount) matches")
                    .font(CantoTypography.uiSmall)
                    .foregroundStyle(CantoColors.textSecondary)
            }

            Spacer()

            Button { onDismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(CantoColors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(CantoColors.surface.opacity(0.8))
        .onAppear { focused = true }
    }
}

// MARK: - NSTextView wrapper

struct MarkdownEditorView: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.delegate = context.coordinator
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = NSColor(named: "TextPrimary") ?? .labelColor
        textView.backgroundColor = NSColor(named: "Background") ?? .textBackgroundColor
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.allowsUndo = true
        textView.drawsBackground = true
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.enabledTextCheckingTypes = 0
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        // Only update from external changes (not from user typing)
        if context.coordinator.isUpdating { return }
        if textView.string != text {
            context.coordinator.isUpdating = true
            let selected = textView.selectedRange()
            textView.string = text
            if selected.location <= text.utf16.count {
                textView.setSelectedRange(selected)
            }
            context.coordinator.isUpdating = false
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        var isUpdating = false

        init(text: Binding<String>) {
            _text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            isUpdating = true
            text = textView.string
            isUpdating = false
        }
    }
}
