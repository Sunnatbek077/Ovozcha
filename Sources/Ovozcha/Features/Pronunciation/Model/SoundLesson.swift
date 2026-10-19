import Foundation

/// Dars bosqichidagi bitta mashq.
struct LessonItem: Identifiable, Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        /// Yakka tovush ("rrr"): eshit va takrorla. Nutq tanish yakka tovushni ishonchli
        /// tekshira olmaydi, shuning uchun baholanmaydi — bola o'z ovozini eshitadi.
        case sound
        /// Bo'g'inlar ("ra · ro · ru"): eshit va takrorla, baholanmaydi (sabab yuqoridagidek).
        case syllables
        /// So'z: aytiladi va tekshiriladi.
        case word
        /// Quloq o'yini: to'g'ri va noto'g'ri aytilishdan to'g'risini tanlash.
        case pair
    }

    /// Butun ilova bo'yicha yagona: "r.word.rasm".
    let id: String
    let kind: Kind
    /// Ekrandagi yozuv: "rrr", "ra · ro · ru", "rasm".
    let text: String
    /// So'z va juftlik uchun rasm (emoji). Tovush va bo'g'inda bo'sh.
    let emoji: String
    /// To'g'ri aytilishi yozuvi (murabbiy ovozi).
    let modelClip: String
    /// Juftlik: noto'g'ri aytilishi ("ayya") va uning yozuvi.
    var wrongText: String = ""
    var wrongClip: String = ""
    /// So'z: nutq tanishning to'g'ri talaffuzdan qaytargan matnlari (`LetterWord.references`).
    var references: [String] = []

    /// Ovozsiz ma'nosiz mashq: quloq o'yinini yozuvsiz o'ynab bo'lmaydi.
    var requiredClips: [String] {
        switch kind {
        case .pair:
            return [modelClip, wrongClip]
        default:
            return []
        }
    }
}

/// Dars bosqichi: bir turdagi mashqlar ketma-ketligi.
struct LessonStage: Identifiable, Hashable, Sendable {
    /// "r.start"
    let id: String
    let title: String
    let subtitle: String
    let items: [LessonItem]
}

/// Bitta tovush darsi. Logopediya tartibida: tovushning o'zi -> uni farqlash (quloq) ->
/// so'z boshida -> o'rtasida -> oxirida.
///
/// Alifboning har bir harfi uchun bitta dars (`SoundLessons.all`). Yangi so'z `LetterWords` ga
/// qo'shilsa, u mos darsning mos bosqichiga o'zi tushadi.
struct SoundLesson: Identifiable, Hashable, Sendable {
    /// Alifbo kaliti (`UzbekLetter.id`): "r", "sh", "o_apos". Progress va fayl nomlari shunga bog'langan.
    let id: String
    /// Tovush (normallashtirilgan grafema): "r", "sh", "o'". Tashxis shu bilan ishlaydi.
    let sound: String
    /// Ekrandagi harf: "R", "Oʻ".
    let letter: String
    /// Kichik shakli: "r", "oʻ" — so'z ichida harfni belgilash uchun.
    let lower: String
    /// Tovushni qanday aytish (bolaga, sodda tilda).
    let hint: String
    let hintClip: String
    let stages: [LessonStage]

    var allItems: [LessonItem] {
        var result: [LessonItem] = []
        for stage in stages {
            result.append(contentsOf: stage.items)
        }
        return result
    }

    func stage(id: String) -> LessonStage? {
        for stage in stages {
            if stage.id == id { return stage }
        }
        return nil
    }
}

// MARK: - Darslar

/// Barcha tovush darslari (alifbo tartibida).
///
/// R darsi qo'lda tanlangan (birinchi, namuna dars). Qolganlari bir xil qoida bilan yasaladi:
/// - so'zlar `LetterWords` dagi barcha so'zlardan: tovush boshida / o'rtasida / oxirida
///   kelganlari, qisqalari birinchi, har bosqichda 5 tagacha; 2 tadan kam bo'lsa bosqich yo'q;
/// - quloq o'yini faqat bolalar haqiqatan adashtiradigan tovush bo'lsa (`pairSwap`);
/// - unlilarda bo'g'in bosqichi yo'q (tovushning o'zi yetarli).
///
/// Kotlin'da statik maydonlar e'lon tartibida ishga tushadi, shuning uchun bu yerda `all` dan
/// boshqa saqlanadigan statik maydon YO'Q — qolgan hammasi funksiya.
enum SoundLessons {

    static let all: [SoundLesson] = build()

    static func lesson(id: String) -> SoundLesson? {
        for lesson in all {
            if lesson.id == id { return lesson }
        }
        return nil
    }

    /// Har bosqichdagi so'zlar soni chegarasi.
    static func wordsPerStage() -> Int {
        return 5
    }

    // MARK: Yasash

    private static func build() -> [SoundLesson] {
        let pool = wordPool()
        var result: [SoundLesson] = []
        for letter in UzbekAlphabet.letters {
            if letter.id == "r" {
                result.append(makeR(letter))
            } else {
                result.append(make(letter, pool: pool))
            }
        }
        return result
    }

    /// Alifbo kaliti -> tashxisdagi tovush: "o_apos" -> "o'".
    static func sound(forLetterID id: String) -> String {
        if id == "o_apos" { return "o'" }
        if id == "g_apos" { return "g'" }
        return id
    }

    static func isVowel(_ id: String) -> Bool {
        return id == "a" || id == "e" || id == "i" || id == "o" || id == "u" || id == "o_apos"
    }

    /// Quloq o'yini: bolalar shu tovush o'rniga ko'p aytadigan tovush. `nil` — o'yin yo'q.
    ///
    /// Bu faqat eshitish mashqi (nutq tanish ishlatilmaydi), shuning uchun `oʻ`/`gʻ` ham bor —
    /// ular uchun xato nomlanmaydi (`SpeechDiagnosis.knownSwaps` ga qarang), lekin quloq bilan
    /// farqlash foydali ("oʻt" / "ot").
    static func pairSwap(forLetterID id: String) -> String? {
        switch id {
        case "l":      return "y"
        case "sh":     return "s"
        case "ch":     return "sh"
        case "j":      return "z"
        case "z":      return "s"
        case "q":      return "k"
        case "x":      return "k"
        case "f":      return "p"
        case "v":      return "b"
        case "k":      return "t"
        case "g":      return "d"
        case "ng":     return "n"
        case "g_apos": return "g"
        case "o_apos": return "o"
        default:       return nil
        }
    }

    /// Tovushning o'zi ekranda: cho'ziladigan tovushlar cho'zib ("sss"), portlovchilar
    /// takrorlab ("p-p-p").
    static func drawnSound(forLetterID id: String, lower: String) -> String {
        switch id {
        case "b", "d", "g", "k", "p", "q", "t", "j", "ch", "y", "ng":
            return lower + "-" + lower + "-" + lower
        case "sh":
            return "shhh"
        default:
            return lower + lower + lower
        }
    }

    private static func make(_ letter: UzbekLetter, pool: [PoolWord]) -> SoundLesson {
        let id = letter.id
        let sound = sound(forLetterID: id)
        let limit = wordsPerStage()

        var start: [LetterWord] = []
        var middle: [LetterWord] = []
        var end: [LetterWord] = []
        for entry in pool {
            if !entry.units.contains(sound) { continue }
            if entry.units.first == sound {
                if start.count < limit { start.append(entry.word) }
            } else if entry.units.last == sound {
                if end.count < limit { end.append(entry.word) }
            } else {
                if middle.count < limit { middle.append(entry.word) }
            }
        }

        var stages: [LessonStage] = []

        // 1. Tovush (va undoshlarda bo'g'inlar).
        var soundItems: [LessonItem] = [
            LessonItem(id: id + ".sound", kind: .sound, text: drawnSound(forLetterID: id, lower: letter.lower),
                       emoji: "", modelClip: "sound_" + id)
        ]
        if !isVowel(id) {
            // "Ng" o'zbekchada so'z boshida kelmaydi — faqat yopiq bo'g'in.
            if id != "ng" {
                soundItems.append(LessonItem(id: id + ".syl.open", kind: .syllables,
                                             text: syllables(open: true, lower: letter.lower),
                                             emoji: "", modelClip: "syl_" + id + "_open"))
            }
            soundItems.append(LessonItem(id: id + ".syl.closed", kind: .syllables,
                                         text: syllables(open: false, lower: letter.lower),
                                         emoji: "", modelClip: "syl_" + id + "_closed"))
        }
        var soundSubtitle: [String] = []
        for item in soundItems {
            soundSubtitle.append(item.text)
        }
        stages.append(LessonStage(
            id: id + ".sound",
            title: isVowel(id) ? Strings.Coach.stageSoundOnly : Strings.Coach.stageSound,
            subtitle: soundSubtitle.joined(separator: " \u{00B7} "),
            items: soundItems
        ))

        // 2. Quloq o'yini.
        if let swap = pairSwap(forLetterID: id) {
            var pairs: [LessonItem] = []
            for word in start + middle + end {
                if pairs.count >= 4 { break }
                pairs.append(pair(lesson: id, word, wrong: replacing(sound, with: swap, in: word.text)))
            }
            if pairs.count >= 2 {
                stages.append(LessonStage(id: id + ".listen", title: Strings.Coach.stageListen,
                                          subtitle: Strings.Coach.stageListenSubtitle, items: pairs))
            }
        }

        // 3-5. So'zlar.
        // 2 tadan kam so'z — bosqich emas.
        if start.count >= 2 {
            stages.append(wordStage(lesson: id, stageID: "start", title: Strings.Coach.stageStart, words: start))
        }
        if middle.count >= 2 {
            stages.append(wordStage(lesson: id, stageID: "middle", title: Strings.Coach.stageMiddle, words: middle))
        }
        if end.count >= 2 {
            stages.append(wordStage(lesson: id, stageID: "end", title: Strings.Coach.stageEnd, words: end))
        }

        return SoundLesson(
            id: id,
            sound: sound,
            letter: letter.upper,
            lower: letter.lower,
            hint: Strings.Coach.hint(forLetterID: id),
            hintClip: CoachAudio.phrase("hint_" + id),
            stages: stages
        )
    }

    // MARK: R (qo'lda tanlangan namuna dars)

    private static func makeR(_ letter: UzbekLetter) -> SoundLesson {
        return SoundLesson(
            id: "r",
            sound: "r",
            letter: letter.upper,
            lower: letter.lower,
            hint: Strings.Coach.hint(forLetterID: "r"),
            hintClip: CoachAudio.phrase("hint_r"),
            stages: [
                LessonStage(
                    id: "r.sound",
                    title: Strings.Coach.stageSound,
                    subtitle: Strings.Coach.stageSoundSubtitle,
                    items: [
                        LessonItem(id: "r.sound.rrr", kind: .sound, text: "rrr", emoji: "",
                                   modelClip: "sound_rrr"),
                        LessonItem(id: "r.syl.open", kind: .syllables, text: "ra \u{00B7} ro \u{00B7} ru", emoji: "",
                                   modelClip: "syl_ra_ro_ru"),
                        LessonItem(id: "r.syl.closed", kind: .syllables, text: "ar \u{00B7} or \u{00B7} ur", emoji: "",
                                   modelClip: "syl_ar_or_ur")
                    ]
                ),
                LessonStage(
                    id: "r.listen",
                    title: Strings.Coach.stageListen,
                    subtitle: Strings.Coach.stageListenSubtitle,
                    items: [
                        pair(lesson: "r", word("arra"), wrong: "ayya"),
                        pair(lesson: "r", word("rasm"), wrong: "lasm"),
                        pair(lesson: "r", word("robot"), wrong: "lobot"),
                        pair(lesson: "r", word("raketa"), wrong: "laketa")
                    ]
                ),
                wordStage(lesson: "r", stageID: "start", title: Strings.Coach.stageStart,
                          words: words(["rasm", "rang", "robot", "raketa", "ruchka"])),
                wordStage(lesson: "r", stageID: "middle", title: Strings.Coach.stageMiddle,
                          words: words(["arra", "tarvuz", "burun", "yurak"])),
                wordStage(lesson: "r", stageID: "end", title: Strings.Coach.stageEnd,
                          words: words(["qor", "shar", "pomidor", "sigir"]))
            ]
        )
    }

    // MARK: Yordamchilar

    /// So'z va uning tovushlari (bir marta hisoblanadi).
    struct PoolWord {
        let word: LetterWord
        let units: [String]
    }

    /// `LetterWords` dagi barcha so'zlar, takrorsiz, qisqalari birinchi (bir xil uzunlikda — alifbo).
    private static func wordPool() -> [PoolWord] {
        var seen: Set<String> = []
        var result: [PoolWord] = []
        for letter in UzbekAlphabet.letters {
            for word in LetterWords.words(for: letter.id) {
                if seen.contains(word.text) { continue }
                seen.insert(word.text)
                result.append(PoolWord(word: word, units: SpeechDiagnosis.graphemes(PronunciationScoring.normalize(word.text))))
            }
        }
        result.sort { a, b in
            if a.units.count != b.units.count { return a.units.count < b.units.count }
            return a.word.text < b.word.text
        }
        return result
    }

    /// "sa · so · su" yoki "as · os · us".
    private static func syllables(open: Bool, lower: String) -> String {
        var parts: [String] = []
        for vowel in ["a", "o", "u"] {
            parts.append(open ? lower + vowel : vowel + lower)
        }
        return parts.joined(separator: " \u{00B7} ")
    }

    /// So'zdagi tovushni boshqasiga almashtiradi (quloq o'yinidagi noto'g'ri variant): "lola" -> "yoya".
    static func replacing(_ sound: String, with swap: String, in text: String) -> String {
        var result = ""
        for unit in SpeechDiagnosis.graphemes(PronunciationScoring.normalize(text)) {
            result = result + (unit == sound ? swap : unit)
        }
        return result
    }

    /// Matn bo'yicha so'zlar (`LetterWords` da yo'g'i tashlanadi — testda tekshiriladi).
    private static func words(_ texts: [String]) -> [LetterWord] {
        var result: [LetterWord] = []
        for text in texts {
            if let found = LetterWords.word(text) {
                result.append(found)
            }
        }
        return result
    }

    private static func word(_ text: String) -> LetterWord {
        return LetterWords.word(text) ?? LetterWord(text: text, emoji: "")
    }

    private static func wordStage(lesson: String, stageID: String, title: String, words: [LetterWord]) -> LessonStage {
        var items: [LessonItem] = []
        var preview: [String] = []
        for word in words {
            items.append(LessonItem(
                id: lesson + ".word." + CoachAudio.slug(word.text),
                kind: .word,
                text: word.text,
                emoji: word.emoji,
                modelClip: CoachAudio.word(word.text),
                references: word.references
            ))
            if preview.count < 3 {
                preview.append(word.text)
            }
        }
        return LessonStage(
            id: lesson + "." + stageID,
            title: title,
            subtitle: Strings.Coach.stageWordsSubtitle(preview),
            items: items
        )
    }

    private static func pair(lesson: String, _ word: LetterWord, wrong: String) -> LessonItem {
        return LessonItem(
            id: lesson + ".pair." + CoachAudio.slug(word.text),
            kind: .pair,
            text: word.text,
            emoji: word.emoji,
            modelClip: CoachAudio.word(word.text),
            wrongText: wrong,
            wrongClip: CoachAudio.wrong(wrong)
        )
    }
}
