import SwiftUI
import Observation

/// Bola profili: ismi. Ism qurilmada (`UserDefaults`) saqlanadi va ilova birinchi
/// ochilganda `SetupView` orqali so'raladi (ismsiz ilovaga kirib bo'lmaydi).
///
/// IOS va Android (Skip) uchun umumiy.
@MainActor
@Observable
final class ProfileStore {

    /// Bo'sh satr — ism hali kiritilmagan degani.
    private(set) var childName: String = ""

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let storageKey = "ovozcha.profile.v1"

    /// Bosh ekrandagi sarlavhaga sig'ishi uchun chegara.
    static let maxNameLength = 20

    init(defaults: UserDefaults = UserDefaults.standard) {
        self.defaults = defaults
        childName = ProfileStore.normalized(StoredText.read(defaults, key: storageKey) ?? "")
    }

    /// Ism kiritilganmi. `false` bo'lsa, ilova `SetupView` ni ko'rsatadi.
    var isSetUp: Bool {
        return !childName.isEmpty
    }

    /// Ismni tekshirib saqlaydi. Bo'sh (yoki faqat bo'shliqdan iborat) bo'lsa,
    /// hech narsa saqlanmaydi va `false` qaytadi.
    @discardableResult
    func setName(_ raw: String) -> Bool {
        let name = ProfileStore.normalized(raw)
        if name.isEmpty {
            return false
        }
        childName = name
        StoredText.write(defaults, key: storageKey, text: name)
        return true
    }

    /// "Progressni tozalash" ismga tegmaydi — buni faqat sinov va alohida tozalash ishlatadi.
    func resetAll() {
        childName = ""
        defaults.removeObject(forKey: storageKey)
    }

    /// Chetdagi bo'shliqlarni olib tashlaydi va uzunligini cheklaydi.
    static func normalized(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if trimmed.count <= maxNameLength {
            return trimmed
        }
        var result = ""
        var taken = 0
        for character in trimmed {
            if taken >= maxNameLength { break }
            // `append(Character)` Skip'da yo'q; birlashtirish ikkala platformada ham ishlaydi.
            result = result + String(character)
            taken += 1
        }
        return result
    }
}
