import SwiftUI

struct TimelineEventRow: View {
    let event: SessionEvent
    let isCompact: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline dot + line
            VStack(spacing: 0) {
                Circle()
                    .fill(colorForType)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(CantoColors.textSecondary.opacity(0.2))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 10)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: iconForType)
                        .font(.system(size: 12))
                        .foregroundStyle(colorForType)
                    Text(labelForType)
                        .font(CantoTypography.sidebarBold)
                        .foregroundStyle(CantoColors.textPrimary)
                    Spacer()
                    Text(event.timestamp, style: .time)
                        .font(CantoTypography.uiSmall)
                        .foregroundStyle(CantoColors.textSecondary)
                }

                if !isCompact {
                    if let path = event.path {
                        Text(path)
                            .font(CantoTypography.code)
                            .foregroundStyle(CantoColors.textSecondary)
                            .lineLimit(1)
                    }
                    if let message = event.commitMessage {
                        Text(message)
                            .font(CantoTypography.bodySmall)
                            .foregroundStyle(CantoColors.textPrimary)
                    }
                    if let files = event.filesChanged {
                        Text("\(files) files, +\(event.insertions ?? 0) -\(event.deletions ?? 0)")
                            .font(CantoTypography.uiSmall)
                            .foregroundStyle(CantoColors.textSecondary)
                    }
                }
            }
        }
        .padding(.vertical, isCompact ? 2 : 6)
    }

    private var iconForType: String {
        switch event.type {
        case .sessionStart: return "play.circle"
        case .fileCreated: return "doc.badge.plus"
        case .fileModified: return "pencil"
        case .fileDeleted: return "trash"
        case .commit: return "arrow.triangle.branch"
        case .memoryCreated: return "brain"
        case .memoryUpdated: return "brain"
        case .planCreated: return "list.bullet.clipboard"
        }
    }

    private var labelForType: String {
        switch event.type {
        case .sessionStart: return "Session started"
        case .fileCreated: return "File created"
        case .fileModified: return "File modified"
        case .fileDeleted: return "File deleted"
        case .commit: return "Commit"
        case .memoryCreated: return "Memory created"
        case .memoryUpdated: return "Memory updated"
        case .planCreated: return "Plan created"
        }
    }

    private var colorForType: Color {
        switch event.type {
        case .sessionStart: return CantoColors.sessionActive
        case .fileCreated: return CantoColors.sessionDone
        case .fileModified: return CantoColors.accent
        case .fileDeleted: return CantoColors.sessionError
        case .commit: return CantoColors.memoryFeedback
        case .memoryCreated, .memoryUpdated: return CantoColors.memoryUser
        case .planCreated: return CantoColors.memoryProject
        }
    }
}
