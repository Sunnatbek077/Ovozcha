import SwiftUI

/// "Bugungi yutuq" kartasi. Maketda matn oq edi (sariq fonda 1.9:1),
/// bu yerda Ink rangida (7.4:1), shunda bola va ota-ona bemalol o'qiydi.
struct RewardCard: View {
    let streakDays: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "star.fill")
                .font(.title2)
                .foregroundStyle(Color.ovInk)
                .accessibilityHidden(true)

            Text(message)
                .ovStyle(.title3)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: Theme.Layout.minTapTarget)
        .background(
            Color.ovRewardFill,
            in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
        )
        // `accessibilityElement` Skip (Android) da hali yo'q, faqat Apple platformalarida.
        #if !SKIP
        .accessibilityElement(children: .combine)
        #endif
    }

    private var message: String {
        streakDays > 0 ? Strings.Home.streak(streakDays) : Strings.Home.noStreak
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        RewardCard(streakDays: 3)
        RewardCard(streakDays: 0)
    }
    .padding(20)
    .background(Color.ovBackground)
    .ovPreviewEnvironment()
}
#endif
