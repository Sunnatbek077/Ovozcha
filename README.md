# Ovozcha

A literacy app for Uzbek children aged 3–5: writing letters and numbers, listening to sounds,
a pronunciation coach and a spelling dictionary. A single Swift/SwiftUI codebase produces both
the **iOS** and the **Android** app: [Skip](https://skip.dev) transpiles the Swift code to
Kotlin/Jetpack Compose for Android.

The app's interface is in Uzbek.

| Section | Works |
|---|---|
| Letters, Numbers | Offline |
| Pronunciation coach | Needs internet and a speech-recognition service (see [Step 5](#step-5-pronunciation-key-optional)) |
| Spelling dictionary | Downloaded on first open, then works from the local cache |

---

## Requirements

The project builds on **macOS only**: the iOS app needs Xcode, and Skip runs through Xcode as well.

| Tool | Version | Notes |
|---|---|---|
| macOS | 14+ | Apple Silicon (M1 or newer) recommended |
| Xcode | **26 or newer** | The code uses iOS 26 APIs (Liquid Glass) and will not build with an older SDK. Tested with Xcode 27.1 |
| Homebrew | any | [brew.sh](https://brew.sh) |
| Skip | 1.9.10+ | Installed via Homebrew; also brings Gradle and a JDK |
| Android Studio | any recent | Only needed for the Android SDK and emulator; you don't write code in it |

Supported devices: **iOS 17+**, **Android 12+** (API 31).

---

## Step 1. Install the tools

You only need to do this once per machine.

**Xcode.** Install it from the App Store, open it once, accept the license and download the iOS
simulator (Xcode offers it on first launch). Then:

```bash
sudo xcode-select -s /Applications/Xcode.app
```

**Skip** (installs Gradle and OpenJDK as well):

```bash
brew install skiptools/skip/skip
```

**Android Studio.** Install it from
[developer.android.com/studio](https://developer.android.com/studio), open it once and finish
the setup wizard (it downloads the SDK). The SDK usually ends up in `~/Library/Android/sdk`.

**Check.** Skip tells you whether everything is in place:

```bash
skip doctor
```

Every line should show `[✓]`. The `[!] A new version is available` warning is harmless. If you
see `[✗]`, follow the hint on that line.

---

## Step 2. Clone the repository

```bash
git clone https://github.com/Sunnatbek077/Ovozcha.git
```

```bash
cd Ovozcha
```

Swift packages (Skip, SkipUI) are fetched automatically on the first build. Exact versions are
pinned in `Package.resolved`, so everyone builds with the same versions.

---

## Step 3. Run on iOS

### From Xcode

```bash
open Project.xcworkspace
```

1. In the scheme menu at the top of Xcode, select **`Ovozcha App`**.
   The `Ovozcha` scheme (without "App") only builds the library: the app won't launch and the
   audio files won't be bundled.
2. Pick an iPhone simulator as the run destination (e.g. *iPhone 17*).
3. Press **⌘R** (Product → Run).

The first build takes a few minutes while packages download and Skip runs.

> **Important: Xcode also builds Android.** `Darwin/Ovozcha.xcconfig` contains
> `SKIP_ACTION = launch`, so every ⌘R also builds the Android app and installs it on the running
> Android emulator. If no emulator is running, that part of the build fails. If you only need
> iOS, the command below is easier; in Xcode you can instead enable the `SKIP_ACTION = none`
> line in that file (don't commit that change).

### From the command line (iOS only)

Open a simulator first (Xcode → Open Developer Tool → Simulator, or `open -a Simulator`), then:

```bash
skip app launch --ios
```

### On a real iPhone

In Xcode select the `Ovozcha App` target → **Signing & Capabilities** → set **Team** to your
Apple ID. If you get an error that the bundle ID is taken, change `PRODUCT_BUNDLE_IDENTIFIER`
in `Skip.env` to your own (e.g. `com.yourname.Ovozcha`).

---

## Step 4. Run on Android

### Create an emulator (once)

```bash
skip android emulator create
```

List existing emulators with `skip android emulator list`. An emulator created in Android
Studio's Device Manager works too.

### Start the emulator

```bash
skip android emulator launch
```

Wait until the emulator has fully booted to its home screen.

### Build and install the app

From the repository root (the `Ovozcha` folder):

```bash
skip app launch --android
```

This transpiles the Swift code to Kotlin, builds it with Gradle, installs it on the emulator and
opens it. **The first build takes 5–10 minutes** (Gradle downloads dependencies); later builds
are much faster.

On a physical Android phone: enable *Developer options → USB debugging*, connect it over USB,
make sure it shows up in `adb devices`, then run the same `skip app launch --android`.

### Opening in Android Studio (optional)

Android Studio → **Open** → the `Android` folder of the repository. This is handy for logs and
inspecting Compose, but edit the code in Swift (`Sources/`): the Kotlin files are regenerated on
every build.

---

## Step 5. Pronunciation key (optional)

The app runs fully without a key. The key is only needed for the **pronunciation coach** to check
the word the child said. Without it the screen shows "Tekshirish hozir ishlamayapti" ("Checking
is not available right now"); every other section works normally.

Speech is converted to text via [Groq](https://console.groq.com) (Whisper model). There are two
options:

| Option | When | Setting name |
|---|---|---|
| Your own server (proxy) | Shipping to the stores | `OvozchaTranscriptionEndpoint` (`https://` only) |
| Groq key directly in the app | Development and testing only | `OvozchaGroqKey` |

> **Never commit a key.** This repository is public. A key embedded in the app can be extracted
> from the APK/IPA, so store builds must only contain a server URL.

**Android.** Copy the template and fill in the key:

```bash
cp Android/secrets.example.xml Android/app/src/main/res/values/secrets.xml
```

```xml
<string name="OvozchaGroqKey">gsk_...</string>
```

`secrets.xml` is in `.gitignore`, so Git ignores it. The template lives outside `res/values/`
on purpose: if it were inside, Android would fail with "Duplicate resources".

**iOS.** Add to `Darwin/Info.plist`:

```xml
<key>OvozchaGroqKey</key>
<string>gsk_...</string>
```

`Info.plist` **is tracked in the repository**. To avoid committing it with the key, tell Git to
ignore your local changes:

```bash
git update-index --skip-worktree Darwin/Info.plist
```

To undo: `git update-index --no-skip-worktree Darwin/Info.plist`.

---

## Project structure

```
Ovozcha/
├── Package.swift              Swift package (Skip, SkipUI dependencies)
├── Skip.env                   App name, bundle ID, version (shared by iOS and Android)
├── Project.xcworkspace        Open this in Xcode
├── Sources/Ovozcha/           ALL app code: one codebase for iOS and Android
│   ├── App/                   Tab bar, navigation
│   ├── Core/                  UI strings (Strings.swift), config, networking
│   ├── DesignSystem/          Colors, fonts, shared modifiers
│   ├── Features/              Screens: Home, Letters, Numbers, Pronunciation,
│   │                          Spelling, Parent, Setup, Shared
│   └── Resources/             Audio (coach voice), fonts, images
├── Darwin/                    iOS app shell (Xcode project, Info.plist, icon)
├── Android/                   Android app shell (Gradle, AndroidManifest)
├── Tests/OvozchaTests/        Tests
├── Tools/                     Helper scripts (audio list, reference transcripts)
└── VAZIFALAR.md               Open tasks (in Uzbek)
```

Platform-specific code lives in `#if SKIP` (Android) and `#if !SKIP` (iOS) blocks.

### Coach voice (audio)

Voice files are in `Sources/Ovozcha/Resources/Audio/`. Which files are needed and how they are
named: [`Tools/voice-recordings/README.md`](Tools/voice-recordings/README.md). If a file is
missing, the coach falls back to text and the app does not crash. After adding words to the
lessons, regenerate the list:

```bash
sh Tools/voice-recordings/generate.sh
```

---

## Tests

Tests are written in `Tests/OvozchaTests/`, but **they don't run yet**: the test bundle builds
for macOS, while the app code only compiles against iOS/Android APIs. This is tracked as an open
task in [`VAZIFALAR.md`](VAZIFALAR.md).

---

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| The app opens but there is no sound | Built with the `Ovozcha` scheme. Select **`Ovozcha App`** |
| Xcode builds iOS but the Android part fails | No Android emulator is running. Start one, or use `skip app launch --ios` |
| `skip: command not found` | `brew install skiptools/skip/skip`, then reopen the terminal |
| `skip doctor` can't find the Android SDK | Open Android Studio once and finish the SDK download |
| `Duplicate resources` (Android) | Another copy of `secrets.xml` sits in `res/values/`. Keep only one |
| Pronunciation shows "Tekshirish hozir ishlamayapti" | No key or server URL, see [Step 5](#step-5-pronunciation-key-optional) |
| Spelling dictionary says "Internet yoʻq" (no internet) | The first open needs internet; afterwards the dictionary works from the cache |
| Strange package-related errors | Xcode → File → Packages → Reset Package Caches, then ⇧⌘K and ⌘R again |

---

## Licenses and sources

- **Andika** and **Poppins** fonts: SIL Open Font License
  (`OFL*.txt` in `Sources/Ovozcha/Resources/Fonts/`).
- **Spelling dictionary**: [uz-hunspell](https://github.com/u2b3k/uz-hunspell) (GPL-3.0,
  © Alisher Jalolov, Bilolbek Normoʻminov). The dictionary is not in this repository: the app
  downloads it at runtime from the jsDelivr CDN.
- **Skip**: [skip.dev](https://skip.dev).
