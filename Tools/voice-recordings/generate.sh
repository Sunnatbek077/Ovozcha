#!/bin/sh
# Murabbiy ovozi uchun yozib olish ro'yxatini (README.md) dars ma'lumotlaridan yasaydi.
#
#     sh Tools/voice-recordings/generate.sh
#
# Avval kodda ishlatilgan har bir `CoachAudio.phrase("...")` katalogda (`CoachAudio.catalog()`)
# borligini tekshiradi: aks holda ro'yxatda yo'q fayl kutilib, murabbiy jim qolardi.
set -eu

cd "$(dirname "$0")/../.."
SRC=Sources/Ovozcha
OUT=Tools/voice-recordings/README.md

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

grep -rhoE 'phrase\("[a-z_0-9]+"\)' "$SRC/Features" | sed -E 's/.*"([a-z_0-9]+)".*/\1/' | grep -v '^hint_' | sort -u > "$TMP/used"
grep -hoE 'CoachPhrase\(key: "[a-z_0-9]+"' "$SRC/Features/Pronunciation/Model/CoachScript.swift" | sed -E 's/.*"([a-z_0-9]+)"/\1/' | sort -u > "$TMP/listed"
missing=$(comm -23 "$TMP/used" "$TMP/listed")
if [ -n "$missing" ]; then
    echo "Katalogda yo'q iboralar (CoachAudio.catalog ga qo'shing):" >&2
    echo "$missing" >&2
    exit 1
fi

swiftc -parse-as-library -o "$TMP/manifest" \
    Tools/voice-recordings/Manifest.swift \
    "$SRC/Core/Strings.swift" \
    "$SRC/Features/Letters/Model/UzbekAlphabet.swift" \
    "$SRC/Features/Letters/Model/LetterWords.swift" \
    "$SRC/Features/Pronunciation/Model/SoundLesson.swift" \
    "$SRC/Features/Pronunciation/Model/CoachScript.swift" \
    "$SRC/Features/Pronunciation/Model/SpeechDiagnosis.swift" \
    "$SRC/Features/Pronunciation/Model/PronunciationScoring.swift"

"$TMP/manifest" > "$OUT"
echo "Yozildi: $OUT ($(grep -c '^| `' "$OUT") ta fayl)"
