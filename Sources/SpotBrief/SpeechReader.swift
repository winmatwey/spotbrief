import Foundation
import AVFoundation

/// Озвучивает краткое содержание новости offline через системный синтез речи —
/// без сторонних API и ключей. Одна общая копия на всё приложение, чтобы
/// при переходе на другую новость озвучка предыдущей корректно останавливалась.
@MainActor
final class SpeechReader: NSObject, ObservableObject {

    static let shared = SpeechReader()

    @Published private(set) var isSpeaking = false
    @Published private(set) var speakingItemID: UUID?

    private let synthesizer = AVSpeechSynthesizer()

    /// Утверждение, которое сейчас звучит. Используется делегатом, чтобы
    /// отличить "настоящее" окончание/отмену текущей реплики от запоздалого
    /// колбэка о ПРЕДЫДУЩЕЙ, уже отменённой репликой — без этой проверки
    /// асинхронный didCancel от старой новости мог прилететь уже после того,
    /// как мы начали озвучивать следующую, и сбрасывал isSpeaking для неё же.
    /// Именно из-за этой гонки индикатор озвучки мог "не включаться" или
    /// сразу гаснуть при переключении между новостями.
    private weak var currentUtterance: AVSpeechUtterance?

    private override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }

    /// Без явной настройки категории аудиосессии звук синтеза речи
    /// на устройстве с включённым боковым переключателем "Бесшумно"
    /// не воспроизводится вовсе — код при этом не падает и не логирует
    /// ошибку, поэтому выглядит так, будто "функция просто не работает".
    /// .playback игнорирует переключатель бесшумного режима.
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch {
            // Не критично: в худшем случае озвучка не заработает на симуляторе
            // без аудиовыхода — на реальном устройстве setCategory почти
            // никогда не бросает ошибку.
        }
    }

    /// Озвучивает переданный текст (обычно — заголовок + краткое содержание,
    /// в т.ч. расширенное, если оно уже подгружено) на заданном языке.
    /// Повторное нажатие на уже озвучиваемую новость — останавливает чтение.
    func toggle(id: UUID, text: String, languageCode: String) {
        if isSpeaking && speakingItemID == id {
            stop()
            return
        }

        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = Self.bestAvailableVoice(for: languageCode)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        currentUtterance = utterance
        speakingItemID = id
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        currentUtterance = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        speakingItemID = nil
    }

    /// Ищет голос для нужного языка; если для него (например, казахского)
    /// на устройстве нет системного голоса синтеза речи, возвращает nil —
    /// тогда AVSpeechSynthesizer сам подставляет голос по умолчанию вместо
    /// того, чтобы молча ничего не произносить.
    private static func bestAvailableVoice(for languageCode: String) -> AVSpeechSynthesisVoice? {
        if let exact = AVSpeechSynthesisVoice(language: languageCode) {
            return exact
        }
        let prefix = languageCode.split(separator: "-").first.map(String.init) ?? languageCode
        return AVSpeechSynthesisVoice.speechVoices().first { $0.language.hasPrefix(prefix) }
    }
}

extension SpeechReader: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                        didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard utterance === self.currentUtterance else { return }
            self.isSpeaking = false
            self.speakingItemID = nil
            self.currentUtterance = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                        didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard utterance === self.currentUtterance else { return }
            self.isSpeaking = false
            self.speakingItemID = nil
            self.currentUtterance = nil
        }
    }
}
