import SwiftUI

public final class SRSLearnViewModel: ObservableObject {
    @Published public var queue: [Flashcard]
    @Published public var currentIndex: Int = 0
    @Published public var isAnswerRevealed: Bool = false
    @Published public var reviewedCount: Int = 0
    @Published public var goodCount: Int = 0
    @Published public var isFinished: Bool = false
    
    public init(cards: [Flashcard]) {
        let due = cards.filter { $0.isDue }
        self.queue = due.isEmpty ? cards : due
    }
    
    public var currentCard: Flashcard? {
        guard currentIndex >= 0 && currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }
    
    public func rateCard(_ rating: SRSRating, deckId: String) {
        guard let card = currentCard else { return }
        
        let updated = SRSEngine.calculate(card: card, rating: rating)
        StorageService.shared.updateCardInDeck(deckId: deckId, card: updated)
        
        reviewedCount += 1
        if rating.rawValue >= 3 {
            goodCount += 1
        }
        
        if rating == .again {
            queue.append(updated)
        }
        
        if currentIndex + 1 < queue.count {
            withAnimation(.spring()) {
                currentIndex += 1
                isAnswerRevealed = false
            }
        } else {
            withAnimation {
                isFinished = true
            }
        }
    }
}

public struct SRSLearnView: View {
    public let deck: Deck
    public var onClose: () -> Void
    
    @StateObject private var viewModel: SRSLearnViewModel
    
    public init(deck: Deck, onClose: @escaping () -> Void) {
        self.deck = deck
        self.onClose = onClose
        _viewModel = StateObject(wrappedValue: SRSLearnViewModel(cards: deck.cards))
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button(action: onClose) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Thoát phiên")
                    }
                    .font(.lexioBody)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("SuperMemo SM-2 • Còn lại \(max(0, viewModel.queue.count - viewModel.currentIndex)) thẻ")
                    .font(.lexioHeadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Đã ôn: \(viewModel.reviewedCount)")
                    .font(.lexioCaption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            if viewModel.isFinished {
                // Completed View
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    Text("Hoàn Thành Phiên Ôn Tập!")
                        .font(.lexioTitle)
                    
                    Text("Bạn đã ôn tập \(viewModel.reviewedCount) thẻ với tỷ lệ nhớ tốt \(viewModel.reviewedCount > 0 ? Int(Double(viewModel.goodCount) / Double(viewModel.reviewedCount) * 100) : 100)%")
                        .font(.lexioBody)
                        .foregroundColor(.secondary)
                    
                    Button("Trở Về Danh Sách") {
                        onClose()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Spacer()
                }
                .padding()
            } else if let card = viewModel.currentCard {
                // Question Card
                VStack(spacing: 24) {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        HStack {
                            if let pos = card.partOfSpeech, !pos.isEmpty {
                                POSBadge(pos)
                            }
                            Spacer()
                            DualAudioButton(term: card.term)
                        }
                        
                        Text(card.term)
                            .font(.lexioDisplay)
                            .multilineTextAlignment(.center)
                        
                        if let phonetic = card.phonetic, !phonetic.isEmpty {
                            Text(phonetic)
                                .font(.lexioSection)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal, 32)
                    
                    if viewModel.isAnswerRevealed {
                        // Answer revealed
                        VStack(spacing: 12) {
                            Text(card.definition)
                                .font(.lexioTitle)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            if let pattern = card.grammarPattern, !pattern.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "link")
                                        .font(.lexioCaption)
                                    Text(pattern)
                                        .font(.lexioCaptionMedium)
                                }
                                .foregroundColor(Color(hex: "#FF2D55"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(hex: "#FF2D55").opacity(0.08))
                                .cornerRadius(6)
                            }
                            
                            if let ex = card.example, !ex.isEmpty {
                                VStack(spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(ex)
                                            .font(.lexioBody)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.center)
                                        
                                        Button {
                                            SpeechService.shared.speak(text: ex, language: deck.language)
                                        } label: {
                                            Image(systemName: "speaker.wave.2.fill")
                                                .font(.system(size: 11))
                                                .foregroundColor(.accentColor)
                                                .padding(4)
                                                .background(Color.accentColor.opacity(0.12))
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                        .help("Nghe phát âm chuẩn cả câu ví dụ")
                                    }
                                    
                                    if let trans = card.exampleTranslation, !trans.isEmpty {
                                        Text(trans)
                                            .font(.lexioCaption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(10)
                                .background(Color.primary.opacity(0.03))
                                .cornerRadius(8)
                            }
                            
                            if let notes = card.notes, !notes.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.lexioCaption)
                                        .foregroundColor(Color(hex: "#FF9500"))
                                    Text(notes)
                                        .font(.lexioCaption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 8)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        Button(action: {
                            withAnimation(.spring()) {
                                viewModel.isAnswerRevealed = true
                            }
                            SpeechService.shared.speakTerm(card.term, language: deck.language)
                        }) {
                            Text("Hiện Đáp Án (Space)")
                                .font(.lexioHeadline)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 11)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.space, modifiers: [])
                    }
                    
                    Spacer()
                }
                .padding(32)
                .frame(maxWidth: 680, maxHeight: 420)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.textBackgroundColor))
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(NSColor.separatorColor).opacity(0.8), lineWidth: 1)
                        )
                )
                
                // SM-2 Rating Bar
                if viewModel.isAnswerRevealed {
                    HStack(spacing: 14) {
                        ForEach(SRSRating.allCases, id: \.self) { rating in
                            Button(action: { viewModel.rateCard(rating, deckId: deck.id) }) {
                                VStack(spacing: 4) {
                                    Text(rating.label)
                                        .font(.lexioHeadline)
                                    Text(rating.subtitle)
                                        .font(.lexioCaption)
                                        .opacity(0.8)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(rating.color.opacity(0.12))
                                .foregroundColor(rating.color)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(rating.color.opacity(0.35), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .keyboardShortcut(KeyEquivalent(Character("\(rating.rawValue)")), modifiers: [])
                        }
                    }
                    .frame(maxWidth: 680)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                } else {
                    Spacer().frame(height: 72)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
