import SwiftUI

struct SkillRow: View {
    let skill: SkillConfig

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(skill.name)
                    .font(CantoTypography.sidebarBold)
                    .foregroundStyle(CantoColors.textPrimary)
                Text(skill.description)
                    .font(CantoTypography.uiSmall)
                    .foregroundStyle(CantoColors.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
            Text(skill.source)
                .font(CantoTypography.uiSmall)
                .foregroundStyle(CantoColors.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(CantoColors.surface)
                .cornerRadius(4)
        }
        .padding(12)
        .background(CantoColors.surface)
        .cornerRadius(8)
    }
}
