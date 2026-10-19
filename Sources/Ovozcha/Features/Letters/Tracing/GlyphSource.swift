import SwiftUI

// Harf/raqam konturi va niqobini beruvchi manba. Ikki platformada turlicha olinadi:
//
// - iOS: CoreText konturi + CoreGraphics rasterlash (`GlyphOutline`, `GlyphRasterizer`), tuval o'lchamiga
//   moslab, ish vaqtida.
// - Android (Skip): CoreText va CoreGraphics yo'q, shuning uchun kontur va niqob OLDINDAN hisoblangan
//   (`GlyphTable`, Tools/glyph-export/export_glyphs.py) va aniq 340 x 380 "tuval"ga bog'langan.
//   Tuval ko'rinishi (`TraceCanvasView`) shu tuvalni real o'lchamga moslab (letterbox) chizadi.

#if SKIP

/// Android: kontur (tuval koordinatalarida, ko'pburchak) va niqob.
struct GlyphBuild {
    let mask: TraceGrid
    let em: CGFloat
    let guidePolylines: [[CGPoint]]
}

enum GlyphSource {

    /// Android'dagi "tuval" o'lchami: jadval shu o'lchamda hisoblangan.
    static let referenceSize = CGSize(width: GlyphTable.canvasWidth, height: GlyphTable.canvasHeight)

    static func build(subject: TraceSubject, canvas: CGSize, gridWidth: Int) -> GlyphBuild {
        guard let entry = GlyphTable.entry(for: tableKey(for: subject)) else {
            return GlyphBuild(
                mask: TraceGrid(width: GlyphTable.gridWidth, height: GlyphTable.gridHeight),
                em: 200.0,
                guidePolylines: []
            )
        }
        return GlyphBuild(
            mask: decodeMask(entry.mask),
            em: entry.em,
            guidePolylines: decodeOutline(entry.outline)
        )
    }

    /// Harf: "a|U" (bosh) yoki "a|L" (kichik). Raqam: "5".
    static func tableKey(for subject: TraceSubject) -> String {
        if subject.kind == TraceKind.digit {
            return subject.id
        }
        if subject.letterCase == LetterCase.lower {
            return subject.id + "|L"
        }
        return subject.id + "|U"
    }

    /// Yugurish uzunligi (RLE) qatori: 0-lardan boshlab galma-gal uzunliklar.
    static func decodeMask(_ text: String) -> TraceGrid {
        let width = GlyphTable.gridWidth
        let height = GlyphTable.gridHeight
        var cells = [Bool](repeating: false, count: width * height)
        var position = 0
        var filled = false
        for token in text.split(separator: ",") {
            guard let run = Int(String(token)) else { continue }
            if filled {
                var k = 0
                while k < run && position + k < cells.count {
                    cells[position + k] = true
                    k += 1
                }
            }
            position += run
            filled = !filled
        }
        return TraceGrid(width: width, height: height, cells: cells)
    }

    /// "x,y x,y ...;x,y ..." -> konturlar.
    static func decodeOutline(_ text: String) -> [[CGPoint]] {
        var contours: [[CGPoint]] = []
        for contourText in text.split(separator: ";") {
            var points: [CGPoint] = []
            for pairText in contourText.split(separator: " ") {
                let parts = pairText.split(separator: ",")
                if parts.count == 2 {
                    if let x = Double(String(parts[0])), let y = Double(String(parts[1])) {
                        points.append(CGPoint(x: x, y: y))
                    }
                }
            }
            if points.count > 1 {
                contours.append(points)
            }
        }
        return contours
    }
}

#else

/// iOS: kontur (`Path`) va niqob.
struct GlyphBuild {
    let mask: TraceGrid
    let em: CGFloat
    let guide: Path
}

enum GlyphSource {

    static func build(subject: TraceSubject, canvas: CGSize, gridWidth: Int) -> GlyphBuild {
        let layout = GlyphOutline.layout(text: subject.text, canvas: canvas, kind: subject.kind)
        let mask = GlyphRasterizer.mask(of: layout.path, canvas: canvas, gridWidth: gridWidth)
        return GlyphBuild(mask: mask, em: layout.em, guide: Path(layout.path))
    }
}

#endif
