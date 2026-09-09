import SwiftUI
import AppKit

public final class DeckDetailViewModel: ObservableObject {
    @Published public var searchQuery: String = ""
    @Published public var onlyStarred: Bool = false
    @Published public var selectedTag: String = "Tất cả"
    @Published public var showDeleteConfirm: Bool = false
    @Published public var cardToDelete: Flashcard? = nil
    @Published public var showDirectCSVEditor: Bool = false
    @Published public var toastMessage: String? = nil
    
    public init() {}
}

public struct DeckDetailView: View {
    public let deck: Deck
    public var onBack: (() -> Void)? = nil
    public var onStartStudy: (StudyMode) -> Void
    public var onEditDeck: () -> Void
    public var onDeleteDeck: () -> Void
    
    @ObservedObject private var storage = StorageService.shared
    @StateObject private var viewModel = DeckDetailViewModel()
    
    public init(
        deck: Deck,
        onBack: (() -> Void)? = nil,
        onStartStudy: @escaping (StudyMode) -> Void,
        onEditDeck: @escaping () -> Void,
        onDeleteDeck: @escaping () -> Void
    ) {
        self.deck = deck
        self.onBack = onBack
        self.onStartStudy = onStartStudy
        self.onEditDeck = onEditDeck
        self.onDeleteDeck = onDeleteDeck
    }
    
    private var currentDeck: Deck {
        storage.decks.first(where: { $0.id == deck.id }) ?? deck
    }
    
    private var allTags: [String] {
        let tags = Set(currentDeck.cards.flatMap { $0.tags })
        return ["Tất cả"] + Array(tags).sorted()
    }
    
    private var filteredCards: [Flashcard] {
        currentDeck.cards.filter { card in
            let matchSearch = viewModel.searchQuery.isEmpty ||
                card.term.localizedCaseInsensitiveContains(viewModel.searchQuery) ||
                card.definition.localizedCaseInsensitiveContains(viewModel.searchQuery) ||
                (card.example?.localizedCaseInsensitiveContains(viewModel.searchQuery) == true)
            
            let matchStar = !viewModel.onlyStarred || card.starred
            let matchTag = viewModel.selectedTag == "Tất cả" || card.tags.contains(viewModel.selectedTag)
            
            return matchSearch && matchStar && matchTag
        }
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // MARK: - 1. Top Navigation & Quick Actions Bar
                    HStack {
                        if let back = onBack {
                            Button(action: back) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text("Tất cả bộ thẻ")
                                        .font(.lexioBody)
                                }
                                .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Spacer()
                        
                        // Top-Right Actions: Menu CSV & Chỉnh sửa
                        HStack(spacing: 8) {
                            Menu {
                                Section("Soạn Thảo & Cập Nhật") {
                                    Button(action: { viewModel.showDirectCSVEditor = true }) {
                                        Label("Sửa Nhanh Bảng CSV...", systemImage: "tablecells.badge.ellipsis")
                                    }
                                    Button(action: importCSVToThisDeck) {
                                        Label("Nạp Thêm Từ File CSV...", systemImage: "arrow.up.doc")
                                    }
                                }
                                Section("Xuất Dữ Liệu") {
                                    Button(action: exportCSV) {
                                        Label("Xuất File CSV...", systemImage: "arrow.down.doc")
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "tablecells")
                                        .font(.system(size: 11, weight: .medium))
                                    Text("Dữ Liệu & CSV")
                                        .font(.system(size: 12, weight: .medium))
                                }
                            }
                            .menuStyle(.borderedButton)
                            .controlSize(.small)
                            .help("Sửa nhanh bảng tính CSV, nạp thêm hoặc xuất dữ liệu bộ thẻ này")
                            
                            Button(action: onEditDeck) {
                                HStack(spacing: 4) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 11, weight: .medium))
                                    Text("Sửa")
                                        .font(.system(size: 12, weight: .medium))
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .help("Chỉnh sửa thông tin và danh sách thẻ trong Studio")
                            
                            Button(action: { viewModel.showDeleteConfirm = true }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.red.opacity(0.85))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .help("Xóa bộ thẻ này")
                        }
                    }
                    
                    // MARK: - 2. Unified Hero Header (Gộp Header + Hero CTA + Stats + Mode Actions)
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 14) {
                            // Deck Icon Badge (48x48 rounded rect with deck color)
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(hex: currentDeck.colorHex).opacity(0.15))
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(Color(hex: currentDeck.colorHex))
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                // Category & Language Pills
                                HStack(spacing: 6) {
                                    Text(currentDeck.category)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.accentColor)
                                        .liquidGlassPill(isHighlighted: true)
                                    
                                    Text(currentDeck.language)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .liquidGlassPill(isHighlighted: false)
                                }
                                
                                // Title
                                Text(currentDeck.title)
                                    .font(.system(size: 21, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                // Description
                                if !currentDeck.description.isEmpty {
                                    Text(currentDeck.description)
                                        .font(.system(size: 12.5))
                                        .foregroundColor(.secondary)
                                        .lineSpacing(2)
                                }
                                
                                // Inline Stats Metadata (Thanh lịch, không bị đóng hộp thô)
                                HStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "square.stack.3d.up.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(hex: "#0A84FF"))
                                        Text("\(currentDeck.cards.count) thẻ")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text("•").foregroundColor(.secondary.opacity(0.35))
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock.badge.exclamationmark.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(currentDeck.dueCardsCount > 0 ? Color(hex: "#FF453A") : Color(hex: "#30D158"))
                                        Text(currentDeck.dueCardsCount > 0 ? "\(currentDeck.dueCardsCount) cần ôn hôm nay" : "Đã ôn xong hôm nay")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(currentDeck.dueCardsCount > 0 ? Color(hex: "#FF453A") : .secondary)
                                    }
                                    
                                    if currentDeck.starredCardsCount > 0 {
                                        Text("•").foregroundColor(.secondary.opacity(0.35))
                                        HStack(spacing: 4) {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 10.5))
                                                .foregroundColor(Color(hex: "#FF9F0A"))
                                            Text("\(currentDeck.starredCardsCount) gắn sao")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Text("•").foregroundColor(.secondary.opacity(0.35))
                                    HStack(spacing: 4) {
                                        Image(systemName: "brain.head.profile")
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(hex: "#BF5AF2"))
                                        Text("Độ dễ: \(String(format: "%.1f", currentDeck.averageEaseFactor))")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.top, 2)
                            }
                            
                            Spacer(minLength: 8)
                        }
                        
                        Divider().opacity(0.4)
                        
                        // Clear Action Bar: Primary Play + Secondary Flip + Mode Menu
                        HStack(spacing: 10) {
                            // Primary Action
                            Button(action: {
                                if currentDeck.dueCardsCount > 0 {
                                    onStartStudy(.srs)
                                } else {
                                    onStartStudy(.flashcards)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 11, weight: .bold))
                                    Text(currentDeck.dueCardsCount > 0 ? "Ôn Tập Ngay (\(currentDeck.dueCardsCount))" : "Bắt Đầu Học")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)
                            .disabled(currentDeck.cards.isEmpty)
                            
                            // Secondary Action: Standard Flip
                            Button(action: { onStartStudy(.flashcards) }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "rectangle.stack")
                                        .font(.system(size: 11, weight: .medium))
                                    Text("Lật Thẻ")
                                        .font(.system(size: 12.5, weight: .medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            .disabled(currentDeck.cards.isEmpty)
                            
                            // Other Practice Modes (Submenu)
                            Menu {
                                Button(action: { onStartStudy(.srs) }) {
                                    Label("Học Ngắt Quãng SRS", systemImage: "brain")
                                }
                                Button(action: { onStartStudy(.write) }) {
                                    Label("Gõ Từ Vựng (Recall)", systemImage: "keyboard")
                                }
                                Button(action: { onStartStudy(.match) }) {
                                    Label("Ghép Thẻ Nhanh", systemImage: "square.grid.2x2")
                                }
                                Button(action: { onStartStudy(.test) }) {
                                    Label("Bài Thi Trắc Nghiệm", systemImage: "checkmark.seal")
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("Luyện Tập Khác")
                                        .font(.system(size: 12.5, weight: .medium))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                            }
                            .menuStyle(.borderedButton)
                            .controlSize(.regular)
                            .disabled(currentDeck.cards.isEmpty)
                            
                            Spacer()
                        }
                    }
                    .padding(16)
                    .liquidGlassCard(cornerRadius: 14)
                    
                    // MARK: - 3. Vocabulary Section Header & Filters
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Danh Sách Từ Vựng")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                            Text("\(filteredCards.count) thẻ vựng")
                                .font(.system(size: 11.5))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Filters & Search Bar aligned neatly on the right
                        HStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 12))
                                TextField("Tìm từ...", text: $viewModel.searchQuery)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 12))
                                if !viewModel.searchQuery.isEmpty {
                                    Button(action: { viewModel.searchQuery = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 11))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .frame(width: 180)
                            .background(Color.lexioCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                            
                            Toggle(isOn: $viewModel.onlyStarred) {
                                Label("Gắn sao", systemImage: "star.fill")
                                    .font(.system(size: 11))
                            }
                            .toggleStyle(.button)
                            .controlSize(.small)
                            .help("Chỉ hiện thẻ có gắn sao")
                            
                            if allTags.count > 1 {
                                Picker("", selection: $viewModel.selectedTag) {
                                    ForEach(allTags, id: \.self) { tag in
                                        Text(tag).tag(tag)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 110)
                                .controlSize(.small)
                            }
                        }
                    }
                    .padding(.top, 4)
                    
                    // MARK: - 4. Inset Grouped Vocabulary List (Container duy nhất, có hairline phân cách)
                    if filteredCards.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "text.magnifyingglass")
                                .font(.system(size: 30))
                                .foregroundColor(.secondary.opacity(0.35))
                            Text(viewModel.searchQuery.isEmpty ? "Chưa có thẻ nào trong bộ thẻ này" : "Không tìm thấy thẻ nào phù hợp")
                                .font(.lexioCaption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                        .liquidGlassCard(cornerRadius: 12)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(filteredCards.enumerated()), id: \.element.id) { index, card in
                                CardRowView(
                                    card: card,
                                    language: deck.language,
                                    showContainer: false,
                                    onToggleStar: {
                                        var updated = card
                                        updated.starred.toggle()
                                        storage.updateCardInDeck(deckId: deck.id, card: updated)
                                    },
                                    onDelete: {
                                        viewModel.cardToDelete = card
                                    }
                                )
                                
                                if index < filteredCards.count - 1 {
                                    Divider()
                                        .padding(.leading, 16)
                                        .opacity(0.35)
                                }
                            }
                        }
                        .liquidGlassCard(cornerRadius: 12)
                    }
                }
                .padding(24)
            }
            // Floating Toast notification
            if let toast = viewModel.toastMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(toast)
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(NSColor.separatorColor).opacity(0.8), lineWidth: 0.5)
                )
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color.clear)
        .sheet(isPresented: $viewModel.showDirectCSVEditor) {
            DirectCSVEditorSheet(
                deckTitle: currentDeck.title,
                initialCards: currentDeck.cards,
                onSave: { newCards in
                    var updated = currentDeck
                    updated.cards = newCards
                    storage.saveDeck(updated)
                    showToast("Đã lưu thành công \(newCards.count) thẻ vào bộ \"\(updated.title)\"!")
                }
            )
        }
        .confirmationDialog(
            "Bạn có chắc muốn xóa bộ thẻ \"\(currentDeck.title)\"?",
            isPresented: $viewModel.showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Xóa Bộ Thẻ", role: .destructive) {
                onDeleteDeck()
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("Hành động này sẽ xóa vĩnh viễn \(currentDeck.cards.count) thẻ từ vựng và lịch sử học tập. Không thể hoàn tác.")
        }
        .confirmationDialog(
            "Xóa từ vựng \"\(viewModel.cardToDelete?.term ?? "")\"?",
            isPresented: Binding(
                get: { viewModel.cardToDelete != nil },
                set: { if !$0 { viewModel.cardToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Xóa Thẻ", role: .destructive) {
                if let card = viewModel.cardToDelete {
                    storage.deleteCard(deckId: currentDeck.id, cardId: card.id)
                    viewModel.cardToDelete = nil
                    showToast("Đã xóa thẻ \"\(card.term)\"")
                }
            }
            Button("Hủy", role: .cancel) {}
        }
    }
    
    @ViewBuilder
    private func studyModeButton(for mode: StudyMode, label: String, icon: String) -> some View {
        Button(action: { onStartStudy(mode) }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(mode.tintColor)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .disabled(currentDeck.cards.isEmpty)
        .help("Bắt đầu luyện tập chế độ \(mode.rawValue)")
    }
    
    private func exportCSV() {
        let panel = NSSavePanel()
        let safeTitle = currentDeck.title.replacingOccurrences(of: "[^a-zA-Z0-9_\\-]", with: "_", options: .regularExpression)
        panel.nameFieldStringValue = "\(safeTitle)_Flashcards.csv"
        panel.canCreateDirectories = true
        panel.prompt = "Lưu File CSV"
        
        if panel.runModal() == .OK, let url = panel.url {
            let csv = CSVService.exportDeckToCSV(deck: currentDeck)
            do {
                try csv.write(to: url, atomically: true, encoding: .utf8)
                showToast("Đã xuất thành công file CSV ra \"\(url.lastPathComponent)\"")
            } catch {
                showToast("Lỗi khi lưu file CSV: \(error.localizedDescription)")
            }
        }
    }
    
    private func importCSVToThisDeck() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.commaSeparatedText, .tabSeparatedText, .plainText]
        panel.prompt = "Chọn File CSV"
        panel.message = "Chọn file CSV để cập nhật vào bộ thẻ \"\(currentDeck.title)\""
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                let cards = CSVService.parseCSV(content: content)
                guard !cards.isEmpty else {
                    let alert = NSAlert()
                    alert.messageText = "Không tìm thấy thẻ hợp lệ"
                    alert.informativeText = "File CSV vừa chọn không chứa dữ liệu thẻ từ vựng hợp lệ (cần tối thiểu cột Term và Definition)."
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "Đóng")
                    alert.runModal()
                    return
                }
                
                let alert = NSAlert()
                alert.messageText = "Cập nhật bộ thẻ \"\(currentDeck.title)\""
                alert.informativeText = "Đã nhận diện thành công \(cards.count) thẻ từ file \"\(url.lastPathComponent)\".\n\nBạn muốn ghi đè toàn bộ danh sách thẻ hiện tại hay thêm nối tiếp thẻ mới vào bộ này?"
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Ghi Đè Toàn Bộ (\(cards.count) Thẻ)")
                alert.addButton(withTitle: "Thêm Nối Tiếp (+\(cards.count) Thẻ)")
                alert.addButton(withTitle: "Hủy")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    var updated = currentDeck
                    updated.cards = cards
                    storage.saveDeck(updated)
                    showToast("Đã ghi đè thành công \(cards.count) thẻ vào bộ \"\(updated.title)\"!")
                } else if response == .alertSecondButtonReturn {
                    var updated = currentDeck
                    updated.cards.append(contentsOf: cards)
                    storage.saveDeck(updated)
                    showToast("Đã thêm nối tiếp \(cards.count) thẻ vào bộ \"\(updated.title)\" (tổng \(updated.cards.count) thẻ)!")
                }
            } catch {
                let alert = NSAlert()
                alert.messageText = "Lỗi khi đọc file CSV"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .critical
                alert.addButton(withTitle: "Đóng")
                alert.runModal()
            }
        }
    }
    
    private func showToast(_ message: String) {
        withAnimation {
            viewModel.toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                if viewModel.toastMessage == message {
                    viewModel.toastMessage = nil
                }
            }
        }
    }
}

private struct StatPill: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(tint)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
