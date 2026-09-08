import SwiftUI

public final class DeckListViewModel: ObservableObject {
    @Published public var searchQuery: String = ""
    @Published public var selectedCategory: String = "Tất cả"
    
    public init() {}
}

public struct DeckListView: View {
    @ObservedObject private var storage = StorageService.shared
    @StateObject private var viewModel = DeckListViewModel()
    
    public var onSelectDeck: (Deck) -> Void
    public var onNewDeck: () -> Void
    public var onImportCSV: () -> Void
    public var onDownloadSampleCSV: () -> Void
    
    public init(
        onSelectDeck: @escaping (Deck) -> Void,
        onNewDeck: @escaping () -> Void,
        onImportCSV: @escaping () -> Void,
        onDownloadSampleCSV: @escaping () -> Void = {}
    ) {
        self.onSelectDeck = onSelectDeck
        self.onNewDeck = onNewDeck
        self.onImportCSV = onImportCSV
        self.onDownloadSampleCSV = onDownloadSampleCSV
    }
    
    private var categories: [String] {
        let cats = Set(storage.decks.map { $0.category })
        return ["Tất cả"] + Array(cats).sorted()
    }
    
    private var filteredDecks: [Deck] {
        storage.decks.filter { deck in
            let matchSearch = viewModel.searchQuery.isEmpty ||
                deck.title.localizedCaseInsensitiveContains(viewModel.searchQuery) ||
                deck.description.localizedCaseInsensitiveContains(viewModel.searchQuery) ||
                deck.cards.contains { $0.term.localizedCaseInsensitiveContains(viewModel.searchQuery) }
            
            let matchCat = viewModel.selectedCategory == "Tất cả" || deck.category == viewModel.selectedCategory
            return matchSearch && matchCat
        }
    }
    
    private var totalCards: Int {
        storage.decks.reduce(0) { $0 + $1.cards.count }
    }
    
    private var totalDueToday: Int {
        storage.decks.reduce(0) { $0 + $1.dueCardsCount }
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Clean Apple Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Thư Viện Bộ Thẻ")
                            .font(.lexioTitle)
                            .foregroundColor(.primary)
                        
                        Text("\(filteredDecks.count) bộ thẻ • \(totalCards) từ vựng • \(totalDueToday) cần ôn hôm nay")
                            .font(.lexioCaption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 10) {
                        Button(action: onNewDeck) {
                            Label("Bộ Thẻ Mới", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        
                        Menu {
                            Button(action: onImportCSV) {
                                Label("Chọn File CSV Để Nhập...", systemImage: "arrow.down.doc")
                            }
                            Divider()
                            Button(action: onDownloadSampleCSV) {
                                Label("Tải Mẫu CSV Chuẩn (.csv)...", systemImage: "square.and.arrow.down")
                            }
                        } label: {
                            Label("Nhập CSV", systemImage: "arrow.down.doc")
                        }
                        .menuStyle(.borderedButton)
                        .controlSize(.regular)
                        .help("Nhập từ vựng hoặc tải file CSV mẫu chuẩn")
                    }
                }
                .padding(.bottom, 4)
                
                // Clean Search & Category Controls
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.lexioBody)
                        
                        TextField("Tìm kiếm bộ thẻ hoặc từ vựng...", text: $viewModel.searchQuery)
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                    )
                    
                    if categories.count > 1 {
                        Picker("Danh mục:", selection: $viewModel.selectedCategory) {
                            ForEach(categories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }
                }
                
                // Deck Cards Grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280, maximum: 380), spacing: 16)], spacing: 16) {
                    ForEach(filteredDecks) { deck in
                        Button(action: {
                            onSelectDeck(deck)
                        }) {
                            DeckCardTile(deck: deck)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if filteredDecks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "square.stack.3d.up.slash")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("Không có bộ thẻ nào phù hợp")
                            .font(.lexioCaption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
            }
            .padding(24)
        }
        .background(Color.clear)
    }
}

private struct DeckCardTile: View {
    let deck: Deck
    
    private var deckColor: Color {
        Color(hex: deck.colorHex)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Clean Apple Icon Square
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(deckColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 18))
                        .foregroundColor(deckColor)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(deck.category)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text(deck.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            
            if !deck.description.isEmpty {
                Text(deck.description)
                    .font(.lexioCaption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            } else {
                Spacer().frame(height: 14)
            }
            
            Spacer()
            
            Divider().opacity(0.4)
            
            HStack {
                Label("\(deck.cards.count) thẻ", systemImage: "rectangle.stack")
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if deck.dueCardsCount > 0 {
                    Text("\(deck.dueCardsCount) cần ôn")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(Color.red.opacity(0.12))
                        .clipShape(Capsule())
                } else {
                    Text("Đã ôn hết")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
        .padding(16)
        .frame(height: 155)
        .liquidGlassCard(cornerRadius: 14, isInteractive: true)
    }
}
