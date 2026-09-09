import Foundation
import Combine

// MARK: - Category Info Model
public struct CategoryInfo: Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let deckCount: Int
    public let totalCards: Int
    public let dueCards: Int
    
    public init(name: String, deckCount: Int, totalCards: Int, dueCards: Int) {
        self.name = name
        self.deckCount = deckCount
        self.totalCards = totalCards
        self.dueCards = dueCards
    }
}

public class StorageService: ObservableObject {
    public static let shared = StorageService()
    
    @Published public var decks: [Deck] = []
    @Published public var customCategories: [String] = []
    
    private let fileManager = FileManager.default
    private let storageURL: URL
    private let categoriesURL: URL
    
    private init() {
        // Thư mục lưu trữ chuẩn macOS: ~/Library/Application Support/LexioPro/
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("LexioPro", isDirectory: true)
        
        if !fileManager.fileExists(atPath: appDir.path) {
            try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        }
        
        self.storageURL = appDir.appendingPathComponent("decks.json")
        self.categoriesURL = appDir.appendingPathComponent("categories.json")
        loadDecks()
        loadCategories()
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
    
    // MARK: - Category Management
    
    public func loadCategories() {
        if fileManager.fileExists(atPath: categoriesURL.path) {
            do {
                let data = try Data(contentsOf: categoriesURL)
                let loaded = try JSONDecoder().decode([String].self, from: data)
                self.customCategories = loaded
                return
            } catch {
                print("[Lexio Native] Lỗi giải mã categories.json: \(error)")
            }
        }
        
        // Mặc định nạp các danh mục từ decks hiện có
        let initialCategories = Array(Set(decks.map { $0.category.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })).sorted()
        self.customCategories = initialCategories.isEmpty ? ["Chung"] : initialCategories
        saveCategories()
    }
    
    public func saveCategories() {
        do {
            let data = try JSONEncoder().encode(customCategories)
            try data.write(to: categoriesURL, options: [.atomicWrite])
        } catch {
            print("[Lexio Native] Lỗi lưu categories.json: \(error)")
        }
    }
    
    public var allCategoryNames: [String] {
        var names = Set(decks.map { $0.category.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
        for cat in customCategories {
            let trimmed = cat.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                names.insert(trimmed)
            }
        }
        if names.isEmpty {
            names.insert("Chung")
        }
        return names.sorted()
    }
    
    public var allCategoryInfos: [CategoryInfo] {
        let names = allCategoryNames
        return names.map { cat in
            let matchingDecks = decks.filter { $0.category.trimmingCharacters(in: .whitespaces) == cat }
            let totalCards = matchingDecks.reduce(0) { $0 + $1.cards.count }
            let dueCards = matchingDecks.reduce(0) { $0 + $1.dueCardsCount }
            return CategoryInfo(name: cat, deckCount: matchingDecks.count, totalCards: totalCards, dueCards: dueCards)
        }
    }
    
    @discardableResult
    public func createCategory(named name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        if !customCategories.contains(trimmed) {
            customCategories.append(trimmed)
            customCategories.sort()
            saveCategories()
            return true
        }
        return false
    }
    
    public func renameCategory(from oldName: String, to newName: String) {
        let from = oldName.trimmingCharacters(in: .whitespaces)
        let to = newName.trimmingCharacters(in: .whitespaces)
        guard !from.isEmpty, !to.isEmpty, from != to else { return }
        
        var modified = false
        for i in 0..<decks.count {
            if decks[i].category.trimmingCharacters(in: .whitespaces) == from {
                decks[i].category = to
                decks[i].updatedAt = Date()
                modified = true
            }
        }
        
        customCategories.removeAll { $0 == from }
        if !customCategories.contains(to) {
            customCategories.append(to)
        }
        customCategories.sort()
        
        if modified {
            saveDecks()
        }
        saveCategories()
    }
    
    public func deleteCategory(named name: String, reassignTo: String = "Chung") {
        let target = name.trimmingCharacters(in: .whitespaces)
        let fallback = reassignTo.trimmingCharacters(in: .whitespaces).isEmpty ? "Chung" : reassignTo.trimmingCharacters(in: .whitespaces)
        
        var modified = false
        for i in 0..<decks.count {
            if decks[i].category.trimmingCharacters(in: .whitespaces) == target {
                decks[i].category = fallback
                decks[i].updatedAt = Date()
                modified = true
            }
        }
        
        customCategories.removeAll { $0 == target }
        if !customCategories.contains(fallback) {
            customCategories.append(fallback)
        }
        customCategories.sort()
        
        if modified {
            saveDecks()
        }
        saveCategories()
    }
}
