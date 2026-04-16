import SwiftUI

struct CodePreviewView: View {
    let url: URL
    @State private var content = ""

    var body: some View {
        ScrollView {
            Text(content)
                .font(CantoTypography.code)
                .foregroundStyle(CantoColors.textPrimary)
                .textSelection(.enabled)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(CantoColors.background)
        .onAppear {
            content = (try? String(contentsOf: url, encoding: .utf8)) ?? "Unable to read file"
        }
    }
}
