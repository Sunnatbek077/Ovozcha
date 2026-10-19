import Foundation
import Observation

/// Bitta so'zning talaffuzini tekshiradi: yozadi -> matnga aylantiradi -> baholaydi.
///
/// IOS va Android (Skip) uchun umumiy.
///
/// Muhim qoida: bu ilova 3-5 yoshdagi bolalar uchun. Nutq tanish o'zbek tilida
/// ishonchli emas (ayniqsa `r` tovushi), shuning uchun MUVAFFAQIYAT ishonch bilan
/// nishonlanadi, lekin MUVAFFAQIYATSIZLIK hech qachon "noto'g'ri" deb aytilmaydi —
/// faqat "yana bir marta aytib ko'r" deyiladi. Bola nutq tanishning xatosi uchun
/// ayblanmasligi kerak.
@MainActor
@Observable
final class WordPronunciationChecker {

    enum Phase: Equatable {
        case idle
        case recording
        /// Yozuv serverga yuborilgan, javob kutilmoqda.
        case checking
        /// Aynan to'g'ri.
        case correct
        /// Deyarli to'g'ri: `sound` — e'tibor berish kerak bo'lgan tovush.
        case almost(sound: String?)
        /// Mos kelmadi. Ayblamaymiz — qayta urinishni taklif qilamiz.
        case retry
        /// Ovoz eshitilmadi yoki juda qisqa.
        case notHeard
        /// Mikrofonga ruxsat berilmagan.
        case permissionDenied
        /// Internet yo'q.
        case offline
        /// Nutq tanish sozlanmagan yoki server xato qaytardi.
        case unavailable
    }

    /// Qaysi so'z tekshirilmoqda (`nil` — hech qaysi).
    private(set) var activeWordID: String?
    private(set) var phase: Phase = .idle

    @ObservationIgnored private let recorder = WordRecorder()
    @ObservationIgnored private let transcriber: (any TranscriptionService)?
    @ObservationIgnored private var work: Task<Void, Never>?

    /// Nutq tanish sozlanganmi. Sozlanmagan bo'lsa, UI mikrofon tugmasini ko'rsatmaydi.
    var isAvailable: Bool {
        return transcriber != nil
    }

    init(transcriber: (any TranscriptionService)? = PronunciationConfig.makeTranscriber()) {
        self.transcriber = transcriber
    }

    func isActive(_ word: LetterWord) -> Bool {
        return activeWordID == word.id
    }

    /// Shu so'z uchun yozishni boshlaydi. Boshqa so'z yozilayotgan bo'lsa, u bekor qilinadi.
    func startRecording(for word: LetterWord) {
        work?.cancel()
        recorder.cancel()
        activeWordID = word.id
        phase = .recording

        work = Task {
            let result = await recorder.start()
            if Task.isCancelled { return }
            switch result {
            case .started:
                // Bola to'xtatishni unutsa, o'zi to'xtaydi.
                try? await Task.sleep(nanoseconds: UInt64(WordRecorder.maxDuration * 1_000_000_000))
                if !Task.isCancelled && phase == .recording {
                    finishRecording(for: word)
                }
            case .permissionDenied:
                phase = .permissionDenied
            case .failed:
                phase = .unavailable
            }
        }
    }

    /// Yozishni to'xtatib, tekshiradi.
    func finishRecording(for word: LetterWord) {
        work?.cancel()
        guard let url = recorder.stop() else {
            phase = .notHeard
            return
        }
        guard let transcriber else {
            phase = .unavailable
            return
        }

        phase = .checking
        work = Task {
            do {
                let transcript = try await transcriber.transcribe(fileURL: url)
                if Task.isCancelled { return }
                phase = Self.phase(for: word, transcript: transcript)
            } catch let error as TranscriptionError {
                if Task.isCancelled { return }
                phase = error == TranscriptionError.offline ? .offline : .unavailable
            } catch {
                if Task.isCancelled { return }
                phase = .unavailable
            }
        }
    }

    /// Yozuvni bekor qiladi va boshlang'ich holatga qaytaradi.
    func reset() {
        work?.cancel()
        recorder.cancel()
        activeWordID = nil
        phase = .idle
    }

    /// Baholash natijasini UI holatiga aylantiradi.
    static func phase(for word: LetterWord, transcript: String) -> Phase {
        let cleaned = PronunciationScoring.normalize(transcript)
        if cleaned.isEmpty || PronunciationScoring.isLikelyHallucination(transcript) {
            return .notHeard
        }
        let result = PronunciationScoring.evaluate(
            target: word.text,
            references: word.references,
            transcript: transcript
        )
        switch result.verdict {
        case .excellent:
            return .correct
        case .almost(let sound):
            return .almost(sound: sound)
        case .tryAgain:
            return .retry
        }
    }
}
