import SwiftUI

/// Ekran ochiq va ilova faol bo'lgan vaqtni "bugungi mashq vaqti"ga qo'shadi.
/// Ilova fonga o'tsa yoki ekran yopilsa hisob to'xtaydi. Shu vaqt `BreakCoachStore`ga ham
/// beriladi (15/25 daqiqalik dam jadvali uchun). IOS va Android (Skip) uchun umumiy.
@MainActor
struct PracticeTimeModifier: ViewModifier {
    @Environment(ActivityStore.self) var activity
    @Environment(BreakCoachStore.self) var coach
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
            // Majburiy dam yoki "Ko'proq mashq qilamizmi?" paytida vaqt sanalmaydi.
            .onChange(of: coach.phase) { _, newPhase in
                if newPhase == BreakCoachStore.Phase.practicing {
                    begin()
                } else {
                    end()
                }
            }
    }

    private func begin() {
        if startedAt == nil && coach.phase == BreakCoachStore.Phase.practicing {
            startedAt = Date()
            coach.sessionBegan()
        }
    }

    private func end() {
        guard let start = startedAt else { return }
        startedAt = nil
        coach.sessionEnded()
        activity.addPracticeTime(seconds: Date().timeIntervalSince(start))
    }
}

extension View {
    /// Shu ekranda o'tkazilgan vaqtni mashq vaqti sifatida yozadi.
    func tracksPracticeTime() -> some View {
        modifier(PracticeTimeModifier())
    }
}
