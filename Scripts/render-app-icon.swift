// Renders the RiveViewer app icon (1024x1024 PNG): an easing curve with keyframe markers under a magnifier.
// Usage: swift Scripts/render-app-icon.swift <outdir>  (writes <outdir>/icon_1024.png)
import AppKit

let outDir = URL(fileURLWithPath: CommandLine.arguments[1])
let size: CGFloat = 1024

func squircle(inset: CGFloat = 0) -> NSBezierPath {
    let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    return NSBezierPath(roundedRect: rect, xRadius: size * 0.2237, yRadius: size * 0.2237)
}

func gradient(_ top: NSColor, _ bottom: NSColor) -> NSGradient { NSGradient(starting: top, ending: bottom)! }

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor { NSColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a) }

/// The animation curve shared by the concepts: an easing curve rising from lower-left to upper-right.
func curvePath(width: CGFloat) -> NSBezierPath {
    let p = NSBezierPath()
    p.move(to: NSPoint(x: 170, y: 300))
    p.curve(to: NSPoint(x: 860, y: 740), controlPoint1: NSPoint(x: 420, y: 300), controlPoint2: NSPoint(x: 560, y: 760))
    p.lineWidth = width
    p.lineCapStyle = .round
    return p
}

func diamond(at center: NSPoint, radius: CGFloat) -> NSBezierPath {
    let p = NSBezierPath()
    p.move(to: NSPoint(x: center.x, y: center.y + radius))
    p.line(to: NSPoint(x: center.x + radius, y: center.y))
    p.line(to: NSPoint(x: center.x, y: center.y - radius))
    p.line(to: NSPoint(x: center.x - radius, y: center.y))
    p.close()
    return p
}

func withShadow(_ blur: CGFloat, _ alpha: CGFloat, _ draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowBlurRadius = blur
    shadow.shadowOffset = NSSize(width: 0, height: -blur / 2)
    shadow.shadowColor = NSColor.black.withAlphaComponent(alpha)
    shadow.set()
    draw()
    NSGraphicsContext.restoreGraphicsState()
}

func render(name: String, _ body: () -> Void) {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    body()
    image.unlockFocus()
    guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) else { fatalError("encode") }
    try! png.write(to: outDir.appendingPathComponent("\(name).png"))
    print("wrote \(name).png")
}

// indigo gradient, white easing curve with keyframe diamonds, magnifier lower right.
render(name: "icon_1024") {
    let bg = squircle()
    gradient(rgb(104, 72, 255), rgb(38, 24, 120)).draw(in: bg, angle: -90)
    // subtle top sheen
    NSGraphicsContext.saveGraphicsState()
    bg.addClip()
    gradient(NSColor.white.withAlphaComponent(0.18), NSColor.white.withAlphaComponent(0)).draw(in: NSRect(x: 0, y: 512, width: size, height: 512), angle: -90)
    NSGraphicsContext.restoreGraphicsState()
    withShadow(30, 0.35) {
        NSColor.white.setStroke()
        curvePath(width: 54).stroke()
    }
    let accent = rgb(255, 210, 80)
    for (point, r) in [(NSPoint(x: 170, y: 300), 46), (NSPoint(x: 515, y: 520), 46), (NSPoint(x: 860, y: 740), 46)] as [(NSPoint, CGFloat)] {
        withShadow(16, 0.3) { accent.setFill(); diamond(at: point, radius: r).fill() }
        NSColor.white.setStroke()
        let d = diamond(at: point, radius: r); d.lineWidth = 10; d.lineJoinStyle = .round; d.stroke()
    }
    // magnifier
    withShadow(26, 0.4) {
        let ring = NSBezierPath(ovalIn: NSRect(x: 560, y: 150, width: 300, height: 300))
        ring.lineWidth = 56
        NSColor.white.setStroke()
        ring.stroke()
        let handle = NSBezierPath()
        handle.move(to: NSPoint(x: 820, y: 180))
        handle.line(to: NSPoint(x: 905, y: 95))
        handle.lineWidth = 70
        handle.lineCapStyle = .round
        handle.stroke()
    }
    // glass tint inside the ring
    NSColor.white.withAlphaComponent(0.12).setFill()
    NSBezierPath(ovalIn: NSRect(x: 588, y: 178, width: 244, height: 244)).fill()
}

