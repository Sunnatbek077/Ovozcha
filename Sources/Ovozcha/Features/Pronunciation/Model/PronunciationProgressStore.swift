import Foundation
import Observation

/// Talaffuz darslarida bajarilgan mashqlar (UserDefaults, JSON matn). IOS va Android uchun umumiy.
///
/// "Bajarilgan": so'z bir marta to'g'ri aytilgan, quloq o'yinida to'g'risi tanlangan,
/// tovush/bo'g'in takrorlangan.
@MainActor
@Observable
final class PronunciationProgressStore {

    struct Snapshot: Codable {
        var done: [String] = []
    }

    private(set) var done: Set<String> = []

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let storageKey = "ovozcha.pronunciation.progress.v1"

    init(defaults: UserDefaults = UserDefaults.standard) {
        self.defaults = defaults
        load()
    }

    func isDone(_ item: LessonItem) -> Bool {
        return done.contains(item.id)
    }

    func doneCount(in items: [LessonItem]) -> Int {
        var count = 0
        for item in items {
            if done.contains(item.id) { count += 1 }
        }
        return count
    }

    func markDone(_ item: LessonItem) {
        if done.contains(item.id) { return }
        done.insert(item.id)
        save()
    }

    func resetAll() {
        done = []
        defaults.removeObject(forKey: storageKey)
    }

    // MARK: Saqlash

    private func load() {
        guard let text = StoredText.read(defaults, key: storageKey) else { return }
        guard let data = text.data(using: .utf8) else { return }
        guard let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        var loaded: Set<String> = []
        for id in snapshot.done {
            loaded.insert(id)
        }
        done = loaded
    }

    private func save() {
        let snapshot = Snapshot(done: done.sorted())
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        guard let text = String(data: data, encoding: .utf8) else { return }
        StoredText.write(defaults, key: storageKey, text: text)
    }
}
