import SwiftUI

public struct POSBadge: View {
    public let pos: String
    
    public init(_ pos: String) {
        self.pos = pos
    }
    
    private var cleanPOS: String {
        pos.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    private var badgeColor: Color {
        if cleanPOS.contains("idiom") || cleanPOS.contains("ngữ") {
            return Color(hex: "#FF9500") // Cam: Idiom / Thành ngữ
        } else if cleanPOS.contains("phras") || cleanPOS.contains("colloc") || cleanPOS.contains("cụm") {
            return Color(hex: "#00C7BE") // Teal: Phrasal verb / Collocation
        } else if cleanPOS.contains("verb") || cleanPOS.contains("động") {
            return Color(hex: "#0A84FF") // Xanh dương: Động từ
        } else if cleanPOS.contains("noun") || cleanPOS.contains("danh") {
            return Color(hex: "#34C759") // Xanh lá: Danh từ
        } else if cleanPOS.contains("adj") || cleanPOS.contains("tính") {
            return Color(hex: "#AF52DE") // Tím: Tính từ
        } else if cleanPOS.contains("adv") || cleanPOS.contains("trạng") {
            return Color(hex: "#5856D6") // Indigo: Trạng từ
        } else if cleanPOS.contains("gram") || cleanPOS.contains("struc") || cleanPOS.contains("pháp") || cleanPOS.contains("trúc") {
            return Color(hex: "#FF2D55") // Hồng: Cấu trúc ngữ pháp
        }
        return Color.secondary
    }
    
    public var body: some View {
        Text(pos)
            .font(.system(size: 10.5, weight: .semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 2.5)
            .background(badgeColor.opacity(0.12))
            .foregroundColor(badgeColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(badgeColor.opacity(0.35), lineWidth: 0.6)
            )
    }
}
