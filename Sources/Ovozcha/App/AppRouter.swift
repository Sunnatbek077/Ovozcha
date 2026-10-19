import SwiftUI
import Observation

/// Ilova bo'ylab navigatsiya holati. Hozircha faqat tanlangan tab.
/// Bosh ekrandagi kartalar shu orqali TabView'ni almashtiradi.
@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab = .home

    func open(_ module: LearningModule) {
        selectedTab = module.tab
    }
}
