import Foundation

/// Barcha foydalanuvchiga ko'rinadigan matnlar bir joyda.
/// Keyinchalik String Catalog (Localizable.xcstrings) ga o'tkazish oson bo'ladi.
///
/// Imlo: yangi o'zbek lotin alifbosi (2026-yil 21-oktabrdagi O'RQ-1184-son qonuni): Ö, Ğ, Ş, Ç
/// harflari (oldin Oʻ, Gʻ, Sh, Ch). Tutuq belgisi (eʼtibor, raʼno) — U+02BC. Poppins va Andika
/// shriftlarida bu harflarning hammasi bor. Eski yozuvdagi matn (nutq tanish natijasi, eski lug'at)
/// ekranga chiqishdan oldin `UzbekOrthography.modern` orqali o'giriladi.
enum Strings {

    enum Tab {
        static let home          = "Boş"
        static let letters       = "Harflar"
        static let numbers       = "Sonlar"
        static let pronunciation = "Talaffuz"
        static let spelling      = "Imlo"
    }

    enum Screen {
        static let letters       = "Harf yoziş"
        static let numbers       = "Son yoziş"
        static let pronunciation = "Talaffuz murabbiyi"
        static let spelling      = "Imlo luğati"
        static let parent        = "Ota-ona paneli"
    }

    /// Ilova birinchi ochilganda: ism so'rash.
    enum Setup {
        static let title       = "Tanişamiz!"
        static let subtitle    = "Ismingni yozib qöy — men seni şunday çaqiraman."
        static let placeholder = "Ismim"
        static let start       = "Boşladik"
        static let emptyError  = "Ismingni yozişing kerak."
    }

    enum Home {
        static let greeting          = "Salom,"
        static let todayAchievement  = "Bugungi yutuq"
        static let noStreak          = "Bugun birinçi maşqni boşlaymiz!"
        static let weekTitle         = "Şu hafta"
        static let weekDone          = "maşq qilingan kun"

        /// Haftalik chiziqdagi bitta kun (VoiceOver uchun).
        static func dayLabel(_ day: String, active: Bool) -> String {
            active ? "\(day): maşq qilingan" : "\(day): maşq qilinmagan"
        }

        static func streak(_ days: Int) -> String {
            "\(days) kun ketma-ket maşq qildingiz!"
        }
    }

    enum Module {
        static let lettersTitle           = "Harflar"
        static let numbersTitle           = "Sonlar"
        static let pronunciationTitle     = "Talaffuz Murabbiyi"
        static let writeListenSpeak       = "Yoziş · Eşitiş · Aytiş"
        static let pronunciationSubtitle  = "AI nutq tahlili"
    }

    /// Dam olish tizimi: 15 daqiqada savol, 25 daqiqada majburiy dam.
    enum BreakCoach {
        static let checkInTitle = "Yana şuğullanasizmi?"
        static let yes          = "Ha"
        static let moreTitle    = "Köproq maşq qilamizmi?"

        /// Dam tartibi bo'yicha xabar: 1-dam, 2-dam, 3-dam va undan keyingilari.
        static func restMessage(forBreak number: Int) -> String {
            if number <= 1 {
                return "Közingizga ozroq dam beramiz"
            }
            if number == 2 {
                return "Közingiz toliqdi, 2 daqiqa dam oling"
            }
            return "Juda yaxşi ketyapsiz, dam oliş yodingizdan çiqmasin"
        }

        /// Sanagich: "1:05".
        static func clock(_ seconds: Int) -> String {
            let safe = max(seconds, 0)
            let minutes = safe / 60
            let rest = safe % 60
            let tail = rest < 10 ? "0\(rest)" : "\(rest)"
            return "\(minutes):" + tail
        }
    }

    enum Mode {
        static let offline              = "Offline"
        static let online               = "Online"
        static let offlineAccessibility = "Internetsiz işlaydi"
        static let onlineAccessibility  = "Internet kerak"
    }

    enum Accessibility {
        static let opensSection = "Bölimni oçadi"
        static let back = "Orqaga"
    }

    enum Placeholder {
        static let comingSoon = "Bu bölim keyingi bosqiçda qöşiladi."
    }

    /// 2-bosqich: Harflar bo'limi (iOS va Android).
    enum Letters {
        static let gridTitle       = "Harflar"
        static let caseUpper       = "Boş harf"
        static let caseLower       = "Kiçik harf"
        static let soundChip       = "Bosing — tovuşni eşiting"
        static let soundMissing    = "Bu harfning ovozi hali qöşilmagan"
        // Talaffuzni tekshirish. Muhim: muvaffaqiyatsizlikda bolani AYBLAMAYMIZ —
        // nutq taniş özbek tilida işonçli emas, xato uniki bölişi mumkin.
        static let speakHint     = "Sözni bosib, ovoz çiqarib ayt"
        static let listening     = "Eşitayapman…"
        static let checking      = "Tekşiryapman…"
        static let correct       = "Barakalla!"
        static let retry         = "Yana bir marta aytib kör"
        static let notHeard      = "Eşitmadim. Yana bir marta?"
        static let micDenied     = "Mikrofonga ruxsat bering"
        static let offline       = "Internet yöq — keyinroq urinib köramiz"
        static let unavailable   = "Tekşiriş hozir işlamayapti"

        /// "Deyarli! «r» tovushiga eʼtibor ber"
        static func almost(sound: String?) -> String {
            guard let sound = sound else { return "Deyarli töğri!" }
            return "Deyarli! «\(sound)» tovuşiga eʼtibor ber"
        }

        /// "R bilan sözlar" — harf ekranidagi misol sözlar bölimi.
        static func wordsTitle(_ letter: String) -> String {
            "\(letter) bilan sözlar"
        }

        static let statToday       = "Bugun maşq"
        static let statLearned     = "Örganilgan"
        static let noneLearned     = "–"
        static let restart         = "Qaytadan"
        static let next            = "Keyingi harf"
        static let backToList      = "Harflar röyxati"
        static let keepGoing       = "Harfning butun ustidan yuring"
        static let stayInside      = "Nuqtali çiziq içida qoling"
        static let success1        = "Yaxşi! Yana bir bor urinib köring"
        static let success2        = "Juda yaxşi!"
        static let success3        = "Ajoyib! Juda çiroyli!"
        static let canvasHint      = "Barmoq bilan harfning nuqtali çiziği ustidan yuring"
        static let restartHint     = "Çizilganini öçirib, qaytadan boşlaydi"

        static func progress(_ learned: Int, of total: Int) -> String {
            "\(learned) / \(total) harf örganildi"
        }

        static func canvasLabel(_ letter: String) -> String {
            "Yoziş maydoni. Harf: \(letter)"
        }

        static func stars(_ count: Int) -> String {
            "\(count) yulduz"
        }

        static func tileLabel(_ letter: String, upperDone: Bool, lowerDone: Bool) -> String {
            let upper = upperDone ? "boş harf yozilgan" : "boş harf yozilmagan"
            let lower = lowerDone ? "kiçik harf yozilgan" : "kiçik harf yozilmagan"
            return "\(letter) harfi, \(upper), \(lower)"
        }
    }

    /// 3-bosqich: Sonlar bo'limi (faqat iOS).
    enum Numbers {
        static let gridTitle   = "Sonlar"
        static let next        = "Keyingi son"
        static let backToList  = "Sonlar röyxati"
        static let soundMissing = "Bu sonning ovozi hali qöşilmagan"

        static func soundChip(_ word: String) -> String {
            "Bosing — \"\(word)\" deb eşiting"
        }

        static func progress(_ learned: Int, of total: Int) -> String {
            "\(learned) / \(total) son örganildi"
        }

        static func tileLabel(_ number: String, word: String, done: Bool) -> String {
            let state = done ? "yozilgan" : "yozilmagan"
            return "\(number) soni, \(word), \(state)"
        }
    }

    /// 4-bosqich: Talaffuz murabbiyi (iOS va Android).
    ///
    /// Murabbiy gaplari (`CoachScript`) bola uchun: sodda, qisqa, "sen" bilan. Xato hech qachon
    /// "notöğri" deb aytilmaydi — "eşitdim" deyiladi (nutq taniş ham adaşişi mumkin).
    /// Har bir gapning ovoz yozuvi: `Tools/voice-recordings/README.md`.
    enum Coach {
        // Bosh ekran
        static let homeTitle       = "Tovuşlarni birga maşq qilamiz"
        static let listenLocked    = "Ovozlar yozilgaç oçiladi"
        static let checkOffline    = "Sözlarni tekşiriş uçun internet kerak"

        static func lessonTitle(_ letter: String) -> String {
            "\(letter) tovuşi"
        }

        static let lessonsHint     = "Harfni tanla: avval tovuş, keyin sözlar."

        static func stageProgress(_ done: Int, of total: Int) -> String {
            "\(done)/\(total)"
        }

        static func lessonLabel(_ letter: String, done: Int, total: Int) -> String {
            "\(letter) tovuşi, \(done) / \(total) bajarilgan"
        }

        static func stageLabel(_ title: String, done: Int, total: Int) -> String {
            "\(title), \(done) / \(total) bajarilgan"
        }

        // Bosqichlar
        static let stageSound          = "Tovuş va böğinlar"
        static let stageSoundSubtitle  = "rrr \u{00B7} ra \u{00B7} ro \u{00B7} ru"
        static let stageSoundOnly      = "Tovuş"
        static let stageListen         = "Quloq öyini"
        static let stageListenSubtitle = "Qaysi biri töğri?"
        static let stageStart          = "Söz boşida"
        static let stageMiddle         = "Söz örtasida"
        static let stageEnd            = "Söz oxirida"

        static func stageWordsSubtitle(_ words: [String]) -> String {
            words.joined(separator: " \u{00B7} ")
        }

        // Mashq ekrani
        static let listen       = "Eşit"
        static let myVoice      = "Öz ovozim"
        static let next         = "Keyingisi"
        static let finish       = "Tugatiş"
        static let again        = "Qaytadan"
        static let startSpeak   = "Gapirişni boşlaş"
        static let stopSpeak    = "Töxtatiş"
        static let recording    = "Eşitayapman…"
        static let checking     = "Tekşiryapman…"
        static let micDenied    = "Mikrofonga ruxsat bering: Sozlamalar → Ovozcha → Mikrofon"
        static let offline      = "Internet yöq — sözni keyinroq tekşiramiz"
        static let unavailable  = "Tekşiriş hozir işlamayapti"
        static let choose       = "Şu!"
        static let replayCoach  = "Murabbiyni qayta eşitiş"

        static func itemProgress(_ index: Int, of total: Int) -> String {
            "\(index) / \(total)"
        }

        static func option(_ number: Int) -> String {
            "\(number)-ovoz"
        }

        static func chooseLabel(_ number: Int) -> String {
            "\(number)-ovoz töğri"
        }

        /// Ota-ona uchun: nutq tanish nima eshitgani.
        static func heard(_ text: String) -> String {
            "Eşitganim: \u{00AB}\(UzbekOrthography.modern(text))\u{00BB}"
        }

        static func summary(_ done: Int, of total: Int) -> String {
            "\(total) ta maşqdan \(done) tasi bajarildi"
        }

        // Murabbiy gaplari
        static let praise1         = "Barakalla!"
        static let praise2         = "Zör!"
        static let praise3         = "Juda töğri!"
        static let listenAndRepeat = "Tingla va takrorla."
        static let sayTheWord      = "Tingla, keyin özing ayt."
        static let sayAloud        = "Ovoz çiqarib ayt."
        static let whichIsRight    = "Tingla: qaysi biri töğri?"
        static let selfListen      = "Yaxşi! Endi öz ovozingni tingla."
        static let almost          = "Deyarli! Yana bir marta, sekinroq ayt."
        static let tryAgain        = "Yana bir marta aytib kör."
        static let notHeard        = "Eşitmadim. Balandroq ayt."
        static let moveOn          = "Yaxşi urinding! Xohlasang, keyingisiga ötamiz."
        static let listenAgain     = "Yana bir tinglab kör."
        static let stageDone       = "Barakalla! Bu bosqiçni tugatding."
        static let stagePartial    = "Yaxşi! Yana maşq qilsak, hammasi çiqadi."
        static let stageRetry      = "Bosqiç tugadi. Keling, yana bir bor urinib köramiz."
        static let onceMore        = "Yana bir bor!"
        static let first           = "Birinçisi:"
        static let second          = "Ikkinçisi:"

        // Ulanadigan bo'laklar (faqat ovoz uchun; ekrandagi gap `swap`/`missing` da yig'iladi).
        static let fragmentStart          = "sözining boşida"
        static let fragmentMiddle         = "sözining örtasida"
        static let fragmentEnd            = "sözining oxirida"
        static let fragmentInsteadOf      = "örniga"
        static let fragmentIHeard         = "eşitdim."
        static let fragmentSoundNotHeard  = "tovuşini eşitmadim."

        /// Tovushni qanday aytish — bolaga, sodda tilda. Logoped tasdig'i kerak.
        static func hint(forLetterID id: String) -> String {
            switch id {
            case "a":      return "Oğzingni katta oç: aaa."
            case "b":      return "Lablaringni yum, keyin ovoz bilan oç: b-b-b."
            case "d":      return "Til uçini tişlaring orqasiga tegizib, ovoz bilan: d-d-d."
            case "e":      return "Oğzingni biroz oç, lablaringni yon tomonga çöz: eee."
            case "f":      return "Yuqori tişlaringni pastki labingga tegizib, pufla: fff."
            case "g":      return "Til orqasini tepaga kötar, ovoz bilan: g-g-g."
            case "h":      return "Oğzingni oçib, iliq havo çiqar: hhh."
            case "i":      return "Jilmayib, lablaringni çöz: iii."
            case "j":      return "Lablaringni oldinga çözib, ovoz bilan: j-j-j."
            case "k":      return "Til orqasini tepaga kötar, ovozsiz: k-k-k."
            case "l":      return "Til uçini yuqori tişlaring orqasiga tegizib tur: lll."
            case "m":      return "Lablaringni yum va ğuvilla: mmm."
            case "n":      return "Til uçini tişlaring orqasiga tegizib, burundan: nnn."
            case "o":      return "Lablaringni yumaloq qil: ooo."
            case "p":      return "Lablaringni yum, keyin puflab oç: p-p-p."
            case "q":      return "Tovuşni tomoğingning içkarisidan çiqar: q-q-q."
            case "r":      return "Tilingni tepaga kötar va titrat: rrr."
            case "s":      return "Tişlaringni yaqin qilib, ilondek vişilla: sss."
            case "t":      return "Til uçini tişlaring orqasiga tegizib, ovozsiz: t-t-t."
            case "u":      return "Lablaringni oldinga, trubadek çöz: uuu."
            case "v":      return "Yuqori tişlaringni pastki labingga tegizib, ovoz bilan: vvv."
            case "x":      return "Tomoğingdan havo çiqarib xirilla: xxx."
            case "y":      return "Til örtasini tepaga kötar: ya, yo, yu."
            case "z":      return "Tişlaringni yaqin qilib, ariday ğuvilla: zzz."
            case "o_apos": return "Lablaringni yumaloq qilib, çuqurroq: ööö."
            case "g_apos": return "Tomoğingdan, ğarğara qilganday: ğğğ."
            case "sh":     return "Lablaringni oldinga çözib, “jim” deganday: şşş."
            case "ch":     return "Lablaringni oldinga çözib, poyezddek: ç-ç-ç."
            default:       return ""
            }
        }

        /// "«rasm» sözining boşida «r» örniga «l» eşitdim."
        static func swap(word: String, position: SoundPosition, sound: String, heard: String) -> String {
            "\u{00AB}\(word)\u{00BB} sözining \(place(position)) \u{00AB}\(shown(sound))\u{00BB} örniga \u{00AB}\(shown(heard))\u{00BB} eşitdim."
        }

        /// "«arra» sözining örtasida «r» tovuşini eşitmadim."
        static func missing(word: String, position: SoundPosition, sound: String) -> String {
            "\u{00AB}\(word)\u{00BB} sözining \(place(position)) \u{00AB}\(shown(sound))\u{00BB} tovuşini eşitmadim."
        }

        /// Tashxisdagi tovush (normallashtirilgan: "o'", "sh") -> yangi alifbo harfi: "ö", "ş".
        static func shown(_ sound: String) -> String {
            return UzbekOrthography.modern(sound)
        }

        static func place(_ position: SoundPosition) -> String {
            switch position {
            case .start:  return "boşida"
            case .middle: return "örtasida"
            case .end:    return "oxirida"
            }
        }
    }

    /// Imlo lug'ati: so'zning to'g'ri yozilishini qidirish (ONLINE, keyin keshdan).
    enum Spelling {
        static let placeholder     = "Sözni yozing"
        static let clear           = "Tozalaş"
        static let loading         = "Luğat yuklanmoqda…"
        static let firstLoad       = "Birinçi marta internetdan yuklab olinadi (~370 KB), keyin internetsiz ham işlaydi."
        static let offline         = "Internet yöq. Luğat birinçi marta internet orqali yuklab olinadi."
        static let failed          = "Luğatni yuklab bölmadi. Birozdan keyin qayta urinib köring."
        static let retry           = "Qayta uriniş"
        static let hintTitle       = "Sözning töğri yozilişini toping"
        static let hintBody        = "Belgisiz, eski yozuvda yoki kirillda yozsangiz ham topadi: togri, toʻgʻri, тўғри → töğri."
        static let resultsHeader   = "Töğri yozilişi"
        static let suggestHeader   = "Balki şulardan biri:"
        static let nothingSimilar  = "Öxşaş söz ham topilmadi. Yozilişini tekşirib köring."
        static let exactMark       = "töğri yozilgan"
        static let source          = "Manba: uz-hunspell oçiq luğati (GPL-3.0)"

        static func wordCount(_ count: Int) -> String {
            "Luğatda \(count) ta söz"
        }

        /// "«togri» — bunday yozilmaydi" emas: foydalanuvchini ayblamaymiz, faqat natijani aytamiz.
        static func notFound(_ query: String) -> String {
            "\u{00AB}\(query)\u{00BB} luğatda topilmadi"
        }

        static func exactLabel(_ word: String) -> String {
            "\(word), töğri yozilgan"
        }
    }

    /// 5-bosqich: Ota-ona paneli (faqat iOS).
    enum Parent {
        static let close            = "Yopiş"
        static let statToday        = "Bugun"
        static let statStreak       = "Kun ketma-ket"
        static let statAccuracy     = "Talaffuz aniqligi"
        static let recentTitle      = "Sönggi faoliyat"
        static let emptyActivity    = "Hali maşq qilinmagan. Birinçi maşqdan keyin şu yerda körinadi."
        static let settingsTitle    = "Sozlamalar"
        static let nameTitle        = "Bolaning ismi"
        static let difficultyTitle  = "Yoziş qiyinligi"
        static let difficultyNormal = "Oddiy"
        static let difficultyEasy   = "Oson"
        static let difficultyHint   = "Oson rejimda çiziqdan biroz çetga çiqiş ham qabul qilinadi."
        static let resetButton      = "Progressni tozalaş"
        static let resetTitle       = "Hamma progress öçirilsinmi?"
        static let resetMessage     = "Harflar, sonlar, faoliyat tarixi va bolaning ismi öçiriladi. Ilova ism söraşdan qayta boşlanadi. Buni qaytarib bölmaydi."
        static let resetConfirm     = "Ha, öçiriş"
        static let cancel           = "Bekor qiliş"

        static func minutes(_ value: Int) -> String {
            "\(value) daq"
        }

        /// Talaffuz aniqligi foizda; hali baho bo'lmasa "–".
        static func accuracy(_ percent: Int?) -> String {
            if let percent = percent {
                return "\(percent)%"
            }
            return "–"
        }

        static func activityLetter(_ letter: String) -> String {
            "\"\(UzbekOrthography.modern(letter))\" harfini yozişni maşq qildi"
        }

        static func activityNumber(_ number: String) -> String {
            "\"\(number)\" sonini yozişni maşq qildi"
        }

        static func activityPronunciation(_ word: String, score: Double) -> String {
            let base = "\"\(UzbekOrthography.modern(word))\" talaffuzini maşq qildi"
            if score >= 0.9 {
                return base + " — ajoyib"
            }
            if score >= 0.6 {
                return base + " — yaxşilanmoqda"
            }
            return base + " — takrorlaş kerak"
        }
    }
}
