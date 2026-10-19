import Foundation

/// To'rdagi katakka nisbatan siljish.
struct GridOffset: Sendable, Equatable {
    let dx: Int
    let dy: Int
}

/// Ikki o'lchamli mantiqiy to'r (past aniqlikdagi piksel niqobi).
///
/// Iz chizish baholashi butunlay shu to'rlar ustida ishlaydi: harf shakli, bola chizgani va ular
/// orasidagi masofalar. Bu qism faqat `Foundation`ga tayanadi: iOS va Android (Skip) da bir xil.
///
/// Skip Lite uchun: issiq sikllar mahalliy massivlarda ishlaydi (struct xossasini har katakda
/// o'zgartirmaslik uchun), shuning uchun natija oxirida bir marta `TraceGrid` ga o'raladi.
struct TraceGrid: Equatable, Sendable {
    let width: Int
    let height: Int
    var cells: [Bool]

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.cells = [Bool](repeating: false, count: width * height)
    }

    init(width: Int, height: Int, cells: [Bool]) {
        self.width = width
        self.height = height
        // `cells` soni width*height ga teng bo'lishi shart; aks holda bo'sh to'r olinadi.
        if cells.count == width * height {
            self.cells = cells
        } else {
            self.cells = [Bool](repeating: false, count: width * height)
        }
    }

    func isInside(x: Int, y: Int) -> Bool {
        return x >= 0 && x < width && y >= 0 && y < height
    }

    /// Chegaradan tashqari kataklar `false` hisoblanadi.
    func value(x: Int, y: Int) -> Bool {
        return isInside(x: x, y: y) && cells[y * width + x]
    }

    mutating func set(x: Int, y: Int, to newValue: Bool) {
        if isInside(x: x, y: y) {
            cells[y * width + x] = newValue
        }
    }

    /// To'ldirilgan kataklar soni.
    var filledCount: Int {
        var total = 0
        for cell in cells where cell {
            total += 1
        }
        return total
    }

    // MARK: Kengaytirish (dilation)

    /// Radiusi `radius` katak bo'lgan doiraviy siljishlar (dx² + dy² <= radius²).
    static func discOffsets(radius: Int) -> [GridOffset] {
        var offsets: [GridOffset] = []
        if radius < 0 { return offsets }
        let limit = radius * radius
        for dy in -radius...radius {
            for dx in -radius...radius where dx * dx + dy * dy <= limit {
                offsets.append(GridOffset(dx: dx, dy: dy))
            }
        }
        return offsets
    }

    /// Har bir to'ldirilgan katak atrofini `radius` katak radiusgacha to'ldiradi.
    func dilated(radius: Int) -> TraceGrid {
        if radius <= 0 { return self }
        let offsets = TraceGrid.discOffsets(radius: radius)
        let w = width
        let h = height
        let source = cells
        var out = [Bool](repeating: false, count: w * h)
        for y in 0..<h {
            for x in 0..<w where source[y * w + x] {
                for offset in offsets {
                    let nx = x + offset.dx
                    let ny = y + offset.dy
                    if nx >= 0 && nx < w && ny >= 0 && ny < h {
                        out[ny * w + nx] = true
                    }
                }
            }
        }
        return TraceGrid(width: w, height: h, cells: out)
    }
}
