import SwiftUI

// MARK: - Apple macOS Human Interface Typography System
// Giới hạn số lượng cấp font, kiểm soát độ đậm nhạt (weight) và loại bỏ hoàn toàn các cỡ font tùy tiện lẻ tẻ.

public extension Font {
    /// 28pt Bold — Dành riêng cho chữ lớn trên thẻ Flashcard chính (Display)
    static let lexioDisplay = Font.system(size: 28, weight: .bold)
    
    /// 20pt Bold — Tiêu đề màn hình chính, tiêu đề bộ thẻ chi tiết (Screen Title)
    static let lexioTitle = Font.system(size: 20, weight: .bold)
    
    /// 14pt Semibold — Tiêu đề các phân nhóm, section header ("Chế Độ Học", "Thư Viện")
    static let lexioSection = Font.system(size: 14, weight: .semibold)
    
    /// 13pt Semibold — Tên thẻ trong danh sách, tiêu đề ô chế độ học, từ vựng chính
    static let lexioHeadline = Font.system(size: 13, weight: .semibold)
    
    /// 13pt Regular — Nội dung văn bản chính, định nghĩa, ô nhập liệu tìm kiếm
    static let lexioBody = Font.system(size: 13, weight: .regular)
    
    /// 11pt Regular — Văn bản phụ, mô tả ngắn, số đếm, nhãn thời gian (Secondary Metadata)
    static let lexioCaption = Font.system(size: 11, weight: .regular)
    
    /// 11pt Medium / Semibold — Huy hiệu đếm thẻ, nhãn phân loại (Capsule Badges)
    static let lexioCaptionMedium = Font.system(size: 11, weight: .medium)
    static let lexioCaptionSemibold = Font.system(size: 11, weight: .semibold)
}
