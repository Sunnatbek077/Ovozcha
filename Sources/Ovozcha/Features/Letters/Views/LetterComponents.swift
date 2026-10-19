import SwiftUI

// MARK: - Statistika kartasi

/// Kichik statistika kartasi: katta qiymat + izoh (maketdagi "12 / Bugun mashq").
struct StatCard: View {
    let value: String
    let title: String
    let valueColor: Color
    /// Bir qatorda bir nechta karta bo'lsa, balandligi teng bo'lishi uchun (Ota-ona paneli).
    var minHeight: CGFloat = 0.0

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(value)
                .ovStyle(.title, color: valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .ovStyle(.caption, color: .ovTextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: minHeight)
        .ovCard(padding: Theme.Spacing.m)
        #if !SKIP
        .accessibilityElement(children: .combine)
        #endif
    }
}

// MARK: - Tovush tugmasi

/// "Bosing — tovushni eshiting" (maketdagi ko'k tugma). Harflar va sonlar uchun umumiy.
/// Yozuv bo'lmasa, ikki soniya davomida buni matn bilan aytadi.
struct SoundChip: View {
    /// Tugmadagi yozuv (harf uchun umumiy, son uchun `Bosing — "besh" deb eshiting`).
    let title: String
    /// Ovoz fayli nomi (kengaytmasiz): `letter_a`, `number_5`.
    let audioFileName: String
    let audio: LetterAudioPlayer
    /// Yozuv topilmasa, 2 soniya ko'rsatiladigan matn (sonlar uchun o'zgartiriladi).
    var missingMessage: String = Strings.Letters.soundMissing

    @State private var showMissing = false

    var body: some View {
        Button(action: { play() }) {
            HStack(spacing: Theme.Spacing.s) {
                OvIcon(symbol: "speaker.wave.2.fill", size: 20, tint: Color.ovSkyStrong)
                    .foregroundStyle(Color.ovSkyStrong)
                    .accessibilityHidden(true)
                Text(showMissing ? missingMessage : title)
                    .ovStyle(.subheadline, color: .ovInk)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(Color.ovSky.opacity(Theme.tintOpacity), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .ovPressShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityLabel(title)
    }

    private func play() {
        if audio.play(fileName: audioFileName) { return }
        showMissing = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showMissing = false
        }
    }
}

// MARK: - Amal tugmasi

/// Katta, aniq tugma (>= 52 pt). `primary`: to'ldirilgan binafsha; `secondary`: oq karta.
///
/// iOS: bosilganda kichrayadigan maxsus `ButtonStyle`. Android (Skip): maxsus stillar qo'llab-quvvatlanmaydi,
/// shuning uchun fon va chegara tugma ichida chiziladi.
struct OvActionButton: View {
    enum Kind {
        case primary
        case secondary
    }

    let title: String
    let systemImage: String
    let kind: Kind
    var hint: String? = nil
    let action: () -> Void

    private var foreground: Color {
        return kind == Kind.primary ? Color.white : Color.ovPurpleStrong
    }

    private var content: some View {
        Label {
            Text(title).ovStyle(.headline, color: foreground)
        } icon: {
            OvIcon(symbol: systemImage, size: 20, tint: foreground)
                .foregroundStyle(foreground)
        }
        .frame(maxWidth: .infinity, minHeight: 52)
    }

    var body: some View {
        #if SKIP
        Button(action: action) {
            content
                .background(
                    kind == Kind.primary ? Color.ovPurpleStrong : Color.ovSurface,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                        .strokeBorder(kind == Kind.primary ? Color.clear : Color.ovBorder, lineWidth: 1.0)
                )
        }
        .buttonStyle(.plain)
        .ovPressShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        #else
        Button(action: action) {
            content
        }
        .buttonStyle(OvActionButtonStyle(kind: kind))
        .accessibilityHint(hint ?? "")
        #endif
    }
}

#if !SKIP
struct OvActionButtonStyle: ButtonStyle {
    let kind: OvActionButton.Kind

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
        let fill = kind == .primary ? Color.ovPurpleStrong : Color.ovSurface
        let border = kind == .primary ? Color.clear : Color.ovBorder
        return configuration.label
            .background(fill, in: shape)
            .overlay(shape.strokeBorder(border, lineWidth: 1))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}
#endif

// MARK: - Fikr-mulohaza tasmasi

/// Kartaning yuqorisida chiqadigan qisqa fikr (muvaffaqiyat yulduzlari yoki yo'l-yo'riq).
struct TraceFeedbackBanner: View {
    let feedback: TraceFeedback

    private var isVisible: Bool {
        switch feedback {
        case .idle:
            return false
        default:
            return true
        }
    }

    private var starCount: Int {
        switch feedback {
        case .success(let stars):
            return stars
        default:
            return 0
        }
    }

    private var symbolName: String {
        switch feedback {
        case .keepGoing:
            return "hand.point.up.left.fill"
        case .stayInside:
            return "scribble.variable"
        default:
            return ""
        }
    }

    private var messageText: String {
        switch feedback {
        case .success(let stars):
            return message(for: stars)
        case .keepGoing:
            return Strings.Letters.keepGoing
        case .stayInside:
            return Strings.Letters.stayInside
        default:
            return ""
        }
    }

    private var fillColor: Color {
        switch feedback {
        case .success:
            return Color.ovGreen.opacity(0.16)
        default:
            return Color.ovYellow.opacity(0.28)
        }
    }

    private var textColor: Color {
        switch feedback {
        case .success:
            return Color.ovGreenStrong
        default:
            return Color.ovInk
        }
    }

    var body: some View {
        if isVisible {
            HStack(spacing: Theme.Spacing.s) {
                if starCount > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { index in
                            OvIcon(symbol: index < starCount ? "star.fill" : "star", size: 16,
                                   tint: index < starCount ? Color.ovRewardFill : Color.ovTextSecondary.opacity(0.5))
                                .foregroundStyle(index < starCount ? Color.ovRewardFill : Color.ovTextSecondary.opacity(0.5))
                        }
                    }
                    #if !SKIP
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Strings.Letters.stars(starCount))
                    #endif
                } else {
                    OvIcon(symbol: symbolName, size: 16, tint: Color.ovInk)
                        .foregroundStyle(Color.ovInk)
                        .accessibilityHidden(true)
                }
                Text(messageText)
                    .ovStyle(.caption, color: textColor)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.s)
            .background(fillColor, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.ovBorder, lineWidth: 1.0))
            .padding(.top, Theme.Spacing.m)
            .padding(.horizontal, Theme.Spacing.m)
            #if !SKIP
            .accessibilityElement(children: .combine)
            #endif
        }
    }

    private func message(for stars: Int) -> String {
        switch stars {
        case 1:
            return Strings.Letters.success1
        case 2:
            return Strings.Letters.success2
        default:
            return Strings.Letters.success3
        }
    }
}
