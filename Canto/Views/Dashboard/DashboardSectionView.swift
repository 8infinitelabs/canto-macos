import SwiftUI

struct DashboardSectionView: View {
    let section: ClaudeMDSection
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let heading = section.heading {
                Button {
                    withAnimation(CantoAnimations.quick) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(heading)
                            .font(CantoTypography.displaySmall)
                            .foregroundStyle(CantoColors.textPrimary)
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(CantoColors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                if !section.prose.isEmpty {
                    Text(section.prose)
                        .font(CantoTypography.body)
                        .foregroundStyle(CantoColors.textPrimary.opacity(0.9))
                        .textSelection(.enabled)
                }

                if !section.rules.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(section.rules) { rule in
                            RuleCardView(rule: rule)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(CantoColors.surface)
        .cornerRadius(12)
    }
}
