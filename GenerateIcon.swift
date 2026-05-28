import Cocoa
import Foundation

// MARK: - Color Helpers

func cgColor(r: Int, g: Int, b: Int, a: CGFloat = 1.0) -> CGColor {
    CGColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: a)
}

// MARK: - Drawing Functions

func drawShieldIcon(ctx: CGContext, size: CGFloat) {
    let scale = size / 1024.0
    ctx.saveGState()
    ctx.scaleBy(x: scale, y: scale)

    // Background: rounded rect with gradient
    let bgRect = CGRect(x: 0, y: 0, width: 1024, height: 1024)
    let cornerRadius: CGFloat = 224
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(bgPath)
    ctx.clip()

    // Gradient background (deep blue-purple)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradientColors = [
        cgColor(r: 30, g: 30, b: 80),
        cgColor(r: 55, g: 40, b: 140),
        cgColor(r: 75, g: 50, b: 180),
    ] as CFArray
    let gradientLocations: [CGFloat] = [0.0, 0.5, 1.0]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: gradientLocations) {
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 1024, y: 1024), options: [])
    }

    // Subtle inner glow circle
    let glowColors = [
        cgColor(r: 100, g: 80, b: 220, a: 0.3),
        cgColor(r: 100, g: 80, b: 220, a: 0.0),
    ] as CFArray
    if let glowGradient = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(glowGradient,
                               startCenter: CGPoint(x: 512, y: 400),
                               startRadius: 0,
                               endCenter: CGPoint(x: 512, y: 400),
                               endRadius: 500,
                               options: [])
    }

    // Shield shape
    let shieldWidth: CGFloat = 460
    let shieldHeight: CGFloat = 520
    let shieldX: CGFloat = (1024 - shieldWidth) / 2
    let shieldY: CGFloat = 200

    ctx.saveGState()

    let shieldPath = CGMutablePath()
    // Top-left corner of shield
    shieldPath.move(to: CGPoint(x: shieldX + 40, y: shieldY))
    // Top edge
    shieldPath.addLine(to: CGPoint(x: shieldX + shieldWidth - 40, y: shieldY))
    // Top-right curve
    shieldPath.addQuadCurve(to: CGPoint(x: shieldX + shieldWidth, y: shieldY + 40),
                            control: CGPoint(x: shieldX + shieldWidth, y: shieldY))
    // Right edge
    shieldPath.addLine(to: CGPoint(x: shieldX + shieldWidth, y: shieldY + shieldHeight * 0.55))
    // Bottom-right curve to point
    shieldPath.addQuadCurve(to: CGPoint(x: shieldX + shieldWidth * 0.5, y: shieldY + shieldHeight + 20),
                            control: CGPoint(x: shieldX + shieldWidth + 10, y: shieldY + shieldHeight * 0.85))
    // Bottom-left curve to point
    shieldPath.addQuadCurve(to: CGPoint(x: shieldX, y: shieldY + shieldHeight * 0.55),
                            control: CGPoint(x: shieldX - 10, y: shieldY + shieldHeight * 0.85))
    // Left edge
    shieldPath.addLine(to: CGPoint(x: shieldX, y: shieldY + 40))
    // Top-left curve
    shieldPath.addQuadCurve(to: CGPoint(x: shieldX + 40, y: shieldY),
                            control: CGPoint(x: shieldX, y: shieldY))
    shieldPath.closeSubpath()

    // Shield fill with gradient
    let shieldColors = [
        cgColor(r: 80, g: 160, b: 255),
        cgColor(r: 60, g: 120, b: 240),
        cgColor(r: 40, g: 80, b: 200),
    ] as CFArray
    if let shieldGradient = CGGradient(colorsSpace: colorSpace, colors: shieldColors, locations: [0.0, 0.5, 1.0]) {
        ctx.addPath(shieldPath)
        ctx.clip()
        ctx.drawLinearGradient(shieldGradient, start: CGPoint(x: 512, y: shieldY), end: CGPoint(x: 512, y: shieldY + shieldHeight), options: [])
    }

    // Shield border highlight
    ctx.restoreGState()
    ctx.addPath(shieldPath)
    ctx.setStrokeColor(cgColor(r: 140, g: 200, b: 255, a: 0.6))
    ctx.setLineWidth(6)
    ctx.strokePath()

    // Inner shield highlight (lighter inner border)
    ctx.saveGState()
    ctx.addPath(shieldPath)
    ctx.clip()

    // Shield glass reflection
    let reflColors = [
        cgColor(r: 255, g: 255, b: 255, a: 0.15),
        cgColor(r: 255, g: 255, b: 255, a: 0.0),
    ] as CFArray
    if let reflGradient = CGGradient(colorsSpace: colorSpace, colors: reflColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(reflGradient,
                               start: CGPoint(x: 512, y: shieldY),
                               end: CGPoint(x: 512, y: shieldY + shieldHeight * 0.5),
                               options: [])
    }

    // Keyhole / Lock icon in center of shield
    let lockCenterY = shieldY + shieldHeight * 0.38
    let lockCenterX: CGFloat = 512

    // Keyhole circle (top)
    let keyholeRadius: CGFloat = 65
    ctx.setFillColor(cgColor(r: 20, g: 30, b: 70, a: 0.7))
    let keyholeCircle = CGPath(ellipseIn: CGRect(x: lockCenterX - keyholeRadius,
                                                   y: lockCenterY - keyholeRadius,
                                                   width: keyholeRadius * 2,
                                                   height: keyholeRadius * 2), transform: nil)
    ctx.addPath(keyholeCircle)
    ctx.fillPath()

    // Keyhole slot (bottom triangle)
    let slotPath = CGMutablePath()
    let slotTopWidth: CGFloat = 30
    let slotBottomWidth: CGFloat = 55
    let slotHeight: CGFloat = 80
    slotPath.move(to: CGPoint(x: lockCenterX - slotTopWidth, y: lockCenterY + 10))
    slotPath.addLine(to: CGPoint(x: lockCenterX - slotBottomWidth, y: lockCenterY + slotHeight))
    slotPath.addLine(to: CGPoint(x: lockCenterX + slotBottomWidth, y: lockCenterY + slotHeight))
    slotPath.addLine(to: CGPoint(x: lockCenterX + slotTopWidth, y: lockCenterY + 10))
    slotPath.closeSubpath()
    ctx.addPath(slotPath)
    ctx.fillPath()

    // "6" digits display at bottom of shield
    let digitY = shieldY + shieldHeight * 0.65
    let digitSpacing: CGFloat = 56
    let digits = "648"
    let startDigitX = lockCenterX - (CGFloat(digits.count - 1) * digitSpacing) / 2

    // Digit background boxes
    ctx.setFillColor(cgColor(r: 20, g: 30, b: 70, a: 0.5))
    for i in 0..<digits.count {
        let boxX = startDigitX + CGFloat(i) * digitSpacing - 32
        let boxRect = CGRect(x: boxX, y: digitY - 32, width: 64, height: 56)
        let boxPath = CGPath(roundedRect: boxRect, cornerWidth: 10, cornerHeight: 10, transform: nil)
        ctx.addPath(boxPath)
        ctx.fillPath()
    }

    // Draw digits using string drawing instead of showText
    let font = NSFont.monospacedSystemFont(ofSize: 40, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(cgColor: cgColor(r: 180, g: 220, b: 255, a: 0.9))!,
    ]

    for (i, char) in digits.enumerated() {
        let charStr = String(char)
        let charX = startDigitX + CGFloat(i) * digitSpacing
        let strSize = charStr.size(withAttributes: attrs)
        let drawX = charX - strSize.width / 2
        let drawY = digitY - strSize.height / 2

        // Flip for Cocoa coordinate system
        ctx.saveGState()
        let strRect = CGRect(x: drawX, y: 1024 - drawY - strSize.height, width: strSize.width, height: strSize.height)
        let nsStr = NSAttributedString(string: charStr, attributes: attrs)
        nsStr.draw(with: strRect, options: [.usesLineFragmentOrigin], context: nil)
        ctx.restoreGState()
    }

    // Restore from shield clip
    ctx.restoreGState()

    // Subtle border on the overall icon
    ctx.addPath(CGPath(roundedRect: bgRect.insetBy(dx: 2, dy: 2),
                       cornerWidth: cornerRadius - 2,
                       cornerHeight: cornerRadius - 2,
                       transform: nil))
    ctx.setStrokeColor(cgColor(r: 100, g: 100, b: 150, a: 0.3))
    ctx.setLineWidth(4)
    ctx.strokePath()

    ctx.restoreGState()
}

// MARK: - PNG Export

func createBitmapContext(size: Int) -> CGContext {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * size
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

    let context = CGContext(data: nil,
                            width: size,
                            height: size,
                            bitsPerComponent: 8,
                            bytesPerRow: bytesPerRow,
                            space: colorSpace,
                            bitmapInfo: bitmapInfo.rawValue)!
    // Flip Y so (0,0) is top-left
    context.translateBy(x: 0, y: CGFloat(size))
    context.scaleBy(x: 1, y: -1)
    return context
}

func savePNG(image: CGImage, url: URL) {
    let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    CGImageDestinationFinalize(destination)
}

// MARK: - Generate All Sizes

let iconSizes: [(name: String, size: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

let outputDir = URL(fileURLWithPath: "/opt/develop/tools/MFA/Resources/Assets.xcassets/AppIcon.appiconset/")

for icon in iconSizes {
    let ctx = createBitmapContext(size: icon.size)
    drawShieldIcon(ctx: ctx, size: CGFloat(icon.size))
    let image = ctx.makeImage()!
    let url = outputDir.appendingPathComponent("\(icon.name).png")
    savePNG(image: image, url: url)
    print("Generated \(icon.name).png (\(icon.size)x\(icon.size))")
}

// Update Contents.json with filenames
let contentsJSON = """
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

try contentsJSON.write(to: outputDir.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("Updated Contents.json")
print("Done! All icons generated.")
