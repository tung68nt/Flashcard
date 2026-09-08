import SwiftUI
import AppKit

public struct UpdateSheetView: View {
    @ObservedObject private var updateService = UpdateService.shared
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header with App Icon
            HStack(spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Cập Nhật Lexio PRO")
                        .font(.lexioTitle)
                        .foregroundColor(.primary)
                    
                    Text("Phiên bản hiện tại: v\(updateService.currentVersion)")
                        .font(.lexioCaptionMedium)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Content area based on State (fixed height prevents window jitter/flicker)
            Group {
                switch updateService.state {
                case .idle, .checking:
                    VStack(spacing: 14) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Đang kiểm tra bản cập nhật mới nhất...")
                            .font(.lexioBody)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                case .upToDate(let version):
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 44))
                            .foregroundColor(Color(hex: "#34C759"))
                        
                        Text("Bạn đang dùng phiên bản mới nhất")
                            .font(.lexioHeadline)
                            .foregroundColor(.primary)
                        
                        Text("Lexio PRO v\(version) hiện là phiên bản mới và ổn định nhất.")
                            .font(.lexioCaption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                case .available(let info):
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(info.title ?? "Đã có bản cập nhật mới!")
                                    .font(.lexioHeadline)
                                    .foregroundColor(.primary)
                                
                                Text("Phiên bản v\(info.version) • \(info.releaseDate ?? "")")
                                    .font(.lexioCaptionMedium)
                                    .foregroundColor(.accentColor)
                            }
                            
                            Spacer()
                            
                            Text("BẢN MỚI")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.accentColor.opacity(0.12))
                                .foregroundColor(.accentColor)
                                .clipShape(Capsule())
                        }
                        
                        if let notes = info.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Những cải tiến mới:")
                                    .font(.lexioCaptionMedium)
                                    .foregroundColor(.secondary)
                                
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 6) {
                                        ForEach(notes, id: \.self) { note in
                                            HStack(alignment: .top, spacing: 8) {
                                                Image(systemName: "sparkles")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.accentColor)
                                                    .padding(.top, 2)
                                                Text(note)
                                                    .font(.lexioCaption)
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                    }
                                    .padding(10)
                                }
                                .frame(maxHeight: 120)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(NSColor.separatorColor).opacity(0.6), lineWidth: 0.8)
                                )
                            }
                        }
                    }
                    
                case .downloading(let progress):
                    VStack(spacing: 12) {
                        ProgressView(value: progress, total: 1.0)
                            .progressViewStyle(.linear)
                        
                        HStack {
                            Text("Đang tải bộ cài đặt DMG...")
                                .font(.lexioCaption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(.lexioCaptionMedium)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.vertical, 24)
                    
                case .downloaded(let fileURL):
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(Color(hex: "#0A84FF"))
                        
                        Text("Đã tải xong tệp cài đặt!")
                            .font(.lexioHeadline)
                        
                        Text("Bộ cài đặt DMG đã được lưu tại thư mục Downloads và đang được mở tự động để bạn cập nhật.")
                            .font(.lexioCaption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Mở lại file DMG") {
                            NSWorkspace.shared.open(fileURL)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 16)
                    
                case .error(let msg):
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color(hex: "#FF9F0A"))
                        
                        Text("Thông Báo Cập Nhật")
                            .font(.lexioHeadline)
                        
                        Text(msg)
                            .font(.lexioCaption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 16)
                }
            }
            .frame(minHeight: 125)
            
            Divider()
            
            // Action Buttons
            HStack {
                Button("Đóng") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                switch updateService.state {
                case .idle, .checking:
                    Button(action: {}) {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Đang kiểm tra...")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(true)
                    
                case .upToDate:
                    Button("Kiểm Tra Lại") {
                        updateService.checkForUpdates()
                    }
                    .buttonStyle(.bordered)
                    
                case .available(let info):
                    Button("Xem Trên Web") {
                        updateService.openReleasePage(info: info)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Tải & Cài Đặt (.dmg)") {
                        updateService.downloadAndInstall(info: info)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    
                case .downloading:
                    Button("Hủy Tải") {
                        updateService.state = .idle
                    }
                    .buttonStyle(.bordered)
                    
                case .downloaded:
                    Button("Hoàn Tất") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    
                case .error:
                    Button("Thử Lại") {
                        updateService.checkForUpdates()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .frame(width: 460)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
