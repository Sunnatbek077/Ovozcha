import Foundation
import Observation

/// Yozish mashqlarining qiyinligi. Ota-ona panelidan o'zgartiriladi.
enum WritingDifficulty: String, CaseIterable, Identifiable, Codable, Sendable {
    case normal
    case easy

    var id: String { return rawValue }

    var title: String {
        switch self {
        case .normal:
            return Strings.Parent.difficultyNormal
        case .easy:
            return Strings.Parent.difficultyEasy
        }
    }

    var tuning: TraceTuning {
        switch self {
        case .normal:
            return TraceTuning.normal
        case .easy:
            return TraceTuning.easy
        }
    }
}

/// Ilova sozlamalari (hozircha faqat yozish qiyinligi). IOS va Android (Skip) uchun umumiy.
@MainActor
@Observable
final class SettingsStore {

    private(set) var writingDifficulty: WritingDifficulty = WritingDifficulty.normal

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let storageKey = "ovozcha.settings.writingDifficulty.v1"

    init(defaults: UserDefaults = UserDefaults.standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: storageKey),
           let saved = WritingDifficulty(rawValue: raw) {
            writingDifficulty = saved
        }
    }

    func setWritingDifficulty(_ difficulty: WritingDifficulty) {
        writingDifficulty = difficulty
        defaults.set(difficulty.rawValue, forKey: storageKey)
    }

    func resetAll() {
        writingDifficulty = WritingDifficulty.normal
        defaults.removeObject(forKey: storageKey)
    }
}
