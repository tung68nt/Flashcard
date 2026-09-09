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

// MARK: - Apple macOS Liquid Glass Icon Badge (Chuẩn Guideline Apple - Không dùng Neon Glow)
public struct LiquidGlassIconBadge: View {
    public let icon: String
    public let tintColor: Color
    public var size: CGFloat
    public var iconSize: CGFloat
    public var cornerRadius: CGFloat
    
    public init(
        icon: String,
        tintColor: Color,
        size: CGFloat = 36,
        iconSize: CGFloat = 16,
        cornerRadius: CGFloat = 10
    ) {
        self.icon = icon
        self.tintColor = tintColor
        self.size = size
        self.iconSize = iconSize
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        ZStack {
            // 1. Translucent Tinted Glass Base (Kính lỏng trong suốt mang sắc thái màu)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(tintColor.opacity(0.12))
            
            // 2. Specular Gloss Reflection (Ánh khúc xạ bề mặt kính lỏng)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.48),
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // 3. Crisp Glass Bevel Border (Đường vát kính phản chiếu)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.75),
                            tintColor.opacity(0.25),
                            Color.white.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
            
            // 4. Vibrant SF Symbol (Biểu tượng sắc nét chuẩn tương phản Apple)
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundColor(tintColor)
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
    }
}

