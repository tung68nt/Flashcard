import Foundation
import AVFoundation

public enum AudioAccent: String, Codable, CaseIterable, Identifiable {
    case uk = "UK"
    case us = "US"
    
    public var id: String { rawValue }
    
    public var label: String {
        switch self {
        case .uk: return "UK"
        case .us: return "US"
        }
    }
    
    public var flag: String {
        switch self {
        case .uk: return "🇬🇧"
        case .us: return "🇺🇸"
        }
    }
    
    public var bcp47: String {
        switch self {
        case .uk: return "en-GB"
        case .us: return "en-US"
        }
    }
}

public final class DictionaryAudioService: NSObject, ObservableObject, @unchecked Sendable, AVAudioPlayerDelegate {
    public static let shared = DictionaryAudioService()
    
    private var audioPlayer: AVAudioPlayer?
    private let cacheDirectory: URL
    private let session: URLSession
    
    // Trạng thái đang phát
    @Published public var activeTerm: String? = nil
    @Published public var activeAccent: AudioAccent? = nil
    
    // Cache URL trong bộ nhớ RAM để tránh parse HTML nhiều lần
    private var resolvedUrlCache: [String: [AudioAccent: String]] = [:]
    private let queue = DispatchQueue(label: "com.lexio.audio.service", qos: .userInitiated)
    
    private override init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = caches.appendingPathComponent("com.lexio.Lexio/AudioCache", isDirectory: true)
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 6.0
        config.timeoutIntervalForResource = 12.0
        let opQueue = OperationQueue()
        opQueue.maxConcurrentOperationCount = 4
        self.session = URLSession(configuration: config, delegate: nil, delegateQueue: opQueue)
        
        super.init()
        
        // Tạo thư mục cache nếu chưa tồn tại
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    /// Phát âm thanh chuẩn từ điển (Oxford/Cambridge). Nếu không tìm thấy, fallback sang TTS
    public func play(term: String, accent: AudioAccent) {
        let sanitized = term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !sanitized.isEmpty else { return }
        
        // Nếu đang phát cùng từ & cùng accent, dừng lại
        if activeTerm == sanitized && activeAccent == accent {
            stop()
            return
        }
        
        stop()
        setPlaybackState(term: sanitized, accent: accent)
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // 1. Kiểm tra local disk cache trước
            let localFile = self.cachedFileURL(term: sanitized, accent: accent)
            if FileManager.default.fileExists(atPath: localFile.path) {
                self.playLocalFile(localFile, term: sanitized, accent: accent)
                return
            }
            
            // 2. Tìm audio URL từ Cambridge hoặc Oxford
            if let audioUrlString = self.resolveAudioUrl(term: sanitized, accent: accent),
               let audioUrl = URL(string: audioUrlString) {
                self.downloadAndPlay(audioUrl: audioUrl, destination: localFile, term: sanitized, accent: accent)
            } else {
                // 3. Fallback sang AVSpeechSynthesizer nếu không có trong từ điển (vd câu dài, cụm từ)
                DispatchQueue.main.async {
                    SpeechService.shared.speak(text: term, language: accent.bcp47)
                    self.setPlaybackState(term: nil, accent: nil)
                }
            }
        }
    }
    
    public func stop() {
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        audioPlayer = nil
        setPlaybackState(term: nil, accent: nil)
    }
    
    private func setPlaybackState(term: String?, accent: AudioAccent?) {
        DispatchQueue.main.async { [weak self] in
            self?.activeTerm = term
            self?.activeAccent = accent
        }
    }
    
    // MARK: - Local Cache Helpers
    
    private func cachedFileURL(term: String, accent: AudioAccent) -> URL {
        let safeName = term.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "_")
        let filename = "\(safeName)_\(accent.rawValue.lowercased()).mp3"
        return cacheDirectory.appendingPathComponent(filename)
    }
    
    private func playLocalFile(_ url: URL, term: String, accent: AudioAccent) {
        do {
            let data = try Data(contentsOf: url)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                do {
                    self.audioPlayer = try AVAudioPlayer(data: data)
                    self.audioPlayer?.delegate = self
                    self.audioPlayer?.prepareToPlay()
                    self.audioPlayer?.play()
                } catch {
                    self.stop()
                }
            }
        } catch {
            // File hỏng -> xóa file và thử tải lại
            try? FileManager.default.removeItem(at: url)
            setPlaybackState(term: nil, accent: nil)
        }
    }
    
    private func downloadAndPlay(audioUrl: URL, destination: URL, term: String, accent: AudioAccent) {
        var request = URLRequest(url: audioUrl)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", forHTTPHeaderField: "User-Agent")
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    SpeechService.shared.speak(text: term, language: accent.bcp47)
                    self?.setPlaybackState(term: nil, accent: nil)
                }
                return
            }
            
            // Lưu vào Disk Cache
            try? data.write(to: destination, options: .atomic)
            
            DispatchQueue.main.async {
                do {
                    self.audioPlayer = try AVAudioPlayer(data: data)
                    self.audioPlayer?.delegate = self
                    self.audioPlayer?.prepareToPlay()
                    self.audioPlayer?.play()
                } catch {
                    SpeechService.shared.speak(text: term, language: accent.bcp47)
                    self.setPlaybackState(term: nil, accent: nil)
                }
            }
        }
        task.resume()
    }
    
    // MARK: - Dictionary Resolvers
    
    private func resolveAudioUrl(term: String, accent: AudioAccent) -> String? {
        // Kiểm tra RAM cache trước
        if let cached = resolvedUrlCache[term]?[accent] {
            return cached
        }
        
        // Nguồn 1: Cambridge Dictionary (Rất phong phú, chuẩn phát âm Anh-Anh & Anh-Mỹ)
        if let cambridgeUrl = fetchCambridgeAudioUrl(term: term, accent: accent) {
            saveToRamCache(term: term, accent: accent, url: cambridgeUrl)
            return cambridgeUrl
        }
        
        // Nguồn 2: Oxford Learner's Dictionaries
        if let oxfordUrl = fetchOxfordAudioUrl(term: term, accent: accent) {
            saveToRamCache(term: term, accent: accent, url: oxfordUrl)
            return oxfordUrl
        }
        
        // Nguồn 3: Free Dictionary API / Wikimedia Commons
        if let freeDictUrl = fetchFreeDictionaryAudioUrl(term: term, accent: accent) {
            saveToRamCache(term: term, accent: accent, url: freeDictUrl)
            return freeDictUrl
        }
        
        return nil
    }
    
    private func saveToRamCache(term: String, accent: AudioAccent, url: String) {
        if resolvedUrlCache[term] == nil {
            resolvedUrlCache[term] = [:]
        }
        resolvedUrlCache[term]?[accent] = url
    }
    
    private func fetchCambridgeAudioUrl(term: String, accent: AudioAccent) -> String? {
        guard let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://dictionary.cambridge.org/dictionary/english/\(encoded)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        
        let semaphore = DispatchSemaphore(value: 0)
        var resultUrl: String?
        
        session.dataTask(with: request) { data, _, _ in
            defer { semaphore.signal() }
            guard let data = data, let html = String(data: data, encoding: .utf8) else { return }
            
            let prefix = accent == .uk ? "uk_pron" : "us_pron"
            let pattern = "\(prefix)/[^\"]+\\.mp3"
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                if let match = regex.firstMatch(in: html, range: range),
                   let matchRange = Range(match.range, in: html) {
                    let matchedPath = String(html[matchRange])
                    resultUrl = "https://dictionary.cambridge.org/media/english/\(matchedPath)"
                }
            }
        }.resume()
        
        _ = semaphore.wait(timeout: .now() + 4.0)
        return resultUrl
    }
    
    private func fetchOxfordAudioUrl(term: String, accent: AudioAccent) -> String? {
        guard let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://www.oxfordlearnersdictionaries.com/definition/english/\(encoded)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        
        let semaphore = DispatchSemaphore(value: 0)
        var resultUrl: String?
        
        session.dataTask(with: request) { data, _, _ in
            defer { semaphore.signal() }
            guard let data = data, let html = String(data: data, encoding: .utf8) else { return }
            
            let pattern = accent == .uk ? "data-src-mp3=\"([^\"]+uk_pron[^\"]+\\.mp3)\"" : "data-src-mp3=\"([^\"]+us_pron[^\"]+\\.mp3)\""
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                if let match = regex.firstMatch(in: html, range: range),
                   match.numberOfRanges > 1,
                   let matchRange = Range(match.range(at: 1), in: html) {
                    resultUrl = String(html[matchRange])
                }
            }
        }.resume()
        
        _ = semaphore.wait(timeout: .now() + 4.0)
        return resultUrl
    }
    
    private func fetchFreeDictionaryAudioUrl(term: String, accent: AudioAccent) -> String? {
        guard let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(encoded)") else {
            return nil
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var resultUrl: String?
        
        session.dataTask(with: url) { data, _, _ in
            defer { semaphore.signal() }
            guard let data = data,
                  let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let firstEntry = jsonArray.first,
                  let phonetics = firstEntry["phonetics"] as? [[String: Any]] else {
                return
            }
            
            let targetSuffix = accent == .uk ? "-uk.mp3" : "-us.mp3"
            for p in phonetics {
                if let audio = p["audio"] as? String, !audio.isEmpty {
                    if audio.hasSuffix(targetSuffix) {
                        resultUrl = audio
                        break
                    } else if resultUrl == nil {
                        resultUrl = audio
                    }
                }
            }
        }.resume()
        
        _ = semaphore.wait(timeout: .now() + 3.0)
        return resultUrl
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        setPlaybackState(term: nil, accent: nil)
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        setPlaybackState(term: nil, accent: nil)
    }
}
