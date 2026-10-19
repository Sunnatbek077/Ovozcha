import Foundation

/// Bog'langan komponentlarni belgilash natijasi.
struct ComponentLabelling {
    /// `labels[i] == 0` fon; komponentlar 1...count.
    let labels: [Int]
    let count: Int
}

/// Harf shaklini "markaz chizig'i" (skelet) va bo'laklarga ajratish.
///
/// IOS va Android (Skip) uchun umumiy. Skip Lite'ga moslashtirilgan: belgisiz sonlar o'rniga `Int`,
/// issiq sikllar mahalliy massivlarda.
enum TraceMorphology {

    // MARK: Zhang–Suen yupqalashtirish

    /// Shaklni bir katak qalinlikdagi markaz chizig'igacha yupqalashtiradi (Zhang–Suen).
    /// Chegaradan tashqari kataklar bo'sh hisoblanadi. Python prototipidagi bilan bir xil.
    static func thinned(_ grid: TraceGrid) -> TraceGrid {
        let w = grid.width
        let h = grid.height
        if w == 0 || h == 0 { return grid }
        let source = grid.cells
        let pw = w + 2
        var p = [Int](repeating: 0, count: pw * (h + 2))
        for y in 0..<h {
            for x in 0..<w where source[y * w + x] {
                p[(y + 1) * pw + (x + 1)] = 1
            }
        }

        var changed = true
        while changed {
            changed = false
            for step in 0..<2 {
                var toRemove: [Int] = []
                for y in 1...h {
                    for x in 1...w {
                        let i = y * pw + x
                        if p[i] == 0 { continue }

                        // Soat mili bo'yicha, shimoldan boshlab: P2..P9
                        let p2 = p[i - pw]
                        let p3 = p[i - pw + 1]
                        let p4 = p[i + 1]
                        let p5 = p[i + pw + 1]
                        let p6 = p[i + pw]
                        let p7 = p[i + pw - 1]
                        let p8 = p[i - 1]
                        let p9 = p[i - pw - 1]

                        let neighbours = p2 + p3 + p4 + p5 + p6 + p7 + p8 + p9
                        if neighbours < 2 || neighbours > 6 { continue }

                        var transitions = 0
                        if p2 == 0 && p3 == 1 { transitions += 1 }
                        if p3 == 0 && p4 == 1 { transitions += 1 }
                        if p4 == 0 && p5 == 1 { transitions += 1 }
                        if p5 == 0 && p6 == 1 { transitions += 1 }
                        if p6 == 0 && p7 == 1 { transitions += 1 }
                        if p7 == 0 && p8 == 1 { transitions += 1 }
                        if p8 == 0 && p9 == 1 { transitions += 1 }
                        if p9 == 0 && p2 == 1 { transitions += 1 }
                        if transitions != 1 { continue }

                        if step == 0 {
                            if p2 * p4 * p6 != 0 { continue }
                            if p4 * p6 * p8 != 0 { continue }
                        } else {
                            if p2 * p4 * p8 != 0 { continue }
                            if p2 * p6 * p8 != 0 { continue }
                        }
                        toRemove.append(i)
                    }
                }
                if !toRemove.isEmpty {
                    changed = true
                    for i in toRemove {
                        p[i] = 0
                    }
                }
            }
        }

        var out = [Bool](repeating: false, count: w * h)
        for y in 0..<h {
            for x in 0..<w where p[(y + 1) * pw + (x + 1)] == 1 {
                out[y * w + x] = true
            }
        }
        return TraceGrid(width: w, height: h, cells: out)
    }

    // MARK: Bog'langan komponentlar

    /// 8 qo'shnilik bo'yicha bog'langan komponentlar.
    static func components(of grid: TraceGrid) -> ComponentLabelling {
        let w = grid.width
        let h = grid.height
        let source = grid.cells
        var labels = [Int](repeating: 0, count: w * h)
        var count = 0

        for start in 0..<(w * h) where source[start] && labels[start] == 0 {
            count += 1
            labels[start] = count
            var queue: [Int] = [start]
            var head = 0
            while head < queue.count {
                let current = queue[head]
                head += 1
                let cx = current % w
                let cy = current / w
                for dy in -1...1 {
                    for dx in -1...1 {
                        if dx == 0 && dy == 0 { continue }
                        let nx = cx + dx
                        let ny = cy + dy
                        if nx < 0 || nx >= w || ny < 0 || ny >= h { continue }
                        let n = ny * w + nx
                        if source[n] && labels[n] == 0 {
                            labels[n] = count
                            queue.append(n)
                        }
                    }
                }
            }
        }
        return ComponentLabelling(labels: labels, count: count)
    }

    // MARK: Ichki masofa

    /// Har bir to'ldirilgan katak uchun fon (yoki to'r chegarasi) gacha 8-qo'shni (Chebyshev) masofa.
    /// Fon kataklari 0. Ikki o'tishli algoritm.
    static func insideDistance(of grid: TraceGrid) -> [Int] {
        let w = grid.width
        let h = grid.height
        let source = grid.cells
        let large = w + h + 10
        var d = [Int](repeating: 0, count: w * h)
        for i in 0..<(w * h) where source[i] {
            d[i] = large
        }

        func at(_ x: Int, _ y: Int) -> Int {
            if x < 0 || x >= w || y < 0 || y >= h { return 0 }
            return d[y * w + x]
        }

        for y in 0..<h {
            for x in 0..<w where d[y * w + x] != 0 {
                var m = d[y * w + x]
                m = min(m, at(x - 1, y - 1) + 1)
                m = min(m, at(x, y - 1) + 1)
                m = min(m, at(x + 1, y - 1) + 1)
                m = min(m, at(x - 1, y) + 1)
                d[y * w + x] = m
            }
        }
        var y = h - 1
        while y >= 0 {
            var x = w - 1
            while x >= 0 {
                if d[y * w + x] != 0 {
                    var m = d[y * w + x]
                    m = min(m, at(x + 1, y + 1) + 1)
                    m = min(m, at(x, y + 1) + 1)
                    m = min(m, at(x - 1, y + 1) + 1)
                    m = min(m, at(x + 1, y) + 1)
                    d[y * w + x] = m
                }
                x -= 1
            }
            y -= 1
        }
        return d
    }
}

// MARK: - Baholanadigan kataklar

/// Baholashda ishlatiladigan kataklar: skelet + kichik "bezak" komponentlari (masalan `i` nuqtasi).
struct TraceScoringSet: Sendable, Equatable {
    /// Skelet va nuqta markazlari (to'r indekslari).
    let cells: [Int]
    /// Har bir kichik komponent (nuqta) uchun markaziy kataklar. Bola shu guruhga tegmasa,
    /// yulduz ko'pi bilan 2 bo'ladi.
    let detailGroups: [[Int]]
}

enum TraceScoring {

    /// Komponentda shuncha (yoki undan kam) skelet katagi bo'lsa, u "bezak" (nuqta) hisoblanadi.
    static let minSkeletonPerComponent = 10

    static func make(from mask: TraceGrid) -> TraceScoringSet {
        let skeleton = TraceMorphology.thinned(mask)
        let skeletonCells = skeleton.cells
        let labelling = TraceMorphology.components(of: mask)
        let labels = labelling.labels
        let count = labelling.count

        var included = skeletonCells
        var groups: [[Int]] = []

        if count > 0 {
            let dist = TraceMorphology.insideDistance(of: mask)
            var skeletonPerLabel = [Int](repeating: 0, count: count + 1)
            for i in 0..<labels.count where labels[i] > 0 && skeletonCells[i] {
                skeletonPerLabel[labels[i]] += 1
            }
            for label in 1...count where skeletonPerLabel[label] < minSkeletonPerComponent {
                var maxDistance = 0
                for i in 0..<labels.count where labels[i] == label {
                    if dist[i] > maxDistance { maxDistance = dist[i] }
                }
                var group: [Int] = []
                for i in 0..<labels.count where labels[i] == label && dist[i] == maxDistance {
                    group.append(i)
                    included[i] = true
                }
                if !group.isEmpty { groups.append(group) }
            }
        }

        var cells: [Int] = []
        for i in 0..<included.count where included[i] {
            cells.append(i)
        }
        return TraceScoringSet(cells: cells, detailGroups: groups)
    }
}
