import SwiftUI

struct MemoryCardView: View {
    @Environment(AppState.self) private var appState
    let memory: MemoryFile
    @State private var showDeleteConfirm = false

    var body: some View {
        Button {
            let node = FileNode(
                id: memory.url.lastPathComponent,
                name: memory.name,
                url: memory.url,
                isDirectory: false,
                children: nil,
                fileExtension: "md"
            )
            appState.openFile(node)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(CantoColors.forMemoryType(memory.type.rawValue))
                            .frame(width: 8, height: 8)
                        Text(memory.type.rawValue.capitalized)
                            .font(CantoTypography.uiSmall)
                            .foregroundStyle(CantoColors.forMemoryType(memory.type.rawValue))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(CantoColors.forMemoryType(memory.type.rawValue).opacity(0.1))
                    .cornerRadius(4)

                    Spacer()

                    if memory.isStale() {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 12))
                            .foregroundStyle(CantoColors.memoryProject)
                    }
                }

                Text(memory.name)
                    .font(CantoTypography.sidebarBold)
                    .foregroundStyle(CantoColors.textPrimary)
                    .lineLimit(1)

                Text(memory.description)
                    .font(CantoTypography.uiSmall)
                    .foregroundStyle(CantoColors.textSecondary)
                    .lineLimit(2)

                Text(memory.content.prefix(120) + (memory.content.count > 120 ? "..." : ""))
                    .font(CantoTypography.uiSmall)
                    .foregroundStyle(CantoColors.textSecondary.opacity(0.7))
                    .lineLimit(3)

                HStack {
                    Spacer()
                    Text(memory.modifiedDate, style: .relative)
                        .font(CantoTypography.uiSmall)
                        .foregroundStyle(CantoColors.textSecondary)
                }
            }
            .padding(16)
            .background(CantoColors.surface)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete Memory", systemImage: "trash")
            }
        }
        .alert("Delete \"\(memory.name)\"?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                try? FileManager.default.removeItem(at: memory.url)
                appState.reloadMemories()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This memory file will be moved to Trash.")
        }
    }
}
