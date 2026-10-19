# Ovozcha

3–5 yoshli o'zbek bolalari uchun savodxonlik ilovasi: harf va sonlarni yozish, tovushlarni
eshitish, talaffuz murabbiyi va imlo lug'ati. Bitta Swift/SwiftUI kodidan **iOS** va **Android**
ilovasi chiqadi: Android qismini [Skip](https://skip.dev) Swift kodidan Kotlin/Jetpack Compose'ga
o'girib quradi.

| Bo'lim | Ishlashi |
|---|---|
| Harflar, Sonlar | Internetsiz |
| Talaffuz murabbiyi | Internet + nutq tanish xizmati kerak (pastda [5-qadam](#5-qadam-talaffuz-uchun-kalit-ixtiyoriy)) |
| Imlo lug'ati | Birinchi ochilishda internetdan yuklanadi, keyin keshdan ishlaydi |

---

## Talablar

Loyiha faqat **macOS** da quriladi: iOS qismi uchun Xcode kerak, Skip ham Xcode orqali ishlaydi.

| Vosita | Versiya | Izoh |
|---|---|---|
| macOS | 14+ | Apple Silicon (M1 va yangi) tavsiya etiladi |
| Xcode | **26 yoki yangi** | Kodda iOS 26 API'lari (Liquid Glass) bor, eski SDK bilan qurilmaydi. Xcode 27.1 da sinalgan |
| Homebrew | istalgan | [brew.sh](https://brew.sh) |
| Skip | 1.9.10+ | Homebrew orqali o'rnatiladi, Gradle va JDK'ni ham olib keladi |
| Android Studio | istalgan yangi | Faqat Android SDK va emulyator uchun kerak, kod unda yozilmaydi |

Ilova ishlaydigan qurilmalar: **iOS 17+**, **Android 12+** (API 31).

---

## 1-qadam. Vositalarni o'rnatish

Bu qadam kompyuterga bir marta bajariladi.

**Xcode.** App Store'dan o'rnating, bir marta ochib, litsenziyani qabul qiling va iOS
simulyatorini yuklab oling (Xcode o'zi taklif qiladi). Keyin:

```bash
sudo xcode-select -s /Applications/Xcode.app
```

**Skip** (Gradle va OpenJDK bilan birga o'rnatiladi):

```bash
brew install skiptools/skip/skip
```

**Android Studio.** [developer.android.com/studio](https://developer.android.com/studio) dan
o'rnating va bir marta ochib, birinchi sozlash ustasini (SDK yuklash) oxirigacha o'tkazing.
SDK odatda `~/Library/Android/sdk` ga tushadi.

**Tekshiruv.** Hammasi joyidami, Skip o'zi aytadi:

```bash
skip doctor
```

Har bir qatorda `[✓]` bo'lishi kerak. `[!] A new version is available` ogohlantirishi
xalaqit bermaydi. `[✗]` chiqsa, o'sha qatordagi ko'rsatmani bajaring.

---

## 2-qadam. Repozitoriyni klonlash

```bash
git clone https://github.com/Sunnatbek077/Ovozcha.git
```

```bash
cd Ovozcha
```

Swift paketlari (Skip, SkipUI) birinchi qurishda o'zi yuklanadi. Aniq versiyalar
`Package.resolved` da qotirilgan, shuning uchun hamma bir xil versiya bilan quradi.

---

## 3-qadam. iOS'da ishga tushirish

### Xcode orqali

```bash
open Project.xcworkspace
```

1. Xcode yuqorisidagi sxema ro'yxatidan **`Ovozcha App`** ni tanlang.
   `Ovozcha` (ilovasiz) sxema faqat kutubxonani quradi: ilova ishga tushmaydi va audio fayllar
   ichiga kirmaydi.
2. Qurilma sifatida iPhone simulyatorini tanlang (masalan, *iPhone 17*).
3. **⌘R** (Product → Run).

Birinchi qurish bir necha daqiqa oladi: paketlar yuklanadi va Skip ishga tushadi.

> **Muhim: Xcode Android'ni ham quradi.** `Darwin/Ovozcha.xcconfig` da
> `SKIP_ACTION = launch` turibdi: har gal ⌘R bosilganda Xcode Android ilovasini ham quradi va
> ochiq Android emulyatoriga o'rnatadi. Android emulyatori ochiq bo'lmasa, bu qism xato berishi
> mumkin. Faqat iOS kerak bo'lsa, quyidagi buyruq qulayroq. Xcode'da esa shu faylda
> `SKIP_ACTION = none` qatorini yoqib qo'ying (bu o'zgarishni commit qilmang).

### Buyruq qatori orqali (faqat iOS)

Avval simulyatorni oching (Xcode → Open Developer Tool → Simulator yoki
`open -a Simulator`), keyin:

```bash
skip app launch --ios
```

### Haqiqiy iPhone'da

Xcode → `Ovozcha App` target → **Signing & Capabilities** → **Team** ga Apple ID'ingizni
tanlang. Bundle ID band deb xato chiqsa, `Skip.env` dagi `PRODUCT_BUNDLE_IDENTIFIER` ni
o'zingiznikiga almashtiring (masalan, `com.ismingiz.Ovozcha`).

---

## 4-qadam. Android'da ishga tushirish

### Emulyator yaratish (bir marta)

```bash
skip android emulator create
```

Mavjud emulyatorlar ro'yxati: `skip android emulator list`. Android Studio'dagi
Device Manager orqali yaratilgan emulyator ham bo'ladi.

### Emulyatorni ochish

```bash
skip android emulator launch
```

Emulyator to'liq yuklanib, bosh ekrani chiqquncha kuting.

### Ilovani qurish va o'rnatish

Loyiha ildizida (`Ovozcha` papkasida):

```bash
skip app launch --android
```

Bu buyruq Swift kodini Kotlin'ga o'giradi, Gradle bilan quradi va emulyatorga o'rnatib ochadi.
**Birinchi qurish 5–10 daqiqa** oladi (Gradle bog'liqliklarni yuklaydi), keyingilari tezroq.

Haqiqiy Android telefonda: telefonda *Developer options → USB debugging* ni yoqing, USB bilan
ulang, `adb devices` ro'yxatida telefon ko'rinsin, keyin xuddi shu `skip app launch --android`.

### Android Studio'da ochish (ixtiyoriy)

Android Studio → **Open** → repozitoriydagi `Android` papkasi. Bu loglarni ko'rish va
Compose'ni tekshirish uchun qulay, lekin kodni Swift'da (`Sources/`) o'zgartiring:
Kotlin fayllari har qurishda qaytadan yaratiladi.

---

## 5-qadam. Talaffuz uchun kalit (ixtiyoriy)

Ilova kalitsiz ham to'liq ishga tushadi. Kalit faqat **Talaffuz murabbiyi** bola aytgan so'zni
tekshirishi uchun kerak. Kalit bo'lmasa, ekranda "Tekshirish hozir ishlamayapti" chiqadi, qolgan
bo'limlar oddiy ishlaydi.

Nutq matnga [Groq](https://console.groq.com) (Whisper modeli) orqali aylantiriladi. Ikki yo'l bor:

| Yo'l | Qachon | Sozlama nomi |
|---|---|---|
| O'z serveringiz (proksi) | Ilovani do'konga chiqarish | `OvozchaTranscriptionEndpoint` (faqat `https://`) |
| Groq kaliti to'g'ridan-to'g'ri | Faqat ishlab chiqish va sinov | `OvozchaGroqKey` |

> **Kalitni hech qachon commit qilmang.** Repozitoriy ochiq. Ilovaga joylangan kalitni
> APK/IPA dan chiqarib olish mumkin, shuning uchun do'kon versiyasida faqat server manzili
> bo'lishi kerak.

**Android.** Namunadan nusxa oling va kalitni yozing:

```bash
cp Android/secrets.example.xml Android/app/src/main/res/values/secrets.xml
```

```xml
<string name="OvozchaGroqKey">gsk_...</string>
```

`secrets.xml` `.gitignore` da, Git uni ko'rmaydi. Namuna `res/values/` dan tashqarida turadi:
ichida bo'lsa, Android "Duplicate resources" xatosini beradi.

**iOS.** `Darwin/Info.plist` ga qo'shing:

```xml
<key>OvozchaGroqKey</key>
<string>gsk_...</string>
```

`Info.plist` **repozitoriyda kuzatiladi**. Kalit yozilgan faylni commit qilmaslik uchun
Git'ga o'zgarishni e'tiborsiz qoldirishni ayting:

```bash
git update-index --skip-worktree Darwin/Info.plist
```

Qaytarish: `git update-index --no-skip-worktree Darwin/Info.plist`.

---

## Loyiha tuzilishi

```
Ovozcha/
├── Package.swift              Swift paketi (Skip, SkipUI bog'liqliklari)
├── Skip.env                   Ilova nomi, bundle ID, versiya (iOS va Android uchun umumiy)
├── Project.xcworkspace        Xcode'da shuni oching
├── Sources/Ovozcha/           BUTUN ilova kodi: iOS va Android uchun bitta
│   ├── App/                   Tab paneli, navigatsiya
│   ├── Core/                  Matnlar (Strings.swift), sozlamalar, tarmoq
│   ├── DesignSystem/          Ranglar, shriftlar, umumiy modifikatorlar
│   ├── Features/              Ekranlar: Home, Letters, Numbers, Pronunciation,
│   │                          Spelling, Parent, Setup, Shared
│   └── Resources/             Audio (murabbiy ovozi), shriftlar, rasmlar
├── Darwin/                    iOS ilova qobig'i (Xcode loyihasi, Info.plist, ikonka)
├── Android/                   Android ilova qobig'i (Gradle, AndroidManifest)
├── Tests/OvozchaTests/        Testlar
├── Tools/                     Yordamchi skriptlar (audio ro'yxati, etalon transkriptlar)
└── VAZIFALAR.md               Ochiq ishlar ro'yxati
```

Platformaga xos kod `#if SKIP` (Android) va `#if !SKIP` (iOS) bloklari ichida.

### Murabbiy ovozi (audio)

Ovoz fayllari `Sources/Ovozcha/Resources/Audio/` da. Qaysi fayl kerakligi va qanday nomlanishi:
[`Tools/voice-recordings/README.md`](Tools/voice-recordings/README.md). Fayl yo'q bo'lsa,
murabbiy matn bilan gapiradi, ilova qulamaydi. Darslarga so'z qo'shilsa, ro'yxatni qayta yasang:

```bash
sh Tools/voice-recordings/generate.sh
```

---

## Testlar

`Tests/OvozchaTests/` da testlar yozilgan, lekin **hozircha ishga tushmaydi**: test to'plami
macOS uchun quriladi, ilova kodi esa faqat iOS/Android API'lari bilan kompilyatsiya bo'ladi.
Bu [`VAZIFALAR.md`](VAZIFALAR.md) da ochiq ish sifatida turibdi.

---

## Tez-tez uchraydigan muammolar

| Belgi | Sabab va yechim |
|---|---|
| Ilova ochiladi, lekin ovoz chiqmaydi | `Ovozcha` sxemasi bilan qurilgan. **`Ovozcha App`** ni tanlang |
| Xcode iOS'ni qurdi, lekin Android qismida xato | Android emulyatori ochiq emas. Uni oching yoki `skip app launch --ios` ni ishlating |
| `skip: command not found` | `brew install skiptools/skip/skip`, keyin terminalni qayta oching |
| `skip doctor` Android SDK'ni topmaydi | Android Studio'ni bir marta ochib, SDK yuklashni tugating |
| `Duplicate resources` (Android) | `secrets.xml` dan boshqa nusxa ham `res/values/` ichida turibdi. Faqat bittasi qolsin |
| Talaffuzda "Tekshirish hozir ishlamayapti" | Kalit yoki server manzili yo'q, [5-qadam](#5-qadam-talaffuz-uchun-kalit-ixtiyoriy) |
| Imlo lug'ati "Internet yo'q" deydi | Birinchi ochilishda internet kerak, keyin lug'at keshdan ishlaydi |
| Paketlar bilan bog'liq g'alati xato | Xcode → File → Packages → Reset Package Caches, keyin ⇧⌘K va qayta ⌘R |

---

## Litsenziyalar va manbalar

- **Andika** va **Poppins** shriftlari: SIL Open Font License
  (`Sources/Ovozcha/Resources/Fonts/` dagi `OFL*.txt`).
- **Imlo lug'ati**: [uz-hunspell](https://github.com/u2b3k/uz-hunspell) (GPL-3.0,
  © Alisher Jalolov, Bilolbek Normoʻminov). Lug'at repozitoriyda yo'q: ilova uni ishlayotganda
  jsDelivr CDN dan yuklaydi.
- **Skip**: [skip.dev](https://skip.dev).
