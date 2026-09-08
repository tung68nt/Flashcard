import SwiftUI

@main
struct LexioNativeApp: App {
    @StateObject private var storage = StorageService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowToolbarStyle(.unified)
        .commands {
            SidebarCommands()
            CommandGroup(after: .appInfo) {
                Button("Kiểm Tra Bản Cập Nhật...") {
                    NotificationCenter.default.post(name: NSNotification.Name("LexioCheckForUpdates"), object: nil)
                }
                .keyboardShortcut("u", modifiers: .command)
            }
            CommandGroup(after: .newItem) {
                Button("Tạo Bộ Thẻ Mới...") {
                    NotificationCenter.default.post(name: NSNotification.Name("LexioNewDeck"), object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Nhập Từ File CSV...") {
                    NotificationCenter.default.post(name: NSNotification.Name("LexioImportCSV"), object: nil)
                }
                .keyboardShortcut("i", modifiers: .command)
                
                Button("Tải File CSV Mẫu Chuẩn...") {
                    NotificationCenter.default.post(name: NSNotification.Name("LexioDownloadSampleCSV"), object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            }
        }
    }
}
