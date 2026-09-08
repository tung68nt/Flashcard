import Foundation

public struct SRSEngine {
    /// Tính toán chu kỳ Spaced Repetition theo SuperMemo-2 (SM-2) cải tiến
    public static func calculate(card: Flashcard, rating: SRSRating) -> Flashcard {
        var updated = card
        var repetition = card.repetition
        var interval = card.interval
        var easeFactor = card.easeFactor
        var lapses = card.lapses
        let now = Date()
        
        let grade: Double = {
            switch rating {
            case .again: return 1.0
            case .hard: return 3.0
            case .good: return 4.0
            case .easy: return 5.0
            }
        }()
        
        if rating == .again {
            repetition = 0
            interval = 1
            lapses += 1
        } else {
            if repetition == 0 {
                interval = (rating == .easy) ? 3 : 1
            } else if repetition == 1 {
                interval = (rating == .hard) ? 2 : ((rating == .easy) ? 6 : 3)
            } else {
                if rating == .hard {
                    interval = max(1, Int(round(Double(interval) * 1.2)))
                } else if rating == .good {
                    interval = Int(round(Double(interval) * easeFactor))
                } else {
                    // Easy: thưởng thêm 30% khoảng cách
                    interval = Int(round(Double(interval) * easeFactor * 1.3))
                }
            }
            repetition += 1
        }
        
        // Cập nhật Ease Factor
        easeFactor = easeFactor + (0.1 - (5.0 - grade) * (0.08 + (5.0 - grade) * 0.02))
        if easeFactor < 1.3 {
            easeFactor = 1.3
        }
        
        let nextDueDate = Calendar.current.date(byAdding: .day, value: interval, to: now) ?? now
        
        updated.repetition = repetition
        updated.interval = interval
        updated.easeFactor = round(easeFactor * 100) / 100.0
        updated.dueDate = nextDueDate
        updated.lastReviewed = now
        updated.reviewCount += 1
        updated.lapses = lapses
        
        return updated
    }
}
