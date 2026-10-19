import SwiftUI

/// Sonning miqdorini ko'rsatuvchi marjon-rangli nuqtalar (maketdagi "5" ostidagi 5 ta nuqta).
/// 5 tadan ko'p bo'lsa, ikki qatorga bo'linadi (6 = 5 + 1, 10 = 5 + 5).
struct CountDotsView: View {
    let count: Int

    private let dotSize: CGFloat = 20.0

    var body: some View {
        VStack(spacing: 6) {
            row(count: min(count, 5))
            if count > 5 {
                row(count: count - 5)
            }
        }
        // Miqdorni chip va raqam matni aytadi; nuqtalarning o'zi bezak.
        .accessibilityHidden(true)
    }

    private func row(count: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { _ in
                Circle()
                    .fill(NumberPalette.dot)
                    .frame(width: dotSize, height: dotSize)
            }
        }
    }
}

enum NumberPalette {
    /// Maketdan o'lchangan (#FF8F70).
    static var dot: Color { Color.ovHex(0xFF8F70) }
}
