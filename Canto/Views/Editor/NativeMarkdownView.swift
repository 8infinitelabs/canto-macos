import SwiftUI

struct NativeMarkdownView: View {
    let tab: TabItem
    @State private var isEditing = false
    @State private var editBuffer: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Top bar with Edit/Preview toggle
            HStack {
                Spacer()
                Button {
                    toggle()
                } label: {
                    Label(isEditing ? "Preview" : "Edit",
                          systemImage: isEditing ? "eye" : "pencil")
                        .font(CantoTypography.ui)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(CantoColors.surface.opacity(0.5))

            Divider()

            if isEditing {
                editor
            } else {
                preview
            }
        }
    }

    private func toggle() {
        if isEditing {
            tab.content = editBuffer
            tab.isDirty = true
        } else {
            editBuffer = tab.content
        }
        isEditing.toggle()
    }

    private var editor: some View {
        TextEditor(text: $editBuffer)
            .font(CantoTypography.code)
            .scrollContentBackground(.hidden)
            .background(CantoColors.background)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .onChange(of: editBuffer) { _, newValue in
                tab.content = newValue
                tab.isDirty = true
            }
    }

    private var preview: some View {
        ScrollView {
            MarkdownRenderer(content: tab.content)
                .frame(maxWidth: 720, alignment: .leading)
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(CantoColors.background)
    }
}
