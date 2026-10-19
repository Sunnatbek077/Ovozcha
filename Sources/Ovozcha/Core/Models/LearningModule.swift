import SwiftUI

/// Bosh ekrandagi uchta o'quv bo'limi.
enum LearningModule: CaseIterable, Identifiable {
    case letters
    case numbers
    case pronunciation

    var id: LearningModule { self }

    /// Bosilganda qaysi tabga o'tiladi.
    var tab: AppTab {
        switch self {
        case .letters:       return .letters
        case .numbers:       return .numbers
        case .pronunciation: return .pronunciation
        }
    }

    var title: String {
        switch self {
        case .letters:       return Strings.Module.lettersTitle
        case .numbers:       return Strings.Module.numbersTitle
        case .pronunciation: return Strings.Module.pronunciationTitle
        }
    }

    var subtitle: String {
        switch self {
        case .letters, .numbers: return Strings.Module.writeListenSpeak
        case .pronunciation:     return Strings.Module.pronunciationSubtitle
        }
    }

    var mode: LearningMode {
        switch self {
        case .letters, .numbers: return .offline
        case .pronunciation:     return .online
        }
    }

    /// Bo'lim rangi (PDF): Harflar yashil, Sonlar havorang, Talaffuz binafsha.
    /// Asl rang ikonka doirasining foni uchun.
    var brandColor: Color {
        switch self {
        case .letters:       return .ovGreen
        case .numbers:       return .ovSky
        case .pronunciation: return .ovPurple
        }
    }

    /// Ikonka rangi (kontrast uchun to'qroq variant).
    var strongColor: Color {
        switch self {
        case .letters:       return .ovGreenStrong
        case .numbers:       return .ovSkyStrong
        case .pronunciation: return .ovPurpleStrong
        }
    }
}
