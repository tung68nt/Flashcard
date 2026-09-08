import Foundation
import AppKit
import Combine

public struct AppUpdateInfo: Codable, Identifiable, Equatable {
    public var id: String { version }
    public let version: String
    public let build: Int?
    public let releaseDate: String?
    public let title: String?
    public let notes: [String]?
    public let downloadUrl: String
    public let fallbackUrl: String?
}

public enum UpdateState: Equatable {
    case idle
    case checking
    case upToDate(version: String)
    case available(AppUpdateInfo)
    case downloading(progress: Double)
    case downloaded(fileURL: URL)
    case error(String)
}

public final class UpdateService: NSObject, ObservableObject, @unchecked Sendable, URLSessionDownloadDelegate {
    public static let shared = UpdateService()
    
    @Published public var state: UpdateState = .idle
    @Published public var isUpdateSheetPresented: Bool = false
    @Published public var downloadProgress: Double = 0.0
    
    // URL nguồn kiểm tra phiên bản mới
    // Có thể trỏ đến GitHub Raw, Supabase, hoặc server của bạn
    public var updateEndpoint: String = "https://raw.githubusercontent.com/tung68nt/Flashcard/main/version.json"
    
    private var downloadTask: URLSessionDownloadTask?
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.timeoutIntervalForRequest = 10.0
        return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
    }()
    
    public var currentVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.1.0"
    }
    
    private override init() {
        super.init()
    }
    
    /// Kiểm tra bản cập nhật mới
    public func checkForUpdates(showUIOnLatest: Bool = true) {
        state = .checking
        if showUIOnLatest {
            isUpdateSheetPresented = true
        }
        
        guard let url = URL(string: updateEndpoint) else {
            state = .error("URL kiểm tra cập nhật không hợp lệ.")
            return
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    // Mất mạng hoặc không thể kết nối -> thông báo nhẹ nhàng
                    self.state = .error("Không thể kết nối máy chủ kiểm tra cập nhật. Vui lòng kiểm tra kết nối mạng (\(error.localizedDescription)).")
                    return
                }
                
                if let http = response as? HTTPURLResponse {
                    if http.statusCode == 404 {
                        // Kho lưu trữ chưa có bản release mới đưa lên GitHub -> hiện tại là bản mới nhất
                        self.state = .upToDate(version: self.currentVersion)
                        return
                    } else if http.statusCode != 200 {
                        self.state = .error("Máy chủ cập nhật phản hồi mã lỗi \(http.statusCode).")
                        return
                    }
                }
                
                guard let data = data, !data.isEmpty else {
                    self.state = .upToDate(version: self.currentVersion)
                    return
                }
                
                do {
                    let info = try JSONDecoder().decode(AppUpdateInfo.self, from: data)
                    let comparison = info.version.compare(self.currentVersion, options: .numeric)
                    
                    if comparison == .orderedDescending {
                        // Đã có phiên bản mới hơn trên máy chủ
                        self.state = .available(info)
                        self.isUpdateSheetPresented = true
                    } else {
                        // Đang ở phiên bản mới nhất
                        self.state = .upToDate(version: self.currentVersion)
                        if !showUIOnLatest {
                            self.isUpdateSheetPresented = false
                        }
                    }
                } catch {
                    // Nếu dữ liệu không phải JSON release hợp lệ, app mặc định là phiên bản hiện tại
                    self.state = .upToDate(version: self.currentVersion)
                }
            }
        }.resume()
    }
    
    /// Tải file DMG mới và mở lên
    public func downloadAndInstall(info: AppUpdateInfo) {
        guard let url = URL(string: info.downloadUrl) else {
            if let fallback = info.fallbackUrl, let fallbackUrl = URL(string: fallback) {
                NSWorkspace.shared.open(fallbackUrl)
            }
            return
        }
        
        state = .downloading(progress: 0.0)
        downloadProgress = 0.0
        
        downloadTask?.cancel()
        downloadTask = urlSession.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    /// Mở trang tải về trên trình duyệt
    public func openReleasePage(info: AppUpdateInfo) {
        if let url = URL(string: info.fallbackUrl ?? info.downloadUrl) {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let targetURL = downloads.appendingPathComponent("Lexio-Pure-Native-macOS.dmg")
        
        do {
            if FileManager.default.fileExists(atPath: targetURL.path) {
                try FileManager.default.removeItem(at: targetURL)
            }
            try FileManager.default.moveItem(at: location, to: targetURL)
            
            DispatchQueue.main.async {
                self.state = .downloaded(fileURL: targetURL)
                // Mở tự động file DMG trong Finder
                NSWorkspace.shared.open(targetURL)
            }
        } catch {
            DispatchQueue.main.async {
                self.state = .error("Lỗi khi lưu file tải về: \(error.localizedDescription)")
            }
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.downloadProgress = progress
            self.state = .downloading(progress: progress)
        }
    }
}
