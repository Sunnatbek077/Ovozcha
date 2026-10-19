import SwiftUI

/// OFFLINE / ONLINE yorlig'i. Ma'no uch xil belgi bilan beriladi: rang, ikonka va yozuv,
/// VoiceOver esa "Internetsiz ishlaydi" / "Internet kerak" deb o'qiydi.
struct ModeBadge: View {
    let mode: LearningMode

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            OvIcon(symbol: mode.symbol, size: 14, tint: mode.strongColor)
                .font(.ov(.badge))
            Text(mode.title)
                .ovStyle(.badge, color: mode.strongColor)
        }
        .foregroundStyle(mode.strongColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(mode.brandColor.opacity(Theme.tintOpacity), in: Capsule())
        .fixedSize()
        // `accessibilityElement` Skip (Android) da hali yo'q, faqat Apple platformalarida.
        #if !SKIP
        .accessibilityElement(children: .ignore)
        #endif
        .accessibilityLabel(mode.accessibilityLabel)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        ModeBadge(mode: .offline)
        ModeBadge(mode: .online)
    }
    .padding()
    .background(Color.ovSurface)
    .ovPreviewEnvironment()
}
#endif
