import SwiftUI

// UIKit va CoreText Skip (Android) da mavjud emas,
// shuning uchun faqat iOS/macOS uchun.
#if !SKIP
import CoreText
// UIKit faqat iOS'da bor. macOS'da (testlar shu yerda ishlaydi) u yo'q,
// shuning uchun shartli import — usiz test target'i umuman qurilmaydi.
#if canImport(UIKit)
import UIKit
#endif
#endif

// MARK: - Shrift vaznlari

/// Poppins (OFL litsenziya).
/// PostScript nomlari .ttf fayllardagi nomlarga mos.
enum PoppinsWeight: String {

    case regular   = "Poppins-Regular"
    case medium    = "Poppins-Medium"
    case semibold  = "Poppins-SemiBold"
    case bold      = "Poppins-Bold"
    case extrabold = "Poppins-ExtraBold"

    var postScriptName: String {
        rawValue
    }

    /// Android (Skip):
    /// Shrift fayli `Android/app/src/main/res/font/` ichida
    /// kichik harf va pastki chiziq bilan nomlanadi.
    ///
    /// Masalan:
    /// `poppins_bold.ttf`
    var androidFontName: String {
        switch self {
        case .regular:
            return "poppins_regular"

        case .medium:
            return "poppins_medium"

        case .semibold:
            return "poppins_semibold"

        case .bold:
            return "poppins_bold"

        case .extrabold:
            return "poppins_extrabold"
        }
    }

    /// Shrift topilmasa, tizimning yumaloq shriftida
    /// shu vazn ishlatiladi.
    var systemWeight: Font.Weight {
        switch self {
        case .regular:
            return .regular

        case .medium:
            return .medium

        case .semibold:
            return .semibold

        case .bold:
            return .bold

        case .extrabold:
            return .heavy
        }
    }
}

// MARK: - Matn uslublari

/// Har bir uslub Apple'ning Dynamic Type stiliga bog'langan (`relativeTo`).
///
/// iOS/macOS'da foydalanuvchi tizim sozlamasida matnni
/// kattalashtirsa, ilova ham mos ravishda kattalashadi.
///
/// Skip/Android'da esa `relativeTo` ishlatilmaydi.
enum OvTextStyle {

    case display       // bosh ekrandagi ism, katta sarlavha
    case title         // ekran ichidagi sarlavha
    case title3        // mukofot kartasi matni
    case headline      // karta sarlavhasi, navigatsiya sarlavhasi
    case body
    case subheadline   // karta izohi
    case caption
    case badge         // OFFLINE / ONLINE
    case overline      // "SALOM,", "BUGUNGI YUTUQ"
    case tabLabel      // pastki tab panelidagi yozuv (Material 3: 12sp)

    var size: CGFloat {
        switch self {
        case .display:
            return 32

        case .title:
            return 22

        case .title3:
            return 20

        case .headline:
            return 18

        case .body:
            return 16

        case .subheadline:
            return 14

        case .caption:
            return 13

        case .badge:
            return 12

        case .overline:
            return 13

        case .tabLabel:
            return 12
        }
    }

    var weight: PoppinsWeight {
        switch self {
        case .display,
             .title,
             .title3,
             .headline,
             .badge:
            return .bold

        case .overline:
            return .semibold

        case .caption,
             .tabLabel:
            return .medium

        case .body,
             .subheadline:
            return .regular
        }
    }

    var relativeTo: Font.TextStyle {
        switch self {
        case .display:
            return .largeTitle

        case .title:
            return .title2

        case .title3:
            return .title3

        case .headline:
            return .headline

        case .body:
            return .body

        case .subheadline:
            return .subheadline

        case .caption:
            return .caption

        case .badge:
            return .caption2

        case .overline:
            return .caption

        case .tabLabel:
            return .caption2
        }
    }

    var tracking: CGFloat {
        switch self {
        case .overline:
            return 1.0

        case .badge:
            return 0.8

        default:
            return 0
        }
    }

    var isUppercase: Bool {
        self == .overline || self == .badge
    }
}

// MARK: - AppFont

enum AppFont {

    /// `OvTextStyle` uchun SwiftUI shrifti.
    ///
    /// iOS/macOS:
    /// - Poppins mavjud bo'lsa, undan foydalanadi.
    /// - `relativeTo` orqali Dynamic Type ishlaydi.
    /// - Poppins topilmasa, SF Rounded fallback ishlatiladi.
    ///
    /// Android / Skip:
    /// - `relativeTo` ISHLATILMAYDI.
    /// - Aks holda SkipUI o'lchamni qo'shimcha ravishda
    ///   o'zgartirishi mumkin.
    static func font(for style: OvTextStyle) -> Font {

        let name = style.weight.postScriptName

        #if SKIP

        // MARK: Android / Skip

        // relativeTo ishlatilmaydi.
        // SkipUI uni qo'shimcha o'lcham sifatida qo'llashi mumkin.
        return Font.custom(
            style.weight.androidFontName,
            size: style.size
        )

        #else

        // MARK: iOS / macOS

        #if canImport(UIKit)

        // Poppins mavjudligini tekshirish.
        if UIFont(name: name, size: style.size) != nil {

            return .custom(
                name,
                size: style.size,
                relativeTo: style.relativeTo
            )
        }

        // Poppins topilmasa, SF Rounded fallback.
        return .system(
            style.relativeTo,
            design: .rounded
        )
        .weight(style.weight.systemWeight)

        #else

        // macOS: shrift bor-yo'qligini UIKit'siz tekshirib bo'lmaydi.
        // SwiftUI shrift topilmasa o'zi tizim shriftiga qaytadi.
        return .custom(
            name,
            size: style.size,
            relativeTo: style.relativeTo
        )

        #endif

        #endif
    }

    /// Bundle ichidagi barcha `.ttf` / `.otf` fayllarni
    /// CoreText orqali ro'yxatdan o'tkazadi.
    ///
    /// Shu sababli Info.plist'dagi
    /// "Fonts provided by application"
    /// sozlamasi shart emas.
    ///
    /// `OvozchaAppDelegate.onInit()` ichida,
    /// birinchi ekran chizilishidan oldin chaqiriladi.
    ///
    /// CoreText faqat Apple platformalarida mavjud;
    /// Skip (Android) da bu funksiya bo'sh.
    static func registerBundledFonts() {

        #if !SKIP

        let bundle = Bundle.main

        guard
            let root = bundle.resourceURL,
            let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: nil
            )
        else {
            return
        }

        for case let url as URL in enumerator {

            let ext = url.pathExtension.lowercased()

            guard ext == "ttf" || ext == "otf" else {
                continue
            }

            var error: Unmanaged<CFError>?

            let registered = CTFontManagerRegisterFontsForURL(
                url as CFURL,
                .process,
                &error
            )

            #if DEBUG

            if !registered {
                // "Allaqachon ro'yxatdan o'tgan"
                // xatosi zararsiz.
                print(
                    "Shrift ro'yxatdan o'tmadi: \(url.lastPathComponent)"
                )
            }

            #else

            _ = registered

            #endif
        }

        #endif
    }
}

// MARK: - Qulay sintaksis

extension Font {

    /// Foydalanish:
    /// `.font(.ov(.headline))`
    static func ov(_ style: OvTextStyle) -> Font {
        AppFont.font(for: style)
    }
}

extension Text {

    /// Shrift, rang, harflar oralig'i va
    /// kerak bo'lsa bosh harflarni bir joyda beradi.
    ///
    /// Misol:
    /// `Text("Salom,").ovStyle(.overline, color: .ovTextSecondary)`
    func ovStyle(
        _ style: OvTextStyle,
        color: Color = .ovInk
    ) -> some View {

        self
            .font(.ov(style))
            .tracking(style.tracking)
            .foregroundStyle(color)
            .textCase(
                style.isUppercase
                ? Text.Case.uppercase
                : nil
            )
    }
}
