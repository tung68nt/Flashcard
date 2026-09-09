import SwiftUI
import AppKit

// MARK: - Apple macOS Human Interface Guidelines Material & Inset Grouped Styling

public struct AppleInsetCardModifier: ViewModifier {
    public var cornerRadius: CGFloat
    
    public init(cornerRadius: CGFloat = 10) {
        self.cornerRadius = cornerRadius
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color(NSColor.separatorColor).opacity(0.6), lineWidth: 0.5)
            )
    }
}

public struct ApplePillModifier: ViewModifier {
    public var isHighlighted: Bool
    
    public init(isHighlighted: Bool = false) {
        self.isHighlighted = isHighlighted
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, 9)
            .padding(.vertical, 3.5)
            .background(
                Capsule()
                    .fill(isHighlighted ? Color.accentColor.opacity(0.12) : Color(NSColor.quaternaryLabelColor).opacity(0.15))
            )
            .overlay(
                Capsule()
                    .stroke(isHighlighted ? Color.accentColor.opacity(0.25) : Color(NSColor.separatorColor).opacity(0.4), lineWidth: 0.5)
            )
    }
}

public extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 10, isInteractive: Bool = false) -> some View {
        self.modifier(AppleInsetCardModifier(cornerRadius: cornerRadius))
    }
    
    func liquidGlassPill(isHighlighted: Bool = false) -> some View {
        self.modifier(ApplePillModifier(isHighlighted: isHighlighted))
    }
}
