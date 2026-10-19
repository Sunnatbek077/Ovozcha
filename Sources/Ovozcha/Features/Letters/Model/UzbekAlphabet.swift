import Foundation

// MARK: - Harf shakli

/// Harfning ikki shakli: bosh (katta) va kichik.
enum LetterCase: String, CaseIterable, Identifiable, Codable, Sendable {
    case upper
    case lower

    var id: String { rawValue }

    var title: String {
        switch self {
        case .upper: return Strings.Letters.caseUpper
        case .lower: return Strings.Letters.caseLower
        }
    }
}

// MARK: - Harf

/// O'zbek lotin alifbosidagi bitta harf.
struct UzbekLetter: Identifiable, Hashable, Sendable {

    /// Barqaror kalit (progress saqlash va audio fayl nomi uchun). Faqat ASCII: "a", "o_apos", "sh".
    /// Shakli o'zgarmasligi shart: saqlangan progress shu kalitga bog'langan.
    let id: String
    let upper: String
    let lower: String
    /// Shu harfdan boshlanadigan (yoki "Ng" uchun o'z ichiga olgan) oddiy so'z.
    let exampleWord: String

    func text(for style: LetterCase) -> String {
        switch style {
        case .upper: return upper
        case .lower: return lower
        }
    }

    /// Bu harf tovushi yozilgan audio fayl nomi (kengaytmasiz): `letter_a`, `letter_o_apos` ...
    var audioFileName: String { "letter_" + id }
}

// MARK: - Alifbo

/// O'zbek lotin alifbosi (29 ta harf; Sh, Ch, Ng alohida harf hisoblanadi).
///
/// "Oʻ" va "Gʻ" dagi belgi U+02BB (ʻ, "okina"). Manba kodida ko'rinmas belgi bilan adashmaslik
/// uchun u ochiq `\u{02BB}` ko'rinishida yozilgan.
///
/// Misol so'zlar ta'lim dasturi bilan solishtirilishi va o'zbek tili o'qituvchisi tomonidan
/// tasdiqlanishi kerak.
enum UzbekAlphabet {

    private static let tutuq = "\u{02BB}"

    static let letters: [UzbekLetter] = [
        UzbekLetter(id: "a", upper: "A", lower: "a", exampleWord: "anor"),
        UzbekLetter(id: "b", upper: "B", lower: "b", exampleWord: "baliq"),
        UzbekLetter(id: "d", upper: "D", lower: "d", exampleWord: "daraxt"),
        UzbekLetter(id: "e", upper: "E", lower: "e", exampleWord: "eshak"),
        UzbekLetter(id: "f", upper: "F", lower: "f", exampleWord: "fil"),
        UzbekLetter(id: "g", upper: "G", lower: "g", exampleWord: "gul"),
        UzbekLetter(id: "h", upper: "H", lower: "h", exampleWord: "hovli"),
        UzbekLetter(id: "i", upper: "I", lower: "i", exampleWord: "ilon"),
        UzbekLetter(id: "j", upper: "J", lower: "j", exampleWord: "jiraf"),
        UzbekLetter(id: "k", upper: "K", lower: "k", exampleWord: "kitob"),
        UzbekLetter(id: "l", upper: "L", lower: "l", exampleWord: "lola"),
        UzbekLetter(id: "m", upper: "M", lower: "m", exampleWord: "mushuk"),
        UzbekLetter(id: "n", upper: "N", lower: "n", exampleWord: "non"),
        UzbekLetter(id: "o", upper: "O", lower: "o", exampleWord: "olma"),
        UzbekLetter(id: "p", upper: "P", lower: "p", exampleWord: "pomidor"),
        UzbekLetter(id: "q", upper: "Q", lower: "q", exampleWord: "qalam"),
        UzbekLetter(id: "r", upper: "R", lower: "r", exampleWord: "rasm"),
        UzbekLetter(id: "s", upper: "S", lower: "s", exampleWord: "soat"),
        UzbekLetter(id: "t", upper: "T", lower: "t", exampleWord: "tulki"),
        UzbekLetter(id: "u", upper: "U", lower: "u", exampleWord: "uy"),
        UzbekLetter(id: "v", upper: "V", lower: "v", exampleWord: "velosiped"),
        UzbekLetter(id: "x", upper: "X", lower: "x", exampleWord: "xurmo"),
        UzbekLetter(id: "y", upper: "Y", lower: "y", exampleWord: "yulduz"),
        UzbekLetter(id: "z", upper: "Z", lower: "z", exampleWord: "zebra"),
        UzbekLetter(id: "o_apos", upper: "O" + tutuq, lower: "o" + tutuq, exampleWord: "o" + tutuq + "rdak"),
        UzbekLetter(id: "g_apos", upper: "G" + tutuq, lower: "g" + tutuq, exampleWord: "g" + tutuq + "oz"),
        UzbekLetter(id: "sh", upper: "Sh", lower: "sh", exampleWord: "shar"),
        UzbekLetter(id: "ch", upper: "Ch", lower: "ch", exampleWord: "choy"),
        UzbekLetter(id: "ng", upper: "Ng", lower: "ng", exampleWord: "tong")
    ]

    static func letter(id: String) -> UzbekLetter? {
        return letters.first(where: { $0.id == id })
    }

    static func index(of id: String) -> Int? {
        return letters.firstIndex(where: { $0.id == id })
    }
}
