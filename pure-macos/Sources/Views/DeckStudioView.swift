import SwiftUI

public class DeckStudioViewModel: ObservableObject {
    @Published public var title: String = ""
    @Published public var description: String = ""
    @Published public var language: String = "en-US"
    @Published public var category: String = "General"
    @Published public var colorHex: String = "#FF2A6D"
    @Published public var cards: [Flashcard] = []
    @Published public var showDirectCSVEditor: Bool = false
    
    public init(deckToEdit: Deck?) {
        if let deck = deckToEdit {
            self.title = deck.title
            self.description = deck.description
            self.language = deck.language
            self.category = deck.category
            self.colorHex = deck.colorHex
            self.cards = deck.cards
        } else {
            self.cards = [Flashcard(term: "", definition: "")]
        }
    }
    
    public func addCard() {
        cards.append(Flashcard(term: "", definition: ""))
    }
}

public struct DeckStudioView: View {
    @Environment(\.dismiss) private var dismiss
    
    public var deckToEdit: Deck?
    public var onSave: (Deck) -> Void
    
    @StateObject private var vm: DeckStudioViewModel
    
    public init(deckToEdit: Deck? = nil, onSave: @escaping (Deck) -> Void) {
        self.deckToEdit = deckToEdit
        self.onSave = onSave
        _vm = StateObject(wrappedValue: DeckStudioViewModel(deckToEdit: deckToEdit))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Text(deckToEdit == nil ? "Tạo Bộ Thẻ Mới" : "Chỉnh Sửa Bộ Thẻ")
                    .font(.lexioTitle)
                
                Spacer()
                
                Button("Hủy") {
                    ColorPanelManager.shared.close()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Lưu Bộ Thẻ") {
                    ColorPanelManager.shared.close()
                    save()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(vm.title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(18)
            .background(VisualEffectView(material: .titlebar, blendingMode: .withinWindow))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // Deck Metadata Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Thông Tin Bộ Thẻ")
                            .font(.lexioSection)
                            .foregroundColor(.secondary)
                        
                        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 10) {
                            GridRow {
                                Text("Tên bộ thẻ *:")
                                    .font(.lexioBody)
                                TextField("VD: Oxford 3000 Academic", text: $vm.title)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.lexioBody)
                            }
                            
                            GridRow {
                                Text("Mô tả:")
                                    .font(.lexioBody)
                                TextField("VD: Từ vựng học thuật C1-C2", text: $vm.description)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.lexioBody)
                            }
                            
                            GridRow {
                                Text("Danh mục:")
                                    .font(.lexioBody)
                                TextField("VD: Academic, IT, Daily...", text: $vm.category)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.lexioBody)
                            }
                            
                            GridRow {
                                Text("Màu nhận diện:")
                                    .font(.lexioBody)
                                DeckColorPickerRow(selectedHex: $vm.colorHex)
                            }
                        }
                        .padding(16)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(NSColor.separatorColor).opacity(0.7), lineWidth: 1)
                        )
                    }
                    
                    // Cards Management Section
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Danh Sách Từ Vựng (\(vm.cards.count))")
                                .font(.lexioSection)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Button(action: { vm.showDirectCSVEditor = true }) {
                                    Label("Sửa Nhanh CSV", systemImage: "tablecells.badge.ellipsis")
                                }
                                .buttonStyle(.bordered)
                                .help("Mở bảng soạn thảo CSV để copy/paste hoặc sửa nhanh toàn bộ thẻ mà không cần cuộn trang")
                                
                                Button(action: { vm.addCard() }) {
                                    Label("Thêm Thẻ", systemImage: "plus")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        
                        ForEach(vm.cards.indices, id: \.self) { index in
                            CardEditorRow(
                                index: index + 1,
                                card: $vm.cards[index],
                                onDelete: {
                                    if vm.cards.count > 1 {
                                        vm.cards.remove(at: index)
                                    }
                                },
                                onDuplicate: {
                                    let copy = vm.cards[index]
                                    var newCard = copy
                                    newCard.id = UUID().uuidString
                                    vm.cards.insert(newCard, at: index + 1)
                                }
                            )
                        }
                        
                        Button(action: { vm.addCard() }) {
                            HStack {
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                Text("Thêm Thẻ Mới")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(24)
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .sheet(isPresented: $vm.showDirectCSVEditor) {
            DirectCSVEditorSheet(
                deckTitle: vm.title.isEmpty ? "Bộ thẻ mới" : vm.title,
                initialCards: vm.cards,
                onSave: { newCards in
                    vm.cards = newCards
                }
            )
        }
        .onDisappear {
            ColorPanelManager.shared.close()
        }
    }
    
    private func save() {
        let validCards = vm.cards.filter { !$0.term.trimmingCharacters(in: .whitespaces).isEmpty || !$0.definition.trimmingCharacters(in: .whitespaces).isEmpty }
        let deck = Deck(
            id: deckToEdit?.id ?? UUID().uuidString,
            title: vm.title.trimmingCharacters(in: .whitespaces),
            description: vm.description.trimmingCharacters(in: .whitespaces),
            language: vm.language,
            targetLanguage: "vi-VN",
            category: vm.category.trimmingCharacters(in: .whitespaces),
            tags: deckToEdit?.tags ?? ["Custom"],
            colorHex: vm.colorHex,
            createdAt: deckToEdit?.createdAt ?? Date(),
            updatedAt: Date(),
            cards: validCards.isEmpty ? [Flashcard(term: "Mẫu", definition: "Nghĩa mẫu")] : validCards
        )
        onSave(deck)
        dismiss()
    }
}

private struct CardEditorRow: View {
    let index: Int
    @Binding var card: Flashcard
    var onDelete: () -> Void
    var onDuplicate: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("#\(index)")
                    .font(.lexioHeadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: onDuplicate) {
                    Image(systemName: "doc.on.doc")
                        .font(.lexioBody)
                }
                .buttonStyle(.plain)
                .help("Nhân đôi thẻ này")
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.lexioBody)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Xóa thẻ")
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Từ vựng / Cụm từ *").font(.lexioCaptionMedium).foregroundColor(.secondary)
                    TextField("Word / Term", text: $card.term)
                        .textFieldStyle(.roundedBorder)
                        .font(.lexioBody)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Phiên âm (IPA)").font(.lexioCaptionMedium).foregroundColor(.secondary)
                    TextField("/aɪˈpiː.eɪ/", text: Binding(
                        get: { card.phonetic ?? "" },
                        set: { card.phonetic = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.lexioBody)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Từ loại").font(.lexioCaptionMedium).foregroundColor(.secondary)
                    TextField("noun, verb, adj...", text: Binding(
                        get: { card.partOfSpeech ?? "" },
                        set: { card.partOfSpeech = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.lexioBody)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Định nghĩa / Nghĩa tiếng Việt *").font(.lexioCaptionMedium).foregroundColor(.secondary)
                TextField("Nghĩa của từ...", text: $card.definition)
                    .textFieldStyle(.roundedBorder)
                    .font(.lexioBody)
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Câu ví dụ").font(.lexioCaptionMedium).foregroundColor(.secondary)
                    TextField("Example sentence...", text: Binding(
                        get: { card.example ?? "" },
                        set: { card.example = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.lexioBody)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dịch câu ví dụ").font(.lexioCaptionMedium).foregroundColor(.secondary)
                    TextField("Dịch nghĩa ví dụ...", text: Binding(
                        get: { card.exampleTranslation ?? "" },
                        set: { card.exampleTranslation = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.lexioBody)
                }
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cấu trúc ngữ pháp / Phrasal pattern").font(.lexioCaptionMedium).foregroundColor(.secondary)
                    TextField("VD: take sth with a pinch of salt...", text: Binding(
                        get: { card.grammarPattern ?? "" },
                        set: { card.grammarPattern = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.lexioBody)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ghi chú / Mẹo nhớ").font(.lexioCaptionMedium).foregroundColor(.secondary)
                    TextField("Từ đồng nghĩa, mẹo nhớ...", text: Binding(
                        get: { card.notes ?? "" },
                        set: { card.notes = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.lexioBody)
                }
            }
        }
        .padding(14)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(NSColor.separatorColor).opacity(0.7), lineWidth: 1)
        )
    }
}
