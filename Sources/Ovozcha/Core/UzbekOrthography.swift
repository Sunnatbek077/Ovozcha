import Foundation

/// Yangi o'zbek lotin alifbosi bilan eski yozuv orasidagi moslik.
///
/// 2026-yil 21-oktabrdagi O'RQ-1184-son qonuni bo'yicha alifbo 28 ta harf va tutuq belgisidan
/// iborat; to'rt harf birikmasi (yoki belgili harf) bitta harfga almashtirildi:
///
/// | Eski | Yangi |
/// |------|-------|
/// | Oʻ oʻ | Ö ö |
/// | Gʻ gʻ | Ğ ğ |
/// | Sh sh | Ş ş |
/// | Ch ch | Ç ç |
///
/// `Ng` endi alohida harf emas: u ikki harf ("n" + "g") bo'lib yoziladi.
/// Tutuq belgisi (raʼno, eʼlon) o'zgarmadi: U+02BC (ʼ).
///
/// Ilovaning ichki mantiqi (talaffuz tahlili, lug'at qidiruvi, ovoz fayllari nomi) hamon
/// "normallashtirilgan" shaklda ishlaydi: `o'`, `g'`, `sh`, `ch` (`PronunciationScoring.normalize`
/// yangi harflarni shunga keltiradi). Shu sababli ovoz fayllari nomi va saqlangan progress
/// o'zgarmadi. Bu enum esa teskari tomonga xizmat qiladi: eski yozuvdagi matnni (nutq tanish
/// natijasi, eski lug'at, saqlangan tarix) ekranda yangi harflar bilan ko'rsatadi.
///
/// Skip (Android) uchun: faqat oddiy `Character` va `String` amallari ishlatilgan.
enum UzbekOrthography {

    /// Eski yozuvda `o` va `g` dan keyin keladigan apostrof o'rnidagi belgilar: ʻ ʼ ' ’ ‘ ` ´
    private static let apostrophes: Set<Character> = [
        "\u{02BB}", "\u{02BC}", "\u{0027}", "\u{2019}", "\u{2018}", "\u{0060}", "\u{00B4}"
    ]

    /// Eski yozuvdagi matnni yangi alifboga o'giradi: "oʻrdak" -> "ördak", "shahar" -> "şahar",
    /// "Choy" -> "Çoy". Yangi yozuvdagi matn o'zgarmaydi (ikki marta chaqirish zararsiz).
    ///
    /// Bitta tutuq belgisi (raʼno) tegmaydi: u faqat `o`/`g` dan keyin kelganda `ö`/`ğ` bo'ladi.
    static func modern(_ text: String) -> String {
        var chars: [Character] = []
        for character in text {
            chars.append(character)
        }

        var result = ""
        var i = 0
        while i < chars.count {
            let current = chars[i]
            let next: Character = i + 1 < chars.count ? chars[i + 1] : " "
            let low = String(current).lowercased()
            let nextLow = String(next).lowercased()

            if (low == "o" || low == "g") && apostrophes.contains(next) {
                if low == "o" {
                    result = result + (current.isUppercase ? "\u{00D6}" : "\u{00F6}")
                } else {
                    result = result + (current.isUppercase ? "\u{011E}" : "\u{011F}")
                }
                i += 2
            } else if (low == "s" || low == "c") && nextLow == "h" {
                if low == "s" {
                    result = result + (current.isUppercase ? "\u{015E}" : "\u{015F}")
                } else {
                    result = result + (current.isUppercase ? "\u{00C7}" : "\u{00E7}")
                }
                i += 2
            } else {
                result = result + String(current)
                i += 1
            }
        }
        return result
    }
}
