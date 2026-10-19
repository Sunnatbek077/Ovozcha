import SwiftUI

extension View {
    /// Katta ekranlarda (iPad) kontent kengligini cheklab, markazga qo'yadi.
    /// Android (Skip)'da kenglik cheklovi kontentni ekrandan kengroq qilib yuborishi mumkin (BosH ekrandagi
    /// izohga qarang), shuning uchun u yerda faqat to'liq kenglik beriladi.
    func ovContentWidth() -> some View {
        #if SKIP
        return self.frame(maxWidth: .infinity)
        #else
        return self
            .frame(maxWidth: Theme.Layout.maxContentWidth)
            .frame(maxWidth: .infinity)
        #endif
    }
}
