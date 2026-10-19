"""Android uchun harf/raqam jadvalini (kontur + niqob) oldindan hisoblaydi.

Sabab: Android'da (Skip Lite) CoreText va CoreGraphics yo'q, shuning uchun iOS'dagi kabi shrift konturini
ishlab chiqib, uni niqobga aylantirib bo'lmaydi. Buning o'rniga Andika-Bold'dan har bir shaklning
konturi va niqobi shu skriptda hisoblanib, Swift manba fayliga yoziladi.

Joylashuv `GlyphOutline.swift` dagi bilan bir xil (mos "profil"):
  harf : em 0.86 H, baseline 0.74 H, eng katta kenglik 0.86 W
  raqam: em 0.80 H, baseline 0.79 H, eng katta kenglik 0.86 W   ("1" = poydevorsiz `one.NoBase`)
Mos "tuval": 340 x 380 (Python simulyatsiyasi va sozlash shu o'lchamda o'tkazilgan). Niqob to'ri: 96 x 107.

Ishga tushirish:  python3 export_glyphs.py <Andika-Bold.ttf> <UzbekAlphabet.swift> <chiqish GlyphTable.swift>
(numpy pillow fonttools cairosvg kerak)
"""
import io
import re
import sys

import cairosvg
import numpy as np
from fontTools.pens.basePen import BasePen
from fontTools.ttLib import TTFont
from PIL import Image

W, H = 340, 380
GRID_W = 96
GRID_H = max(1, round(GRID_W * H / W))            # 107
PROFILE = {"letter": (0.86, 0.74, 0.86), "digit": (0.80, 0.79, 0.86)}
CURVE_STEPS = 8
SUPERSAMPLE = 3
APOSTROPHE = "\u02BB"


class FlattenPen(BasePen):
    """Egri chiziqlarni to'g'ri kesmalarga bo'ladi (Swift tomonda faqat move/addLine kerak bo'lsin)."""

    def __init__(self, glyph_set):
        super().__init__(glyph_set)
        self.contours = []
        self._current = None

    def _moveTo(self, pt):
        self._current = [pt]
        self.contours.append(self._current)

    def _lineTo(self, pt):
        self._current.append(pt)

    def _qCurveToOne(self, p1, p2):
        p0 = self._getCurrentPoint()
        for i in range(1, CURVE_STEPS + 1):
            t = i / CURVE_STEPS
            x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0]
            y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1]
            self._current.append((x, y))

    def _curveToOne(self, p1, p2, p3):
        p0 = self._getCurrentPoint()
        for i in range(1, CURVE_STEPS + 1):
            t = i / CURVE_STEPS
            x = (1 - t) ** 3 * p0[0] + 3 * (1 - t) ** 2 * t * p1[0] + 3 * (1 - t) * t ** 2 * p2[0] + t ** 3 * p3[0]
            y = (1 - t) ** 3 * p0[1] + 3 * (1 - t) ** 2 * t * p1[1] + 3 * (1 - t) * t ** 2 * p2[1] + t ** 3 * p3[1]
            self._current.append((x, y))

    def _closePath(self):
        pass


def load_letters(swift_path):
    """(id, upper, lower) ro'yxati. Manba: UzbekAlphabet.swift (id tartibi tekshiriladi)."""
    text = open(swift_path, encoding="utf-8").read()
    rows = re.findall(r'UzbekLetter\(id: "([a-z_]+)", upper: (.+?), lower: (.+?), exampleWord', text)
    result = []
    for letter_id, upper, lower in rows:
        def value(expr):
            parts = [p.strip() for p in expr.split("+")]
            return "".join(APOSTROPHE if p == "tutuq" else p.strip('"') for p in parts)
        result.append((letter_id, value(upper), value(lower)))
    assert len(result) == 29, f"29 ta harf kutilgan, {len(result)} ta topildi"
    return result


def glyph_contours(font, text, digit):
    """`text` ni belgi-belgi joylab, kesmalarga bo'lingan konturlar (font birliklarida, y yuqoriga)."""
    glyph_set = font.getGlyphSet()
    cmap = font.getBestCmap()
    advances = font["hmtx"]
    contours, x = [], 0
    for ch in text:
        name = cmap[ord(ch)]
        if digit and ch == "1" and "one.NoBase" in glyph_set:
            name = "one.NoBase"
        pen = FlattenPen(glyph_set)
        glyph_set[name].draw(pen)
        for contour in pen.contours:
            contours.append([(px + x, py) for px, py in contour])
        x += advances[name][0]
    return contours


def place(font, text, kind):
    """Tuvalga joylashtirilgan konturlar (tuval koordinatalari, y pastga) va amalda ishlatilgan em."""
    upm = font["head"].unitsPerEm
    em_fraction, baseline_fraction, max_width_fraction = PROFILE[kind]
    em = em_fraction * H
    k = em / upm
    contours = glyph_contours(font, text, kind == "digit")
    xs = [p[0] * k for c in contours for p in c]
    min_x, max_x = min(xs), max(xs)
    scale = min(1.0, max_width_fraction * W / (max_x - min_x))
    mid_x = (min_x + max_x) / 2
    baseline = baseline_fraction * H
    placed = []
    for contour in contours:
        # 0.1 gacha yaxlitlaymiz: niqob ham AYNAN shu yaxlitlangan konturdan hisoblanadi, shuning uchun
        # ilovaga yetkaziladigan kontur va niqob bir xil bo'ladi.
        pts = [(round(W / 2 + (px * k - mid_x) * scale, 1), round(baseline - py * k * scale, 1)) for px, py in contour]
        pts.append(pts[0])                                     # konturni yopamiz
        placed.append(pts)
    return placed, em * scale


def rasterize(placed):
    d = ""
    for pts in placed:
        d += "M" + " L".join(f"{x*SUPERSAMPLE:.2f},{y*SUPERSAMPLE:.2f}" for x, y in pts) + " Z "
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W*SUPERSAMPLE}" height="{H*SUPERSAMPLE}">'
           f'<rect width="100%" height="100%" fill="black"/><path fill="white" fill-rule="nonzero" d="{d}"/></svg>')
    image = Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg.encode()))).convert("L")
    image = image.resize((GRID_W, GRID_H), Image.BOX)
    return (np.asarray(image, dtype=np.float32) / 255.0) > 0.5


def encode_mask(mask):
    """Qator bo'yicha yugurish-uzunligi (RLE): 0-lardan boshlab galma-gal uzunliklar."""
    flat = mask.flatten()
    runs, current, length = [], False, 0
    for value in flat:
        if bool(value) == current:
            length += 1
        else:
            runs.append(length)
            current, length = bool(value), 1
    runs.append(length)
    return ",".join(str(r) for r in runs)


def encode_outline(placed):
    return ";".join(" ".join(f"{x:.1f},{y:.1f}" for x, y in pts) for pts in placed)


def swift_string(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main(font_path, alphabet_path, out_path):
    font = TTFont(font_path)
    letters = load_letters(alphabet_path)
    subjects = []                                             # (kalit, matn, tur)
    for letter_id, upper, lower in letters:
        subjects.append((f"{letter_id}|U", upper, "letter"))
        subjects.append((f"{letter_id}|L", lower, "letter"))
    for value in range(1, 11):
        subjects.append((str(value), str(value), "digit"))

    lines = [
        "#if SKIP",
        "// ⚠️ AVTOMATIK YARATILGAN FAYL: qo'lda tahrirlamang.",
        "// Manba: Tools/glyph-export/export_glyphs.py (Andika-Bold, tuval 340x380, to'r 96x107).",
        "",
        "/// Bitta shaklning oldindan hisoblangan ma'lumoti.",
        "struct GlyphTableEntry {",
        "    /// Amalda ishlatilgan shrift o'lchami (tuval birligida).",
        "    let em: Double",
        "    /// Konturlar: `x,y x,y ...;` (kontur `;` bilan ajratilgan), tuval koordinatalarida (y pastga).",
        "    let outline: String",
        "    /// Niqob (yugurish uzunligi): 0-lardan boshlab galma-gal uzunliklar, qator bo'yicha.",
        "    let mask: String",
        "}",
        "",
        "enum GlyphTable {",
        f"    static let canvasWidth = {float(W)}",
        f"    static let canvasHeight = {float(H)}",
        f"    static let gridWidth = {GRID_W}",
        f"    static let gridHeight = {GRID_H}",
        "",
        "    static func entry(for key: String) -> GlyphTableEntry? {",
        "        return entries[key]",
        "    }",
        "",
        "    static let entries: [String: GlyphTableEntry] = [",
    ]
    total_points = 0
    for index, (key, text, kind) in enumerate(subjects):
        placed, em_eff = place(font, text, kind)
        mask = rasterize(placed)
        total_points += sum(len(c) for c in placed)
        comma = "," if index < len(subjects) - 1 else ""
        lines.append(f"        {swift_string(key)}: GlyphTableEntry(")
        lines.append(f"            em: {em_eff:.2f},")
        lines.append(f"            outline: {swift_string(encode_outline(placed))},")
        lines.append(f"            mask: {swift_string(encode_mask(mask))}")
        lines.append(f"        ){comma}")
    lines += ["    ]", "}", "#endif", ""]
    open(out_path, "w", encoding="utf-8").write("\n".join(lines))
    print(f"{len(subjects)} shakl, jami {total_points} nuqta -> {out_path}")


if __name__ == "__main__":
    main(*sys.argv[1:4])
