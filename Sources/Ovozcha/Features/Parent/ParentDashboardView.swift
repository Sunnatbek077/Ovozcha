import SwiftUI

/// 5-ekran (PDF): "Ota-ona paneli". Uch statistika kartasi, "So'nggi faoliyat" ro'yxati va sozlamalar.
/// IOS va Android (Skip) uchun umumiy.
struct ParentDashboardView: View {
    @Environment(ActivityStore.self) private var activity
    @Environment(ProfileStore.self) private var profile
    @Environment(SettingsStore.self) private var settings
    @Environment(LetterProgressStore.self) private var letters
    @Environment(NumberProgressStore.self) private var numbers
    @Environment(PronunciationProgressStore.self) private var pronunciation

    /// Panelni yopish. `nil` bo'lsa, yopish tugmasi ko'rsatilmaydi.
    var onClose: (() -> Void)? = nil

    @State private var showResetConfirmation = false

    /// Ro'yxatda ko'rsatiladigan eng so'nggi 6 ta faoliyat.
    private var visibleRecent: [ActivityStore.Entry] {
        var result: [ActivityStore.Entry] = []
        for entry in activity.recent {
            if result.count >= 6 { break }
            result.append(entry)
        }
        return result
    }

    var body: some View {
        #if SKIP
        // Android: NavigationStack yo'q (TabView ichida konflikt), o'z top bari bilan.
        VStack(spacing: 0) {
            AndroidScreenBar(title: Strings.Screen.parent, mode: nil, onBack: onClose)
            ScrollView {
                content
            }
        }
        .ovScreenBackground()
        .confirmationDialog(
            Strings.Parent.resetTitle,
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(Strings.Parent.resetConfirm, role: .destructive) {
                resetProgress()
            }
            Button(Strings.Parent.cancel, role: .cancel) {}
        } message: {
            Text(Strings.Parent.resetMessage)
        }
        #else
        NavigationStack {
            ScrollView {
                content
            }
            .ovScreenBackground()
            .ovNavigationBar(title: Strings.Screen.parent)
            .toolbar {
                if let onClose {
                    ToolbarItem(placement: .topBarTrailing) {
                        closeButton(onClose)
                    }
                }
            }
        }
        .confirmationDialog(
            Strings.Parent.resetTitle,
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(Strings.Parent.resetConfirm, role: .destructive) {
                resetProgress()
            }
            Button(Strings.Parent.cancel, role: .cancel) {}
        } message: {
            Text(Strings.Parent.resetMessage)
        }
        #endif
    }

    #if !SKIP
    /// iOS 26: tizimning yopish tugmasi (`role: .close` — Liquid Glass doirasidagi ✕).
    @ViewBuilder
    private func closeButton(_ action: @escaping () -> Void) -> some View {
        if #available(iOS 26.0, *) {
            Button(role: .close, action: action)
        } else {
            Button(Strings.Parent.close, action: action)
        }
    }
    #endif

    private var content: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            statsRow
            recentSection
            settingsSection
        }
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.vertical, Theme.Spacing.l)
        .ovContentWidth()
    }

    // MARK: Statistika

    private var statsRow: some View {
        StatCardRow(cards: [
            StatCard(
                value: Strings.Parent.minutes(activity.todayMinutes),
                title: Strings.Parent.statToday,
                valueColor: .ovSkyStrong,
                minHeight: 104
            ),
            StatCard(
                value: String(activity.streakDays),
                title: Strings.Parent.statStreak,
                valueColor: .ovGreenStrong,
                minHeight: 104
            ),
            StatCard(
                value: Strings.Parent.accuracy(activity.pronunciationAccuracyPercent),
                title: Strings.Parent.statAccuracy,
                valueColor: .ovPurpleStrong,
                minHeight: 104
            )
        ])
    }

    // MARK: So'nggi faoliyat

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text(Strings.Parent.recentTitle)
                .ovStyle(.overline, color: .ovTextSecondary)
                #if !SKIP
                .accessibilityAddTraits(.isHeader)
                #endif

            if activity.recent.isEmpty {
                Text(Strings.Parent.emptyActivity)
                    .ovStyle(.subheadline, color: .ovTextSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .ovCard()
            } else {
                ForEach(visibleRecent) { entry in
                    ActivityRow(entry: entry)
                }
            }
        }
    }

    // MARK: Sozlamalar

    /// Bolaning ismini tuzatish. Ism `SetupView` da bir marta so'raladi, lekin xato
    /// yozilgan bo'lsa shu yerdan o'zgartiriladi. Bo'sh qoldirib bo'lmaydi.
    private var nameCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(Strings.Parent.nameTitle)
                .ovStyle(.headline)
            TextField(Strings.Setup.placeholder, text: nameBinding)
                .textFieldStyle(.plain)
                .font(.ov(.body))
                .foregroundStyle(Color.ovInk)
                .padding(Theme.Spacing.m)
                .frame(maxWidth: .infinity, minHeight: Theme.Layout.minTapTarget)
                .background(
                    Color.ovBackground,
                    in: RoundedRectangle(cornerRadius: Theme.Spacing.m, style: .continuous)
                )
                .accessibilityLabel(Strings.Parent.nameTitle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ovCard()
    }

    /// Yozilgan matnni darhol saqlaydi; bo'sh bo'lsa, eski ism saqlanib qoladi.
    private var nameBinding: Binding<String> {
        return Binding(
            get: { profile.childName },
            set: { newValue in profile.setName(newValue) }
        )
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text(Strings.Parent.settingsTitle)
                .ovStyle(.overline, color: .ovTextSecondary)
                #if !SKIP
                .accessibilityAddTraits(.isHeader)
                #endif

            nameCard

            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text(Strings.Parent.difficultyTitle)
                    .ovStyle(.headline)
                Picker(selection: difficultyBinding) {
                    ForEach(WritingDifficulty.allCases) { option in
                        Text(option.title).tag(option)
                    }
                } label: {
                    Text(Strings.Parent.difficultyTitle)
                }
                .pickerStyle(.segmented)
                Text(Strings.Parent.difficultyHint)
                    .ovStyle(.caption, color: .ovTextSecondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .ovCard()

            OvActionButton(
                title: Strings.Parent.resetButton,
                systemImage: "trash",
                kind: OvActionButton.Kind.secondary,
                action: { showResetConfirmation = true }
            )
        }
    }

    private var difficultyBinding: Binding<WritingDifficulty> {
        return Binding(
            get: { settings.writingDifficulty },
            set: { settings.setWritingDifficulty($0) }
        )
    }

    private func resetProgress() {
        letters.resetAll()
        numbers.resetAll()
        pronunciation.resetAll()
        activity.resetAll()
        // Ism ham o'chadi. Shundan keyin `ProfileStore.isSetUp` `false` bo'ladi va
        // ilova `SetupView` ga qaytadi (`OvozchaRootView` ga qarang), ya'ni bola
        // ismini qaytadan kiritadi.
        profile.resetAll()
    }
}

// MARK: - Faoliyat qatori

struct ActivityRow: View {
    let entry: ActivityStore.Entry

    private var module: LearningModule {
        switch entry.kind {
        case .letter:
            return LearningModule.letters
        case .number:
            return LearningModule.numbers
        case .pronunciation:
            return LearningModule.pronunciation
        }
    }

    private var message: String {
        switch entry.kind {
        case .letter:
            return Strings.Parent.activityLetter(entry.subject)
        case .number:
            return Strings.Parent.activityNumber(entry.subject)
        case .pronunciation:
            return Strings.Parent.activityPronunciation(entry.subject, score: entry.score ?? 0.0)
        }
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            OvIcon(symbol: module.tab.symbol, size: 18, tint: module.strongColor)
                .foregroundStyle(module.strongColor)
                .frame(width: 40, height: 40)
                .background(module.brandColor.opacity(Theme.tintOpacity), in: Circle())
                .accessibilityHidden(true)

            Text(message)
                .ovStyle(.body)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ovCard(padding: Theme.Spacing.m)
        #if !SKIP
        .accessibilityElement(children: .combine)
        #endif
    }
}

#if DEBUG && !SKIP
#Preview("Ota-ona paneli") {
    ParentDashboardView()
        .ovPreviewEnvironment()
}
#endif
