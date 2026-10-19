import SwiftUI

/// Ilovaning skeleti.
///
/// iOS: faqat tizimning `TabView`i va uning o'z Liquid Glass paneli (bosilgandagi linza effekti,
/// animatsiyalar — hammasi tizimniki; qo'lda chizilgan panel yo'q). Panel barqaror:
///
///     [ Bosh · Harflar · Sonlar · Talaffuz ]  ( 🔍 )
///
/// - To'rtta tab doim o'z joyida — hech biri yashirinmaydi (bola "Bosh" ni yo'qotmaydi).
/// - Imlo — tizimning qidiruv tabi (`Tab(role: .search)`): iOS 26 da panelda alohida doira,
///   bosilganda tizimning o'zi uni qidiruv maydoniga kengaytiradi (Imlo ekrani `.searchable`).
///   iOS 27 da doira alohida chizilishi uchun `tabViewSearchActivation(.searchTabSelection)` kerak.
/// - Ota-ona paneli tab emas — Bosh ekrandagi tugma (`HomeView`).
///
/// Android: `AndroidTabShell` — Material 3 `NavigationBar` ustiga qurilgan o'z skeletimiz.
/// SkipUI'ning `TabView`i Android'da Navigation 3 (`NavDisplay`) ustida ishlaydi va har
/// kompozitsiyada 100 ta `NavBackStack` hamda 100 ta `rememberDecoratedNavEntries` ni
/// qayta yaratadi (`TabView.swift` dagi `rememberSkipTabViewBackStacks`). Bizda tablar
/// mustaqil yuqori darajadagi ekranlar, ular orasida push navigatsiya yo'q, shuning uchun
/// bu mexanizm ortiqcha yuk edi: o'lchovda bo'sh ekranlar bilan ham bosishiga ~139 ms
/// ketardi, o'z skeletimizda ~95 ms (debug, emulyator).
struct RootTabView: View {
    #if !SKIP
    @Environment(AppRouter.self) private var router
    #endif

    var body: some View {
        #if SKIP
        AndroidTabShell()
        #else
        tabView
            // Binafsha brend rangining to'qroq varianti (oq fonda 5.4:1), PDF'dagi faol tab rangi.
            .tint(Color.ovPurpleStrong)
            // Haptic feedback faqat iOS/macOS'da ishlatiladi.
            // Android/Skip'da sensoryFeedback ayrim qurilmalarda haptic
            // permission/runtime muammosi sabab tab almashishda crash qilishi mumkin.
            .sensoryFeedback(.selection, trigger: router.selectedTab)
        #endif
    }

    #if !SKIP
    @ViewBuilder
    private var tabView: some View {
        if #available(iOS 26.0, *) {
            searchTabView
                .tabViewSearchActivation(.searchTabSelection)
        } else if #available(iOS 18.0, *) {
            searchTabView
        } else {
            legacyTabView
        }
    }

    @available(iOS 18.0, *)
    private var searchTabView: some View {
        @Bindable var router = router

        return TabView(selection: $router.selectedTab) {
            ForEach(AppTab.primaryTabs) { tab in
                Tab(tab.title, systemImage: tab.symbol, value: tab) {
                    tab.screen
                }
            }
            Tab(AppTab.spelling.title, systemImage: "magnifyingglass", value: AppTab.spelling, role: .search) {
                AppTab.spelling.screen
            }
        }
    }

    /// iOS 17: `Tab` API yo'q — oddiy 5 ta tab.
    private var legacyTabView: some View {
        @Bindable var router = router

        return TabView(selection: $router.selectedTab) {
            ForEach(AppTab.allCases) { tab in
                tab.screen
                    .tabItem {
                        Label(tab.title, systemImage: tab.symbol)
                    }
                    .tag(tab)
            }
        }
    }
    #endif
}

extension AppTab {
    /// Shu tabning ekrani. iOS va Android bitta ta'rifdan foydalanadi.
    @MainActor @ViewBuilder var screen: some View {
        switch self {
        case .home:          HomeView()
        case .letters:       LettersView()
        case .numbers:       NumbersView()
        case .pronunciation: PronunciationView()
        case .spelling:      SpellingView()
        }
    }
}

#if DEBUG
#Preview {
    RootTabView()
        .ovPreviewEnvironment()
}
#endif
