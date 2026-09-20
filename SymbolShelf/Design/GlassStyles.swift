import SwiftUI

extension View {
    @ViewBuilder
    func adaptiveGlass(cornerRadius: CGFloat = 24, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            if interactive {
                self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
            } else {
                self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 0.5)
                }
        }
    }
}

struct AmbientBackground: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
            Circle()
                .fill(.blue.opacity(0.18))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: -160, y: -300)
            Circle()
                .fill(.purple.opacity(0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: 180, y: 250)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
