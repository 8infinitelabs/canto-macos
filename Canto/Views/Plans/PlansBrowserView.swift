import SwiftUI

struct PlansBrowserView: View {
    @Environment(AppState.self) private var appState
    @State private var showCreateSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Plans")
                    .font(CantoTypography.displayMedium)
                    .foregroundStyle(CantoColors.textPrimary)
                Spacer()
                Button {
                    showCreateSheet = true
                } label: {
                    Label("New Plan", systemImage: "plus")
                        .font(CantoTypography.ui)
                }
                .buttonStyle(.borderedProminent)
                .tint(CantoColors.accent)
                .controlSize(.small)
            }

            if plans.isEmpty {
                EmptyStateView(
                    icon: "list.bullet.clipboard",
                    title: "No plans yet",
                    subtitle: "Plans live in docs/superpowers/plans/ or .claude/plans/. Create one with the button above."
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 12)], spacing: 12) {
                        ForEach(plans) { plan in
                            PlanCardView(plan: plan)
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CantoColors.background)
        .sheet(isPresented: $showCreateSheet) {
            PlanCreateSheet()
        }
    }

    private var plans: [FileNode] {
        func findPlans(in nodes: [FileNode]) -> [FileNode] {
            var result: [FileNode] = []
            for node in nodes {
                if node.isDirectory, let children = node.children {
                    if node.name == "plans" {
                        result += children.filter { $0.isMarkdown }
                    } else {
                        result += findPlans(in: children)
                    }
                }
            }
            return result
        }
        return findPlans(in: appState.fileTree)
    }
}

struct PlanCardView: View {
    @Environment(AppState.self) private var appState
    let plan: FileNode

    var body: some View {
        Button {
            appState.openFile(plan)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "list.bullet.clipboard")
                        .foregroundStyle(CantoColors.accent)
                    Text(plan.name)
                        .font(CantoTypography.sidebarBold)
                        .foregroundStyle(CantoColors.textPrimary)
                        .lineLimit(1)
                    Spacer()
                }
                if let preview = previewContent {
                    Text(preview)
                        .font(CantoTypography.uiSmall)
                        .foregroundStyle(CantoColors.textSecondary)
                        .lineLimit(3)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CantoColors.surface)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var previewContent: String? {
        guard let content = try? String(contentsOf: plan.url, encoding: .utf8) else { return nil }
        let firstLines = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty && !$0.hasPrefix("#") }
            .prefix(3)
            .joined(separator: " ")
        return String(firstLines.prefix(200))
    }
}

struct PlanCreateSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var goal = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Plan")
                .font(CantoTypography.displaySmall)
                .foregroundStyle(CantoColors.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(CantoTypography.sidebarBold)
                    .foregroundStyle(CantoColors.textSecondary)
                TextField("e.g., migrate-auth-system", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Goal")
                    .font(CantoTypography.sidebarBold)
                    .foregroundStyle(CantoColors.textSecondary)
                TextField("What will this plan accomplish?", text: $goal, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                Button("Create") { createPlan() }
                    .buttonStyle(.borderedProminent)
                    .tint(CantoColors.accent)
                    .disabled(name.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 480)
    }

    private func createPlan() {
        guard let folderURL = appState.openFolderURL else { return }

        // Prefer docs/superpowers/plans/ if exists, else .claude/plans/
        let supDir = folderURL.appendingPathComponent("docs/superpowers/plans")
        let claudeDir = folderURL.appendingPathComponent(".claude/plans")
        let targetDir = FileManager.default.fileExists(atPath: supDir.path) ? supDir : claudeDir
        try? FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)

        let dateStr = DateFormatter.yyyymmdd.string(from: Date())
        let slug = name.replacingOccurrences(of: " ", with: "-").lowercased()
        let filename = "\(dateStr)-\(slug).md"
        let fileURL = targetDir.appendingPathComponent(filename)

        let content = """
        # \(name)

        **Goal:** \(goal)

        ## Context

        ## Tasks

        - [ ] Task 1

        """

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            appState.reloadPlans()
            dismiss()
        } catch {
            print("[Canto] Failed to create plan: \(error)")
        }
    }
}

extension DateFormatter {
    static let yyyymmdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
