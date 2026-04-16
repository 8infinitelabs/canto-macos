import SwiftUI

struct MCPServerRow: View {
    let server: MCPServerConfig

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(server.name)
                    .font(CantoTypography.sidebarBold)
                    .foregroundStyle(CantoColors.textPrimary)
                if let command = server.command {
                    Text("\(command) \(server.args?.joined(separator: " ") ?? "")")
                        .font(CantoTypography.codeSmall)
                        .foregroundStyle(CantoColors.textSecondary)
                        .lineLimit(1)
                }
                if let url = server.url {
                    Text(url)
                        .font(CantoTypography.codeSmall)
                        .foregroundStyle(CantoColors.accent)
                        .lineLimit(1)
                }
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(CantoColors.sessionDone)
        }
        .padding(12)
        .background(CantoColors.surface)
        .cornerRadius(8)
    }
}
