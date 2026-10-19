import SwiftUI

/// Ekran ochiq va ilova faol bo'lgan vaqtni "bugungi mashq vaqti"ga qo'shadi.
/// Ilova fonga o'tsa yoki ekran yopilsa hisob to'xtaydi. IOS va Android (Skip) uchun umumiy.
@MainActor
struct PracticeTimeModifier: ViewModifier {
    @Environment(ActivityStore.self) var activity
    @Environment(\.scenePhase) var scenePhase
    @State private var startedAt: Date? = nil

    func body(content: Content) -> some View {
        content
            .onAppear { begin() }
            .onDisappear { end() }
            .onChange(of: scenePhase) { _, phase in
                if phase == ScenePhase.active {
                    begin()
                } else {
                    end()
                }
            }
    }

    private func begin() {
        if startedAt == nil {
            startedAt = Date()
        }
    }

    private func end() {
        guard let start = startedAt else { return }
        startedAt = nil
        activity.addPracticeTime(seconds: Date().timeIntervalSince(start))
    }
}

extension View {
    /// Shu ekranda o'tkazilgan vaqtni mashq vaqti sifatida yozadi.
    func tracksPracticeTime() -> some View {
        modifier(PracticeTimeModifier())
    }
}
