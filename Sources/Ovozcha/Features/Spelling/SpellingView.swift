import SwiftUI

/// 6-tab: Imlo lug'ati (ONLINE, keyin keshdan). So'z yoziladi — to'g'ri yozilishlari ro'yxat
/// bo'lib chiqadi. Hech narsa topilmasa, yozilishi eng yaqin so'zlar taklif qilinadi.
///
/// Lug'atdan asosan ota-ona va o'qituvchi foydalanadi (3-5 yoshli bola yoza olmaydi),
/// shuning uchun matnlar kattalarga ("siz") emas, betaraf yozilgan.
///
/// Ro'yxat native `List`: Android'da `LazyColumn`, ya'ni faqat ko'rinadigan qatorlar chiziladi.
/// IOS va Android (Skip) uchun umumiy.
struct SpellingView: View {
    @Environment(SpellingDictionaryStore.self) private var dictionary

    @State private var query = ""
    @State private var results: [SpellingEntry] = []
    @State private var suggestions: [SpellingEntry] = []
    /// Takliflar kechiktirib hisoblanadi (har harfda emas); eskirganini tashlash uchun.
    @State private var generation = 0

    var body: some View {
        #if SKIP
        VStack(spacing: 0) {
            AndroidScreenBar(title: Strings.Screen.spelling, mode: LearningMode.online)
            content
        }
        .ovScreenBackground()
        #else
        // iOS: tizimning qidiruv maydoni. Imlo — tab panelidagi qidiruv tabi (`RootTabView`), shu
        // maydon panel doirasidan kengayadi; o'zimizning maydon kerak emas.
        NavigationStack {
            content
                .ovScreenBackground()
                .ovNavigationBar(title: Strings.Screen.spelling, mode: .online)
                .searchable(text: $query, prompt: Strings.Spelling.placeholder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        #endif
    }

    private var content: some View {
        VStack(spacing: Theme.Spacing.m) {
            #if SKIP
            searchField
                .padding(.horizontal, Theme.Spacing.screen)
                .padding(.top, Theme.Spacing.s)
            #endif
            stateContent(for: dictionary.state)
        }
        .ovContentWidth()
        .onAppear { dictionary.loadIfNeeded() }
        .onChange(of: query) { _, newValue in
            search(newValue)
        }
        .onChange(of: dictionary.state) { _, state in
            if state == SpellingDictionaryStore.State.ready {
                search(query)
            }
        }
    }

    // MARK: Qidiruv maydoni (Android)

    #if SKIP
    private var searchField: some View {
        HStack(spacing: Theme.Spacing.s) {
            OvIcon(symbol: "magnifyingglass", size: 22, tint: Color.ovTextSecondary)
                .foregroundStyle(Color.ovTextSecondary)
                .accessibilityHidden(true)
            TextField(Strings.Spelling.placeholder, text: $query)
                // Android'da Material chegarasi chiqmasin: maydon kartaning ichida.
                .textFieldStyle(.plain)
                .font(.ov(.headline))
                .foregroundStyle(Color.ovInk)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
            if !query.isEmpty {
                Button(action: { query = "" }) {
                    OvIcon(symbol: "xmark.circle.fill", size: 22, tint: Color.ovTextSecondary)
                        .foregroundStyle(Color.ovTextSecondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .ovPressShape(Circle())
                .accessibilityLabel(Strings.Spelling.clear)
            }
        }
        .padding(.leading, Theme.Spacing.l)
        .padding(.trailing, Theme.Spacing.xs)
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(Color.ovSurface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Color.ovBorder, lineWidth: 1.0)
        )
    }

    #endif

    // MARK: Holatlar

    @ViewBuilder
    private func stateContent(for state: SpellingDictionaryStore.State) -> some View {
        switch state {
        case .idle, .loading:
            message(title: Strings.Spelling.loading, text: Strings.Spelling.firstLoad, showsSpinner: true)
        case .offline:
            failure(Strings.Spelling.offline)
        case .failed:
            failure(Strings.Spelling.failed)
        case .ready:
            if SpellingIndex.key(query).isEmpty {
                message(
                    title: Strings.Spelling.hintTitle,
                    text: Strings.Spelling.hintBody + "\n\n" + Strings.Spelling.wordCount(dictionary.wordCount)
                        + "\n" + Strings.Spelling.source,
                    showsSpinner: false
                )
            } else {
                resultList
            }
        }
    }

    private func message(title: String, text: String, showsSpinner: Bool) -> some View {
        VStack(spacing: Theme.Spacing.m) {
            if showsSpinner {
                ProgressView()
                    .tint(Color.ovPurpleStrong)
            }
            Text(title)
                .ovStyle(.headline)
                .multilineTextAlignment(.center)
            Text(text)
                .ovStyle(.subheadline, color: .ovTextSecondary)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.top, Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func failure(_ text: String) -> some View {
        VStack(spacing: Theme.Spacing.l) {
            Text(text)
                .ovStyle(.subheadline, color: .ovInk)
                .multilineTextAlignment(.center)
            OvActionButton(
                title: Strings.Spelling.retry,
                systemImage: "arrow.counterclockwise",
                kind: OvActionButton.Kind.secondary,
                action: { dictionary.loadIfNeeded() }
            )
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.top, Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Natijalar

    private var resultList: some View {
        List {
            if !results.isEmpty {
                Section {
                    ForEach(results) { entry in
                        row(entry, isExact: SpellingIndex.isExactSpelling(query, of: entry))
                    }
                } header: {
                    sectionHeader(Strings.Spelling.resultsHeader)
                }
            } else {
                Section {
                    if suggestions.isEmpty {
                        Text(Strings.Spelling.nothingSimilar)
                            .ovStyle(.subheadline, color: .ovTextSecondary)
                            .listRowBackground(Color.ovBackground)
                    } else {
                        ForEach(suggestions) { entry in
                            row(entry, isExact: false)
                        }
                    }
                } header: {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(Strings.Spelling.notFound(query))
                            .ovStyle(.subheadline, color: .ovInk)
                        if !suggestions.isEmpty {
                            sectionHeader(Strings.Spelling.suggestHeader)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .background(Color.ovBackground)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .ovStyle(.overline, color: .ovTextSecondary)
    }

    private func row(_ entry: SpellingEntry, isExact: Bool) -> some View {
        HStack(spacing: Theme.Spacing.s) {
            Text(entry.word)
                .ovStyle(.headline, color: .ovInk)
            Spacer(minLength: 0)
            if isExact {
                OvIcon(symbol: "checkmark", size: 18, tint: Color.ovGreenStrong)
                    .foregroundStyle(Color.ovGreenStrong)
                Text(Strings.Spelling.exactMark)
                    .ovStyle(.caption, color: .ovGreenStrong)
            }
        }
        .frame(minHeight: Theme.Layout.minTapTarget)
        .listRowBackground(isExact ? Color.ovGreen.opacity(0.16) : Color.ovBackground)
        #if !SKIP
        .accessibilityElement(children: .ignore)
        #endif
        .accessibilityLabel(isExact ? Strings.Spelling.exactLabel(entry.word) : entry.word)
    }

    // MARK: Qidirish

    /// Prefiks qidiruvi har harfda (ikkilik qidiruv — arzon). Takliflar (Levenshtein) faqat
    /// hech narsa topilmasa va yozish to'xtagandan keyin hisoblanadi.
    private func search(_ text: String) {
        generation += 1
        let ticket = generation
        let entries = dictionary.entries
        results = SpellingIndex.search(text, in: entries)
        suggestions = []
        if !results.isEmpty || SpellingIndex.key(text).count < 2 {
            return
        }
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            if ticket != generation { return }
            suggestions = SpellingIndex.suggestions(text, in: entries)
        }
    }
}

#if DEBUG && !SKIP
#Preview("Imlo lug'ati") {
    SpellingView()
        .ovPreviewEnvironment()
}
#endif
