import SwiftUI

public struct CardRowView: View {
    public let card: Flashcard
    public let language: String
    public var onToggleStar: () -> Void
    public var onDelete: () -> Void
    
    public init(
        card: Flashcard,
        language: String = "en-US",
        onToggleStar: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.card = card
        self.language = language
        self.onToggleStar = onToggleStar
        self.onDelete = onDelete
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Core Word & Definition
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .center, spacing: 8) {
                    Text(card.term)
                        .font(.lexioHeadline)
                        .foregroundColor(.primary)
                    
                    if let phonetic = card.phonetic, !phonetic.isEmpty {
                        Text(phonetic)
                            .font(.lexioCaption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Nút phát âm chuẩn từ điển Oxford / Cambridge: UK 🇬🇧 & US 🇺🇸
                    DualAudioButton(term: card.term)
                    
                    if let pos = card.partOfSpeech, !pos.isEmpty {
                        POSBadge(pos)
                    }
                    
                    Spacer()
                    
                    // Star button
                    Button(action: onToggleStar) {
                        Image(systemName: card.starred ? "star.fill" : "star")
                            .font(.lexioHeadline)
                            .foregroundColor(card.starred ? .yellow : .secondary.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    
                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.lexioHeadline)
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Xóa thẻ này")
                }
                
                Text(card.definition)
                    .font(.lexioBody)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                
                // Cấu trúc ngữ pháp / Phrasal pattern
                if let grammar = card.grammarPattern, !grammar.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(Color(hex: "#FF2D55"))
                        Text(grammar)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(hex: "#FF2D55"))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#FF2D55").opacity(0.08))
                    .cornerRadius(5)
                }
                
                // Câu ví dụ kèm phát âm câu chuẩn bản xứ
                if let example = card.example, !example.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Button {
                            SpeechService.shared.speak(text: example, language: language)
                        } label: {
                            Image(systemName: "speaker.wave.2")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.accentColor)
                                .padding(5)
                                .background(Color.accentColor.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .help("Nghe phát âm chuẩn cả câu ví dụ")
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(example)
                                .font(.lexioCaption)
                                .foregroundColor(.primary)
                            
                            if let trans = card.exampleTranslation, !trans.isEmpty {
                                Text(trans)
                                    .font(.lexioCaption)
                                    .foregroundColor(.secondary.opacity(0.85))
                            }
                        }
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(6)
                }
                
                // Ghi chú / Mẹo nhớ
                if let notes = card.notes, !notes.isEmpty {
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#FF9500"))
                            .padding(.top, 2)
                        Text(notes)
                            .font(.lexioCaption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Tags
                if !card.tags.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(card.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.lexioCaption)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Color.secondary.opacity(0.08))
                                .foregroundColor(.secondary)
                                .cornerRadius(3)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor).opacity(0.7), lineWidth: 1)
        )
    }
}
