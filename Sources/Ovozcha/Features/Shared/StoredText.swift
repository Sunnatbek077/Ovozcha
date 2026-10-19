import Foundation

/// Kichik omborlar (progress, faoliyat, sozlamalar) ma'lumotni JSON MATN sifatida `UserDefaults`ga yozadi.
///
/// Matn (`String`) ikkala platformada ham eng ishonchli tur. Eski iOS versiyalar JSON'ni `Data` sifatida
/// yozgan edi: iOS'da u o'qilib, keyingi saqlashda matnga aylanadi (ma'lumot yo'qolmaydi).
enum StoredText {

    static func read(_ defaults: UserDefaults, key: String) -> String? {
        if let text = defaults.string(forKey: key) {
            return text
        }
        #if !SKIP
        if let data = defaults.data(forKey: key), let text = String(data: data, encoding: .utf8) {
            return text
        }
        #endif
        return nil
    }

    static func write(_ defaults: UserDefaults, key: String, text: String) {
        defaults.set(text, forKey: key)
    }
}
