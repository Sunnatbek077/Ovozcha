import SwiftUI

/// Tanlangan dars bosqichi (navigatsiya uchun).
struct StageRoute: Hashable {
    let lesson: SoundLesson
    let stage: LessonStage
}

/// 4-ekran: Talaffuz murabbiyi (ONLINE). Harflar to'ri -> tovush darsi (bosqichlar) -> mashq.
///
/// iOS: native `NavigationStack`. Android: `NavigationStack`siz oddiy almashtirish
/// (`LettersFlowView` dagi sabab bilan bir xil).
struct PronunciationView: View {
    /// Android: tanlangan dars va bosqich. iOS'da ishlatilmaydi.
    @State private var lesson: SoundLesson? = nil
    @State private var route: StageRoute? = nil

    var body: some View {
        #if SKIP
        if let route = route {
            LessonRunnerView(lesson: route.lesson, stage: route.stage, onClose: { self.route = nil })
        } else if let lesson = lesson {
            SoundLessonView(
                lesson: lesson,
                onBack: { self.lesson = nil },
                onSelect: { picked in self.route = picked }
            )
        } else {
            PronunciationHomeView(onSelect: { picked in self.lesson = picked })
        }
        #else
        NavigationStack {
            PronunciationHomeView()
                .navigationDestination(for: SoundLesson.self) { lesson in
                    SoundLessonView(lesson: lesson)
                }
                .navigationDestination(for: StageRoute.self) { route in
                    LessonRunnerView(lesson: route.lesson, stage: route.stage)
                }
        }
        #endif
    }
}

// MARK: - Harflar to'ri

/// 29 ta tovush darsi, alifbo tartibida. Har kartada bajarilgan mashqlar.
struct PronunciationHomeView: View {
    @Environment(PronunciationProgressStore.self) private var progress
    /// Android: dars tanlanganda (iOS'da `NavigationLink`).
    var onSelect: ((SoundLesson) -> Void)? = nil

    /// Faqat yozuvlar borligini tekshirish uchun (quloq o'yini ochiqmi).
    @State private var player = ClipPlayer()

    private let columns = [GridItem(.adaptive(minimum: 84), spacing: Theme.Spacing.m)]

    var body: some View {
        #if SKIP
        // Android: `LazyVGrid` `ScrollView` ichida yagona bola bo'lishi shart (`LetterGridView` ga qarang).
        VStack(spacing: 0) {
            AndroidScreenBar(title: Strings.Screen.pronunciation, mode: LearningMode.online)
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                intro
                ScrollView {
                    grid
                }
            }
            .padding(.horizontal, Theme.Spacing.screen)
            .padding(.top, Theme.Spacing.s)
        }
        .ovScreenBackground()
        #else
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                intro
                grid
            }
            .padding(.horizontal, Theme.Spacing.screen)
            .padding(.vertical, Theme.Spacing.l)
            .ovContentWidth()
        }
        .ovScreenBackground()
        .ovNavigationBar(title: Strings.Screen.pronunciation, mode: .online)
        #endif
    }

    private var intro: some View {
        HStack(spacing: Theme.Spacing.m) {
            MascotView(size: 52)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(Strings.Coach.homeTitle)
                    .ovStyle(.headline)
                Text(Strings.Coach.lessonsHint)
                    .ovStyle(.subheadline, color: .ovTextSecondary)
            }
            Spacer(minLength: 0)
        }
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.m) {
            ForEach(SoundLessons.all) { lesson in
                #if SKIP
                Button(action: { onSelect?(lesson) }) {
                    tile(lesson)
                }
                .buttonStyle(.plain)
                .ovPressShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                #else
                NavigationLink(value: lesson) {
                    tile(lesson)
                }
                .buttonStyle(CardPressStyle())
                #endif
            }
        }
    }

    private func tile(_ lesson: SoundLesson) -> some View {
        var items: [LessonItem] = []
        for stage in lesson.stages {
            items.append(contentsOf: LessonSession.playableItems(stage.items, player: player))
        }
        let done = progress.doneCount(in: items)
        let complete = !items.isEmpty && done >= items.count
        return VStack(spacing: Theme.Spacing.s) {
            Text(lesson.letter)
                .font(GuideFont.font(size: 30, relativeTo: .title))
                .foregroundStyle(Color.ovInk)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(Strings.Coach.stageProgress(done, of: items.count))
                .ovStyle(.caption, color: complete ? .ovGreenStrong : .ovTextSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 84)
        .background(complete ? Color.ovGreen.opacity(0.16) : Color.ovSurface,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Color.ovBorder, lineWidth: 1.0)
        )
        #if !SKIP
        .accessibilityElement(children: .ignore)
        #endif
        .accessibilityLabel(Strings.Coach.lessonLabel(lesson.letter, done: done, total: items.count))
    }
}

// MARK: - Tovush darsi

/// Bitta tovush: harf, uni qanday aytish va bosqichlar ro'yxati.
struct SoundLessonView: View {
    @Environment(PronunciationProgressStore.self) private var progress

    let lesson: SoundLesson
    /// Android: orqaga va bosqich tanlash (iOS'da navigatsiya o'zi).
    var onBack: (() -> Void)? = nil
    var onSelect: ((StageRoute) -> Void)? = nil

    /// Faqat yozuvlar borligini tekshirish uchun (quloq o'yini ochiqmi).
    @State private var player = ClipPlayer()

    var body: some View {
        #if SKIP
        VStack(spacing: 0) {
            AndroidScreenBar(title: Strings.Coach.lessonTitle(lesson.letter), mode: LearningMode.online, onBack: onBack)
            ScrollView {
                content
            }
        }
        .ovScreenBackground()
        #else
        ScrollView {
            content
        }
        .ovScreenBackground()
        .ovNavigationBar(title: Strings.Coach.lessonTitle(lesson.letter), mode: .online)
        #endif
    }

    private var content: some View {
        lessonCard(lesson)
            .padding(.horizontal, Theme.Spacing.screen)
            .padding(.vertical, Theme.Spacing.l)
            .ovContentWidth()
    }

    // MARK: Dars kartasi

    private func lessonCard(_ lesson: SoundLesson) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.m) {
                Text(lesson.letter)
                    .font(GuideFont.font(size: 34, relativeTo: .title))
                    .foregroundStyle(Color.white)
                    .frame(width: 56, height: 56)
                    .background(Color.ovPurpleStrong, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(Strings.Coach.lessonTitle(lesson.letter))
                        .ovStyle(.headline)
                    Text(lesson.hint)
                        .ovStyle(.caption, color: .ovTextSecondary)
                }
                Spacer(minLength: 0)
            }
            VStack(spacing: Theme.Spacing.s) {
                ForEach(Array(lesson.stages.indices), id: \.self) { index in
                    stageEntry(lesson: lesson, stage: lesson.stages[index], number: index + 1)
                }
            }
        }
        .ovCard()
    }

    @ViewBuilder
    private func stageEntry(lesson: SoundLesson, stage: LessonStage, number: Int) -> some View {
        let playable = LessonSession.playableItems(stage.items, player: player)
        if playable.isEmpty {
            stageRow(stage: stage, number: number, items: stage.items, locked: true)
        } else {
            let route = StageRoute(lesson: lesson, stage: stage)
            #if SKIP
            Button(action: { onSelect?(route) }) {
                stageRow(stage: stage, number: number, items: playable, locked: false)
            }
            .buttonStyle(.plain)
            .ovPressShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            #else
            NavigationLink(value: route) {
                stageRow(stage: stage, number: number, items: playable, locked: false)
            }
            .buttonStyle(CardPressStyle())
            #endif
        }
    }

    private func stageRow(stage: LessonStage, number: Int, items: [LessonItem], locked: Bool) -> some View {
        let done = progress.doneCount(in: items)
        let complete = !locked && done >= items.count
        return HStack(spacing: Theme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(complete ? Color.ovGreenStrong : Color.ovPurple.opacity(Theme.tintOpacity))
                    .frame(width: 32, height: 32)
                if complete {
                    OvIcon(symbol: "checkmark", size: 18, tint: Color.white)
                        .foregroundStyle(Color.white)
                        .font(.subheadline.weight(.bold))
                } else {
                    Text(String(number))
                        .ovStyle(.caption, color: .ovPurpleStrong)
                }
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(stage.title)
                    .ovStyle(.subheadline, color: .ovInk)
                Text(locked ? Strings.Coach.listenLocked : stage.subtitle)
                    .ovStyle(.caption, color: .ovTextSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            if !locked {
                Text(Strings.Coach.stageProgress(done, of: items.count))
                    .ovStyle(.caption, color: complete ? .ovGreenStrong : .ovTextSecondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.m)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .background(Color.ovBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .opacity(locked ? 0.55 : 1.0)
        #if !SKIP
        .accessibilityElement(children: .ignore)
        #endif
        .accessibilityLabel(Strings.Coach.stageLabel(stage.title, done: done, total: items.count))
    }
}

#if DEBUG && !SKIP
#Preview("Talaffuz") {
    PronunciationView()
        .ovPreviewEnvironment()
}
#endif
