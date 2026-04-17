import SwiftUI

struct NativeMarkdownView: View {
    let tab: TabItem
    @State private var isEditing = false

    var body: some View {
        if isEditing {
            // Raw markdown editor
            TextEditor(text: Binding(
                get: { tab.content },
                set: { newValue in
                    tab.content = newValue
                    tab.isDirty = true
                }
            ))
            .font(CantoTypography.code)
            .scrollContentBackground(.hidden)
            .background(CantoColors.background)
            .padding(.horizontal, 24)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        isEditing = false
                    } label: {
                        Label("Preview", systemImage: "eye")
                    }
                }
            }
        } else {
            // Rendered markdown preview
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let attributed = try? AttributedString(markdown: tab.content, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                        Text(attributed)
                            .font(CantoTypography.body)
                            .foregroundStyle(CantoColors.textPrimary)
                            .textSelection(.enabled)
                            .frame(maxWidth: 720, alignment: .leading)
                    } else {
                        Text(tab.content)
                            .font(CantoTypography.body)
                            .foregroundStyle(CantoColors.textPrimary)
                            .textSelection(.enabled)
                            .frame(maxWidth: 720, alignment: .leading)
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(CantoColors.background)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        isEditing = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
        }
    }
}
