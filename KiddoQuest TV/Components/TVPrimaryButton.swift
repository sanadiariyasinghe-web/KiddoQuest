import SwiftUI

/// Large pill-shaped action button, e.g. PLAY on the Home screen.
struct TVPrimaryButton: View {
    let title: String
    var subtitle: String?
    var systemImage: String?
    var tint: Color = TVTheme.Palette.numbersYellow
    var prominence: TVButtonProminence = .filled
    var minWidth: CGFloat = 560
    let action: () -> Void

    @Environment(TVSoundService.self) private var sound: TVSoundService?

    var body: some View {
        Button {
            sound?.play(.select)
            action()
        } label: {
            HStack(spacing: 28) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 46, weight: .bold))
                        .frame(width: 64)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(TVTheme.Typography.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if let subtitle {
                        Text(subtitle)
                            .font(TVTheme.Typography.caption)
                            .opacity(0.85)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 44)
            .padding(.vertical, subtitle == nil ? 30 : 22)
            .frame(minWidth: minWidth, alignment: .leading)
            // Hug content (never stretch across a container) but keep a minimum width.
            .fixedSize(horizontal: true, vertical: false)
        }
        .tvCardButtonStyle(tint: tint, prominence: prominence, cornerRadius: TVTheme.Metrics.buttonCorner, focusScale: 1.06)
        .accessibilityLabel(subtitle.map { "\(title), \($0)" } ?? title)
    }
}
