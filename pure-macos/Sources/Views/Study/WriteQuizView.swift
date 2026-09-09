import SwiftUI

public final class WriteQuizViewModel: ObservableObject {
    @Published public var cards: [Flashcard]
    @Published public var currentIndex: Int = 0
    @Published public var input: String = ""
    @Published public var isSubmitted: Bool = false
    @Published public var isCorrect: Bool = false
    @Published public var score: Int = 0
    @Published public var streak: Int = 0
    @Published public var isFinished: Bool = false
    
    public init(cards: [Flashcard]) {
        self.cards = cards.shuffled()
    }
    
    public var currentCard: Flashcard? {
        guard currentIndex >= 0 && currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }
    
    public var borderColor: Color {
        if !isSubmitted { return Color.accentColor.opacity(0.4) }
        return isCorrect ? Color.green : Color.red
    }
    
    public func checkAnswer(language: String) {
        guard let card = currentCard else { return }
        let cleanInput = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanTarget = card.term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        let match = (cleanInput == cleanTarget)
        isCorrect = match
        isSubmitted = true
        
        if match {
            score += 1
            streak += 1
            SpeechService.shared.speakTerm(card.term, language: language)
        } else {
            streak = 0
        }
    }
    
    public func nextCard() {
        input = ""
        isSubmitted = false
        if currentIndex + 1 < cards.count {
            currentIndex += 1
        } else {
            isFinished = true
        }
    }
}

public struct WriteQuizView: View {
    public let deck: Deck
    public var onClose: () -> Void
    
    @StateObject private var viewModel: WriteQuizViewModel
    
    public init(deck: Deck, onClose: @escaping () -> Void) {
        self.deck = deck
        self.onClose = onClose
        _viewModel = StateObject(wrappedValue: WriteQuizViewModel(cards: deck.cards))
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button(action: onClose) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Quay lại")
                    }
                    .font(.lexioBody)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Label("\(viewModel.streak) Streak", systemImage: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.lexioHeadline)
                    
                    Text("\(viewModel.currentIndex + 1) / \(max(1, viewModel.cards.count))")
                        .font(.lexioCaptionMedium)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            if viewModel.isFinished {
                // Completed View
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "pencil.and.outline")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    Text("Hoàn Thành Bài Viết!")
                        .font(.lexioTitle)
                    
                    Text("Điểm số của bạn: \(viewModel.score) / \(viewModel.cards.count) (\(viewModel.cards.count > 0 ? Int(Double(viewModel.score) / Double(viewModel.cards.count) * 100) : 0)%)")
                        .font(.lexioBody)
                        .foregroundColor(.secondary)
                    
                    Button("Trở Về Bộ Thẻ") {
                        onClose()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Spacer()
                }
            } else if let card = viewModel.currentCard {
                // Quiz Content
                VStack(spacing: 24) {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        if let pos = card.partOfSpeech, !pos.isEmpty {
                            POSBadge(pos)
                        }
                        
                        Text(card.definition)
                            .font(.lexioDisplay)
                            .multilineTextAlignment(.center)
                        
                        if let example = card.example, !example.isEmpty {
                            Text(example.replacingOccurrences(of: card.term, with: "______", options: .caseInsensitive))
                                .font(.lexioBody)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(10)
                                .background(Color.primary.opacity(0.04))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Input Area
                    VStack(spacing: 14) {
                        TextField("Gõ từ vựng tiếng Anh tương ứng...", text: $viewModel.input)
                            .textFieldStyle(.plain)
                            .font(.lexioTitle)
                            .padding(14)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(viewModel.borderColor, lineWidth: 1.5)
                            )
                            .disabled(viewModel.isSubmitted)
                            .onSubmit {
                                if viewModel.isSubmitted {
                                    viewModel.nextCard()
                                } else {
                                    viewModel.checkAnswer(language: deck.language)
                                }
                            }
                        
                        if viewModel.isSubmitted {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(viewModel.isCorrect ? .green : .red)
                                
                                Text(viewModel.isCorrect ? "Chính xác: \(card.term)" : "Đáp án đúng: \(card.term)")
                                    .font(.lexioHeadline)
                                    .foregroundColor(viewModel.isCorrect ? .green : .red)
                                
                                if let phonetic = card.phonetic, !phonetic.isEmpty {
                                    Text(phonetic)
                                        .font(.lexioCaption)
                                        .foregroundColor(.secondary)
                                }
                                
                                DualAudioButton(term: card.term)
                                
                                Spacer()
                                
                                Button("Tiếp tục (Enter)") {
                                    viewModel.nextCard()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(12)
                            .background((viewModel.isCorrect ? Color.green : Color.red).opacity(0.12))
                            .cornerRadius(10)
                        } else {
                            Button("Kiểm Tra (Enter)") {
                                viewModel.checkAnswer(language: deck.language)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.input.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    
                    Spacer()
                }
                .padding(32)
                .frame(maxWidth: 640, maxHeight: 420)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color(NSColor.separatorColor).opacity(0.6), lineWidth: 0.5)
                        )
                )
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
