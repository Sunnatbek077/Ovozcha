import SwiftUI

/// 2-ekran (PDF): "Harf yozish". Katta ko'rsatma harf, uning ustidan barmoq bilan yuriladi.
///
/// Tuzilishi maketdagidek: yuqorida bosh/kichik tanlagich, o'rtada oq karta (chizish tuvali + tovush
/// tugmasi), pastda ikki statistika kartasi va amal tugmalari.
///
/// IOS va Android (Skip) uchun umumiy. Android'da faqat animatsiya, sensorli javob (haptic) va
/// maxsus `ButtonStyle` yo'q.
struct LetterWritingView: View {
    @Environment(LetterProgressStore.self) private var store
    @Environment(LetterAudioPlayer.self) private var audio
    @Environment(SettingsStore.self) private var settings
    @Environment(ActivityStore.self) private var activity
    #if !SKIP
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    #endif

    /// Android: ro'yxatga qaytish (NavigationStack yo'q). iOS'da `dismiss` ishlatiladi.
    let onClose: (() -> Void)?

    @State private var session: TraceSession
    @State private var letterIndex: Int
    @State private var style: LetterCase = LetterCase.upper

    init(startLetter: UzbekLetter, onClose: (() -> Void)? = nil) {
        self.onClose = onClose
        _letterIndex = State(initialValue: UzbekAlphabet.index(of: startLetter.id) ?? 0)
        _session = State(initialValue: TraceSession(letter: startLetter, style: LetterCase.upper))
    }

    private var letter: UzbekLetter { return UzbekAlphabet.letters[letterIndex] }
    private var isLastLetter: Bool { return letterIndex >= UzbekAlphabet.letters.count - 1 }

    var body: some View {
        #if SKIP
        VStack(spacing: 0) {
            AndroidScreenBar(title: Strings.Screen.letters, mode: LearningMode.offline, onBack: onClose)
            mainContent
        }
        .ovScreenBackground()
        #else
        mainContent
            .ovNavigationBar(title: Strings.Screen.letters, mode: .offline)
        #endif
    }

    private var mainContent: some View {
        VStack(spacing: Theme.Spacing.m) {
            casePicker
            traceCard
            wordsStrip
            statsRow
            actionsRow
        }
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.top, Theme.Spacing.s)
        .padding(.bottom, Theme.Spacing.m)
        .ovContentWidth()
        .ovScreenBackground()
        .onAppear { wireSession() }
        .onChange(of: letterIndex) { _, _ in reconfigure() }
        .onChange(of: style) { _, _ in reconfigure() }
        .onChange(of: settings.writingDifficulty) { _, difficulty in
            session.apply(tuning: difficulty.tuning)
        }
        .onDisappear { audio.stop() }
        .tracksPracticeTime()
        #if !SKIP
        .sensoryFeedback(.success, trigger: session.successCount)
        #endif
    }

    // MARK: Bo'laklar

    private var casePicker: some View {
        Picker(selection: $style) {
            ForEach(LetterCase.allCases) { option in
                Text(option.title).tag(option)
            }
        } label: {
            Text(Strings.Letters.gridTitle)
        }
        .pickerStyle(.segmented)
    }

    private var traceCard: some View {
        VStack(spacing: 0) {
            TraceCanvasView(session: session)
                .frame(maxWidth: .infinity, minHeight: 220, maxHeight: .infinity)
            SoundChip(title: Strings.Letters.soundChip, audioFileName: letter.audioFileName, audio: audio)
                .padding(Theme.Spacing.m)
        }
        .overlay(alignment: .top) {
            // `if` ichida bo'lgani uchun `transition` ishlaydi (banner paydo bo'ladi/yo'qoladi).
            if session.hasFeedback {
                TraceFeedbackBanner(feedback: session.feedback)
                    .allowsHitTesting(false)
                    #if !SKIP
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.9).combined(with: .opacity))
                    #endif
            }
        }
        #if !SKIP
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.75), value: session.feedback)
        #endif
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .ovCard(padding: 0)
        .frame(maxHeight: .infinity)
    }

    /// Harfni tushuntiruvchi so'zlar. Ro'yxat bo'sh bo'lsa (harf hali to'ldirilmagan),
    /// bo'lim butunlay ko'rsatilmaydi va joy egallamaydi.
    @ViewBuilder
    private var wordsStrip: some View {
        let words = LetterWords.words(for: letter.id)
        if !words.isEmpty {
            LetterWordsStrip(letter: letter, words: words)
        }
    }

    private var statsRow: some View {
        StatCardRow(cards: [
            StatCard(
                value: String(store.todayCount),
                title: Strings.Letters.statToday,
                valueColor: .ovGreenStrong
            ),
            StatCard(
                value: store.lastLearnedLetter?.upper ?? Strings.Letters.noneLearned,
                title: Strings.Letters.statLearned,
                valueColor: .ovPurpleStrong
            )
        ])
    }

    private var actionsRow: some View {
        HStack(spacing: Theme.Spacing.m) {
            OvActionButton(
                title: Strings.Letters.restart,
                systemImage: "arrow.counterclockwise",
                kind: OvActionButton.Kind.secondary,
                hint: Strings.Letters.restartHint,
                action: { session.restart() }
            )
            OvActionButton(
                title: isLastLetter ? Strings.Letters.backToList : Strings.Letters.next,
                systemImage: isLastLetter ? "square.grid.2x2" : "arrow.right",
                kind: OvActionButton.Kind.primary,
                action: { goNext() }
            )
        }
    }

    // MARK: Harakatlar

    private func wireSession() {
        let progress = store
        let log = activity
        session.onFinish = { outcome in
            progress.record(outcome)
            if outcome.isFirstSuccessInAttempt {
                log.logPractice(kind: ActivityStore.Kind.letter, subject: outcome.subject.text, stars: outcome.stars)
            }
        }
        session.apply(tuning: settings.writingDifficulty.tuning)
        session.configure(letter: letter, style: style)
    }

    private func reconfigure() {
        audio.stop()
        session.configure(letter: letter, style: style)
    }

    private func goNext() {
        if isLastLetter {
            #if SKIP
            onClose?()
            #else
            dismiss()
            #endif
        } else {
            letterIndex += 1
        }
    }
}

#if DEBUG && !SKIP
#Preview("Harf yozish") {
    NavigationStack {
        LetterWritingView(startLetter: UzbekAlphabet.letters[1])
    }
    .ovPreviewEnvironment()
}

#Preview("Harflar to'ri") {
    NavigationStack {
        LetterGridView()
    }
    .ovPreviewEnvironment()
}
#endif
