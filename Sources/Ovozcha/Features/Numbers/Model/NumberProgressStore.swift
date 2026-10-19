import Foundation
import Observation

/// Sonlar bo'yicha natijalar: har son uchun eng yaxshi yulduz va kunlik mashq soni.
/// IOS va Android (Skip) uchun umumiy.
@MainActor
@Observable
final class NumberProgressStore {

    struct Snapshot: Codable {
        var stars: [String: Int] = [:]
        var dailyCounts: [String: Int] = [:]
    }

    private(set) var starsByNumber: [String: Int] = [:]
    private var dailyCounts: [String: Int] = [:]

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let storageKey = "ovozcha.numbers.progress.v1"
    private static let keptDays = 90

    init(defaults: UserDefaults = UserDefaults.standard, now: @escaping () -> Date = { Date() }) {
        self.defaults = defaults
        self.now = now
        load()
    }

    func stars(for number: NumberItem) -> Int {
        return starsByNumber[number.id] ?? 0
    }

    /// Son "o'rganilgan": kamida 1 yulduz.
    func isLearned(_ number: NumberItem) -> Bool {
        return stars(for: number) >= 1
    }

    var learnedCount: Int {
        var total = 0
        for number in UzbekNumbers.all {
            if isLearned(number) { total += 1 }
        }
        return total
    }

    /// 1 dan boshlab ketma-ket o'rganilgan sonlar oralig'i: "1", "1–4". Hech biri bo'lmasa "–".
    /// (Maketdagi "O'rganilgan: 1–4".)
    var learnedRangeText: String {
        var highest = 0
        for number in UzbekNumbers.all {
            if isLearned(number) {
                highest = number.value
            } else {
                break
            }
        }
        if highest == 0 { return Strings.Letters.noneLearned }
        if highest == 1 { return "1" }
        return "1–" + String(highest)
    }

    var todayCount: Int {
        return dailyCounts[LetterProgressStore.dayKey(for: now())] ?? 0
    }

    /// Natijani saqlaydi (eng yaxshi yulduz pasayib ketmaydi). Kunlik son har urinishda bir marta oshadi.
    func record(_ outcome: TraceOutcome) {
        if outcome.stars < 1 { return }
        if outcome.subject.kind != TraceKind.digit { return }
        let id = outcome.subject.id
        starsByNumber[id] = max(starsByNumber[id] ?? 0, outcome.stars)
        if outcome.isFirstSuccessInAttempt {
            let key = LetterProgressStore.dayKey(for: now())
            dailyCounts[key] = (dailyCounts[key] ?? 0) + 1
        }
        trimOldDays()
        save()
    }

    func resetAll() {
        starsByNumber = [:]
        dailyCounts = [:]
        defaults.removeObject(forKey: storageKey)
    }

    private func trimOldDays() {
        if dailyCounts.count <= NumberProgressStore.keptDays { return }
        let sortedKeys = dailyCounts.keys.sorted()
        let removeCount = sortedKeys.count - NumberProgressStore.keptDays
        for i in 0..<removeCount {
            dailyCounts.removeValue(forKey: sortedKeys[i])
        }
    }

    private func load() {
        guard let text = StoredText.read(defaults, key: storageKey) else { return }
        guard let data = text.data(using: .utf8) else { return }
        guard let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        starsByNumber = snapshot.stars
        dailyCounts = snapshot.dailyCounts
    }

    private func save() {
        let snapshot = Snapshot(stars: starsByNumber, dailyCounts: dailyCounts)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        guard let text = String(data: data, encoding: .utf8) else { return }
        StoredText.write(defaults, key: storageKey, text: text)
    }
}
