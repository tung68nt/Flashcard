import SwiftUI

public struct CardRowView: View {
    public let card: Flashcard
    public let language: String
    public var showContainer: Bool
    public var onToggleStar: () -> Void
    public var onDelete: () -> Void
    
    public init(
        card: Flashcard,
        language: String = "en-US",
        showContainer: Bool = false,
        onToggleStar: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.card = card
        self.language = language
        self.showContainer = showContainer
        self.onToggleStar = onToggleStar
        self.onDelete = onDelete
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header Row: Term, Phonetic, Audio, POS, Actions
            HStack(alignment: .center, spacing: 8) {
                Text(card.term)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                
                if let phonetic = card.phonetic, !phonetic.isEmpty {
                    Text(phonetic)
                        .font(.system(size: 12.5))
                        .foregroundColor(.secondary)
                }
                
                DualAudioButton(term: card.term)
                
                if let pos = card.partOfSpeech, !pos.isEmpty {
                    POSBadge(pos)
                }
                
                Spacer()
                
                // Star Button
                Button(action: onToggleStar) {
                    Image(systemName: card.starred ? "star.fill" : "star")
                        .font(.system(size: 13))
                        .foregroundColor(card.starred ? .yellow : .secondary.opacity(0.35))
                }
                .buttonStyle(.plain)
                .help(card.starred ? "Bỏ gắn sao" : "Gắn sao thẻ này")
                
                // Delete Button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.4))
                }
                .buttonStyle(.plain)
                .help("Xóa thẻ này")
            }
            
            // Definition
            Text(card.definition)
                .font(.system(size: 13))
                .foregroundColor(.primary.opacity(0.9))
                .lineSpacing(2)
            
            // Grammar Pattern (Inline pill)
            if let grammar = card.grammarPattern, !grammar.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "link")
                        .font(.system(size: 9, weight: .bold))
                    Text(grammar)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                }
                .foregroundColor(Color(hex: "#FF2D55"))
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(Color(hex: "#FF2D55").opacity(0.08))
                .cornerRadius(4)
            }
            
            // Example Sentence (Clean dictionary quote style)
            if let example = card.example, !example.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Button {
                        SpeechService.shared.speak(text: example, language: language)
                    } label: {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.accentColor)
                            .padding(.top, 2)
                    }
                    .buttonStyle(.plain)
                    .help("Nghe câu ví dụ")
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("“\(example)”")
                            .font(.system(size: 12, weight: .regular))
                            .italic()
                            .foregroundColor(.secondary)
                        
                        if let trans = card.exampleTranslation, !trans.isEmpty {
                            Text(trans)
                                .font(.system(size: 11.5))
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                    }
                }
                .padding(.top, 2)
            }
            
            // Notes & Tags
            if (card.notes != nil && !card.notes!.isEmpty) || !card.tags.isEmpty {
                HStack(spacing: 8) {
                    if let notes = card.notes, !notes.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 9.5))
                                .foregroundColor(Color(hex: "#FF9500"))
                            Text(notes)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !card.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(card.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 10.5))
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                        }
                    }
                }
                .padding(.top, 1)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .if(showContainer) { view in
            view.liquidGlassCard(cornerRadius: 12, isInteractive: true)
        }
    }
}

private extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
