#if !SKIP
import Foundation
import CoreGraphics
import CoreText

/// Tuvalga joylashtirilgan harf konturi.
struct GlyphLayout {
    /// Tuval koordinatalarida (y pastga qarab) kontur.
    let path: CGPath
    /// Amalda ishlatilgan shrift o'lchami. Kenglik sig'masa kichraytirilgan bo'ladi.
    let em: CGFloat
}

/// Harf, digraf (`Sh`, `Ch`, `Ng`) yoki raqam konturini Core Text orqali oladi.
///
/// Joylashuv bir turdagi barcha elementlar uchun bir xil: umumiy asosiy chiziq (baseline) va shrift
/// o'lchami. Shunda `g`, `j`, `p`, `q`, `y` pastga tushadi, `b`, `d`, `h`, `k` yuqoriga chiqadi va
/// harflar orasidagi nisbiy o'lcham saqlanadi (bola katta/kichik harfni farqlashi uchun muhim).
/// Raqamlar pastga tushmaydi, shuning uchun ular kartada vertikal markazlashtiriladi.
enum GlyphOutline {

    struct Profile {
        /// Shrift o'lchami tuval balandligining shuncha ulushi.
        let emFraction: CGFloat
        /// Asosiy chiziq (baseline) tuval balandligining shuncha ulushida.
        let baselineFraction: CGFloat
        /// Kenglik tuval kengligining shuncha ulushidan oshmaydi (oshsa, bir tekis kichraytiriladi).
        let maxWidthFraction: CGFloat
    }

    static func profile(for kind: TraceKind) -> Profile {
        switch kind {
        case .letter: return Profile(emFraction: 0.86, baselineFraction: 0.74, maxWidthFraction: 0.86)
        case .digit:  return Profile(emFraction: 0.80, baselineFraction: 0.79, maxWidthFraction: 0.86)
        }
    }

    /// Andika'dagi poydevorsiz "1" (maktabda yoziladigan shakl: bayroqcha va tik chiziq).
    /// Oddiy "1" da pastki chiziq (poydevor) bor, bola uni ham chizishi kerak bo'lib qolardi.
    private static let plainOneGlyphName = "one.NoBase"

    static func layout(text: String, canvas: CGSize, kind: TraceKind = .letter) -> GlyphLayout {
        let profile = profile(for: kind)
        let em = canvas.height * profile.emFraction
        let font = TraceFont.makeCTFont(size: em)

        let combined: CGPath
        switch kind {
        case .letter: combined = letterPath(text: text, font: font)
        case .digit:  combined = digitPath(text: text, font: font)
        }

        // Core Text konturi y yuqoriga yo'nalgan; tuvalniki pastga. Markazlash va kichraytirish.
        let bounds = combined.boundingBoxOfPath
        if bounds.isNull || bounds.isEmpty || bounds.width <= 0 {
            return GlyphLayout(path: CGPath(rect: .zero, transform: nil), em: em)
        }

        let maxWidth = canvas.width * profile.maxWidthFraction
        let scale = min(1, maxWidth / bounds.width)
        let baseline = canvas.height * profile.baselineFraction

        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: canvas.width / 2, y: baseline)
        transform = transform.scaledBy(x: scale, y: -scale)
        transform = transform.translatedBy(x: -bounds.midX, y: 0)

        let placed = combined.copy(using: &transform) ?? combined
        return GlyphLayout(path: placed, em: em * scale)
    }

    // MARK: Harflar (Core Text satri)

    private static func letterPath(text: String, font: CTFont) -> CGPath {
        let attributed = NSAttributedString(
            string: text,
            attributes: [kCTFontAttributeName as NSAttributedString.Key: font]
        )
        let line = CTLineCreateWithAttributedString(attributed)
        let runs = CTLineGetGlyphRuns(line) as! [CTRun]

        let combined = CGMutablePath()
        for run in runs {
            let count = CTRunGetGlyphCount(run)
            if count == 0 { continue }

            var glyphs = [CGGlyph](repeating: 0, count: count)
            var positions = [CGPoint](repeating: .zero, count: count)
            CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
            CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)

            // Har bir bo'lakning o'z shrifti bo'lishi mumkin (yetishmagan belgi uchun zaxira shrift).
            let attributes = CTRunGetAttributes(run) as NSDictionary
            var runFont = font
            if let value = attributes[kCTFontAttributeName as String] {
                runFont = value as! CTFont
            }

            for i in 0..<count {
                if let glyphPath = CTFontCreatePathForGlyph(runFont, glyphs[i], nil) {
                    let move = CGAffineTransform(translationX: positions[i].x, y: positions[i].y)
                    combined.addPath(glyphPath, transform: move)
                }
            }
        }
        return combined
    }

    // MARK: Raqamlar (belgi-belgi, poydevorsiz "1" bilan)

    private static func digitPath(text: String, font: CTFont) -> CGPath {
        let plainOne = CTFontGetGlyphWithName(font, plainOneGlyphName as CFString)
        let combined = CGMutablePath()
        var x: CGFloat = 0

        for scalar in text.unicodeScalars {
            var characters = Array(String(scalar).utf16)
            var glyphs = [CGGlyph](repeating: 0, count: characters.count)
            if !CTFontGetGlyphsForCharacters(font, &characters, &glyphs, characters.count) {
                continue
            }
            var glyph = glyphs[0]
            if scalar == "1" && plainOne != 0 {
                glyph = plainOne
            }
            if let glyphPath = CTFontCreatePathForGlyph(font, glyph, nil) {
                combined.addPath(glyphPath, transform: CGAffineTransform(translationX: x, y: 0))
            }
            var advance = CGSize.zero
            CTFontGetAdvancesForGlyphs(font, .horizontal, &glyph, &advance, 1)
            x += advance.width
        }
        return combined
    }
}
#endif
