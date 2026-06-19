import AppKit
import Foundation

struct IconSlot {
    let size: String
    let scale: String
    let pixels: Int
    let filename: String
}

let slots = [
    IconSlot(size: "16x16", scale: "1x", pixels: 16, filename: "quicklm-icon-16.png"),
    IconSlot(size: "16x16", scale: "2x", pixels: 32, filename: "quicklm-icon-16@2x.png"),
    IconSlot(size: "32x32", scale: "1x", pixels: 32, filename: "quicklm-icon-32.png"),
    IconSlot(size: "32x32", scale: "2x", pixels: 64, filename: "quicklm-icon-32@2x.png"),
    IconSlot(size: "128x128", scale: "1x", pixels: 128, filename: "quicklm-icon-128.png"),
    IconSlot(size: "128x128", scale: "2x", pixels: 256, filename: "quicklm-icon-128@2x.png"),
    IconSlot(size: "256x256", scale: "1x", pixels: 256, filename: "quicklm-icon-256.png"),
    IconSlot(size: "256x256", scale: "2x", pixels: 512, filename: "quicklm-icon-256@2x.png"),
    IconSlot(size: "512x512", scale: "1x", pixels: 512, filename: "quicklm-icon-512.png"),
    IconSlot(size: "512x512", scale: "2x", pixels: 1024, filename: "quicklm-icon-512@2x.png")
]

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let appIconDirectory = root
    .appendingPathComponent("gpt_action")
    .appendingPathComponent("Assets.xcassets")
    .appendingPathComponent("AppIcon.appiconset")

try FileManager.default.createDirectory(at: appIconDirectory, withIntermediateDirectories: true)

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func drawSpark(center: CGPoint, outerRadius: CGFloat, innerRadius: CGFloat, color: NSColor) {
    let path = NSBezierPath()

    for index in 0..<8 {
        let angle = -.pi / 2 + CGFloat(index) * .pi / 4
        let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
        let point = CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )

        if index == 0 {
            path.move(to: point)
        } else {
            path.line(to: point)
        }
    }

    path.close()
    color.setFill()
    path.fill()
}

func drawIcon(pixels: Int) -> NSImage {
    let side = CGFloat(pixels)
    let bounds = CGRect(x: 0, y: 0, width: side, height: side)
    let image = NSImage(size: bounds.size)

    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    context.setShouldAntialias(true)
    context.setAllowsAntialiasing(true)
    context.interpolationQuality = .high

    NSColor.clear.setFill()
    bounds.fill()

    let inset = side * 0.085
    let tileRect = bounds.insetBy(dx: inset, dy: inset)
    let tileRadius = side * 0.205
    let tilePath = NSBezierPath(
        roundedRect: tileRect,
        xRadius: tileRadius,
        yRadius: tileRadius
    )

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color(0, 0, 0, 0.28)
    shadow.shadowOffset = CGSize(width: 0, height: -side * 0.025)
    shadow.shadowBlurRadius = side * 0.04
    shadow.set()
    color(11, 16, 24).setFill()
    tilePath.fill()
    NSGraphicsContext.restoreGraphicsState()

    let backgroundGradient = NSGradient(colors: [
        color(34, 44, 59),
        color(18, 22, 31),
        color(8, 12, 20)
    ])!
    backgroundGradient.draw(in: tilePath, angle: 315)

    NSGraphicsContext.saveGraphicsState()
    tilePath.addClip()

    let glowRect = CGRect(
        x: side * 0.08,
        y: side * 0.42,
        width: side * 0.86,
        height: side * 0.72
    )
    let glowPath = NSBezierPath(ovalIn: glowRect)
    color(20, 145, 255, 0.34).setFill()
    glowPath.fill()

    let lowerGlowRect = CGRect(
        x: side * 0.28,
        y: -side * 0.16,
        width: side * 0.76,
        height: side * 0.52
    )
    let lowerGlowPath = NSBezierPath(ovalIn: lowerGlowRect)
    color(87, 212, 255, 0.18).setFill()
    lowerGlowPath.fill()

    NSGraphicsContext.restoreGraphicsState()

    let bubbleRect = CGRect(
        x: side * 0.235,
        y: side * 0.285,
        width: side * 0.53,
        height: side * 0.43
    )
    let bubbleRadius = side * 0.095
    let bubblePath = NSBezierPath(
        roundedRect: bubbleRect,
        xRadius: bubbleRadius,
        yRadius: bubbleRadius
    )

    let tailPath = NSBezierPath()
    tailPath.move(to: CGPoint(x: bubbleRect.maxX - side * 0.17, y: bubbleRect.minY + side * 0.015))
    tailPath.line(to: CGPoint(x: bubbleRect.maxX - side * 0.035, y: bubbleRect.minY - side * 0.105))
    tailPath.line(to: CGPoint(x: bubbleRect.maxX - side * 0.05, y: bubbleRect.minY + side * 0.12))
    tailPath.close()

    let bubbleGradient = NSGradient(colors: [
        color(47, 178, 255),
        color(17, 116, 255)
    ])!

    NSGraphicsContext.saveGraphicsState()
    let bubbleShadow = NSShadow()
    bubbleShadow.shadowColor = color(0, 0, 0, 0.22)
    bubbleShadow.shadowOffset = CGSize(width: 0, height: -side * 0.012)
    bubbleShadow.shadowBlurRadius = side * 0.025
    bubbleShadow.set()
    bubbleGradient.draw(in: bubblePath, angle: 270)
    bubbleGradient.draw(in: tailPath, angle: 270)
    NSGraphicsContext.restoreGraphicsState()

    let highlightPath = NSBezierPath(
        roundedRect: bubbleRect.insetBy(dx: side * 0.035, dy: side * 0.035),
        xRadius: bubbleRadius * 0.72,
        yRadius: bubbleRadius * 0.72
    )
    color(255, 255, 255, 0.11).setStroke()
    highlightPath.lineWidth = max(1, side * 0.012)
    highlightPath.stroke()

    drawSpark(
        center: CGPoint(x: side * 0.5, y: side * 0.515),
        outerRadius: side * 0.155,
        innerRadius: side * 0.055,
        color: color(255, 255, 255)
    )

    drawSpark(
        center: CGPoint(x: side * 0.33, y: side * 0.71),
        outerRadius: side * 0.05,
        innerRadius: side * 0.018,
        color: color(117, 218, 255)
    )

    drawSpark(
        center: CGPoint(x: side * 0.69, y: side * 0.31),
        outerRadius: side * 0.038,
        innerRadius: side * 0.014,
        color: color(152, 226, 255)
    )

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        throw CocoaError(.fileWriteUnknown)
    }

    try pngData.write(to: url)
}

for slot in slots {
    let image = drawIcon(pixels: slot.pixels)
    try writePNG(image, to: appIconDirectory.appendingPathComponent(slot.filename))
}

let images = slots.map { slot in
    """
        {
          "filename" : "\(slot.filename)",
          "idiom" : "mac",
          "scale" : "\(slot.scale)",
          "size" : "\(slot.size)"
        }
    """
}.joined(separator: ",\n")

let contents = """
{
  "images" : [
\(images)
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

try contents.write(
    to: appIconDirectory.appendingPathComponent("Contents.json"),
    atomically: true,
    encoding: .utf8
)

print("Generated \(slots.count) app icon assets in \(appIconDirectory.path)")
