import Foundation

/// Imlo lug'atidagi bitta so'z.
struct SpellingEntry: Identifiable, Hashable, Sendable {
    /// To'g'ri yozilishi: "toʻgʻri", "abadiylashtirilmoq".
    let word: String
    /// Qidiruv kaliti: kichik harf, apostrof/chiziqchasiz, lotin — "togri".
    let key: String
    var id: String { return word }
}

/// Lug'atni o'qish va unda qidirish. Sof mantiq, iOS va Android (Skip) uchun umumiy.
///
/// Manba — Hunspell formatidagi `.dic` fayl: birinchi qatorda so'zlar soni, keyin
/// `so'z/BELGILAR`. Belgilar (flag) qo'shimchalarni bildiradi; bizga faqat bittasi kerak:
/// `X` — fe'l o'zagi. Lug'atda fe'l "-moq" shaklida beriladi (`uz_UZ.aff`: `SFX X 0 moq`),
/// shuning uchun "abadiylashtiril/X" -> "abadiylashtirilmoq".
enum SpellingIndex {

    /// Ro'yxatda ko'rsatiladigan eng ko'p natija.
    static let resultLimit = 60
    /// Prefiks bo'yicha shuncha nomzod yig'ilib, keyin qisqasi birinchi qilib saralanadi.
    static let candidateLimit = 400
    static let suggestionLimit = 8

    // MARK: O'qish

    /// `.dic` matnidan saralangan (kalit bo'yicha) ro'yxat. Takrorlar tashlanadi.
    ///
    /// Takrorlar `Set` bilan EMAS, saralashdan keyin tashlanadi: Skip'da `Set.insert` Android'da
    /// chiziqli qidiradi (`indexOf`), 95 000 so'zda bu O(n²) — tahlil daqiqalab cho'zilardi.
    /// Bir xil so'zning kaliti ham bir xil, shuning uchun saralangandan keyin ular yonma-yon turadi.
    static func parse(_ text: String) -> [SpellingEntry] {
        var entries: [SpellingEntry] = []
        var isFirstLine = true
        for rawLine in text.components(separatedBy: "\n") {
            if isFirstLine {
                // So'zlar soni.
                isFirstLine = false
                continue
            }
            // Ba'zi qatorlarda flagdan keyin tab bilan morfologik izoh bo'lishi mumkin.
            let line = rawLine.components(separatedBy: "\t")[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }

            let parts = line.components(separatedBy: "/")
            var word = parts[0]
            let flags = parts.count > 1 ? parts[1] : ""
            if word.isEmpty { continue }
            if flags.contains("X") {
                word = word + "moq"
            }
            entries.append(SpellingEntry(word: word, key: key(word)))
        }
        entries.sort { a, b in
            if a.key != b.key { return a.key < b.key }
            return a.word < b.word
        }
        // Oldingi so'z alohida o'zgaruvchida: sikl ichida massivdan o'qish (`unique.last`)
        // Android'da har qadamda qimmatga tushdi (stekda `Array.getLast` da turib qolgan).
        var unique: [SpellingEntry] = []
        var previousWord = ""
        for entry in entries {
            if entry.word == previousWord {
                continue
            }
            previousWord = entry.word
            unique.append(entry)
        }
        return unique
    }

    /// Qidiruv kaliti: "Toʻgʻri" / "to'g'ri" / "тўғри" / "togri" -> "togri".
    static func key(_ text: String) -> String {
        var result = ""
        for character in PronunciationScoring.normalize(text) {
            if character == "'" || character == " " { continue }
            result = result + String(character)
        }
        return result
    }

    // MARK: Qidirish

    /// Kaliti so'rov bilan boshlanadigan so'zlar: to'liq mos birinchi, keyin qisqalari.
    static func search(_ query: String, in entries: [SpellingEntry]) -> [SpellingEntry] {
        let wanted = key(query)
        if wanted.isEmpty || entries.isEmpty { return [] }

        var index = lowerBound(wanted, in: entries)
        var candidates: [SpellingEntry] = []
        while index < entries.count && candidates.count < candidateLimit {
            let entry = entries[index]
            if !entry.key.hasPrefix(wanted) { break }
            candidates.append(entry)
            index += 1
        }
        candidates.sort { a, b in
            if a.key.count != b.key.count { return a.key.count < b.key.count }
            return a.word < b.word
        }
        if candidates.count > resultLimit {
            var trimmed: [SpellingEntry] = []
            for i in 0..<resultLimit {
                trimmed.append(candidates[i])
            }
            return trimmed
        }
        return candidates
    }

    /// Hech narsa topilmasa: yozilishi eng yaqin so'zlar ("kitop" -> "kitob").
    /// Birinchi harfi bir xil va uzunligi yaqinlarigina solishtiriladi — tez bo'lishi uchun.
    static func suggestions(_ query: String, in entries: [SpellingEntry]) -> [SpellingEntry] {
        let wanted = key(query)
        if wanted.count < 2 || entries.isEmpty { return [] }
        let wantedChars = PronunciationScoring.characters(wanted)
        let first = String(wantedChars[0])
        let maxDistance = wanted.count <= 4 ? 1 : 2

        var start = lowerBound(first, in: entries)
        var scored: [Scored] = []
        while start < entries.count {
            let entry = entries[start]
            if !entry.key.hasPrefix(first) { break }
            start += 1
            if abs(entry.key.count - wanted.count) > maxDistance { continue }
            let distance = PronunciationScoring.distance(wantedChars, PronunciationScoring.characters(entry.key))
            if distance <= maxDistance {
                scored.append(Scored(entry: entry, distance: distance))
            }
        }
        // Yaqinroq -> uzunligi bir xil -> oddiy so'z (atoqli otdan oldin) -> alifbo.
        let length = wanted.count
        scored.sort { a, b in
            if a.distance != b.distance { return a.distance < b.distance }
            let aLength = abs(a.entry.key.count - length)
            let bLength = abs(b.entry.key.count - length)
            if aLength != bLength { return aLength < bLength }
            let aProper = isProperNoun(a.entry.word)
            let bProper = isProperNoun(b.entry.word)
            if aProper != bProper { return !aProper }
            return a.entry.word < b.entry.word
        }
        var result: [SpellingEntry] = []
        for item in scored {
            if result.count >= suggestionLimit { break }
            result.append(item.entry)
        }
        return result
    }

    private static func isProperNoun(_ word: String) -> Bool {
        guard let first = word.first else { return false }
        return first.isUppercase
    }

    // MARK: Kesh

    /// Tayyor indeks (keshga yoziladi): har qatorda `kalit<TAB>so'z`, kalit bo'yicha saralangan.
    /// Qayta ochilganda `.dic` ni qayta tahlil qilish (normallashtirish va saralash) kerak emas —
    /// Android'da bu eng qimmat qism.
    static func serialize(_ entries: [SpellingEntry]) -> String {
        var lines: [String] = []
        for entry in entries {
            lines.append(entry.key + "\t" + entry.word)
        }
        return lines.joined(separator: "\n")
    }

    static func deserialize(_ text: String) -> [SpellingEntry] {
        var entries: [SpellingEntry] = []
        for line in text.components(separatedBy: "\n") {
            let parts = line.components(separatedBy: "\t")
            if parts.count == 2 && !parts[1].isEmpty {
                entries.append(SpellingEntry(word: parts[1], key: parts[0]))
            }
        }
        return entries
    }

    private struct Scored {
        let entry: SpellingEntry
        let distance: Int
    }

    /// Yozilgani lug'atdagi so'zning o'zimi (apostrof turi farq qilmaydi: o' = oʻ).
    static func isExactSpelling(_ query: String, of entry: SpellingEntry) -> Bool {
        let typed = PronunciationScoring.normalize(query).trimmingCharacters(in: .whitespaces)
        return !typed.isEmpty && typed == PronunciationScoring.normalize(entry.word)
    }

    /// Kaliti `key` dan kichik bo'lmagan birinchi yozuv (ikkilik qidiruv).
    private static func lowerBound(_ key: String, in entries: [SpellingEntry]) -> Int {
        var low = 0
        var high = entries.count
        while low < high {
            let middle = (low + high) / 2
            if entries[middle].key < key {
                low = middle + 1
            } else {
                high = middle
            }
        }
        return low
    }
}
