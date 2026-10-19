"""Raqamlar (1-10) uchun baholash sozlamasini tekshirish va tanlash.

Harflar uchun tanlangan reach/tolerance raqamlarda juda bo'sh chiqdi (raqamlar ixcham va katta:
siljigan iz 40% da, tasodifiy chiziqlar 6-8% da o'tardi). Bu skript raqamlarni Swift'dagi kabi
chizadi (Andika, poydevorsiz "1" = `one.NoBase`, em 0.80H, baseline 0.79H) va turli
reachEm / toleranceEm juftliklarini solishtiradi.

Ishga tushirish:  python3 digits.py        (numpy scipy pillow fonttools cairosvg kerak)
Natija Swift'dagi TraceTuning.digitReachEm / digitToleranceEm qiymatlarini asoslaydi.
"""
import io
import itertools
import contextlib
import numpy as np
from scipy import ndimage as ndi
from PIL import Image
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.boundsPen import BoundsPen
import cairosvg

with contextlib.redirect_stdout(io.StringIO()):
    from proto import FONT, GW, GH, CELL, W, H
    from proto2 import zhang_suen

EM_FRACTION, BASELINE_FRACTION, FIT_FRACTION = 0.80, 0.79, 0.86
DIGITS = [str(i) for i in range(1, 11)]
rng = np.random.default_rng(9)

font = TTFont(FONT)
glyph_set = font.getGlyphSet()
cmap = font.getBestCmap()
units = font["head"].unitsPerEm
advances = font["hmtx"]


def digit_mask(text, plain_one=True, supersample=3):
    """Raqam niqobi va amalda ishlatilgan em (pt)."""
    names = []
    for ch in text:
        name = cmap[ord(ch)]
        if ch == "1" and plain_one and "one.NoBase" in glyph_set:
            name = "one.NoBase"
        names.append(name)
    em = EM_FRACTION * H
    base_scale = em / units
    x = 0
    parts, x0, x1 = [], 1e9, -1e9
    for name in names:
        pen = SVGPathPen(glyph_set)
        glyph_set[name].draw(pen)
        parts.append((x, pen.getCommands()))
        bounds = BoundsPen(glyph_set)
        glyph_set[name].draw(bounds)
        if bounds.bounds:
            x0, x1 = min(x0, x + bounds.bounds[0]), max(x1, x + bounds.bounds[2])
        x += advances[name][0]
    scale = min(1.0, FIT_FRACTION * W / ((x1 - x0) * base_scale)) * base_scale
    cx = (x0 + x1) / 2
    ss = supersample
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{W*ss}" height="{H*ss}"><rect width="100%" height="100%" fill="black"/>'
    for xo, cmd in parts:
        svg += (f'<path fill="white" transform="translate({W*ss/2} {BASELINE_FRACTION*H*ss}) '
                f'scale({scale*ss} {-scale*ss}) translate({-cx} 0) translate({xo} 0)" d="{cmd}"/>')
    svg += "</svg>"
    image = Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg.encode()))).convert("L").resize((GW, GH), Image.BOX)
    return (np.asarray(image, dtype=np.float32) / 255.0) > 0.5, em * scale / base_scale


TARGET, SKELETON, EM = {}, {}, {}
for d in DIGITS:
    TARGET[d], EM[d] = digit_mask(d)
    SKELETON[d] = zhang_suen(TARGET[d])

DISC = {r: [(dx, dy) for dy in range(-r, r + 1) for dx in range(-r, r + 1) if dx * dx + dy * dy <= r * r] for r in range(0, 16)}


def dilate(mask, radius):
    if radius <= 0:
        return mask.copy()
    out = np.zeros_like(mask)
    ys, xs = np.nonzero(mask)
    for dx, dy in DISC[radius]:
        nx, ny = xs + dx, ys + dy
        ok = (nx >= 0) & (nx < GW) & (ny >= 0) & (ny < GH)
        out[ny[ok], nx[ok]] = True
    return out


def rnd(x):
    return int(np.floor(x + 0.5))


def smooth_field(amp, sigma=14):
    fx = ndi.gaussian_filter(rng.standard_normal((GH, GW)), sigma)
    fy = ndi.gaussian_filter(rng.standard_normal((GH, GW)), sigma)
    return fx / fx.std() * amp / CELL, fy / fy.std() * amp / CELL


def good_trace(d, amp, bias, drop):
    ys, xs = np.nonzero(SKELETON[d])
    pts = np.stack([xs, ys], 1).astype(float)
    keep = np.ones(len(pts), bool)
    removed = tries = 0
    while removed < drop * len(pts) and tries < 50:
        tries += 1
        c = pts[rng.integers(len(pts))]
        m = (np.hypot(pts[:, 0] - c[0], pts[:, 1] - c[1]) < rng.uniform(2, 5)) & keep
        removed += m.sum()
        keep &= ~m
    pts = pts[keep]
    fx, fy = smooth_field(amp)
    xi, yi = np.clip(pts[:, 0].astype(int), 0, GW - 1), np.clip(pts[:, 1].astype(int), 0, GH - 1)
    b = rng.normal(0, bias / CELL, 2)
    return np.stack([pts[:, 0] + fx[yi, xi] + b[0], pts[:, 1] + fy[yi, xi] + b[1]], 1)


def polyline(points):
    out = []
    for (ax, ay), (bx, by) in zip(points[:-1], points[1:]):
        n = max(1, int(np.ceil(np.hypot(bx - ax, by - ay) / 0.7)))
        out += [(ax + (bx - ax) * k / n, ay + (by - ay) * k / n) for k in range(n)]
    return np.array(out)


def evaluate(d, path, reach_em, tol_em, min_reach=18, min_tol=7):
    em = EM[d]
    tol = rnd(max(min_tol, tol_em * em) / CELL)
    reach = rnd(max(min_reach, reach_em * em) / CELL)
    zone = dilate(TARGET[d], tol)
    ky, kx = np.nonzero(SKELETON[d])
    if len(path) == 0:
        return 0.0, 0.0
    m = np.zeros((GH, GW), bool)
    xi, yi = np.floor(path[:, 0]).astype(int), np.floor(path[:, 1]).astype(int)
    ok = (xi >= 0) & (xi < GW) & (yi >= 0) & (yi < GH)
    m[yi[ok], xi[ok]] = True
    inside = np.zeros(len(path), bool)
    inside[ok] = zone[yi[ok], xi[ok]]
    return dilate(m, reach)[ky, kx].mean(), inside.mean()


THRESHOLDS = ((0.70, 0.60), (0.82, 0.75), (0.92, 0.85))


def stars(cov, prec):
    n = 0
    for i, (c, p) in enumerate(THRESHOLDS):
        if cov >= c and prec >= p:
            n = i + 1
    return n


def bad_attempts(d):
    em = EM[d]
    ys, xs = np.nonzero(SKELETON[d])
    sk = np.stack([xs, ys], 1).astype(float)
    shifted = lambda dx, dy: sk + np.array([dx / CELL, dy / CELL])
    left = sk[:, 0] < np.median(sk[:, 0])
    return {
        "scribble": lambda: polyline([(rng.uniform(5, 90), rng.uniform(8, 100)) for _ in range(6)]),
        "shift 0.11em": lambda: shifted(0.11 * em, 0.037 * em),   # NB: harflar sinovidagi 30pt raqamga nisbatan kichik edi
        "shift 0.16em": lambda: shifted(0.16 * em, 0.0),
        "half": lambda: sk[left],
    }


if __name__ == "__main__":
    print(f"em(1)={EM['1']:.0f}pt  em(10)={EM['10']:.0f}pt  katak={CELL:.2f}pt")
    print("  1: skelet", int(SKELETON['1'].sum()), "katak (poydevorsiz);  oddiy 1 da ~94 katak bo'lardi")
    print("\nreachEm toleranceEm | oddiy>=2★ oddiy=3★ beparvo>=1★ || yomon o'tishi: scribble shift.11 shift.16 half")
    for reach, tol in itertools.product([0.06, 0.07, 0.08, 0.0909], [0.03, 0.0364]):
        r = lambda amp, b, dr: [stars(*evaluate(d, good_trace(d, amp, b, dr), reach, tol)) for d in DIGITS for _ in range(8)]
        typical, sloppy = np.array(r(9, 6, 0.08)), np.array(r(15, 10, 0.18))
        fp = {k: np.mean([stars(*evaluate(d, bad_attempts(d)[k](), reach, tol)) >= 1 for d in DIGITS for _ in range(6)])
              for k in ["scribble", "shift 0.11em", "shift 0.16em", "half"]}
        mark = "  <- normal" if (reach, tol) == (0.07, 0.03) else ("  <- easy" if (reach, tol) == (0.08, 0.0364) else "")
        print(f" {reach:.4f}  {tol:.4f}    |  {np.mean(typical>=2):4.0%}     {np.mean(typical==3):4.0%}      {np.mean(sloppy>=1):4.0%}     ||"
              f"   {fp['scribble']:5.1%}  {fp['shift 0.11em']:5.1%}  {fp['shift 0.16em']:5.1%}  {fp['half']:5.1%}{mark}")
