import SwiftUI

struct MemoryCreateSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var type: MemoryFile.MemoryType = .user
    @State private var content = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Memory")
                .font(CantoTypography.displaySmall)
                .foregroundStyle(CantoColors.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(CantoTypography.sidebarBold)
                    .foregroundStyle(CantoColors.textSecondary)
                TextField("e.g., user_preferences", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(CantoTypography.sidebarBold)
                    .foregroundStyle(CantoColors.textSecondary)
                TextField("One-line description", text: $description)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Type")
                    .font(CantoTypography.sidebarBold)
                    .foregroundStyle(CantoColors.textSecondary)
                Picker("Type", selection: $type) {
                    ForEach(MemoryFile.MemoryType.allCases.filter { $0 != .unknown }, id: \.self) { t in
                        Text(t.rawValue.capitalized).tag(t)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Content")
                    .font(CantoTypography.sidebarBold)
                    .foregroundStyle(CantoColors.textSecondary)
                TextEditor(text: $content)
                    .font(CantoTypography.body)
                    .frame(minHeight: 100)
                    .border(CantoColors.textSecondary.opacity(0.3))
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                Button("Create") { createMemory() }
                    .buttonStyle(.borderedProminent)
                    .tint(CantoColors.accent)
                    .disabled(name.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 480)
    }

    private func createMemory() {
        guard let folderURL = appState.openFolderURL else { return }
        let memoryDir = folderURL.appendingPathComponent(".claude/projects/memory")
        try? FileManager.default.createDirectory(at: memoryDir, withIntermediateDirectories: true)

        let filename = name.replacingOccurrences(of: " ", with: "_").lowercased() + ".md"
        let fileURL = memoryDir.appendingPathComponent(filename)

        let fileContent = """
        ---
        name: \(name)
        description: \(description)
        type: \(type.rawValue)
        ---

        \(content)
        """

        try? fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
        dismiss()
    }
}
