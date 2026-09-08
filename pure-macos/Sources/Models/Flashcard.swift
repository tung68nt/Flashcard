import Foundation

public struct Flashcard: Identifiable, Codable, Equatable, Hashable {
    public var id: String
    public var term: String
    public var phonetic: String?
    public var partOfSpeech: String?
    public var definition: String
    public var example: String?
    public var exampleTranslation: String?
    public var grammarPattern: String?
    public var notes: String?
    public var tags: [String]
    public var starred: Bool
    
    // Spaced Repetition (SuperMemo SM-2) Data
    public var repetition: Int
    public var interval: Int
    public var easeFactor: Double
    public var dueDate: Date
    public var lastReviewed: Date?
    public var reviewCount: Int
    public var lapses: Int
    
    public init(
        id: String = UUID().uuidString,
        term: String,
        phonetic: String? = nil,
        partOfSpeech: String? = nil,
        definition: String,
        example: String? = nil,
        exampleTranslation: String? = nil,
        grammarPattern: String? = nil,
        notes: String? = nil,
        tags: [String] = [],
        starred: Bool = false,
        repetition: Int = 0,
        interval: Int = 1,
        easeFactor: Double = 2.5,
        dueDate: Date = Date(),
        lastReviewed: Date? = nil,
        reviewCount: Int = 0,
        lapses: Int = 0
    ) {
        self.id = id
        self.term = term
        self.phonetic = phonetic
        self.partOfSpeech = partOfSpeech
        self.definition = definition
        self.example = example
        self.exampleTranslation = exampleTranslation
        self.grammarPattern = grammarPattern
        self.notes = notes
        self.tags = tags
        self.starred = starred
        self.repetition = repetition
        self.interval = interval
        self.easeFactor = easeFactor
        self.dueDate = dueDate
        self.lastReviewed = lastReviewed
        self.reviewCount = reviewCount
        self.lapses = lapses
    }
    
    public var isDue: Bool {
        return dueDate <= Date()
    }
}
