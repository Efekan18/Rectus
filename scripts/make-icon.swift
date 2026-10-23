// Draws the app icon (a perfectly straight spine) and writes Resources/AppIcon.icns.
// Run from the repo root:  swift scripts/make-icon.swift
import AppKit

let canvas: CGFloat = 1024

func drawIcon() -> NSImage {
    NSImage(size: NSSize(width: canvas, height: canvas), flipped: false) { _ in
        // macOS icon grid: the rounded square is 824 pt inside a 1024 canvas.
        let body = NSRect(x: 100, y: 100, width: 824, height: 824)
        let shape = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)

        // Soft drop shadow under the tile.
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
        shadow.shadowOffset = NSSize(width: 0, height: -12)
        shadow.shadowBlurRadius = 28
        shadow.set()
        NSColor.black.setFill()
        shape.fill()
        NSGraphicsContext.restoreGraphicsState()

        // Deep indigo-to-teal tile.
        let tile = NSGradient(colors: [
            NSColor(red: 0.17, green: 0.20, blue: 0.48, alpha: 1),
            NSColor(red: 0.04, green: 0.50, blue: 0.52, alpha: 1),
        ])!
        tile.draw(in: shape, angle: -90)

        // A soft glow behind the spine so it reads as lit from within.
        NSGraphicsContext.saveGraphicsState()
        shape.addClip()
        NSGradient(colors: [NSColor.white.withAlphaComponent(0.20), NSColor.white.withAlphaComponent(0)])!
            .draw(fromCenter: NSPoint(x: 512, y: 512), radius: 0,
                  toCenter: NSPoint(x: 512, y: 512), radius: 380, options: [])
        NSGraphicsContext.restoreGraphicsState()

        // The spine: vertebrae stacked in a perfectly straight column, wider at the
        // bottom like a real spine. Each vertebra is a body with two side wings
        // (the transverse processes), which is what makes it read as a spine.
        let count = 7
        let gap: CGFloat = 16
        var y: CGFloat = 196
        for i in 0..<count {
            let t = CGFloat(i) / CGFloat(count - 1)          // 0 at the bottom, 1 at the top
            let bodyWidth = 190 - 70 * t
            let height = 72 - 18 * t
            let wingWidth = bodyWidth * 1.75
            let wingHeight = height * 0.38

            let body = NSBezierPath(roundedRect: NSRect(x: (canvas - bodyWidth) / 2, y: y, width: bodyWidth, height: height),
                                    xRadius: height * 0.45, yRadius: height * 0.45)
            let wings = NSBezierPath(roundedRect: NSRect(x: (canvas - wingWidth) / 2, y: y + height * 0.40,
                                                         width: wingWidth, height: wingHeight),
                                     xRadius: wingHeight / 2, yRadius: wingHeight / 2)
            let vertebra = NSBezierPath()
            vertebra.append(wings)
            vertebra.append(body)
            vertebra.windingRule = .nonZero

            NSGraphicsContext.saveGraphicsState()
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.32)
            shadow.shadowOffset = NSSize(width: 0, height: -6)
            shadow.shadowBlurRadius = 12
            shadow.set()
            NSColor.white.setFill()
            vertebra.fill()
            NSGraphicsContext.restoreGraphicsState()

            // Light from above: white on top, a cool tint underneath.
            NSGradient(colors: [NSColor(red: 0.78, green: 0.92, blue: 0.94, alpha: 1), .white])!
                .draw(in: vertebra, angle: 90)

            y += height
            if i < count - 1 {
                let discWidth = bodyWidth * 0.7
                let disc = NSRect(x: (canvas - discWidth) / 2, y: y + gap * 0.22, width: discWidth, height: gap * 0.56)
                NSColor(red: 0.50, green: 0.93, blue: 0.85, alpha: 0.9).setFill()
                NSBezierPath(roundedRect: disc, xRadius: gap * 0.28, yRadius: gap * 0.28).fill()
                y += gap
            }
        }
        return true
    }
}

func writePNG(_ image: NSImage, pixels: Int, to url: URL) throws {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: url)
}

let icon = drawIcon()
let iconset = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

// The sizes iconutil expects: 16–512 pt, each at 1x and 2x.
for points in [16, 32, 128, 256, 512] {
    try writePNG(icon, pixels: points, to: iconset.appendingPathComponent("icon_\(points)x\(points).png"))
    try writePNG(icon, pixels: points * 2, to: iconset.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}
try writePNG(icon, pixels: 1024, to: URL(fileURLWithPath: "Resources/AppIcon-preview.png"))

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try iconutil.run()
iconutil.waitUntilExit()
print(iconutil.terminationStatus == 0 ? "✓ Resources/AppIcon.icns" : "iconutil failed")
