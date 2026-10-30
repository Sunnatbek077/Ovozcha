import Foundation
import Observation

/// Dam olish jadvali vaqtlari. Sinov uchun `quick` ishlatish mumkin.
struct BreakTiming {
    /// Mashq boshlanganidan shuncha soniyadan keyin "Yana shug'ullanasizmi?" chiqadi.
    var checkInAfter: Double
    /// Mashq boshlanganidan shuncha soniyadan keyin majburiy dam boshlanadi.
    var breakAfter: Double
    /// Shundan uzoq mashqsiz o'tgan vaqt tabiiy dam hisoblanadi: 25 daqiqalik hisob noldan boshlanadi.
    var idleReset: Double
    /// 1-, 2-, 3-va undan keyingi damlarning uzunligi (soniya).
    var restSeconds: [Int]

    func restDuration(forBreak number: Int) -> Int {
        if restSeconds.isEmpty {
            return 60
        }
        let index = min(max(number, 1), restSeconds.count) - 1
        return restSeconds[index]
    }

    /// Haqiqiy jadval: 15 daqiqada savol, 25 daqiqada dam (1 → 2 → 5 daqiqa).
    static var standard: BreakTiming {
        return BreakTiming(
            checkInAfter: 15.0 * 60.0,
            breakAfter: 25.0 * 60.0,
            idleReset: 5.0 * 60.0,
            restSeconds: [60, 120, 300]
        )
    }

    /// Sinov uchun tezlashtirilgan jadval: 5 soniyada savol, 10 soniyada dam (5 → 8 → 12 soniya).
    static var quick: BreakTiming {
        return BreakTiming(
            checkInAfter: 5.0,
            breakAfter: 10.0,
            idleReset: 60.0,
            restSeconds: [5, 8, 12]
        )
    }
}

/// Bolaning ko'zi va diqqatini asrash: mashq vaqtini sanaydi va jadval bo'yicha to'xtatadi.
///
///  - 15 daqiqada pastdan "Yana shug'ullanasizmi?" (faqat "Ha" tugmasi).
///  - 25 daqiqada majburiy dam: 1-dam 1 daqiqa, 2-dam 2 daqiqa, 3-dam va keyingilari 5 daqiqa.
///  - Dam tugagach "Ko'proq mashq qilamizmi?" deb so'raydi, "Ha" bosilgach hisob noldan boshlanadi.
///
/// Vaqt faqat mashq ekrani ochiq va ilova faol bo'lganda sanaladi (`PracticeTimeModifier` xabar beradi).
/// Hisob, dam tartibi va dam qoldig'i `UserDefaults`da saqlanadi — ilovani yopib ochish bilan
/// dam qochib bo'lmaydi. Damlar tartibi har kuni noldan boshlanadi.
///
/// IOS va Android (Skip) uchun umumiy.
@MainActor
@Observable
final class BreakCoachStore {

    enum Phase: String, Sendable {
        /// Oddiy mashq.
        case practicing
        /// Majburiy dam: ekran yopiladi, sanagich ketadi.
        case resting
        /// Dam tugadi: "Ko'proq mashq qilamizmi?" javobini kutmoqda.
        case askMore
    }

    // MARK: Ochiq holat (ko'rinish shularni kuzatadi)

    private(set) var phase: Phase = Phase.practicing
    /// 15 daqiqalik "Yana shug'ullanasizmi?" ko'rinib turibdimi.
    private(set) var showCheckIn: Bool = false
    /// Damdan qolgan soniyalar.
    private(set) var restRemaining: Int = 0
    /// Joriy damning umumiy uzunligi (soniya).
    private(set) var restTotal: Int = 0
    /// Bugun nechanchi dam (dam paytida: joriy damning tartib raqami).
    private(set) var breakNumber: Int = 0

    // MARK: Ichki holat (ko'rinishni qayta chizmaydi)

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let timing: BreakTiming
    @ObservationIgnored private let storageKey = "ovozcha.breakcoach.v1"

    @ObservationIgnored private var day: String = ""
    @ObservationIgnored private var cycleSeconds: Double = 0.0
    @ObservationIgnored private var checkInShown: Bool = false
    @ObservationIgnored private var restEndsAt: Double = 0.0
    @ObservationIgnored private var lastActiveAt: Double = 0.0
    /// Hozir ochiq mashq ekranlari soni.
    @ObservationIgnored private var activeCount: Int = 0
    /// Sanoq ketayotgan bo'lsa, oxirgi hisoblangan payt.
    @ObservationIgnored private var activeSince: Date? = nil
    @ObservationIgnored private var ticksSinceSave: Int = 0

    /// Bir marta qo'shiladigan vaqt chegarasi (ilova to'xtab qolsa, soatlab yozilmasin).
    private static let maxFlushSeconds: Double = 60.0
    private static let saveEveryTicks: Int = 10

    init(
        defaults: UserDefaults = UserDefaults.standard,
        timing: BreakTiming = BreakTiming.standard,
        now: @escaping () -> Date = { Date() }
    ) {
        self.defaults = defaults
        self.timing = timing
        self.now = now
        load()
        rolloverIfNeeded()
        resolveRestAfterLaunch()
    }

    // MARK: Mashq ekranlari bildirishnomasi

    /// Mashq ekrani ochildi (ilova faol).
    func sessionBegan() {
        rolloverIfNeeded()
        activeCount += 1
        if activeCount == 1 && phase == Phase.practicing {
            let t = now()
            let gap = t.timeIntervalSince1970 - lastActiveAt
            if lastActiveAt > 0.0 && gap >= timing.idleReset {
                // Uzoq tanaffus bo'lgan: bola o'zi dam olgan, hisob noldan.
                cycleSeconds = 0.0
                checkInShown = false
            }
            activeSince = t
        }
    }

    /// Mashq ekrani yopildi yoki ilova fonga o'tdi.
    func sessionEnded() {
        if activeCount > 0 {
            activeCount -= 1
        }
        if activeCount == 0 && activeSince != nil {
            flush(now())
            activeSince = nil
            save()
        }
    }

    // MARK: Soat

    /// Har soniyada chaqiriladi.
    func tick() {
        let t = now()
        switch phase {
        case .practicing:
            tickPracticing(t)
        case .resting:
            tickResting(t)
        case .askMore:
            break
        }
    }

    /// Tepadagi `task` ichida soatni yuritadi; ko'rinish yo'qolsa, avtomatik to'xtaydi.
    func runClock() async {
        do {
            while true {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                tick()
            }
        } catch {
            // Bekor qilindi.
        }
    }

    // MARK: Javoblar

    /// 15 daqiqalik savolga "Ha".
    func confirmCheckIn() {
        showCheckIn = false
        save()
    }

    /// Damdan keyingi "Ko'proq mashq qilamizmi?" savoliga "Ha".
    func continuePracticing() {
        if phase != Phase.askMore { return }
        cycleSeconds = 0.0
        checkInShown = false
        showCheckIn = false
        restRemaining = 0
        restEndsAt = 0.0
        lastActiveAt = now().timeIntervalSince1970
        phase = Phase.practicing
        save()
    }

    // MARK: Ichki

    private func tickPracticing(_ t: Date) {
        if activeSince == nil { return }
        flush(t)
        if cycleSeconds >= timing.breakAfter {
            startRest(t)
            return
        }
        if !checkInShown && cycleSeconds >= timing.checkInAfter {
            checkInShown = true
            showCheckIn = true
            save()
            return
        }
        ticksSinceSave += 1
        if ticksSinceSave >= BreakCoachStore.saveEveryTicks {
            ticksSinceSave = 0
            save()
        }
    }

    private func tickResting(_ t: Date) {
        let remaining = restEndsAt - t.timeIntervalSince1970
        if remaining <= 0.0 {
            restRemaining = 0
            phase = Phase.askMore
            save()
        } else {
            let seconds = BreakCoachStore.wholeSeconds(roundingUp: remaining)
            if seconds != restRemaining {
                restRemaining = seconds
            }
        }
    }

    private func startRest(_ t: Date) {
        breakNumber += 1
        restTotal = timing.restDuration(forBreak: breakNumber)
        restRemaining = restTotal
        restEndsAt = t.timeIntervalSince1970 + Double(restTotal)
        showCheckIn = false
        activeSince = nil
        phase = Phase.resting
        save()
    }

    /// Oxirgi hisobdan beri o'tgan vaqtni siklga qo'shadi.
    private func flush(_ t: Date) {
        guard let since = activeSince else { return }
        let elapsed = max(0.0, min(t.timeIntervalSince(since), BreakCoachStore.maxFlushSeconds))
        cycleSeconds += elapsed
        activeSince = t
        lastActiveAt = t.timeIntervalSince1970
    }

    /// Yangi kun: damlar tartibi va hisob noldan. Dam yoki savol ochiq bo'lsa, u tugaguncha kutiladi.
    private func rolloverIfNeeded() {
        let key = LetterProgressStore.dayKey(for: now())
        if key == day { return }
        if phase != Phase.practicing { return }
        day = key
        breakNumber = 0
        cycleSeconds = 0.0
        checkInShown = false
        showCheckIn = false
        save()
    }

    /// Ilova dam paytida yopilib, qayta ochilgan bo'lishi mumkin: qolgan vaqtni tiklaydi.
    private func resolveRestAfterLaunch() {
        if phase != Phase.resting { return }
        restTotal = timing.restDuration(forBreak: breakNumber)
        let remaining = restEndsAt - now().timeIntervalSince1970
        if remaining <= 0.0 {
            restRemaining = 0
            phase = Phase.askMore
            save()
        } else {
            restRemaining = BreakCoachStore.wholeSeconds(roundingUp: remaining)
        }
    }

    /// Yuqoriga yaxlitlaydi (`ceil` o'rniga: Skip'da aniq ishlashi uchun faqat `Int(_:)` ishlatiladi).
    private static func wholeSeconds(roundingUp value: Double) -> Int {
        let whole = Int(value)
        if Double(whole) < value {
            return whole + 1
        }
        return whole
    }

    /// Holat bitta matn qatori sifatida saqlanadi: "v1|kun|damlar|sikl|savol|faza|damTugashi|oxirgiFaollik".
    /// JSON/`utf8` ishlatilmaydi: Skip (Android) ularni bu joyda aniqlay olmay xato bergan edi.
    private func load() {
        guard let text = StoredText.read(defaults, key: storageKey) else { return }
        let parts = text.components(separatedBy: "|")
        if parts.count != 8 { return }
        if parts[0] != "v1" { return }
        guard let breaks = Int(parts[2]) else { return }
        guard let cycle = Double(parts[3]) else { return }
        guard let ends = Double(parts[6]) else { return }
        guard let last = Double(parts[7]) else { return }
        guard let savedPhase = Phase(rawValue: parts[5]) else { return }
        day = parts[1]
        breakNumber = breaks
        cycleSeconds = cycle
        checkInShown = parts[4] == "1"
        phase = savedPhase
        restEndsAt = ends
        lastActiveAt = last
    }

    private func save() {
        let fields: [String] = [
            "v1",
            day,
            String(breakNumber),
            String(cycleSeconds),
            checkInShown ? "1" : "0",
            phase.rawValue,
            String(restEndsAt),
            String(lastActiveAt)
        ]
        StoredText.write(defaults, key: storageKey, text: fields.joined(separator: "|"))
    }
}
