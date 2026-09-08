import Foundation
import SwiftUI

public enum StudyMode: String, CaseIterable, Identifiable {
    case flashcards = "Flashcards"
    case srs = "Spaced Repetition (SM-2)"
    case write = "Write & Recall"
    case match = "Speed Match Game"
    case test = "Practice Test"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .flashcards: return "rectangle.portrait.on.rectangle.portrait.angled.fill"
        case .srs: return "brain.head.profile"
        case .write: return "square.and.pencil"
        case .match: return "bolt.fill"
        case .test: return "checkmark.seal.fill"
        }
    }
    
    public var description: String {
        switch self {
        case .flashcards: return "Lật thẻ trực quan 3D với phiên âm IPA và ví dụ ngữ cảnh"
        case .srs: return "Học theo thuật toán chống quên Ebbinghaus (Again, Hard, Good, Easy)"
        case .write: return "Luyện gõ từ vựng, kiểm tra chính tả và phản xạ tức thì"
        case .match: return "Nối từ nhanh với định nghĩa trong thời gian ngắn nhất"
        case .test: return "Bài thi trắc nghiệm khách quan và đánh giá mức độ thuần thục"
        }
    }
    
    public var tintColor: Color {
        switch self {
        case .flashcards: return Color(red: 1.0, green: 0.34, blue: 0.2) // Coral
        case .srs: return Color(red: 1.0, green: 0.16, blue: 0.43)       // Pink Electric
        case .write: return Color(red: 0.02, green: 0.71, blue: 0.83)    // Cyan
        case .match: return Color(red: 0.96, green: 0.62, blue: 0.04)    // Amber
        case .test: return Color(red: 0.06, green: 0.73, blue: 0.51)     // Emerald
        }
    }
}

public enum SRSRating: Int, CaseIterable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4
    
    public var label: String {
        switch self {
        case .again: return "Again"
        case .hard: return "Hard"
        case .good: return "Good"
        case .easy: return "Easy"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .again: return "< 1 ngày"
        case .hard: return "1-2 ngày"
        case .good: return "3-5 ngày"
        case .easy: return "6+ ngày"
        }
    }
    
    public var color: Color {
        switch self {
        case .again: return Color.red
        case .hard: return Color.orange
        case .good: return Color.blue
        case .easy: return Color.green
        }
    }
}
