import SwiftUI


/// Butun ilova bo'yicha bo'lishiladigan ombor va pleyerlarni `environment` orqali beradi.
/// Bir joyda yaratiladi, shunda Harflar, Sonlar, Talaffuz va Ota-ona paneli bir xil ma'lumotni ko'radi
/// (masalan, panel "progressni tozalash" desa, hamma joyda tozalanadi).
///
/// IOS va Android (Skip) uchun umumiy.
@MainActor
struct LearningStoresModifier: ViewModifier {
    @State private var activity: ActivityStore
    @State private var settings: SettingsStore
    @State private var letters: LetterProgressStore
    @State private var numbers: NumberProgressStore
    @State private var pronunciation: PronunciationProgressStore
    @State private var spelling: SpellingDictionaryStore
    @State private var audio: LetterAudioPlayer
    @State private var breakCoach: BreakCoachStore

    /// `defaults`: Preview'larda alohida (`suiteName`) to'plam berilib, haqiqiy ma'lumot buzilmaydi.
    init(defaults: UserDefaults = UserDefaults.standard) {
        _activity = State(initialValue: ActivityStore(defaults: defaults))
        _settings = State(initialValue: SettingsStore(defaults: defaults))
        _letters = State(initialValue: LetterProgressStore(defaults: defaults))
        _numbers = State(initialValue: NumberProgressStore(defaults: defaults))
        _pronunciation = State(initialValue: PronunciationProgressStore(defaults: defaults))
        _spelling = State(initialValue: SpellingDictionaryStore())
        _audio = State(initialValue: LetterAudioPlayer())

        // Haqiqiy jadval: 15 daqiqada savol, 25 daqiqada dam.
        // Sinash uchun `BreakTiming.quick` (5 / 10 soniya) ishlating.
        _breakCoach = State(initialValue: BreakCoachStore(defaults: defaults, timing: BreakTiming.standard))
    }

    func body(content: Content) -> some View {
        content
            // Dam olish: pastdan chiqadigan savol va majburiy dam ekrani butun ilova ustida.
            // `environment`dan OLDIN turishi shart, shunda overlay ham ombordan foydalanadi.
            .overlay { BreakCoachOverlay() }
            .task { await breakCoach.runClock() }
            .environment(breakCoach)
            .environment(activity)
            .environment(settings)
            .environment(letters)
            .environment(numbers)
            .environment(pronunciation)
            .environment(spelling)
            .environment(audio)
    }
}
