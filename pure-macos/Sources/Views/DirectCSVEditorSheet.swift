import SwiftUI
import AppKit

public final class DirectCSVEditorViewModel: ObservableObject {
    @Published public var cards: [Flashcard] = []
    @Published public var csvText: String = ""
    @Published public var selectedTab: Int = 0 // 0: Bảng tính trực quan (Mặc định), 1: Văn bản CSV
    @Published public var showResetConfirm: Bool = false
    @Published public var toastMessage: String? = nil
    
    public init() {}
    
    public var validCardsCount: Int {
        cards.filter { !$0.term.trimmingCharacters(in: .whitespaces).isEmpty || !$0.definition.trimmingCharacters(in: .whitespaces).isEmpty }.count
    }
    
    public func syncToCSVText() {
        self.csvText = CSVService.cardsToCSVString(cards: cards)
    }
    
    public func syncFromCSVText() {
        let parsed = CSVService.parseCSV(content: csvText)
        if !parsed.isEmpty {
            self.cards = parsed
        }
    }
    
    public func addNewCard() {
        cards.append(Flashcard(term: "", definition: ""))
    }
}

public struct DirectCSVEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    public let deckTitle: String
    public let initialCards: [Flashcard]
    public var onSave: ([Flashcard]) -> Void
    
    @StateObject private var vm = DirectCSVEditorViewModel()
    
    public init(
        deckTitle: String,
        initialCards: [Flashcard],
        onSave: @escaping ([Flashcard]) -> Void
    ) {
        self.deckTitle = deckTitle
        self.initialCards = initialCards
        self.onSave = onSave
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "tablecells.badge.ellipsis")
                    .font(.system(size: 26))
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("Chỉnh Sửa Nhanh Dạng Bảng / CSV")
                            .font(.lexioTitle)
                            .foregroundColor(.primary)
                        
                        // Status Badge
                        if vm.validCardsCount == 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("Chưa có thẻ hợp lệ")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(6)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("\(vm.validCardsCount) thẻ hợp lệ")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(6)
                        }
                    }
                    
                    Text("Bộ thẻ: \(deckTitle) • Sửa trực tiếp từng ô dạng bảng tính như Excel, lưu tức thì không cần cuộn trang.")
                        .font(.lexioCaption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 10) {
                    Button("Hủy") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Button(action: handleSave) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                            Text("Lưu Vào Bộ Thẻ (\(vm.validCardsCount) Thẻ)")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .keyboardShortcut(.defaultAction)
                    .disabled(vm.validCardsCount == 0)
                }
            }
            .padding(18)
            .background(VisualEffectView(material: .titlebar, blendingMode: .withinWindow))
            
            Divider()
            
            // Sub-Toolbar: Mode Switcher & Tools
            HStack(spacing: 12) {
                // Segmented Picker không bị chữ "Chế độ xem" xếp dọc
                Picker("", selection: $vm.selectedTab) {
                    Label("Bảng Tính Dễ Sửa", systemImage: "tablecells").tag(0)
                    Label("Văn Bản CSV (Nâng Cao)", systemImage: "doc.plaintext").tag(1)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 360)
                .onChange(of: vm.selectedTab) { newTab in
                    if newTab == 1 {
                        vm.syncToCSVText()
                    } else {
                        vm.syncFromCSVText()
                    }
                }
                
                Spacer()
                
                Button(action: { vm.addNewCard() }) {
                    Label("Thêm Thẻ Mới", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Thêm một dòng thẻ mới vào danh sách")
                
                Button(action: copyToClipboard) {
                    Label("Sao Chép CSV", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Sao chép toàn bộ danh sách ra định dạng CSV vào bộ nhớ đệm")
                
                Button(action: pasteFromClipboard) {
                    Label("Dán Từ Clipboard", systemImage: "arrow.right.doc.on.clipboard")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Dán dữ liệu từ bảng tính Excel / Google Sheets vào đây")
                
                Button(action: { vm.showResetConfirm = true }) {
                    Label("Khôi Phục Gốc", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Khôi phục lại danh sách thẻ ban đầu của bộ này")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Quick Info Guide Bar
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                if vm.selectedTab == 0 {
                    Text("Chế độ Bảng Tính:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Click trực tiếp vào từng ô để gõ sửa như Excel. Không cần quan tâm dấu phẩy hay cấu trúc code.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                } else {
                    Text("Chế độ Văn Bản CSV:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Dành cho việc copy/paste hàng loạt toàn bộ file CSV hoặc từ bảng tính ngoài.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 7)
            .background(Color(NSColor.separatorColor).opacity(0.12))
            
            Divider()
            
            // Main Content Area
            ZStack(alignment: .bottom) {
                if vm.selectedTab == 0 {
                    // TAB 0: Interactive Spreadsheet Table Editor
                    interactiveTableEditor
                } else {
                    // TAB 1: Raw Monospace CSV Text Editor
                    rawCSVTextEditor
                }
                
                // Toast notification pill
                if let msg = vm.toastMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(msg)
                    }
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(NSColor.separatorColor).opacity(0.8), lineWidth: 0.5)
                    )
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            Divider()
            
            // Footer Info Bar
            HStack {
                Text(vm.selectedTab == 0
                     ? "💡 Nhấn nút [Thêm Thẻ Mới] hoặc cuộn xuống cuối bảng để tạo thêm thẻ vựng."
                     : "💡 Có thể copy bảng từ Google Sheets / Excel rồi dán trực tiếp vào đây.")
                    .font(.lexioCaption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Tổng: \(vm.cards.count) dòng (\(vm.validCardsCount) thẻ hợp lệ)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(VisualEffectView(material: .titlebar, blendingMode: .withinWindow))
        }
        .frame(minWidth: 980, minHeight: 660)
        .onAppear {
            loadInitialCards()
        }
        .alert("Khôi phục danh sách thẻ gốc?", isPresented: $vm.showResetConfirm) {
            Button("Khôi Phục", role: .destructive) {
                loadInitialCards()
                showToast("Đã khôi phục lại danh sách thẻ ban đầu")
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("Mọi thay đổi trong bảng này sẽ bị hủy bỏ và quay về \(initialCards.count) thẻ ban đầu.")
        }
    }
    
    // MARK: - Interactive Spreadsheet Table Editor
    private var interactiveTableEditor: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Table Header Row
                HStack(spacing: 6) {
                    headerCell("#", width: 38)
                    headerCell("Từ vựng (Term) *", width: 145)
                    headerCell("Phiên âm (IPA)", width: 115)
                    headerCell("Từ loại", width: 85)
                    headerCell("Định nghĩa (Meaning) *", width: 190)
                    headerCell("Ngữ pháp / Cấu trúc", width: 140)
                    headerCell("Câu ví dụ (Example)", width: 200)
                    headerCell("Dịch ví dụ", width: 180)
                    headerCell("Ghi chú / Mẹo nhớ", width: 140)
                    headerCell("Nhãn (Tags)", width: 110)
                    headerCell("", width: 36) // Nút xóa
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Table Data Rows
                ForEach(0..<vm.cards.count, id: \.self) { index in
                    HStack(spacing: 6) {
                        // Số thứ tự
                        Text("\(index + 1)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 38, alignment: .center)
                        
                        // Term
                        tableTextField(
                            placeholder: "Từ vựng...",
                            text: $vm.cards[index].term,
                            width: 145,
                            isBold: true
                        )
                        
                        // Phonetic
                        tableTextField(
                            placeholder: "/ipa/",
                            text: optionalBinding(
                                get: { vm.cards[index].phonetic },
                                set: { vm.cards[index].phonetic = $0 }
                            ),
                            width: 115,
                            isMonospace: true
                        )
                        
                        // POS
                        tableTextField(
                            placeholder: "noun, verb...",
                            text: optionalBinding(
                                get: { vm.cards[index].partOfSpeech },
                                set: { vm.cards[index].partOfSpeech = $0 }
                            ),
                            width: 85
                        )
                        
                        // Definition
                        tableTextField(
                            placeholder: "Định nghĩa nghĩa từ...",
                            text: $vm.cards[index].definition,
                            width: 190
                        )
                        
                        // Grammar Pattern
                        tableTextField(
                            placeholder: "Cấu trúc ngữ pháp...",
                            text: optionalBinding(
                                get: { vm.cards[index].grammarPattern },
                                set: { vm.cards[index].grammarPattern = $0 }
                            ),
                            width: 140
                        )
                        
                        // Example
                        tableTextField(
                            placeholder: "Câu ví dụ...",
                            text: optionalBinding(
                                get: { vm.cards[index].example },
                                set: { vm.cards[index].example = $0 }
                            ),
                            width: 200
                        )
                        
                        // Example Translation
                        tableTextField(
                            placeholder: "Dịch câu ví dụ...",
                            text: optionalBinding(
                                get: { vm.cards[index].exampleTranslation },
                                set: { vm.cards[index].exampleTranslation = $0 }
                            ),
                            width: 180
                        )
                        
                        // Notes
                        tableTextField(
                            placeholder: "Ghi chú...",
                            text: optionalBinding(
                                get: { vm.cards[index].notes },
                                set: { vm.cards[index].notes = $0 }
                            ),
                            width: 140
                        )
                        
                        // Tags
                        tableTextField(
                            placeholder: "IELTS; C1...",
                            text: tagsBinding(index: index),
                            width: 110
                        )
                        
                        // Delete Button
                        Button(action: {
                            if vm.cards.count > 1 {
                                vm.cards.remove(at: index)
                            } else {
                                vm.cards[0] = Flashcard(term: "", definition: "")
                            }
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                        .frame(width: 36, alignment: .center)
                        .help("Xóa dòng này")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(index % 2 == 0 ? Color(NSColor.textBackgroundColor) : Color(NSColor.controlBackgroundColor).opacity(0.4))
                    
                    Divider()
                }
                
                // Add new row button at bottom of table
                Button(action: { vm.addNewCard() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Thêm Dòng Mới")
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.08))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .padding(.bottom, 24)
        }
        .background(Color(NSColor.textBackgroundColor))
    }
    
    private func headerCell(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.secondary)
            .lineLimit(1)
            .frame(width: width, alignment: .leading)
    }
    
    private func tableTextField(
        placeholder: String,
        text: Binding<String>,
        width: CGFloat,
        isBold: Bool = false,
        isMonospace: Bool = false
    ) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .font(isMonospace ? .system(size: 11, design: .monospaced) : .system(size: 12, weight: isBold ? .semibold : .regular))
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color(NSColor.separatorColor).opacity(0.35), lineWidth: 0.5)
            )
            .frame(width: width)
    }
    
    // MARK: - Raw CSV Text Editor
    private var rawCSVTextEditor: some View {
        TextEditor(text: $vm.csvText)
            .font(.system(size: 13, weight: .regular, design: .monospaced))
            .scrollContentBackground(.hidden)
            .padding(14)
            .background(Color(NSColor.textBackgroundColor))
            .onChange(of: vm.csvText) { _ in
                let parsed = CSVService.parseCSV(content: vm.csvText)
                if !parsed.isEmpty {
                    vm.cards = parsed
                }
            }
    }
    
    // MARK: - Logic Helpers
    private func loadInitialCards() {
        if initialCards.isEmpty {
            vm.cards = [Flashcard(term: "", definition: "")]
        } else {
            vm.cards = initialCards
        }
        vm.syncToCSVText()
    }
    
    private func optionalBinding(
        get: @escaping () -> String?,
        set: @escaping (String?) -> Void
    ) -> Binding<String> {
        Binding<String>(
            get: { get() ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                set(trimmed.isEmpty ? nil : newValue)
            }
        )
    }
    
    private func tagsBinding(index: Int) -> Binding<String> {
        Binding<String>(
            get: {
                guard index < vm.cards.count else { return "" }
                return vm.cards[index].tags.joined(separator: "; ")
            },
            set: { newValue in
                guard index < vm.cards.count else { return }
                vm.cards[index].tags = newValue
                    .components(separatedBy: CharacterSet(charactersIn: ";,"))
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            }
        )
    }
    
    private func copyToClipboard() {
        vm.syncToCSVText()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(vm.csvText, forType: .string)
        showToast("Đã sao chép toàn bộ CSV vào bộ nhớ đệm")
    }
    
    private func pasteFromClipboard() {
        if let clipboard = NSPasteboard.general.string(forType: .string), !clipboard.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let formatted = formatClipboardContent(clipboard)
            let parsed = CSVService.parseCSV(content: formatted)
            if !parsed.isEmpty {
                vm.cards = parsed
                vm.csvText = formatted
                showToast("Đã dán và nạp \(parsed.count) thẻ vào bảng")
            } else {
                showToast("Không phân tích được dữ liệu thẻ từ nội dung vừa dán")
            }
        } else {
            showToast("Bộ nhớ đệm rỗng")
        }
    }
    
    private func formatClipboardContent(_ input: String) -> String {
        if input.contains("\t") && !input.contains(",") {
            let lines = input.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            var converted = ""
            if !lines.isEmpty && !lines[0].lowercased().contains("term") {
                converted += "Term,Phonetic,PartOfSpeech,Definition,Example,ExampleTranslation,GrammarPattern,Notes,Tags\n"
            }
            for line in lines {
                let parts = line.components(separatedBy: "\t")
                let escapedParts = parts.map { part -> String in
                    let cleaned = part.trimmingCharacters(in: .whitespaces)
                    if cleaned.contains(",") || cleaned.contains("\"") {
                        return "\"\(cleaned.replacingOccurrences(of: "\"", with: "\"\""))\""
                    }
                    return cleaned
                }
                converted += escapedParts.joined(separator: ",") + "\n"
            }
            return converted
        }
        
        let firstLine = input.components(separatedBy: .newlines).first?.lowercased() ?? ""
        if !firstLine.contains("term") && !firstLine.contains("word") && !firstLine.contains("tu") {
            return "Term,Phonetic,PartOfSpeech,Definition,Example,ExampleTranslation,GrammarPattern,Notes,Tags\n" + input
        }
        
        return input
    }
    
    private func handleSave() {
        if vm.selectedTab == 1 {
            vm.syncFromCSVText()
        }
        let valid = vm.cards.filter { !$0.term.trimmingCharacters(in: .whitespaces).isEmpty || !$0.definition.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !valid.isEmpty else { return }
        onSave(valid)
        dismiss()
    }
    
    private func showToast(_ msg: String) {
        withAnimation {
            vm.toastMessage = msg
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                if vm.toastMessage == msg {
                    vm.toastMessage = nil
                }
            }
        }
    }
}
