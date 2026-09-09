import SwiftUI
import AppKit

// MARK: - Apple macOS Human Interface Guidelines Material & Inset Grouped Styling

public extension Color {
    static var lexioCanvasBackground: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark 
                ? NSColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
                : NSColor(red: 0.942, green: 0.946, blue: 0.955, alpha: 1.0)
        }))
    }
    
    static var lexioCardBackground: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark 
                ? NSColor(red: 0.17, green: 0.17, blue: 0.185, alpha: 1.0)
                : NSColor.white
        }))
    }
}

public struct AppleInsetCardModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var isInteractive: Bool
    
    public init(cornerRadius: CGFloat = 10, isInteractive: Bool = false) {
        self.cornerRadius = cornerRadius
        self.isInteractive = isInteractive
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.lexioCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isInteractive ? 0.04 : 0.02), radius: isInteractive ? 3 : 1, x: 0, y: 1)
            .shadow(color: Color.black.opacity(isInteractive ? 0.06 : 0.03), radius: isInteractive ? 8 : 4, x: 0, y: isInteractive ? 3 : 2)
    }
}

public struct AppleStudyCardModifier: ViewModifier {
    public var cornerRadius: CGFloat
    
    public init(cornerRadius: CGFloat = 18) {
        self.cornerRadius = cornerRadius
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.lexioCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.09), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1.5)
            .shadow(color: Color.black.opacity(0.09), radius: 18, x: 0, y: 8)
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
                    .fill(isHighlighted ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.05))
            )
            .overlay(
                Capsule()
                    .stroke(isHighlighted ? Color.accentColor.opacity(0.25) : Color.primary.opacity(0.08), lineWidth: 0.5)
            )
    }
}

public extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 10, isInteractive: Bool = false) -> some View {
        self.modifier(AppleInsetCardModifier(cornerRadius: cornerRadius, isInteractive: isInteractive))
    }
    
    func appleStudyCard(cornerRadius: CGFloat = 18) -> some View {
        self.modifier(AppleStudyCardModifier(cornerRadius: cornerRadius))
    }
    
    func liquidGlassPill(isHighlighted: Bool = false) -> some View {
        self.modifier(ApplePillModifier(isHighlighted: isHighlighted))
    }
}
