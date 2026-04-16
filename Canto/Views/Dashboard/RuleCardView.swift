import SwiftUI

struct RuleCardView: View {
    let rule: ClaudeMDSection.RuleItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(CantoColors.accent)
                .padding(.top, 2)
            Text(rule.text)
                .font(CantoTypography.body)
                .foregroundStyle(CantoColors.textPrimary)
                .textSelection(.enabled)
            Spacer()
        }
        .padding(12)
        .background(CantoColors.background)
        .cornerRadius(8)
    }
}
