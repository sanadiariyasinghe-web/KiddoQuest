import AppKit
// Usage: swift Tools/make_ios_app_icon.swift KiddoQuest/Assets.xcassets/AppIcon.appiconset/AppIcon.png

// Renders the KiddoQuest iOS app icon from original vector shapes:
// Buddy the owl in front of a glowing moon on a night sky, with a gold star.
let size = 1024
guard let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                          space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { fatalError() }
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor { NSColor(red: r, green: g, blue: b, alpha: a) }
func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ fill: NSColor) {
    fill.setFill(); NSBezierPath(ovalIn: NSRect(x: x, y: y, width: w, height: h)).fill()
}
func polygon(_ points: [(CGFloat, CGFloat)], _ fill: NSColor) {
    let path = NSBezierPath()
    path.move(to: NSPoint(x: points[0].0, y: points[0].1))
    for p in points.dropFirst() { path.line(to: NSPoint(x: p.0, y: p.1)) }
    path.close(); fill.setFill(); path.fill()
}
func star(cx: CGFloat, cy: CGFloat, outer: CGFloat, inner: CGFloat, _ fill: NSColor) {
    var points: [(CGFloat, CGFloat)] = []
    for i in 0..<10 {
        let angle = CGFloat(i) * .pi / 5 + .pi / 2
        let r = i.isMultiple(of: 2) ? outer : inner
        points.append((cx + cos(angle) * r, cy + sin(angle) * r))
    }
    polygon(points, fill)
}

// Night sky
NSGradient(colors: [color(0.28, 0.65, 0.95), color(0.16, 0.20, 0.48)])!
    .draw(in: NSRect(x: 0, y: 0, width: size, height: size), angle: -90)
for (x, y, r) in [(120.0, 880.0, 14.0), (900.0, 880.0, 16.0), (880.0, 150.0, 12.0), (140.0, 190.0, 10.0), (520.0, 960.0, 9.0)] {
    oval(x - r, y - r, r * 2, r * 2, NSColor(white: 1, alpha: 0.85))
}

// Glowing moon
oval(132, 112, 760, 760, NSColor(white: 1, alpha: 0.18))
oval(182, 162, 660, 660, color(1.0, 0.84, 0.30))

// Buddy: ear tufts, body, wings, belly
let brown = color(0.55, 0.36, 0.22), darkBrown = color(0.42, 0.26, 0.15), cream = color(0.98, 0.91, 0.78)
polygon([(360, 700), (330, 820), (440, 730)], darkBrown)
polygon([(664, 700), (694, 820), (584, 730)], darkBrown)
oval(322, 210, 380, 560, brown)
oval(270, 290, 150, 300, darkBrown)
oval(604, 290, 150, 300, darkBrown)
oval(392, 240, 240, 330, cream)

// Big friendly eyes and beak
for x in [362.0, 512.0] {
    oval(x, 540, 150, 150, .white)
    oval(x + 42, 572, 78, 78, color(0.12, 0.12, 0.18))
    oval(x + 78, 620, 24, 24, .white)
}
polygon([(486, 560), (538, 560), (512, 500)], color(1.0, 0.55, 0.25))

// Feet
oval(420, 196, 80, 36, color(1.0, 0.55, 0.25))
oval(524, 196, 80, 36, color(1.0, 0.55, 0.25))

// Gold star
star(cx: 812, cy: 800, outer: 110, inner: 46, color(1.0, 0.84, 0.0))

NSGraphicsContext.restoreGraphicsState()
let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
print("wrote")
