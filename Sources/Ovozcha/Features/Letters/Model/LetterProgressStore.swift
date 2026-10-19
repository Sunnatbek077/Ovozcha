import Foundation
import Observation

/// Harflar bo'yicha natijalarni saqlaydi (UserDefaults, JSON matn).
///
/// 5-bosqichda umumiy `ProgressStore` (SwiftData) bilan birlashtiriladi; hozircha shu kichik va
/// mustaqil ombor yetarli: harf boshiga ikki shakl (bosh/kichik) uchun eng yaxshi yulduz soni,
/// kunlik mashqlar soni va oxirgi o'rganilgan harf.
///
/// IOS va Android (Skip) uchun umumiy.
@MainActor
@Observable
final class LetterProgressStore {

    // MARK: Saqlanadigan ma'lumot

    struct Record: Codable, Equatable {
        var upperStars: Int = 0
        var lowerStars: Int = 0
    }

    struct Snapshot: Codable {
        var records: [String: Record] = [:]
        /// "2026-09-21" -> shu kuni bajarilgan muvaffaqiyatli mashqlar soni.
        var dailyCounts: [String: Int] = [:]
        var lastLearnedID: String?
    }

    // MARK: Ochiq holat (UI shuni kuzatadi)

    private(set) var records: [String: Record] = [:]
    private(set) var lastLearnedID: String?
    private var dailyCounts: [String: Int] = [:]

    // MARK: Ichki

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let storageKey = "ovozcha.letters.progress.v1"

    /// Kunlik hisobda ushlab turiladigan kunlar (eskilari o'chiriladi).
    private static let keptDays = 90

    init(defaults: UserDefaults = UserDefaults.standard, now: @escaping () -> Date = { Date() }) {
        self.defaults = defaults
        self.now = now
        load()
    }

    // MARK: So'rovlar

    func stars(for letter: UzbekLetter, style: LetterCase) -> Int {
        let record = records[letter.id] ?? Record()
        switch style {
        case .upper:
            return record.upperStars
        case .lower:
            return record.lowerStars
        }
    }

    /// Harf "o'rganilgan": ikkala shakli ham kamida 1 yulduz olgan.
    func isLearned(_ letter: UzbekLetter) -> Bool {
        let record = records[letter.id] ?? Record()
        return record.upperStars >= 1 && record.lowerStars >= 1
    }

    var learnedCount: Int {
        var total = 0
        for letter in UzbekAlphabet.letters {
            if isLearned(letter) { total += 1 }
        }
        return total
    }

    var lastLearnedLetter: UzbekLetter? {
        guard let id = lastLearnedID else { return nil }
        return UzbekAlphabet.letter(id: id)
    }

    /// Bugun bajarilgan muvaffaqiyatli mashqlar soni.
    var todayCount: Int {
        return dailyCounts[LetterProgressStore.dayKey(for: now())] ?? 0
    }

    // MARK: Yozish

    /// Natijani saqlaydi. Eng yaxshi yulduz soni saqlanadi (pasayib ketmaydi).
    /// Mashq soni faqat har urinishdagi birinchi muvaffaqiyat uchun oshadi.
    func record(_ outcome: TraceOutcome) {
        if outcome.stars < 1 { return }
        guard let letter = UzbekAlphabet.letter(id: outcome.letterID) else { return }

        let wasLearned = isLearned(letter)
        var record = records[letter.id] ?? Record()
        switch outcome.style {
        case .upper:
            record.upperStars = max(record.upperStars, outcome.stars)
        case .lower:
            record.lowerStars = max(record.lowerStars, outcome.stars)
        }
        records[letter.id] = record

        if outcome.isFirstSuccessInAttempt {
            let key = LetterProgressStore.dayKey(for: now())
            dailyCounts[key] = (dailyCounts[key] ?? 0) + 1
        }
        if !wasLearned && isLearned(letter) {
            lastLearnedID = letter.id
        }
        trimOldDays()
        save()
    }

    /// Sinov va "hammasini tozalash" uchun.
    func resetAll() {
        records = [:]
        dailyCounts = [:]
        lastLearnedID = nil
        defaults.removeObject(forKey: storageKey)
    }

    // MARK: Saqlash

    private func load() {
        guard let text = StoredText.read(defaults, key: storageKey) else { return }
        guard let data = text.data(using: .utf8) else { return }
        guard let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        records = snapshot.records
        dailyCounts = snapshot.dailyCounts
        lastLearnedID = snapshot.lastLearnedID
    }

    private func save() {
        let snapshot = Snapshot(records: records, dailyCounts: dailyCounts, lastLearnedID: lastLearnedID)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        guard let text = String(data: data, encoding: .utf8) else { return }
        StoredText.write(defaults, key: storageKey, text: text)
    }

    private func trimOldDays() {
        if dailyCounts.count <= LetterProgressStore.keptDays { return }
        let sortedKeys = dailyCounts.keys.sorted()
        let removeCount = sortedKeys.count - LetterProgressStore.keptDays
        for i in 0..<removeCount {
            dailyCounts.removeValue(forKey: sortedKeys[i])
        }
    }

    /// "yyyy-MM-dd" (qurilmaning joriy kalendari va vaqt mintaqasi bo'yicha).
    static func dayKey(for date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return pad(year, 4) + "-" + pad(month, 2) + "-" + pad(day, 2)
    }

    private static func pad(_ value: Int, _ width: Int) -> String {
        var text = String(value)
        while text.count < width {
            text = "0" + text
        }
        return text
    }
}
