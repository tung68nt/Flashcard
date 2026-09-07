import { Flashcard, SRSRating } from '../types/flashcard';

/**
 * Thuật toán SuperMemo-2 (SM-2) cải tiến cho Spaced Repetition (Lặp lại ngắt quãng)
 * Tự động tính toán chu kỳ ôn tập tối ưu để chống quên (Forgetting Curve của Ebbinghaus)
 */
export function calculateSRS(card: Flashcard, rating: SRSRating): Partial<Flashcard> {
  let { repetition, interval, easeFactor, lapses } = card;
  const now = new Date();

  // Mapping rating (1: Again, 2: Hard, 3: Good, 4: Easy) sang thang điểm SM-2 (0-5)
  // 1 -> grade 1 (quên hoàn toàn)
  // 2 -> grade 3 (nhớ nhưng rất vất vả)
  // 3 -> grade 4 (nhớ tốt sau một chút suy nghĩ)
  // 4 -> grade 5 (nhớ ngay lập tức, hoàn hảo)
  const grade = rating === 1 ? 1 : rating === 2 ? 3 : rating === 3 ? 4 : 5;

  if (rating === 1) {
    // Quên từ -> reset repetition về 0, ôn lại sau 1 ngày (hoặc ngay trong phiên)
    repetition = 0;
    interval = 1;
    lapses += 1;
  } else {
    // Nhớ được từ
    if (repetition === 0) {
      interval = rating === 4 ? 3 : 1;
    } else if (repetition === 1) {
      interval = rating === 2 ? 2 : rating === 4 ? 6 : 3;
    } else {
      if (rating === 2) {
        interval = Math.max(1, Math.round(interval * 1.2));
      } else if (rating === 3) {
        interval = Math.round(interval * easeFactor);
      } else {
        // Easy: thưởng thêm hệ số 1.3
        interval = Math.round(interval * easeFactor * 1.3);
      }
    }
    repetition += 1;
  }

  // Cập nhật Ease Factor (EF)
  // EF' = EF + (0.1 - (5 - grade) * (0.08 + (5 - grade) * 0.02))
  easeFactor = easeFactor + (0.1 - (5 - grade) * (0.08 + (5 - grade) * 0.02));
  if (easeFactor < 1.3) easeFactor = 1.3; // Giới hạn sàn tối thiểu

  // Tính ngày cần ôn tập tiếp theo
  const nextDueDate = new Date();
  nextDueDate.setDate(now.getDate() + interval);

  return {
    repetition,
    interval,
    easeFactor: Math.round(easeFactor * 100) / 100,
    dueDate: nextDueDate.toISOString(),
    lastReviewed: now.toISOString(),
    reviewCount: (card.reviewCount || 0) + 1,
    lapses,
  };
}

/**
 * Kiểm tra xem thẻ đã đến hạn cần ôn tập hay chưa
 */
export function isCardDue(card: Flashcard): boolean {
  if (!card.dueDate) return true;
  const due = new Date(card.dueDate);
  const now = new Date();
  return due.getTime() <= now.getTime();
}

/**
 * Lấy danh sách thẻ cần ôn tập hôm nay
 */
export function getDueCards(cards: Flashcard[]): Flashcard[] {
  return cards.filter(isCardDue);
}
