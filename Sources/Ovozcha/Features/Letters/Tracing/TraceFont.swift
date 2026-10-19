#if !SKIP
import SwiftUI
import CoreText

/// Iz chizish ko'rsatmasi uchun shrift.
///
/// Andika (SIL, OFL): o'qish-yozishni endi o'rganayotgan bolalar uchun yaratilgan. Bir qavatli
/// `a` va `g` (maktabda yoziladigan shakl) va o'zbek `ʻ` (U+02BB) belgisi bor. Poppins'da `ʻ` yo'q,
/// shuning uchun "Oʻ" va "Gʻ" da belgi boshqa shriftdan olinardi va shakli mos kelmasdi.
///
/// Interfeys matni (sarlavha, tugma) esa oldingidek Poppins'da qoladi.
enum TraceFont {

    static let primaryName = "Andika-Bold"
    /// Andika topilmasa (fayl qo'shilmagan bo'lsa) — ilova buzilmaydi.
    static let fallbackName = "Poppins-ExtraBold"

    /// Andika faylini modul resurslaridan ro'yxatdan o'tkazadi (bir marta).
    /// `AppFont.registerBundledFonts()` ham uni topishi mumkin; ikki marta ro'yxatdan o'tkazish zararsiz.
    static func registerIfNeeded() {
        _ = registration
    }

    private static let registration: Bool = registerBundledFile()

    private static func registerBundledFile() -> Bool {
        let bundle = Bundle.module
        let url = bundle.url(forResource: "Andika-Bold", withExtension: "ttf", subdirectory: "Fonts")
            ?? bundle.url(forResource: "Andika-Bold", withExtension: "ttf")
        guard let fontURL = url else { return false }
        var error: Unmanaged<CFError>?
        return CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
    }

    /// Core Text shrifti. Andika -> Poppins ExtraBold -> tizim shrifti tartibida.
    static func makeCTFont(size: CGFloat) -> CTFont {
        registerIfNeeded()
        for name in [primaryName, fallbackName] {
            let font = CTFontCreateWithName(name as CFString, size, nil)
            let postScript = CTFontCopyPostScriptName(font) as String
            if postScript == name {
                return font
            }
        }
        return CTFontCreateUIFontForLanguage(.system, size, nil)
            ?? CTFontCreateWithName("Helvetica-Bold" as CFString, size, nil)
    }

    /// Ro'yxat (to'r) kartalaridagi harflar uchun SwiftUI shrifti: iz ko'rsatmasi bilan bir xil shakl.
    static func swiftUIFont(size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        registerIfNeeded()
        return Font.custom(primaryName, size: size, relativeTo: style)
    }
}
#endif
