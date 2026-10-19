import Foundation

/// 1 dan 10 gacha bitta son.
struct NumberItem: Identifiable, Hashable, Sendable {
    let value: Int
    /// O'zbekcha nomi ("besh").
    let word: String

    /// Barqaror kalit (progress uchun): "5".
    var id: String { String(value) }
    /// Ekranda chiziladigan matn.
    var text: String { String(value) }
    /// Ovoz fayli nomi (kengaytmasiz): `number_5`.
    var audioFileName: String { "number_" + String(value) }

    var subject: TraceSubject {
        return TraceSubject(id: id, text: text, kind: TraceKind.digit, letterCase: nil)
    }
}

enum UzbekNumbers {

    /// "toʻrt", "toʻqqiz", "oʻn" dagi belgi U+02BB (ʻ), ochiq yozilgan.
    private static let tutuq = "\u{02BB}"

    static let all: [NumberItem] = [
        NumberItem(value: 1, word: "bir"),
        NumberItem(value: 2, word: "ikki"),
        NumberItem(value: 3, word: "uch"),
        NumberItem(value: 4, word: "to" + tutuq + "rt"),
        NumberItem(value: 5, word: "besh"),
        NumberItem(value: 6, word: "olti"),
        NumberItem(value: 7, word: "yetti"),
        NumberItem(value: 8, word: "sakkiz"),
        NumberItem(value: 9, word: "to" + tutuq + "qqiz"),
        NumberItem(value: 10, word: "o" + tutuq + "n")
    ]

    static func item(id: String) -> NumberItem? {
        return all.first(where: { $0.id == id })
    }

    static func index(of value: Int) -> Int? {
        return all.firstIndex(where: { $0.value == value })
    }
}
