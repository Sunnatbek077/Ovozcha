#!/usr/bin/env python3
"""`word_*.m4a` yozuvlarini etalon papkasiga nusxalaydi.

Nega kerak
----------
Ilova so'z yozuvlarini `Resources/Audio/word_<so'z>.m4a` nomi bilan izlaydi.
`build.py` esa ularni so'zning o'z nomi bilan kutadi: `audio/<so'z>.m4a`.
Bu skript shu ikki nomlashni bog'laydi — qo'lda nusxalash shart emas.

    word_robot.m4a      ->  robot.m4a
    word_bo_ri.m4a      ->  bo'ri.m4a
    word_makkajo_xori   ->  makkajo'xori.m4a

Ishlatish
---------
    python3 Tools/reference-transcripts/sync_words.py            # quruq yurish
    python3 Tools/reference-transcripts/sync_words.py --apply    # nusxalaydi

Keyin: export GROQ_API_KEY=... && python3 Tools/reference-transcripts/build.py
"""

import os
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "Sources/Ovozcha/Resources/Audio"
DST = Path(__file__).resolve().parent / "audio"

# Fayl nomida apostrof ishlatib bo'lmagani uchun `_` yozilgan. Qaytarishda
# faqat UNLI/UNDOSHDAN KEYINGI `_` apostrofga aylanadi: `bo_ri` -> `bo'ri`,
# lekin `-2` kabi namuna raqami va so'z ichidagi haqiqiy `_` tegilmaydi.
# Manifestdagi barcha so'zlarda `_` faqat apostrof o'rnida turadi (tekshirildi),
# shuning uchun qoida sodda: hammasi apostrof.
def word_from(stem: str) -> str:
    return stem[len("word_"):].replace("_", "'")


def main() -> int:
    apply = "--apply" in sys.argv

    if not SRC.is_dir():
        print(f"✗ Manba papka yo'q: {SRC}", file=sys.stderr)
        return 1

    found = sorted(p for p in SRC.glob("word_*.m4a"))
    if not found:
        print(f"Hali bitta ham `word_*.m4a` yo'q ({SRC}).")
        print("So'zlarni yozib, shu papkaga qo'ying — keyin bu skriptni qayta ishga tushiring.")
        return 0

    DST.mkdir(parents=True, exist_ok=True)
    copied = skipped = 0

    for src in found:
        name = word_from(src.stem) + src.suffix
        dst = DST / name
        if dst.exists() and dst.stat().st_mtime >= src.stat().st_mtime:
            print(f"  = {name}  (o'zgarmagan)")
            skipped += 1
            continue
        print(f"  {'+' if apply else '→'} {src.name:30s} -> {name}")
        if apply:
            shutil.copy2(src, dst)
        copied += 1

    print()
    if apply:
        print(f"✅ {copied} ta nusxalandi, {skipped} ta o'zgarmagan -> {DST}")
        print("Keyingi qadam: export GROQ_API_KEY=... && python3 Tools/reference-transcripts/build.py")
    else:
        print(f"{copied} ta nusxalanadi, {skipped} ta o'zgarmagan.")
        print("(quruq yurish — hech narsa ko'chirilmadi; --apply bilan bajariladi)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
