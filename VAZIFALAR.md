# Ovozcha — sizning vazifalaringiz

Bu ro'yxatdagi ishlarni kod bilan hal qilib bo'lmaydi: ular sizning qaroringiz, ovozingiz,
hisobingiz yoki mutaxassis bahosini talab qiladi. Muhimlik tartibida.

Oxirgi yangilanish: 2026-09-27 (imlo lugʻati qoʻshildi).

---

## 1. Shoshilinch: Groq kalitini almashtiring

Groq API kaliti suhbatda ochiq yuborilgan edi, shuning uchun uni **eskirgan** deb hisoblang.

- [ ] [console.groq.com/keys](https://console.groq.com/keys) da eski kalitni o'chiring va yangisini yarating.
- [ ] Yangi kalitni faqat `Android/app/src/main/res/values/secrets.xml` ga yozing
      (fayl `.gitignore` da, manba kodiga tushmaydi). Namuna: `Android/secrets.example.xml`.
- [ ] Kalitni hech qachon kodga, `Info.plist` ga commit qilinadigan faylga yoki chatga yozmang.

## 2. Murabbiy ovozini yozib olish

To'liq ro'yxat, fayl nomlari va yozish qoidalari: [`Tools/voice-recordings/README.md`](Tools/voice-recordings/README.md).
Jami **410 ta** qisqa fayl. Ular qo'shilmaguncha murabbiy faqat matn bilan gapiradi,
quloq o'yini esa yopiq turadi.

- [ ] **Bitta harfdan boshlang (R tavsiya etiladi).** Shu harfga kerak bo'ladigan fayllar:
      `coach_hint_r`, `letter_r`, `sound_rrr`, `syl_ra_ro_ru`, `syl_ar_or_ur`, R so'zlari (`word_*`),
      quloq o'yini variantlari (`wrong_*`) va 25 ta umumiy ibora (`coach_*`).
- [ ] Fayllarni `Sources/Ovozcha/Resources/Audio/` ga qo'ying (papkani yarating) va ilovani qayta yig'ing.
- [ ] Qolgan harflarni asta-sekin qo'shing. Qaysi fayl qaysi harfga tegishli ekani ro'yxatda ko'rsatilgan.
- [ ] Darslar o'zgarsa (masalan, `LetterWords.swift` ga so'z qo'shsangiz), ro'yxatni qayta yasang:

      sh Tools/voice-recordings/generate.sh

## 3. Nutq tanish etalonlari (R tovushi xavfini kamaytiradi)

Whisper to'g'ri aytilgan "robot"ni ham "Lobots" deb yozishi mumkin. Shunda murabbiy
to'g'ri gapirgan bolaga "r oʻrniga l eshitdim" deydi. Etalon yozuvlar buni to'xtatadi.

- [ ] 2-bosqichdagi `word_*.m4a` fayllarini `Tools/reference-transcripts/audio/` ga so'zning o'zi
      nomi bilan nusxalang (`word_robot.m4a` → `robot.m4a`). Bolaga yaqin ovoz bo'lsa yaxshiroq.
- [ ] Skriptni ishga tushiring (kalit muhitdan olinadi):

      export GROQ_API_KEY=...
      python3 Tools/reference-transcripts/build.py

- [ ] Chiqqan qatorlarni `Sources/Ovozcha/Features/Letters/Model/LetterWords.swift` dagi mos so'zga ko'chiring.

## 4. Haqiqiy telefonda, haqiqiy bola bilan sinash

Emulyator mikrofoni jim, shuning uchun talaffuzni tekshirish zanjiri faqat texnik jihatdan
sinalgan. **Bola ovozida qanchalik to'g'ri ishlashi hali noma'lum.**

- [ ] Android'da (iloji bo'lsa, oddiy/arzon telefonda) va iPhone'da sinang.
- [ ] R darsining so'z bosqichlarida bola to'g'ri aytganda "Barakalla" chiqyaptimi?
      Xato aytganda xato to'g'ri topilyaptimi?
- [ ] Bola past ovozda gapirganda "Eshitmadim" ko'p chiqsa, bu haqda menga ayting.
      Chegara: `WordRecorder.silenceThreshold` (hozir 0.03). Logda `yozuv balandligi ...`
      qatori haqiqiy qiymatni ko'rsatadi.
- [ ] Topilgan muammolarni menga yuboring: qaysi so'z aytilgan va ekranda nima chiqqan
      ("Eshitganim: ...").

## 5. iOS'da so'z tekshiruvini yoqish

Hozir `Darwin/Info.plist` da na kalit, na server manzili bor. Shu sabab iOS'da so'z tekshiruvi
o'chiq, ekranda "Tekshirish hozir ishlamayapti" chiqadi. Android'da ishlaydi.

- [ ] Sinov uchun: `Darwin/Info.plist` ga `OvozchaGroqKey` qo'shing.
      **Bu faylni commit qilmang** — kalit ilova ichiga tushadi.
- [ ] Ishlab chiqarish uchun: 6-bo'limdagi server tayyor bo'lgach, faqat `OvozchaTranscriptionEndpoint` yozing.

## 6. Ilovani chiqarishdan oldin (ishlab chiqarish)

- [ ] **O'z proksi serveringiz.** Kalit ilova ichida bo'lmasligi kerak: ilovani ochgan har kim
      uni topib olishi mumkin. Server ovoz faylini qabul qiladi, Groq'ga (yoki boshqa xizmatga)
      yuboradi va matnni qaytaradi. Manzili `OvozchaTranscriptionEndpoint` ga yoziladi
      (faqat `https`). Serverni yozishda yordam kerak bo'lsa, ayting.
- [ ] **Bolalar ovozi va maxfiylik.** Ilova 3–5 yoshli bolaning ovozini tashqi serverga yuboradi.
      Buning uchun kerak bo'ladi:
  - ota-onaning roziligi (masalan, birinchi ishga tushishda);
  - maxfiylik siyosati: nima yuboriladi, qayerga, qancha saqlanadi;
  - App Store "Kids" va Google Play "Families" talablariga moslik tekshiruvi;
  - Groq (yoki tanlangan xizmat) ovozni saqlaydimi yoki o'qitishda ishlatadimi — shartlarini o'qing.
- [ ] **Imlo lug'ati litsenziyasi.** Lug'at ochiq [uz-hunspell](https://github.com/u2b3k/uz-hunspell)
      loyihasidan olinadi (GPL-3.0). Ilova uni o'zi bilan olib yurmaydi — foydalanuvchi telefoniga
      internetdan yuklanadi, ekranda manba ko'rsatilgan. Do'konga chiqarishdan oldin bu yondashuvni
      yurist bilan tasdiqlang yoki mualliflardan (Alisher Jalolov, Bilolbek Normoʻminov) ruxsat so'rang.
- [ ] **Ota-ona tekshiruvi (parental gate).** Ota-ona paneli endi tab emas, Bosh ekrandagi
      tugma orqali ochiladi — bola tasodifan kirmasligi uchun. App Store "Kids" toifasi va
      Google Play "Families" talablari uchun unga oddiy tekshiruv qo'shish kerak (masalan,
      "3 × 4 = ?"). Qaysi turdagi tekshiruv bo'lishini ayting — men qo'shaman.
- [ ] Muqobil xizmatlarni ko'rib chiqing: o'zbek tiliga moslangan UzbekVoice, Muxlisa, Aisha.
      Ularni 3-bo'limdagi yozuvlar bilan Whisper'ga solishtirish mumkin.

## 7. Mutaxassis tekshiruvi

- [ ] **Logoped:**
  - bolalar qaysi tovushni qaysisiga almashtirishi (`SpeechDiagnosis.knownSwaps`,
    `SoundLessons.pairSwap`);
  - 29 ta talaffuz ko'rsatmasi (`Strings.Coach.hint` — `Sources/Ovozcha/Core/Strings.swift`);
  - yosh me'yorlari. Masalan, R tovushi odatda 5–6 yoshgacha to'liq shakllanmaydi:
    3–4 yoshli bolada R o'rniga L aytilishi normal bo'lishi mumkin. Ilova buni "muammo"
    sifatida ko'rsatmasligi kerak.
- [ ] **O'zbek tili o'qituvchisi:** 236 ta misol so'z va ularning imlosi
      (`Sources/Ovozcha/Features/Letters/Model/LetterWords.swift`), emoji so'zga mosligi.
      Har bir so'z avtomatik ravishda Talaffuz darslariga ham tushadi.
- [ ] **Imlo lug'ati sifati:** lug'at spell-checker uchun yig'ilgan, 95 000 so'z ichida kam
      uchraydigan yoki shubhali so'zlar bor (masalan "bedandit", "glistogon"). Bir necha tanish
      so'zni qidirib, natijalarni ko'rib chiqing. Xato topilsa, uz-hunspell loyihasiga xabar berish mumkin.
- [ ] Murabbiy gaplari bolaga tushunarli va iliqmi (`Strings.Coach`) — o'qituvchi yoki ota-onalar fikri.

## 8. Loyiha xavfsizligi

- [x] Loyiha git'da va GitHub'da: [github.com/Sunnatbek077/Ovozcha](https://github.com/Sunnatbek077/Ovozcha) (public).
- [ ] Repo ochiq: kalitni hech qachon commit qilmang. `Darwin/Info.plist` ga kalit yozsangiz,
      README'dagi 5-qadamni bajaring (`git update-index --skip-worktree`).

---

## Men qila oladigan ishlar (buyruq bersangiz)

Bular sizni kutmaydi — "davom et" desangiz, bajaraman:

- **Test to'plamini ishga tushadigan qilish.** Testlar yozilgan (`Tests/OvozchaTests/`),
  lekin to'plam kompilyatsiya bo'lmaydi: ilova kodi macOS'da qurilmaydi.
- **Harflar ekranini tezlashtirish.** Oldingi urinish natija bermagan; tab almashish o'lchovlari
  ham juda tarqoq. Buni haqiqiy telefonda release build'da o'lchash kerak.
- **Proksi server** (6-bo'lim).
