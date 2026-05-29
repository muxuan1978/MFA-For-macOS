import Cocoa
import CoreGraphics
import Foundation

// MARK: - Color Helpers

func cgColor(r: Int, g: Int, b: Int, a: CGFloat = 1.0) -> CGColor {
    CGColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: a)
}

// MARK: - Draw Icon

func drawIcon(ctx: CGContext, size: CGFloat) {
    let scale = size / 1024.0
    ctx.saveGState()
    ctx.scaleBy(x: scale, y: scale)

    let bgRect = CGRect(x: 0, y: 0, width: 1024, height: 1024)
    let cornerRadius: CGFloat = 220

    // Clip to rounded rect
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(bgPath)
    ctx.clip()

    // Background gradient: deep indigo -> blue
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    let bgColors = [
        cgColor(r: 20, g: 20, b: 60),
        cgColor(r: 35, g: 35, b: 100),
        cgColor(r: 50, g: 50, b: 140),
    ] as CFArray
    if let bg = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 0.5, 1.0]) {
        ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 1024, y: 1024), options: [])
    }

    // Subtle radial glow top-center
    let glowColors = [
        cgColor(r: 100, g: 100, b: 255, a: 0.15),
        cgColor(r: 100, g: 100, b: 255, a: 0.0),
    ] as CFArray
    if let glow = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(glow, startCenter: CGPoint(x: 512, y: 300), startRadius: 0, endCenter: CGPoint(x: 512, y: 300), endRadius: 450, options: [])
    }

    // Shield shape (larger)
    let shieldX: CGFloat = 212
    let shieldY: CGFloat = 110
    let shieldW: CGFloat = 600
    let shieldH: CGFloat = 700

    let shieldPath = CGMutablePath()
    let r: CGFloat = 50
    shieldPath.move(to: CGPoint(x: shieldX + r, y: shieldY))
    shieldPath.addLine(to: CGPoint(x: shieldX + shieldW - r, y: shieldY))
    shieldPath.addQuadCurve(to: CGPoint(x: shieldX + shieldW, y: shieldY + r), control: CGPoint(x: shieldX + shieldW, y: shieldY))
    shieldPath.addLine(to: CGPoint(x: shieldX + shieldW, y: shieldY + shieldH * 0.55))
    shieldPath.addQuadCurve(to: CGPoint(x: shieldX + shieldW * 0.5, y: shieldY + shieldH + 30), control: CGPoint(x: shieldX + shieldW + 15, y: shieldY + shieldH * 0.82))
    shieldPath.addQuadCurve(to: CGPoint(x: shieldX, y: shieldY + shieldH * 0.55), control: CGPoint(x: shieldX - 15, y: shieldY + shieldH * 0.82))
    shieldPath.addLine(to: CGPoint(x: shieldX, y: shieldY + r))
    shieldPath.addQuadCurve(to: CGPoint(x: shieldX + r, y: shieldY), control: CGPoint(x: shieldX, y: shieldY))
    shieldPath.closeSubpath()

    // Shield fill gradient
    ctx.saveGState()
    ctx.addPath(shieldPath)
    ctx.clip()

    let shieldColors = [
        cgColor(r: 66, g: 133, b: 244),
        cgColor(r: 50, g: 110, b: 230),
        cgColor(r: 30, g: 80, b: 200),
    ] as CFArray
    if let sg = CGGradient(colorsSpace: colorSpace, colors: shieldColors, locations: [0.0, 0.5, 1.0]) {
        ctx.drawLinearGradient(sg, start: CGPoint(x: 512, y: shieldY), end: CGPoint(x: 512, y: shieldY + shieldH), options: [])
    }

    // Glass reflection on shield top half
    let reflColors = [
        cgColor(r: 255, g: 255, b: 255, a: 0.12),
        cgColor(r: 255, g: 255, b: 255, a: 0.0),
    ] as CFArray
    if let rg = CGGradient(colorsSpace: colorSpace, colors: reflColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(rg, start: CGPoint(x: 512, y: shieldY), end: CGPoint(x: 512, y: shieldY + shieldH * 0.45), options: [])
    }
    ctx.restoreGState()

    // Shield border
    ctx.addPath(shieldPath)
    ctx.setStrokeColor(cgColor(r: 120, g: 180, b: 255, a: 0.4))
    ctx.setLineWidth(4)
    ctx.strokePath()

    // Lock icon (centered in shield upper area)
    let lockCX: CGFloat = 512
    let lockCY: CGFloat = shieldY + shieldH * 0.30

    // Lock body (rounded rect) — larger
    let lockW: CGFloat = 110
    let lockH: CGFloat = 85
    let lockBody = CGPath(roundedRect: CGRect(x: lockCX - lockW/2, y: lockCY - lockH/2 + 22, width: lockW, height: lockH), cornerWidth: 14, cornerHeight: 14, transform: nil)
    ctx.addPath(lockBody)
    ctx.setFillColor(cgColor(r: 255, g: 255, b: 255, a: 0.9))
    ctx.fillPath()

    // Lock shackle (U shape) — larger
    let shackleW: CGFloat = 66
    let shackleH: CGFloat = 52
    let shackleRect = CGRect(x: lockCX - shackleW/2, y: lockCY - shackleH + 14, width: shackleW, height: shackleH)
    ctx.addEllipse(in: shackleRect)
    ctx.setFillColor(cgColor(r: 20, g: 30, b: 80, a: 0.0))
    ctx.setStrokeColor(cgColor(r: 255, g: 255, b: 255, a: 0.9))
    ctx.setLineWidth(14)
    ctx.strokePath()

    // Cut out inner of shackle — larger
    let innerShackleW: CGFloat = 38
    let innerShackleH: CGFloat = 34
    let innerShackleRect = CGRect(x: lockCX - innerShackleW/2, y: lockCY - innerShackleH + 16, width: innerShackleW, height: innerShackleH)
    ctx.addEllipse(in: innerShackleRect)
    ctx.setFillColor(cgColor(r: 50, g: 110, b: 230))
    ctx.fillPath()

    // Lock keyhole — larger
    let keyholeY = lockCY + 22
    ctx.addEllipse(in: CGRect(x: lockCX - 10, y: keyholeY - 16, width: 20, height: 20))
    ctx.setFillColor(cgColor(r: 30, g: 80, b: 200))
    ctx.fillPath()

    // TOTP digits in lower shield area
    let digitY = shieldY + shieldH * 0.62
    let digits = "648"
    let digitSpacing: CGFloat = 72
    let startX = lockCX - (CGFloat(digits.count - 1) * digitSpacing) / 2

    // Digit background pills
    ctx.setFillColor(cgColor(r: 255, g: 255, b: 255, a: 0.15))
    for i in 0..<digits.count {
        let pillX = startX + CGFloat(i) * digitSpacing - 30
        let pillRect = CGRect(x: pillX, y: digitY - 30, width: 60, height: 50)
        let pillPath = CGPath(roundedRect: pillRect, cornerWidth: 10, cornerHeight: 10, transform: nil)
        ctx.addPath(pillPath)
        ctx.fillPath()
    }

    // Draw digits using NSAttributedString
    let font = NSFont.monospacedSystemFont(ofSize: 36, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(white: 1.0, alpha: 0.95),
    ]

    for (i, char) in digits.enumerated() {
        let charStr = String(char)
        let charSize = charStr.size(withAttributes: attrs)
        let charX = startX + CGFloat(i) * digitSpacing

        ctx.saveGState()
        let drawRect = CGRect(
            x: charX - charSize.width / 2,
            y: 1024 - digitY - charSize.height / 2 - 2,
            width: charSize.width,
            height: charSize.height
        )
        let attrStr = NSAttributedString(string: charStr, attributes: attrs)
        attrStr.draw(with: drawRect, options: [.usesLineFragmentOrigin], context: nil)
        ctx.restoreGState()
    }

    // Outer border
    ctx.addPath(CGPath(roundedRect: bgRect.insetBy(dx: 1, dy: 1), cornerWidth: cornerRadius - 1, cornerHeight: cornerRadius - 1, transform: nil))
    ctx.setStrokeColor(cgColor(r: 80, g: 80, b: 130, a: 0.25))
    ctx.setLineWidth(2)
    ctx.strokePath()

    ctx.restoreGState()
}

// MARK: - PNG Export

func createBitmapContext(size: Int) -> CGContext {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 4 * size, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
    ctx.translateBy(x: 0, y: CGFloat(size))
    ctx.scaleBy(x: 1, y: -1)
    return ctx
}

func savePNG(image: CGImage, url: URL) {
    let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

// MARK: - Generate

let iconSizes: [(name: String, size: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

let outputDir = URL(fileURLWithPath: "/opt/develop/tools/MFA/Resources/Assets.xcassets/AppIcon.appiconset/")

for icon in iconSizes {
    let ctx = createBitmapContext(size: icon.size)
    drawIcon(ctx: ctx, size: CGFloat(icon.size))
    let image = ctx.makeImage()!
    savePNG(image: image, url: outputDir.appendingPathComponent("\(icon.name).png"))
    print("Generated \(icon.name).png (\(icon.size)x\(icon.size))")
}

print("Done!")
