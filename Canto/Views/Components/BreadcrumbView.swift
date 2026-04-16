import SwiftUI

struct BreadcrumbView: View {
    let path: String
    let projectRoot: String

    var body: some View {
        let relativePath = path.replacingOccurrences(of: projectRoot + "/", with: "")
        let components = relativePath.components(separatedBy: "/")

        HStack(spacing: 4) {
            ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                if index > 0 {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9))
                        .foregroundStyle(CantoColors.textSecondary)
                }
                Text(component)
                    .font(CantoTypography.uiSmall)
                    .foregroundStyle(index == components.count - 1 ? CantoColors.textPrimary : CantoColors.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(CantoColors.surface.opacity(0.5))
    }
}
