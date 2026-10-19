import SwiftUI

/// Hali yozilmagan bo'limlar uchun vaqtinchalik ekran. iOS'da native `NavigationStack` va
/// haqiqiy navigatsiya paneli ishlatiladi. Android/Skip'da esa hozircha bu placeholder
/// ekranlar `NavigationStack`dan foydalanmaydi, chunki ular ichki push navigatsiyaga ega emas.
/// Shu bilan Android'dagi TabView -> NavigationStack lifecycle konfliktining oldi olinadi.
struct FeaturePlaceholderView: View {
    let title: String
    let symbol: String
    let mode: LearningMode?

    var body: some View {
        #if SKIP
        VStack(spacing: 0) {
            androidNavigationBar
            placeholder
        }
        .ovScreenBackground()
        #else
        NavigationStack {
            if let mode = mode {
                placeholder.ovNavigationBar(title: title, mode: mode)
            } else {
                placeholder.ovNavigationBar(title: title)
            }
        }
        #endif
    }

    #if SKIP
    /// Android uchun yengil top bar.
    /// Placeholder ekranlarida hozircha ichki NavigationStack kerak emas.
    private var androidNavigationBar: some View {
        ZStack {
            Text(title)
                .ovStyle(.headline)
                .lineLimit(1)
                .padding(.horizontal, 90)

            HStack {
                Spacer(minLength: 0)

                if let mode = mode {
                    ModeBadge(mode: mode)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 52)
        .padding(.horizontal, Theme.Spacing.screen)
        .background(Color.ovBackground)
    }
    #endif

    private var placeholder: some View {
        #if SKIP
        // Skip (Android) da `ContentUnavailableView` yo'q, shuning uchun o'xshash ko'rinish qo'lda yig'ilgan.
        return VStack(spacing: Theme.Spacing.m) {
            OvIcon(symbol: symbol, size: 44, tint: Color.ovPurpleStrong)
                .font(.largeTitle)
                .foregroundStyle(Color.ovPurpleStrong)
            Text(title)
                .ovStyle(.title)
            Text(Strings.Placeholder.comingSoon)
                .ovStyle(.body, color: .ovTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ovScreenBackground()
        #else
        return ContentUnavailableView {
            Label {
                Text(title).ovStyle(.title)
            } icon: {
                Image(systemName: symbol)
                    .foregroundStyle(Color.ovPurpleStrong)
            }
        } description: {
            Text(Strings.Placeholder.comingSoon)
                .ovStyle(.body, color: .ovTextSecondary)
        }
        .ovScreenBackground()
        #endif
    }
}

#if DEBUG
#Preview {
    FeaturePlaceholderView(title: Strings.Screen.letters, symbol: AppTab.letters.symbol, mode: .offline)
        .ovPreviewEnvironment()
}
#endif
