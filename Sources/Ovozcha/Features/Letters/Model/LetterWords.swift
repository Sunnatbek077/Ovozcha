import Foundation

/// Harfni tushuntirish uchun misol so'z.
///
/// Emoji rasm o'rnida ishlatiladi: 3-5 yoshdagi bola hali o'qiy olmaydi, shuning uchun
/// so'zning ma'nosi surat orqali yetkaziladi. Emoji ikkala platformada ham tizim
/// tomonidan chiziladi, qo'shimcha resurs talab qilmaydi.
struct LetterWord: Identifiable, Hashable, Sendable {
    var id: String { return text }
    let text: String
    let emoji: String

    /// To'g'ri aytilgan namunani nutq tanish QANDAY MATN qilib qaytargani.
    ///
    /// Nega kerak: Whisper har so'zda o'ziga xos xatoga yo'l qo'yadi ("arra" ni "Ara",
    /// "robot" ni "Робот" deb eshitadi). Bolaning matnini imlo bilan solishtirsak,
    /// TO'G'RI aytilgan so'z ham past baho oladi. Namuna bilan solishtirilsa, bu xato
    /// qisqaradi — va bu bitta mexanizm hamma harflar uchun ishlaydi.
    ///
    /// Bo'sh bo'lsa, imlo bilan solishtiriladi (aniqligi pastroq, lekin ishlaydi).
    /// To'ldirish: `Tools/reference-transcripts/build.py` ga qarang.
    var references: [String] = []
}

/// Har bir harf uchun misol so'zlar (29 ta harf, jami 236 so'z).
///
/// Tanlash mezoni: bola biladigan, ko'z oldiga keltiradigan aniq narsa, va emoji so'zning
/// ma'nosini HAQIQATAN ko'rsatishi. Mos emoji topilmagan so'zlar qo'shilmadi — noto'g'ri
/// surat bolaga noto'g'ri bog'lanish o'rgatadi. Shuning uchun harflarda so'z soni har xil
/// (5 tadan 10 tagacha).
///
/// `Ng` hech qachon so'z boshida kelmaydi, shuning uchun unga harf ICHIDA bo'lgan so'zlar
/// tanlangan ("tong", "qo'ng'iroq"). `LetterWords.letterMask` harfni so'zning istalgan
/// joyida topadi.
///
/// DIQQAT: so'zlar va imlo o'zbek tili o'qituvchisi tomonidan tasdiqlanishi kerak.
/// Tekshirilgani: har bir so'z o'z harfini o'z ichiga oladi va har birida emoji bor.
enum LetterWords {

    /// Tutuq belgisi (U+02BC) — "raʼno" dagi belgi.
    /// Diqqat: bu `Oʻ`/`Gʻ` dagi belgidan (U+02BB) boshqa.
    private static let tutuq = "\u{02BC}"

    /// `Oʻ`/`Gʻ` dagi belgi (U+02BB) — "roʻmol" dagi `oʻ` uchun.
    private static let okina = "\u{02BB}"

    /// So'zni matni bo'yicha topadi (barcha harflar ichidan). Talaffuz darslari so'zlarni shu
    /// yerdan oladi — emoji va etalonlar (`references`) bitta joyda turadi.
    static func word(_ text: String) -> LetterWord? {
        for letter in UzbekAlphabet.letters {
            for word in words(for: letter.id) {
                if word.text == text {
                    return word
                }
            }
        }
        return nil
    }

    static func words(for letterID: String) -> [LetterWord] {
        switch letterID {
        case "a":
            return [
                LetterWord(text: "ari",       emoji: "🐝"),
                LetterWord(text: "ayiq",      emoji: "🐻"),
                LetterWord(text: "asal",      emoji: "🍯"),
                LetterWord(text: "archa",     emoji: "🌲"),
                LetterWord(text: "apelsin",   emoji: "🍊"),
                LetterWord(text: "ananas",    emoji: "🍍"),
                LetterWord(text: "avtobus",   emoji: "🚌"),
                LetterWord(text: "akula",     emoji: "🦈"),
                LetterWord(text: "ayol",      emoji: "👩"),
                LetterWord(text: "aeroport",  emoji: "✈️")
            ]
        case "b":
            return [
                LetterWord(text: "baliq",              emoji: "🐟"),
                LetterWord(text: "banan",              emoji: "🍌"),
                LetterWord(text: "bodring",            emoji: "🥒"),
                LetterWord(text: "bulut",              emoji: "☁️"),
                LetterWord(text: "bola",               emoji: "🧒"),
                LetterWord(text: "barg",               emoji: "🍃"),
                LetterWord(text: "bo" + okina + "ri",  emoji: "🐺"),
                LetterWord(text: "burun",              emoji: "👃"),
                LetterWord(text: "buqa",               emoji: "🐂"),
                LetterWord(text: "basketbol",          emoji: "🏀")
            ]
        case "d":
            return [
                LetterWord(text: "daraxt",    emoji: "🌳"),
                LetterWord(text: "dengiz",    emoji: "🌊"),
                LetterWord(text: "deraza",    emoji: "🪟"),
                LetterWord(text: "dori",      emoji: "💊"),
                LetterWord(text: "dunyo",     emoji: "🌍"),
                LetterWord(text: "dala",      emoji: "🌾"),
                LetterWord(text: "devor",     emoji: "🧱"),
                LetterWord(text: "daftar",    emoji: "📓"),
                LetterWord(text: "delfin",    emoji: "🐬"),
                LetterWord(text: "dinozavr",  emoji: "🦕")
            ]
        case "e":
            return [
                LetterWord(text: "eshak",   emoji: "🫏"),
                LetterWord(text: "eshik",   emoji: "🚪"),
                LetterWord(text: "echki",   emoji: "🐐"),
                LetterWord(text: "etik",    emoji: "🥾"),
                LetterWord(text: "et",      emoji: "🥩"),
                LetterWord(text: "ertak",   emoji: "📖"),
                LetterWord(text: "elektr",  emoji: "⚡"),
                LetterWord(text: "ekran",   emoji: "📺"),
                LetterWord(text: "erkak",   emoji: "👨")
            ]
        case "f":
            return [
                LetterWord(text: "fil",          emoji: "🐘"),
                LetterWord(text: "futbol",       emoji: "⚽"),
                LetterWord(text: "fonar",        emoji: "🔦"),
                LetterWord(text: "ferma",        emoji: "🚜"),
                LetterWord(text: "fotoapparat",  emoji: "📷"),
                LetterWord(text: "flomaster",    emoji: "🖍️"),
                LetterWord(text: "fontan",       emoji: "⛲")
            ]
        case "g":
            return [
                LetterWord(text: "gul",     emoji: "🌸"),
                LetterWord(text: "gilos",   emoji: "🍒"),
                LetterWord(text: "gazeta",  emoji: "📰"),
                LetterWord(text: "gitara",  emoji: "🎸"),
                LetterWord(text: "globus",  emoji: "🌐"),
                LetterWord(text: "guruch",  emoji: "🍚"),
                LetterWord(text: "gubka",   emoji: "🧽")
            ]
        case "h":
            return [
                LetterWord(text: "hovli",     emoji: "🏡"),
                LetterWord(text: "hasharot",  emoji: "🐛"),
                LetterWord(text: "hamyon",    emoji: "👛"),
                LetterWord(text: "handalak",  emoji: "🍈"),
                LetterWord(text: "hujjat",    emoji: "📄"),
                LetterWord(text: "hammom",    emoji: "🛁"),
                LetterWord(text: "hokkey",    emoji: "🏒")
            ]
        case "i":
            return [
                LetterWord(text: "ilon",    emoji: "🐍"),
                LetterWord(text: "it",      emoji: "🐕"),
                LetterWord(text: "igna",    emoji: "🪡"),
                LetterWord(text: "idish",   emoji: "🍽️"),
                LetterWord(text: "ip",      emoji: "🧵"),
                LetterWord(text: "imorat",  emoji: "🏢"),
                LetterWord(text: "inson",   emoji: "🧑"),
                LetterWord(text: "ikki",    emoji: "2️⃣")
            ]
        case "j":
            return [
                LetterWord(text: "jiraf",              emoji: "🦒"),
                LetterWord(text: "jo" + okina + "ja",  emoji: "🐤"),
                LetterWord(text: "jun",                emoji: "🧶"),
                LetterWord(text: "jurnal",             emoji: "📔"),
                LetterWord(text: "jamoa",              emoji: "👥"),
                LetterWord(text: "jinsi",              emoji: "👖")
            ]
        case "k":
            return [
                LetterWord(text: "kitob",      emoji: "📚"),
                LetterWord(text: "kapalak",    emoji: "🦋"),
                LetterWord(text: "kalit",      emoji: "🔑"),
                LetterWord(text: "kema",       emoji: "🚢"),
                LetterWord(text: "kiyik",      emoji: "🦌"),
                LetterWord(text: "koptok",     emoji: "⚽"),
                LetterWord(text: "kuchuk",     emoji: "🐶"),
                LetterWord(text: "kartoshka",  emoji: "🥔"),
                LetterWord(text: "karam",      emoji: "🥬"),
                LetterWord(text: "kalamush",   emoji: "🐭")
            ]
        case "l":
            return [
                LetterWord(text: "lola",   emoji: "🌷"),
                LetterWord(text: "limon",  emoji: "🍋"),
                LetterWord(text: "lampa",  emoji: "💡"),
                LetterWord(text: "lift",   emoji: "🛗"),
                LetterWord(text: "lenta",  emoji: "🎀"),
                LetterWord(text: "lab",    emoji: "👄")
            ]
        case "m":
            return [
                LetterWord(text: "mushuk",                    emoji: "🐱"),
                LetterWord(text: "maymun",                    emoji: "🐵"),
                LetterWord(text: "mashina",                   emoji: "🚗"),
                LetterWord(text: "meva",                      emoji: "🍏"),
                LetterWord(text: "muz",                       emoji: "🧊"),
                LetterWord(text: "mikroskop",                 emoji: "🔬"),
                LetterWord(text: "makkajo" + okina + "xori",  emoji: "🌽"),
                LetterWord(text: "muzqaymoq",                 emoji: "🍦"),
                LetterWord(text: "masjid",                    emoji: "🕌"),
                LetterWord(text: "mix",                       emoji: "🔩")
            ]
        case "n":
            return [
                LetterWord(text: "non",       emoji: "🍞"),
                LetterWord(text: "nok",       emoji: "🍐"),
                LetterWord(text: "nay",       emoji: "🪈"),
                LetterWord(text: "nur",       emoji: "☀️"),
                LetterWord(text: "nonushta",  emoji: "🍳"),
                LetterWord(text: "noutbuk",   emoji: "💻")
            ]
        case "o":
            return [
                LetterWord(text: "olma",     emoji: "🍎"),
                LetterWord(text: "oy",       emoji: "🌙"),
                LetterWord(text: "ot",       emoji: "🐴"),
                LetterWord(text: "ona",      emoji: "👩"),
                LetterWord(text: "oshxona",  emoji: "🍳"),
                LetterWord(text: "olov",     emoji: "🔥"),
                LetterWord(text: "oyna",     emoji: "🪞"),
                LetterWord(text: "oltin",    emoji: "🥇"),
                LetterWord(text: "oqqush",   emoji: "🦢"),
                LetterWord(text: "olcha",    emoji: "🍒")
            ]
        case "p":
            return [
                LetterWord(text: "pomidor",   emoji: "🍅"),
                LetterWord(text: "piyoz",     emoji: "🧅"),
                LetterWord(text: "poyabzal",  emoji: "👟"),
                LetterWord(text: "palto",     emoji: "🧥"),
                LetterWord(text: "paypoq",    emoji: "🧦"),
                LetterWord(text: "pishloq",   emoji: "🧀"),
                LetterWord(text: "poyezd",    emoji: "🚂"),
                LetterWord(text: "pul",       emoji: "💵"),
                LetterWord(text: "palma",     emoji: "🌴"),
                LetterWord(text: "pingvin",   emoji: "🐧")
            ]
        case "q":
            return [
                LetterWord(text: "qalam",             emoji: "✏️"),
                LetterWord(text: "quyosh",            emoji: "☀️"),
                LetterWord(text: "qor",               emoji: "❄️"),
                LetterWord(text: "qush",              emoji: "🐦"),
                LetterWord(text: "qo" + okina + "y",  emoji: "🐑"),
                LetterWord(text: "qozon",             emoji: "🍲"),
                LetterWord(text: "qaychi",            emoji: "✂️"),
                LetterWord(text: "qulf",              emoji: "🔒"),
                LetterWord(text: "qovun",             emoji: "🍈"),
                LetterWord(text: "qulupnay",          emoji: "🍓")
            ]
        case "r":
            return [
                LetterWord(text: "arra",                 emoji: "🪚"),
                LetterWord(text: "randa",                emoji: "🛠️"),
                LetterWord(text: "ra" + tutuq + "no",    emoji: "🌺"),
                LetterWord(text: "rasm",                 emoji: "🖼️"),
                LetterWord(text: "rang",                 emoji: "🎨"),
                LetterWord(text: "raqs",                 emoji: "💃"),
                LetterWord(text: "robot",                emoji: "🤖"),
                LetterWord(text: "raketa",               emoji: "🚀"),
                LetterWord(text: "ruchka",               emoji: "🖊️"),
                LetterWord(text: "ro" + okina + "mol",   emoji: "🧕")
            ]
        case "s":
            return [
                LetterWord(text: "soat",      emoji: "⏰"),
                LetterWord(text: "sabzi",     emoji: "🥕"),
                LetterWord(text: "samolyot",  emoji: "✈️"),
                LetterWord(text: "sigir",     emoji: "🐄"),
                LetterWord(text: "suv",       emoji: "💧"),
                LetterWord(text: "sut",       emoji: "🥛"),
                LetterWord(text: "sichqon",   emoji: "🐭"),
                LetterWord(text: "stul",      emoji: "🪑"),
                LetterWord(text: "sumka",     emoji: "👜"),
                LetterWord(text: "sovun",     emoji: "🧼")
            ]
        case "t":
            return [
                LetterWord(text: "tulki",        emoji: "🦊"),
                LetterWord(text: "tovuq",        emoji: "🐔"),
                LetterWord(text: "tarvuz",       emoji: "🍉"),
                LetterWord(text: "tish",         emoji: "🦷"),
                LetterWord(text: "tuz",          emoji: "🧂"),
                LetterWord(text: "telefon",      emoji: "📱"),
                LetterWord(text: "televizor",    emoji: "📺"),
                LetterWord(text: "tuya",         emoji: "🐫"),
                LetterWord(text: "tog" + okina,  emoji: "⛰️"),
                LetterWord(text: "tomchi",       emoji: "💧")
            ]
        case "u":
            return [
                LetterWord(text: "uy",          emoji: "🏠"),
                LetterWord(text: "uzum",        emoji: "🍇"),
                LetterWord(text: "ukki",        emoji: "🦉"),
                LetterWord(text: "uzuk",        emoji: "💍"),
                LetterWord(text: "usta",        emoji: "🔧"),
                LetterWord(text: "uchburchak",  emoji: "🔺")
            ]
        case "v":
            return [
                LetterWord(text: "velosiped",  emoji: "🚲"),
                LetterWord(text: "vaza",       emoji: "🏺"),
                LetterWord(text: "vertolyot",  emoji: "🚁"),
                LetterWord(text: "vagon",      emoji: "🚃"),
                LetterWord(text: "vilka",      emoji: "🍴"),
                LetterWord(text: "vulqon",     emoji: "🌋")
            ]
        case "x":
            return [
                LetterWord(text: "xo" + okina + "roz",  emoji: "🐓"),
                LetterWord(text: "xat",                 emoji: "✉️"),
                LetterWord(text: "xarita",              emoji: "🗺️"),
                LetterWord(text: "xalta",               emoji: "🛍️"),
                LetterWord(text: "xamir",               emoji: "🥟")
            ]
        case "y":
            return [
                LetterWord(text: "yulduz",               emoji: "⭐"),
                LetterWord(text: "yomg" + okina + "ir",  emoji: "🌧️"),
                LetterWord(text: "yurak",                emoji: "❤️"),
                LetterWord(text: "yaproq",               emoji: "🍂"),
                LetterWord(text: "yong" + okina + "oq",  emoji: "🌰"),
                LetterWord(text: "yo" + okina + "l",     emoji: "🛣️"),
                LetterWord(text: "yer",                  emoji: "🌍"),
                LetterWord(text: "yoz",                  emoji: "☀️")
            ]
        case "z":
            return [
                LetterWord(text: "zebra",   emoji: "🦓"),
                LetterWord(text: "zanjir",  emoji: "⛓️"),
                LetterWord(text: "zavod",   emoji: "🏭"),
                LetterWord(text: "zaytun",  emoji: "🫒"),
                LetterWord(text: "zontik",  emoji: "☂️")
            ]
        case "o_apos":
            return [
                LetterWord(text: "o" + okina + "rdak",              emoji: "🦆"),
                LetterWord(text: "o" + okina + "rmon",              emoji: "🌲"),
                LetterWord(text: "o" + okina + "tin",               emoji: "🪵"),
                LetterWord(text: "o" + okina + "rgimchak",          emoji: "🕷️"),
                LetterWord(text: "o" + okina + "g" + okina + "il",  emoji: "👦"),
                LetterWord(text: "o" + okina + "simlik",            emoji: "🌱"),
                LetterWord(text: "o" + okina + "t",                 emoji: "🌿")
            ]
        case "g_apos":
            return [
                LetterWord(text: "g" + okina + "oz",       emoji: "🪿"),
                LetterWord(text: "g" + okina + "ildirak",  emoji: "🛞"),
                LetterWord(text: "g" + okina + "or",       emoji: "🕳️"),
                LetterWord(text: "g" + okina + "isht",     emoji: "🧱"),
                LetterWord(text: "bog" + okina,            emoji: "🌳"),
                LetterWord(text: "tog" + okina,            emoji: "⛰️"),
                LetterWord(text: "yog" + okina,            emoji: "🧈")
            ]
        case "sh":
            return [
                LetterWord(text: "shar",                  emoji: "🎈"),
                LetterWord(text: "shakar",                emoji: "🍬"),
                LetterWord(text: "shamol",                emoji: "🌬️"),
                LetterWord(text: "shaftoli",              emoji: "🍑"),
                LetterWord(text: "shim",                  emoji: "👖"),
                LetterWord(text: "shokolad",              emoji: "🍫"),
                LetterWord(text: "shahar",                emoji: "🏙️"),
                LetterWord(text: "shisha",                emoji: "🍾"),
                LetterWord(text: "shlyapa",               emoji: "👒"),
                LetterWord(text: "sholg" + okina + "om",  emoji: "🥬")
            ]
        case "ch":
            return [
                LetterWord(text: "choy",                   emoji: "🍵"),
                LetterWord(text: "chelak",                 emoji: "🪣"),
                LetterWord(text: "chumoli",                emoji: "🐜"),
                LetterWord(text: "chivin",                 emoji: "🦟"),
                LetterWord(text: "chaqmoq",                emoji: "⚡"),
                LetterWord(text: "chiroq",                 emoji: "💡"),
                LetterWord(text: "chana",                  emoji: "🛷"),
                LetterWord(text: "chipta",                 emoji: "🎫"),
                LetterWord(text: "chizg" + okina + "ich",  emoji: "📏"),
                LetterWord(text: "cho" + okina + "tka",    emoji: "🪥")
            ]
        case "ng":
            return [
                LetterWord(text: "tong",                                emoji: "🌅"),
                LetterWord(text: "bodring",                              emoji: "🥒"),
                LetterWord(text: "ohang",                               emoji: "🎵"),
                LetterWord(text: "singil",                              emoji: "👧"),
                LetterWord(text: "ming",                                emoji: "🔢"),
                LetterWord(text: "rang",                                emoji: "🎨")
            ]
        default:
            return []
        }
    }

    /// So'zdagi qaysi belgilar shu harfga tegishli ekanini belgilaydi.
    ///
    /// Bu bolaga harf so'zning qayerida turganini ko'rsatadi — "arra" da o'rtada,
    /// "raketa" da boshida. Ko'p belgili harflar (`Sh`, `Ch`, `Ng`, `Oʻ`, `Gʻ`) ham
    /// to'g'ri ishlaydi, chunki moslik belgilab-belgilab tekshiriladi.
    ///
    /// Qaytadigan massiv uzunligi so'zdagi belgilar soniga teng.
    static func letterMask(word: String, letter: String) -> [Bool] {
        var characters: [String] = []
        for character in word {
            characters.append(String(character))
        }
        var target: [String] = []
        for character in letter.lowercased() {
            target.append(String(character))
        }

        var mask: [Bool] = []
        for _ in characters {
            mask.append(false)
        }
        if target.isEmpty {
            return mask
        }

        var index = 0
        while index + target.count <= characters.count {
            var matches = true
            for offset in 0..<target.count {
                if characters[index + offset].lowercased() != target[offset] {
                    matches = false
                    break
                }
            }
            if matches {
                for offset in 0..<target.count {
                    mask[index + offset] = true
                }
                index += target.count
            } else {
                index += 1
            }
        }
        return mask
    }
}
