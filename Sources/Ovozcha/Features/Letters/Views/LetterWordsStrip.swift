import SwiftUI

/// Harfni tushuntiruvchi so'zlar qatori: emoji + so'z, so'z ichidagi harf ajratilgan.
///
/// Nutq tanish sozlangan bo'lsa, kartani bosib so'zni aytish mumkin: ilova yozib oladi,
/// matnga aylantiradi va baholaydi.
///
/// Sozlanmagan bo'lsa (`OvozchaConfig` da kalit/manzil yo'q), kartalar oddiy ko'rsatkich
/// bo'lib qoladi — bosilmaydi, ya'ni hech narsa qilmaydigan tugma paydo bo'lmaydi.
struct LetterWordsStrip: View {
    let letter: UzbekLetter
    let words: [LetterWord]

    @State private var checker = WordPronunciationChecker()

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            header
            ScrollView(.horizontal) {
                HStack(spacing: Theme.Spacing.s) {
                    ForEach(words) { word in
                        card(for: word)
                    }
                }
                #if !SKIP
                .padding(.horizontal, 1)
                #endif
            }
            #if !SKIP
            .scrollIndicators(.hidden)
            #endif
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
            Text(Strings.Letters.wordsTitle(letter.upper))
                .ovStyle(.overline, color: .ovTextSecondary)
                #if !SKIP
                .accessibilityAddTraits(.isHeader)
                #endif
            Spacer(minLength: 0)
            Text(statusText)
                .ovStyle(.caption, color: statusColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    // MARK: Holat matni

    private var statusText: String {
        guard checker.isAvailable else { return "" }
        switch checker.phase {
        case .idle:              return Strings.Letters.speakHint
        case .recording:         return Strings.Letters.listening
        case .checking:          return Strings.Letters.checking
        case .correct:           return Strings.Letters.correct
        case .almost(let sound): return Strings.Letters.almost(sound: sound)
        case .retry:             return Strings.Letters.retry
        case .notHeard:          return Strings.Letters.notHeard
        case .permissionDenied:  return Strings.Letters.micDenied
        case .offline:           return Strings.Letters.offline
        case .unavailable:       return Strings.Letters.unavailable
        }
    }

    private var statusColor: Color {
        switch checker.phase {
        case .correct:   return .ovGreenStrong
        case .recording: return .ovPurpleStrong
        default:         return .ovTextSecondary
        }
    }

    // MARK: Karta

    /// Kartaning chegarasi holatni ko'rsatadi: yozilmoqda, to'g'ri, yoki qayta urinish.
    private func borderColor(for word: LetterWord) -> Color {
        guard checker.isActive(word) else { return .ovBorder }
        switch checker.phase {
        case .recording:          return .ovPurpleStrong
        case .correct:            return .ovGreenStrong
        case .almost, .retry:     return .ovRewardFill
        default:                  return .ovBorder
        }
    }

    private func borderWidth(for word: LetterWord) -> CGFloat {
        return checker.isActive(word) && checker.phase != .idle ? 2.0 : 1.0
    }

    @ViewBuilder
    private func card(for word: LetterWord) -> some View {
        if checker.isAvailable {
            Button(action: { tapped(word) }) {
                cardBody(word)
            }
            .buttonStyle(.plain)
            .ovPressShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .accessibilityLabel(word.text)
            .accessibilityHint(Strings.Letters.speakHint)
        } else {
            cardBody(word)
                #if !SKIP
                .accessibilityElement(children: .ignore)
                #endif
                .accessibilityLabel(word.text)
        }
    }

    private func cardBody(_ word: LetterWord) -> some View {
        return VStack(spacing: Theme.Spacing.xs) {
            Text(word.emoji)
                .font(.system(size: 34))
                .accessibilityHidden(true)
            highlighted(word.text)
        }
        .frame(minWidth: 84)
        .padding(.vertical, Theme.Spacing.s)
        .padding(.horizontal, Theme.Spacing.m)
        .background(
            Color.ovSurface,
            in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(borderColor(for: word), lineWidth: borderWidth(for: word))
        )
    }

    private func tapped(_ word: LetterWord) {
        if checker.isActive(word) && checker.phase == .recording {
            checker.finishRecording(for: word)
        } else {
            checker.startRecording(for: word)
        }
    }

    /// So'zni belgilab chizadi: harfga tegishli belgilar brend rangida.
    ///
    /// `Text + Text` SkipUI'da ishlamaydi (Android'da `fatalError`), shuning uchun
    /// har bir belgi alohida `Text` sifatida, oralig'isiz `HStack` da chiziladi.
    private func highlighted(_ word: String) -> some View {
        let mask = LetterWords.letterMask(word: word, letter: letter.lower)
        var characters: [String] = []
        for character in word {
            characters.append(String(character))
        }
        return HStack(spacing: 0) {
            ForEach(Array(characters.indices), id: \.self) { index in
                Text(characters[index])
                    .font(GuideFont.font(size: 20, relativeTo: .body))
                    .foregroundStyle(mask[index] ? Color.ovPurpleStrong : Color.ovInk)
            }
        }
        .lineLimit(1)
    }
}
