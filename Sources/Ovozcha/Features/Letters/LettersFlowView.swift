import SwiftUI

/// Harflar bo'limining ildizi: harflar to'ri -> harf yozish ekrani.
/// Ombor, sozlamalar va pleyer butun ilova uchun umumiy (`LearningStoresModifier`).
///
/// iOS: native `NavigationStack`. Android: `NavigationStack`siz oddiy almashtirish (TabView ichidagi
/// `NavigationStack` konflikti sababli; `AndroidScreenBar` ga qarang).
struct LettersFlowView: View {
    /// Android: tanlangan element (`nil` bo'lsa, to'r ko'rsatiladi). iOS'da ishlatilmaydi.
    @State private var selected: UzbekLetter? = nil

    var body: some View {
        #if SKIP
        if let letter = selected {
            LetterWritingView(startLetter: letter, onClose: { selected = nil })
        } else {
            LetterGridView(onSelect: { picked in selected = picked })
        }
        #else
        NavigationStack {
            LetterGridView()
                .navigationDestination(for: UzbekLetter.self) { letter in
                    LetterWritingView(startLetter: letter)
                }
        }
        #endif
    }
}

// MARK: - Harflar to'ri

/// 29 ta harf: bosilsa, shu harfni yozish ekrani ochiladi. Har bir kartada ikki nuqta:
/// bosh va kichik shakl yozilganmi.
struct LetterGridView: View {
    @Environment(LetterProgressStore.self) private var store
    /// Android: harf tanlanganda chaqiriladi (iOS'da `NavigationLink` ishlatiladi).
    var onSelect: ((UzbekLetter) -> Void)? = nil

    private let columns = [GridItem(.adaptive(minimum: 84), spacing: Theme.Spacing.m)]

    var body: some View {
        #if SKIP
        // Android: `LazyVGrid` `ScrollView` ichida yagona bola bo'lishi shart (o'ralmagan), shuning uchun
        // sarlavha tashqarida, bo'sh joy esa `ScrollView`ning o'zida.
        VStack(spacing: 0) {
            AndroidScreenBar(title: Strings.Letters.gridTitle, mode: LearningMode.offline)
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
        .ovNavigationBar(title: Strings.Letters.gridTitle, mode: .offline)
        #endif
    }

    private func tile(for letter: UzbekLetter) -> some View {
        return LetterTile(
            letter: letter,
            upperDone: store.stars(for: letter, style: LetterCase.upper) > 0,
            lowerDone: store.stars(for: letter, style: LetterCase.lower) > 0
        )
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.m) {
            ForEach(UzbekAlphabet.letters) { letter in
                #if SKIP
                Button(action: { onSelect?(letter) }) {
                    tile(for: letter)
                }
                .buttonStyle(.plain)
                .ovPressShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous), keepsCardShadow: true)
                #else
                NavigationLink(value: letter) {
                    tile(for: letter)
                }
                .buttonStyle(CardPressStyle())
                #endif
            }
        }
    }

    private var header: some View {
        let total = UzbekAlphabet.letters.count
        let learned = store.learnedCount
        let fraction = total == 0 ? 0.0 : Double(learned) / Double(total)
        return VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(Strings.Letters.progress(learned, of: total))
                .ovStyle(.subheadline, color: .ovTextSecondary)
            Capsule()
                .fill(Color.ovBorder)
                .frame(height: 8)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(Color.ovGreenStrong)
                            .frame(width: proxy.size.width * fraction)
                    }
                }
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Harf kartasi

struct LetterTile: View {
    let letter: UzbekLetter
    let upperDone: Bool
    let lowerDone: Bool

    var body: some View {
        VStack(spacing: Theme.Spacing.s) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(letter.upper)
                    .font(GuideFont.font(size: 30, relativeTo: .title))
                    .foregroundStyle(Color.ovInk)
                Text(letter.lower)
                    .font(GuideFont.font(size: 22, relativeTo: .title3))
                    .foregroundStyle(Color.ovTextSecondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            HStack(spacing: 6) {
                dot(filled: upperDone)
                dot(filled: lowerDone)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 84)
        .ovCard(padding: Theme.Spacing.s)
        #if !SKIP
        .accessibilityElement(children: .ignore)
        #endif
        .accessibilityLabel(Strings.Letters.tileLabel(letter.upper, upperDone: upperDone, lowerDone: lowerDone))
    }

    private func dot(filled: Bool) -> some View {
        Circle()
            .fill(filled ? Color.ovGreenStrong : Color.ovBorder)
            .frame(width: 8, height: 8)
    }
}
