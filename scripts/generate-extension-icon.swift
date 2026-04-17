#!/usr/bin/swift

import Cocoa

let size = 128

func drawIcon(size: Int) -> Data? {
    let s = CGFloat(size)
    guard let bitmap = NSBitmapImageRep(
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
    ) else { return nil }

    NSGraphicsContext.saveGraphicsState()
    guard let gc = NSGraphicsContext(bitmapImageRep: bitmap) else {
        NSGraphicsContext.restoreGraphicsState()
        return nil
    }
    NSGraphicsContext.current = gc
    let ctx = gc.cgContext

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let cornerRadius = s * 0.22
    let rect = CGRect(x: 0, y: 0, width: s, height: s)
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil))
    ctx.clip()

    let bgColors = [
        CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
        CGColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0),
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: 0, y: 0), options: [])
    }

    ctx.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.06))
    ctx.setLineWidth(s * 0.008)
    ctx.addPath(CGPath(roundedRect: rect.insetBy(dx: s * 0.004, dy: s * 0.004),
                        cornerWidth: cornerRadius - s * 0.004,
                        cornerHeight: cornerRadius - s * 0.004,
                        transform: nil))
    ctx.strokePath()

    let fontSize = s * 0.80
    let font = NSFont.systemFont(ofSize: fontSize, weight: .heavy)
    let attrString = NSAttributedString(string: "C", attributes: [.font: font])
    let line = CTLineCreateWithAttributedString(attrString)
    let runs = CTLineGetGlyphRuns(line) as! [CTRun]
    let rawPath = CGMutablePath()

    for run in runs {
        let runFont = (CTRunGetAttributes(run) as Dictionary)[kCTFontAttributeName] as! CTFont
        let glyphCount = CTRunGetGlyphCount(run)
        for i in 0..<glyphCount {
            let range = CFRangeMake(i, 1)
            var glyph = CGGlyph()
            var position = CGPoint()
            CTRunGetGlyphs(run, range, &glyph)
            CTRunGetPositions(run, range, &position)
            if let glyphPath = CTFontCreatePathForGlyph(runFont, glyph, nil) {
                rawPath.addPath(glyphPath, transform: CGAffineTransform(translationX: position.x, y: 0))
            }
        }
    }

    let glyphBounds = rawPath.boundingBoxOfPath
    let translateX = (s - glyphBounds.width) / 2 - glyphBounds.minX
    let translateY = (s - glyphBounds.height) / 2 - glyphBounds.minY

    let centeredPath = CGMutablePath()
    centeredPath.addPath(rawPath, transform: CGAffineTransform(translationX: translateX, y: translateY))

    ctx.saveGState()
    ctx.addPath(centeredPath)
    ctx.clip()

    let claudeColors = [
        CGColor(red: 0.839, green: 0.439, blue: 0.349, alpha: 1.0),
        CGColor(red: 0.749, green: 0.357, blue: 0.271, alpha: 1.0),
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: claudeColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(gradient, start: CGPoint(x: s * 0.5, y: s), end: CGPoint(x: s * 0.5, y: 0), options: [])
    }
    ctx.restoreGState()

    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])
}

if let data = drawIcon(size: size) {
    try! data.write(to: URL(fileURLWithPath: "/Users/diego/dev/canto/canto-vscode/media/icon.png"))
    print("Generated media/icon.png (\(size)x\(size))")
}
