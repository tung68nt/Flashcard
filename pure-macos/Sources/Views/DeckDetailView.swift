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
    
    // Practice Session Limit
    @Published public var sessionLimit: Int = 0 // 0 = Tất cả thẻ
    @Published public var isCustomLimit: Bool = false
    @Published public var customLimitInput: Int = 20
    @Published public var isCustomPopoverPresented: Bool = false
    @Published public var hoveredMode: StudyMode? = nil
    
    public init() {}
}

public struct DeckDetailView: View {
    public let deck: Deck
    public var onBack: (() -> Void)? = nil
    public var onStartStudy: (StudyMode, Int?) -> Void
    public var onEditDeck: () -> Void
    public var onDeleteDeck: () -> Void
    
    @ObservedObject private var storage = StorageService.shared
    @StateObject private var viewModel = DeckDetailViewModel()
    
    public init(
        deck: Deck,
        onBack: (() -> Void)? = nil,
        onStartStudy: @escaping (StudyMode, Int?) -> Void,
        onEditDeck: @escaping () -> Void,
        onDeleteDeck: @escaping () -> Void
    ) {
        self.deck = deck
        self.onBack = onBack
        self.onStartStudy = onStartStudy
        self.onEditDeck = onEditDeck
        self.onDeleteDeck = onDeleteDeck
    }
    
    private var effectiveLimit: Int? {
        if viewModel.isCustomLimit {
            return viewModel.customLimitInput > 0 ? viewModel.customLimitInput : nil
        }
        return viewModel.sessionLimit > 0 ? viewModel.sessionLimit : nil
    }
    
    private var srsTargetCount: Int {
        let poolCount = currentDeck.dueCardsCount > 0 ? currentDeck.dueCardsCount : currentDeck.cards.count
        if let limit = effectiveLimit {
            return min(limit, poolCount)
        }
        return poolCount
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
                    }
                    .padding(16)
                    .liquidGlassCard(cornerRadius: 14)
                    
                    // MARK: - 2. PRACTICE MODES HUB (Chế Độ Luyện Tập Sống Động & Tùy Chọn Số Thẻ)
                    VStack(alignment: .leading, spacing: 14) {
                        // Section Header + Session Size Controls
                        HStack(alignment: .center) {
                            HStack(spacing: 7) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "#FF9F0A"))
                                Text("Chế Độ Luyện Tập")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            // Custom Session Limit Selector (Quy định số thẻ học hôm nay)
                            HStack(spacing: 5) {
                                Text("Số thẻ học:")
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                sessionLimitChip(num: 10)
                                sessionLimitChip(num: 20)
                                sessionLimitChip(num: 30)
                                sessionLimitAllChip
                                sessionLimitCustomChip
                            }
                        }
                        
                        // 1. Featured Flagship: Spaced Repetition (SRS) Card
                        Button(action: {
                            onStartStudy(.srs, effectiveLimit)
                        }) {
                            HStack(spacing: 16) {
                                // Vibrant Glowing Icon Badge
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "#FF2A6D"), Color(hex: "#7928CA")],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 46, height: 46)
                                        .shadow(color: Color(hex: "#FF2A6D").opacity(0.35), radius: 8, x: 0, y: 3)
                                    
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text("Ôn Tập Thông Minh SRS")
                                            .font(.system(size: 14.5, weight: .bold))
                                            .foregroundColor(.primary)
                                        
                                        // Dynamic Due Badge
                                        if currentDeck.dueCardsCount > 0 {
                                            HStack(spacing: 4) {
                                                Image(systemName: "flame.fill")
                                                    .font(.system(size: 9.5))
                                                Text("\(currentDeck.dueCardsCount) thẻ đến hạn")
                                                    .font(.system(size: 10.5, weight: .bold))
                                            }
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 2.5)
                                            .background(Color(hex: "#FF453A").opacity(0.12))
                                            .foregroundColor(Color(hex: "#FF453A"))
                                            .cornerRadius(6)
                                        } else {
                                            HStack(spacing: 4) {
                                                Image(systemName: "checkmark.seal.fill")
                                                    .font(.system(size: 9.5))
                                                Text("Đã ôn xong hôm nay")
                                                    .font(.system(size: 10.5, weight: .bold))
                                            }
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 2.5)
                                            .background(Color(hex: "#30D158").opacity(0.12))
                                            .foregroundColor(Color(hex: "#30D158"))
                                            .cornerRadius(6)
                                        }
                                    }
                                    
                                    Text("Thuật toán ngắt quãng SM-2 khoa học • Tự động lên lịch theo đường cong quên lãng")
                                        .font(.system(size: 11.5))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer(minLength: 8)
                                
                                // Play Pill CTA
                                HStack(spacing: 6) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 10.5, weight: .bold))
                                    Text(srsTargetCount > 0 ? "Ôn (\(srsTargetCount)) Thẻ" : "Ôn Ngay")
                                        .font(.system(size: 12.5, weight: .semibold))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "#0A84FF"), Color(hex: "#0066CC")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .shadow(color: Color(hex: "#0A84FF").opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.85))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                viewModel.hoveredMode == .srs ? Color(hex: "#FF2A6D").opacity(0.6) : Color.primary.opacity(0.08),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                            .scaleEffect(viewModel.hoveredMode == .srs ? 1.01 : 1.0)
                            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: viewModel.hoveredMode)
                        }
                        .buttonStyle(.plain)
                        .onHover { h in viewModel.hoveredMode = h ? .srs : nil }
                        .disabled(currentDeck.cards.isEmpty)
                        
                        // 2. Grid of 4 Companion Practice Modes
                        HStack(spacing: 10) {
                            // Flashcards 3D
                            PracticeModeTile(
                                title: "Lật Thẻ 3D",
                                subtitle: "Lật 2 mặt kèm audio",
                                icon: "rectangle.portrait.on.rectangle.portrait.angled.fill",
                                gradientColors: [Color(hex: "#FF7A00"), Color(hex: "#FF512F")],
                                isHovered: viewModel.hoveredMode == .flashcards,
                                onHover: { h in viewModel.hoveredMode = h ? .flashcards : nil },
                                onTap: { onStartStudy(.flashcards, effectiveLimit) }
                            )
                            
                            // Write & Recall
                            PracticeModeTile(
                                title: "Gõ Từ Vựng",
                                subtitle: "Luyện phản xạ chính tả",
                                icon: "keyboard.fill",
                                gradientColors: [Color(hex: "#00C9FF"), Color(hex: "#0072FF")],
                                isHovered: viewModel.hoveredMode == .write,
                                onHover: { h in viewModel.hoveredMode = h ? .write : nil },
                                onTap: { onStartStudy(.write, effectiveLimit) }
                            )
                            
                            // Speed Match Game
                            PracticeModeTile(
                                title: "Ghép Thẻ Nhanh",
                                subtitle: "Nối nhanh từ & nghĩa",
                                icon: "bolt.fill",
                                gradientColors: [Color(hex: "#F7971E"), Color(hex: "#FFD200")],
                                isHovered: viewModel.hoveredMode == .match,
                                onHover: { h in viewModel.hoveredMode = h ? .match : nil },
                                onTap: { onStartStudy(.match, effectiveLimit) }
                            )
                            
                            // Practice Test
                            PracticeModeTile(
                                title: "Bài Kiểm Tra",
                                subtitle: "Trắc nghiệm & chấm điểm",
                                icon: "checkmark.seal.fill",
                                gradientColors: [Color(hex: "#11998E"), Color(hex: "#38EF7D")],
                                isHovered: viewModel.hoveredMode == .test,
                                onHover: { h in viewModel.hoveredMode = h ? .test : nil },
                                onTap: { onStartStudy(.test, effectiveLimit) }
                            )
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
    private func sessionLimitChip(num: Int) -> some View {
        let isSelected = (viewModel.sessionLimit == num && !viewModel.isCustomLimit)
        Button(action: {
            viewModel.sessionLimit = num
            viewModel.isCustomLimit = false
        }) {
            Text("\(num)")
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(isSelected ? Color.accentColor : Color.primary.opacity(0.06))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var sessionLimitAllChip: some View {
        let isSelected = (viewModel.sessionLimit == 0 && !viewModel.isCustomLimit)
        Button(action: {
            viewModel.sessionLimit = 0
            viewModel.isCustomLimit = false
        }) {
            Text("Tất cả")
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(isSelected ? Color.accentColor : Color.primary.opacity(0.06))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var sessionLimitCustomChip: some View {
        Button(action: {
            viewModel.isCustomPopoverPresented = true
        }) {
            HStack(spacing: 3) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 10))
                Text(viewModel.isCustomLimit ? "\(viewModel.customLimitInput) thẻ" : "Tùy chỉnh")
                    .font(.system(size: 11, weight: viewModel.isCustomLimit ? .bold : .medium))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background(viewModel.isCustomLimit ? Color.accentColor : Color.primary.opacity(0.06))
            .foregroundColor(viewModel.isCustomLimit ? .white : .primary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $viewModel.isCustomPopoverPresented) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.accentColor)
                    Text("Quy Định Số Thẻ Phiên Này")
                        .font(.system(size: 13, weight: .bold))
                }
                
                Text("Đặt số lượng thẻ bạn muốn tập trung ôn luyện trong phiên này (từ 1 đến \(max(1, currentDeck.cards.count)) thẻ).")
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 10) {
                    TextField("Số thẻ", value: $viewModel.customLimitInput, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                    
                    Stepper("", value: $viewModel.customLimitInput, in: 1...max(1, currentDeck.cards.count))
                        .labelsHidden()
                    
                    Text("/ \(currentDeck.cards.count) thẻ")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Button("Hủy") {
                        viewModel.isCustomPopoverPresented = false
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Áp Dụng") {
                        viewModel.customLimitInput = max(1, min(viewModel.customLimitInput, currentDeck.cards.count))
                        viewModel.isCustomLimit = true
                        viewModel.isCustomPopoverPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(14)
            .frame(width: 270)
        }
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

struct PracticeModeTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
    let isHovered: Bool
    let onHover: (Bool) -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                            .shadow(color: gradientColors[0].opacity(0.35), radius: 4, x: 0, y: 2)
                        
                        Image(systemName: icon)
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isHovered ? gradientColors[0] : .secondary.opacity(0.35))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 11)
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(
                                isHovered ? gradientColors[0].opacity(0.6) : Color.primary.opacity(0.07),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover(perform: onHover)
    }
}

