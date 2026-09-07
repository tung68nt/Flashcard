export type PartOfSpeech = 
  | 'noun' 
  | 'verb' 
  | 'adjective' 
  | 'adverb' 
  | 'idiom' 
  | 'phrasal verb' 
  | 'preposition' 
  | 'conjunction' 
  | 'grammar structure'
  | 'other';

export interface Flashcard {
  id: string;
  term: string;                      // Từ vựng hoặc Cụm từ/Cấu trúc
  phonetic?: string;                  // Phiên âm IPA (VD: /prəˈfɪʃ.ənt/)
  partOfSpeech?: string;              // Từ loại (VD: adj, v, n, idiom...)
  definition: string;                // Định nghĩa / Nghĩa tiếng Việt
  example?: string;                   // Câu ví dụ minh hoạ
  exampleTranslation?: string;        // Dịch nghĩa câu ví dụ
  grammarPattern?: string;            // Cấu trúc/Mẫu ngữ pháp (VD: proficient in/at sth)
  notes?: string;                     // Ghi chú, mẹo nhớ (mnemonics), từ đồng nghĩa/trái nghĩa
  tags?: string[];                    // Nhãn phân loại (C1, IELTS, Topic, etc.)
  starred?: boolean;                  // Đánh dấu yêu thích / cần chú ý

  // Dữ liệu thuật toán SRS (Spaced Repetition - SM2)
  repetition: number;                 // Số lần ôn tập thành công liên tiếp
  interval: number;                   // Khoảng cách ngày ôn tập tiếp theo
  easeFactor: number;                 // Hệ số độ khó (mặc định 2.5)
  dueDate: string;                    // Ngày cần ôn tập tiếp theo (ISO string)
  lastReviewed?: string;              // Ngày ôn tập gần nhất
  reviewCount: number;                // Tổng số lần đã học
  lapses: number;                     // Số lần quên (nhấn Again)
}

export interface Deck {
  id: string;
  title: string;
  description: string;
  language: string;                   // 'en-US' | 'en-GB' | 'ja-JP' | 'zh-CN' | 'ko-KR' | 'fr-FR' | etc.
  targetLanguage: string;             // 'vi-VN'
  category?: string;
  tags: string[];
  cards: Flashcard[];
  createdAt: string;
  updatedAt: string;
  color?: string;                     // Accent color theme cho bộ thẻ
}

export type StudyMode = 'flashcards' | 'srs' | 'write' | 'match' | 'test';

export type SRSRating = 1 | 2 | 3 | 4; // 1: Again (Quên), 2: Hard (Khó), 3: Good (Tốt), 4: Easy (Dễ)

export interface ColumnMapping {
  term: string;
  phonetic: string;
  partOfSpeech: string;
  definition: string;
  example: string;
  exampleTranslation: string;
  grammarPattern: string;
  notes: string;
  tags: string;
}

export interface TestResult {
  total: number;
  correct: number;
  incorrect: number;
  percentage: number;
  timeSpentSeconds: number;
  answers: {
    cardId: string;
    term: string;
    userAnswer: string;
    correctAnswer: string;
    isCorrect: boolean;
    type: 'multiple-choice' | 'written' | 'true-false';
  }[];
}
