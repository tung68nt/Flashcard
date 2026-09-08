import SwiftUI
import AppKit

// MARK: - Liquid Glass View Modifiers for macOS

public struct LiquidGlassCardModifier: ViewModifier {
    public var cornerRadius: CGFloat
    
    public init(cornerRadius: CGFloat = 16) {
        self.cornerRadius = cornerRadius
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.28),
                                Color.white.opacity(0.08),
                                Color.black.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(0.07),
                radius: 10,
                x: 0,
                y: 4
            )
    }
}

public struct LiquidGlassPillModifier: ViewModifier {
    public var isHighlighted: Bool
    
    public init(isHighlighted: Bool = false) {
        self.isHighlighted = isHighlighted
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 4.5)
            .background(
                Capsule()
                    .fill(isHighlighted ? AnyShapeStyle(Color.accentColor.opacity(0.16)) : AnyShapeStyle(.thinMaterial))
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isHighlighted ? 0.4 : 0.25),
                                Color.white.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
    }
}

public extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 16, isInteractive: Bool = false) -> some View {
        self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius))
    }
    
    func liquidGlassPill(isHighlighted: Bool = false) -> some View {
        self.modifier(LiquidGlassPillModifier(isHighlighted: isHighlighted))
    }
}
