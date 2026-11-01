import SwiftUI

/// Butun ilova ustidagi dam olish qatlami (`LearningStoresModifier` qo'yadi).
///
///  - 15 daqiqada pastdan chiqadigan karta: "Yana shug'ullanasizmi?" va faqat "Ha" tugmasi.
///  - 25 daqiqada to'liq ekranli majburiy dam: xabar, sanagich, tugma yo'q.
///  - Dam tugagach: "Ko'proq mashq qilamizmi?" va "Ha" tugmasi.
///
/// Hech narsa ko'rsatilmasa, qatlam bo'sh va teginishlarni to'smaydi.
/// IOS va Android (Skip) uchun umumiy.
struct BreakCoachOverlay: View {
    @Environment(BreakCoachStore.self) private var coach

    var body: some View {
        ZStack(alignment: .bottom) {
            if coach.phase == BreakCoachStore.Phase.resting {
                restScreen
                    .transition(.opacity)
            } else if coach.phase == BreakCoachStore.Phase.askMore {
                askMoreScreen
                    .transition(.opacity)
            } else if coach.showCheckIn {
                // Orqa xira parda va karta alohida: parda so'nadi, karta pastdan chiqadi.
                Color.ovInk.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { }
                    .transition(.opacity)
                checkInCard
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(Animation.easeOut(duration: 0.25), value: coach.showCheckIn)
        .animation(Animation.easeOut(duration: 0.25), value: coach.phase)
    }

    // MARK: 15 daqiqa: pastdan chiqadigan savol

    private var checkInCard: some View {
        VStack(spacing: Theme.Spacing.l) {
            Text(Strings.BreakCoach.checkInTitle)
                .ovStyle(.title)
                .multilineTextAlignment(.center)
            yesButton(action: { coach.confirmCheckIn() })
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            Color.ovSurface,
            in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Color.ovBorder, lineWidth: 1)
        )
        .ovContentWidth()
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.bottom, Theme.Spacing.xl)
    }

    // MARK: 25 daqiqa: majburiy dam

    private var restScreen: some View {
        let total = max(coach.restTotal, 1)
        let progress = 1.0 - Double(coach.restRemaining) / Double(total)
        return VStack(spacing: Theme.Spacing.xl) {
            Spacer(minLength: 0)

            MascotView(size: 120)

            Text(Strings.BreakCoach.restMessage(forBreak: coach.breakNumber))
                .ovStyle(.title)
                .multilineTextAlignment(.center)

            Text(Strings.BreakCoach.clock(coach.restRemaining))
                .ovStyle(.display, color: Color.ovPurpleStrong)

            ProgressView(value: min(max(progress, 0.0), 1.0), total: 1.0)
                .tint(Color.ovPurpleStrong)
                .frame(maxWidth: 240)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.vertical, Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ovScreenBackground()
        // Ostidagi mashq ekraniga teginish o'tmasin.
        .onTapGesture { }
    }

    // MARK: Dam tugadi: "Ko'proq mashq qilamizmi?"

    private var askMoreScreen: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer(minLength: 0)

            MascotView(size: 120)

            Text(Strings.BreakCoach.moreTitle)
                .ovStyle(.title)
                .multilineTextAlignment(.center)

            // Android (Skip)'da `frame(maxWidth: 560)` tugmani ekrandan kengaytirib, chapga siljitardi
            // (`ovContentWidth` izohiga qarang): u yerda faqat to'liq kenglik beriladi.
            yesButton(action: { coach.continuePracticing() })
                .ovContentWidth()

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.vertical, Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ovScreenBackground()
        .onTapGesture { }
    }

    // MARK: Umumiy "Ha" tugmasi

    private func yesButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(Strings.BreakCoach.yes)
                .ovStyle(.headline, color: Color.ovSurface)
                .frame(maxWidth: .infinity)
                .frame(minHeight: Theme.Layout.minTapTarget)
                .background(Color.ovPurpleStrong, in: Capsule())
        }
        .buttonStyle(.plain)
        .ovPressShape(Capsule())
        .accessibilityLabel(Strings.BreakCoach.yes)
    }
}
