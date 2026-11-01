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
    /// Shakli o'zgarmasligi shart: saqlangan progress va ovoz fayllari shu kalitga bog'langan.
    /// Shuning uchun yangi alifboda ham `Ö` kaliti hamon "o_apos", `Ş` — "sh" va hokazo.
    let id: String
    let upper: String
    let lower: String
    /// Shu harfdan boshlanadigan oddiy so'z.
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

/// Yangi o'zbek lotin alifbosi (2026-yil 21-oktabrdagi O'RQ-1184-son qonuni): 28 ta harf.
///
/// Oldingi alifbodan farqi (`UzbekOrthography` ga qarang): `Oʻ`, `Gʻ`, `Sh`, `Ch` o'rniga
/// bitta belgili harflar `Ö`, `Ğ`, `Ş`, `Ç` keldi; `Ng` alohida harf emas (ikki harf: n + g).
/// Tutuq belgisi (ʼ) harf hisoblanmaydi.
///
/// Harflar tartibi qonundagi tartib bo'yicha: ... S, Ş, Ç, T ...
///
/// Misol so'zlar ta'lim dasturi bilan solishtirilishi va o'zbek tili o'qituvchisi tomonidan
/// tasdiqlanishi kerak.
enum UzbekAlphabet {

    static let letters: [UzbekLetter] = [
        UzbekLetter(id: "a", upper: "A", lower: "a", exampleWord: "anor"),
        UzbekLetter(id: "b", upper: "B", lower: "b", exampleWord: "baliq"),
        UzbekLetter(id: "d", upper: "D", lower: "d", exampleWord: "daraxt"),
        UzbekLetter(id: "e", upper: "E", lower: "e", exampleWord: "e\u{015F}ak"),
        UzbekLetter(id: "f", upper: "F", lower: "f", exampleWord: "fil"),
        UzbekLetter(id: "g", upper: "G", lower: "g", exampleWord: "gul"),
        UzbekLetter(id: "g_apos", upper: "\u{011E}", lower: "\u{011F}", exampleWord: "\u{011F}oz"),
        UzbekLetter(id: "h", upper: "H", lower: "h", exampleWord: "hovli"),
        UzbekLetter(id: "i", upper: "I", lower: "i", exampleWord: "ilon"),
        UzbekLetter(id: "j", upper: "J", lower: "j", exampleWord: "jiraf"),
        UzbekLetter(id: "k", upper: "K", lower: "k", exampleWord: "kitob"),
        UzbekLetter(id: "l", upper: "L", lower: "l", exampleWord: "lola"),
        UzbekLetter(id: "m", upper: "M", lower: "m", exampleWord: "mu\u{015F}uk"),
        UzbekLetter(id: "n", upper: "N", lower: "n", exampleWord: "non"),
        UzbekLetter(id: "o", upper: "O", lower: "o", exampleWord: "olma"),
        UzbekLetter(id: "o_apos", upper: "\u{00D6}", lower: "\u{00F6}", exampleWord: "\u{00F6}rdak"),
        UzbekLetter(id: "p", upper: "P", lower: "p", exampleWord: "pomidor"),
        UzbekLetter(id: "q", upper: "Q", lower: "q", exampleWord: "qalam"),
        UzbekLetter(id: "r", upper: "R", lower: "r", exampleWord: "rasm"),
        UzbekLetter(id: "s", upper: "S", lower: "s", exampleWord: "soat"),
        UzbekLetter(id: "sh", upper: "\u{015E}", lower: "\u{015F}", exampleWord: "\u{015F}ar"),
        UzbekLetter(id: "ch", upper: "\u{00C7}", lower: "\u{00E7}", exampleWord: "\u{00E7}oy"),
        UzbekLetter(id: "t", upper: "T", lower: "t", exampleWord: "tulki"),
        UzbekLetter(id: "u", upper: "U", lower: "u", exampleWord: "uy"),
        UzbekLetter(id: "v", upper: "V", lower: "v", exampleWord: "velosiped"),
        UzbekLetter(id: "x", upper: "X", lower: "x", exampleWord: "xurmo"),
        UzbekLetter(id: "y", upper: "Y", lower: "y", exampleWord: "yulduz"),
        UzbekLetter(id: "z", upper: "Z", lower: "z", exampleWord: "zebra")
    ]

    static func letter(id: String) -> UzbekLetter? {
        return letters.first(where: { $0.id == id })
    }

    static func index(of id: String) -> Int? {
        return letters.firstIndex(where: { $0.id == id })
    }
}
