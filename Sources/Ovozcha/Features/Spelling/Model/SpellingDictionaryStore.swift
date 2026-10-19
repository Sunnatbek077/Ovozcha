import Foundation
import Observation

/// Imlo lug'ati: internetdan bir marta yuklanadi, keyin telefon keshida turadi.
///
/// Manba — ochiq [uz-hunspell](https://github.com/u2b3k/uz-hunspell) lug'ati (GPL-3.0,
/// © Alisher Jalolov, Bilolbek Normoʻminov), 95 000 ga yaqin so'z. Ilova uni o'zi bilan olib
/// yurmaydi: birinchi qidiruvda jsDelivr CDN dan yuklaydi (siqilgan ~370 KB).
/// Manzil aniq versiyaga bog'langan — fayl hech qachon o'zgarmaydi, CDN uni cheksiz keshlaydi.
///
/// Keshda xom `.dic` emas, tayyor indeks saqlanadi (`SpellingIndex.serialize`): qayta ochilganda
/// normallashtirish va saralash takrorlanmaydi. Kesh `Caches` papkasida — tizim joy kerak bo'lsa
/// uni o'chirishi mumkin, u holda lug'at qayta yuklanadi.
///
/// Ilova bo'yicha bitta (`LearningStoresModifier`): tab almashganda qayta yuklanmaydi.
/// IOS va Android (Skip) uchun umumiy.
@MainActor
@Observable
final class SpellingDictionaryStore {

    enum State: Equatable {
        case idle
        case loading
        case ready
        /// Internet yo'q va keshda ham yo'q.
        case offline
        case failed
    }

    private(set) var state: State = .idle
    /// Kalit bo'yicha saralangan so'zlar.
    @ObservationIgnored private(set) var entries: [SpellingEntry] = []

    /// uz-hunspell versiyasi (git commit). Yangilash: shu qiymatni almashtiring — eski kesh
    /// fayli nomi boshqa bo'lgani uchun lug'at o'zi qayta yuklanadi.
    nonisolated static let version = "a27cccf4f7dd06734b0bc66d56ce759f9fc28b61"

    init() {
    }

    var wordCount: Int {
        return entries.count
    }

    /// Bo'lim ochilganda chaqiriladi. Yuklangan yoki yuklanayotgan bo'lsa, hech narsa qilmaydi.
    func loadIfNeeded() {
        if state == .loading || state == .ready { return }
        state = .loading
        Task {
            await load()
        }
    }

    // MARK: Ichki

    private func load() async {
        let cache = SpellingDictionaryStore.cacheFile()

        // Og'ir ish (fayl o'qish, tahlil) main thread'dan tashqarida.
        let cached = await Task.detached {
            return SpellingDictionaryStore.readCache(cache)
        }.value
        if !cached.isEmpty {
            entries = cached
            state = .ready
            return
        }

        do {
            var request = URLRequest(url: SpellingDictionaryStore.sourceURL(), timeoutInterval: NetworkErrors.requestTimeout)
            // Javob HTTP keshiga yozilmasin: aks holda lug'at telefonda ikki marta turadi
            // (Android'da OkHttp keshi ham, bizning indeksimiz ham). O'z keshimiz yetarli.
            request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                state = .failed
                return
            }
            let parsed = await Task.detached {
                return SpellingDictionaryStore.parseAndCache(data, to: cache)
            }.value
            if parsed.isEmpty {
                state = .failed
                return
            }
            entries = parsed
            state = .ready
        } catch {
            state = NetworkErrors.isOffline(error) ? .offline : .failed
        }
    }

    nonisolated static func sourceURL() -> URL {
        return URL(string: "https://cdn.jsdelivr.net/gh/u2b3k/uz-hunspell@" + version + "/uz_UZ.dic")!
    }

    nonisolated static func cacheFile() -> URL {
        let name = "uz_UZ-" + String(version.prefix(12)) + ".idx"
        return URL.cachesDirectory.appendingPathComponent("imlo").appendingPathComponent(name)
    }

    nonisolated static func readCache(_ url: URL) -> [SpellingEntry] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        guard let text = String(data: data, encoding: .utf8) else { return [] }
        return SpellingIndex.deserialize(text)
    }

    nonisolated static func parseAndCache(_ data: Data, to url: URL) -> [SpellingEntry] {
        guard let text = String(data: data, encoding: .utf8) else { return [] }
        let entries = SpellingIndex.parse(text)
        // Buzilgan/qisqa javob keshga yozilmaydi.
        if entries.count > 1000, let index = SpellingIndex.serialize(entries).data(using: .utf8) {
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? index.write(to: url)
        }
        return entries
    }
}
