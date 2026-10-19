import SwiftUI

/// 1-ekran: Bosh ekran.
/// Salom + maskot, uchta bo'lim kartasi, "Bugungi yutuq".
///
/// Kartalar tabni almashtiradi (push qilmaydi): Apple HIG bo'yicha tab bar
/// yuqori darajadagi bo'limlar uchun, ular orasida "orqaga" tugmasi bo'lmaydi.
///
/// Ota-ona paneli shu yerdan, sarlavhadagi tugma orqali ochiladi (tab emas — kattalar uchun):
/// iOS'da tizim sheet'i (iOS 18+ da tugmadan "zoom" bo'lib ochiladi), Android'da to'liq ekran.
struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(ProfileStore.self) private var profile
    // Haqiqiy ketma-ket kunlar faoliyat tarixidan olinadi (iOS va Android).
    @Environment(ActivityStore.self) private var activity

    @State private var showsParent = false
    #if !SKIP
    @Namespace private var parentTransition
    #endif

    var body: some View {
        #if SKIP
        if showsParent {
            ParentView(onClose: { showsParent = false })
                .background(AndroidBackHandler(onBack: { showsParent = false }))
        } else {
            homeContent
                .ovScreenBackground()
        }
        #else
        NavigationStack {
            homeContent
                .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showsParent) {
            ParentView(onClose: { showsParent = false })
                .parentZoomTransition(in: parentTransition)
        }
        #endif
    }

    private var homeContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                header
                modules
                weekStrip
                achievement
            }
            .padding(.horizontal, Theme.Spacing.screen)
            .padding(.top, Theme.Spacing.s)
            .padding(.bottom, Theme.Spacing.xl)
            // Skip (Android) da `maxWidth` cheklovi kontentni ekrandan kengroq qilib yuboradi,
            // shuning uchun u faqat iOS'da qo'llanadi (telefonda baribir ekran kengligicha).
            #if !SKIP
            .frame(maxWidth: Theme.Layout.maxContentWidth)
            #endif
            .frame(maxWidth: .infinity)
        }
        .ovScreenBackground()
    }

    // MARK: Bo'limlar

    private var header: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(Strings.Home.greeting)
                    .ovStyle(.overline, color: .ovTextSecondary)
                Text(verbatim: "\(profile.childName)!")
                    .ovStyle(.display)
                    // Ism 20 belgigacha: uzun ism (va yonidagi Ota-ona tugmasi) uni ikki qatorga
                    // bo'lib, "!" ni alohida qatorga tushirmasin.
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            // `accessibilityElement` va `accessibilityAddTraits` Skip (Android) da hali yo'q.
            #if !SKIP
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            #endif

            Spacer(minLength: Theme.Spacing.s)

            parentButton

            MascotView(size: 68)
        }
    }

    /// Ota-ona paneli tugmasi. iOS 26: Apple'ning tayyor Liquid Glass tugmasi.
    @ViewBuilder
    private var parentButton: some View {
        #if SKIP
        Button(action: { showsParent = true }) {
            OvIcon(symbol: "person", size: 24, tint: Color.ovInk)
                .foregroundStyle(Color.ovInk)
                .frame(width: 48, height: 48)
                .background(Color.ovSurface, in: Circle())
                .overlay(Circle().strokeBorder(Color.ovBorder, lineWidth: 1.0))
        }
        .buttonStyle(.plain)
        .ovPressShape(Circle())
        .accessibilityLabel(Strings.Screen.parent)
        #else
        Button {
            showsParent = true
        } label: {
            Image(systemName: "person.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.ovInk)
                .frame(width: 28, height: 28)
        }
        .parentButtonStyle()
        .parentZoomSource(in: parentTransition)
        .accessibilityLabel(Strings.Screen.parent)
        #endif
    }

    private var modules: some View {
        VStack(spacing: Theme.Spacing.m) {
            ForEach(LearningModule.allCases) { module in
                ModuleCard(module: module) {
                    router.open(module)
                }
            }
        }
    }

    private var streakDays: Int {
        return activity.streakDays
    }

    /// Kunlik faollik: oxirgi 7 kun. To'ldirilgan doira — shu kuni mashq qilingan.
    private var weekStrip: some View {
        let days = activity.recentDays(7)
        var activeCount = 0
        for day in days {
            if day.isActive { activeCount += 1 }
        }
        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                Text(Strings.Home.weekTitle)
                    .ovStyle(.overline, color: .ovTextSecondary)
                    #if !SKIP
                    .accessibilityAddTraits(.isHeader)
                    #endif
                Spacer(minLength: 0)
                Text(verbatim: "\(activeCount)/7 \(Strings.Home.weekDone)")
                    .ovStyle(.caption, color: .ovTextSecondary)
            }
            WeekStripView(days: days)
        }
    }

    private var achievement: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text(Strings.Home.todayAchievement)
                .ovStyle(.overline, color: .ovTextSecondary)
                #if !SKIP
                .accessibilityAddTraits(.isHeader)
                #endif
            RewardCard(streakDays: streakDays)
        }
    }
}

#if DEBUG
#Preview {
    HomeView()
        .ovPreviewEnvironment()
}
#endif

#if !SKIP
private extension View {
    /// iOS 26: tizimning shisha tugmasi; oldingi versiyalarda tizimning oddiy doira tugmasi.
    @ViewBuilder
    func parentButtonStyle() -> some View {
        if #available(iOS 26.0, *) {
            self
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(.large)
        } else {
            self
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .controlSize(.large)
        }
    }

    /// iOS 18+: sheet shu tugmadan "zoom" bo'lib ochiladi (tizim o'tishi).
    @ViewBuilder
    func parentZoomSource(in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            self.matchedTransitionSource(id: "parent", in: namespace)
        } else {
            self
        }
    }

    @ViewBuilder
    func parentZoomTransition(in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            self.navigationTransition(.zoom(sourceID: "parent", in: namespace))
        } else {
            self
        }
    }
}
#endif
