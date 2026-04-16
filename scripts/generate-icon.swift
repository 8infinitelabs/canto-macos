#!/usr/bin/swift

import Cocoa

let sizes: [(Int, String)] = [
    (1024, "icon_512x512@2x"),
    (512, "icon_512x512"),
    (512, "icon_256x256@2x"),
    (256, "icon_256x256"),
    (256, "icon_128x128@2x"),
    (128, "icon_128x128"),
    (64, "icon_32x32@2x"),
    (32, "icon_32x32"),
    (32, "icon_16x16@2x"),
    (16, "icon_16x16"),
]

func drawIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let colorSpace = CGColorSpaceCreateDeviceRGB()

    // Rounded rect clip
    let cornerRadius = s * 0.22
    let rect = CGRect(x: 0, y: 0, width: s, height: s)
    let bgPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(bgPath)
    ctx.clip()

    // Gradient background: violet → coral
    let bgColors = [
        CGColor(red: 0.545, green: 0.361, blue: 0.965, alpha: 1.0),
        CGColor(red: 0.878, green: 0.424, blue: 0.329, alpha: 1.0),
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(gradient,
            start: CGPoint(x: 0, y: s),
            end: CGPoint(x: s, y: 0),
            options: [])
    }

    // Build text path for "C"
    let fontSize = s * 0.55
    let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
    let attrString = NSAttributedString(string: "C", attributes: [.font: font])
    let textSize = attrString.size()
    let textX = (s - textSize.width) / 2
    let textY = (s - textSize.height) / 2

    let line = CTLineCreateWithAttributedString(attrString)
    let runs = CTLineGetGlyphRuns(line) as! [CTRun]
    let textPath = CGMutablePath()

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
                let transform = CGAffineTransform(translationX: textX + position.x, y: textY)
                textPath.addPath(glyphPath, transform: transform)
            }
        }
    }

    // Shadow behind letter
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.015), blur: s * 0.03,
                  color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.3))
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.addPath(textPath)
    ctx.fillPath()
    ctx.restoreGState()

    // Inner gradient on the C: white top → semi-transparent white bottom (relief effect)
    ctx.saveGState()
    ctx.addPath(textPath)
    ctx.clip()

    let innerColors = [
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.95),
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.55),
    ] as CFArray
    if let innerGradient = CGGradient(colorsSpace: colorSpace, colors: innerColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(innerGradient,
            start: CGPoint(x: s * 0.5, y: textY + textSize.height),
            end: CGPoint(x: s * 0.5, y: textY),
            options: [])
    }
    ctx.restoreGState()

    image.unlockFocus()
    return image
}

let outputDir = "/Users/diego/dev/canto/Canto/Assets.xcassets/AppIcon.appiconset"

for (size, name) in sizes {
    let image = drawIcon(size: size)
    let filename = "\(outputDir)/\(name).png"
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:])
    else { continue }
    try! png.write(to: URL(fileURLWithPath: filename))
    print("Generated \(name).png (\(size)x\(size))")
}
print("Done!")
