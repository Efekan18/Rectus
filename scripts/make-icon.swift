// Draws the app icon and writes Resources/AppIcon.icns.
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

        // Teal-to-blue gradient tile.
        let gradient = NSGradient(colors: [
            NSColor(red: 0.16, green: 0.78, blue: 0.70, alpha: 1),
            NSColor(red: 0.12, green: 0.40, blue: 0.85, alpha: 1),
        ])!
        gradient.draw(in: shape, angle: -90)

        // A thin vertical "spine" line behind the figure: the upright axis.
        NSColor.white.withAlphaComponent(0.18).setFill()
        NSBezierPath(roundedRect: NSRect(x: 502, y: 190, width: 20, height: 644), xRadius: 10, yRadius: 10).fill()

        // The standing figure, white.
        let config = NSImage.SymbolConfiguration(pointSize: 520, weight: .semibold)
            .applying(.init(paletteColors: [.white]))
        if let figure = NSImage(systemSymbolName: "figure.stand", accessibilityDescription: nil)?
            .withSymbolConfiguration(config) {
            let size = figure.size
            figure.draw(in: NSRect(x: (canvas - size.width) / 2, y: (canvas - size.height) / 2,
                                   width: size.width, height: size.height))
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
