import Foundation
import Combine

public class StorageService: ObservableObject {
    public static let shared = StorageService()
    
    @Published public var decks: [Deck] = []
    
    private let fileManager = FileManager.default
    private let storageURL: URL
    
    private init() {
        // Thư mục lưu trữ chuẩn macOS: ~/Library/Application Support/LexioPro/
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("LexioPro", isDirectory: true)
        
        if !fileManager.fileExists(atPath: appDir.path) {
            try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        }
        
        self.storageURL = appDir.appendingPathComponent("decks.json")
        loadDecks()
    }
    
    public func loadDecks() {
        if fileManager.fileExists(atPath: storageURL.path) {
            do {
                let data = try Data(contentsOf: storageURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let loaded = try decoder.decode([Deck].self, from: data)
                if !loaded.isEmpty {
                    self.decks = loaded
                    return
                }
            } catch {
                print("[Lexio Native] Lỗi giải mã decks.json: \(error)")
            }
        }
        
        // Khởi tạo lần đầu với dữ liệu mẫu chất lượng cao
        self.decks = SampleData.defaultDecks()
        saveDecks()
    }
    
    public func saveDecks() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(decks)
            try data.write(to: storageURL, options: [.atomicWrite])
        } catch {
            print("[Lexio Native] Lỗi lưu trữ decks.json: \(error)")
        }
    }
    
    public func saveDeck(_ deck: Deck) {
        if let index = decks.firstIndex(where: { $0.id == deck.id }) {
            var updated = deck
            updated.updatedAt = Date()
            decks[index] = updated
        } else {
            decks.insert(deck, at: 0)
        }
        saveDecks()
    }
    
    public func deleteDeck(id: String) {
        decks.removeAll { $0.id == id }
        saveDecks()
    }
    
    public func updateCardInDeck(deckId: String, card: Flashcard) {
        guard let deckIndex = decks.firstIndex(where: { $0.id == deckId }) else { return }
        var deck = decks[deckIndex]
        
        if let cardIndex = deck.cards.firstIndex(where: { $0.id == card.id }) {
            deck.cards[cardIndex] = card
        } else {
            deck.cards.append(card)
        }
        deck.updatedAt = Date()
        decks[deckIndex] = deck
        saveDecks()
    }
    
    public func deleteCard(deckId: String, cardId: String) {
        guard let deckIndex = decks.firstIndex(where: { $0.id == deckId }) else { return }
        decks[deckIndex].cards.removeAll { $0.id == cardId }
        decks[deckIndex].updatedAt = Date()
        saveDecks()
    }
    
    public func exportBackupJSON(to destinationURL: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(decks)
        try data.write(to: destinationURL)
    }
    
    public func importBackupJSON(from sourceURL: URL) throws {
        let data = try Data(contentsOf: sourceURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let imported = try decoder.decode([Deck].self, from: data)
        self.decks = imported
        saveDecks()
    }
}
