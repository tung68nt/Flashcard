import SwiftUI
import Combine

public struct MatchTile: Identifiable {
    public let id: String
    public let cardId: String
    public let text: String
    public let isTerm: Bool
    public var isMatched: Bool = false
    
    public init(id: String, cardId: String, text: String, isTerm: Bool, isMatched: Bool = false) {
        self.id = id
        self.cardId = cardId
        self.text = text
        self.isTerm = isTerm
        self.isMatched = isMatched
    }
}

public final class MatchGameViewModel: ObservableObject {
    @Published public var tiles: [MatchTile] = []
    @Published public var selectedId: String? = nil
    @Published public var wrongIds: [String] = []
    @Published public var startTime: Date = Date()
    @Published public var elapsedSeconds: Double = 0.0
    @Published public var timerActive: Bool = false
    @Published public var isFinished: Bool = false
    @Published public var bestTime: Double? = nil
    
    public init() {}
    
    public func startNewGame(deck: Deck) {
        let sample = deck.cards.shuffled().prefix(6)
        var generated: [MatchTile] = []
        
        for c in sample {
            generated.append(MatchTile(id: "term-\(c.id)", cardId: c.id, text: c.term, isTerm: true))
            generated.append(MatchTile(id: "def-\(c.id)", cardId: c.id, text: c.definition, isTerm: false))
        }
        
        tiles = generated.shuffled()
        selectedId = nil
        wrongIds = []
        startTime = Date()
        elapsedSeconds = 0.0
        timerActive = true
        isFinished = false
    }
    
    public func handleTileTap(_ tile: MatchTile, deckId: String) {
        guard timerActive, !tile.isMatched, wrongIds.isEmpty else { return }
        
        if selectedId == nil {
            selectedId = tile.id
            return
        }
        
        if selectedId == tile.id {
            selectedId = nil
            return
        }
        
        guard let firstId = selectedId, let firstTile = tiles.first(where: { $0.id == firstId }) else { return }
        
        if firstTile.cardId == tile.cardId && firstTile.isTerm != tile.isTerm {
            // Đúng cặp
            if let idx1 = tiles.firstIndex(where: { $0.id == firstId }),
               let idx2 = tiles.firstIndex(where: { $0.id == tile.id }) {
                tiles[idx1].isMatched = true
                tiles[idx2].isMatched = true
            }
            selectedId = nil
            
            // Kiểm tra hoàn thành ván
            if tiles.allSatisfy({ $0.isMatched }) {
                timerActive = false
                isFinished = true
                saveBestTime(elapsedSeconds, deckId: deckId)
            }
        } else {
            // Sai cặp: highlight đỏ trong 0.6s
            wrongIds = [firstId, tile.id]
            selectedId = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.wrongIds = []
            }
        }
    }
    
    public func tickTimer() {
        if timerActive && !isFinished {
            elapsedSeconds = Date().timeIntervalSince(startTime)
        }
    }
    
    public func loadBestTime(deckId: String) {
        let key = "lexio_best_match_\(deckId)"
        let saved = UserDefaults.standard.double(forKey: key)
        if saved > 0 {
            bestTime = saved
        }
    }
    
    public func saveBestTime(_ time: Double, deckId: String) {
        let key = "lexio_best_match_\(deckId)"
        if bestTime == nil || time < bestTime! {
            bestTime = time
            UserDefaults.standard.set(time, forKey: key)
        }
    }
}

public struct MatchGameView: View {
    public let deck: Deck
    public var onClose: () -> Void
    
    @StateObject private var viewModel = MatchGameViewModel()
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    public init(deck: Deck, onClose: @escaping () -> Void) {
        self.deck = deck
        self.onClose = onClose
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
                
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .foregroundColor(.accentColor)
                    Text(String(format: "%.1fs", viewModel.elapsedSeconds))
                        .font(.lexioTitle)
                        .monospacedDigit()
                }
                
                Spacer()
                
                Button(action: { viewModel.startNewGame(deck: deck) }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.lexioHeadline)
                }
                .buttonStyle(.plain)
                .help("Chơi lại ván mới")
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            if viewModel.isFinished {
                // Victory Screen
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.yellow)
                    
                    Text("Xuất Sắc! Hoàn Thành Ghép Thẻ")
                        .font(.lexioTitle)
                    
                    Text(String(format: "Thời gian hoàn thành: %.1f giây", viewModel.elapsedSeconds))
                        .font(.lexioHeadline)
                        .foregroundColor(.primary)
                    
                    if let best = viewModel.bestTime {
                        Text(String(format: "Kỷ lục cá nhân: %.1f giây", best))
                            .font(.lexioCaption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 14) {
                        Button("Chơi Lại Ván Mới") {
                            viewModel.startNewGame(deck: deck)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Button("Về Bộ Thẻ") {
                            onClose()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    
                    Spacer()
                }
            } else {
                // Tiles Grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 14)], spacing: 14) {
                    ForEach(viewModel.tiles) { tile in
                        TileCardView(
                            tile: tile,
                            isSelected: viewModel.selectedId == tile.id,
                            isWrong: viewModel.wrongIds.contains(tile.id)
                        )
                        .onTapGesture {
                            viewModel.handleTileTap(tile, deckId: deck.id)
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: 820)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            viewModel.loadBestTime(deckId: deck.id)
            viewModel.startNewGame(deck: deck)
        }
        .onReceive(timer) { _ in
            viewModel.tickTimer()
        }
    }
}

private struct TileCardView: View {
    let tile: MatchTile
    let isSelected: Bool
    let isWrong: Bool
    
    var body: some View {
        VStack {
            Spacer()
            Text(tile.text)
                .font(tile.isTerm ? .lexioHeadline : .lexioBody)
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .padding(12)
            Spacer()
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        .opacity(tile.isMatched ? 0.0 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: tile.isMatched)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
    
    private var backgroundColor: Color {
        if isWrong { return Color.red.opacity(0.12) }
        if isSelected { return Color.accentColor.opacity(0.12) }
        return Color(NSColor.textBackgroundColor)
    }
    
    private var borderColor: Color {
        if isWrong { return Color.red }
        if isSelected { return Color.accentColor }
        return Color(NSColor.separatorColor).opacity(0.8)
    }
    
    private var textColor: Color {
        if isWrong { return .red }
        if isSelected { return .accentColor }
        return .primary
    }
}
