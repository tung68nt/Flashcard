/**
 * Tiện ích phát âm chuẩn bản xứ bằng Web Speech Synthesis API
 */

export interface SpeechOptions {
  lang?: string;      // 'en-US' | 'en-GB' | 'ja-JP' | 'zh-CN' | etc.
  rate?: number;      // 0.5 to 2.0 (mặc định 0.9 cho học ngoại ngữ dễ nghe)
  pitch?: number;     // 0.5 to 1.5
  volume?: number;    // 0 to 1
}

class SpeechService {
  private synth: SpeechSynthesis | null = null;
  private voices: SpeechSynthesisVoice[] = [];

  constructor() {
    if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
      this.synth = window.speechSynthesis;
      this.loadVoices();
      if (this.synth.onvoiceschanged !== undefined) {
        this.synth.onvoiceschanged = () => this.loadVoices();
      }
    }
  }

  private loadVoices() {
    if (!this.synth) return;
    this.voices = this.synth.getVoices();
  }

  public getAvailableVoices(langPrefix?: string): SpeechSynthesisVoice[] {
    if (!this.synth) return [];
    if (this.voices.length === 0) {
      this.voices = this.synth.getVoices();
    }
    if (!langPrefix) return this.voices;
    return this.voices.filter(v => v.lang.toLowerCase().startsWith(langPrefix.toLowerCase()));
  }

  public speak(text: string, options: SpeechOptions = {}) {
    if (!this.synth) {
      console.warn('SpeechSynthesis is not supported in this browser.');
      return;
    }

    // Huỷ các phát âm đang phát trước đó để tránh trùng âm
    this.synth.cancel();

    const utterance = new SpeechSynthesisUtterance(text);
    const lang = options.lang || 'en-US';
    utterance.lang = lang;
    utterance.rate = options.rate !== undefined ? options.rate : 0.92;
    utterance.pitch = options.pitch !== undefined ? options.pitch : 1.0;
    utterance.volume = options.volume !== undefined ? options.volume : 1.0;

    // Chọn voice tự nhiên tốt nhất theo ngôn ngữ
    const matchingVoices = this.getAvailableVoices(lang.slice(0, 2));
    if (matchingVoices.length > 0) {
      // Ưu tiên voice chất lượng cao (Google, Samantha, Daniel, Siri, Natural)
      const naturalVoice = matchingVoices.find(v => 
        v.name.includes('Natural') || 
        v.name.includes('Google') || 
        v.name.includes('Samantha') || 
        v.name.includes('Daniel')
      ) || matchingVoices[0];
      utterance.voice = naturalVoice;
    }

    this.synth.speak(utterance);
  }

  public stop() {
    if (this.synth) {
      this.synth.cancel();
    }
  }
}

export const speechService = new SpeechService();
