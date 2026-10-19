import SwiftUI

/// Ota-ona paneli. Bugungi vaqt, ketma-ket kunlar, talaffuz aniqligi, so'nggi faoliyat va
/// sozlamalar (`ParentDashboardView`). IOS va Android (Skip) uchun bir xil.
///
/// Tab emas: Bosh ekrandagi tugma orqali ochiladi (`HomeView`) — kattalar uchun bo'lim.
/// `onClose` — panelni yopish (iOS: sheet, Android: Bosh ekranga qaytish).
struct ParentView: View {
    var onClose: (() -> Void)? = nil

    var body: some View {
        ParentDashboardView(onClose: onClose)
    }
}
