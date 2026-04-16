import SwiftUI

struct MemoryBrowserView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var selectedType: MemoryFile.MemoryType?
    @State private var showCreateSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Memory")
                    .font(CantoTypography.displayMedium)
                    .foregroundStyle(CantoColors.textPrimary)
                Spacer()
                Button {
                    showCreateSheet = true
                } label: {
                    Label("New Memory", systemImage: "plus")
                        .font(CantoTypography.ui)
                }
                .buttonStyle(.borderedProminent)
                .tint(CantoColors.accent)
                .controlSize(.small)
            }

            // Search + filter
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(CantoColors.textSecondary)
                    TextField("Search memories...", text: $searchText)
                        .font(CantoTypography.ui)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(CantoColors.surface)
                .cornerRadius(8)

                HStack(spacing: 4) {
                    FilterButton(label: "All", isSelected: selectedType == nil) {
                        selectedType = nil
                    }
                    ForEach(MemoryFile.MemoryType.allCases.filter { $0 != .unknown }, id: \.rawValue) { type in
                        FilterButton(
                            label: type.rawValue.capitalized,
                            color: CantoColors.forMemoryType(type.rawValue),
                            isSelected: selectedType == type
                        ) {
                            selectedType = type
                        }
                    }
                }
            }

            // Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 12)], spacing: 12) {
                    ForEach(filteredMemories) { memory in
                        MemoryCardView(memory: memory)
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CantoColors.background)
        .sheet(isPresented: $showCreateSheet) {
            MemoryCreateSheet()
        }
    }

    private var filteredMemories: [MemoryFile] {
        appState.memories.filter { memory in
            let matchesType = selectedType == nil || memory.type == selectedType
            let matchesSearch = searchText.isEmpty ||
                memory.name.localizedCaseInsensitiveContains(searchText) ||
                memory.description.localizedCaseInsensitiveContains(searchText) ||
                memory.content.localizedCaseInsensitiveContains(searchText)
            return matchesType && matchesSearch
        }
    }
}

struct FilterButton: View {
    let label: String
    var color: Color = CantoColors.textSecondary
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(CantoTypography.uiSmall)
                .foregroundStyle(isSelected ? .white : CantoColors.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? color : CantoColors.surface)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
