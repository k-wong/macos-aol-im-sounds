import AppKit
import Foundation

struct IconVariant {
    let filename: String
    let pixels: Int
}

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    fputs("usage: render_app_icon.swift <input-svg> <output-iconset-dir>\n", stderr)
    exit(1)
}

let inputURL = URL(fileURLWithPath: arguments[1])
let outputURL = URL(fileURLWithPath: arguments[2], isDirectory: true)

let variants: [IconVariant] = [
    .init(filename: "icon_16x16.png", pixels: 16),
    .init(filename: "icon_16x16@2x.png", pixels: 32),
    .init(filename: "icon_32x32.png", pixels: 32),
    .init(filename: "icon_32x32@2x.png", pixels: 64),
    .init(filename: "icon_128x128.png", pixels: 128),
    .init(filename: "icon_128x128@2x.png", pixels: 256),
    .init(filename: "icon_256x256.png", pixels: 256),
    .init(filename: "icon_256x256@2x.png", pixels: 512),
    .init(filename: "icon_512x512.png", pixels: 512),
    .init(filename: "icon_512x512@2x.png", pixels: 1024),
]

guard let image = NSImage(contentsOf: inputURL) else {
    fputs("failed to load image at \(inputURL.path)\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

for variant in variants {
    let size = NSSize(width: variant.pixels, height: variant.pixels)
    image.size = size

    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: variant.pixels,
            pixelsHigh: variant.pixels,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
    else {
        fputs("failed to create bitmap for \(variant.filename)\n", stderr)
        exit(1)
    }

    bitmap.size = size

    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fputs("failed to create graphics context for \(variant.filename)\n", stderr)
        exit(1)
    }

    NSGraphicsContext.current = context
    NSColor.clear.setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
    image.draw(
        in: NSRect(origin: .zero, size: size),
        from: .zero,
        operation: .copy,
        fraction: 1
    )
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        fputs("failed to encode PNG for \(variant.filename)\n", stderr)
        exit(1)
    }

    try pngData.write(to: outputURL.appendingPathComponent(variant.filename))
}
