import SwiftUI

// MARK: - Karta

/// PDF'dagi oq karta: yumaloq burchak, iliq bej chegara, yengil soya.
struct OvCardModifier: ViewModifier {
    let padding: CGFloat

    /// Karta soyasi (`ovPressShape(_:keepsCardShadow:)` ham shuni ishlatadi).
    static var shadowColor: Color { Color.ovInk.opacity(0.06) }
    static let shadowRadius: CGFloat = 10
    static let shadowY: CGFloat = 3

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
        content
            .padding(padding)
            .background(Color.ovSurface, in: shape)
            .overlay(shape.strokeBorder(Color.ovBorder, lineWidth: 1))
            .shadow(color: OvCardModifier.shadowColor, radius: OvCardModifier.shadowRadius, x: 0, y: OvCardModifier.shadowY)
    }
}

extension View {
    func ovCard(padding: CGFloat = Theme.Spacing.l) -> some View {
        modifier(OvCardModifier(padding: padding))
    }

    /// Krem fon (#FDF6EF). Xavfsiz zonalar (notch, home indicator) ostiga ham cho'ziladi.
    func ovScreenBackground() -> some View {
        background { Color.ovBackground.ignoresSafeArea() }
    }
}

// MARK: - Android: bosish effekti tugma shaklida

extension View {
    /// Android: tugma bosilgandagi Material effekti (ripple va bosish qatlami) shu shakl ichida
    /// chiziladi — iOS'dagidek, faqat tugmaning o'zi "bosiladi".
    ///
    /// Nega kerak: SkipUI'da `.plain` tugma `Modifier.clickable` ni yorliqning TO'RTBURCHAK
    /// chegarasiga qo'yadi, `contentShape` esa Android'da yo'q. Natijada dumaloq kartani bosganda
    /// effekt to'rtburchak bo'lib chiqib, karta ichida yana bir tugma borga o'xshardi.
    /// Kesish (`clip`) `clickable` dan oldin turadi, shuning uchun effekt shu shaklga kesiladi.
    ///
    /// `keepsCardShadow`: yorliq `ovCard` bo'lsa, kesish uning soyasini ham kesadi — soya kesilgan
    /// shaklning tashqarisiga qayta qo'yiladi. iOS'da hech narsa qilmaydi (u yerda `ButtonStyle`).
    @ViewBuilder
    func ovPressShape<S: Shape>(_ shape: S, keepsCardShadow: Bool = false) -> some View {
        #if SKIP
        if keepsCardShadow {
            self
                .clipShape(shape)
                .shadow(color: OvCardModifier.shadowColor, radius: OvCardModifier.shadowRadius, x: 0, y: OvCardModifier.shadowY)
        } else {
            self.clipShape(shape)
        }
        #else
        self
        #endif
    }
}

// MARK: - Bosilganda javob beruvchi tugma uslubi

/// Karta bosilganda biroz kichrayadi va xiralashadi.
/// "Harakatni kamaytirish" yoqilgan bo'lsa, kichrayish o'chiriladi (Apple HIG).
/// Skip (Android) da maxsus `ButtonStyle` yozib bo'lmaydi, u yerda `.plain` ishlatiladi.
#if !SKIP
struct CardPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(reduceMotion ? nil : Animation.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
#endif

// MARK: - Navigatsiya paneli
//
// Panelning o'zi native (NavigationStack: orqaga tugmasi, sistem harakati, VoiceOver).
// Faqat sarlavha Poppins bilan, `.principal` joyiga qo'yiladi. `navigationTitle`
// esa orqaga tugmasi va accessibility uchun saqlanadi.

extension View {
    func ovNavigationBar(title: String) -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .ovStyle(.headline)
                        // `accessibilityAddTraits` Skip (Android) da hali yo'q.
                        #if !SKIP
                        .accessibilityAddTraits(.isHeader)
                        #endif
                }
            }
    }

    /// Sarlavha + o'ng tomonda OFFLINE/ONLINE yorlig'i (PDF'dagi 2, 3, 4-ekranlar).
    func ovNavigationBar(title: String, mode: LearningMode) -> some View {
        self
            .ovNavigationBar(title: title)
            .toolbar {
                #if SKIP
                ToolbarItem(placement: .topBarTrailing) {
                    ModeBadge(mode: mode)
                }
                #else
                modeBadgeItem(mode)
                #endif
            }
    }
}

#if !SKIP
/// OFFLINE/ONLINE yorlig'i toolbar'da. iOS 26 tizimi har bir toolbar elementini Liquid Glass
/// kapsulasiga o'raydi, yorliqning esa o'z rangli kapsulasi bor — "kapsula ichida kapsula" chiqadi.
/// Yorliq tugma emas, holat belgisi: tizim shishasi tizimning o'z API'si bilan o'chiriladi
/// (`sharedBackgroundVisibility(.hidden)`).
@MainActor
@ToolbarContentBuilder
private func modeBadgeItem(_ mode: LearningMode) -> some ToolbarContent {
    if #available(iOS 26.0, *) {
        ToolbarItem(placement: .topBarTrailing) {
            ModeBadge(mode: mode)
        }
        .sharedBackgroundVisibility(.hidden)
    } else {
        ToolbarItem(placement: .topBarTrailing) {
            ModeBadge(mode: mode)
        }
    }
}
#endif
