import SwiftUI

extension View {
    @ViewBuilder
    func symbolRenderingStyle(_ settings: ExportSettings) -> some View {
        switch settings.renderingStyle {
        case .monochrome:
            self
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(settings.tint.color)
        case .hierarchical:
            self
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(settings.tint.color)
        case .palette:
            self
                .symbolRenderingMode(.palette)
                .foregroundStyle(settings.tint.color, settings.secondaryTint.color)
        case .multicolor:
            self.symbolRenderingMode(.multicolor)
        }
    }

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
                        .stroke(.primary.opacity(0.14), lineWidth: 0.5)
                }
        }
    }

    @ViewBuilder
    func nativeTabBarBehavior() -> some View {
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }

    @ViewBuilder
    func adaptiveTabAccessory<Content: View>(
        isEnabled: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if #available(iOS 26.1, *) {
            self.tabViewBottomAccessory(isEnabled: isEnabled) {
                content()
            }
        } else {
            self.safeAreaInset(edge: .bottom) {
                if isEnabled {
                    content()
                        .background(.ultraThinMaterial)
                }
            }
        }
    }
}

struct AmbientBackground: View {
    var body: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}
