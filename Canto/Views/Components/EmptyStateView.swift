import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(CantoColors.textSecondary.opacity(0.5))
            Text(title)
                .font(CantoTypography.body)
                .foregroundStyle(CantoColors.textSecondary)
            Text(subtitle)
                .font(CantoTypography.bodySmall)
                .foregroundStyle(CantoColors.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CantoColors.background)
    }
}
