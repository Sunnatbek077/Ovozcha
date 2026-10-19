import SwiftUI

/// Bosqich mashqi: bitta vaqtda bitta mashq (3-5 yosh uchun), murabbiy gapi va katta tugmalar.
///
/// Ekran tuzilishi: yuqorida mashqlar nuqtalari, o'rtada mashq kartasi (rasm + so'z, mashq
/// tovushi rangda), murabbiy pufagi, katta mikrofon (yoki quloq o'yinida ikki ovoz), pastda "Keyingisi".
///
/// IOS va Android (Skip) uchun umumiy.
struct LessonRunnerView: View {
    @Environment(PronunciationProgressStore.self) private var progress
    @Environment(ActivityStore.self) private var activity
    #if !SKIP
    @Environment(\.dismiss) private var dismiss
    #endif

    /// Android: ro'yxatga qaytish. iOS'da `dismiss`.
    let onClose: (() -> Void)?

    @State private var session: LessonSession

    init(lesson: SoundLesson, stage: LessonStage, onClose: (() -> Void)? = nil) {
        self.onClose = onClose
        _session = State(initialValue: LessonSession(lesson: lesson, stage: stage, player: ClipPlayer()))
    }

    var body: some View {
        #if SKIP
        VStack(spacing: 0) {
            AndroidScreenBar(title: session.stage.title, mode: LearningMode.online, onBack: onClose)
            mainContent
        }
        .ovScreenBackground()
        #else
        mainContent
            .ovNavigationBar(title: session.stage.title, mode: .online)
        #endif
    }

    private var mainContent: some View {
        VStack(spacing: Theme.Spacing.m) {
            progressDots
            if session.isFinished {
                finishedCard
                Spacer(minLength: 0)
            } else if let item = session.item {
                itemCard(item)
                coachBubble
                Spacer(minLength: 0)
                controls(item)
                nextButton
            }
        }
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.top, Theme.Spacing.s)
        .padding(.bottom, Theme.Spacing.m)
        .ovContentWidth()
        .ovScreenBackground()
        .onAppear { start() }
        .onDisappear { session.cancel() }
        .tracksPracticeTime()
        #if !SKIP
        .sensoryFeedback(.success, trigger: session.doneInRun)
        #endif
    }

    // MARK: Mashqlar nuqtalari

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(Array(session.items.indices), id: \.self) { index in
                Capsule()
                    .fill(dotColor(index))
                    .frame(width: index == session.index && !session.isFinished ? 20.0 : 8.0, height: 8)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 16)

        #if !SKIP
        .accessibilityElement(children: .ignore)
        #endif
        .accessibilityLabel(Strings.Coach.itemProgress(min(session.index + 1, session.items.count), of: session.items.count))
    }

    private func dotColor(_ index: Int) -> Color {
        if progress.isDone(session.items[index]) { return .ovGreenStrong }
        if index == session.index && !session.isFinished { return .ovPurpleStrong }
        return .ovBorder
    }

    // MARK: Mashq kartasi

    private func itemCard(_ item: LessonItem) -> some View {
        VStack(spacing: Theme.Spacing.s) {
            if !item.emoji.isEmpty {
                Text(item.emoji)
                    .font(.system(size: 72))
                    .accessibilityHidden(true)
            }
            switch item.kind {
            case .word:
                highlighted(item.text)
            case .sound, .syllables:
                Text(item.text)
                    .font(GuideFont.font(size: 44, relativeTo: .largeTitle))
                    .foregroundStyle(Color.ovPurpleStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            case .pair:
                EmptyView()
            }
            if item.kind != .pair && session.player.has(item.modelClip) {
                smallButton(title: Strings.Coach.listen, symbol: "speaker.wave.2.fill", tint: .ovSkyStrong) {
                    session.playModel()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.l)
        .ovCard()
    }

    /// So'z: mashq tovushi rangda. Tovush eshitilmagan bo'lsa (tashxis), u to'q sariqda.
    ///
    /// `Text + Text` SkipUI'da ishlamaydi, shuning uchun har bir belgi alohida `Text`.
    private func highlighted(_ word: String) -> some View {
        let mask = LetterWords.letterMask(word: word, letter: session.lesson.lower)
        var characters: [String] = []
        for character in word {
            characters.append(String(character))
        }
        let accent = session.soundMissed ? Color.ovRewardFill : Color.ovPurpleStrong
        return HStack(spacing: 0) {
            ForEach(Array(characters.indices), id: \.self) { index in
                Text(characters[index])
                    .font(GuideFont.font(size: 44, relativeTo: .largeTitle))
                    .foregroundStyle(mask[index] ? accent : Color.ovInk)
            }
        }
        .lineLimit(1)

        #if !SKIP
        .accessibilityElement(children: .ignore)
        #endif
        .accessibilityLabel(word)
    }

    // MARK: Murabbiy

    private var coachBubble: some View {
        let line = session.line
        let canReplay = !line.clips.isEmpty && session.player.hasAll(line.clips)
        return VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(alignment: .top, spacing: Theme.Spacing.m) {
                MascotView(size: 36)
                Text(line.text)
                    .ovStyle(.subheadline, color: .ovInk)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if canReplay {
                    Button(action: { session.replayLine() }) {
                        OvIcon(symbol: "speaker.wave.2.fill", size: 20, tint: Color.ovSkyStrong)
                            .foregroundStyle(Color.ovSkyStrong)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .ovPressShape(Circle())
                    .accessibilityLabel(Strings.Coach.replayCoach)
                }
            }
            if let heard = session.heardText {
                Text(Strings.Coach.heard(heard))
                    .ovStyle(.caption, color: .ovTextSecondary)
            }
        }
        .padding(Theme.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bubbleFill(line.tone), in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))

        #if !SKIP
        .accessibilityElement(children: .combine)
        #endif
    }

    private func bubbleFill(_ tone: CoachLine.Tone) -> Color {
        switch tone {
        case .praise:  return Color.ovGreen.opacity(0.16)
        case .hint:    return Color.ovYellow.opacity(0.28)
        case .neutral: return Color.ovSky.opacity(Theme.tintOpacity)
        }
    }

    // MARK: Boshqaruv

    @ViewBuilder
    private func controls(_ item: LessonItem) -> some View {
        switch item.kind {
        case .pair:
            pairOptions
        case .word:
            if session.canCheckWords {
                speakControls
            } else {
                Text(Strings.Coach.unavailable)
                    .ovStyle(.caption, color: .ovTextSecondary)
            }
        case .sound, .syllables:
            speakControls
        }
    }

    private var speakControls: some View {
        VStack(spacing: Theme.Spacing.s) {
            microphone
            Text(statusText)
                .ovStyle(.caption, color: .ovTextSecondary)
                .frame(minHeight: 18)
            if session.ownRecording != nil && session.phase == .ready {
                smallButton(title: Strings.Coach.myVoice, symbol: "play.fill", tint: .ovPurpleStrong) {
                    session.playOwnRecording()
                }
            }
        }
    }

    private var statusText: String {
        switch session.phase {
        case .recording: return Strings.Coach.recording
        case .checking:  return Strings.Coach.checking
        case .ready:     return ""
        }
    }

    private var microphone: some View {
        let recording = session.phase == .recording
        let busy = session.phase == .checking
        return Button(action: { session.toggleRecording() }) {
            ZStack {
                Circle()
                    .fill(recording ? Color.ovPurple.opacity(0.28) : Color.clear)
                    .frame(width: 112, height: 112)
                Circle()
                    .fill(recording ? Color.ovRewardFill : Color.ovPurpleStrong)
                    .frame(width: 92, height: 92)
                if busy {
                    ProgressView()
                        .tint(Color.white)
                } else {
                    OvIcon(symbol: recording ? "stop.fill" : "mic", size: 40, tint: Color.white)
                        .foregroundStyle(Color.white)
                        .font(.system(size: 36, weight: .regular))
                }
            }
            .frame(width: 112, height: 112)
        }
        .buttonStyle(.plain)
        .ovPressShape(Circle())
        .disabled(busy)
        .accessibilityLabel(recording ? Strings.Coach.stopSpeak : Strings.Coach.startSpeak)
    }

    /// Quloq o'yini: ikki ovoz. Har biri — eshitish va tanlash.
    /// Ikki qator (yonma-yon emas): Android'da `HStack` teng kenglik bermaydi.
    private var pairOptions: some View {
        VStack(spacing: Theme.Spacing.s) {
            ForEach(Array(session.pairOptions.indices), id: \.self) { index in
                HStack(spacing: Theme.Spacing.m) {
                    Button(action: { session.playOption(index) }) {
                        HStack(spacing: Theme.Spacing.s) {
                            OvIcon(symbol: "speaker.wave.2.fill", size: 22, tint: Color.ovSkyStrong)
                                .foregroundStyle(Color.ovSkyStrong)
                            Text(Strings.Coach.option(index + 1))
                                .ovStyle(.headline, color: .ovInk)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                        .background(Color.ovSky.opacity(Theme.tintOpacity), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .ovPressShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button(action: { session.choose(index) }) {
                        Text(Strings.Coach.choose)
                            .ovStyle(.headline, color: .white)
                            .frame(width: 88, height: 56)
                            .background(choiceFill(index), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .ovPressShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .disabled(session.itemDone)
                    .accessibilityLabel(Strings.Coach.chooseLabel(index + 1))
                }
            }
        }
    }

    /// To'g'ri tanlangandan keyin: to'g'ri variant yashil, ikkinchisi xira.
    private func choiceFill(_ index: Int) -> Color {
        if !session.itemDone { return Color.ovPurpleStrong }
        return session.pairOptions[index].isCorrect ? Color.ovGreenStrong : Color.ovBorder
    }

    private var nextButton: some View {
        OvActionButton(
            title: session.isLastItem ? Strings.Coach.finish : Strings.Coach.next,
            systemImage: "arrow.right",
            kind: session.itemDone ? OvActionButton.Kind.primary : OvActionButton.Kind.secondary,
            action: { session.next() }
        )
    }

    // MARK: Yakun

    private var finishedCard: some View {
        VStack(spacing: Theme.Spacing.m) {
            // Emoji to'g'ridan-to'g'ri: Kotlin `\u` faqat 4 xonali kodni tushunadi,
            // 5 xonali (`\u{1F389}`) Android'da buzilib chiqadi.
            Text(session.doneInRun >= session.items.count ? "🎉" : "🙂")
                .font(.system(size: 64))
                .accessibilityHidden(true)
            Text(session.line.text)
                .ovStyle(.title3)
                .multilineTextAlignment(.center)
            Text(Strings.Coach.summary(session.doneInRun, of: session.items.count))
                .ovStyle(.subheadline, color: .ovTextSecondary)
                .multilineTextAlignment(.center)
            VStack(spacing: Theme.Spacing.s) {
                OvActionButton(title: Strings.Coach.again, systemImage: "arrow.counterclockwise", kind: OvActionButton.Kind.secondary) {
                    session.restart()
                }
                OvActionButton(title: Strings.Coach.finish, systemImage: "checkmark", kind: OvActionButton.Kind.primary) {
                    close()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.l)
        .ovCard()
    }

    // MARK: Yordamchilar

    private func smallButton(title: String, symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                OvIcon(symbol: symbol, size: 18, tint: tint)
                    .foregroundStyle(tint)
                Text(title)
                    .ovStyle(.subheadline, color: tint)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .frame(minHeight: 44)
            .background(tint.opacity(Theme.tintOpacity), in: Capsule())
        }
        .buttonStyle(.plain)
        .ovPressShape(Capsule())
    }

    private func start() {
        let store = progress
        let log = activity
        session.onItemDone = { item in store.markDone(item) }
        session.onWordChecked = { item, score in log.logPronunciation(word: item.text, score: score) }
        session.begin()
    }

    private func close() {
        session.cancel()
        #if SKIP
        onClose?()
        #else
        dismiss()
        #endif
    }
}
