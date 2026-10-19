import SwiftUI

/// Ro'yxat (to'r) kartalaridagi harf va raqamlar uchun shrift: iz ko'rsatmasi bilan bir xil shakl (Andika).
///
/// iOS: `TraceFont` (modul resursidan ro'yxatdan o'tkaziladi). Android: `Android/app/src/main/res/font/`
/// ichidagi `andika_bold.ttf` (Poppins bilan bir xil usul; shrift nomi fayl nomi).
enum GuideFont {
    static func font(size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        #if SKIP
        // `relativeTo` Android'da ishlatilmaydi (SkipUI o'lchamni qo'shimcha o'zgartirmasligi uchun).
        return Font.custom("andika_bold", size: size)
        #else
        return TraceFont.swiftUIFont(size: size, relativeTo: style)
        #endif
    }
}
