import Foundation

public struct Deck: Identifiable, Codable, Equatable {
    public var id: String
    public var title: String
    public var description: String
    public var language: String
    public var targetLanguage: String
    public var category: String
    public var tags: [String]
    public var colorHex: String
    public var createdAt: Date
    public var updatedAt: Date
    public var cards: [Flashcard]
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String = "",
        language: String = "en-US",
        targetLanguage: String = "vi-VN",
        category: String = "General",
        tags: [String] = [],
        colorHex: String = "#FF2A6D",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        cards: [Flashcard] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.language = language
        self.targetLanguage = targetLanguage
        self.category = category
        self.tags = tags
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.cards = cards
    }
    
    public var dueCardsCount: Int {
        return cards.filter { $0.isDue }.count
    }
    
    public var starredCardsCount: Int {
        return cards.filter { $0.starred }.count
    }
    
    public var averageEaseFactor: Double {
        guard !cards.isEmpty else { return 2.5 }
        let total = cards.reduce(0.0) { $0 + $1.easeFactor }
        return total / Double(cards.count)
    }
}
