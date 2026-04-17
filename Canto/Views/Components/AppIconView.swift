import SwiftUI

struct AppIconView: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: s * 0.22)
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color(hex: "#F5F5F7")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: s * 0.22)
                            .strokeBorder(Color.black.opacity(0.06), lineWidth: s * 0.004)
                    )

                Text("C")
                    .font(.system(size: s * 0.58, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#D67059"), Color(hex: "#BF5B45")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
    }
}
