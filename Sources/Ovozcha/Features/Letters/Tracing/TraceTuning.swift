import Foundation

/// Iz chizish baholashining barcha sozlamalari bir joyda.
///
/// Raqamlar Python'dagi simulyatsiyada (29 harf x 2 shakl, "ehtiyotkor / oddiy / beparvo" bola va
/// yomon urinishlar) tanlangan. HAQIQIY BOLALAR bilan sinab, shu yerda moslanadi:
/// kattalar kattalikning `em` ulushi (harf shrifti o'lchami) bilan beriladi, kichik ekranda
/// esa barmoq o'lchamidan kichik bo'lib ketmasligi uchun nuqtadagi pastki chegara bor.
struct TraceTuning: Sendable, Equatable {

    struct StarThreshold: Sendable, Equatable {
        /// Harf markaz chizig'ining kamida shuncha qismi bola chizig'iga yaqin bo'lishi kerak (0...1).
        let coverage: Double
        /// Bola chizgan nuqtalarning kamida shuncha qismi harf (+ ruxsat etilgan chetlik) ichida bo'lishi kerak (0...1).
        let precision: Double
    }

    /// Markaz chizig'i "qoplangan" hisoblanishi uchun bola chizig'igacha masofa (em ulushida).
    let reachEm: Double
    /// Harf shaklidan tashqariga shuncha chiqish ruxsat etiladi (em ulushida).
    let toleranceEm: Double
    let minReachPoints: Double
    let minTolerancePoints: Double
    /// 1, 2 va 3 yulduz uchun chegaralar (tartib bilan).
    let thresholds: [StarThreshold]
    /// To'r kengligi (kataklarda). Balandlik tuval nisbatidan olinadi.
    let gridWidth: Int
    /// Bola chizig'i nuqtalari orasidagi maksimal masofa (kataklarda) namunalanganda.
    let sampleSpacingCells: Double
    /// Raqamlar uchun `reachEm` / `toleranceEm` (raqamlar ixcham va katta, shuning uchun qat'iyroq).
    let digitReachEm: Double
    let digitToleranceEm: Double

    /// Nima chizilayotganiga qarab sozlama: raqamlar uchun `digit*` qiymatlari.
    func tuned(for kind: TraceKind) -> TraceTuning {
        switch kind {
        case .letter:
            return self
        case .digit:
            return TraceTuning(
                reachEm: digitReachEm,
                toleranceEm: digitToleranceEm,
                minReachPoints: minReachPoints,
                minTolerancePoints: minTolerancePoints,
                thresholds: thresholds,
                gridWidth: gridWidth,
                sampleSpacingCells: sampleSpacingCells,
                digitReachEm: digitReachEm,
                digitToleranceEm: digitToleranceEm
            )
        }
    }

    func reachPoints(em: Double) -> Double {
        max(minReachPoints, reachEm * em)
    }

    func tolerancePoints(em: Double) -> Double {
        max(minTolerancePoints, toleranceEm * em)
    }

    /// Ko'rsatkichlardan yulduz sonini hisoblaydi (0...3).
    /// `missingDetail`: harfning nuqtasi (`i`, `j`) kabi kichik qismi tegilmagan bo'lsa, ko'pi bilan 2.
    func stars(coverage: Double, precision: Double, missingDetail: Bool) -> Int {
        var result = 0
        for (index, threshold) in thresholds.enumerated() {
            if coverage >= threshold.coverage && precision >= threshold.precision {
                result = index + 1
            }
        }
        if missingDetail && result > 2 {
            result = 2
        }
        return result
    }

    private static let standardThresholds: [StarThreshold] = [
        StarThreshold(coverage: 0.70, precision: 0.60),
        StarThreshold(coverage: 0.82, precision: 0.75),
        StarThreshold(coverage: 0.92, precision: 0.85)
    ]

    /// Odatiy qiyinlik. Simulyatsiya (chegara em = 220 pt uchun): ehtiyotkor iz 98% da 3 yulduz,
    /// oddiy iz 78% da 3 yulduz; bo'sh, nuqta, chiziqcha, to'ldirib chizish, siljigan va yarim
    /// chizilgan urinishlar 0-3.4% da 1 yulduzdan oshadi.
    ///
    /// Raqamlar (`digitReachEm 0.07`, `digitToleranceEm 0.03`): simulyatsiyada (ikki yurgizish)
    /// oddiy bola 95-98% da 2 yulduz yoki undan yuqori oladi; siljigan va yarim chizilgan iz o'tmaydi,
    /// tasodifiy chiziqlar 2-5% da o'tadi. Harflar uchun tanlangan qiymatlar raqamlarda juda bo'sh
    /// chiqqan edi (siljigan iz 40% da o'tardi), shuning uchun raqamlarga alohida sozlama berilgan.
    /// Qayta hisoblash: `Tools/trace-prototype/digits.py`.
    static let normal = TraceTuning(
        reachEm: 0.0909,
        toleranceEm: 0.0364,
        minReachPoints: 18,
        minTolerancePoints: 7,
        thresholds: standardThresholds,
        gridWidth: 96,
        sampleSpacingCells: 0.7,
        digitReachEm: 0.07,
        digitToleranceEm: 0.03
    )

    /// Yumshoqroq: 4-5 yoshli bolalar uchun. Simulyatsiyada "beparvo" iz 0 yulduzni 33% dan 22% ga
    /// tushiradi, lekin yarim chizilgan harfning 1 yulduz olish ehtimoli 3% dan 10% ga oshadi.
    /// Raqamlar uchun (`0.08` / `0.036`): beparvo bola 79-88% da kamida 1 yulduz oladi,
    /// tasodifiy chiziqlar 0-5% da o'tadi, siljigan va yarim chizilgan iz o'tmaydi.
    static let easy = TraceTuning(
        reachEm: 0.105,
        toleranceEm: 0.04,
        minReachPoints: 20,
        minTolerancePoints: 8,
        thresholds: standardThresholds,
        gridWidth: 96,
        sampleSpacingCells: 0.7,
        digitReachEm: 0.08,
        digitToleranceEm: 0.036
    )
}
