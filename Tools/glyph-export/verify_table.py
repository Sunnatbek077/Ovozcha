"""Android jadvalini (GlyphTable.swift) Swift algoritmining aynan Python nusxasi bilan tekshiradi.

Bu skript Swift'dagi `TraceGrid.dilated`, `TraceMorphology`, `TraceScoring.make` va `TraceEvaluator.evaluate`
ning qator-ma-qator nusxasi (yangi, Skip'ga moslangan shakli). Jadvaldagi 68 shakl uchun sun'iy izlar bilan
yulduzlar hisoblanadi: ehtiyotkor iz 3 yulduz olishi, siljigan/bo'sh/tasodifiy iz esa o'tmasligi kerak.

Ishga tushirish:  python3 verify_table.py <GlyphTable.swift>
"""
import re
import sys
import numpy as np

GW, GH, W, H = 96, 107, 340.0, 380.0
CELL = W / GW

# --- TraceTuning (Swift bilan bir xil) ---
class Tuning:
    def __init__(s, reach_em, tol_em, min_reach, min_tol, spacing=0.7):
        s.reach_em, s.tol_em, s.min_reach, s.min_tol, s.spacing = reach_em, tol_em, min_reach, min_tol, spacing
    def reach(s, em): return max(s.min_reach, s.reach_em * em)
    def tolerance(s, em): return max(s.min_tol, s.tol_em * em)
THRESHOLDS = [(0.70, 0.60), (0.82, 0.75), (0.92, 0.85)]
NORMAL_LETTER = Tuning(0.0909, 0.0364, 18, 7)
NORMAL_DIGIT = Tuning(0.07, 0.03, 18, 7)
EASY_LETTER = Tuning(0.105, 0.04, 20, 8)
EASY_DIGIT = Tuning(0.08, 0.036, 20, 8)

def stars(cov, prec, missing):
    r = 0
    for i, (c, p) in enumerate(THRESHOLDS):
        if cov >= c and prec >= p: r = i + 1
    return 2 if (missing and r > 2) else r

# --- GlyphSource (Android) dekodlash ---
def load_table(path):
    src = open(path, encoding="utf-8").read()
    out = {}
    for m in re.finditer(r'"([^"]+)": GlyphTableEntry\(\s*em: ([\d.]+),\s*outline: "([^"]*)",\s*mask: "([^"]*)"\s*\)', src):
        out[m.group(1)] = (float(m.group(2)), m.group(3), m.group(4))
    return out

def decode_mask(text):
    cells, filled = [], False
    for tok in text.split(","):
        run = int(tok); cells += [filled] * run; filled = not filled
    return cells[:GW * GH]

# --- TraceGrid / TraceMorphology (Swift shakli: Int massivlar, mahalliy sikllar) ---
def disc_offsets(r):
    return [(dx, dy) for dy in range(-r, r + 1) for dx in range(-r, r + 1) if dx * dx + dy * dy <= r * r]

def dilated(cells, radius):
    if radius <= 0: return list(cells)
    offs = disc_offsets(radius); out = [False] * (GW * GH)
    for y in range(GH):
        for x in range(GW):
            if cells[y * GW + x]:
                for dx, dy in offs:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < GW and 0 <= ny < GH: out[ny * GW + nx] = True
    return out

def thinned(cells):
    w, h = GW, GH; pw = w + 2
    p = [0] * (pw * (h + 2))
    for y in range(h):
        for x in range(w):
            if cells[y * w + x]: p[(y + 1) * pw + (x + 1)] = 1
    changed = True
    while changed:
        changed = False
        for step in range(2):
            rem = []
            for y in range(1, h + 1):
                for x in range(1, w + 1):
                    i = y * pw + x
                    if p[i] == 0: continue
                    p2, p3, p4, p5 = p[i - pw], p[i - pw + 1], p[i + 1], p[i + pw + 1]
                    p6, p7, p8, p9 = p[i + pw], p[i + pw - 1], p[i - 1], p[i - pw - 1]
                    n = p2 + p3 + p4 + p5 + p6 + p7 + p8 + p9
                    if n < 2 or n > 6: continue
                    t = 0
                    for a, b in ((p2, p3), (p3, p4), (p4, p5), (p5, p6), (p6, p7), (p7, p8), (p8, p9), (p9, p2)):
                        if a == 0 and b == 1: t += 1
                    if t != 1: continue
                    if step == 0:
                        if p2 * p4 * p6 != 0 or p4 * p6 * p8 != 0: continue
                    else:
                        if p2 * p4 * p8 != 0 or p2 * p6 * p8 != 0: continue
                    rem.append(i)
            if rem:
                changed = True
                for i in rem: p[i] = 0
    return [p[(y + 1) * pw + (x + 1)] == 1 for y in range(h) for x in range(w)]

def components(cells):
    w, h = GW, GH; labels = [0] * (w * h); count = 0
    for start in range(w * h):
        if cells[start] and labels[start] == 0:
            count += 1; labels[start] = count; q = [start]; head = 0
            while head < len(q):
                cur = q[head]; head += 1; cx, cy = cur % w, cur // w
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        if dx == 0 and dy == 0: continue
                        nx, ny = cx + dx, cy + dy
                        if nx < 0 or nx >= w or ny < 0 or ny >= h: continue
                        n = ny * w + nx
                        if cells[n] and labels[n] == 0: labels[n] = count; q.append(n)
    return labels, count

def inside_distance(cells):
    w, h = GW, GH; large = w + h + 10
    d = [large if cells[i] else 0 for i in range(w * h)]
    def at(x, y): return 0 if (x < 0 or x >= w or y < 0 or y >= h) else d[y * w + x]
    for y in range(h):
        for x in range(w):
            if d[y * w + x] != 0:
                m = d[y * w + x]
                for a, b in ((x - 1, y - 1), (x, y - 1), (x + 1, y - 1), (x - 1, y)): m = min(m, at(a, b) + 1)
                d[y * w + x] = m
    for y in range(h - 1, -1, -1):
        for x in range(w - 1, -1, -1):
            if d[y * w + x] != 0:
                m = d[y * w + x]
                for a, b in ((x + 1, y + 1), (x, y + 1), (x - 1, y + 1), (x + 1, y)): m = min(m, at(a, b) + 1)
                d[y * w + x] = m
    return d

def scoring_make(cells):
    skeleton = thinned(cells); labels, count = components(cells)
    included = list(skeleton); groups = []
    if count > 0:
        dist = inside_distance(cells); per = [0] * (count + 1)
        for i in range(len(labels)):
            if labels[i] > 0 and skeleton[i]: per[labels[i]] += 1
        for label in range(1, count + 1):
            if per[label] < 10:
                mx = max([dist[i] for i in range(len(labels)) if labels[i] == label] or [0])
                group = [i for i in range(len(labels)) if labels[i] == label and dist[i] == mx]
                for i in group: included[i] = True
                if group: groups.append(group)
    return [i for i, v in enumerate(included) if v], groups

def floor_int(v):
    r = int(v)
    return r - 1 if float(r) > v else r

def evaluate(strokes, target, tuning):
    cells_mask, tol_cells, scoring, groups, em = target
    sx, sy = GW / W, GH / H; xs, ys = [], []
    for st in strokes:
        if not st: continue
        if len(st) == 1: xs.append(st[0][0] * sx); ys.append(st[0][1] * sy); continue
        for i in range(1, len(st)):
            ax, ay, bx, by = st[i - 1][0] * sx, st[i - 1][1] * sy, st[i][0] * sx, st[i][1] * sy
            raw = ((bx - ax) ** 2 + (by - ay) ** 2) ** 0.5 / tuning.spacing
            steps = int(raw); steps += 1 if steps < raw else 0; steps = max(1, steps)
            for s in range(steps):
                t = s / steps; xs.append(ax + (bx - ax) * t); ys.append(ay + (by - ay) * t)
        xs.append(st[-1][0] * sx); ys.append(st[-1][1] * sy)
    if not xs: return 0, 0.0, 0.0
    drawn = [False] * (GW * GH); inside = 0
    for x, y in zip(xs, ys):
        xi, yi = floor_int(x), floor_int(y)
        if 0 <= xi < GW and 0 <= yi < GH:
            drawn[yi * GW + xi] = True
            if tol_cells[yi * GW + xi]: inside += 1
    precision = inside / len(xs)
    reach_cells = int(round(tuning.reach(em) / CELL))
    reached = dilated(drawn, reach_cells)
    covered = sum(1 for i in scoring if reached[i]); coverage = covered / len(scoring)
    missing = any(not any(reached[i] for i in g) for g in groups)
    return stars(coverage, precision, missing), coverage, precision

def make_target(mask, em, tuning):
    tol_cells = dilated(mask, int(round(tuning.tolerance(em) / CELL)))
    scoring, groups = scoring_make(mask)
    return (mask, tol_cells, scoring, groups, em)

def main(path):
    table = load_table(path); rng = np.random.default_rng(3)
    rows = []
    for key, (em, outline, rle) in table.items():
        digit = key.isdigit(); tuning = NORMAL_DIGIT if digit else NORMAL_LETTER
        mask = decode_mask(rle); target = make_target(mask, em, tuning)
        skel = [i for i in target[2]]                       # skelet + nuqta markazlari (canvas nuqtalari)
        pts = [(((i % GW) + 0.5) * CELL, ((i // GW) + 0.5) * CELL) for i in skel]
        def trace(shift=(0, 0), jitter=0.0):
            return [[(x + shift[0] + rng.normal(0, jitter), y + shift[1] + rng.normal(0, jitter))] for x, y in pts]
        careful = evaluate(trace(jitter=0.01 * em), target, tuning)[0]
        sloppy = evaluate(trace(jitter=0.03 * em), target, tuning)[0]
        shifted = evaluate(trace(shift=(0.30 * em, 0.0)), target, tuning)[0]
        blank = evaluate([], target, tuning)[0]
        dot = evaluate([[(W / 2, H / 2)]], target, tuning)[0]
        scribble = evaluate([[(10 + 320 * k / 40, 60 + 260 * ((k * 7) % 11) / 10) for k in range(41)]], target, tuning)[0]
        rows.append((key, careful, sloppy, shifted, blank, dot, scribble, len(target[2]), len(target[3])))
    n = len(rows)
    print(f"{n} shakl (Android jadvali) — Swift algoritmi nusxasi")
    print(f"  ehtiyotkor iz -> 3 yulduz : {sum(r[1] == 3 for r in rows)}/{n}")
    print(f"  beparvo iz    -> >=1 yulduz: {sum(r[2] >= 1 for r in rows)}/{n}   (3 yulduz: {sum(r[2] == 3 for r in rows)})")
    print(f"  siljigan (0.3em) -> 0 yulduz: {sum(r[3] == 0 for r in rows)}/{n}")
    print(f"  bo'sh / nuqta / tasodifiy chiziq -> 0 yulduz: {sum(r[4] == 0 for r in rows)} / {sum(r[5] == 0 for r in rows)} / {sum(r[6] == 0 for r in rows)}  (har biri {n} dan)")
    bad = [r[0] for r in rows if r[1] != 3]
    print("  ehtiyotkor iz 3 yulduz olmagan:", bad or "yo'q")
    dots = [(r[0], r[8]) for r in rows if r[8] > 0]
    print("  nuqtali (i/j) shakllar:", dots)
    return rows

if __name__ == "__main__":
    main(sys.argv[1])
