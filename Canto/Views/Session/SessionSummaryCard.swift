import SwiftUI

struct SessionSummaryCard: View {
    let session: SessionRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(session.name)
                    .font(CantoTypography.displaySmall)
                    .foregroundStyle(CantoColors.textPrimary)
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(session.status == .active ? CantoColors.sessionActive : CantoColors.sessionDone)
                        .frame(width: 8, height: 8)
                    Text(session.status == .active ? "Active" : "Completed")
                        .font(CantoTypography.uiSmall)
                        .foregroundStyle(session.status == .active ? CantoColors.sessionActive : CantoColors.sessionDone)
                }
            }

            HStack(spacing: 24) {
                StatItem(label: "Files created", value: "\(session.stats.filesCreated)")
                StatItem(label: "Files modified", value: "\(session.stats.filesModified)")
                StatItem(label: "Commits", value: "\(session.stats.commits)")
                StatItem(label: "Insertions", value: "+\(session.stats.totalInsertions)")
                StatItem(label: "Deletions", value: "-\(session.stats.totalDeletions)")
                StatItem(label: "Memories", value: "\(session.stats.memoriesAdded)")
            }

            HStack {
                Text("Started \(session.startedAt, style: .relative)")
                    .font(CantoTypography.uiSmall)
                    .foregroundStyle(CantoColors.textSecondary)
                if let ended = session.endedAt {
                    Text("Ended \(ended, style: .relative)")
                        .font(CantoTypography.uiSmall)
                        .foregroundStyle(CantoColors.textSecondary)
                }
            }
        }
        .padding(20)
        .background(CantoColors.surface)
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(CantoTypography.sidebarBold)
                .foregroundStyle(CantoColors.textPrimary)
            Text(label)
                .font(CantoTypography.uiSmall)
                .foregroundStyle(CantoColors.textSecondary)
        }
    }
}
