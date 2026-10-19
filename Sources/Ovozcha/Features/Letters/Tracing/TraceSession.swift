import SwiftUI
import Observation

/// Muvaffaqiyatli urinish natijasi (omborga yoziladi).
struct TraceOutcome: Equatable {
    let subject: TraceSubject
    let stars: Int
    /// Shu urinishdagi birinchi muvaffaqiyatmi (kunlik mashq sonini faqat shunda oshiramiz).
    let isFirstSuccessInAttempt: Bool

    init(subject: TraceSubject, stars: Int, isFirstSuccessInAttempt: Bool) {
        self.subject = subject
        self.stars = stars
        self.isFirstSuccessInAttempt = isFirstSuccessInAttempt
    }

    /// Harflar uchun qulay init (testlar va harf omborlari shuni ishlatadi).
    ///
    /// Eslatma: Kotlin (Skip) ikkinchi konstruktor `self.init(...)` ga faqat shu konstruktorning
    /// o'z parametrlarini (mahalliy o'zgaruvchisiz) uzatishga ruxsat beradi, shuning uchun bu yerda
    /// `self.init` chaqirilmaydi — hamma xossa to'g'ridan-to'g'ri o'rnatiladi.
    init(letterID: String, style: LetterCase, stars: Int, isFirstSuccessInAttempt: Bool) {
        self.subject = TraceSubject(
            id: letterID,
            text: UzbekAlphabet.letter(id: letterID)?.text(for: style) ?? letterID,
            kind: TraceKind.letter,
            letterCase: style
        )
        self.stars = stars
        self.isFirstSuccessInAttempt = isFirstSuccessInAttempt
    }

    var letterID: String { subject.id }
    var style: LetterCase { subject.letterCase ?? .upper }
}

/// Bola uchun ko'rsatiladigan fikr-mulohaza.
enum TraceFeedback: Equatable {
    /// Hozircha fikr yo'q.
    case idle
    case success(stars: Int)
    /// Harfning butun ustidan yurmagan (qoplash kam).
    case keepGoing
    /// Harf chizig'idan ko'p chiqib ketgan (aniqlik kam).
    case stayInside
}

/// Bitta harfni iz bo'yicha chizish sessiyasi: chiziqlar, harf konturi, baho va fikr-mulohaza.
///
/// Ish tartibi: bola chizadi -> barmoq ko'tarilganda baho yangilanadi -> ~1.3 soniya yangi chiziq
/// boshlanmasa (yoki 3 yulduz bo'lsa, tezroq) natija "yakunlanadi", omborga yoziladi va fikr
/// ko'rsatiladi. Ko'p chiziqli harflarda (`E`, `k`) birinchi chiziqdan keyin darrov yakunlanib
/// qolmaslik uchun aynan shunday kechiktirish kerak.
///
/// IOS va Android (Skip) uchun umumiy. Farq faqat kontur manbasida (`GlyphSource`) va ko'rsatmaning
/// turida: iOS'da `guide` (`Path`), Android'da `guidePolylines` (ko'pburchaklar).
@MainActor
@Observable
final class TraceSession {

    // MARK: Ochiq holat (UI shuni kuzatadi)

    private(set) var subject: TraceSubject
    private(set) var strokes: [[CGPoint]] = []
    #if SKIP
    private(set) var guidePolylines: [[CGPoint]] = []
    #else
    private(set) var guide: Path = Path()
    #endif
    private(set) var feedback: TraceFeedback = TraceFeedback.idle
    private(set) var score: TraceScore = TraceScore.empty
    /// Har muvaffaqiyatli yakunlanganda +1 (haptic va animatsiyalar uchun trigger).
    private(set) var successCount: Int = 0
    private(set) var inkWidth: CGFloat = 26.0
    private(set) var isStrokeActive: Bool = false

    /// Fikr-mulohaza ko'rsatilyaptimi.
    var hasFeedback: Bool {
        switch feedback {
        case .idle:
            return false
        default:
            return true
        }
    }

    /// Muvaffaqiyatli yakunlanganda chaqiriladi.
    @ObservationIgnored var onFinish: ((TraceOutcome) -> Void)?

    // MARK: Ichki

    /// Asosiy sozlama (`.normal` / `.easy`). Raqamlar uchun `effectiveTuning` ishlatiladi.
    @ObservationIgnored private(set) var tuning: TraceTuning
    @ObservationIgnored private var effectiveTuning: TraceTuning
    @ObservationIgnored private var canvasSize: CGSize = CGSize(width: 0.0, height: 0.0)
    @ObservationIgnored private var target: TraceTarget?
    @ObservationIgnored private var finalizeTask: Task<Void, Never>?
    @ObservationIgnored private var successCountedInAttempt = false

    /// Barmoq ko'tarilgach natijani yakunlashgacha kutish (nanosoniya).
    /// Kotlin (Skip) `UInt64` (`ULong`) uchun butun son literalidan aniq o'tishni talab qiladi.
    private static let settleDelayNanos: UInt64 = UInt64(1_300_000_000)
    /// 3 yulduz bo'lsa kutib o'tirmaymiz (nanosoniya).
    private static let perfectDelayNanos: UInt64 = UInt64(250_000_000)
    /// Bundan yaqin nuqtalar qo'shilmaydi (barmoq titrashi va ortiqcha nuqtalarni kesadi).
    private static let minPointDistance: Double = 1.0

    init(subject: TraceSubject, tuning: TraceTuning = TraceTuning.normal) {
        self.subject = subject
        self.tuning = tuning
        self.effectiveTuning = tuning.tuned(for: subject.kind)
        #if !SKIP
        TraceFont.registerIfNeeded()
        #endif
    }

    init(letter: UzbekLetter, style: LetterCase, tuning: TraceTuning = TraceTuning.normal) {
        let subject = letter.subject(for: style)
        self.subject = subject
        self.tuning = tuning
        self.effectiveTuning = tuning.tuned(for: subject.kind)
        #if !SKIP
        TraceFont.registerIfNeeded()
        #endif
    }

    // MARK: Sozlash

    /// Boshqa harf, raqam yoki shaklga o'tish. Chizilgan hamma narsa tozalanadi.
    func configure(subject: TraceSubject) {
        self.subject = subject
        self.effectiveTuning = tuning.tuned(for: subject.kind)
        resetAttempt()
        rebuildTarget()
    }

    func configure(letter: UzbekLetter, style: LetterCase) {
        configure(subject: letter.subject(for: style))
    }

    /// Qiyinlikni almashtirish (masalan, ota-ona panelidan). Chizilgan tozalanadi.
    func apply(tuning: TraceTuning) {
        self.tuning = tuning
        self.effectiveTuning = tuning.tuned(for: subject.kind)
        resetAttempt()
        rebuildTarget()
    }

    /// Tuval o'lchami (yoki aylantirish) o'zgarganda chaqiriladi.
    /// Android'da doim `GlyphSource.referenceSize`: real o'lchamga moslashni ko'rinish qiladi.
    func setCanvasSize(_ size: CGSize) {
        if size.width < 40.0 || size.height < 40.0 { return }
        if abs(size.width - canvasSize.width) < 0.5 && abs(size.height - canvasSize.height) < 0.5 { return }
        canvasSize = size
        resetAttempt()
        rebuildTarget()
    }

    /// "Qaytadan": chizilganni o'chiradi (yangi urinish boshlanadi).
    func restart() {
        resetAttempt()
    }

    // MARK: Chizish

    func beginStroke(at point: CGPoint) {
        finalizeTask?.cancel()
        finalizeTask = nil
        feedback = TraceFeedback.idle
        isStrokeActive = true
        strokes.append([point])
    }

    func extendStroke(to point: CGPoint) {
        if !isStrokeActive { return }
        let lastIndex = strokes.count - 1
        if lastIndex < 0 { return }
        var current = strokes[lastIndex]
        if current.count > 0 {
            let previous = current[current.count - 1]
            let dx = Double(point.x - previous.x)
            let dy = Double(point.y - previous.y)
            if sqrt(dx * dx + dy * dy) < TraceSession.minPointDistance { return }
        }
        current.append(point)
        strokes[lastIndex] = current
    }

    func endStroke() {
        if !isStrokeActive { return }
        isStrokeActive = false
        guard let target = target else { return }
        score = TraceEvaluator.evaluate(strokes: strokes, target: target, tuning: effectiveTuning)
        let delay = score.stars >= 3 ? TraceSession.perfectDelayNanos : TraceSession.settleDelayNanos
        scheduleFinalize(afterNanos: delay)
    }

    // MARK: Yakunlash

    private func scheduleFinalize(afterNanos delay: UInt64) {
        finalizeTask?.cancel()
        finalizeTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            if Task.isCancelled { return }
            self?.finalize()
        }
    }

    private func finalize() {
        finalizeTask = nil
        if strokes.isEmpty { return }

        if score.stars >= 1 {
            feedback = TraceFeedback.success(stars: score.stars)
            successCount += 1
            let isFirst = !successCountedInAttempt
            successCountedInAttempt = true
            onFinish?(TraceOutcome(
                subject: subject,
                stars: score.stars,
                isFirstSuccessInAttempt: isFirst
            ))
        } else if score.precision < effectiveTuning.thresholds[0].precision {
            feedback = TraceFeedback.stayInside
        } else {
            feedback = TraceFeedback.keepGoing
        }
    }

    // MARK: Ichki yordamchilar

    private func resetAttempt() {
        finalizeTask?.cancel()
        finalizeTask = nil
        strokes = []
        score = TraceScore.empty
        feedback = TraceFeedback.idle
        isStrokeActive = false
        successCountedInAttempt = false
    }

    private func rebuildTarget() {
        if canvasSize.width < 40.0 || canvasSize.height < 40.0 { return }
        let build = GlyphSource.build(subject: subject, canvas: canvasSize, gridWidth: effectiveTuning.gridWidth)
        target = TraceTarget(mask: build.mask, canvasSize: canvasSize, em: build.em, tuning: effectiveTuning)
        #if SKIP
        guidePolylines = build.guidePolylines
        #else
        guide = build.guide
        #endif
        inkWidth = max(16.0, build.em * 0.095)
    }
}
