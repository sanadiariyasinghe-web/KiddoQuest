import SwiftUI

nonisolated struct TVTriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

nonisolated struct TVDiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

nonisolated struct TVStarShape: Shape {
    var points = 5
    var innerRatio: CGFloat = 0.45

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        var path = Path()
        for index in 0..<(points * 2) {
            let radius = index.isMultiple(of: 2) ? outer : inner
            let angle = Double(index) * .pi / Double(points) - .pi / 2
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

/// Draws a `TVShapeKind` natively, filled or as an outline.
struct TVShapeView: View {
    let kind: TVShapeKind
    var color: Color = TVTheme.Palette.shapesPurple
    var isFilled: Bool = true

    var body: some View {
        shape
            .aspectRatio(1, contentMode: .fit)
            .accessibilityElement()
            .accessibilityLabel(kind.name)
    }

    @ViewBuilder
    private var shape: some View {
        switch kind {
        case .triangle: styled(TVTriangleShape())
        case .circle: styled(Circle())
        case .square: styled(RoundedRectangle(cornerRadius: 14, style: .continuous))
        case .star: styled(TVStarShape())
        case .diamond: styled(TVDiamondShape())
        }
    }

    @ViewBuilder
    private func styled<S: Shape>(_ shape: S) -> some View {
        if isFilled {
            shape
                .fill(LinearGradient(colors: [color.mix(with: .white, by: 0.25), color], startPoint: .top, endPoint: .bottom))
                .overlay(shape.stroke(Color.white.opacity(0.6), lineWidth: 4))
        } else {
            shape.stroke(color, style: StrokeStyle(lineWidth: 10, lineJoin: .round, dash: [24, 14]))
        }
    }
}

extension TVShapeView {
    /// Bright colours used to vary hunt items so colour is never the clue.
    static let huntPalette: [Color] = [
        TVTheme.Palette.familyCoral,
        TVTheme.Palette.lettersBlue,
        TVTheme.Palette.numbersYellow,
        TVTheme.Palette.animalsGreen,
        TVTheme.Palette.shapesPurple,
        TVTheme.Palette.buddyOrange
    ]

    static func huntColor(at index: Int) -> Color {
        huntPalette[abs(index) % huntPalette.count]
    }
}
