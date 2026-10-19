import Foundation

/// Tab panelining 5 ta bo'limi. Bola uchun to'rtta doimiy tab + Imlo (iOS'da qidiruv tabi).
///
/// Ota-ona paneli tab EMAS: u kattalar uchun va Bosh ekrandagi tugma orqali ochiladi
/// (`HomeView`) — bola tasodifan kirib, masalan, progressni tozalab yubormasin. Tablar soni
/// 5 dan oshmasligi kerak: iPhone ortiqchasini "More" ro'yxatiga yig'adi.
enum AppTab: Int, CaseIterable, Identifiable, Hashable {
    case home
    case letters
    case numbers
    case pronunciation
    case spelling

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home:          return Strings.Tab.home
        case .letters:       return Strings.Tab.letters
        case .numbers:       return Strings.Tab.numbers
        case .pronunciation: return Strings.Tab.pronunciation
        case .spelling:      return Strings.Tab.spelling
        }
    }

    /// SF Symbols. TabView tanlangan holatda ularni o'zi to'ldirib (fill) ko'rsatadi.
    var symbol: String {
        switch self {
        case .home:          return "house"
        case .letters:       return "pencil.line"
        case .numbers:       return "textformat.123"
        case .pronunciation: return "mic"
        case .spelling:      return "character.book.closed"
        }
    }

    #if !SKIP
    /// iOS: tab panelidagi oddiy tablar. Imlo ular qatorida emas — u tizimning qidiruv tabi
    /// (`RootTabView`): panelda alohida doira, bosilganda qidiruv maydoniga kengayadi.
    static var primaryTabs: [AppTab] {
        return [.home, .letters, .numbers, .pronunciation]
    }
    #endif

    #if SKIP
    // Android: tab ikonkalari `res/drawable/` dagi vektor fayllardan olinadi
    // (`RootTabView` ga qarang). SF Symbol va SVG yo'li ishlatilmaydi: birinchisi
    // har rekompozitsiyada ImageVector qayta quradi, ikkinchisi Coil orqali
    // asinxron yuklanib, panelni siljitadi.
    //
    // Material 3 qoidasi: tanlanmagan holat — kontur, tanlangan holat — to'ldirilgan.
    // `numbers` da raqam glifi bo'lgani uchun ikkala holat bir xil; tanlanganini
    // rang va indikator ko'rsatadi.

    /// Tanlanmagan holat (kontur).
    var androidIcon: String {
        switch self {
        case .home:          return "ov_home_outline"
        case .letters:       return "ov_pencil_line_outline"
        case .numbers:       return "ov_numbers"
        case .pronunciation: return "ov_mic_outline"
        case .spelling:      return "ov_book_outline"
        }
    }

    /// Tanlangan holat (to'ldirilgan).
    var androidIconSelected: String {
        switch self {
        case .home:          return "ov_home"
        case .letters:       return "ov_pencil_line"
        case .numbers:       return "ov_numbers"
        case .pronunciation: return "ov_mic"
        case .spelling:      return "ov_book"
        }
    }
    #endif
}
