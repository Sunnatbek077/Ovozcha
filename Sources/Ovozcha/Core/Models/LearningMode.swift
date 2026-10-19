import SwiftUI

/// Bo'lim internet talab qiladimi yoki yo'qmi. Texnik spetsifikatsiyadagi arxitekturaga mos:
/// Harflar va Sonlar to'liq offline, Talaffuz murabbiyi serverga ulanadi.
// `public`: Skip'da `View.ovNavigationBar(title:mode:)` public funksiya bo'lib qoladi,
// shuning uchun uning parametr tipi ham public bo'lishi shart.
public enum LearningMode {
    case offline
    case online

    var title: String {
        switch self {
        case .offline: return Strings.Mode.offline
        case .online:  return Strings.Mode.online
        }
    }

    /// VoiceOver uchun tushunarli izoh. Rang va yozuv yolg'iz ma'no tashimasligi uchun ham kerak.
    var accessibilityLabel: String {
        switch self {
        case .offline: return Strings.Mode.offlineAccessibility
        case .online:  return Strings.Mode.onlineAccessibility
        }
    }

    /// SF Symbol: rangdan tashqari ikkinchi belgi (ranglarni ajrata olmaydigan foydalanuvchilar uchun).
    var symbol: String {
        switch self {
        case .offline: return "wifi.slash"
        case .online:  return "wifi"
        }
    }

    /// Asl brend rangi: faqat fon uchun (12% shaffoflikda).
    var brandColor: Color {
        switch self {
        case .offline: return .ovGreen
        case .online:  return .ovPurple
        }
    }

    /// To'q variant: matn va ikonka uchun (4.5:1 kontrast).
    var strongColor: Color {
        switch self {
        case .offline: return .ovGreenStrong
        case .online:  return .ovPurpleStrong
        }
    }
}
