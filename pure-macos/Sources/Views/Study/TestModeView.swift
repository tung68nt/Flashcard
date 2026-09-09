import SwiftUI

public struct TestQuestion: Identifiable {
    public let id: String
    public let card: Flashcard
    public let prompt: String
    public let options: [String]
    public let correctAnswer: String
    public let isTrueFalse: Bool
    
    public init(id: String, card: Flashcard, prompt: String, options: [String], correctAnswer: String, isTrueFalse: Bool) {
        self.id = id
        self.card = card
        self.prompt = prompt
        self.options = options
        self.correctAnswer = correctAnswer
        self.isTrueFalse = isTrueFalse
    }
}

public final class TestModeViewModel: ObservableObject {
    @Published public var questions: [TestQuestion] = []
    @Published public var currentIndex: Int = 0
    @Published public var userAnswers: [String: String] = [:] // questionId: selectedOption
    @Published public var isSubmitted: Bool = false
    
    public init() {}
    
    public var currentQuestion: TestQuestion? {
        guard currentIndex >= 0 && currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    public var score: Int {
        var count = 0
        for q in questions {
            if userAnswers[q.id] == q.correctAnswer {
                count += 1
            }
        }
        return count
    }
    
    public func generateQuestions(deck: Deck, limit: Int? = nil) {
        var generated: [TestQuestion] = []
        var pool = deck.cards
        guard !pool.isEmpty else { return }
        
        if let limit = limit, limit > 0 {
            pool = Array(pool.prefix(limit))
        }
        
        for (idx, card) in pool.enumerated() {
            let isTF = (idx % 3 == 2) // Mỗi câu thứ 3 là True/False
            
            if isTF {
                let makeTrue = Bool.random()
                let displayMeaning = makeTrue ? card.definition : (pool.first(where: { $0.id != card.id })?.definition ?? card.definition)
                
                generated.append(TestQuestion(
                    id: "q-\(card.id)",
                    card: card,
                    prompt: "Từ \"\(card.term)\" có nghĩa là: \"\(displayMeaning)\"?",
                    options: ["Đúng (True)", "Sai (False)"],
                    correctAnswer: makeTrue ? "Đúng (True)" : "Sai (False)",
                    isTrueFalse: true
                ))
            } else {
                var wrongDefs = pool.filter { $0.id != card.id }.map { $0.definition }.shuffled().prefix(3).map { String($0) }
                while wrongDefs.count < 3 {
                    wrongDefs.append("Đáp án dự phòng \(wrongDefs.count + 1)")
                }
                var allOptions = [card.definition] + wrongDefs
                allOptions.shuffle()
                
                generated.append(TestQuestion(
                    id: "q-\(card.id)",
                    card: card,
                    prompt: "Chọn định nghĩa chính xác nhất cho từ: \"\(card.term)\"",
                    options: allOptions,
                    correctAnswer: card.definition,
                    isTrueFalse: false
                ))
            }
        }
        
        questions = generated
        currentIndex = 0
        userAnswers = [:]
        isSubmitted = false
    }
}

public struct TestModeView: View {
    public let deck: Deck
    public var sessionLimit: Int? = nil
    public var onClose: () -> Void
    
    @StateObject private var viewModel = TestModeViewModel()
    
    public init(deck: Deck, sessionLimit: Int? = nil, onClose: @escaping () -> Void) {
        self.deck = deck
        self.sessionLimit = sessionLimit
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
                
                Text(viewModel.isSubmitted ? "Kết Quả Bài Thi" : "Câu hỏi \(viewModel.currentIndex + 1) / \(viewModel.questions.count)")
                    .font(.lexioHeadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !viewModel.isSubmitted {
                    Button("Nộp Bài") {
                        viewModel.isSubmitted = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.userAnswers.count == 0)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            if viewModel.isSubmitted {
                // Scorecard
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 10) {
                            Image(systemName: viewModel.score >= viewModel.questions.count / 2 ? "rosette" : "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(viewModel.score >= viewModel.questions.count / 2 ? .green : .orange)
                            
                            Text("Kết Quả: \(viewModel.score) / \(viewModel.questions.count)")
                                .font(.lexioTitle)
                            
                            let percent = viewModel.questions.count > 0 ? Int(Double(viewModel.score) / Double(viewModel.questions.count) * 100) : 0
                            Text("Tỷ lệ chính xác: \(percent)%")
                                .font(.lexioBody)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 10)
                        
                        Divider()
                        
                        // Answer Review List
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Chi tiết bài làm:")
                                .font(.lexioSection)
                            
                            ForEach(viewModel.questions) { q in
                                let chosen = viewModel.userAnswers[q.id]
                                let isRight = (chosen == q.correctAnswer)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: isRight ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(isRight ? .green : .red)
                                        Text(q.prompt)
                                            .font(.lexioHeadline)
                                    }
                                    
                                    HStack {
                                        Text("Bạn chọn: \(chosen ?? "(Chưa chọn)")")
                                            .font(.lexioBody)
                                            .foregroundColor(isRight ? .green : .red)
                                        
                                        if !isRight {
                                            Spacer()
                                            Text("Đáp án đúng: \(q.correctAnswer)")
                                                .font(.lexioHeadline)
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(NSColor.separatorColor).opacity(0.7), lineWidth: 1)
                                )
                            }
                        }
                        
                        Button("Làm Lại Bài Thi") {
                            viewModel.generateQuestions(deck: deck)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 32)
                }
            } else if let q = viewModel.currentQuestion {
                // Question Card
                VStack(spacing: 24) {
                    Spacer()
                    
                    Text(q.prompt)
                        .font(.lexioTitle)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        ForEach(q.options, id: \.self) { option in
                            Button(action: {
                                viewModel.userAnswers[q.id] = option
                            }) {
                                HStack {
                                    Image(systemName: viewModel.userAnswers[q.id] == option ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(viewModel.userAnswers[q.id] == option ? .accentColor : .secondary)
                                    Text(option)
                                        .font(.lexioBody)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(14)
                                .background(viewModel.userAnswers[q.id] == option ? Color.accentColor.opacity(0.1) : Color(NSColor.textBackgroundColor))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(viewModel.userAnswers[q.id] == option ? Color.accentColor : Color(NSColor.separatorColor).opacity(0.8), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: 580)
                    
                    Spacer()
                    
                    // Nav buttons
                    HStack {
                        Button("Câu Trước") {
                            if viewModel.currentIndex > 0 { viewModel.currentIndex -= 1 }
                        }
                        .disabled(viewModel.currentIndex == 0)
                        
                        Spacer()
                        
                        if viewModel.currentIndex < viewModel.questions.count - 1 {
                            Button("Câu Tiếp Theo") {
                                viewModel.currentIndex += 1
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button("Nộp Bài Thi") {
                                viewModel.isSubmitted = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(maxWidth: 580)
                }
                .padding(32)
                .frame(maxWidth: 680, maxHeight: 520)
                .appleStudyCard(cornerRadius: 18)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.lexioCanvasBackground)
        .onAppear {
            viewModel.generateQuestions(deck: deck, limit: sessionLimit)
        }
    }
}
