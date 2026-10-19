import SwiftUI

#if SKIP
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
#endif

/// Ikonka: iOS'da SF Symbol, Android'da `res/drawable/` ichidagi vektor ikonka.
///
/// Nega shunday: Skip'ning `Image(systemName:)` va `Image(_:bundle:)` Android'da qimmat.
/// Birinchisi SF Symbol XML faylini o'qib, har bir qayta chizishda `ImageVector` ni
/// qaytadan yig'adi; ikkinchisi SVG ni Coil orqali **asinxron** yuklaydi, ya'ni ikonka
/// kechikib paydo bo'ladi va layout sakraydi. Tab panelida beshta ikonka bir vaqtda
/// shu yo'ldan o'tardi — tab almashishi shuning uchun sekin edi.
///
/// Buning o'rniga Android'ning o'z vektor ikonkasi (`VectorDrawable`) ishlatiladi:
/// tizim uni o'zi tahlil qilib keshlaydi, `painterResource` esa sinxron qaytaradi.
/// Ikonka fayllari: `Android/app/src/main/res/drawable/ov_*.xml`.
struct OvIcon: View {
    /// SF Symbol nomi (masalan `mic`).
    let symbol: String
    /// Faqat Android'dagi vektor ikonkalar uchun o'lcham (pt). iOS'da o'lchamni `font` belgilaydi.
    var size: CGFloat = 20
    /// Faqat Android: ikonka rangi. `nil` bo'lsa, Compose'ning joriy kontent rangi
    /// (`LocalContentColor`) olinadi — tab panelida Material 3 tanlangan/tanlanmagan
    /// rangni o'zi beradi. iOS'da rang oldingidek `.foregroundStyle` orqali beriladi.
    var tint: Color? = nil

    var body: some View {
        #if SKIP
        ComposeView { context in
            let resourceID = OvIcon.drawableID(for: symbol, ctx: LocalContext.current)
            if resourceID != 0 {
                Icon(
                    painter: painterResource(id: resourceID),
                    contentDescription: nil,
                    modifier: context.modifier.size(size.dp),
                    tint: tint?.asComposeColor() ?? LocalContentColor.current
                )
            }
        }
        #else
        Image(systemName: symbol)
        #endif
    }

    #if SKIP
    /// `getIdentifier` qidiruvi arzon emas, shuning uchun natija keshlanadi
    /// (SkipUI shriftlarni ham shunday keshlaydi).
    private static var drawableIDs: [String: Int] = [:]

    private static func drawableID(for symbol: String, ctx: android.content.Context) -> Int {
        guard let name = OvIcon.androidDrawable(for: symbol) else {
            return 0
        }
        var identifier: Int? = nil
        synchronized(drawableIDs) {
            identifier = drawableIDs[name]
        }
        if let identifier {
            return identifier
        }
        let resolved = ctx.resources.getIdentifier(name, "drawable", ctx.packageName)
        if resolved == 0 {
            android.util.Log.w("Ovozcha", "ikonka topilmadi: \(name)")
        }
        synchronized(drawableIDs) {
            drawableIDs[name] = resolved
        }
        return resolved
    }

    /// SF Symbol nomi -> `res/drawable/` dagi vektor ikonka nomi.
    private static func androidDrawable(for symbol: String) -> String? {
        switch symbol {
        case "house":                      return "ov_home"
        case "person":                     return "ov_person"
        case "pencil.line":                return "ov_pencil_line"
        case "textformat.123":             return "ov_numbers"
        case "mic":                        return "ov_mic"
        case "wifi":                       return "ov_wifi"
        case "wifi.slash":                 return "ov_wifi_slash"
        case "speaker.wave.2.fill":        return "ov_volume_up"
        case "arrow.counterclockwise":     return "ov_replay"
        case "arrow.right":                return "ov_arrow_forward"
        case "square.grid.2x2":            return "ov_grid_view"
        case "star.fill":                  return "ov_star"
        case "star":                       return "ov_star_border"
        case "scribble.variable":          return "ov_center_focus"
        case "hand.point.up.left.fill":    return "ov_touch_app"
        case "trash":                      return "ov_delete"
        case "arrow.left":                 return "ov_arrow_back"
        case "stop.fill":                  return "ov_stop"
        case "play.fill":                  return "ov_play"
        case "checkmark":                  return "ov_check"
        case "magnifyingglass":            return "ov_search"
        case "xmark.circle.fill":          return "ov_cancel"
        case "character.book.closed":      return "ov_book"
        default:                           return nil
        }
    }
    #endif
}
