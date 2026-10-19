import SwiftUI

/// Ovozcha maskoti, SwiftUI shakllaridan chizilgan (rasm fayli kerak emas).
/// Proporsiyalar PDF'dagi maskotdan o'lchangan (birlik: `size` = tana diametri).
/// Dizayner tayyor asset (SVG/PDF) bersa, shu view ichini `Image("mascot")` bilan almashtirish kifoya.
struct MascotView: View {
    /// Tana diametri (pt). Umumiy balandlik ≈ 1.2 × size (kamon + soya bilan).
    var size: CGFloat = 76

    private var outline: CGFloat { max(1.0, size * 0.018) }

    var body: some View {
        ZStack(alignment: .top) {
            groundShadow.offset(y: size * 1.14)
            bodyShape.offset(y: size * 0.14)
            bow
        }
        .frame(width: size, height: size * 1.2, alignment: .top)
        .accessibilityHidden(true) // bezak: VoiceOver uni o'tkazib yuboradi
    }

    // MARK: Tana

    private var bodyShape: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.ovHex(0xFFE676), Color.ovYellow, Color.ovHex(0xF2B800)],
                        center: UnitPoint(x: 0.38, y: 0.3),
                        startRadius: 0,
                        endRadius: size * 0.75
                    )
                )
            Circle()
                .strokeBorder(Color.ovPurple, lineWidth: outline)
            face
            waveform.offset(y: size * 0.16)
        }
        .frame(width: size, height: size)
    }

    // MARK: Yuz

    private var face: some View {
        ZStack {
            HStack(spacing: size * 0.03) { eye; eye }
                .offset(y: -size * 0.13)
            HStack(spacing: size * 0.35) { cheek; cheek }
                .offset(y: -size * 0.055)
            Smile()
                .stroke(Color.ovInk, style: StrokeStyle(lineWidth: size * 0.022, lineCap: .round))
                .frame(width: size * 0.19, height: size * 0.05)
        }
    }

    private var eye: some View {
        ZStack {
            Ellipse().fill(Color.white)
            Circle()
                .fill(Color.ovInk)
                .frame(width: size * 0.09, height: size * 0.09)
                .offset(x: -size * 0.005, y: size * 0.02)
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.032, height: size * 0.032)
        }
        .frame(width: size * 0.21, height: size * 0.22)
    }

    private var cheek: some View {
        Ellipse()
            .fill(Color.ovHex(0xFF96A5).opacity(0.75))
            .frame(width: size * 0.14, height: size * 0.10)
    }

    // MARK: Ovoz to'lqini (ismi "Ovozcha" ekanining belgisi)

    private static let waveHeights: [CGFloat] = [0.07, 0.10, 0.155, 0.24, 0.155, 0.10, 0.07]

    private var waveform: some View {
        HStack(spacing: size * 0.025) {
            ForEach(Array(MascotView.waveHeights.enumerated()), id: \.offset) { _, height in
                Capsule()
                    .fill(Color.white)
                    .frame(width: size * 0.028, height: size * height)
            }
        }
    }

    // MARK: Kamon

    private var bow: some View {
        ZStack {
            bowLoop(angle: 14).offset(x: -size * 0.22)
            bowLoop(angle: -14).offset(x: size * 0.22)
            Circle()
                .fill(Color.ovPurple)
                .frame(width: size * 0.11, height: size * 0.11)
                .offset(y: size * 0.075)
        }
        .frame(width: size * 0.82, height: size * 0.25)
    }

    private func bowLoop(angle: Double) -> some View {
        Ellipse()
            .fill(Color.ovYellow)
            .overlay(Ellipse().strokeBorder(Color.ovPurple, lineWidth: outline))
            .frame(width: size * 0.40, height: size * 0.20)
            .rotationEffect(.degrees(angle))
    }

    // MARK: Yer soyasi

    private var groundShadow: some View {
        Ellipse()
            .fill(Color.ovInk.opacity(0.10))
            .frame(width: size * 0.56, height: size * 0.06)
    }
}

/// Tabassum: ikki nuqtani pastga egilgan egri chiziq bilan tutashtiradi.
private struct Smile: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        // Kvadratik egri chiziq nazorat nuqtasigacha faqat yarim yo'l egiladi,
        // shuning uchun nazorat nuqtasi 2× balandlikda.
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.minY + rect.height * 2)
        )
        return path
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 32) {
        MascotView(size: 76)
        MascotView(size: 160)
    }
    .padding(32)
    .background(Color.ovBackground)
}
#endif
