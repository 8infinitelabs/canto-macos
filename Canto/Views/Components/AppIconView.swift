import SwiftUI

struct AppIconView: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                // Gradient background (like the Ca version)
                RoundedRectangle(cornerRadius: s * 0.22)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#8B5CF6"), Color(hex: "#E06C54")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // White C with inner gradient/relief
                Text("C")
                    .font(.system(size: s * 0.55, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: s * 0.02, y: s * 0.015)
                    .overlay(
                        Text("C")
                            .font(.system(size: s * 0.55, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white.opacity(0.9), .white.opacity(0.5)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            }
        }
    }
}
