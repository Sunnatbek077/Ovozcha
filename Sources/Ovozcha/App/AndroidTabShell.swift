import SwiftUI

#if SKIP
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp

/// Android tab skeleti: yuqorida tanlangan tab ekrani, pastda Material 3 `NavigationBar`.
///
/// Nega SkipUI `TabView` emas — `RootTabView` dagi izohga qarang.
///
/// Muhim jihatlar:
///
/// - **Tezlik.** `router.selectedTab` faqat shu `ComposeView` ichida o'qiladi, shuning
///   uchun tab bosilganda butun SwiftUI daraxti emas, faqat shu joy qayta hisoblanadi.
/// - **Holat saqlanishi.** Har bir tab `SaveableStateProvider` ichida chiziladi, shuning
///   uchun boshqa tabga o'tib qaytganda ro'yxat pozitsiyasi va ekran holati (masalan,
///   qaysi harf ochiq ekani) saqlanadi — `TabView` dagidek.
/// - **"Orqaga" tugmasi.** Tizim tugmasi Bosh tabiga qaytaradi; Bosh tabida bo'lsa,
///   tizimning o'z xatti-harakati ishlaydi (ilovadan chiqish).
struct AndroidTabShell: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        ComposeView { context in
            let selected = router.selectedTab

            // Tizim "orqaga" tugmasi: boshqa tabdan Bosh tabiga qaytaramiz.
            BackHandler(enabled: selected != AppTab.home) {
                router.selectedTab = AppTab.home
            }

            let stateHolder = rememberSaveableStateHolder()

            // `ComposeContainer` — SkipUI ekranlarga o'lcham qoidalarini shu orqali beradi
            // (`fillWidth`/`fillHeight`). SkipUI'ning o'z `TabView`i ham tab mazmunini
            // xuddi shunday o'raydi, shuning uchun ekranlar bizning skeletimiz ostida ham
            // o'sha sharoitda chiziladi.
            ComposeContainer(modifier: context.modifier, fillWidth: true, fillHeight: true) { containerModifier in
                // Fon butun skelet ostida: tizim chizig'i (gesture bar) zonasi ham
                // krem rangda qolsin, pastda boshqa rangli tasma paydo bo'lmasin.
                Column(modifier: containerModifier.fillMaxSize().background(Color.ovBackground.asComposeColor())) {
                    Box(modifier: Modifier.weight(Float(1.0)).fillMaxWidth()) {
                        stateHolder.SaveableStateProvider(selected.rawValue) {
                            selected.screen.Compose(context.content())
                        }
                    }
                    RenderNavigationBar(selected: selected)
                }
            }
        }
    }

    /// Material 3 pastki paneli. Komponent native: to'lqin effekti (ripple), tanlash
    /// indikatori (pill) va tizim chetlari (window insets) Material'ning o'zidan.
    /// Biz faqat ikonka manbasi, shrift va brend ranglarini beramiz.
    @Composable private func RenderNavigationBar(selected: AppTab) {
        let androidContext = LocalContext.current

        // Poppins: butun ilovada shu shrift ishlatiladi, tab yorlig'i ham undan qolmasin.
        // Resurs id'si bir marta qidiriladi.
        let poppins = remember {
            let fontID = androidContext.resources.getIdentifier("poppins_medium", "font", androidContext.packageName)
            fontID == 0 ? nil : FontFamily(androidx.compose.ui.text.font.Font(fontID))
        }

        // Material'ning o'z yorliq uslubi (labelMedium: 12sp), faqat shrifti brendniki.
        var labelStyle = MaterialTheme.typography.labelMedium
        if let poppins {
            labelStyle = labelStyle.copy(fontFamily: poppins)
        }

        let itemColors = NavigationBarItemDefaults.colors(
            selectedIconColor: Color.ovPurpleStrong.asComposeColor(),
            selectedTextColor: Color.ovPurpleStrong.asComposeColor(),
            indicatorColor: Color.ovPurple.asComposeColor().copy(alpha: Float(0.22)),
            unselectedIconColor: Color.ovTextSecondary.asComposeColor(),
            unselectedTextColor: Color.ovTextSecondary.asComposeColor()
        )

        NavigationBar(containerColor: Color.ovBackground.asComposeColor()) {
            for tab in AppTab.allCases {
                let isSelected = tab == selected
                NavigationBarItem(
                    selected: isSelected,
                    onClick: {
                        if !isSelected {
                            router.selectedTab = tab
                        }
                    },
                    icon: {
                        RenderTabIcon(tab: tab, isSelected: isSelected, androidContext: androidContext)
                    },
                    label: {
                        androidx.compose.material3.Text(tab.title, style: labelStyle, maxLines: 1)
                    },
                    colors: itemColors
                )
            }
        }
    }

    /// Tab ikonkasi: `res/drawable/` dagi vektordan, aniq 24dp (Material standarti).
    ///
    /// Rang berilmaydi — uni o'rab turgan `NavigationBarItem` `LocalContentColor` orqali
    /// tanlangan/tanlanmagan holatga qarab o'zi beradi.
    ///
    /// SkipUI'ning `Image(systemName:)` va `Image(name:bundle:)` yo'llari ishlatilmaydi:
    /// birinchisi SF Symbol XML'idan har rekompozitsiyada yangi `ImageVector` quradi,
    /// ikkinchisi SVG'ni Coil bilan asinxron yuklaydi (panel avval bo'sh joy bilan
    /// chiziladi, keyin siljiydi). Android vektor resursi esa tizim tomonidan keshlanadi.
    @Composable private func RenderTabIcon(tab: AppTab, isSelected: Bool, androidContext: android.content.Context) {
        let name = isSelected ? tab.androidIconSelected : tab.androidIcon
        let resourceID = remember(name) {
            androidContext.resources.getIdentifier(name, "drawable", androidContext.packageName)
        }
        if resourceID != 0 {
            Icon(
                painter: painterResource(id: resourceID),
                contentDescription: nil,
                modifier: Modifier.size(24.dp)
            )
        }
    }
}
#endif
