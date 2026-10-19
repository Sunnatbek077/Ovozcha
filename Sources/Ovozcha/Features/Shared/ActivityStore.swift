import Foundation
import Observation

/// Bolaning faoliyat tarixi: bugungi mashq vaqti, ketma-ket kunlar, so'nggi mashqlar va talaffuz
/// aniqligi. Ota-ona paneli va Bosh ekrandagi "ketma-ket kun" shuni o'qiydi.
///
/// UserDefaults'da (JSON matn). Keyinroq umumiy SwiftData omboriga ko'chiriladi.
/// IOS va Android (Skip) uchun umumiy.
@MainActor
@Observable
final class ActivityStore {

    enum Kind: String, Codable, Sendable {
        case letter
        case number
        case pronunciation
    }

    struct Entry: Codable, Equatable, Identifiable {
        var id: String
        /// Vaqt (1970-yildan beri soniyalarda).
        var timestamp: Double
        var kind: Kind
        /// Harf ("B"), raqam ("5") yoki so'z ("olma").
        var subject: String
        /// Yozish mashqlari uchun yulduz (1...3).
        var stars: Int?
        /// Talaffuz uchun aniqlik (0...1).
        var score: Double?
    }

    struct Day: Codable, Equatable {
        var seconds: Double = 0.0
        var successes: Int = 0
    }

    struct Snapshot: Codable {
        var days: [String: Day] = [:]
        var recent: [Entry] = []
        var scores: [Double] = []
    }

    // MARK: Ochiq holat

    private(set) var days: [String: Day] = [:]
    private(set) var recent: [Entry] = []
    /// Oxirgi talaffuz baholari (0...1).
    private(set) var pronunciationScores: [Double] = []

    // MARK: Ichki

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let storageKey = "ovozcha.activity.v1"

    /// Ketma-ket kunlarni hisoblash uchun ushlab turiladigan kunlar.
    private static let keptDays = 400
    private static let keptEntries = 20
    private static let keptScores = 20
    /// Bir marta qo'shiladigan mashq vaqti chegarasi (ekran ochiq qolib ketsa, soatlab yozilmasin).
    private static let maxSecondsPerChunk: Double = 900.0
    /// Shu vaqt ichida bir xil narsani takrorlash ro'yxatda yangi qator ochmaydi.
    private static let coalesceWindow: Double = 600.0

    init(defaults: UserDefaults = UserDefaults.standard, now: @escaping () -> Date = { Date() }) {
        self.defaults = defaults
        self.now = now
        load()
    }

    // MARK: So'rovlar

    private var todayKey: String {
        return LetterProgressStore.dayKey(for: now())
    }

    /// Bugungi mashq vaqti, daqiqada.
    var todayMinutes: Int {
        let seconds = days[todayKey]?.seconds ?? 0.0
        return Int((seconds / 60.0).rounded())
    }

    /// Ketma-ket mashq qilingan kunlar. Bugun hali mashq qilinmagan bo'lsa, kechagi kungacha
    /// bo'lgan seriya saqlanib turadi (kun tugamaguncha uzilmaydi).
    var streakDays: Int {
        let calendar = Calendar.current
        var day = now()
        var count = 0
        var isToday = true
        while count <= ActivityStore.keptDays {
            let successes = days[LetterProgressStore.dayKey(for: day)]?.successes ?? 0
            if successes > 0 {
                count += 1
            } else if !isToday {
                break
            }
            isToday = false
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    /// Bitta kun: Bosh ekrandagi haftalik chiziq shuni chizadi.
    struct DayMark: Identifiable, Equatable {
        /// "yyyy-MM-dd".
        var id: String
        /// Hafta kunining qisqa nomi ("Du", "Se", ...).
        var label: String
        /// Shu kuni kamida bitta mashq bajarilganmi.
        var isActive: Bool
        var isToday: Bool
    }

    /// Oxirgi `count` kun, eng eskisidan bugungacha (Bosh ekrandagi haftalik chiziq uchun).
    func recentDays(_ count: Int) -> [DayMark] {
        let calendar = Calendar.current
        let today = now()
        var marks: [DayMark] = []
        var offset = count - 1
        while offset >= 0 {
            guard let date = calendar.date(byAdding: Calendar.Component.day, value: -offset, to: today) else {
                break
            }
            let key = LetterProgressStore.dayKey(for: date)
            let weekday = calendar.component(Calendar.Component.weekday, from: date)
            marks.append(DayMark(
                id: key,
                label: ActivityStore.weekdayLabel(weekday),
                isActive: (days[key]?.successes ?? 0) > 0,
                isToday: offset == 0
            ))
            offset -= 1
        }
        return marks
    }

    /// `Calendar` hafta kuni raqami (1 = yakshanba) -> o'zbekcha qisqa nom.
    private static func weekdayLabel(_ weekday: Int) -> String {
        switch weekday {
        case 1:  return "Ya"
        case 2:  return "Du"
        case 3:  return "Se"
        case 4:  return "Cho"
        case 5:  return "Pay"
        case 6:  return "Ju"
        default: return "Sha"
        }
    }

    /// Talaffuz aniqligi, foizda (oxirgi baholarning o'rtachasi). Hali baho bo'lmasa `nil`.
    var pronunciationAccuracyPercent: Int? {
        if pronunciationScores.isEmpty { return nil }
        var total = 0.0
        for score in pronunciationScores {
            total += score
        }
        let average = total / Double(pronunciationScores.count)
        return Int((average * 100.0).rounded())
    }

    // MARK: Yozish

    /// Muvaffaqiyatli yozish mashqi (harf yoki raqam).
    func logPractice(kind: Kind, subject: String, stars: Int) {
        let entry = Entry(
            id: UUID().uuidString,
            timestamp: now().timeIntervalSince1970,
            kind: kind,
            subject: subject,
            stars: stars,
            score: nil
        )
        addEntry(entry)
        countSuccessToday()
        save()
    }

    /// Talaffuz mashqi va uning aniqligi (0...1).
    func logPronunciation(word: String, score: Double) {
        let clamped = min(max(score, 0.0), 1.0)
        let entry = Entry(
            id: UUID().uuidString,
            timestamp: now().timeIntervalSince1970,
            kind: Kind.pronunciation,
            subject: word,
            stars: nil,
            score: clamped
        )
        addEntry(entry)
        pronunciationScores.append(clamped)
        if pronunciationScores.count > ActivityStore.keptScores {
            var trimmed: [Double] = []
            let start = pronunciationScores.count - ActivityStore.keptScores
            for i in start..<pronunciationScores.count {
                trimmed.append(pronunciationScores[i])
            }
            pronunciationScores = trimmed
        }
        countSuccessToday()
        save()
    }

    /// Mashq ekrani ochiq bo'lgan vaqt.
    func addPracticeTime(seconds: Double) {
        if seconds <= 0.0 { return }
        let chunk = min(seconds, ActivityStore.maxSecondsPerChunk)
        let key = todayKey
        var day = days[key] ?? Day()
        day.seconds += chunk
        days[key] = day
        trimOldDays()
        save()
    }

    func resetAll() {
        days = [:]
        recent = []
        pronunciationScores = []
        defaults.removeObject(forKey: storageKey)
    }

    // MARK: Ichki yordamchilar

    private func addEntry(_ entry: Entry) {
        var list = recent
        if list.count > 0 {
            let first = list[0]
            if first.kind == entry.kind
                && first.subject == entry.subject
                && entry.timestamp - first.timestamp < ActivityStore.coalesceWindow {
                // Bir xil narsani ketma-ket mashq qilish: yangi qator o'rniga oxirgisini yangilaymiz.
                var merged = entry
                merged.id = first.id
                if let a = first.stars, let b = entry.stars {
                    merged.stars = max(a, b)
                }
                list[0] = merged
                recent = list
                return
            }
        }
        list.insert(entry, at: 0)
        if list.count > ActivityStore.keptEntries {
            var kept: [Entry] = []
            for i in 0..<ActivityStore.keptEntries {
                kept.append(list[i])
            }
            list = kept
        }
        recent = list
    }

    private func countSuccessToday() {
        let key = todayKey
        var day = days[key] ?? Day()
        day.successes += 1
        days[key] = day
        trimOldDays()
    }

    private func trimOldDays() {
        if days.count <= ActivityStore.keptDays { return }
        let sortedKeys = days.keys.sorted()
        let removeCount = sortedKeys.count - ActivityStore.keptDays
        for i in 0..<removeCount {
            days.removeValue(forKey: sortedKeys[i])
        }
    }

    private func load() {
        guard let text = StoredText.read(defaults, key: storageKey) else { return }
        guard let data = text.data(using: .utf8) else { return }
        guard let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        days = snapshot.days
        recent = snapshot.recent
        pronunciationScores = snapshot.scores
    }

    private func save() {
        let snapshot = Snapshot(days: days, recent: recent, scores: pronunciationScores)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        guard let text = String(data: data, encoding: .utf8) else { return }
        StoredText.write(defaults, key: storageKey, text: text)
    }
}
