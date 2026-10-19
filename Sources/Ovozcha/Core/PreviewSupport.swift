#if DEBUG
import SwiftUI

extension View {
    /// Xcode Preview uchun: shriftlarni ro'yxatdan o'tkazadi va kerakli environment obyektlarini beradi.
    /// (Preview'da `OvozchaApp.init()` ishlamaydi.)
    func ovPreviewEnvironment() -> some View {
        AppFont.registerBundledFonts()
        return self
            .environment(AppRouter())
            .environment(ProfileStore())
            #if SKIP
            .modifier(LearningStoresModifier())
            #else
            // Preview'da haqiqiy ma'lumotga tegmaslik uchun alohida UserDefaults to'plami.
            .modifier(LearningStoresModifier(defaults: UserDefaults(suiteName: "ovozcha.preview") ?? .standard))
            #endif
    }
}
#endif
