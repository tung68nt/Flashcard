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
                VStack(alignment: .leading, spacing: 20) {
                    // Back Button
                    if let back = onBack {
                        Button(action: back) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Tất cả bộ thẻ")
                            }
                            .font(.lexioBody)
                            .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Clean Header Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack(spacing: 8) {
                                    Text(currentDeck.category)
                                        .font(.lexioCaptionMedium)
                                        .foregroundColor(.secondary)
                                    
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    
                                    Text(currentDeck.language)
                                        .font(.lexioCaptionMedium)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(currentDeck.title)
                                    .font(.lexioTitle)
                                    .foregroundColor(.primary)
                                
                                if !currentDeck.description.isEmpty {
                                    Text(currentDeck.description)
                                        .font(.lexioBody)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer(minLength: 16)
                            
                            // Top-Right Actions: Chỉnh Sửa thông tin & Xóa
                            HStack(spacing: 8) {
                                Button(action: onEditDeck) {
                                    Label("Chỉnh Sửa", systemImage: "pencil")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.regular)
                                .fixedSize(horizontal: true, vertical: false)
                                .help("Chỉnh sửa thông tin và danh sách thẻ trong Studio")
                                
                                Button(action: { viewModel.showDeleteConfirm = true }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.regular)
                                .fixedSize(horizontal: true, vertical: false)
                                .help("Xóa bộ thẻ này")
                            }
                        }
                        
                        Divider()
                            .opacity(0.6)
                        
                        // Bottom Action Strip: Thao tác dữ liệu CSV (Độc lập, rộng rãi, tuyệt đối không bị khuất chữ)
                        HStack(spacing: 10) {
                            // 1. Sửa trực tiếp dạng CSV / Bảng
                            Button(action: { viewModel.showDirectCSVEditor = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "tablecells.badge.ellipsis")
                                        .foregroundColor(.accentColor)
                                    Text("Sửa Nhanh CSV")
                                        .fontWeight(.medium)
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            .fixedSize(horizontal: true, vertical: false)
                            .help("Mở bảng soạn thảo CSV trực tiếp, sửa hoặc copy/paste từ Excel/Sheets rồi lưu ngay")
                            
                            // 2. Nạp file CSV cập nhật đúng bộ này
                            Button(action: importCSVToThisDeck) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.up.doc")
                                        .foregroundColor(.blue)
                                    Text("Cập Nhật CSV")
                                        .fontWeight(.medium)
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            .fixedSize(horizontal: true, vertical: false)
                            .help("Nạp file CSV đã sửa vào đúng bộ thẻ này mà không tạo bộ mới")
                            
                            // 3. Tải CSV về máy
                            Button(action: exportCSV) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.down.doc")
                                        .foregroundColor(.secondary)
                                    Text("Tải CSV")
                                        .fontWeight(.medium)
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            .fixedSize(horizontal: true, vertical: false)
                            .help("Tải file CSV của bộ này về máy để chỉnh sửa")
                            
                            Spacer(minLength: 0)
                        }
                    }
                    .padding(18)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(NSColor.separatorColor).opacity(0.7), lineWidth: 1)
                    )
                
                // Modern Apple KPI Metric Cards Grid (2 Cột x 2 Hàng để chữ rộng rãi, không bị khuất chữ)
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        StatMetricCard(
                            title: "Tổng số thẻ",
                            subtitle: "\(currentDeck.cards.count) thẻ vựng",
                            value: "\(currentDeck.cards.count)",
                            icon: "square.stack.3d.up.fill",
                            color: Color(hex: "#0A84FF") // Apple Blue
                        )
                        StatMetricCard(
                            title: "Cần ôn hôm nay",
                            subtitle: currentDeck.dueCardsCount > 0 ? "Sẵn sàng ôn tập" : "Đã hoàn thành",
                            value: "\(currentDeck.dueCardsCount)",
                            icon: "clock.badge.exclamationmark.fill",
                            color: currentDeck.dueCardsCount > 0 ? Color(hex: "#FF453A") : Color(hex: "#30D158") // Apple Red/Green
                        )
                    }
                    GridRow {
                        StatMetricCard(
                            title: "Yêu thích",
                            subtitle: "\(currentDeck.starredCardsCount) thẻ quan trọng",
                            value: "\(currentDeck.starredCardsCount)",
                            icon: "star.fill",
                            color: Color(hex: "#FF9F0A") // Apple Amber
                        )
                        StatMetricCard(
                            title: "Độ dễ SM-2",
                            subtitle: "Hệ số ghi nhớ dài hạn",
                            value: String(format: "%.1f", currentDeck.averageEaseFactor),
                            icon: "brain.head.profile",
                            color: Color(hex: "#BF5AF2") // Apple Purple
                        )
                    }
                }
                
                // 5 Study Modes Section (Equal height per row, full title & description)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Chế Độ Học & Luyện Tập")
                        .font(.lexioSection)
                        .foregroundColor(.primary)
                    
                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                        GridRow {
                            studyModeCard(for: .flashcards)
                            studyModeCard(for: .srs)
                            studyModeCard(for: .write)
                        }
                        GridRow {
                            studyModeCard(for: .match)
                            studyModeCard(for: .test)
                            Color.clear
                        }
                    }
                }
                
                // Flashcards Filter & Search Bar
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .font(.lexioBody)
                            TextField("Tìm kiếm từ vựng, định nghĩa...", text: $viewModel.searchQuery)
                                .textFieldStyle(.plain)
                                .font(.lexioBody)
                            if !viewModel.searchQuery.isEmpty {
                                Button(action: { viewModel.searchQuery = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                        .font(.lexioCaption)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(NSColor.separatorColor).opacity(0.7), lineWidth: 1)
                        )
                        
                        // Filter Starred
                        Toggle(isOn: $viewModel.onlyStarred) {
                            Label("Gắn sao", systemImage: "star.fill")
                                .font(.lexioCaption)
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
                            .font(.lexioCaption)
                        }
                    }
                    
                    // Cards List
                    VStack(spacing: 8) {
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
                            VStack(spacing: 8) {
                                Image(systemName: "text.magnifyingglass")
                                    .font(.system(size: 28))
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
        .background(Color(NSColor.windowBackgroundColor))
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
    private func studyModeCard(for mode: StudyMode) -> some View {
        Button(action: { onStartStudy(mode) }) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(mode.tintColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: mode.iconName)
                        .font(.system(size: 17))
                        .foregroundColor(mode.tintColor)
                }
                .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.rawValue)
                        .font(.lexioHeadline)
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    
                    Text(mode.description)
                        .font(.lexioCaption)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                }
                
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 84, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(NSColor.separatorColor).opacity(0.7), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(currentDeck.cards.isEmpty)
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

private struct StatMetricCard: View {
    let title: String
    let subtitle: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Icon Chip
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.lexioCaptionMedium)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(NSColor.separatorColor).opacity(0.6), lineWidth: 0.8)
        )
    }
}
