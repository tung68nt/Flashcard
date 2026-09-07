import Cocoa
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate {
    var window: NSWindow!
    var webView: WKWebView!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Setup Window
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1440, height: 900)
        let windowWidth: CGFloat = min(1240, screenSize.width - 80)
        let windowHeight: CGFloat = min(840, screenSize.height - 80)
        
        let rect = NSRect(
            x: (screenSize.width - windowWidth) / 2,
            y: (screenSize.height - windowHeight) / 2,
            width: windowWidth,
            height: windowHeight
        )

        window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Lexio PRO"
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: 900, height: 620)
        window.isReleasedWhenClosed = false
        window.center()

        // Setup WebKit Configuration
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        let webpagePreferences = WKWebpagePreferences()
        webpagePreferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = webpagePreferences

        // Create WebView
        webView = WKWebView(frame: window.contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.setValue(false, forKey: "drawsBackground") // Transparent background until loaded

        window.contentView?.addSubview(webView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Setup Native Menus
        setupMainMenu()

        // Load Content: Try localhost dev server first; fallback to local dist/index.html
        loadContent()
    }

    func loadContent() {
        // Test if localhost:5173 is running
        if let devUrl = URL(string: "http://localhost:5173"), isServerRunning(url: devUrl) {
            print("[Lexio Native] Đang kết nối tới Live Dev Server: http://localhost:5173/")
            webView.load(URLRequest(url: devUrl))
            return
        }

        // Fallback to bundled dist/index.html
        let bundlePath = Bundle.main.bundlePath
        let distUrl = URL(fileURLWithPath: bundlePath).appendingPathComponent("Contents/Resources/dist/index.html")
        let resourcesUrl = URL(fileURLWithPath: bundlePath).appendingPathComponent("Contents/Resources/dist")

        if FileManager.default.fileExists(atPath: distUrl.path) {
            print("[Lexio Native] Đang chạy Offline Local từ file: \(distUrl.path)")
            webView.loadFileURL(distUrl, allowingReadAccessTo: resourcesUrl)
        } else {
            // Check project dist folder relative to binary
            let currentDir = FileManager.default.currentDirectoryPath
            let projectDist = URL(fileURLWithPath: currentDir).appendingPathComponent("dist/index.html")
            let projectDistDir = URL(fileURLWithPath: currentDir).appendingPathComponent("dist")
            
            if FileManager.default.fileExists(atPath: projectDist.path) {
                print("[Lexio Native] Đang chạy từ thư mục dist dự án: \(projectDist.path)")
                webView.loadFileURL(projectDist, allowingReadAccessTo: projectDistDir)
            } else {
                let html = """
                <html>
                <body style='font-family: -apple-system; padding: 40px; text-align: center; background: #faf8f5;'>
                    <h2>Lexio PRO Native macOS</h2>
                    <p>Vui lòng chạy <code>npm run build</code> hoặc khởi động <code>npm run dev</code>.</p>
                </body>
                </html>
                """
                webView.loadHTMLString(html, baseURL: nil)
            }
        }
    }

    func isServerRunning(url: URL) -> Bool {
        var running = false
        let semaphore = DispatchSemaphore(value: 0)
        var request = URLRequest(url: url, timeoutInterval: 0.8)
        request.httpMethod = "HEAD"
        let task = URLSession.shared.dataTask(with: request) { _, response, _ in
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                running = true
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + 0.9)
        return running
    }

    func setupMainMenu() {
        let mainMenu = NSMenu()

        // 1. App Menu (Lexio PRO)
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Lexio PRO", action: #selector(showAboutPanel), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Hide Lexio", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthers)
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Lexio PRO", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // 2. File Menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "New Deck...", action: #selector(triggerNewDeck), keyEquivalent: "n")
        fileMenu.addItem(withTitle: "Import Excel or CSV...", action: #selector(triggerImport), keyEquivalent: "i")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // 3. Edit Menu (Standard Copy/Paste/SelectAll for Web inputs)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z")
        let redoItem = NSMenuItem(title: "Redo", action: #selector(UndoManager.redo), keyEquivalent: "z")
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(redoItem)
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // 4. View Menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(withTitle: "Reload Page", action: #selector(reloadPage), keyEquivalent: "r")
        viewMenu.addItem(NSMenuItem.separator())
        let fullScreenItem = NSMenuItem(title: "Toggle Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        fullScreenItem.keyEquivalentModifierMask = [.command, .control]
        viewMenu.addItem(fullScreenItem)
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // 5. Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        // 6. Help Menu
        let helpMenuItem = NSMenuItem()
        let helpMenu = NSMenu(title: "Help")
        helpMenu.addItem(withTitle: "About Tulie Tech...", action: #selector(showAboutPanel), keyEquivalent: "")
        helpMenuItem.submenu = helpMenu
        mainMenu.addItem(helpMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc func showAboutPanel() {
        let credits = NSMutableAttributedString(
            string: "Crafted with precision by Tulie Tech.\nSpaced Repetition & Linguistic Memory System.\n\nWebsite: tulietech.com\nCommercial Edition",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )

        let options: [NSApplication.AboutPanelOptionKey: Any] = [
            .applicationName: "Lexio PRO",
            .applicationVersion: "Version 1.2.0",
            .version: "Build 2026.1 (Commercial Release)",
            .credits: credits,
            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "Copyright © 2026 Tulie Tech. All rights reserved."
        ]

        NSApp.orderFrontStandardAboutPanel(options: options)
    }

    @objc func triggerNewDeck() {
        webView.evaluateJavaScript("window.dispatchEvent(new CustomEvent('lexio:open-new-deck'))")
    }

    @objc func triggerImport() {
        webView.evaluateJavaScript("window.dispatchEvent(new CustomEvent('lexio:open-import'))")
    }

    @objc func reloadPage() {
        loadContent()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// Entrypoint
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
