#!/usr/bin/env python3
"""To'g'ri talaffuz yozuvlaridan etalon matnlarni yasaydi.

Nega kerak
----------
Nutq tanish (Whisper) har so'zda o'ziga xos xatoga yo'l qo'yadi: "arra" ni "Ara",
"robot" ni "Робот" deb eshitadi. Agar bolaning matnini IMLO bilan solishtirsak,
to'g'ri aytilgan so'z ham past baho oladi.

Shuning uchun to'g'ri talaffuzni bir marta yozib olamiz, uni Whisper'dan o'tkazamiz
va NATIJANI etalon qilib saqlaymiz. Keyin bolaning matni shu etalon bilan
solishtiriladi — nutq tanishning o'z xatosi bolaning xatosi deb hisoblanmaydi.

Bu bitta mexanizm: har harf uchun alohida sozlash kerak emas.

Ishlatish
---------
1. Har bir so'zni aniq aytib yozing va `audio/` ga qo'ying. Fayl nomi = so'zning o'zi:

       audio/arra.m4a  audio/raketa.m4a  audio/ro'mol.m4a

   Bir so'zga bir nechta yozuv bo'lsa, raqam qo'shing: `arra-2.m4a`.
   Ko'p namuna — yaxshiroq: turli ovoz va ohanglar qamrab olinadi.

2. Kalitni muhitga bering (kodga YOZMANG):

       export GROQ_API_KEY=...

3. Ishga tushiring:

       python3 Tools/reference-transcripts/build.py

4. Chiqqan Swift kodini `Sources/Ovozcha/Features/Letters/Model/LetterWords.swift`
   ichidagi mos so'zga ko'chiring.

Eslatma: yozuvlar bola ovoziga yaqin bo'lsa yaxshiroq. Kattalar ovozi bilan
yasalgan etalon bolaning ovoziga to'liq mos kelmasligi mumkin.
"""

import json
import os
import sys
import urllib.request
import urllib.error
from pathlib import Path
from typing import Dict, List, Optional

ENDPOINT = "https://api.groq.com/openai/v1/audio/transcriptions"
MODEL = "whisper-large-v3"
AUDIO_DIR = Path(__file__).parent / "audio"


def transcribe(path: Path, key: str) -> Optional[str]:
    boundary = "----ovozcha-reference"
    parts = []
    for name, value in (("model", MODEL), ("language", "uz"), ("response_format", "json")):
        parts.append(
            f"--{boundary}\r\nContent-Disposition: form-data; name=\"{name}\"\r\n\r\n{value}\r\n".encode()
        )
    parts.append(
        f"--{boundary}\r\nContent-Disposition: form-data; "
        f"name=\"file\"; filename=\"{path.name}\"\r\n"
        f"Content-Type: application/octet-stream\r\n\r\n".encode()
    )
    parts.append(path.read_bytes())
    parts.append(f"\r\n--{boundary}--\r\n".encode())
    body = b"".join(parts)

    request = urllib.request.Request(
        ENDPOINT,
        data=body,
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": f"multipart/form-data; boundary={boundary}",
            # Usiz Cloudflare urllib'ning sukutdagi User-Agent'ini bloklaydi (403, 1010).
            "User-Agent": "ovozcha-reference-builder/1.0",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.load(response).get("text", "").strip()
    except urllib.error.HTTPError as error:
        print(f"  XATO {path.name}: HTTP {error.code} {error.read()[:200]!r}", file=sys.stderr)
    except Exception as error:  # tarmoq, vaqt tugashi va h.k.
        print(f"  XATO {path.name}: {error}", file=sys.stderr)
    return None


def word_of(path: Path) -> str:
    """`arra-2.m4a` -> `arra`."""
    stem = path.stem
    if "-" in stem and stem.rsplit("-", 1)[1].isdigit():
        stem = stem.rsplit("-", 1)[0]
    return stem


def main() -> int:
    key = os.environ.get("GROQ_API_KEY", "").strip()
    if not key:
        print("GROQ_API_KEY muhit o'zgaruvchisi berilmagan.", file=sys.stderr)
        print("  export GROQ_API_KEY=...", file=sys.stderr)
        return 1

    files = sorted(p for p in AUDIO_DIR.iterdir() if p.suffix.lower() in {".m4a", ".mp3", ".wav", ".ogg", ".flac"}) \
        if AUDIO_DIR.is_dir() else []
    if not files:
        print(f"Yozuv topilmadi: {AUDIO_DIR}")
        print("Fayl nomi so'zning o'zi bo'lsin, masalan `arra.m4a`.")
        return 1

    results: Dict[str, List[str]] = {}
    for path in files:
        print(f"-> {path.name}")
        text = transcribe(path, key)
        if not text:
            continue
        word = word_of(path)
        print(f"   eshitildi: {text!r}")
        results.setdefault(word, [])
        if text not in results[word]:
            results[word].append(text)

    if not results:
        print("\nHech narsa olinmadi.")
        return 1

    print("\n" + "=" * 60)
    print("LetterWords.swift ga ko'chiring (mos so'zga `references:` qo'shing):")
    print("=" * 60)
    for word in sorted(results):
        forms = ", ".join(f'"{t}"' for t in results[word])
        print(f'  // {word}')
        print(f'  references: [{forms}]')
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
