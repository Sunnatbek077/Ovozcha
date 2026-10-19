// Murabbiy ovozi uchun yozib olish ro'yxatini (README.md) dars ma'lumotlaridan yasaydi.
// To'g'ridan-to'g'ri ishga tushirilmaydi: `generate.sh` uni ilova manba fayllari bilan birga
// kompilyatsiya qiladi. Ro'yxatni qo'lda tahrirlamang — darslar o'zgarsa, qayta yasang.

@main
struct Manifest {

    static func main() {
        var out: [String] = []
        var total = 0

        func table(_ title: String, _ note: String?, _ rows: [(String, String)]) {
            out.append("## \(title) (\(rows.count) ta)")
            out.append("")
            if let note = note {
                out.append(note)
                out.append("")
            }
            out.append("| Fayl | Nima deyiladi |")
            out.append("|---|---|")
            for (file, text) in rows {
                out.append("| `\(file)` | \(text) |")
            }
            out.append("")
            total += rows.count
        }

        let lessons = SoundLessons.all

        table("1. Murabbiy iboralari", nil,
              CoachAudio.catalog().map { ("coach_" + $0.key, $0.text) })

        table("2. Tovushni qanday aytish", "Har bir dars boshida va xatodan keyin aytiladi.",
              lessons.map { ($0.hintClip, $0.hint) })

        table("3. Harf tovushlari",
              "Harfning **nomi emas, tovushi** (\"er\" emas, \"r\"). Harflar, Sonlar va Talaffuz bo'limlarida ishlatiladi.",
              UzbekAlphabet.letters.map { ("letter_" + $0.id, $0.lower) })

        var drills: [(String, String)] = []
        for lesson in lessons {
            for item in lesson.allItems where item.kind == .sound || item.kind == .syllables {
                drills.append((item.modelClip, item.text.replacingOccurrences(of: " \u{00B7} ", with: ", ")))
            }
        }
        table("4. Tovush va bo'g'inlar",
              "Cho'ziladigan tovushni 2 soniyacha cho'zing; bo'g'inlar orasida qisqa pauza.",
              drills)

        var words: [String: String] = [:]
        var wrongs: [String: String] = [:]
        for lesson in lessons {
            for item in lesson.allItems where item.kind == .word || item.kind == .pair {
                words[item.modelClip] = item.text
                if item.kind == .pair {
                    wrongs[item.wrongClip] = shown(item.wrongText) + " (" + item.text + " o'rniga)"
                }
            }
        }
        table("5. So'zlar — to'g'ri aytilishi",
              "Bir so'z bir necha darsda uchrasa ham, fayl bitta.",
              words.keys.sorted().map { ($0, words[$0] ?? "") })

        table("6. Quloq o'yini — noto'g'ri aytilishi",
              "Bola qanday xato qilsa, aynan shunday ayting: aniq, lekin masxara qilmasdan.",
              wrongs.keys.sorted().map { ($0, wrongs[$0] ?? "") })

        print(header(total: total))
        print(out.joined(separator: "\n"))
    }

    /// Tashxisdagi apostrof -> o'zbek imlosi: "zo'za" -> "zoʻza".
    static func shown(_ text: String) -> String {
        return text.replacingOccurrences(of: "'", with: "\u{02BB}")
    }

    static func header(total: Int) -> String {
        return """
        # Murabbiy ovozi: yozib olish ro'yxati

        > Bu fayl avtomatik yasalgan: `sh Tools/voice-recordings/generate.sh`.
        > Qo'lda tahrirlamang — darslar o'zgarsa, skriptni qayta ishga tushiring.

        Talaffuz murabbiyi jonli ovoz bilan gapiradi (TTS emas). Har bir gap alohida qisqa fayl:
        ilova ularni ketma-ket ulab, to'liq gap yasaydi. Masalan:

            word_rasm + coach_pos_start + letter_r + coach_instead_of + letter_l + coach_i_heard
            = "rasm soʻzining boshida r oʻrniga l eshitdim."

        Fayl yo'q bo'lsa ilova buzilmaydi: murabbiy gapi faqat matn bo'lib ko'rinadi. Faqat
        **quloq o'yini** `word_*` va `wrong_*` yozuvlarisiz yopiq turadi.

        Jami: **\(total) ta fayl**. Hammasini birdan yozish shart emas — bir harfdan boshlang
        (masalan R): shu harfning ko'rsatmasi, tovushi, bo'g'inlari va so'zlari yetarli.

        ## Qayerga qo'yiladi

            Sources/Ovozcha/Resources/Audio/<fayl nomi>.m4a

        Papka yo'q bo'lsa, yarating. Qo'yilgandan keyin ilovani qayta yig'ing
        (`skip app launch`). Fayl nomi aynan jadvaldagidek bo'lishi shart (kichik harf, `_`).

        ## Yozish qoidalari

        - Format: **m4a (AAC), mono**. mp3 va wav ham ishlaydi.
        - Tinch xona, telefon og'izdan ~20 sm. Bir kishi, bir xil ohang.
        - Boshi va oxiridagi jimlikni kesing (0.1 s dan oshmasin) — bo'laklar ulanganda
          gap tabiiy eshitilishi uchun.
        - Bolaga gapirgandek: iliq, sekinroq, aniq.
        - Bo'lak gaplarni (masalan `coach_pos_start`) gap o'rtasidagidek, pasaymaydigan ohangda ayting.

        ## Qo'shimcha foyda: nutq tanish etalonlari

        `word_*` yozuvlari tekshiruv aniqligini ham oshiradi. Whisper to'g'ri aytilgan so'zni ham
        xato yozishi mumkin ("robot" -> "Lobots"). Buni bola xatosi deb hisoblamaslik uchun ularni
        `Tools/reference-transcripts/audio/` ga so'zning o'zi nomi bilan nusxalang
        (`word_robot.m4a` -> `robot.m4a`) va `Tools/reference-transcripts/build.py` ni ishga tushiring.

        """
    }
}
