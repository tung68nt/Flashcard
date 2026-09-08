import SwiftUI

public struct DualAudioButton: View {
    public let term: String
    public var showLabels: Bool = true
    
    @ObservedObject private var audioService = DictionaryAudioService.shared
    
    public init(term: String, showLabels: Bool = true) {
        self.term = term
        self.showLabels = showLabels
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            // Nút UK (Anh - Anh 🇬🇧)
            audioPill(accent: .uk)
            
            // Nút US (Anh - Mỹ 🇺🇸)
            audioPill(accent: .us)
        }
    }
    
    @ViewBuilder
    private func audioPill(accent: AudioAccent) -> some View {
        let cleanTerm = term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let isPlaying = audioService.activeTerm == cleanTerm && audioService.activeAccent == accent
        
        Button {
            audioService.play(term: term, accent: accent)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: isPlaying ? "speaker.wave.2.fill" : "speaker.wave.1")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(isPlaying ? Color.accentColor : Color.secondary)
                
                if showLabels {
                    Text(accent.label)
                        .font(.lexioCaptionMedium)
                        .foregroundColor(isPlaying ? Color.accentColor : Color.secondary)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(isPlaying ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(
                        isPlaying ? Color.accentColor.opacity(0.4) : Color(nsColor: .separatorColor).opacity(0.4),
                        lineWidth: 0.6
                    )
            )
        }
        .buttonStyle(.plain)
        .help("Nghe phát âm chuẩn \(accent == .uk ? "Anh - Anh (Oxford/Cambridge)" : "Anh - Mỹ (Oxford/Cambridge)")")
    }
}
