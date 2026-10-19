import SwiftUI

#if SKIP

/// Chizish tuvali (Android): harfning to'ldirilgan va nuqtali konturi (ko'rsatma) hamda bola chizgan siyoh.
///
/// Android'da `Canvas` va `GraphicsContext` yo'q, shuning uchun hammasi oddiy `Shape` (`Path`) lardan
/// yig'iladi. Jadval (`GlyphTable`) 340 x 380 "tuval"da hisoblangan: ko'rinish uni real o'lchamga
/// moslab (letterbox) chizadi, barmoq nuqtalari esa aksincha 340 x 380 koordinatalarga aylantirilib
/// sessiyaga beriladi. Shunda baholash iOS'dagi bilan bir xil o'lchamda ishlaydi.
///
/// Siyoh harf ichida to'liq rangda, tashqarisida xira (iOS'dagidek): to'liq rangdagi qatlam
/// `.mask` bilan harf konturi ichiga qisqartiriladi.
struct TraceCanvasView: View {
    let session: TraceSession

    var body: some View {
        GeometryReader { proxy in
            let refWidth = GlyphTable.canvasWidth
            let refHeight = GlyphTable.canvasHeight
            let scale = min(proxy.size.width / refWidth, proxy.size.height / refHeight)
            let offsetX = (proxy.size.width - refWidth * scale) / 2.0
            let offsetY = (proxy.size.height - refHeight * scale) / 2.0
            let ink = session.inkWidth * scale

            ZStack {
                Rectangle()
                    .fill(Color.ovSurface)
                // Ko'rsatma: maketdagi och bej to'ldirish + nuqtali kontur.
                TracePolylines(lines: session.guidePolylines, scale: scale, offsetX: offsetX, offsetY: offsetY)
                    .fill(TracePalette.guideFill)
                TracePolylines(lines: session.guidePolylines, scale: scale, offsetX: offsetX, offsetY: offsetY)
                    .stroke(TracePalette.guideOutline, style: StrokeStyle(lineWidth: 2.0, lineCap: .round, dash: [0.5, 7.0]))
                // 1) Hamma joyda xira siyoh (harfdan tashqarisi shu holda qoladi).
                TracePolylines(lines: session.strokes, scale: scale, offsetX: offsetX, offsetY: offsetY)
                    .stroke(TracePalette.inkOutside, style: StrokeStyle(lineWidth: ink, lineCap: .round, lineJoin: .round))
                // 2) Harf ichida to'liq rangdagi siyoh.
                TracePolylines(lines: session.strokes, scale: scale, offsetX: offsetX, offsetY: offsetY)
                    .stroke(TracePalette.inkInside, style: StrokeStyle(lineWidth: ink, lineCap: .round, lineJoin: .round))
                    .mask {
                        TracePolylines(lines: session.guidePolylines, scale: scale, offsetX: offsetX, offsetY: offsetY)
                            .fill(Color.black)
                    }
            }
            .gesture(
                DragGesture(minimumDistance: 0.0)
                    .onChanged { value in
                        if !session.isStrokeActive {
                            session.beginStroke(at: CGPoint(
                                x: (value.startLocation.x - offsetX) / scale,
                                y: (value.startLocation.y - offsetY) / scale
                            ))
                        }
                        session.extendStroke(to: CGPoint(
                            x: (value.location.x - offsetX) / scale,
                            y: (value.location.y - offsetY) / scale
                        ))
                    }
                    .onEnded { _ in
                        session.endStroke()
                    }
            )
            .onAppear {
                session.setCanvasSize(GlyphSource.referenceSize)
            }
        }
    }
}

/// Ko'pburchaklar (yoki chiziqlar) to'plamini `scale` va siljish bilan chizadigan shakl.
/// Faqat `move` va `addLine` ishlatiladi (SkipUI'da tekshirilgan). Bitta nuqtali "chiziq" nuqta bo'lib chiqadi.
struct TracePolylines: Shape {
    let lines: [[CGPoint]]
    let scale: Double
    let offsetX: Double
    let offsetY: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for line in lines {
            if line.count == 0 { continue }
            let first = line[0]
            let startX = Double(first.x) * scale + offsetX
            let startY = Double(first.y) * scale + offsetY
            path.move(to: CGPoint(x: startX, y: startY))
            if line.count == 1 {
                // Bitta bosish: yumaloq uchli juda qisqa kesma nuqta bo'lib ko'rinadi.
                path.addLine(to: CGPoint(x: startX + 0.1, y: startY))
            } else {
                for i in 1..<line.count {
                    let point = line[i]
                    path.addLine(to: CGPoint(x: Double(point.x) * scale + offsetX, y: Double(point.y) * scale + offsetY))
                }
            }
        }
        return path
    }
}

#else



/// Chizish tuvali: harfning nuqtali konturi (ko'rsatma) va bola chizgan siyoh.
///
/// Siyoh harf ichida to'liq rangda, tashqarisida xira chiqadi: bola qayerda chegaradan
/// chiqqanini ko'radi, lekin urinishi "xato" deb bloklanmaydi.
struct TraceCanvasView: View {
    let session: TraceSession

    var body: some View {
        GeometryReader { proxy in
            let guide = session.guide
            let strokes = session.strokes
            let inkWidth = session.inkWidth

            Canvas { context, _ in
                TraceCanvasView.draw(into: &context, guide: guide, strokes: strokes, inkWidth: inkWidth)
            }
            .contentShape(Rectangle())
            .gesture(drawGesture)
            .onAppear { session.setCanvasSize(proxy.size) }
            .onChange(of: proxy.size) { _, newSize in
                session.setCanvasSize(newSize)
            }
            // VoiceOver yoqilgan bo'lsa, barmoq harakati to'g'ridan-to'g'ri tuvalga uzatiladi
            // (Apple chizish tuvallari uchun tavsiya qiladigan usul).
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Strings.Letters.canvasLabel(session.subject.text))
            .accessibilityHint(Strings.Letters.canvasHint)
            .accessibilityAddTraits(.allowsDirectInteraction)
        }
    }

    @MainActor
    private var drawGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                if !session.isStrokeActive {
                    session.beginStroke(at: value.startLocation)
                }
                session.extendStroke(to: value.location)
            }
            .onEnded { _ in
                session.endStroke()
            }
    }

    // MARK: Chizish

    private nonisolated static func draw(
        into context: inout GraphicsContext,
        guide: Path,
        strokes: [[CGPoint]],
        inkWidth: CGFloat
    ) {
        // Ko'rsatma: maketdagi och bej to'ldirish + o'qib bo'ladigan nuqtali kontur.
        context.fill(guide, with: .color(TracePalette.guideFill))
        context.stroke(
            guide,
            with: .color(TracePalette.guideOutline),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0.5, 7])
        )

        if strokes.isEmpty { return }

        // 1) Hamma joyda xira siyoh (harfdan tashqarisi shu holda qoladi).
        for points in strokes {
            drawStroke(&context, points, color: TracePalette.inkOutside, width: inkWidth)
        }
        // 2) Harf ichida to'liq rangdagi siyoh.
        context.drawLayer { layer in
            layer.clip(to: guide)
            for points in strokes {
                drawStroke(&layer, points, color: TracePalette.inkInside, width: inkWidth)
            }
        }
    }

    private nonisolated static func drawStroke(
        _ context: inout GraphicsContext,
        _ points: [CGPoint],
        color: Color,
        width: CGFloat
    ) {
        if points.count == 1 {
            // Bitta bosish: nuqta (masalan `i` nuqtasi).
            let radius = width / 2
            let dot = Path(ellipseIn: CGRect(x: points[0].x - radius, y: points[0].y - radius, width: width, height: width))
            context.fill(dot, with: .color(color))
        } else if points.count > 1 {
            context.stroke(
                smoothedPath(points),
                with: .color(color),
                style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
            )
        }
    }

    /// Nuqtalar orasidan silliq egri chiziq (o'rta nuqtalar orqali kvadratik egrilar).
    nonisolated static func smoothedPath(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        if points.count == 1 { return path }
        if points.count == 2 {
            path.addLine(to: points[1])
            return path
        }
        for i in 1..<(points.count - 1) {
            let mid = CGPoint(
                x: (points[i].x + points[i + 1].x) / 2,
                y: (points[i].y + points[i + 1].y) / 2
            )
            path.addQuadCurve(to: mid, control: points[i])
        }
        path.addLine(to: points[points.count - 1])
        return path
    }
}

#endif

/// Tuval ranglari. Ko'rsatma to'ldirishi maketdan o'lchangan (#E7E2D2).
enum TracePalette {
    static var guideFill: Color { Color.ovHex(0xE7E2D2) }
    /// Nuqtali kontur: oq fonda 3:1 dan yuqori (WCAG 1.4.11: ma'no tashuvchi grafika).
    static var guideOutline: Color { Color.ovTextSecondary.opacity(0.75) }
    static var inkInside: Color { Color.ovPurpleStrong }
    static var inkOutside: Color { Color.ovPurple.opacity(0.35) }
}
