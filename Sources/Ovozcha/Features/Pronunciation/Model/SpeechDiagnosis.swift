import Foundation

/// Tovush so'zning qayerida.
enum SoundPosition: Equatable, Sendable {
    case start
    case middle
    case end
}

/// Bola aytgan so'zni TOVUSH darajasida tahlil qilish natijasi: nima o'zgargan va qayerda.
///
/// `PronunciationScoring` dan farqi: u faqat "qanchalik o'xshash" deydi. Bu esa murabbiy
/// "«rasm» so'zining boshida «r» o'rniga «l» eshitdim" deb aytishi uchun kerak.
enum SpeechDiagnosis: Equatable, Sendable {
    /// Imlo yoki etalon bilan aynan mos.
    case correct
    /// Mashq qilinayotgan tovush bolalarda ko'p uchraydigan tovushga almashgan
    /// (`heard` — nima eshitildi) yoki tushib qolgan (`heard == nil`). So'zning qolgan qismi to'g'ri.
    case soundSwap(sound: String, heard: String?, position: SoundPosition, heardWord: String)
    /// O'xshash, lekin xato boshqa joyda yoki aniq emas.
    case almost(heardWord: String)
    /// Mos kelmadi.
    case retry(heardWord: String)
    /// Hech narsa eshitilmadi.
    case notHeard
}

/// Talaffuzni tovushlarga bo'lib solishtiradi. Sof mantiq, iOS va Android (Skip) uchun umumiy.
///
/// Muhim cheklov: tahlil nutq tanish qaytargan MATN ustida ishlaydi. Whisper o'zbekcha `r` ni
/// to'g'ri aytilganda ham `l` deb yozishi mumkin (sintetik ovozda "robot" -> "Lobots").
/// Shuning uchun:
/// 1. So'zning etalonlari (`references`) bo'lsa, ular ham "to'g'ri" hisoblanadi — nutq
///    tanishning o'z xatosi bolaga yozilmaydi.
/// 2. Aniq xato faqat bolalarda haqiqatan uchraydigan almashtirish bo'lsa (`knownSwaps`) va
///    so'zning QOLGAN qismi to'g'ri bo'lsa aytiladi. Aks holda — umumiy "yana bir marta".
/// 3. Murabbiy "sen xato qilding" demaydi, "men ... eshitdim" deydi (`CoachScript`).
/// 4. `oʻ`/`o` va `gʻ`/`g` bir xil hisoblanadi (mashq tovushining o'zi bo'lmasa): Whisper
///    belgini ko'pincha tushirib qoldiradi ("roʻmol" -> "romol").
/// 5. Qo'sh tovush bitta hisoblanadi: Whisper to'g'ri aytilgan "arra" ni "Ara" deb yozadi,
///    bu "r tushib qoldi" deb chiqmasligi kerak (`collapsingDoubles`).
extension SpeechDiagnosis {

    /// Tovush -> bolalarda u o'rniga ko'p aytiladigan tovushlar.
    ///
    /// Manba: bolalar nutqining umumiy qonuniyatlari (tovushni oldinga surish, to'xtatish,
    /// jarangsizlash). O'zbek tili uchun logoped bilan tasdiqlanishi kerak. Ro'yxatga kirmagan
    /// almashtirish aniq nomlanmaydi — murabbiy faqat "yana bir marta" deydi.
    ///
    /// `oʻ` va `gʻ` ATAYLAB yo'q: Whisper to'g'ri aytilganda ham belgini tushirib, "o"/"g" deb
    /// yozadi — "oʻ o'rniga o eshitdim" desak, bolani nohaq ayblaymiz. Ular uchun faqat quloq
    /// o'yini bor (`SoundLessons.pairSwap`). Unlilar ham yo'q.
    static func knownSwaps(for sound: String) -> [String] {
        switch sound {
        // Bolalar `r` o'rniga ko'pincha `l` yoki `y` aytadi, ba'zan tomoq `g` si yoki `v`.
        case "r":  return ["l", "y", "g", "v"]
        case "l":  return ["y"]
        case "sh": return ["s"]
        case "ch": return ["sh", "s"]
        case "j":  return ["z", "d"]
        case "z":  return ["s"]
        case "q":  return ["k"]
        case "x":  return ["k"]
        case "f":  return ["p"]
        case "v":  return ["b"]
        case "k":  return ["t"]
        case "g":  return ["d"]
        case "ng": return ["n"]
        default:   return []
        }
    }

    /// `transcript` ni `target` bilan solishtiradi. `focus` — mashq qilinayotgan tovush ("r").
    static func diagnose(target: String, focus: String, references: [String] = [], transcript: String) -> SpeechDiagnosis {
        let heardText = PronunciationScoring.normalize(transcript)
        if graphemes(heardText).isEmpty || PronunciationScoring.isLikelyHallucination(transcript) {
            return .notHeard
        }

        let want = comparable(target, focus: focus)
        var accepted: [[String]] = [want]
        for reference in references {
            let form = comparable(reference, focus: focus)
            if !form.isEmpty {
                accepted.append(form)
            }
        }

        // Eng yaxshi nomzod: imloga eng o'xshash so'z.
        var bestWord = ""
        var bestUnits: [String] = []
        var bestScore = -1.0
        for candidate in PronunciationScoring.candidates(from: transcript) {
            let units = comparable(candidate, focus: focus)
            for form in accepted {
                if units == form {
                    return .correct
                }
            }
            let score = similarity(want, units)
            if score > bestScore {
                bestScore = score
                bestWord = candidate
                bestUnits = units
            }
        }

        if let swap = soundSwap(want: want, heard: bestUnits, focus: focus, heardWord: bestWord) {
            return swap
        }
        if bestScore >= PronunciationScoring.almostThreshold {
            return .almost(heardWord: bestWord)
        }
        return .retry(heardWord: bestWord)
    }

    // MARK: Tovushlarga bo'lish

    /// Normallashtirilgan so'zni o'zbek tovushlariga (harflariga) bo'ladi:
    /// "sh", "ch", "ng", "o'", "g'" — bitta birlik. Tutuq belgisi (ra'no) tashlanadi:
    /// u nutqda deyarli eshitilmaydi va nutq tanish uni yozmaydi.
    ///
    /// "qo'ng'iroq" dagi `n` + `g'` — "ng" emas (keyingi belgi apostrof).
    static func graphemes(_ normalized: String) -> [String] {
        var chars: [String] = []
        for character in normalized {
            if character != " " {
                chars.append(String(character))
            }
        }

        var result: [String] = []
        var i = 0
        while i < chars.count {
            let current = chars[i]
            let next = i + 1 < chars.count ? chars[i + 1] : ""
            let afterNext = i + 2 < chars.count ? chars[i + 2] : ""

            if (current == "o" || current == "g") && next == "'" {
                result.append(current + "'")
                i += 2
            } else if (current == "s" || current == "c") && next == "h" {
                result.append(current + "h")
                i += 2
            } else if current == "n" && next == "g" && afterNext != "'" {
                result.append("ng")
                i += 2
            } else if current == "'" {
                i += 1
            } else {
                result.append(current)
                i += 1
            }
        }
        return result
    }

    /// Solishtirish uchun shakl: tovushlar, belgisiz `oʻ`/`gʻ` (mashq tovushi bo'lmasa),
    /// qo'sh tovushlar bitta.
    static func comparable(_ text: String, focus: String) -> [String] {
        var units: [String] = []
        for unit in graphemes(PronunciationScoring.normalize(text)) {
            if unit == "o'" && focus != "o'" {
                units.append("o")
            } else if unit == "g'" && focus != "g'" {
                units.append("g")
            } else {
                units.append(unit)
            }
        }
        return collapsingDoubles(units)
    }

    /// Ketma-ket bir xil tovushlarni bittaga qisqartiradi: "arra" -> "ara".
    static func collapsingDoubles(_ units: [String]) -> [String] {
        var result: [String] = []
        for unit in units {
            if let last = result.last, last == unit {
                continue
            }
            result.append(unit)
        }
        return result
    }

    // MARK: Solishtirish

    /// Bitta farq: `target[index]` o'rniga `heard` (almashtirish), `heard == nil` (tushib qolgan)
    /// yoki `index` oldiga ortiqcha tovush qo'shilgan (`isInsertion`).
    struct Edit: Equatable {
        let index: Int
        let heard: String?
        let isInsertion: Bool
    }

    /// Ikki tovush qatorining farqlari (Levenshtein yo'li bo'yicha). Mos kelganlari kirmaydi.
    static func edits(target: [String], heard: [String]) -> [Edit] {
        let n = target.count
        let m = heard.count
        var table = [[Int]](repeating: [Int](repeating: 0, count: m + 1), count: n + 1)
        for i in 0...n { table[i][0] = i }
        for j in 0...m { table[0][j] = j }
        if n > 0 && m > 0 {
            for i in 1...n {
                for j in 1...m {
                    let cost = target[i - 1] == heard[j - 1] ? 0 : 1
                    table[i][j] = min(min(table[i - 1][j] + 1, table[i][j - 1] + 1), table[i - 1][j - 1] + cost)
                }
            }
        }

        var result: [Edit] = []
        var i = n
        var j = m
        while i > 0 || j > 0 {
            if i > 0 && j > 0 {
                let cost = target[i - 1] == heard[j - 1] ? 0 : 1
                if table[i][j] == table[i - 1][j - 1] + cost {
                    if cost == 1 {
                        result.insert(Edit(index: i - 1, heard: heard[j - 1], isInsertion: false), at: 0)
                    }
                    i -= 1
                    j -= 1
                    continue
                }
            }
            if i > 0 && table[i][j] == table[i - 1][j] + 1 {
                result.insert(Edit(index: i - 1, heard: nil, isInsertion: false), at: 0)
                i -= 1
            } else {
                result.insert(Edit(index: i, heard: heard[j - 1], isInsertion: true), at: 0)
                j -= 1
            }
        }
        return result
    }

    static func similarity(_ a: [String], _ b: [String]) -> Double {
        let longest = max(a.count, b.count)
        if longest == 0 { return 0.0 }
        return 1.0 - Double(edits(target: a, heard: b).count) / Double(longest)
    }

    /// Barcha farqlar mashq tovushida va ular ma'lum almashtirish (yoki tushib qolish) bo'lsa —
    /// aniq tashxis. Aks holda `nil`.
    private static func soundSwap(want: [String], heard: [String], focus: String, heardWord: String) -> SpeechDiagnosis? {
        let swaps = knownSwaps(for: focus)
        if swaps.isEmpty { return nil }
        let differences = edits(target: want, heard: heard)
        if differences.isEmpty { return nil }

        var substitute: String? = nil
        for edit in differences {
            if edit.isInsertion { return nil }
            if want[edit.index] != focus { return nil }
            if let sound = edit.heard {
                if !swaps.contains(sound) { return nil }
                // Bir so'zda ikki xil almashtirish ("arra" -> "alya") — aniq emas.
                if let previous = substitute, previous != sound { return nil }
                substitute = sound
            }
        }

        let first = differences[0].index
        let position: SoundPosition
        if first == 0 {
            position = .start
        } else if first == want.count - 1 {
            position = .end
        } else {
            position = .middle
        }
        return .soundSwap(sound: focus, heard: substitute, position: position, heardWord: heardWord)
    }
}
