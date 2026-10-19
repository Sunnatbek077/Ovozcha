import SwiftUI

#if SKIP
import androidx.activity.compose.BackHandler

/// Android tizim "orqaga" tugmasi (apparat/gesture) uchun: yoqilgan paytda `onBack` chaqiriladi.
/// Ichki ekranlar (masalan, Bosh ekrandan ochilgan Ota-ona paneli) shu bilan yopiladi — aks holda
/// tizim "orqaga"si ilovadan chiqarib yuborardi.
struct AndroidBackHandler: View {
    let onBack: () -> Void

    var body: some View {
        ComposeView { context in
            BackHandler(enabled: true) {
                onBack()
            }
        }
    }
}

/// Android uchun yengil top bar: sarlavha, chapda "orqaga" (ixtiyoriy), o'ngda OFFLINE/ONLINE yorlig'i.
///
/// Sabab: Android'da TabView ichida `NavigationStack` lifecycle konfliktiga olib keladi
/// (`FeaturePlaceholderView` dagi izohga qarang), shuning uchun Android ekranlari `NavigationStack`siz,
/// oddiy holat orqali almashadi va o'z top barini chizadi. iOS'da native navigatsiya paneli ishlatiladi.
struct AndroidScreenBar: View {
    let title: String
    let mode: LearningMode?
    /// `nil` bo'lsa, "orqaga" tugmasi ko'rsatilmaydi.
    var onBack: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Text(title)
                .ovStyle(.headline)
                .lineLimit(1)
                .padding(.horizontal, 90)

            HStack {
                if let onBack = onBack {
                    Button(action: { onBack() }) {
                        OvIcon(symbol: "arrow.left", size: 24, tint: Color.ovInk)
                            .foregroundStyle(Color.ovInk)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .ovPressShape(Circle())
                    .accessibilityLabel(Strings.Accessibility.back)
                }

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
}

// Eslatma: Android tizim "orqaga" tugmasi (apparat/gesture) hozircha faqat ekrandagi strelka
// tugmasi bilan almashtirilgan; tizim "orqaga"sini ushlash (`BackHandler`) Kotlin interop talab
// qiladi va bu bosqichda qo'shilmagan. Ya'ni hozircha tizim "orqaga"si yozish ekranidan ro'yxatga
// emas, TabView'ning "Bosh" tabiga olib boradi — funksional, lekin ideal emas.

#endif
