import Foundation

/// Nimani chizyapmiz: harf yoki raqam. Joylashuv va baholash sozlamalari shunga qarab tanlanadi.
enum TraceKind: Sendable, Hashable {
    case letter
    case digit
}

/// Iz chiziladigan bitta narsa (masalan "B", "b" yoki "5").
/// Harflar ham, raqamlar ham bir xil iz chizish mexanizmidan foydalanadi.
struct TraceSubject: Equatable, Hashable, Sendable {
    /// Barqaror kalit: harf uchun "a", "o_apos"; raqam uchun "5".
    let id: String
    /// Ekranda chiziladigan matn: "B", "sh", "10".
    let text: String
    let kind: TraceKind
    /// Faqat harflar uchun: bosh yoki kichik shakl.
    let letterCase: LetterCase?
}

extension UzbekLetter {
    func subject(for style: LetterCase) -> TraceSubject {
        return TraceSubject(id: id, text: text(for: style), kind: TraceKind.letter, letterCase: style)
    }
}
