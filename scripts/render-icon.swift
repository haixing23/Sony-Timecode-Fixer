import AppKit
import Foundation

func renderSVG(_ svgURL: URL, size: Int, outputURL: URL) throws {
    guard let image = NSImage(contentsOf: svgURL) else {
        throw NSError(domain: "RenderIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not load SVG: \(svgURL.path)"])
    }

    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "RenderIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create bitmap context"])
    }

    guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
        throw NSError(domain: "RenderIcon", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not create graphics context"])
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size), from: .zero, operation: .sourceOver, fraction: 1)
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "RenderIcon", code: 4, userInfo: [NSLocalizedDescriptionKey: "Could not encode PNG"])
    }
    try data.write(to: outputURL)
}

let arguments = Array(CommandLine.arguments.dropFirst())
let iconsetURL = URL(fileURLWithPath: arguments.first ?? ".build/AppIcon.iconset")
let svgURL = URL(fileURLWithPath: arguments.dropFirst().first ?? "Assets/sony-timecode-fixer-icon.svg")

try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let entries: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

for entry in entries {
    try renderSVG(svgURL, size: entry.0, outputURL: iconsetURL.appendingPathComponent(entry.1))
}
