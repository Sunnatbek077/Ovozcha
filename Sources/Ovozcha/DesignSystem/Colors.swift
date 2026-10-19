import SwiftUI

// MARK: - Ranglar
//
// Manba: PDF "Dizayn tizimi" + maketdan o'lchangan piksel qiymatlari.
// Qoida: matn va ikonka uchun faqat "Strong" variantlar ishlatiladi
// (Apple HIG / WCAG AA: kamida 4.5:1). Asl brend ranglari esa fon, tugma va
// bezak uchun qoladi.
//
//   Asl rang      -> oq fonda  | Strong variant -> oq fonda
//   Sky    5AC8FA -> 1.90:1    | 0576A9         -> 5.04:1
//   Green  4CD787 -> 1.85:1    | 1C7F46         -> 5.03:1
//   Purple 8B72C4 -> 3.96:1    | 7659B9         -> 5.38:1
//
// Skip eslatmasi: boshqa modulda (SwiftUI) aniqlangan `Color` tipiga extension orqali
// `static let` (saqlanadigan qiymat) va `init` qo'shib bo'lmaydi. Faqat `static var`
// (hisoblanadigan qiymat) va `static func` mumkin, shuning uchun shunday yozilgan.

extension Color {

    /// 0xRRGGBB formatidagi qiymatdan rang yaratadi (sRGB).
    /// Oldingi `Color(hex:)` o'rniga: `Color.ovHex(0xFFD23F)`.
    static func ovHex(_ hex: Int, opacity: Double = 1) -> Color {
        let red   = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue  = Double(hex & 0xFF) / 255
        return Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    // MARK: Brend ranglari (PDF)

    static var ovSky: Color        { ovHex(0x5AC8FA) }
    static var ovPurple: Color     { ovHex(0x8B72C4) }
    static var ovGreen: Color      { ovHex(0x4CD787) }
    static var ovYellow: Color     { ovHex(0xFFD23F) }
    static var ovInk: Color        { ovHex(0x1F2A44) }
    static var ovBackground: Color { ovHex(0xFDF6EF) }

    // MARK: Matn/ikonka uchun to'qroq variantlar (tus saqlangan, faqat yorqinlik kamaytirilgan)

    static var ovSkyStrong: Color    { ovHex(0x0576A9) }
    static var ovGreenStrong: Color  { ovHex(0x1C7F46) }
    static var ovPurpleStrong: Color { ovHex(0x7659B9) }

    // MARK: Sirt va matn (maketdan o'lchangan)

    /// Karta foni.
    static var ovSurface: Color       { Color.white }
    /// Ikkilamchi matn (fonda 5.5:1).
    static var ovTextSecondary: Color { ovHex(0x5B6478) }
    /// Karta chegarasi (iliq bej).
    static var ovBorder: Color        { ovHex(0xF0E2CF) }
    /// Mukofot kartasi foni. Maketda matn oq edi (1.9:1, o'qish qiyin),
    /// shuning uchun bu yerda matn Ink rangida (7.4:1).
    static var ovRewardFill: Color    { ovHex(0xE8B400) }
}
