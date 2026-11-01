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

/// Har bir harf uchun misol so'zlar (28 ta harf, jami 230 so'z). So'zlar yangi alifboda yozilgan.
///
/// Tanlash mezoni: bola biladigan, ko'z oldiga keltiradigan aniq narsa, va emoji so'zning
/// ma'nosini HAQIQATAN ko'rsatishi. Mos emoji topilmagan so'zlar qo'shilmadi — noto'g'ri
/// surat bolaga noto'g'ri bog'lanish o'rgatadi. Shuning uchun harflarda so'z soni har xil
/// (5 tadan 10 tagacha).
///
/// DIQQAT: so'zlar va imlo o'zbek tili o'qituvchisi tomonidan tasdiqlanishi kerak.
/// Tekshirilgani: har bir so'z o'z harfini o'z ichiga oladi va har birida emoji bor.
enum LetterWords {

    /// Tutuq belgisi (U+02BC) — "raʼno" dagi belgi. Yangi alifboda ham o'zgarmadi
    /// (`Ö`, `Ğ` harflarida alohida belgi yo'q).
    private static let tutuq = "\u{02BC}"

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
                LetterWord(text: "arça",     emoji: "🌲"),
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
                LetterWord(text: "böri",  emoji: "🐺"),
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
                LetterWord(text: "eşak",   emoji: "🫏"),
                LetterWord(text: "eşik",   emoji: "🚪"),
                LetterWord(text: "eçki",   emoji: "🐐"),
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
                LetterWord(text: "guruç",  emoji: "🍚"),
                LetterWord(text: "gubka",   emoji: "🧽")
            ]
        case "h":
            return [
                LetterWord(text: "hovli",     emoji: "🏡"),
                LetterWord(text: "haşarot",  emoji: "🐛"),
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
                LetterWord(text: "idiş",   emoji: "🍽️"),
                LetterWord(text: "ip",      emoji: "🧵"),
                LetterWord(text: "imorat",  emoji: "🏢"),
                LetterWord(text: "inson",   emoji: "🧑"),
                LetterWord(text: "ikki",    emoji: "2️⃣")
            ]
        case "j":
            return [
                LetterWord(text: "jiraf",              emoji: "🦒"),
                LetterWord(text: "jöja",  emoji: "🐤"),
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
                LetterWord(text: "kuçuk",     emoji: "🐶"),
                LetterWord(text: "kartoşka",  emoji: "🥔"),
                LetterWord(text: "karam",      emoji: "🥬"),
                LetterWord(text: "kalamuş",   emoji: "🐭")
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
                LetterWord(text: "muşuk",                    emoji: "🐱"),
                LetterWord(text: "maymun",                    emoji: "🐵"),
                LetterWord(text: "maşina",                   emoji: "🚗"),
                LetterWord(text: "meva",                      emoji: "🍏"),
                LetterWord(text: "muz",                       emoji: "🧊"),
                LetterWord(text: "mikroskop",                 emoji: "🔬"),
                LetterWord(text: "makkajöxori",  emoji: "🌽"),
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
                LetterWord(text: "nonuşta",  emoji: "🍳"),
                LetterWord(text: "noutbuk",   emoji: "💻")
            ]
        case "o":
            return [
                LetterWord(text: "olma",     emoji: "🍎"),
                LetterWord(text: "oy",       emoji: "🌙"),
                LetterWord(text: "ot",       emoji: "🐴"),
                LetterWord(text: "ona",      emoji: "👩"),
                LetterWord(text: "oşxona",  emoji: "🍳"),
                LetterWord(text: "olov",     emoji: "🔥"),
                LetterWord(text: "oyna",     emoji: "🪞"),
                LetterWord(text: "oltin",    emoji: "🥇"),
                LetterWord(text: "oqquş",   emoji: "🦢"),
                LetterWord(text: "olça",    emoji: "🍒")
            ]
        case "p":
            return [
                LetterWord(text: "pomidor",   emoji: "🍅"),
                LetterWord(text: "piyoz",     emoji: "🧅"),
                LetterWord(text: "poyabzal",  emoji: "👟"),
                LetterWord(text: "palto",     emoji: "🧥"),
                LetterWord(text: "paypoq",    emoji: "🧦"),
                LetterWord(text: "pişloq",   emoji: "🧀"),
                LetterWord(text: "poyezd",    emoji: "🚂"),
                LetterWord(text: "pul",       emoji: "💵"),
                LetterWord(text: "palma",     emoji: "🌴"),
                LetterWord(text: "pingvin",   emoji: "🐧")
            ]
        case "q":
            return [
                LetterWord(text: "qalam",             emoji: "✏️"),
                LetterWord(text: "quyoş",            emoji: "☀️"),
                LetterWord(text: "qor",               emoji: "❄️"),
                LetterWord(text: "quş",              emoji: "🐦"),
                LetterWord(text: "qöy",  emoji: "🐑"),
                LetterWord(text: "qozon",             emoji: "🍲"),
                LetterWord(text: "qayçi",            emoji: "✂️"),
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
                LetterWord(text: "ruçka",               emoji: "🖊️"),
                LetterWord(text: "römol",   emoji: "🧕")
            ]
        case "s":
            return [
                LetterWord(text: "soat",      emoji: "⏰"),
                LetterWord(text: "sabzi",     emoji: "🥕"),
                LetterWord(text: "samolyot",  emoji: "✈️"),
                LetterWord(text: "sigir",     emoji: "🐄"),
                LetterWord(text: "suv",       emoji: "💧"),
                LetterWord(text: "sut",       emoji: "🥛"),
                LetterWord(text: "siçqon",   emoji: "🐭"),
                LetterWord(text: "stul",      emoji: "🪑"),
                LetterWord(text: "sumka",     emoji: "👜"),
                LetterWord(text: "sovun",     emoji: "🧼")
            ]
        case "t":
            return [
                LetterWord(text: "tulki",        emoji: "🦊"),
                LetterWord(text: "tovuq",        emoji: "🐔"),
                LetterWord(text: "tarvuz",       emoji: "🍉"),
                LetterWord(text: "tiş",         emoji: "🦷"),
                LetterWord(text: "tuz",          emoji: "🧂"),
                LetterWord(text: "telefon",      emoji: "📱"),
                LetterWord(text: "televizor",    emoji: "📺"),
                LetterWord(text: "tuya",         emoji: "🐫"),
                LetterWord(text: "toğ",  emoji: "⛰️"),
                LetterWord(text: "tomçi",       emoji: "💧")
            ]
        case "u":
            return [
                LetterWord(text: "uy",          emoji: "🏠"),
                LetterWord(text: "uzum",        emoji: "🍇"),
                LetterWord(text: "ukki",        emoji: "🦉"),
                LetterWord(text: "uzuk",        emoji: "💍"),
                LetterWord(text: "usta",        emoji: "🔧"),
                LetterWord(text: "uçburçak",  emoji: "🔺")
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
                LetterWord(text: "xöroz",  emoji: "🐓"),
                LetterWord(text: "xat",                 emoji: "✉️"),
                LetterWord(text: "xarita",              emoji: "🗺️"),
                LetterWord(text: "xalta",               emoji: "🛍️"),
                LetterWord(text: "xamir",               emoji: "🥟")
            ]
        case "y":
            return [
                LetterWord(text: "yulduz",               emoji: "⭐"),
                LetterWord(text: "yomğir",  emoji: "🌧️"),
                LetterWord(text: "yurak",                emoji: "❤️"),
                LetterWord(text: "yaproq",               emoji: "🍂"),
                LetterWord(text: "yonğoq",  emoji: "🌰"),
                LetterWord(text: "yöl",     emoji: "🛣️"),
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
                LetterWord(text: "ördak",              emoji: "🦆"),
                LetterWord(text: "örmon",              emoji: "🌲"),
                LetterWord(text: "ötin",               emoji: "🪵"),
                LetterWord(text: "örgimçak",          emoji: "🕷️"),
                LetterWord(text: "öğil",  emoji: "👦"),
                LetterWord(text: "ösimlik",            emoji: "🌱"),
                LetterWord(text: "öt",                 emoji: "🌿")
            ]
        case "g_apos":
            return [
                LetterWord(text: "ğoz",       emoji: "🪿"),
                LetterWord(text: "ğildirak",  emoji: "🛞"),
                LetterWord(text: "ğor",       emoji: "🕳️"),
                LetterWord(text: "ğişt",     emoji: "🧱"),
                LetterWord(text: "boğ",            emoji: "🌳"),
                LetterWord(text: "toğ",            emoji: "⛰️"),
                LetterWord(text: "yoğ",            emoji: "🧈")
            ]
        case "sh":
            return [
                LetterWord(text: "şar",                  emoji: "🎈"),
                LetterWord(text: "şakar",                emoji: "🍬"),
                LetterWord(text: "şamol",                emoji: "🌬️"),
                LetterWord(text: "şaftoli",              emoji: "🍑"),
                LetterWord(text: "şim",                  emoji: "👖"),
                LetterWord(text: "şokolad",              emoji: "🍫"),
                LetterWord(text: "şahar",                emoji: "🏙️"),
                LetterWord(text: "şişa",                emoji: "🍾"),
                LetterWord(text: "şlyapa",               emoji: "👒"),
                LetterWord(text: "şolğom",  emoji: "🥬")
            ]
        case "ch":
            return [
                LetterWord(text: "çoy",                   emoji: "🍵"),
                LetterWord(text: "çelak",                 emoji: "🪣"),
                LetterWord(text: "çumoli",                emoji: "🐜"),
                LetterWord(text: "çivin",                 emoji: "🦟"),
                LetterWord(text: "çaqmoq",                emoji: "⚡"),
                LetterWord(text: "çiroq",                 emoji: "💡"),
                LetterWord(text: "çana",                  emoji: "🛷"),
                LetterWord(text: "çipta",                 emoji: "🎫"),
                LetterWord(text: "çizğiç",  emoji: "📏"),
                LetterWord(text: "çötka",    emoji: "🪥")
            ]
        default:
            return []
        }
    }

    /// So'zdagi qaysi belgilar shu harfga tegishli ekanini belgilaydi.
    ///
    /// Bu bolaga harf so'zning qayerida turganini ko'rsatadi — "arra" da o'rtada,
    /// "raketa" da boshida. Yangi alifboda hamma harf bitta belgi (`Ö`, `Ğ`, `Ş`, `Ç` ham), shuning
    /// uchun `g` harfi "toğ" dagi `ğ` ni, `s` harfi "şar" dagi `ş` ni belgilamaydi.
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
