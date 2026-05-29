import Cocoa
import CoreGraphics
import Foundation

func cgColor(r: Int, g: Int, b: Int, a: CGFloat = 1.0) -> CGColor {
    CGColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: a)
}

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

let colorSpace = CGColorSpaceCreateDeviceRGB()

func drawBackground(ctx: CGContext, colors: [CGColor], locations: [CGFloat] = [0.0, 0.5, 1.0]) {
    let bgRect = CGRect(x: 0, y: 0, width: 1024, height: 1024)
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: 220, cornerHeight: 220, transform: nil)
    ctx.addPath(bgPath)
    ctx.clip()
    if let bg = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) {
        ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 1024, y: 1024), options: [])
    }
}

func makeShieldPath(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, r: CGFloat = 60) -> CGMutablePath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: x + r, y: y))
    path.addLine(to: CGPoint(x: x + w - r, y: y))
    path.addQuadCurve(to: CGPoint(x: x + w, y: y + r), control: CGPoint(x: x + w, y: y))
    path.addLine(to: CGPoint(x: x + w, y: y + h * 0.55))
    path.addQuadCurve(to: CGPoint(x: x + w * 0.5, y: y + h + 20), control: CGPoint(x: x + w + 10, y: y + h * 0.82))
    path.addQuadCurve(to: CGPoint(x: x, y: y + h * 0.55), control: CGPoint(x: x - 10, y: y + h * 0.82))
    path.addLine(to: CGPoint(x: x, y: y + r))
    path.addQuadCurve(to: CGPoint(x: x + r, y: y), control: CGPoint(x: x, y: y))
    path.closeSubpath()
    return path
}

// ============================================================
// App Icon: Green shield + lock + digits
// ============================================================
func drawAppIcon(ctx: CGContext, size: CGFloat) {
    let scale = size / 1024.0
    ctx.saveGState()
    ctx.scaleBy(x: scale, y: scale)
    drawBackground(ctx: ctx, colors: [
        cgColor(r: 10, g: 30, b: 20),
        cgColor(r: 15, g: 55, b: 35),
        cgColor(r: 20, g: 80, b: 50),
    ])

    // Shield
    let sx: CGFloat = 120, sy: CGFloat = 80, sw: CGFloat = 784, sh: CGFloat = 860
    let shieldPath = makeShieldPath(x: sx, y: sy, w: sw, h: sh)

    ctx.saveGState()
    ctx.addPath(shieldPath)
    ctx.clip()
    if let sg = CGGradient(colorsSpace: colorSpace, colors: [
        cgColor(r: 34, g: 197, b: 94),
        cgColor(r: 22, g: 163, b: 74),
        cgColor(r: 16, g: 130, b: 58),
    ] as CFArray, locations: [0.0, 0.5, 1.0]) {
        ctx.drawLinearGradient(sg, start: CGPoint(x: 512, y: sy), end: CGPoint(x: 512, y: sy + sh), options: [])
    }
    if let rg = CGGradient(colorsSpace: colorSpace, colors: [
        cgColor(r: 255, g: 255, b: 255, a: 0.12),
        cgColor(r: 255, g: 255, b: 255, a: 0.0),
    ] as CFArray, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(rg, start: CGPoint(x: 512, y: sy), end: CGPoint(x: 512, y: sy + sh * 0.4), options: [])
    }
    ctx.restoreGState()

    ctx.addPath(shieldPath)
    ctx.setStrokeColor(cgColor(r: 100, g: 230, b: 150, a: 0.4))
    ctx.setLineWidth(4)
    ctx.strokePath()

    // Lock
    let lockCX: CGFloat = 512, lockCY: CGFloat = sy + sh * 0.27

    ctx.addEllipse(in: CGRect(x: lockCX - 70, y: lockCY - 60, width: 140, height: 110))
    ctx.setFillColor(cgColor(r: 16, g: 130, b: 58, a: 0))
    ctx.setStrokeColor(cgColor(r: 255, g: 255, b: 255, a: 0.92))
    ctx.setLineWidth(22)
    ctx.strokePath()

    ctx.addEllipse(in: CGRect(x: lockCX - 44, y: lockCY - 38, width: 88, height: 72))
    ctx.setFillColor(cgColor(r: 16, g: 130, b: 58))
    ctx.fillPath()

    ctx.addPath(CGPath(roundedRect: CGRect(x: lockCX - 110, y: lockCY + 20, width: 220, height: 160), cornerWidth: 22, cornerHeight: 22, transform: nil))
    ctx.setFillColor(cgColor(r: 255, g: 255, b: 255, a: 0.92))
    ctx.fillPath()

    ctx.addEllipse(in: CGRect(x: lockCX - 20, y: lockCY + 50, width: 40, height: 40))
    ctx.setFillColor(cgColor(r: 16, g: 100, b: 48))
    ctx.fillPath()

    // Digits
    let digitY: CGFloat = sy + sh * 0.68
    let font = NSFont.monospacedSystemFont(ofSize: 72, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor(white: 1.0, alpha: 0.95)]
    let digits = "648 029"
    let spacing: CGFloat = 70
    let startX: CGFloat = 512 - 2.5 * spacing

    ctx.setFillColor(cgColor(r: 255, g: 255, b: 255, a: 0.15))
    for i in 0..<6 {
        let pillRect = CGRect(x: startX + CGFloat(i) * spacing - 30, y: digitY - 36, width: 60, height: 56)
        ctx.addPath(CGPath(roundedRect: pillRect, cornerWidth: 10, cornerHeight: 10, transform: nil))
        ctx.fillPath()
    }

    let cleanDigits = Array(digits.filter { $0 != " " })
    for (i, char) in cleanDigits.enumerated() {
        let charStr = String(char)
        let charSize = charStr.size(withAttributes: attrs)
        let cx = startX + CGFloat(i) * spacing
        ctx.saveGState()
        let drawRect = CGRect(x: cx - charSize.width / 2, y: 1024 - digitY - charSize.height / 2, width: charSize.width, height: charSize.height)
        let attrStr = NSAttributedString(string: charStr, attributes: attrs)
        attrStr.draw(with: drawRect, options: [.usesLineFragmentOrigin], context: nil)
        ctx.restoreGState()
    }

    ctx.restoreGState()
}

// ============================================================
// Menu Bar Icon: Green shield + lock, template style (monochrome)
// ============================================================
func drawMenuBarIcon(ctx: CGContext, size: CGFloat) {
    let scale = size / 1024.0
    ctx.saveGState()
    ctx.scaleBy(x: scale, y: scale)

    // Shield
    let sx: CGFloat = 80, sy: CGFloat = 60, sw: CGFloat = 864, sh: CGFloat = 900
    let shieldPath = makeShieldPath(x: sx, y: sy, w: sw, h: sh)

    // Fill shield solid
    ctx.addPath(shieldPath)
    ctx.setFillColor(cgColor(r: 34, g: 197, b: 94, a: 1.0))
    ctx.fillPath()

    // Lock - white
    let lockCX: CGFloat = 512, lockCY: CGFloat = 380

    // Shackle
    ctx.addEllipse(in: CGRect(x: lockCX - 100, y: lockCY - 80, width: 200, height: 160))
    ctx.setFillColor(CGColor(red: 0, green: 0.4, blue: 0.2, alpha: 0))
    ctx.setStrokeColor(cgColor(r: 255, g: 255, b: 255, a: 1.0))
    ctx.setLineWidth(32)
    ctx.strokePath()

    // Inner shackle cutout
    ctx.addEllipse(in: CGRect(x: lockCX - 60, y: lockCY - 44, width: 120, height: 100))
    ctx.setFillColor(cgColor(r: 34, g: 197, b: 94))
    ctx.fillPath()

    // Lock body
    ctx.addPath(CGPath(roundedRect: CGRect(x: lockCX - 140, y: lockCY + 40, width: 280, height: 220), cornerWidth: 28, cornerHeight: 28, transform: nil))
    ctx.setFillColor(cgColor(r: 255, g: 255, b: 255, a: 1.0))
    ctx.fillPath()

    // Keyhole
    ctx.addEllipse(in: CGRect(x: lockCX - 28, y: lockCY + 80, width: 56, height: 56))
    ctx.setFillColor(cgColor(r: 34, g: 197, b: 94))
    ctx.fillPath()

    // Keyhole rectangle
    ctx.addPath(CGPath(rect: CGRect(x: lockCX - 12, y: lockCY + 130, width: 24, height: 40), transform: nil))
    ctx.setFillColor(cgColor(r: 34, g: 197, b: 94))
    ctx.fillPath()

    ctx.restoreGState()
}

// ============================================================
// Generate App Icon sizes
// ============================================================
let appIconSizes: [(name: String, size: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

let appIconDir = URL(fileURLWithPath: "/opt/develop/tools/MFA/Resources/Assets.xcassets/AppIcon.appiconset/")

for icon in appIconSizes {
    let ctx = createBitmapContext(size: icon.size)
    drawAppIcon(ctx: ctx, size: CGFloat(icon.size))
    let image = ctx.makeImage()!
    savePNG(image: image, url: appIconDir.appendingPathComponent("\(icon.name).png"))
}
print("App icons generated")

// ============================================================
// Generate Menu Bar Icon
// ============================================================
let menuBarDir = URL(fileURLWithPath: "/opt/develop/tools/MFA/Resources/Assets.xcassets/")

// Create imageset directory
let menuBarSetDir = menuBarDir.appendingPathComponent("MenuBarIcon.imageset/")
let fm = FileManager.default
if !fm.fileExists(atPath: menuBarSetDir.path) {
    try? fm.createDirectory(at: menuBarSetDir, withIntermediateDirectories: true)
}

// Generate @1x (22px) and @2x (44px) - standard menu bar icon sizes
for scale in [1, 2] {
    let pixelSize = 22 * scale
    let ctx = createBitmapContext(size: pixelSize)
    drawMenuBarIcon(ctx: ctx, size: CGFloat(pixelSize))
    let image = ctx.makeImage()!
    let filename = scale == 1 ? "menubar_icon.png" : "menubar_icon@2x.png"
    savePNG(image: image, url: menuBarSetDir.appendingPathComponent(filename))
}

// Write Contents.json for the imageset
let contentsJSON = """
{
  "images" : [
    {
      "filename" : "menubar_icon.png",
      "idiom" : "mac",
      "scale" : "1x"
    },
    {
      "filename" : "menubar_icon@2x.png",
      "idiom" : "mac",
      "scale" : "2x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "preserves-vector-representation" : true,
    "template-rendering-intent" : "original"
  }
}
"""
try! contentsJSON.write(to: menuBarSetDir.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("Menu bar icon generated")

print("\nDone!")
