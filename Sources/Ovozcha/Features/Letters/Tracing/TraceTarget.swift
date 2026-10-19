import Foundation
#if !SKIP
import CoreGraphics
#endif

/// Bitta harf (bitta shakl, bitta tuval o'lchami) uchun tayyorlangan baholash maqsadi.
struct TraceTarget: Sendable {
    /// Harf shakli.
    let mask: TraceGrid
    /// Harf shakli + ruxsat etilgan chetlik.
    let tolerance: TraceGrid
    /// Baholanadigan kataklar (skelet + nuqta markazlari).
    let scoringCells: [Int]
    let detailGroups: [[Int]]
    let canvasSize: CGSize
    /// Harf shrifti o'lchami (nuqtada), kengligi sig'may kichraytirilgan bo'lsa shu kichraytirilgani.
    let em: CGFloat

    /// Bir katak necha nuqta (tuval kengligi bo'yicha).
    var cellSize: CGFloat {
        canvasSize.width / CGFloat(mask.width)
    }

    init(mask: TraceGrid, canvasSize: CGSize, em: CGFloat, tuning: TraceTuning) {
        self.mask = mask
        self.canvasSize = canvasSize
        self.em = em

        let cell = canvasSize.width / CGFloat(mask.width)
        let toleranceCells = Int((tuning.tolerancePoints(em: Double(em)) / Double(cell)).rounded())
        self.tolerance = mask.dilated(radius: toleranceCells)

        let scoring = TraceScoring.make(from: mask)
        self.scoringCells = scoring.cells
        self.detailGroups = scoring.detailGroups
    }
}
