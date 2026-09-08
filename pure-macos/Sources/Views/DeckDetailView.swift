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
                    // Back Navigation Link
                    if let back = onBack {
                        Button(action: back) {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Tất cả bộ thẻ")
                                    .font(.lexioBody)
                            }
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // MARK: - 1. Liquid Glass Header & Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text(currentDeck.category)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.accentColor)
                                        .liquidGlassPill(isHighlighted: true)
                                    
                                    Text(currentDeck.language)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .liquidGlassPill(isHighlighted: false)
                                }
                                
                                Text(currentDeck.title)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                if !currentDeck.description.isEmpty {
                                    Text(currentDeck.description)
                                        .font(.lexioBody)
                                        .foregroundColor(.secondary)
                                        .lineSpacing(2)
                                }
                            }
                            
                            Spacer(minLength: 16)
                            
                            // Top-Right Actions: Menu CSV & Chỉnh sửa
                            HStack(spacing: 8) {
                                Menu {
                                    Section("Soạn Thảo & Cập Nhật") {
                                        Button(action: { viewModel.showDirectCSVEditor = true }) {
                                            Label("Sửa Nhanh Dạng Bảng CSV...", systemImage: "tablecells.badge.ellipsis")
                                        }
                                        Button(action: importCSVToThisDeck) {
                                            Label("Cập Nhật Thêm Từ File CSV...", systemImage: "arrow.up.doc")
                                        }
                                    }
                                    
                                    Section("Xuất Dữ Liệu") {
                                        Button(action: exportCSV) {
                                            Label("Xuất File CSV Bộ Thẻ Này...", systemImage: "arrow.down.doc")
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: "tablecells")
                                            .font(.system(size: 12, weight: .medium))
                                        Text("Dữ Liệu & CSV")
                                            .font(.system(size: 12, weight: .medium))
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 9, weight: .semibold))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.thinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
                                    )
                                }
                                .menuStyle(.borderlessButton)
                                .help("Sửa nhanh bảng tính CSV, nạp thêm hoặc xuất dữ liệu bộ thẻ này")
                                
                                Button(action: onEditDeck) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 12, weight: .medium))
                                        Text("Sửa")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.thinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
                                    )
                                }
                                .buttonStyle(.plain)
                                .help("Chỉnh sửa thông tin và danh sách thẻ trong Studio")
                                
                                Button(action: { viewModel.showDeleteConfirm = true }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.red.opacity(0.85))
                                        .padding(6)
                                        .background(.thinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
                                        )
                                }
                                .buttonStyle(.plain)
                                .help("Xóa bộ thẻ này")
                            }
                        }
                    }
                    .padding(18)
                    .liquidGlassCard(cornerRadius: 16)
                    
                    // MARK: - 2. Hero Primary Study Action (Trung tâm điều hướng cho người mới)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                currentDeck.dueCardsCount > 0 ? Color(hex: "#FF375F") : Color(hex: "#0A84FF"),
                                                currentDeck.dueCardsCount > 0 ? Color(hex: "#FF9F0A") : Color(hex: "#30D158")
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 48, height: 48)
                                    .shadow(color: (currentDeck.dueCardsCount > 0 ? Color.red : Color.blue).opacity(0.3), radius: 10, y: 4)
                                
                                Image(systemName: currentDeck.dueCardsCount > 0 ? "brain.head.profile" : "sparkles")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                if currentDeck.dueCardsCount > 0 {
                                    Text("Đến giờ ôn tập thông minh")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text("Có \(currentDeck.dueCardsCount) thẻ vựng đến hạn ôn hôm nay theo thuật toán ngắt quãng (SRS).")
                                        .font(.system(size: 12.5))
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Bạn đã hoàn thành mục tiêu ôn tập hôm nay!")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text("Tổng cộng \(currentDeck.cards.count) thẻ vựng. Bạn có thể lật thẻ ôn lại hoặc thử sức với các bài tập.")
                                        .font(.system(size: 12.5))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer(minLength: 16)
                            
                            // Nút Bắt Đầu Học Chính (Hero CTA)
                            Button(action: {
                                if currentDeck.dueCardsCount > 0 {
                                    onStartStudy(.srs)
                                } else {
                                    onStartStudy(.flashcards)
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 13, weight: .bold))
                                    Text(currentDeck.dueCardsCount > 0 ? "Ôn Tập Ngay (\(currentDeck.dueCardsCount))" : "Bắt Đầu Lật Thẻ")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    LinearGradient(
                                        colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .shadow(color: Color.accentColor.opacity(0.35), radius: 8, y: 3)
                            }
                            .buttonStyle(.plain)
                            .disabled(currentDeck.cards.isEmpty)
                        }
                    }
                    .padding(18)
                    .liquidGlassCard(cornerRadius: 16, isInteractive: true)
                    
                    // MARK: - 3. Slim Liquid Glass Stat Strip (Thu gọn 4 khối KPI cồng kềnh)
                    HStack(spacing: 0) {
                        StatPill(
                            title: "Tổng số thẻ",
                            value: "\(currentDeck.cards.count)",
                            icon: "square.stack.3d.up.fill",
                            tint: Color(hex: "#0A84FF")
                        )
                        
                        Divider().frame(height: 28).opacity(0.4)
                        
                        StatPill(
                            title: "Cần ôn hôm nay",
                            value: "\(currentDeck.dueCardsCount)",
                            icon: "clock.badge.exclamationmark.fill",
                            tint: currentDeck.dueCardsCount > 0 ? Color(hex: "#FF453A") : Color(hex: "#30D158")
                        )
                        
                        Divider().frame(height: 28).opacity(0.4)
                        
                        StatPill(
                            title: "Gắn sao",
                            value: "\(currentDeck.starredCardsCount)",
                            icon: "star.fill",
                            tint: Color(hex: "#FF9F0A")
                        )
                        
                        Divider().frame(height: 28).opacity(0.4)
                        
                        StatPill(
                            title: "Độ dễ SM-2",
                            value: String(format: "%.1f", currentDeck.averageEaseFactor),
                            icon: "brain.head.profile",
                            tint: Color(hex: "#BF5AF2")
                        )
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .liquidGlassCard(cornerRadius: 12)
                    
                    // MARK: - 4. Study Modes Strip (5 Chế độ học gọn gàng, thanh lịch)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Chế Độ Luyện Tập")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 10) {
                            studyModeButton(for: .flashcards, label: "Lật Thẻ", icon: "rectangle.stack")
                            studyModeButton(for: .srs, label: "Học SRS", icon: "brain")
                            studyModeButton(for: .write, label: "Gõ Từ", icon: "keyboard")
                            studyModeButton(for: .match, label: "Ghép Thẻ", icon: "square.grid.2x2")
                            studyModeButton(for: .test, label: "Kiểm Tra", icon: "checkmark.seal")
                        }
                    }
                    
                    // MARK: - 5. Cards Filter & Search Bar
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 13))
                                TextField("Tìm kiếm từ vựng, định nghĩa...", text: $viewModel.searchQuery)
                                    .textFieldStyle(.plain)
                                    .font(.lexioBody)
                                if !viewModel.searchQuery.isEmpty {
                                    Button(action: { viewModel.searchQuery = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 12))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                            )
                            
                            // Filter Starred
                            Toggle(isOn: $viewModel.onlyStarred) {
                                Label("Gắn sao", systemImage: "star.fill")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .toggleStyle(.button)
                            .controlSize(.regular)
                            
                            // Tag Picker
                            if allTags.count > 1 {
                                Picker("Nhãn:", selection: $viewModel.selectedTag) {
                                    ForEach(allTags, id: \.self) { tag in
                                        Text(tag).tag(tag)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 130)
                                .font(.system(size: 12))
                            }
                        }
                        
                        // Cards List
                        VStack(spacing: 10) {
                            ForEach(filteredCards) { card in
                                CardRowView(
                                    card: card,
                                    language: deck.language,
                                    onToggleStar: {
                                        var updated = card
                                        updated.starred.toggle()
                                        storage.updateCardInDeck(deckId: deck.id, card: updated)
                                    },
                                    onDelete: {
                                        viewModel.cardToDelete = card
                                    }
                                )
                            }
                            
                            if filteredCards.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "text.magnifyingglass")
                                        .font(.system(size: 32))
                                        .foregroundColor(.secondary.opacity(0.4))
                                    Text("Không tìm thấy thẻ nào phù hợp")
                                        .font(.lexioCaption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            }
                        }
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
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .shadow(radius: 6)
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
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(mode.tintColor)
                Text(label)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), Color.white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
        }
        .buttonStyle(.plain)
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
