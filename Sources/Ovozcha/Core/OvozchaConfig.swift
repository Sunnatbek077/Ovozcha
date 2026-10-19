import Foundation

/// Ilova sozlamalari: maxfiy qiymatlar (API kaliti, server manzili) MANBA KODIDA saqlanmaydi.
///
/// Qayerga yoziladi:
/// - iOS:     `Darwin/Info.plist` — kalit nomi shu yerdagidek.
/// - Android: `Android/app/src/main/res/values/secrets.xml` ichida `<string name="...">`.
///
/// `secrets.xml` `.gitignore` da. `Info.plist` esa omborda kuzatiladi: unga kalit yozilsa,
/// commit qilmang (README, 5-qadam: `git update-index --skip-worktree`).
///
/// Skip eslatmasi: Android'da `Bundle.main.infoDictionary` faqat tizim sintez qilgan kalitlarni
/// (`CFBundleIdentifier` va h.k.) beradi, o'z kalitlarimizni emas. Shuning uchun Android'da
/// qiymat resurslardan o'qiladi.
enum OvozchaConfig {

    /// O'z serveringiz (proksi) manzili. ISHLAB CHIQARISH UCHUN SHU YO'L TAVSIYA ETILADI:
    /// kalit serverda qoladi, ilovada emas.
    static let transcriptionEndpointKey = "OvozchaTranscriptionEndpoint"

    /// Groq API kaliti — FAQAT ISHLAB CHIQISH (development) uchun.
    ///
    /// Ogohlantirish: ilovaga joylangan kalitni APK/IPA dan chiqarib olish mumkin.
    /// Do'konga chiqarishdan oldin bu yo'lni o'chirib, yuqoridagi proksiga o'ting.
    static let groqKeyKey = "OvozchaGroqKey"

    /// Berilgan kalit bo'yicha sozlama qiymati. Topilmasa yoki bo'sh bo'lsa `nil`.
    static func value(for key: String) -> String? {
        let raw: String?
        #if SKIP
        // Android: `res/values/*.xml` dagi string resursi (nomi kalit bilan bir xil).
        let context = ProcessInfo.processInfo.androidContext
        let identifier = context.resources.getIdentifier(key, "string", context.packageName)
        raw = identifier == 0 ? nil : context.resources.getString(identifier)
        #else
        raw = Bundle.main.object(forInfoDictionaryKey: key) as? String
        #endif

        guard let text = raw else { return nil }
        let trimmed = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
