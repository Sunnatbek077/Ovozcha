import SwiftUI

/// Sonlar bo'limining ildizi: sonlar to'ri -> son yozish ekrani.
/// Ombor, sozlamalar va pleyer butun ilova uchun umumiy (`LearningStoresModifier`).
///
/// iOS: native `NavigationStack`. Android: `NavigationStack`siz oddiy almashtirish (TabView ichidagi
/// `NavigationStack` konflikti sababli; `AndroidScreenBar` ga qarang).
struct NumbersFlowView: View {
    /// Android: tanlangan element (`nil` bo'lsa, to'r ko'rsatiladi). iOS'da ishlatilmaydi.
    @State private var selected: NumberItem? = nil

    var body: some View {
        #if SKIP
        if let number = selected {
            NumberWritingView(startNumber: number, onClose: { selected = nil })
        } else {
            NumberGridView(onSelect: { picked in selected = picked })
        }
        #else
        NavigationStack {
            NumberGridView()
                .navigationDestination(for: NumberItem.self) { number in
                    NumberWritingView(startNumber: number)
                }
        }
        #endif
    }
}

// MARK: - Sonlar to'ri

struct NumberGridView: View {
    @Environment(NumberProgressStore.self) private var store
    /// Android: son tanlanganda chaqiriladi (iOS'da `NavigationLink` ishlatiladi).
    var onSelect: ((NumberItem) -> Void)? = nil

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: Theme.Spacing.m)]

    var body: some View {
        #if SKIP
        // Android: `LazyVGrid` `ScrollView` ichida yagona bola bo'lishi shart (o'ralmagan), shuning uchun
        // sarlavha tashqarida, bo'sh joy esa `ScrollView`ning o'zida.
        VStack(spacing: 0) {
            AndroidScreenBar(title: Strings.Numbers.gridTitle, mode: LearningMode.offline)
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                header
                ScrollView {
                    grid
                }
            }
            .padding(.horizontal, Theme.Spacing.screen)
            .padding(.top, Theme.Spacing.s)
        }
        .ovScreenBackground()
        #else
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                header
                grid
            }
            .padding(.horizontal, Theme.Spacing.screen)
            .padding(.vertical, Theme.Spacing.l)
            .ovContentWidth()
        }
        .ovScreenBackground()
        .ovNavigationBar(title: Strings.Numbers.gridTitle, mode: .offline)
        #endif
    }

    private func tile(for number: NumberItem) -> some View {
        return NumberTile(number: number, stars: store.stars(for: number))
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.m) {
            ForEach(UzbekNumbers.all) { number in
                #if SKIP
                Button(action: { onSelect?(number) }) {
                    tile(for: number)
                }
                .buttonStyle(.plain)
                .ovPressShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous), keepsCardShadow: true)
                #else
                NavigationLink(value: number) {
                    tile(for: number)
                }
                .buttonStyle(CardPressStyle())
                #endif
            }
        }
    }

    private var header: some View {
        let total = UzbekNumbers.all.count
        let learned = store.learnedCount
        let fraction = total == 0 ? 0.0 : Double(learned) / Double(total)
        return VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(Strings.Numbers.progress(learned, of: total))
                .ovStyle(.subheadline, color: .ovTextSecondary)
            Capsule()
                .fill(Color.ovBorder)
                .frame(height: 8)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(Color.ovSkyStrong)
                            .frame(width: proxy.size.width * fraction)
                    }
                }
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Son kartasi

struct NumberTile: View {
    let number: NumberItem
    let stars: Int

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(number.text)
                .font(GuideFont.font(size: 36, relativeTo: .title))
                .foregroundStyle(Color.ovInk)
            Text(number.word)
                .ovStyle(.caption, color: .ovTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Circle()
                .fill(stars > 0 ? Color.ovSkyStrong : Color.ovBorder)
                .frame(width: 8, height: 8)
        }
        .frame(maxWidth: .infinity, minHeight: 96)
        .ovCard(padding: Theme.Spacing.s)
        #if !SKIP
        .accessibilityElement(children: .ignore)
        #endif
        .accessibilityLabel(Strings.Numbers.tileLabel(number.text, word: number.word, done: stars > 0))
    }
}
