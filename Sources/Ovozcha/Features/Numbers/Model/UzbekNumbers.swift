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

    var subject: TraceSubject {
        return TraceSubject(id: id, text: text, kind: TraceKind.digit, letterCase: nil)
    }
}

enum UzbekNumbers {

    /// Sonlar yangi alifboda: "tört", "töqqiz", "ön", "beş", "uç" (Ö, Ş, Ç — ochiq yozilgan).
    static let all: [NumberItem] = [
        NumberItem(value: 1, word: "bir"),
        NumberItem(value: 2, word: "ikki"),
        NumberItem(value: 3, word: "u\u{00E7}"),
        NumberItem(value: 4, word: "t\u{00F6}rt"),
        NumberItem(value: 5, word: "be\u{015F}"),
        NumberItem(value: 6, word: "olti"),
        NumberItem(value: 7, word: "yetti"),
        NumberItem(value: 8, word: "sakkiz"),
        NumberItem(value: 9, word: "t\u{00F6}qqiz"),
        NumberItem(value: 10, word: "\u{00F6}n")
    ]

    static func item(id: String) -> NumberItem? {
        return all.first(where: { $0.id == id })
    }

    static func index(of value: Int) -> Int? {
        return all.firstIndex(where: { $0.value == value })
    }
}
