#if !SKIP
import Foundation
import CoreGraphics

/// Vektor konturni past aniqlikdagi mantiqiy to'rga (niqob) aylantiradi.
enum GlyphRasterizer {

    /// `path` tuval koordinatalarida (y pastga). Natija: kengligi `gridWidth` bo'lgan to'r,
    /// balandligi tuval nisbatidan.
    static func mask(of path: CGPath, canvas: CGSize, gridWidth: Int) -> TraceGrid {
        let gridHeight = max(1, Int((CGFloat(gridWidth) * canvas.height / canvas.width).rounded()))
        var bytes = [UInt8](repeating: 0, count: gridWidth * gridHeight)

        bytes.withUnsafeMutableBytes { raw in
            guard let base = raw.baseAddress,
                  let context = CGContext(
                    data: base,
                    width: gridWidth,
                    height: gridHeight,
                    bitsPerComponent: 8,
                    bytesPerRow: gridWidth,
                    space: CGColorSpaceCreateDeviceGray(),
                    bitmapInfo: CGImageAlphaInfo.none.rawValue
                  ) else { return }

            context.setShouldAntialias(true)
            // Bitmap xotirasida birinchi qator tepada; tuval koordinatalari ham y pastga: aylantiramiz.
            context.translateBy(x: 0, y: CGFloat(gridHeight))
            context.scaleBy(
                x: CGFloat(gridWidth) / canvas.width,
                y: -CGFloat(gridHeight) / canvas.height
            )
            context.setFillColor(gray: 1, alpha: 1)
            context.addPath(path)
            context.fillPath()
        }

        var cells = [Bool](repeating: false, count: bytes.count)
        for i in 0..<bytes.count where bytes[i] > 127 {
            cells[i] = true
        }
        return TraceGrid(width: gridWidth, height: gridHeight, cells: cells)
    }
}
#endif
