import SwiftUI

#if SKIP
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
#endif

/// Statistika kartalarini teng kenglikda yonma-yon joylashtiradi.
///
/// Nega alohida ko'rinish kerak: oddiy `HStack` Android'da ishlamaydi. SkipUI
/// moslashuvchan kenglikni (`frame(maxWidth: .infinity)`) maxsus mexanizm bilan
/// tarqatadi, lekin `ComposeContainer` uni o'z bolalari uchun tozalaydi
/// (`ComposeContainer.swift` dagi `set_flexibleWidthModifier(nil)`). `StatCard` ustidagi
/// `.ovCard` fon va chegara uchun o'z konteynerini yaratgani uchun ulush kartagacha
/// yetib bormaydi: har bir karta o'zi xohlagan kenglikni oladi va qator ekrandan
/// chiqib ketadi (uchta kartadan faqat bittasi ko'rinardi).
///
/// Shuning uchun Android'da Compose `Row` va `weight` to'g'ridan-to'g'ri ishlatiladi.
/// iOS'da oddiy `HStack` yetarli.
struct StatCardRow: View {
    let cards: [StatCard]

    var body: some View {
        #if SKIP
        ComposeView { context in
            Row(
                modifier: context.modifier.fillMaxWidth(),
                horizontalArrangement: Arrangement.spacedBy(Theme.Spacing.m.dp),
                verticalAlignment: androidx.compose.ui.Alignment.Top
            ) {
                for card in cards {
                    // `weight(1f)` — barcha kartalar bo'sh joyni teng bo'lishadi.
                    card.Compose(context.content(modifier: Modifier.weight(Float(1.0))))
                }
            }
        }
        #else
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            ForEach(Array(cards.indices), id: \.self) { index in
                cards[index]
            }
        }
        #endif
    }
}
