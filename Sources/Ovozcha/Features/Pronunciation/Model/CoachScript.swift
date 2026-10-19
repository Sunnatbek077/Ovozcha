import Foundation

/// Murabbiyning bitta gapi: ekrandagi matn va uni aytadigan ovoz bo'laklari.
///
/// Ovoz jonli yozuvlardan yig'iladi (TTS emas): masalan
/// `word_rasm` + `coach_pos_start` + `letter_r` + `coach_instead_of` + `letter_l` + `coach_i_heard`
/// = "rasm soʻzining boshida r oʻrniga l eshitdim". Bo'laklardan biri yo'q bo'lsa,
/// ovoz umuman chalinmaydi (yarim gap chalkashtiradi) — faqat matn ko'rinadi.
struct CoachLine: Equatable, Sendable {
    enum Tone: Equatable, Sendable {
        /// Muvaffaqiyat: yashil.
        case praise
        /// Yo'l-yo'riq: sariq.
        case hint
        /// Oddiy ko'rsatma: ko'k.
        case neutral
    }

    let text: String
    let clips: [String]
    let tone: Tone
}

/// Ovoz fayllari nomlari. Fayllar: `Sources/Ovozcha/Resources/Audio/<nom>.m4a`.
/// To'liq ro'yxat: `Tools/voice-recordings/README.md`.
enum CoachAudio {

    /// Murabbiy iborasi: `coach_praise_1`.
    static func phrase(_ key: String) -> String {
        return "coach_" + key
    }

    /// So'zning to'g'ri aytilishi: `word_rasm`, `word_ro_mol`.
    static func word(_ text: String) -> String {
        return "word_" + slug(text)
    }

    /// So'zning noto'g'ri aytilishi (quloq o'yini uchun): `wrong_lasm`.
    static func wrong(_ text: String) -> String {
        return "wrong_" + slug(text)
    }

    /// Tovushning o'zi. Harflar bo'limidagi yozuv bilan bir xil fayl (`UzbekLetter.audioFileName`):
    /// `letter_r`, `letter_o_apos`, `letter_sh`.
    static func sound(_ grapheme: String) -> String {
        if grapheme == "o'" { return "letter_o_apos" }
        if grapheme == "g'" { return "letter_g_apos" }
        return "letter_" + grapheme
    }

    /// Fayl nomi uchun: kichik lotin harflari, apostrof va bo'shliq -> `_`.
    static func slug(_ text: String) -> String {
        var result = ""
        for character in PronunciationScoring.normalize(text) {
            if character == "'" || character == " " {
                result = result + "_"
            } else {
                result = result + String(character)
            }
        }
        return result
    }
}

/// Yozib olinadigan bitta murabbiy iborasi.
struct CoachPhrase: Sendable {
    /// Fayl nomi `coach_` dan keyingi qismi: "praise_1".
    let key: String
    let text: String
}

extension CoachAudio {
    /// Murabbiyning barcha umumiy iboralari (tovush ko'rsatmalari — `coach_hint_*` — darslarda).
    ///
    /// Yozib olish ro'yxati shundan yasaladi (`Tools/voice-recordings/generate.sh`); skript kodda
    /// ishlatilgan har bir `CoachAudio.phrase("...")` shu ro'yxatda borligini ham tekshiradi.
    static func catalog() -> [CoachPhrase] {
        return [
            CoachPhrase(key: "praise_1", text: Strings.Coach.praise1),
            CoachPhrase(key: "praise_2", text: Strings.Coach.praise2),
            CoachPhrase(key: "praise_3", text: Strings.Coach.praise3),
            CoachPhrase(key: "listen_repeat", text: Strings.Coach.listenAndRepeat),
            CoachPhrase(key: "say_word", text: Strings.Coach.sayTheWord),
            CoachPhrase(key: "say_aloud", text: Strings.Coach.sayAloud),
            CoachPhrase(key: "self_listen", text: Strings.Coach.selfListen),
            CoachPhrase(key: "which_right", text: Strings.Coach.whichIsRight),
            CoachPhrase(key: "first", text: Strings.Coach.first),
            CoachPhrase(key: "second", text: Strings.Coach.second),
            CoachPhrase(key: "listen_again", text: Strings.Coach.listenAgain),
            CoachPhrase(key: "almost", text: Strings.Coach.almost),
            CoachPhrase(key: "try_again", text: Strings.Coach.tryAgain),
            CoachPhrase(key: "not_heard", text: Strings.Coach.notHeard),
            CoachPhrase(key: "move_on", text: Strings.Coach.moveOn),
            CoachPhrase(key: "once_more", text: Strings.Coach.onceMore),
            CoachPhrase(key: "stage_done", text: Strings.Coach.stageDone),
            CoachPhrase(key: "stage_partial", text: Strings.Coach.stagePartial),
            CoachPhrase(key: "stage_retry", text: Strings.Coach.stageRetry),
            CoachPhrase(key: "pos_start", text: Strings.Coach.fragmentStart),
            CoachPhrase(key: "pos_middle", text: Strings.Coach.fragmentMiddle),
            CoachPhrase(key: "pos_end", text: Strings.Coach.fragmentEnd),
            CoachPhrase(key: "instead_of", text: Strings.Coach.fragmentInsteadOf),
            CoachPhrase(key: "i_heard", text: Strings.Coach.fragmentIHeard),
            CoachPhrase(key: "sound_not_heard", text: Strings.Coach.fragmentSoundNotHeard)
        ]
    }
}

/// Murabbiy nima deyishini tanlaydi. Sof mantiq, iOS va Android uchun umumiy.
///
/// Qoidalar (3-5 yosh):
/// - Muvaffaqiyat ishonch bilan nishonlanadi.
/// - Xato hech qachon "noto'g'ri" deb aytilmaydi. Aniq tashxis bo'lsa, murabbiy "men ... eshitdim"
///   deydi (nutq tanish ham adashishi mumkin — ayb bolaga emas, "quloqqa" olinadi) va tovushni
///   qanday aytishni ko'rsatadi.
/// - Uch urinishdan keyin keyingi so'zga o'tishni taklif qiladi: bola zerikib qolmasin.
enum CoachScript {

    /// Shundan keyin "keyingisiga o'tamiz" taklif qilinadi.
    static let attemptsBeforeMoveOn = 3

    static func praise(_ variant: Int) -> CoachLine {
        switch abs(variant) % 3 {
        case 0:
            return CoachLine(text: Strings.Coach.praise1, clips: [CoachAudio.phrase("praise_1")], tone: .praise)
        case 1:
            return CoachLine(text: Strings.Coach.praise2, clips: [CoachAudio.phrase("praise_2")], tone: .praise)
        default:
            return CoachLine(text: Strings.Coach.praise3, clips: [CoachAudio.phrase("praise_3")], tone: .praise)
        }
    }

    /// Mashq ko'rsatilganda. `hasModel`: namuna yozuvi bormi — yo'q bo'lsa "tingla" demaymiz.
    static func intro(for item: LessonItem, hasModel: Bool) -> CoachLine {
        if !hasModel && item.kind != .pair {
            return CoachLine(text: Strings.Coach.sayAloud, clips: [CoachAudio.phrase("say_aloud")], tone: .neutral)
        }
        switch item.kind {
        case .sound, .syllables:
            return CoachLine(text: Strings.Coach.listenAndRepeat, clips: [CoachAudio.phrase("listen_repeat")], tone: .neutral)
        case .word:
            return CoachLine(text: Strings.Coach.sayTheWord, clips: [CoachAudio.phrase("say_word")], tone: .neutral)
        case .pair:
            return CoachLine(text: Strings.Coach.whichIsRight, clips: [CoachAudio.phrase("which_right")], tone: .neutral)
        }
    }

    /// Tovush/bo'g'in takrorlangandan keyin (baholanmaydi).
    static func selfListen() -> CoachLine {
        return CoachLine(text: Strings.Coach.selfListen, clips: [CoachAudio.phrase("self_listen")], tone: .praise)
    }

    /// So'z tekshiruvi natijasi. `attempt` — shu so'z uchun nechanchi urinish (1 dan).
    static func feedback(for diagnosis: SpeechDiagnosis, word: String, lesson: SoundLesson, attempt: Int) -> CoachLine {
        switch diagnosis {
        case .correct:
            return praise(attempt)

        case .soundSwap(let sound, let heard, let position, _):
            var text = ""
            var clips: [String] = [CoachAudio.word(word), positionClip(position), CoachAudio.sound(sound)]
            if let heard = heard {
                text = Strings.Coach.swap(word: word, position: position, sound: sound, heard: heard)
                clips.append(CoachAudio.phrase("instead_of"))
                clips.append(CoachAudio.sound(heard))
                clips.append(CoachAudio.phrase("i_heard"))
            } else {
                text = Strings.Coach.missing(word: word, position: position, sound: sound)
                clips.append(CoachAudio.phrase("sound_not_heard"))
            }
            text = text + " " + lesson.hint + " " + Strings.Coach.onceMore
            clips.append(lesson.hintClip)
            clips.append(CoachAudio.phrase("once_more"))
            return CoachLine(text: text, clips: clips, tone: .hint)

        case .almost:
            if attempt >= attemptsBeforeMoveOn { return moveOn() }
            return CoachLine(text: Strings.Coach.almost, clips: [CoachAudio.phrase("almost")], tone: .hint)

        case .retry:
            if attempt >= attemptsBeforeMoveOn { return moveOn() }
            return CoachLine(text: Strings.Coach.tryAgain, clips: [CoachAudio.phrase("try_again")], tone: .hint)

        case .notHeard:
            return CoachLine(text: Strings.Coach.notHeard, clips: [CoachAudio.phrase("not_heard")], tone: .hint)
        }
    }

    static func pairAnswer(correct: Bool, item: LessonItem, attempt: Int) -> CoachLine {
        if correct {
            let line = praise(attempt)
            // "Barakalla!" + to'g'ri aytilishini yana bir bor eshittiramiz.
            var clips = line.clips
            clips.append(item.modelClip)
            return CoachLine(text: line.text + " \u{00AB}" + item.text + "\u{00BB}", clips: clips, tone: .praise)
        }
        return CoachLine(text: Strings.Coach.listenAgain, clips: [CoachAudio.phrase("listen_again")], tone: .hint)
    }

    /// Bosqich oxiri. Maqtov natijaga mos: hech narsa chiqmagan bo'lsa "barakalla" demaymiz.
    static func stageDone(done: Int, total: Int) -> CoachLine {
        if total > 0 && done >= total {
            return CoachLine(text: Strings.Coach.stageDone, clips: [CoachAudio.phrase("stage_done")], tone: .praise)
        }
        if done > 0 {
            return CoachLine(text: Strings.Coach.stagePartial, clips: [CoachAudio.phrase("stage_partial")], tone: .praise)
        }
        return CoachLine(text: Strings.Coach.stageRetry, clips: [CoachAudio.phrase("stage_retry")], tone: .neutral)
    }

    private static func moveOn() -> CoachLine {
        return CoachLine(text: Strings.Coach.moveOn, clips: [CoachAudio.phrase("move_on")], tone: .neutral)
    }

    private static func positionClip(_ position: SoundPosition) -> String {
        switch position {
        case .start:  return CoachAudio.phrase("pos_start")
        case .middle: return CoachAudio.phrase("pos_middle")
        case .end:    return CoachAudio.phrase("pos_end")
        }
    }
}
