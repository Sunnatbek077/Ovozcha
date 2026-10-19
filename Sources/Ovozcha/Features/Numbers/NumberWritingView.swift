import SwiftUI

/// 3-ekran (PDF): "Son yozish". Harf yozish ekraniga o'xshash: katta ko'rsatma son, ostida
/// miqdorni ko'rsatuvchi nuqtalar va "Bosing — "besh" deb eshiting" tugmasi.
/// IOS va Android (Skip) uchun umumiy (Android'da animatsiya va haptic yo'q).
struct NumberWritingView: View {
    @Environment(NumberProgressStore.self) private var store
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
    @State private var index: Int

    init(startNumber: NumberItem, onClose: (() -> Void)? = nil) {
        self.onClose = onClose
        _index = State(initialValue: UzbekNumbers.index(of: startNumber.value) ?? 0)
        _session = State(initialValue: TraceSession(subject: startNumber.subject))
    }

    private var number: NumberItem { return UzbekNumbers.all[index] }
    private var isLast: Bool { return index >= UzbekNumbers.all.count - 1 }

    var body: some View {
        #if SKIP
        VStack(spacing: 0) {
            AndroidScreenBar(title: Strings.Screen.numbers, mode: LearningMode.offline, onBack: onClose)
            mainContent
        }
        .ovScreenBackground()
        #else
        mainContent
            .ovNavigationBar(title: Strings.Screen.numbers, mode: .offline)
        #endif
    }

    private var mainContent: some View {
        VStack(spacing: Theme.Spacing.m) {
            traceCard
            statsRow
            actionsRow
        }
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.top, Theme.Spacing.s)
        .padding(.bottom, Theme.Spacing.m)
        .ovContentWidth()
        .ovScreenBackground()
        .onAppear { wireSession() }
        .onChange(of: index) { _, _ in reconfigure() }
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

    private var traceCard: some View {
        VStack(spacing: 0) {
            TraceCanvasView(session: session)
                .frame(maxWidth: .infinity, minHeight: 200, maxHeight: .infinity)
            CountDotsView(count: number.value)
                .padding(.bottom, Theme.Spacing.m)
            SoundChip(
                title: Strings.Numbers.soundChip(number.word),
                audioFileName: number.audioFileName,
                audio: audio,
                missingMessage: Strings.Numbers.soundMissing
            )
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.bottom, Theme.Spacing.m)
        }
        .overlay(alignment: .top) {
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

    private var statsRow: some View {
        StatCardRow(cards: [
            StatCard(
                value: String(store.todayCount),
                title: Strings.Letters.statToday,
                valueColor: .ovGreenStrong
            ),
            StatCard(
                value: store.learnedRangeText,
                title: Strings.Letters.statLearned,
                valueColor: .ovSkyStrong
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
                title: isLast ? Strings.Numbers.backToList : Strings.Numbers.next,
                systemImage: isLast ? "square.grid.2x2" : "arrow.right",
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
                log.logPractice(kind: ActivityStore.Kind.number, subject: outcome.subject.text, stars: outcome.stars)
            }
        }
        session.apply(tuning: settings.writingDifficulty.tuning)
        session.configure(subject: number.subject)
    }

    private func reconfigure() {
        audio.stop()
        session.configure(subject: number.subject)
    }

    private func goNext() {
        if isLast {
            #if SKIP
            onClose?()
            #else
            dismiss()
            #endif
        } else {
            index += 1
        }
    }
}

#if DEBUG && !SKIP
#Preview("Son yozish") {
    NavigationStack {
        NumberWritingView(startNumber: UzbekNumbers.all[4])
    }
    .ovPreviewEnvironment()
}

#Preview("Sonlar to'ri") {
    NavigationStack {
        NumberGridView()
    }
    .ovPreviewEnvironment()
}
#endif
