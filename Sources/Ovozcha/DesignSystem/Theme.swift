import SwiftUI

/// Dizayn tokenlari. Ekranlarda "sehrli raqam" yozilmaydi, hammasi shu yerdan olinadi.
enum Theme {

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        /// Ekranning chap/o'ng chetidan bo'shliq.
        static let screen: CGFloat = 20
    }

    enum Radius {
        static let card: CGFloat = 20
    }

    enum Layout {
        /// Apple HIG va PDF talabi: har bir bosiladigan element kamida 44x44 pt.
        static let minTapTarget: CGFloat = 44
        /// iPad va katta ekranlarda kontent kengligi shu qiymatdan oshmaydi.
        static let maxContentWidth: CGFloat = 560
    }

    /// Ikonka doirasi va badge fonidagi brend rangi shaffofligi (maketdan o'lchangan ~12%).
    static let tintOpacity: Double = 0.12
}
