#if !SKIP
import Testing
import Foundation
import CoreGraphics
import CoreText
@testable import Ovozcha

// Iz chizish mantiqi testlari (2-bosqich, faqat iOS).
//
// Kutilgan raqamlar Python prototipidagi (proto/sim*.py) aynan shu algoritm nusxasida
// hisoblangan va bu yerdagi sun'iy shakllarda tekshirilgan.

/// 340x380 pt tuval, 96x107 to'r (bir katak ~3.54 pt), shrift o'lchami 220 pt.
private enum Fixture {
    static let canvas = CGSize(width: 340, height: 380)
    static let em: CGFloat = 220
    static let gridWidth = 96
    static let gridHeight = 107
    static var cell: CGFloat { canvas.width / CGFloat(gridWidth) }

    /// Katak koordinatasidagi nuqta -> tuval nuqtasi.
    static func point(_ x: Double, _ y: Double) -> CGPoint {
        CGPoint(x: CGFloat(x) * cell, y: CGFloat(y) * cell)
    }

    /// 8 katak enli, 70 katak baland tik "tayoq". `withDot`: tepasida alohida 6x6 nuqta (`i` kabi).
    static func bar(withDot: Bool) -> TraceGrid {
        var grid = TraceGrid(width: gridWidth, height: gridHeight)
        for y in 20..<90 {
            for x in 45..<53 {
                grid.set(x: x, y: y, to: true)
            }
        }
        if withDot {
            for y in 8..<14 {
                for x in 45..<51 {
                    grid.set(x: x, y: y, to: true)
                }
            }
        }
        return grid
    }

    static func score(_ strokes: [[CGPoint]], on mask: TraceGrid, tuning: TraceTuning = .normal) -> TraceScore {
        let target = TraceTarget(mask: mask, canvasSize: canvas, em: em, tuning: tuning)
        return TraceEvaluator.evaluate(strokes: strokes, target: target, tuning: tuning)
    }

    static var fullStroke: [CGPoint] { [point(49, 20.5), point(49, 89.5)] }
}

@Suite("To'r va morfologiya")
struct GridMorphologyTests {

    @Test func discOffsetsMatchGeometry() {
        #expect(TraceGrid.discOffsets(radius: 0).count == 1)
        #expect(TraceGrid.discOffsets(radius: 1).count == 5)
        #expect(TraceGrid.discOffsets(radius: 2).count == 13)
    }

    @Test func dilationOfSingleCellIsADisc() {
        var grid = TraceGrid(width: 21, height: 21)
        grid.set(x: 10, y: 10, to: true)
        #expect(grid.dilated(radius: 2).filledCount == 13)
        #expect(grid.dilated(radius: 0) == grid)
    }

    @Test func thinningReducesBarToItsCentreLine() {
        let skeleton = TraceMorphology.thinned(Fixture.bar(withDot: false))
        // Kutilgan: bitta ustun (x = 48), 62 katak (y 24...85).
        #expect(skeleton.filledCount >= 55 && skeleton.filledCount <= 70)
        for y in 0..<skeleton.height {
            for x in 0..<skeleton.width where skeleton.value(x: x, y: y) {
                #expect(x >= 47 && x <= 50)
            }
        }
    }

    @Test func componentsAreLabelledWithEightConnectivity() {
        let count = TraceMorphology.components(of: Fixture.bar(withDot: true)).count
        #expect(count == 2)

        // Diagonal ulangan ikki katak — 8 qo'shnilikda bitta komponent.
        var diagonal = TraceGrid(width: 5, height: 5)
        diagonal.set(x: 1, y: 1, to: true)
        diagonal.set(x: 2, y: 2, to: true)
        #expect(TraceMorphology.components(of: diagonal).count == 1)
    }

    @Test func dotBecomesADetailGroupButBarDoesNot() {
        #expect(TraceScoring.make(from: Fixture.bar(withDot: false)).detailGroups.isEmpty)
        let withDot = TraceScoring.make(from: Fixture.bar(withDot: true))
        #expect(withDot.detailGroups.count == 1)
        #expect(withDot.detailGroups[0].count == 4)
    }
}

@Suite("Baholash")
struct EvaluatorTests {

    @Test func starThresholdsMapCorrectly() {
        let t = TraceTuning.normal
        #expect(t.stars(coverage: 0.69, precision: 0.90, missingDetail: false) == 0)
        #expect(t.stars(coverage: 0.70, precision: 0.60, missingDetail: false) == 1)
        #expect(t.stars(coverage: 0.82, precision: 0.75, missingDetail: false) == 2)
        #expect(t.stars(coverage: 0.92, precision: 0.85, missingDetail: false) == 3)
        #expect(t.stars(coverage: 1.00, precision: 1.00, missingDetail: true) == 2)
        #expect(t.stars(coverage: 1.00, precision: 0.59, missingDetail: false) == 0)
    }

    @Test func perfectTraceGetsThreeStars() {
        let score = Fixture.score([Fixture.fullStroke], on: Fixture.bar(withDot: false))
        #expect(score.stars == 3)
        #expect(score.coverage >= 0.99)
        #expect(score.precision >= 0.99)
    }

    @Test func emptyDrawingGetsNothing() {
        let score = Fixture.score([], on: Fixture.bar(withDot: false))
        #expect(score == TraceScore.empty)
    }

    @Test func singleTapOnALetterIsNotEnough() {
        let score = Fixture.score([[Fixture.point(49, 50)]], on: Fixture.bar(withDot: false))
        #expect(score.stars == 0)
        #expect(score.coverage < 0.3)
    }

    @Test func traceOutsideTheLetterFailsOnPrecision() {
        // Harfdan 6 katak (~21 pt) chetda, to'g'ri chiziq.
        let shifted = [Fixture.point(55, 20.5), Fixture.point(55, 89.5)]
        let score = Fixture.score([shifted], on: Fixture.bar(withDot: false))
        #expect(score.stars == 0)
        #expect(score.precision < 0.1)
    }

    @Test func halfTraceIsNotEnough() {
        let half = [Fixture.point(49, 20.5), Fixture.point(49, 55)]
        let score = Fixture.score([half], on: Fixture.bar(withDot: false))
        #expect(score.stars == 0)
        #expect(score.coverage < 0.70)
        #expect(score.precision > 0.95)
    }

    @Test func scribbleAcrossTheLetterIsRejected() {
        let lines = [30.0, 40.0, 50.0, 60.0, 70.0].map { [Fixture.point(5, $0), Fixture.point(90, $0)] }
        let score = Fixture.score(lines, on: Fixture.bar(withDot: false))
        #expect(score.stars == 0)
        #expect(score.precision < 0.3)
    }

    @Test func missingDotCapsAtTwoStars() {
        let mask = Fixture.bar(withDot: true)

        let withoutDot = Fixture.score([Fixture.fullStroke], on: mask)
        #expect(withoutDot.missingDetail)
        #expect(withoutDot.stars == 2)

        let tap = [Fixture.point(48, 11)]
        let withDot = Fixture.score([Fixture.fullStroke, tap], on: mask)
        #expect(!withDot.missingDetail)
        #expect(withDot.stars == 3)
    }

    @Test func multiStrokeLettersAreScoredTogether() {
        // Tayoq ikki bo'lakda chizilsa ham (barmoq ko'tarilib), umumiy natija 3 yulduz.
        let top = [Fixture.point(49, 20.5), Fixture.point(49, 55)]
        let bottom = [Fixture.point(49, 55), Fixture.point(49, 89.5)]
        let score = Fixture.score([top, bottom], on: Fixture.bar(withDot: false))
        #expect(score.stars == 3)
    }

    @Test func easyPresetStillRequiresPrecision() {
        let shifted = [Fixture.point(55, 20.5), Fixture.point(55, 89.5)]
        let score = Fixture.score([shifted], on: Fixture.bar(withDot: false), tuning: .easy)
        #expect(score.stars == 0)
    }
}

@Suite("Harflar va shrift")
struct AlphabetAndFontTests {

    @Test func alphabetHasTwentyNineUniqueLetters() {
        let letters = UzbekAlphabet.letters
        #expect(letters.count == 29)
        #expect(Set(letters.map { $0.id }).count == 29)
        for letter in letters {
            #expect(!letter.exampleWord.isEmpty)
            // Fayl nomi va progress kaliti faqat ASCII bo'lishi kerak.
            #expect(letter.id.allSatisfy { $0.isASCII && ($0.isLowercase || $0 == "_") })
            #expect(letter.audioFileName == "letter_" + letter.id)
        }
    }

    @Test func oAndGUseTheOkinaCharacter() throws {
        let o = try #require(UzbekAlphabet.letter(id: "o_apos"))
        let g = try #require(UzbekAlphabet.letter(id: "g_apos"))
        #expect(o.upper.contains("\u{02BB}") && o.lower.contains("\u{02BB}"))
        #expect(g.upper.contains("\u{02BB}") && g.lower.contains("\u{02BB}"))
        #expect(!o.upper.contains("'") && !g.lower.contains("'"))
    }

    /// Andika-Bold.ttf `Resources/Fonts/` ichida bo'lmasa yoki ro'yxatdan o'tmasa, iz ko'rsatmasi
    /// jimgina Poppins'ga o'tib ketadi va "Oʻ", "Gʻ" belgisi noto'g'ri chiqadi. Shuni ushlaymiz.
    @Test func andikaIsBundledAndRegistered() {
        let font = TraceFont.makeCTFont(size: 100)
        let name = CTFontCopyPostScriptName(font) as String
        #expect(name == TraceFont.primaryName, "Andika-Bold.ttf topilmadi yoki ro'yxatdan o'tmadi: \(name)")
    }

    @Test func everyLetterProducesAUsableGlyphMask() {
        let canvas = CGSize(width: 340, height: 380)
        for letter in UzbekAlphabet.letters {
            for style in LetterCase.allCases {
                let text = letter.text(for: style)
                let layout = GlyphOutline.layout(text: text, canvas: canvas)
                let box = layout.path.boundingBoxOfPath
                #expect(!box.isNull && box.width > 20, "\(text): kontur bo'sh")
                #expect(box.minX >= 0 && box.maxX <= canvas.width, "\(text): kenglik tuvaldan chiqib ketdi")
                #expect(box.minY >= 0 && box.maxY <= canvas.height, "\(text): balandlik tuvaldan chiqib ketdi")

                let mask = GlyphRasterizer.mask(of: layout.path, canvas: canvas, gridWidth: 96)
                #expect(mask.filledCount > 150, "\(text): niqob juda kichik")

                let scoring = TraceScoring.make(from: mask)
                #expect(scoring.cells.count >= 8, "\(text): skelet juda qisqa")
            }
        }
    }

    @Test func dottedLettersHaveADetailGroup() {
        let canvas = CGSize(width: 340, height: 380)
        for id in ["i", "j"] {
            guard let letter = UzbekAlphabet.letter(id: id) else {
                Issue.record("\(id) harfi yo'q")
                continue
            }
            let layout = GlyphOutline.layout(text: letter.lower, canvas: canvas)
            let mask = GlyphRasterizer.mask(of: layout.path, canvas: canvas, gridWidth: 96)
            #expect(TraceScoring.make(from: mask).detailGroups.count >= 1, "\(id) nuqtasi topilmadi")
        }
    }
}

@MainActor
@Suite("Progress ombori")
struct ProgressStoreTests {

    private func makeDefaults() -> UserDefaults {
        let name = "ovozcha.tests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func recordsBestStarsAndLearnsWhenBothCasesDone() throws {
        let defaults = makeDefaults()
        let store = LetterProgressStore(defaults: defaults)
        let a = try #require(UzbekAlphabet.letter(id: "a"))

        store.record(TraceOutcome(letterID: "a", style: .upper, stars: 2, isFirstSuccessInAttempt: true))
        #expect(store.stars(for: a, style: .upper) == 2)
        #expect(!store.isLearned(a))
        #expect(store.lastLearnedLetter == nil)

        store.record(TraceOutcome(letterID: "a", style: .lower, stars: 1, isFirstSuccessInAttempt: true))
        #expect(store.isLearned(a))
        #expect(store.lastLearnedLetter?.id == "a")
        #expect(store.learnedCount == 1)

        // Yulduz pasayib ketmaydi.
        store.record(TraceOutcome(letterID: "a", style: .upper, stars: 1, isFirstSuccessInAttempt: false))
        #expect(store.stars(for: a, style: .upper) == 2)
    }

    @Test func zeroStarOutcomeIsIgnored() {
        let store = LetterProgressStore(defaults: makeDefaults())
        store.record(TraceOutcome(letterID: "a", style: .upper, stars: 0, isFirstSuccessInAttempt: true))
        #expect(store.todayCount == 0)
        #expect(store.records.isEmpty)
    }

    @Test func dailyCountOnlyGrowsOncePerAttempt() {
        let store = LetterProgressStore(defaults: makeDefaults())
        store.record(TraceOutcome(letterID: "b", style: .upper, stars: 1, isFirstSuccessInAttempt: true))
        store.record(TraceOutcome(letterID: "b", style: .upper, stars: 3, isFirstSuccessInAttempt: false))
        #expect(store.todayCount == 1)
    }

    @Test func persistsAndResetsOnANewDay() throws {
        let defaults = makeDefaults()
        var current = Date(timeIntervalSince1970: 1_800_000_000)
        let store = LetterProgressStore(defaults: defaults, now: { current })
        store.record(TraceOutcome(letterID: "d", style: .upper, stars: 3, isFirstSuccessInAttempt: true))
        store.record(TraceOutcome(letterID: "d", style: .lower, stars: 2, isFirstSuccessInAttempt: true))

        let reloaded = LetterProgressStore(defaults: defaults, now: { current })
        let d = try #require(UzbekAlphabet.letter(id: "d"))
        #expect(reloaded.isLearned(d))
        #expect(reloaded.todayCount == 2)
        #expect(reloaded.lastLearnedLetter?.id == "d")

        // 36 soat keyin — albatta boshqa kun.
        current = current.addingTimeInterval(36 * 3600)
        #expect(reloaded.todayCount == 0)
        #expect(reloaded.isLearned(d))
    }
}

// MARK: - 3-5 bosqichlar: raqamlar, talaffuz, faoliyat, sozlamalar

@Suite("Raqamlar")
struct NumberGlyphTests {

    @Test func numbersAreOneToTenWithApostropheWords() {
        #expect(UzbekNumbers.all.count == 10)
        #expect(UzbekNumbers.all.map { $0.value } == Array(1...10))
        #expect(UzbekNumbers.all.allSatisfy { !$0.word.isEmpty })
        // to'rt, to'qqiz, o'n: U+02BB
        for value in [4, 9, 10] {
            let word = UzbekNumbers.all[value - 1].word
            #expect(word.contains("\u{02BB}"), "\(value): \(word)")
        }
        #expect(UzbekNumbers.all[4].audioFileName == "number_5")
    }

    @Test func digitsUseTheirOwnStricterTuning() {
        let letters = TraceTuning.normal
        let digits = TraceTuning.normal.tuned(for: .digit)
        #expect(letters.tuned(for: .letter) == letters)
        #expect(digits.reachEm == 0.07)
        #expect(digits.toleranceEm == 0.03)
        #expect(digits.reachEm < letters.reachEm)
        #expect(digits.thresholds == letters.thresholds)
    }

    @Test func everyNumberProducesAUsableGlyphMask() {
        let canvas = CGSize(width: 340, height: 380)
        for number in UzbekNumbers.all {
            let layout = GlyphOutline.layout(text: number.text, canvas: canvas, kind: .digit)
            let box = layout.path.boundingBoxOfPath
            #expect(!box.isNull && box.width > 20, "\(number.text): kontur bo'sh")
            #expect(box.minX >= 0 && box.maxX <= canvas.width, "\(number.text): kenglik tuvaldan chiqdi")
            #expect(box.minY >= 0 && box.maxY <= canvas.height, "\(number.text): balandlik tuvaldan chiqdi")

            let mask = GlyphRasterizer.mask(of: layout.path, canvas: canvas, gridWidth: 96)
            #expect(mask.filledCount > 200, "\(number.text): niqob juda kichik")
            #expect(TraceScoring.make(from: mask).detailGroups.isEmpty, "\(number.text): raqamda nuqta bo'lmasligi kerak")
        }
    }

    /// Oddiy Andika "1" da pastki chiziq (poydevor) bor. Maktabda poydevorsiz yoziladi, shuning
    /// uchun `one.NoBase` glifi ishlatiladi. Poydevor bo'lsa, raqam ancha kengroq chiqardi.
    @Test func plainOneHasNoBase() {
        let canvas = CGSize(width: 340, height: 380)
        let layout = GlyphOutline.layout(text: "1", canvas: canvas, kind: .digit)
        let mask = GlyphRasterizer.mask(of: layout.path, canvas: canvas, gridWidth: 96)
        var minX = mask.width
        var maxX = -1
        for y in 0..<mask.height {
            for x in 0..<mask.width where mask.value(x: x, y: y) {
                minX = min(minX, x)
                maxX = max(maxX, x)
            }
        }
        // Poydevorsiz ~26 katak, poydevor bilan ~38 katak.
        #expect(maxX - minX + 1 < 32, "1 raqami juda keng: poydevorli glif ishlatilgan bo'lishi mumkin")
    }
}

@Suite("Talaffuz baholash")
struct PronunciationScoringTests {

    @Test func exactMatchIsExcellent() {
        #expect(PronunciationScoring.evaluate(target: "olma", transcript: "olma").verdict == .excellent)
        #expect(PronunciationScoring.evaluate(target: "olma", transcript: "Olma.").verdict == .excellent)
        // Server so'zni bo'lib qaytarishi mumkin.
        #expect(PronunciationScoring.evaluate(target: "olma", transcript: "ol ma").verdict == .excellent)
        // Bola gapga qo'shib aytsa ham, so'zning o'zi topiladi.
        #expect(PronunciationScoring.evaluate(target: "olma", transcript: "men olma deyman").verdict == .excellent)
    }

    @Test func allApostropheVariantsAreEquivalent() {
        let target = "o\u{02BB}rdak"
        for heard in ["o'rdak", "o\u{2019}rdak", "o\u{2018}rdak", "o\u{02BB}rdak", "o\u{02BC}rdak"] {
            #expect(PronunciationScoring.evaluate(target: target, transcript: heard).verdict == .excellent, "\(heard)")
        }
    }

    @Test func oneWrongSoundIsAlmostAndNamesTheSound() {
        let result = PronunciationScoring.evaluate(target: "olma", transcript: "alma")
        #expect(result.verdict == .almost(sound: "o"))
        #expect(abs(result.score - 0.75) < 0.001)
        #expect(result.heard == "alma")
    }

    @Test func extraLetterIsAlmostWithoutASound() {
        let result = PronunciationScoring.evaluate(target: "olma", transcript: "olmaa")
        #expect(result.verdict == .almost(sound: nil))
        #expect(abs(result.score - 0.8) < 0.001)
    }

    @Test func missingApostropheNamesThePreviousLetter() {
        let result = PronunciationScoring.evaluate(target: "o\u{02BB}rdak", transcript: "ordak")
        #expect(result.verdict == .almost(sound: "o"))
    }

    @Test func unrelatedOrEmptyTranscriptNeedsAnotherTry() {
        let unrelated = PronunciationScoring.evaluate(target: "olma", transcript: "uy")
        #expect(unrelated.verdict == .tryAgain)
        #expect(unrelated.heard == "uy")

        let empty = PronunciationScoring.evaluate(target: "olma", transcript: "")
        #expect(empty.verdict == .tryAgain)
        #expect(empty.score == 0)
        #expect(empty.heard.isEmpty)
    }

    @Test func shortWordWithOneMistakeIsNotAlmost() {
        // "uy" -> "oy": 1 ta xato, lekin so'z 2 harfli, o'xshashlik 0.5 < 0.6.
        #expect(PronunciationScoring.evaluate(target: "uy", transcript: "oy").verdict == .tryAgain)
    }

    @Test func levenshteinDistanceIsCorrect() {
        #expect(PronunciationScoring.distance(Array("kitten"), Array("sitting")) == 3)
        #expect(PronunciationScoring.distance([], Array("abc")) == 3)
        #expect(PronunciationScoring.distance(Array("abc"), Array("abc")) == 0)
    }

    @Test func everyPracticeWordIsScoredAsExcellentWhenHeardExactly() {
        for word in PronunciationWords.all {
            #expect(PronunciationScoring.evaluate(target: word.text, transcript: word.text).verdict == .excellent, "\(word.text)")
        }
    }
}

@MainActor
@Suite("Faoliyat, sonlar va sozlamalar")
struct ActivityAndSettingsTests {

    private func makeDefaults() -> UserDefaults {
        let name = "ovozcha.tests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func streakCountsConsecutiveDaysAndSurvivesUntilTheDayEnds() {
        var current = Date(timeIntervalSince1970: 1_800_000_000)
        let store = ActivityStore(defaults: makeDefaults(), now: { current })
        #expect(store.streakDays == 0)

        store.logPractice(kind: .letter, subject: "A", stars: 3)
        current = current.addingTimeInterval(24 * 3600)
        store.logPractice(kind: .number, subject: "5", stars: 2)
        current = current.addingTimeInterval(24 * 3600)
        store.logPractice(kind: .letter, subject: "B", stars: 1)
        #expect(store.streakDays == 3)

        // Ertasi kuni hali mashq qilinmagan: seriya kun tugaguncha saqlanadi.
        current = current.addingTimeInterval(24 * 3600)
        #expect(store.streakDays == 3)

        // Yana bir kun o'tkazib yuborilsa, seriya uziladi.
        current = current.addingTimeInterval(24 * 3600)
        #expect(store.streakDays == 0)
    }

    @Test func repeatingTheSameThingUpdatesTheLastEntry() {
        let current = Date(timeIntervalSince1970: 1_800_000_000)
        let store = ActivityStore(defaults: makeDefaults(), now: { current })
        store.logPractice(kind: .letter, subject: "A", stars: 1)
        store.logPractice(kind: .letter, subject: "A", stars: 3)
        #expect(store.recent.count == 1)
        #expect(store.recent[0].stars == 3)

        store.logPractice(kind: .letter, subject: "B", stars: 2)
        #expect(store.recent.count == 2)
        #expect(store.recent[0].subject == "B")
    }

    @Test func recentListIsCappedAtTwenty() {
        let current = Date(timeIntervalSince1970: 1_800_000_000)
        let store = ActivityStore(defaults: makeDefaults(), now: { current })
        for index in 0..<30 {
            store.logPractice(kind: .number, subject: String(index), stars: 1)
        }
        #expect(store.recent.count == 20)
        #expect(store.recent[0].subject == "29")
    }

    @Test func practiceTimeAndAccuracyAreAggregated() {
        let current = Date(timeIntervalSince1970: 1_800_000_000)
        let store = ActivityStore(defaults: makeDefaults(), now: { current })
        #expect(store.pronunciationAccuracyPercent == nil)

        store.addPracticeTime(seconds: 125)
        #expect(store.todayMinutes == 2)
        // Ekran ochiq qolib ketsa, bir martalik qo'shimcha 15 daqiqadan oshmaydi.
        store.addPracticeTime(seconds: 50_000)
        #expect(store.todayMinutes == 17)

        store.logPronunciation(word: "olma", score: 0.8)
        store.logPronunciation(word: "anor", score: 1.0)
        #expect(store.pronunciationAccuracyPercent == 90)
    }

    @Test func activityPersistsAndResets() {
        let defaults = makeDefaults()
        let current = Date(timeIntervalSince1970: 1_800_000_000)
        let store = ActivityStore(defaults: defaults, now: { current })
        store.logPractice(kind: .letter, subject: "A", stars: 3)
        store.addPracticeTime(seconds: 60)

        let reloaded = ActivityStore(defaults: defaults, now: { current })
        #expect(reloaded.recent.count == 1)
        #expect(reloaded.todayMinutes == 1)
        #expect(reloaded.streakDays == 1)

        reloaded.resetAll()
        #expect(reloaded.recent.isEmpty)
        #expect(ActivityStore(defaults: defaults, now: { current }).streakDays == 0)
    }

    @Test func numberRangeFollowsTheContiguousPrefixFromOne() {
        let store = NumberProgressStore(defaults: makeDefaults())
        #expect(store.learnedRangeText == "\u{2013}")

        func record(_ value: Int, stars: Int = 2) {
            let item = UzbekNumbers.all[value - 1]
            store.record(TraceOutcome(subject: item.subject, stars: stars, isFirstSuccessInAttempt: true))
        }
        record(1)
        #expect(store.learnedRangeText == "1")
        record(2)
        record(4)
        #expect(store.learnedRangeText == "1\u{2013}2")
        record(3)
        #expect(store.learnedRangeText == "1\u{2013}4")
        #expect(store.learnedCount == 4)
        #expect(store.todayCount == 4)
    }

    @Test func numberStoreKeepsBestStarsAndIgnoresLetters() {
        let store = NumberProgressStore(defaults: makeDefaults())
        let five = UzbekNumbers.all[4]
        store.record(TraceOutcome(subject: five.subject, stars: 3, isFirstSuccessInAttempt: true))
        store.record(TraceOutcome(subject: five.subject, stars: 1, isFirstSuccessInAttempt: false))
        #expect(store.stars(for: five) == 3)

        store.record(TraceOutcome(letterID: "a", style: .upper, stars: 3, isFirstSuccessInAttempt: true))
        #expect(store.learnedCount == 1)
    }

    @Test func difficultyPersists() {
        let defaults = makeDefaults()
        let settings = SettingsStore(defaults: defaults)
        #expect(settings.writingDifficulty == .normal)
        settings.setWritingDifficulty(.easy)
        #expect(SettingsStore(defaults: defaults).writingDifficulty == .easy)
        #expect(WritingDifficulty.easy.tuning == TraceTuning.easy)
    }
}
#endif

// MARK: - Harfni tushuntiruvchi so'zlar

@Suite("Harf so'zlari")
struct LetterWordsTests {

    @Test func everyLetterHasWords() {
        for letter in UzbekAlphabet.letters {
            #expect(!LetterWords.words(for: letter.id).isEmpty, "\(letter.upper) uchun so'z yo'q")
        }
        // Noma'lum harf uchun bo'sh: ekranda bo'lim ko'rsatilmaydi.
        #expect(LetterWords.words(for: "yoq").isEmpty)
    }

    @Test func wordsAreUniqueWithinALetter() {
        for letter in UzbekAlphabet.letters {
            let texts = LetterWords.words(for: letter.id).map { $0.text }
            #expect(Set(texts).count == texts.count, "\(letter.upper) da takror so'z bor")
        }
    }

    /// `Ng` da harf so'z ichida keladi. "qoʻngʻiroq" kabi so'zlarda esa `n` va `gʻ`
    /// ALOHIDA harflar — u yerda `ng` qo'sh harfi yo'q, shuning uchun bunday so'z
    /// bu ro'yxatga tushmasligi kerak.
    @Test func ngWordsContainTheRealDigraph() throws {
        let okina = "\u{02BB}"
        for word in LetterWords.words(for: "ng") {
            let characters = PronunciationScoring.characters(word.text)
            var found = false
            for index in 0..<(characters.count - 1) {
                if characters[index] == "n" && characters[index + 1] == "g" {
                    let after = index + 2 < characters.count ? String(characters[index + 2]) : ""
                    if after != okina { found = true }
                }
            }
            #expect(found, "\(word.text) da haqiqiy 'ng' yo'q")
        }
    }

    @Test func everyWordActuallyContainsItsLetter() {
        for letter in UzbekAlphabet.letters {
            for word in LetterWords.words(for: letter.id) {
                #expect(!word.emoji.isEmpty)
                let mask = LetterWords.letterMask(word: word.text, letter: letter.lower)
                #expect(mask.contains(true), "\(word.text) ichida \(letter.lower) topilmadi")
            }
        }
    }

    @Test func maskMarksLetterAtStartAndInsideTheWord() {
        // "raketa": faqat birinchi belgi.
        #expect(LetterWords.letterMask(word: "raketa", letter: "r")
                == [true, false, false, false, false, false])
        // "arra": harf o'rtada, ikki marta ketma-ket — bola uni shu yerda ko'radi.
        #expect(LetterWords.letterMask(word: "arra", letter: "r")
                == [false, true, true, false])
        // Bosh harf ham tanilishi kerak.
        #expect(LetterWords.letterMask(word: "Rasm", letter: "r")
                == [true, false, false, false])
    }

    @Test func maskHandlesMultiCharacterLetters() {
        // "shar": "sh" bitta harf, ikkala belgisi ham belgilanadi.
        #expect(LetterWords.letterMask(word: "shar", letter: "sh")
                == [true, true, false, false])
        // Mos kelmasa, hech narsa belgilanmaydi.
        #expect(LetterWords.letterMask(word: "non", letter: "sh")
                == [false, false, false])
    }

    @Test func maskLengthAlwaysMatchesWordLength() {
        for word in LetterWords.words(for: "r") {
            let mask = LetterWords.letterMask(word: word.text, letter: "r")
            #expect(mask.count == word.text.count)
        }
    }
}
