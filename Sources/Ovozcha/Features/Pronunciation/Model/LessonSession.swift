import Foundation
import Observation

/// Bitta bosqichni o'tish: mashq ko'rsatiladi -> murabbiy namunani aytadi -> bola aytadi
/// (yoki quloq o'yinida tanlaydi) -> murabbiy javob beradi -> keyingisi.
///
/// IOS va Android (Skip) uchun umumiy.
@MainActor
@Observable
final class LessonSession {

    enum Phase: Equatable {
        /// Bola harakatini kutmoqda.
        case ready
        case recording
        /// Yozuv nutq tanishga yuborilgan.
        case checking
    }

    /// Quloq o'yinidagi bitta variant.
    struct PairOption: Equatable {
        let clip: String
        let isCorrect: Bool
    }

    let lesson: SoundLesson
    let stage: LessonStage
    /// Shu qurilmada o'ynasa bo'ladigan mashqlar (ovozi yo'q quloq o'yini chiqarib tashlanadi).
    let items: [LessonItem]
    let player: ClipPlayer

    private(set) var index = 0
    private(set) var phase: Phase = .ready
    /// Murabbiy hozir nima deyapti.
    private(set) var line: CoachLine
    /// Ota-ona uchun: nutq tanish nima eshitgani.
    private(set) var heardText: String?
    /// Oxirgi tashxis mashq tovushini topdimi (so'zda o'sha harflar boshqa rangda ko'rsatiladi).
    private(set) var soundMissed = false
    /// Joriy mashq bajarildimi.
    private(set) var itemDone = false
    private(set) var ownRecording: URL?
    private(set) var pairOptions: [PairOption] = []
    private(set) var isFinished = false
    /// Shu o'tishda bajarilganlar soni.
    private(set) var doneInRun = 0

    /// Mashq bajarilganda (omborga yozish uchun).
    @ObservationIgnored var onItemDone: ((LessonItem) -> Void)?
    /// So'z tekshirilganda: so'z va aniqlik (0...1) — faoliyat tarixi uchun.
    @ObservationIgnored var onWordChecked: ((LessonItem, Double) -> Void)?

    @ObservationIgnored private let recorder = WordRecorder()
    @ObservationIgnored private let transcriber: (any TranscriptionService)?
    @ObservationIgnored private var work: Task<Void, Never>?
    @ObservationIgnored private var attempts = 0
    @ObservationIgnored private var hasBegun = false

    init(lesson: SoundLesson, stage: LessonStage, player: ClipPlayer, transcriber: (any TranscriptionService)? = PronunciationConfig.makeTranscriber()) {
        self.lesson = lesson
        self.stage = stage
        self.player = player
        self.transcriber = transcriber
        self.items = LessonSession.playableItems(stage.items, player: player)
        self.line = CoachLine(text: "", clips: [], tone: .neutral)
    }

    /// Quloq o'yini yozuvlarsiz ma'nosiz: yozuvi yo'q mashqlar tashlanadi.
    static func playableItems(_ items: [LessonItem], player: ClipPlayer) -> [LessonItem] {
        var result: [LessonItem] = []
        for item in items {
            if player.hasAll(item.requiredClips) {
                result.append(item)
            }
        }
        return result
    }

    var item: LessonItem? {
        if index < items.count { return items[index] }
        return nil
    }

    /// So'zlarni tekshirish sozlanganmi (kalit yoki server manzili bor).
    var canCheckWords: Bool {
        return transcriber != nil
    }

    var isLastItem: Bool {
        return index >= items.count - 1
    }

    // MARK: Boshqaruv

    /// Ekran ochilganda. Qayta ochilganda (masalan, Android'da tab almashib qaytganda)
    /// joriy mashq saqlanadi.
    func begin() {
        if hasBegun { return }
        hasBegun = true
        show(0)
    }

    func next() {
        if isLastItem {
            finish()
        } else {
            show(index + 1)
        }
    }

    func restart() {
        doneInRun = 0
        isFinished = false
        show(0)
    }

    /// Ekran yopilganda.
    func cancel() {
        work?.cancel()
        recorder.cancel()
        player.stop()
        phase = .ready
    }

    // MARK: Tinglash

    /// Namunani (to'g'ri aytilishini) qayta eshittiradi.
    func playModel() {
        guard let item = item else { return }
        player.play([item.modelClip])
    }

    /// Murabbiy gapini qayta eshittiradi.
    func replayLine() {
        player.play(line.clips)
    }

    func playOwnRecording() {
        guard let url = ownRecording else { return }
        player.play([], then: url)
    }

    func playOption(_ option: Int) {
        if option < pairOptions.count {
            player.play([pairOptions[option].clip])
        }
    }

    // MARK: Gapirish

    func toggleRecording() {
        switch phase {
        case .recording:
            finishRecording()
        case .checking:
            return
        case .ready:
            startRecording()
        }
    }

    private func startRecording() {
        guard let item = item else { return }
        work?.cancel()
        player.stop()
        heardText = nil
        phase = .recording

        work = Task {
            let result = await recorder.start()
            if Task.isCancelled { return }
            switch result {
            case .started:
                // Bola to'xtatishni unutsa, o'zi to'xtaydi.
                try? await Task.sleep(nanoseconds: UInt64(WordRecorder.maxDuration * 1_000_000_000.0))
                if !Task.isCancelled && phase == .recording && self.item == item {
                    finishRecording()
                }
            case .permissionDenied:
                phase = .ready
                say(CoachLine(text: Strings.Coach.micDenied, clips: [], tone: .hint))
            case .failed:
                phase = .ready
                say(CoachLine(text: Strings.Coach.unavailable, clips: [], tone: .hint))
            }
        }
    }

    private func finishRecording() {
        guard let item = item else { return }
        work?.cancel()
        guard let url = recorder.stop() else {
            phase = .ready
            say(CoachScript.feedback(for: .notHeard, word: item.text, lesson: lesson, attempt: attempts + 1))
            return
        }
        ownRecording = url

        switch item.kind {
        case .sound, .syllables:
            // Baholanmaydi: bola takrorladi va o'z ovozini eshitadi.
            phase = .ready
            markDone(item)
            let praise = CoachScript.selfListen()
            line = praise
            player.play(praise.clips, then: url)
        case .word:
            check(url: url, item: item)
        case .pair:
            phase = .ready
        }
    }

    private func check(url: URL, item: LessonItem) {
        guard let transcriber = transcriber else {
            phase = .ready
            say(CoachLine(text: Strings.Coach.unavailable, clips: [], tone: .hint))
            return
        }
        phase = .checking
        work = Task {
            do {
                let transcript = try await transcriber.transcribe(fileURL: url)
                if Task.isCancelled { return }
                handle(transcript: transcript, item: item)
            } catch let error as TranscriptionError {
                if Task.isCancelled { return }
                phase = .ready
                let text = error == TranscriptionError.offline ? Strings.Coach.offline : Strings.Coach.unavailable
                say(CoachLine(text: text, clips: [], tone: .hint))
            } catch {
                if Task.isCancelled { return }
                phase = .ready
                say(CoachLine(text: Strings.Coach.unavailable, clips: [], tone: .hint))
            }
        }
    }

    private func handle(transcript: String, item: LessonItem) {
        let diagnosis = SpeechDiagnosis.diagnose(
            target: item.text,
            focus: lesson.sound,
            references: item.references,
            transcript: transcript
        )
        attempts += 1
        phase = .ready

        switch diagnosis {
        case .correct:
            heardText = nil
            soundMissed = false
            markDone(item)
            onWordChecked?(item, 1.0)
        case .soundSwap(_, _, _, let heardWord):
            heardText = heardWord
            soundMissed = true
            onWordChecked?(item, score(item, transcript))
        case .almost(let heardWord):
            heardText = heardWord.isEmpty ? nil : heardWord
            soundMissed = false
            onWordChecked?(item, score(item, transcript))
        case .retry(let heardWord):
            heardText = heardWord.isEmpty ? nil : heardWord
            soundMissed = false
            onWordChecked?(item, score(item, transcript))
        case .notHeard:
            heardText = nil
            soundMissed = false
        }
        say(CoachScript.feedback(for: diagnosis, word: item.text, lesson: lesson, attempt: attempts))
    }

    private func score(_ item: LessonItem, _ transcript: String) -> Double {
        return PronunciationScoring.evaluate(target: item.text, references: item.references, transcript: transcript).score
    }

    // MARK: Quloq o'yini

    func choose(_ option: Int) {
        guard let item = item, option < pairOptions.count, !itemDone else { return }
        attempts += 1
        let correct = pairOptions[option].isCorrect
        if correct {
            markDone(item)
        }
        let answer = CoachScript.pairAnswer(correct: correct, item: item, attempt: attempts)
        line = answer
        if correct {
            player.play(answer.clips)
        } else {
            // Ikkalasini yana bir bor eshittiramiz.
            playOptions(after: answer.clips)
        }
    }

    // MARK: Ichki

    private func show(_ newIndex: Int) {
        work?.cancel()
        recorder.cancel()
        player.stop()
        index = newIndex
        phase = .ready
        attempts = 0
        heardText = nil
        soundMissed = false
        ownRecording = nil
        itemDone = false
        pairOptions = []

        guard let item = item else {
            finish()
            return
        }

        let intro = CoachScript.intro(for: item, hasModel: player.has(item.modelClip))
        line = intro
        switch item.kind {
        case .pair:
            let correct = PairOption(clip: item.modelClip, isCorrect: true)
            let wrong = PairOption(clip: item.wrongClip, isCorrect: false)
            pairOptions = Int.random(in: 0..<2) == 0 ? [correct, wrong] : [wrong, correct]
            playOptions(after: intro.clips)
        default:
            // Murabbiy ko'rsatmasi, keyin namuna. Ko'rsatma yozuvi yo'q bo'lsa — faqat namuna.
            if !player.play(intro.clips + [item.modelClip]) {
                player.play([item.modelClip])
            }
        }
    }

    /// "<ko'rsatma>. Birinchisi: arra. Ikkinchisi: ayya." Murabbiy iboralari yozilmagan bo'lsa —
    /// faqat ikki variant ketma-ket (ular quloq o'yinining sharti, doim bor).
    private func playOptions(after prefix: [String]) {
        if pairOptions.count != 2 { return }
        var full = prefix
        full.append(CoachAudio.phrase("first"))
        full.append(pairOptions[0].clip)
        full.append(CoachAudio.phrase("second"))
        full.append(pairOptions[1].clip)
        if !player.play(full) {
            player.play([pairOptions[0].clip, pairOptions[1].clip])
        }
    }

    private func say(_ newLine: CoachLine) {
        line = newLine
        player.play(newLine.clips)
    }

    private func markDone(_ item: LessonItem) {
        if itemDone { return }
        itemDone = true
        doneInRun += 1
        onItemDone?(item)
    }

    private func finish() {
        work?.cancel()
        recorder.cancel()
        isFinished = true
        phase = .ready
        say(CoachScript.stageDone(done: doneInRun, total: items.count))
    }
}
