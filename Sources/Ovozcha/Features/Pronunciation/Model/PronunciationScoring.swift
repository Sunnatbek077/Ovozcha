import Foundation

/// Bola aytgan so'zni (server qaytargan matn) kutilgan so'z bilan solishtirish natijasi.
enum PronunciationVerdict: Equatable, Sendable {
    /// Aynan to'g'ri.
    case excellent
    /// Deyarli to'g'ri. `sound`: birinchi xato qilingan tovush (bo'lsa).
    case almost(sound: String?)
    case tryAgain
}

struct PronunciationResult: Equatable, Sendable {
    /// Eshitilgan (tozalangan) matn.
    let heard: String
    /// O'xshashlik: 0...1.
    let score: Double
    let verdict: PronunciationVerdict
}

/// Talaffuzni matn asosida baholash. IOS va Android (Skip) uchun umumiy: bu sof mantiq,
/// platformaga bog'liq API ishlatmaydi.
///
/// Talaffuzni matn asosida baholash. Tovushning o'zini tahlil qilmaydi: serverdagi nutq tanish
/// matnni qaytaradi, biz uni kutilgan so'z bilan Levenshtein masofasi orqali solishtiramiz.
///
/// Cheklov: nutq tanish bolalar ovozini va o'zbekcha tovushlarni (`q`, `x`, `gʻ`, `oʻ`, `ng`)
/// yaxshi tanimasa, to'g'ri aytilgan so'z ham "deyarli to'g'ri" deb chiqishi mumkin.
enum PronunciationScoring {

    /// Shundan yuqori o'xshashlik "deyarli to'g'ri" hisoblanadi.
    static let almostThreshold = 0.6

    /// Apostrof o'rnida uchraydigan belgilar: ʻ ʼ ' ’ ‘ ` ´
    private static let apostrophes: Set<Character> = [
        "\u{02BB}", "\u{02BC}", "\u{0027}", "\u{2019}", "\u{2018}", "\u{0060}", "\u{00B4}"
    ]

    private static let digits: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

    /// Harf yoki raqammi (tinish belgisi emasmi).
    ///
    /// `Character.isLetter` va `isNumber` Skip (Android) da yo'q. O'zbek lotin (va kirill)
    /// harflarining hammasi katta/kichik shaklga ega, apostrof va tinish belgilari esa
    /// yo'q — shuning uchun harfni shu orqali ajratamiz.
    private static func isLetterOrDigit(_ character: Character) -> Bool {
        return character.isUppercase || character.isLowercase || digits.contains(character)
    }

    /// Satrni belgilar massiviga aylantiradi. `Array(String)` Skip'da yo'q.
    /// `skipSpaces` berilsa, bo'shliqlar tashlanadi.
    static func characters(_ text: String, skipSpaces: Bool = false) -> [Character] {
        var result: [Character] = []
        for character in text {
            if skipSpaces && character == " " { continue }
            result.append(character)
        }
        return result
    }

    /// Kirill -> lotin. Nutq tanish `language=uz` bilan ham ko'pincha kirill qaytaradi
    /// ("ракета", "робот", "ранг"). Usiz kirill javob lotin so'z bilan solishtirilganda
    /// o'xshashlik ~0 chiqib, TO'G'RI aytilgan so'z rad etilardi.
    ///
    /// Jadval o'zbek kirillini ham, rus kirillini ham qamraydi (Whisper ikkalasini ham qaytaradi).
    private static let cyrillicToLatin: [Character: String] = [
        "а": "a", "б": "b", "в": "v", "г": "g", "д": "d", "е": "e", "ё": "yo",
        "ж": "j", "з": "z", "и": "i", "й": "y", "к": "k", "л": "l", "м": "m",
        "н": "n", "о": "o", "п": "p", "р": "r", "с": "s", "т": "t", "у": "u",
        "ф": "f", "х": "x", "ц": "ts", "ч": "ch", "ш": "sh", "щ": "sh",
        "ъ": "'", "ы": "i", "ь": "", "э": "e", "ю": "yu", "я": "ya",
        // O'zbek kirilliga xos harflar.
        "ў": "o'", "қ": "q", "ғ": "g'", "ҳ": "h"
    ]

    /// Kichik harf, apostroflar bitta belgiga (`'`), tinish belgilari olib tashlanadi,
    /// kirill lotinga o'giriladi.
    static func normalize(_ text: String) -> String {
        var result = ""
        for character in text.lowercased() {
            if apostrophes.contains(character) {
                result = result + "'"
            } else if character.isWhitespace {
                result = result + " "
            } else if let latin = cyrillicToLatin[character] {
                result = result + latin
            } else if isLetterOrDigit(character) {
                result = result + String(character)
            }
        }
        return result
    }

    /// Whisper jimlik yoki shovqindan "o'ylab topadigan" matnlar (o'quv ma'lumotidagi video
    /// subtitrlaridan). Ular bola aytgan narsa emas — "eshitmadim" deb hisoblanadi.
    /// Asosiy himoya — yozuvning balandligi (`WordRecorder.silenceThreshold`); bu ikkinchi qatlam.
    private static let hallucinations: Set<String> = [
        "thank you", "thank you so much", "thanks for watching", "thank you for watching",
        "thanks", "you", "bye", "bye bye",
        // Kirilldan lotinga o'girilgan: "Продолжение следует...", "Спасибо за просмотр".
        "prodoljenie sleduet", "spasibo za prosmotr"
    ]

    /// Matn Whisper'ning ma'lum "xayoliy" javobimi.
    static func isLikelyHallucination(_ transcript: String) -> Bool {
        let cleaned = normalize(transcript).split(separator: " ").map { String($0) }.joined(separator: " ")
        if hallucinations.contains(cleaned) { return true }
        // "Субтитры сделал ...", "Subtitles by the Amara.org community".
        return cleaned.hasPrefix("subtitr") || cleaned.hasPrefix("subtitles")
    }

    /// Ikki qator orasidagi tahrirlash masofasi (Levenshtein).
    static func distance(_ a: [Character], _ b: [Character]) -> Int {
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var previous = Array(0...b.count)
        for i in 1...a.count {
            var current = [Int](repeating: 0, count: b.count + 1)
            current[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                // Skip'da `min` faqat ikki argument oladi.
                current[j] = min(min(previous[j] + 1, current[j - 1] + 1), previous[j - 1] + cost)
            }
            previous = current
        }
        return previous[b.count]
    }

    /// 1 - masofa / uzunroq qator uzunligi. Ikkalasi bo'sh bo'lsa 0.
    static func similarity(_ a: [Character], _ b: [Character]) -> Double {
        let longest = max(a.count, b.count)
        if longest == 0 { return 0 }
        return 1 - Double(distance(a, b)) / Double(longest)
    }

    /// Kutilgan so'zdagi birinchi xato qilingan (tushib qolgan yoki almashgan) tovush.
    static func firstMissedSound(target: [Character], heard: [Character]) -> String? {
        let n = target.count
        let m = heard.count
        if n == 0 { return nil }

        var table = [[Int]](repeating: [Int](repeating: 0, count: m + 1), count: n + 1)
        for i in 0...n { table[i][0] = i }
        for j in 0...m { table[0][j] = j }
        if m > 0 {
            for i in 1...n {
                for j in 1...m {
                    let cost = target[i - 1] == heard[j - 1] ? 0 : 1
                    table[i][j] = min(min(table[i - 1][j] + 1, table[i][j - 1] + 1), table[i - 1][j - 1] + cost)
                }
            }
        }

        // Orqaga yurib, eng erta xato indeksini topamiz.
        var i = n
        var j = m
        var firstMiss: Int?
        while i > 0 || j > 0 {
            if i > 0 && j > 0 && table[i][j] == table[i - 1][j - 1] + (target[i - 1] == heard[j - 1] ? 0 : 1) {
                if target[i - 1] != heard[j - 1] { firstMiss = i - 1 }
                i -= 1
                j -= 1
            } else if i > 0 && table[i][j] == table[i - 1][j] + 1 {
                firstMiss = i - 1
                i -= 1
            } else {
                j -= 1
            }
        }

        guard var index = firstMiss else { return nil }
        // Apostrof alohida tovush emas: uni tushirib qoldirsa, oldingi harfni ("o", "g") ko'rsatamiz.
        if target[index] == "'" && index > 0 {
            index -= 1
        }
        return String(target[index])
    }

    /// Server matnidagi nomzodlar: har bir so'z va hammasi birlashtirilgani ("ol ma" -> "olma").
    static func candidates(from transcript: String) -> [String] {
        let words = normalize(transcript).split(separator: " ").map { String($0) }
        if words.isEmpty { return [] }
        var result = words
        if words.count > 1 {
            result.append(words.joined())
        }
        return result
    }

    /// `references`: to'g'ri aytilgan namunani nutq tanish qanday matn qilib qaytargani
    /// (`LetterWord.references`). Berilsa, bola matni imlo bilan ham, namunalar bilan ham
    /// solishtiriladi va eng yaxshisi olinadi — shunda nutq tanishning o'z xatosi
    /// bolaning xatosi deb hisoblanmaydi.
    static func evaluate(target: String, references: [String] = [], transcript: String) -> PronunciationResult {
        let want = characters(normalize(target), skipSpaces: true)

        // Qabul qilinadigan shakllar: imlo + namunalar.
        var accepted: [[Character]] = [want]
        for reference in references {
            let form = characters(normalize(reference), skipSpaces: true)
            if !form.isEmpty {
                accepted.append(form)
            }
        }

        var bestScore = 0.0
        var bestHeard = ""
        for candidate in candidates(from: transcript) {
            let heard = characters(candidate)
            for form in accepted {
                let score = similarity(form, heard)
                if score > bestScore {
                    bestScore = score
                    bestHeard = candidate
                }
            }
        }

        let verdict: PronunciationVerdict
        if bestScore >= 1 {
            verdict = .excellent
        } else if bestScore >= almostThreshold {
            verdict = .almost(sound: firstMissedSound(target: want, heard: characters(bestHeard)))
        } else {
            verdict = .tryAgain
        }
        let shown = bestHeard.isEmpty ? normalize(transcript) : bestHeard
        return PronunciationResult(heard: shown, score: bestScore, verdict: verdict)
    }
}
