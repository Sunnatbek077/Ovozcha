import Foundation

/// Barcha foydalanuvchiga ko'rinadigan matnlar bir joyda.
/// Keyinchalik String Catalog (Localizable.xcstrings) ga o'tkazish oson bo'ladi.
///
/// Imlo: o'zbek lotin yozuvida "o'" va "g'" uchun ʻ (U+02BB) belgisi ishlatiladi.
/// Poppins'da bu belgi yo'q, iOS uni avtomatik ravishda tizim shriftidan oladi.
enum Strings {

    enum Tab {
        static let home          = "Bosh"
        static let letters       = "Harflar"
        static let numbers       = "Sonlar"
        static let pronunciation = "Talaffuz"
        static let spelling      = "Imlo"
    }

    enum Screen {
        static let letters       = "Harf yozish"
        static let numbers       = "Son yozish"
        static let pronunciation = "Talaffuz murabbiyi"
        static let spelling      = "Imlo lugʻati"
        static let parent        = "Ota-ona paneli"
    }

    /// Ilova birinchi ochilganda: ism so'rash.
    enum Setup {
        static let title       = "Tanishamiz!"
        static let subtitle    = "Ismingni yozib qoʻy — men seni shunday chaqiraman."
        static let placeholder = "Ismim"
        static let start       = "Boshladik"
        static let emptyError  = "Ismingni yozishing kerak."
    }

    enum Home {
        static let greeting          = "Salom,"
        static let todayAchievement  = "Bugungi yutuq"
        static let noStreak          = "Bugun birinchi mashqni boshlaymiz!"
        static let weekTitle         = "Shu hafta"
        static let weekDone          = "mashq qilingan kun"

        /// Haftalik chiziqdagi bitta kun (VoiceOver uchun).
        static func dayLabel(_ day: String, active: Bool) -> String {
            active ? "\(day): mashq qilingan" : "\(day): mashq qilinmagan"
        }

        static func streak(_ days: Int) -> String {
            "\(days) kun ketma-ket mashq qildingiz!"
        }
    }

    enum Module {
        static let lettersTitle           = "Harflar"
        static let numbersTitle           = "Sonlar"
        static let pronunciationTitle     = "Talaffuz Murabbiyi"
        static let writeListenSpeak       = "Yozish · Eshitish · Aytish"
        static let pronunciationSubtitle  = "AI nutq tahlili"
    }

    enum Mode {
        static let offline              = "Offline"
        static let online               = "Online"
        static let offlineAccessibility = "Internetsiz ishlaydi"
        static let onlineAccessibility  = "Internet kerak"
    }

    enum Accessibility {
        static let opensSection = "Boʻlimni ochadi"
        static let back = "Orqaga"
    }

    enum Placeholder {
        static let comingSoon = "Bu boʻlim keyingi bosqichda qoʻshiladi."
    }

    /// 2-bosqich: Harflar bo'limi (iOS va Android).
    enum Letters {
        static let gridTitle       = "Harflar"
        static let caseUpper       = "Bosh harf"
        static let caseLower       = "Kichik harf"
        static let soundChip       = "Bosing — tovushni eshiting"
        static let soundMissing    = "Bu harfning ovozi hali qoʻshilmagan"
        // Talaffuzni tekshirish. Muhim: muvaffaqiyatsizlikda bolani AYBLAMAYMIZ —
        // nutq tanish oʻzbek tilida ishonchli emas, xato uniki boʻlishi mumkin.
        static let speakHint     = "Soʻzni bosib, ovoz chiqarib ayt"
        static let listening     = "Eshitayapman…"
        static let checking      = "Tekshiryapman…"
        static let correct       = "Barakalla!"
        static let retry         = "Yana bir marta aytib koʻr"
        static let notHeard      = "Eshitmadim. Yana bir marta?"
        static let micDenied     = "Mikrofonga ruxsat bering"
        static let offline       = "Internet yoʻq — keyinroq urinib koʻramiz"
        static let unavailable   = "Tekshirish hozir ishlamayapti"

        /// "Deyarli! «r» tovushiga eʼtibor ber"
        static func almost(sound: String?) -> String {
            guard let sound = sound else { return "Deyarli toʻgʻri!" }
            return "Deyarli! «\(sound)» tovushiga eʼtibor ber"
        }

        /// "R bilan soʻzlar" — harf ekranidagi misol soʻzlar boʻlimi.
        static func wordsTitle(_ letter: String) -> String {
            "\(letter) bilan soʻzlar"
        }

        static let statToday       = "Bugun mashq"
        static let statLearned     = "Oʻrganilgan"
        static let noneLearned     = "–"
        static let restart         = "Qaytadan"
        static let next            = "Keyingi harf"
        static let backToList      = "Harflar roʻyxati"
        static let keepGoing       = "Harfning butun ustidan yuring"
        static let stayInside      = "Nuqtali chiziq ichida qoling"
        static let success1        = "Yaxshi! Yana bir bor urinib koʻring"
        static let success2        = "Juda yaxshi!"
        static let success3        = "Ajoyib! Juda chiroyli!"
        static let canvasHint      = "Barmoq bilan harfning nuqtali chizigʻi ustidan yuring"
        static let restartHint     = "Chizilganini oʻchirib, qaytadan boshlaydi"

        static func progress(_ learned: Int, of total: Int) -> String {
            "\(learned) / \(total) harf oʻrganildi"
        }

        static func canvasLabel(_ letter: String) -> String {
            "Yozish maydoni. Harf: \(letter)"
        }

        static func stars(_ count: Int) -> String {
            "\(count) yulduz"
        }

        static func tileLabel(_ letter: String, upperDone: Bool, lowerDone: Bool) -> String {
            let upper = upperDone ? "bosh harf yozilgan" : "bosh harf yozilmagan"
            let lower = lowerDone ? "kichik harf yozilgan" : "kichik harf yozilmagan"
            return "\(letter) harfi, \(upper), \(lower)"
        }
    }

    /// 3-bosqich: Sonlar bo'limi (faqat iOS).
    enum Numbers {
        static let gridTitle   = "Sonlar"
        static let next        = "Keyingi son"
        static let backToList  = "Sonlar roʻyxati"
        static let soundMissing = "Bu sonning ovozi hali qoʻshilmagan"

        static func soundChip(_ word: String) -> String {
            "Bosing — \"\(word)\" deb eshiting"
        }

        static func progress(_ learned: Int, of total: Int) -> String {
            "\(learned) / \(total) son oʻrganildi"
        }

        static func tileLabel(_ number: String, word: String, done: Bool) -> String {
            let state = done ? "yozilgan" : "yozilmagan"
            return "\(number) soni, \(word), \(state)"
        }
    }

    /// 4-bosqich: Talaffuz murabbiyi (iOS va Android).
    ///
    /// Murabbiy gaplari (`CoachScript`) bola uchun: sodda, qisqa, "sen" bilan. Xato hech qachon
    /// "notoʻgʻri" deb aytilmaydi — "eshitdim" deyiladi (nutq tanish ham adashishi mumkin).
    /// Har bir gapning ovoz yozuvi: `Tools/voice-recordings/README.md`.
    enum Coach {
        // Bosh ekran
        static let homeTitle       = "Tovushlarni birga mashq qilamiz"
        static let listenLocked    = "Ovozlar yozilgach ochiladi"
        static let checkOffline    = "Soʻzlarni tekshirish uchun internet kerak"

        static func lessonTitle(_ letter: String) -> String {
            "\(letter) tovushi"
        }

        static let lessonsHint     = "Harfni tanla: avval tovush, keyin soʻzlar."

        static func stageProgress(_ done: Int, of total: Int) -> String {
            "\(done)/\(total)"
        }

        static func lessonLabel(_ letter: String, done: Int, total: Int) -> String {
            "\(letter) tovushi, \(done) / \(total) bajarilgan"
        }

        static func stageLabel(_ title: String, done: Int, total: Int) -> String {
            "\(title), \(done) / \(total) bajarilgan"
        }

        // Bosqichlar
        static let stageSound          = "Tovush va boʻgʻinlar"
        static let stageSoundSubtitle  = "rrr \u{00B7} ra \u{00B7} ro \u{00B7} ru"
        static let stageSoundOnly      = "Tovush"
        static let stageListen         = "Quloq oʻyini"
        static let stageListenSubtitle = "Qaysi biri toʻgʻri?"
        static let stageStart          = "Soʻz boshida"
        static let stageMiddle         = "Soʻz oʻrtasida"
        static let stageEnd            = "Soʻz oxirida"

        static func stageWordsSubtitle(_ words: [String]) -> String {
            words.joined(separator: " \u{00B7} ")
        }

        // Mashq ekrani
        static let listen       = "Eshit"
        static let myVoice      = "Oʻz ovozim"
        static let next         = "Keyingisi"
        static let finish       = "Tugatish"
        static let again        = "Qaytadan"
        static let startSpeak   = "Gapirishni boshlash"
        static let stopSpeak    = "Toʻxtatish"
        static let recording    = "Eshitayapman…"
        static let checking     = "Tekshiryapman…"
        static let micDenied    = "Mikrofonga ruxsat bering: Sozlamalar → Ovozcha → Mikrofon"
        static let offline      = "Internet yoʻq — soʻzni keyinroq tekshiramiz"
        static let unavailable  = "Tekshirish hozir ishlamayapti"
        static let choose       = "Shu!"
        static let replayCoach  = "Murabbiyni qayta eshitish"

        static func itemProgress(_ index: Int, of total: Int) -> String {
            "\(index) / \(total)"
        }

        static func option(_ number: Int) -> String {
            "\(number)-ovoz"
        }

        static func chooseLabel(_ number: Int) -> String {
            "\(number)-ovoz toʻgʻri"
        }

        /// Ota-ona uchun: nutq tanish nima eshitgani.
        static func heard(_ text: String) -> String {
            "Eshitganim: \u{00AB}\(text)\u{00BB}"
        }

        static func summary(_ done: Int, of total: Int) -> String {
            "\(total) ta mashqdan \(done) tasi bajarildi"
        }

        // Murabbiy gaplari
        static let praise1         = "Barakalla!"
        static let praise2         = "Zoʻr!"
        static let praise3         = "Juda toʻgʻri!"
        static let listenAndRepeat = "Tingla va takrorla."
        static let sayTheWord      = "Tingla, keyin oʻzing ayt."
        static let sayAloud        = "Ovoz chiqarib ayt."
        static let whichIsRight    = "Tingla: qaysi biri toʻgʻri?"
        static let selfListen      = "Yaxshi! Endi oʻz ovozingni tingla."
        static let almost          = "Deyarli! Yana bir marta, sekinroq ayt."
        static let tryAgain        = "Yana bir marta aytib koʻr."
        static let notHeard        = "Eshitmadim. Balandroq ayt."
        static let moveOn          = "Yaxshi urinding! Xohlasang, keyingisiga oʻtamiz."
        static let listenAgain     = "Yana bir tinglab koʻr."
        static let stageDone       = "Barakalla! Bu bosqichni tugatding."
        static let stagePartial    = "Yaxshi! Yana mashq qilsak, hammasi chiqadi."
        static let stageRetry      = "Bosqich tugadi. Keling, yana bir bor urinib koʻramiz."
        static let onceMore        = "Yana bir bor!"
        static let first           = "Birinchisi:"
        static let second          = "Ikkinchisi:"

        // Ulanadigan bo'laklar (faqat ovoz uchun; ekrandagi gap `swap`/`missing` da yig'iladi).
        static let fragmentStart          = "soʻzining boshida"
        static let fragmentMiddle         = "soʻzining oʻrtasida"
        static let fragmentEnd            = "soʻzining oxirida"
        static let fragmentInsteadOf      = "oʻrniga"
        static let fragmentIHeard         = "eshitdim."
        static let fragmentSoundNotHeard  = "tovushini eshitmadim."

        /// Tovushni qanday aytish — bolaga, sodda tilda. Logoped tasdig'i kerak.
        static func hint(forLetterID id: String) -> String {
            switch id {
            case "a":      return "Ogʻzingni katta och: aaa."
            case "b":      return "Lablaringni yum, keyin ovoz bilan och: b-b-b."
            case "d":      return "Til uchini tishlaring orqasiga tegizib, ovoz bilan: d-d-d."
            case "e":      return "Ogʻzingni biroz och, lablaringni yon tomonga choʻz: eee."
            case "f":      return "Yuqori tishlaringni pastki labingga tegizib, pufla: fff."
            case "g":      return "Til orqasini tepaga koʻtar, ovoz bilan: g-g-g."
            case "h":      return "Ogʻzingni ochib, iliq havo chiqar: hhh."
            case "i":      return "Jilmayib, lablaringni choʻz: iii."
            case "j":      return "Lablaringni oldinga choʻzib, ovoz bilan: j-j-j."
            case "k":      return "Til orqasini tepaga koʻtar, ovozsiz: k-k-k."
            case "l":      return "Til uchini yuqori tishlaring orqasiga tegizib tur: lll."
            case "m":      return "Lablaringni yum va gʻuvilla: mmm."
            case "n":      return "Til uchini tishlaring orqasiga tegizib, burundan: nnn."
            case "o":      return "Lablaringni yumaloq qil: ooo."
            case "p":      return "Lablaringni yum, keyin puflab och: p-p-p."
            case "q":      return "Tovushni tomogʻingning ichkarisidan chiqar: q-q-q."
            case "r":      return "Tilingni tepaga koʻtar va titrat: rrr."
            case "s":      return "Tishlaringni yaqin qilib, ilondek vishilla: sss."
            case "t":      return "Til uchini tishlaring orqasiga tegizib, ovozsiz: t-t-t."
            case "u":      return "Lablaringni oldinga, trubadek choʻz: uuu."
            case "v":      return "Yuqori tishlaringni pastki labingga tegizib, ovoz bilan: vvv."
            case "x":      return "Tomogʻingdan havo chiqarib xirilla: xxx."
            case "y":      return "Til oʻrtasini tepaga koʻtar: ya, yo, yu."
            case "z":      return "Tishlaringni yaqin qilib, ariday gʻuvilla: zzz."
            case "o_apos": return "Lablaringni yumaloq qilib, chuqurroq: oʻoʻoʻ."
            case "g_apos": return "Tomogʻingdan, gʻargʻara qilganday: gʻgʻgʻ."
            case "sh":     return "Lablaringni oldinga choʻzib, “jim” deganday: shhh."
            case "ch":     return "Lablaringni oldinga choʻzib, poyezddek: ch-ch-ch."
            case "ng":     return "Ogʻzingni ochiq tut, ovozni burundan chiqar: ng."
            default:       return ""
            }
        }

        /// "«rasm» soʻzining boshida «r» oʻrniga «l» eshitdim."
        static func swap(word: String, position: SoundPosition, sound: String, heard: String) -> String {
            "\u{00AB}\(word)\u{00BB} soʻzining \(place(position)) \u{00AB}\(shown(sound))\u{00BB} oʻrniga \u{00AB}\(shown(heard))\u{00BB} eshitdim."
        }

        /// "«arra» soʻzining oʻrtasida «r» tovushini eshitmadim."
        static func missing(word: String, position: SoundPosition, sound: String) -> String {
            "\u{00AB}\(word)\u{00BB} soʻzining \(place(position)) \u{00AB}\(shown(sound))\u{00BB} tovushini eshitmadim."
        }

        /// Tashxisdagi tovush (ASCII apostrof bilan) -> to'g'ri imlo: "o'" -> "oʻ".
        static func shown(_ sound: String) -> String {
            return sound.replacingOccurrences(of: "'", with: "\u{02BB}")
        }

        static func place(_ position: SoundPosition) -> String {
            switch position {
            case .start:  return "boshida"
            case .middle: return "oʻrtasida"
            case .end:    return "oxirida"
            }
        }
    }

    /// Imlo lug'ati: so'zning to'g'ri yozilishini qidirish (ONLINE, keyin keshdan).
    enum Spelling {
        static let placeholder     = "Soʻzni yozing"
        static let clear           = "Tozalash"
        static let loading         = "Lugʻat yuklanmoqda…"
        static let firstLoad       = "Birinchi marta internetdan yuklab olinadi (~370 KB), keyin internetsiz ham ishlaydi."
        static let offline         = "Internet yoʻq. Lugʻat birinchi marta internet orqali yuklab olinadi."
        static let failed          = "Lugʻatni yuklab boʻlmadi. Birozdan keyin qayta urinib koʻring."
        static let retry           = "Qayta urinish"
        static let hintTitle       = "Soʻzning toʻgʻri yozilishini toping"
        static let hintBody        = "Apostrofsiz yoki kirillda yozsangiz ham topadi: togri, тўғри → toʻgʻri."
        static let resultsHeader   = "Toʻgʻri yozilishi"
        static let suggestHeader   = "Balki shulardan biri:"
        static let nothingSimilar  = "Oʻxshash soʻz ham topilmadi. Yozilishini tekshirib koʻring."
        static let exactMark       = "toʻgʻri yozilgan"
        static let source          = "Manba: uz-hunspell ochiq lugʻati (GPL-3.0)"

        static func wordCount(_ count: Int) -> String {
            "Lugʻatda \(count) ta soʻz"
        }

        /// "«togri» — bunday yozilmaydi" emas: foydalanuvchini ayblamaymiz, faqat natijani aytamiz.
        static func notFound(_ query: String) -> String {
            "\u{00AB}\(query)\u{00BB} lugʻatda topilmadi"
        }

        static func exactLabel(_ word: String) -> String {
            "\(word), toʻgʻri yozilgan"
        }
    }

    /// 5-bosqich: Ota-ona paneli (faqat iOS).
    enum Parent {
        static let close            = "Yopish"
        static let statToday        = "Bugun"
        static let statStreak       = "Kun ketma-ket"
        static let statAccuracy     = "Talaffuz aniqligi"
        static let recentTitle      = "Soʻnggi faoliyat"
        static let emptyActivity    = "Hali mashq qilinmagan. Birinchi mashqdan keyin shu yerda koʻrinadi."
        static let settingsTitle    = "Sozlamalar"
        static let nameTitle        = "Bolaning ismi"
        static let difficultyTitle  = "Yozish qiyinligi"
        static let difficultyNormal = "Oddiy"
        static let difficultyEasy   = "Oson"
        static let difficultyHint   = "Oson rejimda chiziqdan biroz chetga chiqish ham qabul qilinadi."
        static let resetButton      = "Progressni tozalash"
        static let resetTitle       = "Hamma progress oʻchirilsinmi?"
        static let resetMessage     = "Harflar, sonlar, faoliyat tarixi va bolaning ismi oʻchiriladi. Ilova ism soʻrashdan qayta boshlanadi. Buni qaytarib boʻlmaydi."
        static let resetConfirm     = "Ha, oʻchirish"
        static let cancel           = "Bekor qilish"

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
            "\"\(letter)\" harfini yozishni mashq qildi"
        }

        static func activityNumber(_ number: String) -> String {
            "\"\(number)\" sonini yozishni mashq qildi"
        }

        static func activityPronunciation(_ word: String, score: Double) -> String {
            let base = "\"\(word)\" talaffuzini mashq qildi"
            if score >= 0.9 {
                return base + " — ajoyib"
            }
            if score >= 0.6 {
                return base + " — yaxshilanmoqda"
            }
            return base + " — takrorlash kerak"
        }
    }
}
