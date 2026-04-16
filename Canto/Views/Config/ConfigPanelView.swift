import SwiftUI

struct ConfigPanelView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = "MCP Servers"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Claude Code Config")
                .font(CantoTypography.displayMedium)
                .foregroundStyle(CantoColors.textPrimary)

            Picker("Section", selection: $selectedTab) {
                Text("MCP Servers").tag("MCP Servers")
                Text("Permissions").tag("Permissions")
                Text("Hooks").tag("Hooks")
            }
            .pickerStyle(.segmented)

            ScrollView {
                switch selectedTab {
                case "MCP Servers":
                    if appState.mcpServers.isEmpty {
                        EmptyStateView(icon: "server.rack", title: "No MCP servers", subtitle: "Configure MCP servers in .claude/settings.json")
                    } else {
                        VStack(spacing: 8) {
                            ForEach(appState.mcpServers) { server in
                                MCPServerRow(server: server)
                            }
                        }
                    }
                case "Permissions":
                    if appState.permissions.isEmpty {
                        EmptyStateView(icon: "lock.shield", title: "No permissions", subtitle: "Permissions are set in .claude/settings.json")
                    } else {
                        VStack(spacing: 8) {
                            ForEach(appState.permissions) { perm in
                                HStack {
                                    Image(systemName: perm.allowed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(perm.allowed ? CantoColors.sessionDone : CantoColors.sessionError)
                                    Text(perm.tool)
                                        .font(CantoTypography.code)
                                        .foregroundStyle(CantoColors.textPrimary)
                                    Spacer()
                                    Text(perm.scope)
                                        .font(CantoTypography.uiSmall)
                                        .foregroundStyle(CantoColors.textSecondary)
                                }
                                .padding(12)
                                .background(CantoColors.surface)
                                .cornerRadius(8)
                            }
                        }
                    }
                case "Hooks":
                    if appState.hooks.isEmpty {
                        EmptyStateView(icon: "link", title: "No hooks", subtitle: "Configure hooks in .claude/settings.json")
                    } else {
                        VStack(spacing: 8) {
                            ForEach(appState.hooks) { hook in
                                HStack {
                                    Text(hook.event)
                                        .font(CantoTypography.sidebarBold)
                                        .foregroundStyle(CantoColors.accent)
                                    Spacer()
                                    Text(hook.command)
                                        .font(CantoTypography.code)
                                        .foregroundStyle(CantoColors.textSecondary)
                                        .lineLimit(1)
                                }
                                .padding(12)
                                .background(CantoColors.surface)
                                .cornerRadius(8)
                            }
                        }
                    }
                default:
                    EmptyView()
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CantoColors.background)
    }
}
