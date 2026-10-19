import Foundation

/// Bir urinishning natijasi.
struct TraceScore: Equatable, Sendable {
    /// Harf markaz chizig'ining bola chizig'iga yaqin qismi (0...1).
    var coverage: Double
    /// Bola chizig'ining harf ichida (yoki ruxsat etilgan chetlikda) qolgan qismi (0...1).
    var precision: Double
    var stars: Int
    /// `i`, `j` nuqtasi kabi kichik qism tegilmagan.
    var missingDetail: Bool

    static let empty = TraceScore(coverage: 0.0, precision: 0.0, stars: 0, missingDetail: false)
}

/// Bola chizgan chiziqlarni harf bilan solishtiradi.
///
/// Algoritm (Python prototipi bilan bir xil):
/// 1. Chiziqlar zich nuqtalarga bo'linadi (har ~0.7 katakda).
/// 2. Qoplash: harf skeletining har bir katagi uchun, unga `reach` masofada bola nuqtasi bormi?
/// 3. Aniqlik: bola nuqtalarining qanchasi harf + chetlik ichida?
/// 4. Yulduz: ikkalasi ham chegaradan oshsa; nuqta qo'yilmasa ko'pi bilan 2.
///
/// Bola cho'tkasining qalinligi hisobga olinmaydi, faqat chiziq yo'li. Shuning uchun ko'rinadigan
/// siyoh qalinligini bemalol o'zgartirish mumkin.
///
/// IOS va Android (Skip) uchun umumiy: `rounded(.up/.down)`, `squareRoot()` va kortejlarsiz.
enum TraceEvaluator {

    /// `floor(value)` ni butun songa (manfiylar uchun ham to'g'ri).
    private static func floorInt(_ value: Double) -> Int {
        var result = Int(value)
        if Double(result) > value { result -= 1 }
        return result
    }

    static func evaluate(strokes: [[CGPoint]], target: TraceTarget, tuning: TraceTuning) -> TraceScore {
        let gw = target.mask.width
        let gh = target.mask.height
        if gw == 0 || gh == 0 || target.scoringCells.isEmpty { return TraceScore.empty }

        let sx = Double(gw) / Double(target.canvasSize.width)
        let sy = Double(gh) / Double(target.canvasSize.height)

        // 1) Nuqtalarni to'r koordinatalarida zichlashtirish
        var sampleX: [Double] = []
        var sampleY: [Double] = []
        for stroke in strokes {
            if stroke.isEmpty { continue }
            if stroke.count == 1 {
                sampleX.append(Double(stroke[0].x) * sx)
                sampleY.append(Double(stroke[0].y) * sy)
                continue
            }
            for i in 1..<stroke.count {
                let ax = Double(stroke[i - 1].x) * sx
                let ay = Double(stroke[i - 1].y) * sy
                let bx = Double(stroke[i].x) * sx
                let by = Double(stroke[i].y) * sy
                let length = sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay))
                let raw = length / tuning.sampleSpacingCells
                var steps = Int(raw)
                if Double(steps) < raw { steps += 1 }
                if steps < 1 { steps = 1 }
                for s in 0..<steps {
                    let t = Double(s) / Double(steps)
                    sampleX.append(ax + (bx - ax) * t)
                    sampleY.append(ay + (by - ay) * t)
                }
            }
            let last = stroke[stroke.count - 1]
            sampleX.append(Double(last.x) * sx)
            sampleY.append(Double(last.y) * sy)
        }
        if sampleX.isEmpty { return TraceScore.empty }

        // 2) Bola nuqtalari to'ri va aniqlik
        let toleranceCells = target.tolerance.cells
        var drawnCells = [Bool](repeating: false, count: gw * gh)
        var inside = 0
        for k in 0..<sampleX.count {
            let xi = floorInt(sampleX[k])
            let yi = floorInt(sampleY[k])
            if xi >= 0 && xi < gw && yi >= 0 && yi < gh {
                drawnCells[yi * gw + xi] = true
                if toleranceCells[yi * gw + xi] {
                    inside += 1
                }
            }
        }
        let precision = Double(inside) / Double(sampleX.count)

        // 3) Qoplash: bola nuqtalarini `reach` radiusga kengaytirib, skelet katagi tushadimi
        let cell = Double(target.cellSize)
        let reachCells = Int((tuning.reachPoints(em: Double(target.em)) / cell).rounded())
        let drawn = TraceGrid(width: gw, height: gh, cells: drawnCells)
        let reached = drawn.dilated(radius: reachCells).cells
        var covered = 0
        for index in target.scoringCells where reached[index] {
            covered += 1
        }
        let coverage = Double(covered) / Double(target.scoringCells.count)

        // 4) Kichik qismlar (nuqta) tegildimi?
        var missingDetail = false
        for group in target.detailGroups {
            var touched = false
            for index in group where reached[index] {
                touched = true
                break
            }
            if !touched {
                missingDetail = true
                break
            }
        }

        let stars = tuning.stars(coverage: coverage, precision: precision, missingDetail: missingDetail)
        return TraceScore(coverage: coverage, precision: precision, stars: stars, missingDetail: missingDetail)
    }
}
