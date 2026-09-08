import Foundation
import AVFoundation

public final class SpeechService: NSObject, @unchecked Sendable, AVSpeechSynthesizerDelegate {
    public static let shared = SpeechService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    public var preferredAccent: AudioAccent {
        get {
            if let saved = UserDefaults.standard.string(forKey: "lexio_preferred_accent"),
               let accent = AudioAccent(rawValue: saved) {
                return accent
            }
            return .us
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "lexio_preferred_accent")
        }
    }
    
    private override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    public func speak(text: String, language: String = "en-US") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Dừng audio phát từ điển nếu đang phát
        DictionaryAudioService.shared.stop()
        
        // Dừng phát âm trước đó
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.rate = 0.46 // Tốc độ chuẩn, tự nhiên cho học từ vựng, thành ngữ & câu ví dụ
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Tìm voice bản xứ chất lượng cao nhất (ưu tiên Premium / Enhanced Siri voice của Apple)
        let availableVoices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == language }
        if let premiumVoice = availableVoices.first(where: { $0.quality == .premium }) ?? availableVoices.first(where: { $0.quality == .enhanced }) ?? availableVoices.first {
            utterance.voice = premiumVoice
        } else if let voice = AVSpeechSynthesisVoice(language: language) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        synthesizer.speak(utterance)
    }
    
    /// Phát âm từ vựng ưu tiên audio chuẩn studio Oxford/Cambridge, nếu câu dài hoặc từ không có thì fallback sang TTS
    public func speakTerm(_ term: String, language: String = "en-US", accent: AudioAccent? = nil) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Nếu là tiếng Anh và từ ngắn (< 4 từ) -> dùng audio chuẩn phòng thu Oxford/Cambridge
        let isEnglish = language.lowercased().starts(with: "en")
        let wordCount = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        
        if isEnglish && wordCount <= 3 {
            let selectedAccent = accent ?? preferredAccent
            DictionaryAudioService.shared.play(term: trimmed, accent: selectedAccent)
        } else {
            let targetLang = accent == .uk ? "en-GB" : (accent == .us ? "en-US" : language)
            speak(text: trimmed, language: targetLang)
        }
    }
    
    public func stop() {
        DictionaryAudioService.shared.stop()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
