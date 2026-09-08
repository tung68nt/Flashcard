import SwiftUI
import AppKit
import Combine

// MARK: - NSColor Hex Extension
extension NSColor {
    convenience init?(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: clean).scanHexInt64(&int) else { return nil }
        let r, g, b: CGFloat
        switch clean.count {
        case 6:
            r = CGFloat((int >> 16) & 0xFF) / 255.0
            g = CGFloat((int >> 8) & 0xFF) / 255.0
            b = CGFloat(int & 0xFF) / 255.0
        default:
            return nil
        }
        self.init(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }
    
    var hexString: String {
        guard let srgb = usingColorSpace(.sRGB) else { return "#3B82F6" }
        let r = Int(round(srgb.redComponent * 255))
        let g = Int(round(srgb.greenComponent * 255))
        let b = Int(round(srgb.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Color Panel Manager (Docked Adjacent to App Window)
public final class ColorPanelManager: NSObject {
    public static let shared = ColorPanelManager()
    private var onColorChange: ((String) -> Void)?
    
    public func present(initialHex: String, onChange: @escaping (String) -> Void) {
        self.onColorChange = onChange
        let panel = NSColorPanel.shared
        panel.showsAlpha = false
        panel.isContinuous = true
        panel.setTarget(self)
        panel.setAction(#selector(colorPanelAction(_:)))
        
        if let nscolor = NSColor(hex: initialHex) {
            panel.color = nscolor
        }
        
        // Đặt vị trí cửa sổ chọn màu ngay sát cạnh cửa sổ chính của ứng dụng
        if let window = NSApp.keyWindow ?? NSApp.mainWindow {
            let winFrame = window.frame
            let panelSize = panel.frame.size
            
            // Ưu tiên đặt bên phải cửa sổ chính
            var targetX = winFrame.maxX + 12
            if let screen = window.screen ?? NSScreen.main {
                let screenFrame = screen.visibleFrame
                if targetX + panelSize.width > screenFrame.maxX {
                    // Nếu tràn màn hình bên phải thì đặt ngay bên trái cửa sổ chính
                    targetX = max(screenFrame.minX + 12, winFrame.minX - panelSize.width - 12)
                }
            }
            
            let targetY = max(window.screen?.visibleFrame.minY ?? 0, winFrame.maxY - panelSize.height)
            panel.setFrameOrigin(NSPoint(x: targetX, y: targetY))
        }
        
        panel.orderFront(nil)
    }
    
    @objc private func colorPanelAction(_ sender: NSColorPanel) {
        let hex = sender.color.hexString
        onColorChange?(hex)
    }
    
    public func close() {
        if NSColorPanel.sharedColorPanelExists {
            NSColorPanel.shared.close()
        }
        onColorChange = nil
    }
}

// MARK: - Observable State for Color Picker
final class ColorPickerState: ObservableObject {
    @Published var showCustomPopover: Bool = false
    @Published var hexInputText: String = ""
}

// MARK: - Deck Color Picker Row Component
public struct DeckColorPickerRow: View {
    @Binding var selectedHex: String
    @StateObject private var state = ColorPickerState()
    
    // 10 màu nhận diện tinh tế, hiện đại chuẩn Apple Design
    private let primaryPresets: [String] = [
        "#3B82F6", // Ocean Blue
        "#6366F1", // Indigo
        "#8B5CF6", // Purple
        "#EC4899", // Neon Pink
        "#EF4444", // Coral Red
        "#F97316", // Sunset Orange
        "#F59E0B", // Amber Gold
        "#10B981", // Emerald
        "#06B6D4", // Teal / Cyan
        "#64748B"  // Slate
    ]
    
    private let extendedPresets: [[String]] = [
        ["#EF4444", "#F87171", "#F97316", "#FB923C", "#F59E0B"],
        ["#10B981", "#34D399", "#06B6D4", "#22D3EE", "#3B82F6"],
        ["#6366F1", "#818CF8", "#8B5CF6", "#A78BFA", "#C084FC"],
        ["#EC4899", "#F472B6", "#FB7185", "#64748B", "#94A3B8"]
    ]
    
    public init(selectedHex: Binding<String>) {
        self._selectedHex = selectedHex
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            // 1. Dãy 10 màu preset chọn nhanh trực tiếp
            ForEach(primaryPresets, id: \.self) { hex in
                let isSelected = selectedHex.uppercased() == hex.uppercased()
                Button {
                    selectedHex = hex
                    ColorPanelManager.shared.close()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 22, height: 22)
                        
                        if isSelected {
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 20, height: 20)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.white)
                        }
                    }
                    .shadow(color: Color.black.opacity(isSelected ? 0.25 : 0.06), radius: isSelected ? 3 : 1, x: 0, y: 1)
                    .scaleEffect(isSelected ? 1.15 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
                }
                .buttonStyle(.plain)
                .help("Chọn màu \(hex)")
            }
            
            // 2. Nút mở Popover màu mở rộng & Tùy chỉnh
            Button {
                state.hexInputText = selectedHex
                state.showCustomPopover.toggle()
            } label: {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: selectedHex))
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
                    
                    Image(systemName: "paintpalette")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .help("Chọn màu tùy chỉnh hoặc bảng màu mở rộng")
            .popover(isPresented: $state.showCustomPopover, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 12) {
                    // Xem trước và nhập HEX trực tiếp
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: selectedHex))
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1.5))
                            .shadow(color: Color.black.opacity(0.15), radius: 2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mã màu HEX")
                                .font(.lexioCaptionMedium)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                TextField("#HEX", text: $state.hexInputText)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 11, design: .monospaced))
                                    .frame(width: 80)
                                
                                Button("OK") {
                                    var clean = state.hexInputText.trimmingCharacters(in: .whitespaces)
                                    if !clean.hasPrefix("#") {
                                        clean = "#" + clean
                                    }
                                    selectedHex = clean
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Lưới màu mở rộng
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Bảng màu phong phú")
                            .font(.lexioCaptionMedium)
                            .foregroundColor(.secondary)
                        
                        ForEach(0..<extendedPresets.count, id: \.self) { rowIndex in
                            HStack(spacing: 7) {
                                ForEach(extendedPresets[rowIndex], id: \.self) { hex in
                                    let isSel = selectedHex.uppercased() == hex.uppercased()
                                    Button {
                                        selectedHex = hex
                                        state.hexInputText = hex
                                    } label: {
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 20, height: 20)
                                            .overlay(
                                                Circle().stroke(Color.white, lineWidth: isSel ? 2 : 0)
                                            )
                                            .overlay(
                                                Group {
                                                    if isSel {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 8, weight: .bold))
                                                            .foregroundColor(.white)
                                                    }
                                                }
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Mở bảng màu macOS nhưng định vị ngay bên cạnh cửa sổ chính!
                    Button {
                        state.showCustomPopover = false
                        ColorPanelManager.shared.present(initialHex: selectedHex) { newHex in
                            selectedHex = newHex
                            state.hexInputText = newHex
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "slider.horizontal.3")
                            Text("Bảng màu macOS nâng cao...")
                            Spacer()
                        }
                        .font(.lexioCaptionMedium)
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                }
                .padding(14)
                .frame(width: 210)
            }
            
            Spacer()
        }
        .onDisappear {
            ColorPanelManager.shared.close()
        }
    }
}
