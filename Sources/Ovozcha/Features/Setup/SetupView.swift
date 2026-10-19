import SwiftUI

/// Ilova birinchi marta ochilganda ko'rsatiladigan ekran: bola ismini so'raydi.
///
/// Ism majburiy — u kiritilmaguncha ilovaga kirib bo'lmaydi (`OvozchaRootView` ga qarang).
/// Kiritilgan ism qurilmada saqlanadi, shuning uchun bu ekran faqat bir marta ko'rinadi.
///
/// IOS va Android (Skip) uchun umumiy.
struct SetupView: View {
    @Environment(ProfileStore.self) private var profile

    @State private var name: String = ""
    @State private var showEmptyError: Bool = false

    private var canContinue: Bool {
        return !ProfileStore.normalized(name).isEmpty
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer(minLength: 0)

            MascotView(size: 120)

            VStack(spacing: Theme.Spacing.s) {
                Text(Strings.Setup.title)
                    .ovStyle(.display)
                    .multilineTextAlignment(.center)
                Text(Strings.Setup.subtitle)
                    .ovStyle(.body, color: .ovTextSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                nameField
                // Ism yozila boshlashi bilan xato matni yo'qoladi.
                if showEmptyError && !canContinue {
                    Text(Strings.Setup.emptyError)
                        .ovStyle(.subheadline, color: .ovPurpleStrong)
                }
            }

            startButton

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.vertical, Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ovScreenBackground()
    }

    private var nameField: some View {
        TextField(Strings.Setup.placeholder, text: $name)
            // Android'da TextField sukut bo'yicha Material chegarasini chizadi; bizda
            // karta ko'rinishi bor, shuning uchun ikkita chegara chiqib qolmasin.
            .textFieldStyle(.plain)
            .font(.ov(.title))
            .foregroundStyle(Color.ovInk)
            .multilineTextAlignment(.center)
            .submitLabel(.done)
            .onSubmit {
                submit()
            }
            .padding(Theme.Spacing.l)
            .frame(maxWidth: .infinity, minHeight: Theme.Layout.minTapTarget)
            .background(
                Color.ovSurface,
                in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(Color.ovBorder, lineWidth: 1)
            )
            .accessibilityLabel(Strings.Setup.placeholder)
    }

    private var startButton: some View {
        Button(action: { submit() }) {
            Text(Strings.Setup.start)
                .ovStyle(.headline, color: canContinue ? Color.ovSurface : Color.ovTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: Theme.Layout.minTapTarget)
                .background(
                    canContinue ? Color.ovPurpleStrong : Color.ovBorder,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .ovPressShape(Capsule())
        .accessibilityLabel(Strings.Setup.start)
    }

    private func submit() {
        if profile.setName(name) {
            showEmptyError = false
        } else {
            showEmptyError = true
        }
    }
}

#if DEBUG
#Preview {
    SetupView()
        .ovPreviewEnvironment()
}
#endif
