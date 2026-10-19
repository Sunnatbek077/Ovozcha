import SwiftUI

/// Bosh ekrandagi bo'lim kartasi: ikonka, sarlavha, izoh va OFFLINE/ONLINE yorlig'i.
/// Butun karta bitta katta tugma (HIG: kamida 44x44 pt, bu yerda ancha katta).
struct ModuleCard: View {
    let module: LearningModule
    let action: () -> Void

    // Dynamic Type o'lchami faqat Apple platformalarida o'qiladi.
    // Skip (Android) da bu environment kaliti hali yo'q, u yerda `isLargeText` doim `false`.
    #if !SKIP
    @Environment(\.dynamicTypeSize) private var typeSize: DynamicTypeSize
    #endif
    /// Ikonka doirasi Dynamic Type bilan birga o'sadi (faqat iOS; Skip'da qat'iy 52).
    #if SKIP
    private var iconBox: CGFloat { 52 }
    #else
    @ScaledMetric(relativeTo: .headline) private var iconBox: CGFloat = 52
    #endif

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.l) {
                icon

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(module.title)
                        .ovStyle(.headline)
                    Text(module.subtitle)
                        .ovStyle(.subheadline, color: .ovTextSecondary)
                    // Juda katta matn o'lchamida yorliq matn ostiga tushadi (siqilib qolmasligi uchun).
                    if isLargeText {
                        ModeBadge(mode: module.mode)
                            .padding(.top, Theme.Spacing.xs)
                    }
                }
                .multilineTextAlignment(.leading)

                Spacer(minLength: Theme.Spacing.s)

                if !isLargeText {
                    ModeBadge(mode: module.mode)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .ovCard()
            #if !SKIP
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            #endif
        }
        #if SKIP
        .buttonStyle(.plain)
        .ovPressShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous), keepsCardShadow: true)
        #else
        .buttonStyle(CardPressStyle())
        #endif
        .accessibilityHint(Strings.Accessibility.opensSection)
    }

    /// Juda katta matn o'lchamida (Accessibility sizes) yorliq matn ostiga tushadi.
    private var isLargeText: Bool {
        #if SKIP
        return false
        #else
        return typeSize.isAccessibilitySize
        #endif
    }

    private var icon: some View {
        OvIcon(symbol: module.tab.symbol, size: 22, tint: module.strongColor)
            .font(.title3.weight(.semibold))
            .foregroundStyle(module.strongColor)
            .frame(width: iconBox, height: iconBox)
            .background(module.brandColor.opacity(Theme.tintOpacity), in: Circle())
            .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        ForEach(LearningModule.allCases) { module in
            ModuleCard(module: module) {}
        }
    }
    .padding(20)
    .background(Color.ovBackground)
    .ovPreviewEnvironment()
}
#endif
