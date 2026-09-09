import SwiftUI

public final class FlashcardStudyViewModel: ObservableObject {
    @Published public var cards: [Flashcard]
    @Published public var currentIndex: Int = 0
    @Published public var isFlipped: Bool = false
    @Published public var autoPlayAudio: Bool = true
    
    public init(cards: [Flashcard], limit: Int? = nil) {
        if let limit = limit, limit > 0 {
            self.cards = Array(cards.prefix(limit))
        } else {
            self.cards = cards
        }
    }
    
    public var currentCard: Flashcard? {
        guard currentIndex >= 0 && currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }
    
    public func nextCard(language: String) {
        if currentIndex < cards.count - 1 {
            withAnimation(.spring()) {
                isFlipped = false
                currentIndex += 1
            }
            if autoPlayAudio, let card = currentCard {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    SpeechService.shared.speakTerm(card.term, language: language)
                }
            }
        }
    }
    
    public func prevCard() {
        if currentIndex > 0 {
            withAnimation(.spring()) {
                isFlipped = false
                currentIndex -= 1
            }
        }
    }
    
    public func shuffleCards() {
        withAnimation {
            cards.shuffle()
            currentIndex = 0
            isFlipped = false
        }
    }
}

public struct FlashcardStudyView: View {
    public let deck: Deck
    public var onClose: () -> Void
    
    @StateObject private var viewModel: FlashcardStudyViewModel
    
    public init(deck: Deck, sessionLimit: Int? = nil, onClose: @escaping () -> Void) {
        self.deck = deck
        self.onClose = onClose
        _viewModel = StateObject(wrappedValue: FlashcardStudyViewModel(cards: deck.cards, limit: sessionLimit))
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header Bar
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
                
                // Progress counter
                Text("\(viewModel.currentIndex + 1) / \(max(1, viewModel.cards.count))")
                    .font(.lexioHeadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Shuffle button
                Button(action: viewModel.shuffleCards) {
                    Image(systemName: "shuffle")
                        .font(.lexioHeadline)
                }
                .buttonStyle(.plain)
                .help("Xáo trộn thứ tự thẻ")
                
                // Toggle Auto Audio
                Button(action: { viewModel.autoPlayAudio.toggle() }) {
                    Image(systemName: viewModel.autoPlayAudio ? "speaker.wave.3.fill" : "speaker.slash")
                        .font(.lexioHeadline)
                        .foregroundColor(viewModel.autoPlayAudio ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help("Tự động phát âm khi chuyển thẻ")
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(LinearGradient(colors: [Color.pink, Color.purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(viewModel.currentIndex + 1) / CGFloat(max(1, viewModel.cards.count)), height: 6)
                        .animation(.easeInOut(duration: 0.25), value: viewModel.currentIndex)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 24)
            
            Spacer()
            
            // 3D Flip Card Container
            if let card = viewModel.currentCard {
                ZStack {
                    // Front Face
                    CardFaceView(card: card, language: deck.language, isBack: false)
                        .opacity(viewModel.isFlipped ? 0 : 1)
                        .rotation3DEffect(
                            .degrees(viewModel.isFlipped ? 180 : 0),
                            axis: (x: 0.0, y: 1.0, z: 0.0)
                        )
                    
                    // Back Face
                    CardFaceView(card: card, language: deck.language, isBack: true)
                        .opacity(viewModel.isFlipped ? 1 : 0)
                        .rotation3DEffect(
                            .degrees(viewModel.isFlipped ? 0 : -180),
                            axis: (x: 0.0, y: 1.0, z: 0.0)
                        )
                }
                .frame(maxWidth: 680, minHeight: 380, maxHeight: 420)
                .padding(.horizontal, 24)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                        viewModel.isFlipped.toggle()
                    }
                }
            }
            
            Spacer()
            
            // Bottom Controls
            HStack(spacing: 36) {
                Button(action: viewModel.prevCard) {
                    Image(systemName: "arrow.left")
                        .font(.lexioHeadline)
                        .frame(width: 38, height: 38)
                        .background(Color.lexioCardBackground)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.currentIndex == 0)
                .keyboardShortcut(.leftArrow, modifiers: [])
                .help("Thẻ trước (Mũi tên Trái)")
                
                Button(action: {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                        viewModel.isFlipped.toggle()
                    }
                }) {
                    Text(viewModel.isFlipped ? "Xem Mặt Trước" : "Lật Xem Nghĩa")
                        .font(.lexioHeadline)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .keyboardShortcut(.space, modifiers: [])
                .help("Lật thẻ (Phím Space)")
                
                Button(action: { viewModel.nextCard(language: deck.language) }) {
                    Image(systemName: "arrow.right")
                        .font(.lexioHeadline)
                        .frame(width: 38, height: 38)
                        .background(Color.lexioCardBackground)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.currentIndex >= viewModel.cards.count - 1)
                .keyboardShortcut(.rightArrow, modifiers: [])
                .help("Thẻ tiếp (Mũi tên Phải)")
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.lexioCanvasBackground)
        .onAppear {
            if viewModel.autoPlayAudio, let card = viewModel.currentCard {
                SpeechService.shared.speakTerm(card.term, language: deck.language)
            }
        }
    }
}

private struct CardFaceView: View {
    let card: Flashcard
    let language: String
    let isBack: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Header bar in card
            HStack {
                if let pos = card.partOfSpeech, !pos.isEmpty {
                    POSBadge(pos)
                }
                Spacer()
                
                // Nút phát âm UK 🇬🇧 & US 🇺🇸
                DualAudioButton(term: card.term)
            }
            
            Spacer()
            
            if !isBack {
                // Front: Word & IPA & Dual Audio
                VStack(spacing: 10) {
                    Text(card.term)
                        .font(.lexioDisplay)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    if let phonetic = card.phonetic, !phonetic.isEmpty {
                        Text(phonetic)
                            .font(.lexioSection)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // Back: Meaning & Example
                VStack(spacing: 12) {
                    Text(card.definition)
                        .font(.lexioTitle)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    if let example = card.example, !example.isEmpty {
                        VStack(spacing: 6) {
                            HStack(alignment: .center, spacing: 6) {
                                Text(example)
                                    .font(.lexioBody)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                
                                Button {
                                    SpeechService.shared.speak(text: example, language: language)
                                } label: {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.accentColor)
                                        .padding(5)
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
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(12)
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(8)
                    }
                    
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
                    
                    if let notes = card.notes, !notes.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.lexioCaption)
                                .foregroundColor(Color(hex: "#FF9500"))
                            Text(notes)
                                .font(.lexioCaption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                    }
                }
            }
            
            Spacer()
            
            Text(isBack ? "Nhấn Space hoặc Click để lật mặt trước" : "Nhấn Space hoặc Click để lật xem định nghĩa")
                .font(.lexioCaption)
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appleStudyCard(cornerRadius: 18)
    }
}
