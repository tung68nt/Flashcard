import SwiftUI
import UniformTypeIdentifiers
import AppKit

public class ContentViewModel: ObservableObject {
    @Published public var selectedDeckId: String? = nil
    @Published public var activeStudyMode: StudyMode? = nil
    @Published public var isStudioOpen: Bool = false
    @Published public var deckToEdit: Deck? = nil
    @Published public var toastMessage: String? = nil
    @Published public var showAboutModal: Bool = false
    @Published public var selectedAccent: AudioAccent = SpeechService.shared.preferredAccent
    
    public init() {}
    
    public func showToast(_ msg: String) {
        withAnimation {
            toastMessage = msg
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                if self.toastMessage == msg {
                    self.toastMessage = nil
                }
            }
        }
    }
}

public struct ContentView: View {
    @ObservedObject private var storage = StorageService.shared
    @ObservedObject private var updateService = UpdateService.shared
    @StateObject private var vm = ContentViewModel()
    
    private var selectedDeck: Deck? {
        guard let id = vm.selectedDeckId, !id.isEmpty else { return nil }
        return storage.decks.first(where: { $0.id == id })
    }
    
    private var totalDue: Int {
        storage.decks.reduce(0) { $0 + $1.dueCardsCount }
    }
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            // Clean Apple Sidebar
            List(selection: $vm.selectedDeckId) {
                Section {
                    NavigationLink(value: "") {
                        Label("Tất cả bộ thẻ", systemImage: "square.grid.2x2")
                            .font(.lexioBody)
                    }
                }
                
                Section("Bộ thẻ của bạn") {
                    ForEach(storage.decks) { deck in
                        NavigationLink(value: deck.id) {
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(Color(hex: deck.colorHex))
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 5)
                                
                                Text(deck.title)
                                    .font(.lexioBody)
                                    .foregroundColor(.primary)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(2)
                                
                                Spacer(minLength: 6)
                                
                                if deck.dueCardsCount > 0 {
                                    Text("\(deck.dueCardsCount)")
                                        .font(.lexioCaptionSemibold)
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1.5)
                                        .background(Color.red.opacity(0.12))
                                        .clipShape(Capsule())
                                        .padding(.top, 2)
                                } else {
                                    Text("\(deck.cards.count)")
                                        .font(.lexioCaption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 2)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 450)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        vm.deckToEdit = nil
                        vm.isStudioOpen = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .help("Tạo bộ thẻ mới (Cmd+N)")
                    .keyboardShortcut("n", modifiers: .command)
                }
            }
        } detail: {
            ZStack {
                if let mode = vm.activeStudyMode, let deck = selectedDeck {
                    // Active Study Mode
                    switch mode {
                    case .flashcards:
                        FlashcardStudyView(deck: deck) {
                            vm.activeStudyMode = nil
                        }
                    case .srs:
                        SRSLearnView(deck: deck) {
                            vm.activeStudyMode = nil
                        }
                    case .write:
                        WriteQuizView(deck: deck) {
                            vm.activeStudyMode = nil
                        }
                    case .match:
                        MatchGameView(deck: deck) {
                            vm.activeStudyMode = nil
                        }
                    case .test:
                        TestModeView(deck: deck) {
                            vm.activeStudyMode = nil
                        }
                    }
                } else if let deck = selectedDeck {
                    // Deck Detail
                    DeckDetailView(
                        deck: deck,
                        onBack: {
                            vm.selectedDeckId = nil
                        },
                        onStartStudy: { mode in
                            vm.activeStudyMode = mode
                        },
                        onEditDeck: {
                            vm.deckToEdit = deck
                            vm.isStudioOpen = true
                        },
                        onDeleteDeck: {
                            storage.deleteDeck(id: deck.id)
                            vm.selectedDeckId = nil
                            vm.showToast("Đã xóa bộ thẻ \"\(deck.title)\"")
                        }
                    )
                } else {
                    // Home All Decks Grid
                    DeckListView(
                        onSelectDeck: { deck in
                            vm.selectedDeckId = deck.id
                            vm.activeStudyMode = nil
                        },
                        onNewDeck: {
                            vm.deckToEdit = nil
                            vm.isStudioOpen = true
                        },
                        onImportCSV: importCSV,
                        onDownloadSampleCSV: downloadSampleCSV
                    )
                }
                
                // Toast Banner
                if let msg = vm.toastMessage {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(msg)
                                .font(.lexioHeadline)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(NSColor.separatorColor).opacity(0.8), lineWidth: 1)
                        )
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    // 1. Accent Selector (Oxford / Cambridge)
                    Menu {
                        Button {
                            vm.selectedAccent = .uk
                            SpeechService.shared.preferredAccent = .uk
                        } label: {
                            Label("Giọng Anh - Anh (UK 🇬🇧)", systemImage: vm.selectedAccent == .uk ? "checkmark" : "")
                        }
                        
                        Button {
                            vm.selectedAccent = .us
                            SpeechService.shared.preferredAccent = .us
                        } label: {
                            Label("Giọng Anh - Mỹ (US 🇺🇸)", systemImage: vm.selectedAccent == .us ? "checkmark" : "")
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "waveform")
                                .font(.system(size: 13, weight: .medium))
                            Text(vm.selectedAccent.label)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                    }
                    .help("Giọng đọc phát âm mặc định: Oxford / Cambridge")
                    
                    // 2. Data & Cloud/File Management
                    Menu {
                        Section("Nhập / Xuất CSV") {
                            Button(action: importCSV) {
                                Label("Nhập Thêm Từ File CSV...", systemImage: "arrow.down.doc")
                            }
                            Button(action: downloadSampleCSV) {
                                Label("Tải Mẫu File CSV Chuẩn...", systemImage: "square.and.arrow.down")
                            }
                        }
                        
                        Section("Sao Lưu Toàn Bộ") {
                            Button(action: backupAllJSON) {
                                Label("Sao Lưu Toàn Bộ Dữ Liệu (.json)...", systemImage: "arrow.up.doc")
                            }
                            Button(action: restoreAllJSON) {
                                Label("Phục Hồi Dữ Liệu Từ File Backup (.json)...", systemImage: "arrow.clockwise")
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "externaldrive")
                                .font(.system(size: 13, weight: .medium))
                            Text("Dữ Liệu")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                    }
                    .help("Nhập CSV, tải mẫu và sao lưu / phục hồi dữ liệu")
                    
                    // 3. Updates
                    Button(action: { updateService.checkForUpdates() }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 18, height: 18)
                    }
                    .help("Kiểm tra bản cập nhật mới (Check for Updates)")
                    
                    // 4. About Modal
                    Button(action: { vm.showAboutModal = true }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 13, weight: .medium))
                            .frame(width: 18, height: 18)
                    }
                    .help("Thông tin Lexio PRO Native")
                }
            }
        }
        .sheet(isPresented: $vm.isStudioOpen) {
            DeckStudioView(deckToEdit: vm.deckToEdit) { savedDeck in
                storage.saveDeck(savedDeck)
                vm.selectedDeckId = savedDeck.id
                vm.showToast("Đã lưu bộ thẻ \"\(savedDeck.title)\"")
            }
        }
        .sheet(isPresented: $vm.showAboutModal) {
            AboutNativeView()
        }
        .sheet(isPresented: $updateService.isUpdateSheetPresented) {
            UpdateSheetView()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LexioImportCSV"))) { _ in
            importCSV()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LexioDownloadSampleCSV"))) { _ in
            downloadSampleCSV()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LexioCheckForUpdates"))) { _ in
            updateService.checkForUpdates()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LexioShowAbout"))) { _ in
            vm.showAboutModal = true
        }
    }
    
    // MARK: - Native File Operations
    
    private func downloadSampleCSV() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Lexio_Flashcard_Template.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.canCreateDirectories = true
        panel.title = "Tải File CSV Mẫu Chuẩn"
        panel.message = "Tải mẫu CSV chuẩn với đầy đủ 9 cột để nạp từ vựng vào Lexio"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let csv = CSVService.generateSampleCSV()
                try csv.write(to: url, atomically: true, encoding: .utf8)
                vm.showToast("Đã tải thành công file mẫu \"Lexio_Flashcard_Template.csv\"")
            } catch {
                vm.showToast("Lỗi khi lưu file mẫu: \(error.localizedDescription)")
            }
        }
    }
    
    private func importCSV() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.commaSeparatedText, .tabSeparatedText, .plainText]
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                let filename = url.deletingPathExtension().lastPathComponent
                let cards = CSVService.parseCSV(content: content)
                guard !cards.isEmpty else {
                    vm.showToast("Không tìm thấy thẻ từ vựng hợp lệ trong file CSV.")
                    return
                }
                let deck = Deck(
                    title: filename,
                    description: "Nhập từ file CSV",
                    category: "Chung",
                    cards: cards
                )
                storage.saveDeck(deck)
                vm.selectedDeckId = deck.id
                vm.showToast("Đã nhập thành công bộ thẻ \"\(deck.title)\" (\(cards.count) thẻ)")
            } catch {
                vm.showToast("Lỗi khi đọc file CSV: \(error.localizedDescription)")
            }
        }
    }
    
    private func backupAllJSON() {
        let panel = NSSavePanel()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmm"
        panel.nameFieldStringValue = "Lexio_Backup_\(dateFormatter.string(from: Date())).json"
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.json]
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try storage.exportBackupJSON(to: url)
                vm.showToast("Đã sao lưu thành công \(storage.decks.count) bộ thẻ!")
            } catch {
                vm.showToast("Lỗi khi lưu backup: \(error.localizedDescription)")
            }
        }
    }
    
    private func restoreAllJSON() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.json]
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try storage.importBackupJSON(from: url)
                vm.selectedDeckId = nil
                vm.showToast("Đã phục hồi thành công \(storage.decks.count) bộ thẻ!")
            } catch {
                vm.showToast("Lỗi khi phục hồi file: \(error.localizedDescription)")
            }
        }
    }
}

private struct AboutNativeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
            
            VStack(spacing: 4) {
                Text("Lexio PRO")
                    .font(.system(size: 20, weight: .bold))
                
                Text("Phiên bản \(UpdateService.shared.currentVersion)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Text("Ứng dụng học từ vựng và flashcard thông minh")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Bản quyền © 2025 Tulie Tech. Mọi quyền được bảo lưu.")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.8))
                .padding(.top, 2)
            
            HStack(spacing: 12) {
                Button {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        UpdateService.shared.checkForUpdates()
                    }
                } label: {
                    Label("Kiểm Tra Cập Nhật...", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                
                Button("Đóng") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(.top, 6)
        }
        .padding(28)
        .frame(width: 360)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)
        let r, g, b: UInt64
        switch clean.count {
        case 6:
            (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (37, 99, 235) // Clean Apple Blue default
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1.0
        )
    }
}
