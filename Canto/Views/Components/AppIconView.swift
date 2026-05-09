import SwiftUI

/// In-app rendering of the Canto icon — used in welcome screen.
/// Pulls directly from the AppIcon asset for pixel-perfect consistency.
struct AppIconView: View {
    var body: some View {
        if let nsImage = NSImage(named: "AppIcon") {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            // Fallback: vector reproduction
            CantoIconShape()
        }
    }
}

/// Vector reproduction of the Canto icon for use as fallback.
private struct CantoIconShape: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: s * 0.22)
                    .fill(
                        LinearGradient(
                            colors: [.white, Color(hex: "#EFEAFB")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                let barColor = LinearGradient(
                    colors: [Color(hex: "#5B21B6"), Color(hex: "#8B5CF6")],
                    startPoint: .leading, endPoint: .trailing
                )
                let lineColor = LinearGradient(
                    colors: [Color(hex: "#A78BFA"), Color(hex: "#DDD6FE")],
                    startPoint: .leading, endPoint: .trailing
                )
                let bar = s * 0.07
                let inset = s * 0.235
                let cWidth = s - inset * 2

                // Top arm
                RoundedRectangle(cornerRadius: bar / 2)
                    .fill(barColor)
                    .frame(width: cWidth, height: bar)
                    .offset(y: -(s / 2 - inset - bar / 2))

                // Left vertical
                RoundedRectangle(cornerRadius: bar / 2)
                    .fill(barColor)
                    .frame(width: bar, height: cWidth)
                    .offset(x: -(s / 2 - inset - bar / 2))

                // Bottom arm
                RoundedRectangle(cornerRadius: bar / 2)
                    .fill(barColor)
                    .frame(width: cWidth, height: bar)
                    .offset(y: (s / 2 - inset - bar / 2))

                // Inner markdown lines stack
                VStack(alignment: .leading, spacing: s * 0.025) {
                    RoundedRectangle(cornerRadius: s * 0.014)
                        .fill(lineColor)
                        .frame(width: s * 0.31, height: s * 0.027)
                    RoundedRectangle(cornerRadius: s * 0.011)
                        .fill(lineColor.opacity(0.85))
                        .frame(width: s * 0.38, height: s * 0.022)
                    RoundedRectangle(cornerRadius: s * 0.011)
                        .fill(lineColor.opacity(0.85))
                        .frame(width: s * 0.30, height: s * 0.022)
                    HStack(spacing: s * 0.022) {
                        Circle()
                            .fill(lineColor.opacity(0.7))
                            .frame(width: s * 0.018, height: s * 0.018)
                        RoundedRectangle(cornerRadius: s * 0.011)
                            .fill(lineColor.opacity(0.7))
                            .frame(width: s * 0.21, height: s * 0.022)
                    }
                }
                .offset(x: s * 0.075, y: s * 0.018)
            }
        }
    }
}
