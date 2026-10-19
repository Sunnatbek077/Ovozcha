#if !SKIP
import Testing
import Foundation
@testable import Ovozcha

// Talaffuz murabbiyi: tovush darajasidagi tashxis va dars ma'lumotlari.

struct SpeechDiagnosisTests {

    private func diagnose(_ target: String, _ transcript: String, references: [String] = []) -> SpeechDiagnosis {
        return SpeechDiagnosis.diagnose(target: target, focus: "r", references: references, transcript: transcript)
    }

    @Test func graphemesKeepUzbekDigraphs() {
        let g = { (text: String) in SpeechDiagnosis.graphemes(PronunciationScoring.normalize(text)) }
        #expect(g("shar") == ["sh", "a", "r"])
        #expect(g("choy") == ["ch", "o", "y"])
        #expect(g("rang") == ["r", "a", "ng"])
        // n + gʻ — "ng" emas.
        #expect(g("qo\u{02BB}ng\u{02BB}iroq") == ["q", "o'", "n", "g'", "i", "r", "o", "q"])
        // Tutuq belgisi tashlanadi.
        #expect(g("ra\u{02BC}no") == ["r", "a", "n", "o"])
    }

    @Test func correctForms() {
        #expect(diagnose("rasm", "Rasm.") == .correct)
        // Kirill va qo'sh tovush: Whisper to'g'ri "arra" ni "Ара" deb yozadi.
        #expect(diagnose("arra", "Ара") == .correct)
        // Whisper belgini tushiradi: "roʻmol" -> "romol".
        #expect(diagnose("ro\u{02BB}mol", "romol") == .correct)
        // Etalon: nutq tanishning o'z xatosi bolaga yozilmaydi.
        #expect(diagnose("robot", "Lobots", references: ["Lobots"]) == .correct)
    }

    @Test func namesKnownSwapAndWhereItHappened() {
        #expect(diagnose("rasm", "lasm") == .soundSwap(sound: "r", heard: "l", position: .start, heardWord: "lasm"))
        #expect(diagnose("arra", "ayya") == .soundSwap(sound: "r", heard: "y", position: .middle, heardWord: "ayya"))
        #expect(diagnose("tarvuz", "talvuz") == .soundSwap(sound: "r", heard: "l", position: .middle, heardWord: "talvuz"))
        #expect(diagnose("qor", "qol") == .soundSwap(sound: "r", heard: "l", position: .end, heardWord: "qol"))
        #expect(diagnose("shar", "Шай") == .soundSwap(sound: "r", heard: "y", position: .end, heardWord: "shay"))
        #expect(diagnose("raketa", "Bu laketa.") == .soundSwap(sound: "r", heard: "l", position: .start, heardWord: "laketa"))
    }

    @Test func namesMissingSound() {
        #expect(diagnose("rasm", "asm") == .soundSwap(sound: "r", heard: nil, position: .start, heardWord: "asm"))
    }

    @Test func doesNotNameUnclearErrors() {
        // Xato mashq tovushida emas.
        #expect(diagnose("raketa", "raketo") == .almost(heardWord: "raketo"))
        // Bir so'zda ikki xil almashtirish.
        #expect(diagnose("arra", "alya") == .retry(heardWord: "alya"))
        // Boshqa so'z.
        #expect(diagnose("robot", "kitob") == .retry(heardWord: "kitob"))
        #expect(diagnose("rasm", " ... ") == .notHeard)
    }
}

struct SoundLessonTests {

    private func units(_ text: String) -> [String] {
        SpeechDiagnosis.graphemes(PronunciationScoring.normalize(text))
    }

    @Test func everyLetterHasALesson() {
        #expect(SoundLessons.all.count == UzbekAlphabet.letters.count)
        for letter in UzbekAlphabet.letters {
            let lesson = SoundLessons.lesson(id: letter.id)
            #expect(lesson != nil, "\(letter.upper) uchun dars yo'q")
            // Kamida tovush bosqichi va bitta so'z bosqichi.
            #expect((lesson?.stages.count ?? 0) >= 2, "\(letter.upper): bosqich kam")
        }
    }

    @Test func lessonWordsExistInLetterWords() {
        for lesson in SoundLessons.all {
            for item in lesson.allItems where item.kind == .word || item.kind == .pair {
                #expect(LetterWords.word(item.text) != nil, "\(item.text) LetterWords da yo'q")
                #expect(!item.emoji.isEmpty, "\(item.text) uchun rasm yo'q")
            }
        }
    }

    @Test func wordStagesContainTheSoundWhereTheyClaim() {
        for lesson in SoundLessons.all {
            for item in lesson.stage(id: lesson.id + ".start")?.items ?? [] {
                #expect(units(item.text).first == lesson.sound, "\(lesson.letter): \(item.text)")
            }
            for item in lesson.stage(id: lesson.id + ".middle")?.items ?? [] {
                let u = units(item.text)
                #expect(u.first != lesson.sound && u.last != lesson.sound && u.contains(lesson.sound), "\(lesson.letter): \(item.text)")
            }
            for item in lesson.stage(id: lesson.id + ".end")?.items ?? [] {
                #expect(units(item.text).last == lesson.sound, "\(lesson.letter): \(item.text)")
            }
        }
    }

    @Test func digraphsAreNotMistakenForSingleLetters() {
        // "shar" S darsida emas, "tong" N darsida emas, "gʻoz" G darsida emas.
        func words(_ id: String) -> [String] {
            (SoundLessons.lesson(id: id)?.allItems ?? []).filter { $0.kind == .word }.map { $0.text }
        }
        #expect(!words("s").contains("shar"))
        #expect(!words("n").contains("tong"))
        #expect(!words("g").contains("g\u{02BB}oz"))
    }

    @Test func pairsDifferOnlyInTheSound() {
        for lesson in SoundLessons.all {
            for item in lesson.allItems where item.kind == .pair {
                #expect(item.wrongText != PronunciationScoring.normalize(item.text), "\(item.text)")
                #expect(!item.wrongClip.isEmpty)
            }
        }
        #expect(SoundLessons.replacing("l", with: "y", in: "lola") == "yoya")
        #expect(SoundLessons.replacing("o'", with: "o", in: "o\u{02BB}t") == "ot")
    }

    @Test func itemIDsAreUnique() {
        let ids = SoundLessons.all.flatMap { $0.allItems.map { $0.id } }
        #expect(Set(ids).count == ids.count)
    }

    @Test func rLessonKeepsItsIDs() {
        // Saqlangan progress shu kalitlarga bog'langan.
        let ids = SoundLessons.lesson(id: "r")?.allItems.map { $0.id } ?? []
        #expect(ids.contains("r.sound.rrr"))
        #expect(ids.contains("r.word.rasm"))
        #expect(ids.contains("r.pair.arra"))
    }

    @Test func swapFeedbackUsesRecordedClips() {
        let line = CoachScript.feedback(
            for: .soundSwap(sound: "r", heard: "l", position: .start, heardWord: "lasm"),
            word: "rasm",
            lesson: SoundLessons.lesson(id: "r")!,
            attempt: 1
        )
        #expect(line.clips == [
            "word_rasm", "coach_pos_start", "letter_r", "coach_instead_of", "letter_l",
            "coach_i_heard", "coach_hint_r", "coach_once_more"
        ])
        #expect(line.text.hasPrefix("\u{00AB}rasm\u{00BB} so\u{02BB}zining boshida \u{00AB}r\u{00BB} o\u{02BB}rniga \u{00AB}l\u{00BB} eshitdim."))
    }

    @Test func okinaSoundsAreNeverNamedAsSwaps() {
        // Whisper belgini tushiradi — "oʻ oʻrniga o" deb bolani nohaq ayblamaymiz.
        #expect(SpeechDiagnosis.knownSwaps(for: "o'").isEmpty)
        #expect(SpeechDiagnosis.knownSwaps(for: "g'").isEmpty)
        let result = SpeechDiagnosis.diagnose(target: "o\u{02BB}t", focus: "o'", transcript: "ot")
        if case .soundSwap = result {
            Issue.record("oʻ uchun aniq xato nomlanmasligi kerak")
        }
    }
}
#endif
